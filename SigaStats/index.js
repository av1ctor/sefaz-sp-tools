import dotenv from 'dotenv';
dotenv.config();
import {logon, pesquisarDocsDaUnidade, atualizarUsuarios, atualizarUnidades} from './App.js';

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
        new Date().getFullYear(), 
        (new Date().getMonth())-2, 
        new Date().getFullYear(), 
        new Date().getMonth()-1,
        options);
}

main(process.argv.slice(2));
