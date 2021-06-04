const fs = require('fs');
const cliProgress = require('cli-progress');
const sqlite3 = require('sqlite3');
const SigaApi = require('./libs/SigaApi');
const {lastDayOfMonth, dateToString, csv2json, objectsToCsv, array2map} = require('./libs/Util');

const api = new SigaApi();
const db = new sqlite3.Database('./siga.db');

async function logon(user, pwd) 
{
    try
    {
        const res = await api.logon(user, pwd);
        if(res.errors)
        {
            console.error("Erro:", res.errors);
            return false;
        }
    }
    catch(err)
    {
        console.error("Erro:", err);
        return false;
    }

    return true;
}

async function remapUsuario(arr)
{
    for(const item of arr)
    {
        const user = await encontrarUsuario(item['Usuário']);
        item['Usuário'] = user? user.nome: item['Usuário'];
    }

    return arr;
}

async function pesquisarDocs(q, opcoes)
{
    try
    {
        const res = await api.findAllDocs(q, opcoes);
        if(res.errors)
        {
            console.error("Erro:", res.errors);
            return null;
        }
        
        return array2map(csv2json(res.data), ['Número', 'Usuário']);
    }
    catch(err)
    {
        console.error("Erro:", err);
        return null;
    }
}

async function listarDespachosAssinadosPelaUnidade(
    orgaoId, lotacaoId, anoInicial, mesInicial, anoFinal = null, mesFinal = null, opcoes)
{
    const q = {
        "dtDocString": dateToString(new Date(anoInicial, mesInicial, 01)),
        "dtDocFinalString": dateToString(lastDayOfMonth(anoFinal || anoInicial, mesFinal || mesInicial)),
        "orgaoUsu": orgaoId,
        "lotaCadastranteSel.id": lotacaoId,
        "ultMovTipoResp": "2", //unidade
        "idFormaDoc": "8", //DES
        "ultMovIdEstadoDoc": "62", //Assinado
    };

    return pesquisarDocs(q, opcoes);
}

async function listarProcessosEmPosseDaUnidade(
    orgaoId, lotacaoId, anoInicial, mesInicial, anoFinal = null, mesFinal = null, opcoes)
{
    const q = {
        "dtDocString": dateToString(new Date(anoInicial, mesInicial, 01)),
        "dtDocFinalString": dateToString(lastDayOfMonth(anoFinal || anoInicial, mesFinal || mesInicial)),
        "orgaoUsu": orgaoId,
        "ultMovLotaRespSel.id": lotacaoId,
        "ultMovTipoResp": "2", //unidade
        "idFormaDoc": "211", //PRC
        "ultMovIdEstadoDoc": "0", //qualquer
    };

    return pesquisarDocs(q, opcoes);
}

async function listarExpedientesEmPosseDaUnidade(
    orgaoId, lotacaoId, anoInicial, mesInicial, anoFinal = null, mesFinal = null, opcoes)
{
    const q = {
        "dtDocString": dateToString(new Date(anoInicial, mesInicial, 01)),
        "dtDocFinalString": dateToString(lastDayOfMonth(anoFinal || anoInicial, mesFinal || mesInicial)),
        "orgaoUsu": orgaoId,
        "ultMovLotaRespSel.id": lotacaoId,
        "ultMovTipoResp": "2", //unidade
        "idFormaDoc": "140", //EXP
        "ultMovIdEstadoDoc": "0", //qualquer
    };

    return pesquisarDocs(q, opcoes);
}

async function encontrarDocPai(filho)
{
    return new Promise((resolve) =>
    {
        db.get('select p.numero numero, p.data data, p.descricao descricao, u.nome usuario from documentos f inner join documentos p on p.numero = f.pai left join usuarios u on u.id = p.usuario where f.numero = ?', [filho], async (err, row) =>
        {
            if(!err && row)
            {
                resolve({
                    'Número': row.numero,
                    'Usuário': row.usuario,
                    'Data': row.data,
                    'Descrição': row.descricao,
                });
                return;
            }

            try
            {
                const res = await api.findMainDoc(filho);
                if(res.errors)
                {
                    console.error("Erro:", res.errors);
                    return null;
                }
                resolve(res.data);
                return;
            }
            catch(err)
            {
                console.error("Erro:", err);
                resolve(null);
            }
       
        });
    });
}

async function encontrarDoc(num)
{
    try
    {    
        const res = await api.findDocDetails(num);
        if(res.errors)
        {
            console.error("Erro:", res.errors);
            return null;
        }
        return res.data;
    }
    catch(err)
    {
        console.error("Erro:", err);
        return null;
    }
}

async function encontrarUsuario(sigla)
{
    if(!sigla)
    {
        return null;
    }

    return new Promise((resolve) =>
    {
        db.get('select id, sigla, nome from usuarios where sigla = ?', [sigla], async (err, row) =>
        {
            if(!err && row)
            {
                resolve(row);
                return;
            }

            //NOTA: nem sempre o id segue esse padrão!!!
            const id = parseInt(sigla.substring(3)) - 10000;
            resolve(await api.findUser(id))
            return;
        });
    });
}

async function listarDocs(despachos, opcoes)
{
    const docs = new Map();

    const bar = new cliProgress.SingleBar({}, cliProgress.Presets.shades_classic);

    bar.start(despachos.size, 0);

    let cnt = 0;
    for(const despacho of despachos.values())
    {
        bar.update(++cnt);
        
        const pai = await encontrarDocPai(despacho['Número']);
        if(pai)
        {
            atualizarDoc(despacho['Número'], {'pai': pai['Número']});

            const usuario = despacho['Usuário'];
            const key = pai['Número'] + usuario;
            if(!docs.has(key))
            {
                const doc = !pai['Descrição']? 
                    !opcoes.noTitle? 
                        await encontrarDoc(pai['Número']):
                        null:
                    pai;
                if(doc)
                {
                    docs.set(key, {
                        'Número': doc['Número'],
                        'Usuário': usuario,
                        'Data': doc['Data'],
                        'Descrição': doc['Descrição'],
                    });
                }
                else
                {
                    docs.set(key, {
                        'Número': pai['Número'],
                        'Usuário': usuario,
                        'Data': despacho['Data'],
                        'Descrição': !opcoes.noTitle? '***Erro***': '',
                    });
                }
            }
        }
    }

    bar.stop();

    return docs;
}

async function listarDocsDaMesa()
{
    try
    {
        const res = await api.findGroups(true);
        if(res.errors)
        {
            console.error("Erro:", res.errors);
            return null;
        }

        const docs = res.data
            .map(group => (group.grupoDocs || [])
                .map(doc => ({
                    'Número': doc.sigla, 
                    'Usuário': doc.list? 
                        doc.list[doc.list.length-1].pessoa: 
                        null,
                    'Data': doc.data,
                    'Descrição': doc.descr, 
                }))
            ).reduce((arr, item) => {arr.push(...item); return arr;}, []);

        for(const doc of docs)
        {
            if(doc['Usuário'])
            {
                const user = await api.findUser(doc['Usuário']);
                if(user && user.nome)
                {
                    doc['Usuário'] = user.nome;
                }
            }
        }

        return docs;
    }
    catch(err)
    {
        console.error("Erro:", err);
        return null;
    }
}

async function atualizarUnidades(orgao, offset)
{
    try
    {
        console.log("Realizando atualização de unidades...");
        do
        {
            console.log("Offset", offset);
            const res = await api.findAllUnits(orgao, offset);
            if(res.errors)
            {
                console.error("Erro:", res.errors);
                return null;
            }

            console.log(`Encontradas ${res.data.length} unidades!`);

            console.log("Inserindo/atualizando unidades no DB...");
            const stmt = db.prepare("INSERT INTO unidades(id, sigla, descricao) VALUES (?,?,?) ON CONFLICT DO NOTHING");
            res.data.forEach(item => stmt.run(item.id, item.sigla, item.descricao));
            stmt.finalize();

            offset = res.offset;
        }
        while(offset !== -1);

        console.log("Finalizado!");
    }
    catch(err)
    {
        console.error("Erro:", err);
        return null;
    }
}

async function atualizarUsuarios(orgao, offset)
{
    try
    {
        console.log("Realizando atualização de usuários...");
        do
        {
            console.log("Offset", offset);
            const res = await api.findAllUsers(orgao, offset);
            if(res.errors)
            {
                console.error("Erro:", res.errors);
                return null;
            }

            console.log(`Encontrados ${res.data.length} usuários!`);

            console.log("Inserindo/atualizando usuários no DB...");
            const stmt = db.prepare("INSERT INTO usuario(id, sigla, descricao) VALUES (?,?,?) ON DO NOTHING");
            res.data.forEach(item => stmt.run(item.id, item.sigla, item.nome));
            stmt.finalize();
            
            offset = res.offset;
        }
        while(offset !== -1);

        console.log("Finalizado!");
    }
    catch(err)
    {
        console.error("Erro:", err);
        return null;
    }
}

function atualizarDoc(num, obj)
{
    const set = Object.keys(obj).map(key => `${key} = ?`);
    db.run("update documentos set " + set.join(',') + " where numero = ?", ...Object.values(obj), num)   
}

function salvarDocs(docs)
{
    const stmt = db.prepare("INSERT INTO documentos (numero, usuario, data, descricao) VALUES (?,?,?,?) ON CONFLICT DO NOTHING");
    
    for(const doc of docs.values())
    {
        stmt.run(doc['Número'], doc['Usuário'], doc['Data'], doc['Descrição'])
    }
    
    stmt.finalize();
}

async function pesquisarDocsDaUnidade(
    orgao, unidade, anoInicial, mesInicial, anoFinal, mesFinal, opcoes)
{
    console.log("Pesquisando despachos...");
    const despachos = await listarDespachosAssinadosPelaUnidade(
        orgao,
        unidade,
        anoInicial, 
        mesInicial, 
        anoFinal, 
        mesFinal,
        opcoes);
    if(!despachos)
    {
        return;
    }

    salvarDocs(despachos);

    console.log(`Encontrados ${despachos.size} despachos!`);

    console.log("Pesquisando expedientes...");
    const expeds = await listarExpedientesEmPosseDaUnidade(
        orgao,
        unidade,
        anoInicial, 
        mesInicial, 
        anoFinal, 
        mesFinal,
        opcoes);

    salvarDocs(expeds);

    console.log(`Encontrados ${expeds.size} expedientes!`);

    console.log("Pesquisando processos...");
    const procs = await listarProcessosEmPosseDaUnidade(
        orgao,
        unidade,
        anoInicial, 
        mesInicial, 
        anoFinal, 
        mesFinal,
        opcoes);

    salvarDocs(procs);

    console.log(`Encontrados ${procs.size} processos!`);

    console.log("Pesquisando documentos pai dos despachos...");
    const docs = await listarDocs(despachos, opcoes);
    if(!docs)
    {
        return;
    }

    salvarDocs(docs);

    for(const exp of expeds.values())
    {
        const key = exp['Número'] + exp['Usuário'];
        if(!docs.has(key))
        {
            const user = await encontrarUsuario(exp['Usuário']);
            docs.set(key, {
                'Número': exp['Número'],
                'Usuário': user && user.nome || exp['Usuário'],
                'Data': exp['Data'],
                'Descrição': exp['Descrição'].replace('Complemento do Assunto:', ''),
            });
        }
    }

    for(const proc of procs.values())
    {
        const key = proc['Número'] + proc['Usuário'];
        if(!docs.has(key))
        {
            const user = await encontrarUsuario(proc['Usuário']);
            docs.set(key, {
                'Número': proc['Número'],
                'Usuário': user && user.nome || proc['Usuário'],
                'Data': proc['Data'],
                'Descrição': proc['Descrição'].replace('Complemento do Assunto:', ''),
            });
        }
    }

    console.log(`Encontrados ${docs.size} documentos!`);

    console.log("Salvando resultado...");
    const remapped = await remapUsuario(Array.from(docs.values()));
    
    const text = objectsToCsv(remapped);
    fs.writeFile('./docs.csv', text, () => null);

    console.log("Finalizado!");
}

module.exports = {logon, pesquisarDocsDaUnidade, atualizarUsuarios, atualizarUnidades};