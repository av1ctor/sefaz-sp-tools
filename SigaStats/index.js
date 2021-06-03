require('dotenv').config();
const fs = require('fs');
const iconv = require('iconv-lite');
const cliProgress = require('cli-progress');
const {lastDayOfMonth, dateToString, csv2json} = require('./libs/Util');

const SigaApi = require('./libs/SigaApi');
const api = new SigaApi();

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

async function listarDespachos(
    lotacaoId, anoInicial, mesInicial, anoFinal = null, mesFinal = null)
{
    const q = {
        "dtDocString": dateToString(new Date(anoInicial, mesInicial, 01)),
        "dtDocFinalString": dateToString(lastDayOfMonth(anoFinal || anoInicial, mesFinal || mesInicial)),
        "lotaCadastranteSel.id": lotacaoId,
    };

    try
    {
        const res = await api.findAllDocs(q);
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

async function listarDocs(despachos)
{
    const res = new Map();

    const bar = new cliProgress.SingleBar({}, cliProgress.Presets.shades_classic);

    bar.start(despachos.length, 0);

    let cnt = 0;
    for(let despacho of despachos)
    {
        bar.update(++cnt);
        
        const pai = await encontrarDocPai(despacho['Número']);
        if(pai)
        {
            const usuario = despacho['Usuário'];
            if(!res.has(pai + usuario))
            {
                const user = await api.findUser(parseInt(usuario.substring(3)) - 10000);
                const doc = await encontrarDoc(pai);
                if(doc)
                {
                    res.set(pai + usuario, {
                        'Número': doc['Número'],
                        'Usuário': user && user.nome || usuario,
                        'Descrição': doc['Descrição'],
                    });
                }
                else
                {
                    res.set(pai + usuario, {
                        'Número': pai,
                        'Usuário': user && user.nome || usuario,
                        'Descrição': '***Erro***',
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

async function main()
{
    console.log("Fazendo logon...");
    if(!await logon(process.env.USER_NAME, process.env.USER_PWD))
    {
        return;
    }
    
    console.log("Realizando pesquisa de despachos...");
    const despachos = await listarDespachos(
        process.env.LOTA_ID, 2019, 09, new Date().getFullYear(), new Date().getMonth());
    if(!despachos)
    {
        return;
    }

    console.log(`Encontrados ${despachos.length} despachos!`);

    console.log("Realizando pesquisa da mesa...");
    const docsNaMesa = await listarDocsDaMesa();

    console.log("Realizando pesquisa de documentos...");
    const docs = await listarDocs(despachos);
    if(!docs)
    {
        return;
    }

    docsNaMesa.forEach(doc => 
    {
        if(!docs.find(d => d['Número'] === doc['Número']))
        {
            docs.push(doc);
        }
    });

    console.log(`Encontrados ${docs.length} documentos!`);

    console.log("Salvando resultado...");
    const text = objectsToCsv(docs);
    fs.writeFile('./docs.csv', text, () => null);

    console.log("Finalizado!");
}

main();
