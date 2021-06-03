require('dotenv').config();
const fs = require('fs');
const iconv = require('iconv-lite');
const cliProgress = require('cli-progress');
const sqlite3 = require('sqlite3');
const {lastDayOfMonth, dateToString, csv2json} = require('./libs/Util');

const SigaApi = require('./libs/SigaApi');
const api = new SigaApi();
const db = new sqlite3.Database('./config.db');

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
        return csv2json(res.data);
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
    try
    {
        const res = await api.findMainDoc(filho);
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
    const res = new Map();

    const bar = new cliProgress.SingleBar({}, cliProgress.Presets.shades_classic);

    bar.start(despachos.length, 0);

    let cnt = 0;
    for(const despacho of despachos)
    {
        bar.update(++cnt);
        
        const pai = await encontrarDocPai(despacho['Número']);
        if(pai)
        {
            const usuario = despacho['Usuário'];
            if(!res.has(pai + usuario))
            {
                const user = await encontrarUsuario(usuario);
                const doc = !opcoes.noTitle? 
                    await encontrarDoc(pai):
                    null;
                if(doc)
                {
                    res.set(pai + usuario, {
                        'Número': doc['Número'],
                        'Usuário': user && user.nome || usuario,
                        'Data': pai['Data'],
                        'Descrição': doc['Descrição'],
                    });
                }
                else
                {
                    res.set(pai + usuario, {
                        'Número': pai,
                        'Usuário': user && user.nome || usuario,
                        'Data': pai['Data'],
                        'Descrição': !opcoes.noTitle? '***Erro***': '',
                    });
                }
            }
        }
    }

    bar.stop();

    return Array.from(res.values());
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

function objectsToCsv(objs)
{
    let res = '';
    
    if(objs && objs.length > 0)
    {
        res += Object.keys(objs[0]).join(';') + '\n';
        res += objs.map(obj => Object.values(obj).map(val => `"${val}"`).join(';')).join('\n');
    }

    return iconv.encode(res, 'latin1');
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
            const stmt = db.prepare("INSERT INTO unidades VALUES (?,?,?) ON CONFLICT(id) DO UPDATE SET sigla=?, descricao=?");
            res.data.forEach(item => stmt.run(item.id, item.sigla, item.descricao, item.sigla, item.descricao));
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
            const stmt = db.prepare("INSERT INTO usuarios VALUES (?,?,?) ON CONFLICT(id) DO UPDATE SET sigla=?, nome=?");
            res.data.forEach(item => stmt.run(item.id, item.sigla, item.nome, item.sigla, item.nome));
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

async function pesquisarDocsDaUnidade(
    orgao, unidade, anoInicial, mesInicial, anoFinal, mesFinal, opcoes)
{
    console.log("Realizando pesquisa de despachos...");
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

    console.log(`Encontrados ${despachos.length} despachos!`);

    console.log("Realizando pesquisa de expedientes...");
    const expeds = await listarExpedientesEmPosseDaUnidade(
        orgao,
        unidade,
        anoInicial, 
        mesInicial, 
        anoFinal, 
        mesFinal,
        opcoes);

    console.log("Realizando pesquisa de processos...");
    const procs = await listarProcessosEmPosseDaUnidade(
        orgao,
        unidade,
        anoInicial, 
        mesInicial, 
        anoFinal, 
        mesFinal,
        opcoes);

    console.log("Realizando pesquisa de documentos...");
    const docs = []; //await listarDocs(despachos, opcoes);
    if(!docs)
    {
        return;
    }

    for(const exp of expeds)
    {
        if(!docs.find(doc => doc['Número'] === exp['Número']))
        {
            const user = await encontrarUsuario(exp['Usuário']);
            docs.push({
                'Número': exp['Número'],
                'Usuário': user && user.nome || exp['Usuário'],
                'Data': exp['Data'],
                'Descrição': exp['Descrição'].replace('Complemento do Assunto:', ''),
            });
        }
    }

    for(const proc of procs)
    {
        if(!docs.find(doc => doc['Número'] === proc['Número']))
        {
            const user = await encontrarUsuario(proc['Usuário']);
            docs.push({
                'Número': proc['Número'],
                'Usuário': user && user.nome || proc['Usuário'],
                'Data': proc['Data'],
                'Descrição': proc['Descrição'].replace('Complemento do Assunto:', ''),
            });
        }
    }

    console.log(`Encontrados ${docs.length} documentos!`);

    console.log("Salvando resultado...");
    const text = objectsToCsv(docs);
    fs.writeFile('./docs.csv', text, () => null);

    console.log("Finalizado!");
}

async function main(args)
{
    console.log("Fazendo logon...");
    if(!await logon(process.env.USER_NAME, process.env.USER_PWD))
    {
        return;
    }

    const options = {
        noTitle: false
    };

    if(args.length > 0)
    {
        switch(args[0].toLowerCase())
        {
        case '--atualizar-unidades':            
            if(!args[1])
            {
                console.error("Erro: Informar offset");
            }
            else
            {
                atualizarUnidades(process.env.ORGAO_ID, parseInt(args[1]));
            }
            return;

        case '--atualizar-usuarios':
            if(!args[1])
            {
                console.error("Erro: Informar offset");
            }
            else
            {
                atualizarUsuarios(process.env.ORGAO_ID, parseInt(args[1]));
            }
            return;

        default:
            for(const arg of args)
            {
                switch(arg)
                {
                case '--sem-titulo':
                    options.noTitle = true;
                    break;

                default:
                    console.error("Erro: Opção inválida");
                    return;
                }
            }
            break;
        }

        
    }
    
    // default
    pesquisarDocsDaUnidade(
        process.env.ORGAO_ID, 
        process.env.LOTA_ID, 
        2019, 
        09, 
        new Date().getFullYear(), 
        new Date().getMonth(),        
        options);
}

main(process.argv.slice(2));
