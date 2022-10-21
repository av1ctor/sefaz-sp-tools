using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BOLeecher
{
    internal enum Particionamento {
        Nenhum,
        Anual,
        Semestral,
        Trimestral,
        Mensal,
        Quinzenal,
        Semanal,
        Diario
    }

    internal enum ParametroTipo { 
        Texto,
        Data,
        Numerico
    }

    internal struct RelatorioParametro{
        public string key;
        public string nome;
        public string? descricao;
        public ParametroTipo? tipo;
        public bool? multiplo;
        public string? separador;
        public string? formato;
        public object? valor;
        public bool? hidden;
        public bool? opcional;
    }

    internal struct Relatorio{
        public string id;
        public string nome;
        public string? descricao;
        public bool particionavel;
        public Particionamento quebra;
        public List<RelatorioParametro> parametros;
    }

    internal struct RelatorioCtx { 
        public HttpClient client;
        public string bttoken;
    }

}
