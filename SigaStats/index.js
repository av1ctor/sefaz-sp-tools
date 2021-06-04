require('dotenv').config();
const {logon, pesquisarDocsDaUnidade, atualizarUsuarios, atualizarUnidades} = require('./App');

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
        2020, 
        00, 
        2020, //new Date().getFullYear(), 
        11, //new Date().getMonth(),
        options);
}

main(process.argv.slice(2));
