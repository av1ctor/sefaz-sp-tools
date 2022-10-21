// BOLeecher - Copyright 2022 by André Vicentini (avtvicentini)

using System.Net;
using Newtonsoft.Json;

namespace BOLeecher
{
    internal enum Formato
    {
        TXT,
        Excel,
        PDF,
        CSV
    }

    internal delegate void OnErrorCb(string msg);
    internal delegate void OnProgressCb(string msg);
    internal delegate void OnProcessFinished();

    internal struct Callbacks { 
        internal OnErrorCb onError;
        internal OnProgressCb onProgress;
        internal OnPartitionInitialized onPartitionInitialized;
        internal OnPartitionProgress onPartitionProgress;
        internal OnPartitionFinished onPartitionFinished;
        internal OnPartitionError onPartitionError;
    }

    internal struct ArgValue {
        public string caption;
        public string key;
    }

    internal struct ArgDataProvider {
        public string name;
        public string id;
        public string memberSelectionMode;
    }

    internal struct Arg {
        public string id;
        public int index;
        public string key;
        public int dataType;
        public ArgValue[] values;
        public string[] deps;
        public ArgDataProvider[] dataproviderInfo;
    }

    internal class Leecher {
        public const int maxConexoes = 10;
        public const string baseUrl = "https://srvbo-v42.intra.fazenda.sp.gov.br/BOE";
        public const string portalPath = "/portal/2205141328";
        public const string idPasta = "849554";
        public const string idAct = "4687";
        private const string userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.105 Safari/537.36";

        private List<Relatorio> relatorios = new List<Relatorio>();
        private Formato formato = Formato.Excel;

        private int conexoes = 1;
        private int tentativas = 3;
        private string pasta = "";
        private bool sobrescrever = false;
        private string username = "";
        private string password = "";
        private Callbacks cbs;

        private HtmlAgilityPack.HtmlDocument doc = new HtmlAgilityPack.HtmlDocument();

        private volatile int processando = 0;
        private List<Particao> particoes = new List<Particao>();
        private Mutex mut = new Mutex();
        private CancellationTokenSource cancTokenSource = new CancellationTokenSource();

        private object relatoriosCtxSemLock = new object();
        private Dictionary<string, SemaphoreSlim> relatoriosCtxSem = new Dictionary<string, SemaphoreSlim>();
        private Dictionary<string, RelatorioCtx> relatoriosCtx = new Dictionary<string, RelatorioCtx>();

        public static Relatorio[] carregarDefinicaoDeRelatorios() {
            var relatorios = File.ReadAllText(Directory.GetCurrentDirectory() + "/relatorios.json");
            return JsonConvert.DeserializeObject<Relatorio[]>(relatorios);
        }

        public Leecher comRelatorios(List<Relatorio> relatorios) {
            this.relatorios = relatorios;
            return this;
        }

        public Leecher comFormato(string valor)
        {
            Enum.TryParse(valor, out Formato formato);
            this.formato = formato;
            return this;
        }

        public Leecher comPasta(string valor) {
            pasta = valor;
            return this;
        }

        public Leecher comSobrescrever(bool valor) {
            sobrescrever = valor;
            return this;
        }

        public Leecher comUsuario(string username, string password) {
            this.username = username;
            this.password = password;
            return this;
        }

        public Leecher comTentativas(int valor)
        {
            tentativas = valor;
            return this;
        }

        public Leecher comConexoes(int valor)
        {
            conexoes = valor;
            return this;
        }

        public Leecher comCallbacks(Callbacks cbs)
        {
            this.cbs = cbs;
            return this;
        }

        private void onPartitionFinished(int num) { 
            mut.WaitOne();
            --processando;
            mut.ReleaseMutex();
            cbs.onPartitionFinished(num);
        }

        private void onPartitionError(int num, string msg) { 
            mut.WaitOne();
            --processando;
            mut.ReleaseMutex();
            cbs.onPartitionError(num, msg);
        }

        private async Task<RelatorioCtx?> onLogon(
            Relatorio relatorio
        ) {
            // NOTA: É necessário fazer logon para cada relatório diverso ou o LaunchPad começará
            // a retornar os arquivos trocados. Isso não acontece quando são partições do mesmo relatório.
            
            lock(relatoriosCtxSemLock) { 
                if(!relatoriosCtxSem.ContainsKey(relatorio.nome)) {
                    relatoriosCtxSem.Add(relatorio.nome, new SemaphoreSlim(1));
                }
            }

            try { 
                relatoriosCtxSem[relatorio.nome].Wait();

                if(relatoriosCtx.ContainsKey(relatorio.nome)) { 
                    return relatoriosCtx[relatorio.nome];
                }
            
                var handler = new HttpClientHandler {
                    CookieContainer = new CookieContainer(),
                    UseCookies = true,
                    UseDefaultCredentials = true
                };

                var client = new HttpClient(handler);

                client.DefaultRequestHeaders.UserAgent.ParseAdd(userAgent);
                client.Timeout = TimeSpan.FromMinutes(60);

                {
                    cbs.onProgress($"Logando {relatorio.nome}...");
                    var res = await client.GetAsync($"{baseUrl}/BI");
                    if (!res.IsSuccessStatusCode) {
                        cbs.onError("Não foi possível se acessar o LaunchPad!");
                        return null;
                    }
                }

                {
                    cbs.onProgress($"Logando {relatorio.nome}....");
                    var res = await portalPost(client, "/InfoView/logon.faces", new KeyValuePair<string, string>[] { });
                    if (!res.IsSuccessStatusCode) {
                        cbs.onError("'logon.faces' falhou!");
                        return null;
                    }
                }

                {
                    cbs.onProgress($"Logando {relatorio.nome}.....");
                    var form = new[] {
                        new KeyValuePair<string, string>("allowLogoff", "true"),
                        new KeyValuePair<string, string>("appKind", "InfoView"),
                        new KeyValuePair<string, string>("vint_cms", "SRV11375:6400"),
                    };
                    var res = await portalPost(
                        client, 
                        "/BIPCoreWeb/VintelaServlet?vint_backURL=%2FInfoView%2Flogon.faces&allowLogoff=true&appKind=InfoView&vint_cms=SRV11375:6400",
                        form
                    );
                    if (!res.IsSuccessStatusCode) {
                        cbs.onError("'VintelaServlet' falhou!");
                        return null;
                    }
                }

                string ids = "";
                {
                    cbs.onProgress($"Logando {relatorio.nome}......");
                    var res = await portalGet(client, "/InfoView/logon.faces?vint_success=false");
                    if (!res.IsSuccessStatusCode) {
                        cbs.onError("'logon.faces' falhou!");
                        return null;
                    }

                    doc.Load(await res.Content.ReadAsStreamAsync());
                    ids = doc.GetElementbyId("com.sun.faces.VIEW").Attributes["value"].Value;
                }

                if (ids.Length == 0) {
                    cbs.onError("Ids não encontrados!");
                    return null;
                }

                string bttoken = "";
                {
                    cbs.onProgress($"Logando {relatorio.nome}.......");
                    var form = new[] {
                        new KeyValuePair<string, string>("_id0:logon:CMS", "SRV11375:6400"),
                        new KeyValuePair<string, string>("_id0:logon:SAP_SYSTEM", ""),
                        new KeyValuePair<string, string>("_id0:logon:SAP_CLIENT", ""),
                        new KeyValuePair<string, string>("_id0:logon:USERNAME", username),
                        new KeyValuePair<string, string>("_id0:logon:PASSWORD", password),
                        new KeyValuePair<string, string>("_id0:logon:AUTH_TYPE", "secLDAP"),
                        new KeyValuePair<string, string>("vint_success", "false"),
                        new KeyValuePair<string, string>("com.sun.faces.VIEW", ids ?? ""),
                        new KeyValuePair<string, string>("_id0", "_id0")
                    };
                    var res = await portalPost(
                        client, 
                        "/InfoView/logon.faces",
                        form
                    );
                    if (!res.IsSuccessStatusCode) {
                        cbs.onError("'logon.faces' falhou!");
                        return null;
                    }

                    var page = await res.Content.ReadAsStringAsync();
                    if (page.IndexOf("Invalid&#x20;username&#x20;or&#x20;password") > -1) {
                        cbs.onError("Usuário ou senha inválido");
                        return null;
                    }

                    doc.LoadHtml(page);
                    var bttokenNode = doc.DocumentNode.SelectSingleNode("//*[@name='bttoken']");
                    if(bttokenNode != null) { 
                        bttoken = bttokenNode.Attributes["value"].Value;
                    }
                }

                if (bttoken.Length == 0) {
                    cbs.onError("bttoken não encontrado!");
                    return null;
                }

                {
                    cbs.onProgress($"Logando {relatorio.nome}........");
                    var form = new[] {
                        new KeyValuePair<string, string>("bttoken", bttoken),
                        new KeyValuePair<string, string>("vint_success", "false"),
                        new KeyValuePair<string, string>("loggedOff", "false")
                    };
                    var res = await portalPost(
                        client, 
                        "/InfoView/listing/main.do?service=%2Fcommon%2FappService.do&appKind=InfoView",
                        form
                    );
                    if (!res.IsSuccessStatusCode) {
                        cbs.onError("'main.do' falhou!");
                        return null;
                    }
                }

                cbs.onProgress("Gerando relatórios...");
                
                var ctx = new RelatorioCtx() { 
                    client = client,
                    bttoken = bttoken,
                };

                relatoriosCtx.Add(relatorio.nome, ctx);
                
                return ctx;
            }
            finally {
                relatoriosCtxSem[relatorio.nome].Release();
            }

        }

        public async void processar(
            OnProcessFinished onProcessFinished
        ) {
            try {
                var num = 0;
                foreach(var relatorio in relatorios) {
                    foreach(var part in getParticoes(relatorio)) {
                        particoes.Add(new Particao {
                            num = num++,
                            relatorio = atribuirPeriodo(relatorio, part),
                            formato = formato,
                            pasta = pasta,
                            sobrescrever = sobrescrever,
                            estado = Estado.INICIANDO,
                            inicio = part.inicio,
                            fim = part.fim,
                            cbs = new PartitionCallbacks { 
                                onPartitionProgress = cbs.onPartitionProgress,
                                onPartitionFinished = onPartitionFinished,
                                onPartitionError = onPartitionError,
                            },
                        });
                    }
                }

                foreach(var (particao, index) in particoes.Select((value, index) => (value, index))) {
                    cbs.onPartitionInitialized(index, particao.getNomeArquivo());
                }

                await gerar(particoes, onProcessFinished);
            }
            catch(Exception e) {
                cbs.onError(e.Message);
                onProcessFinished();
            }
        }

        public async void reprocessar(
            OnProcessFinished onProcessFinished
        ) {
            try {
                cancTokenSource.Cancel();

                var naoProcessadas = particoes
                    .FindAll(
                        p => p.estado != Estado.FINALIZADA && p.estado != Estado.IGNORADA
                    ).Select(
                        p => {
                            p.estado = Estado.INICIANDO; 
                            return p;
                        }
                    ).ToList();
                
                await gerar(naoProcessadas, onProcessFinished);
            }
            catch(Exception e) {
                cbs.onError(e.Message);
                onProcessFinished();
            } 
        }

        private async Task gerar(
            List<Particao> particoes,
            OnProcessFinished onProcessFinished
        ) { 
            var sem = new Semaphore(conexoes, conexoes);
            processando = particoes.Count;

            cancTokenSource = new CancellationTokenSource();
                
            _ = Task.Factory.StartNew(() => {
                foreach(var particao in particoes) {
                    if(!cancTokenSource.Token.IsCancellationRequested) { 
                        _ = particao.processar(sem, onLogon);
                    }
                }
            }, cancTokenSource.Token);

            _ = Task.Factory.StartNew(async () =>
            {
                while (processando > 0 && !cancTokenSource.Token.IsCancellationRequested) {
                    Thread.Sleep(100);
                }

                await processarFalhadas(particoes);

                cbs.onProgress(cancTokenSource.Token.IsCancellationRequested ? "Cancelado!" : "Finalizado!");
                onProcessFinished();
            }, cancTokenSource.Token);
        } 

        private async Task processarFalhadas(
            List<Particao> particoes
        ) {
            while (!cancTokenSource.Token.IsCancellationRequested)
            {
                var falhadas = particoes.FindAll(p => p.estado == Estado.FALHOU && p.tentativas < tentativas);
                if (falhadas.Count == 0)
                {
                    break;
                }

                cbs.onProgress("Gerando relatórios que falharam...");

                foreach (var particao in falhadas)
                {
                    if (!cancTokenSource.Token.IsCancellationRequested)
                    {
                        await particao.processar(null, onLogon);
                    }
                }
            }
        }

        private string converterValor(
            object valor,
            RelatorioParametro param
        ) {
            if(valor == null) {
                return "";
            }
            
            switch(param.tipo) {
                case ParametroTipo.Data:
                    return ((DateOnly)valor).ToString(param.formato ?? "dd/MM/yyyy");
                default:
                    return valor.ToString();
            }
        }

        private RelatorioParametro alterarPeriodo(
            RelatorioParametro param,
            Part part
        ) {
            var valor = param.valor;
            if(param.nome.Equals("Data Inicial")) { 
                valor = part.inicio;
            }
            else if (param.nome.Equals("Data Final")) {
                valor = part.fim;
            }

            return new RelatorioParametro
            {
                key = param.key,
                valor = converterValor(valor, param),
            };
        }   

        private Relatorio atribuirPeriodo (
            Relatorio relatorio, 
            Part part
        ) {
            if(!relatorio.particionavel || relatorio.quebra == Particionamento.Nenhum) {
                return relatorio;
            }

            return new Relatorio {
                id = relatorio.id,
                nome = relatorio.nome,
                particionavel = relatorio.particionavel,
                quebra = relatorio.quebra,
                parametros = relatorio.parametros.Select(param => alterarPeriodo(param, part)).ToList(),
            };
        }

        private async Task<HttpResponseMessage> portalGet(
            HttpClient client,
            string path
        ) {
            return await client.GetAsync($"{baseUrl}{portalPath}{path}");
        }

        private async Task<HttpResponseMessage> portalPost(
            HttpClient client,
            string path,
            KeyValuePair<string, string>[] fields
        ) {
            var form = new FormUrlEncodedContent(fields);
            return await client.PostAsync($"{baseUrl}{portalPath}{path}", form);
        }

        private struct Part
        {
            public DateOnly inicio;
            public DateOnly fim;
        }
        private List<Part> getParticoes(
            Relatorio relatorio
        ) {
            var parts = new List<Part>();
            if(!relatorio.particionavel || relatorio.quebra == Particionamento.Nenhum) {
                parts.Add(new Part { });
                return parts;
            }

            var inicio = (DateOnly)(relatorio.parametros.Find(r => r.nome == "Data Inicial").valor);
            var fim = (DateOnly)(relatorio.parametros.Find(r => r.nome == "Data Final").valor);
            var data = inicio;

            switch (relatorio.quebra) {
                case Particionamento.Anual:
                    var primeiroDiaDoAno = new DateOnly(inicio.Year, 1, 1);
                    while (data <= fim) {
                        var ultimoDia = primeiroDiaDoAno.AddYears(1).AddDays(-1);
                        parts.Add(new Part {
                            inicio = data,
                            fim = ultimoDia <= fim? ultimoDia: fim,
                        });
                        primeiroDiaDoAno = primeiroDiaDoAno.AddYears(1);
                        data = primeiroDiaDoAno;
                    }
                    break;

                case Particionamento.Semestral:
                    var primeiroDiaDoSemestre = new DateOnly(inicio.Year, inicio.Month, 1);
                    while (data <= fim)
                    {
                        var ultimoDia = primeiroDiaDoSemestre.AddMonths(6).AddDays(-1);
                        parts.Add(new Part
                        {
                            inicio = data,
                            fim = ultimoDia <= fim ? ultimoDia : fim,
                        });
                        primeiroDiaDoSemestre = primeiroDiaDoSemestre.AddMonths(6);
                        data = primeiroDiaDoSemestre;
                    }
                    break;

                case Particionamento.Trimestral:
                    var primeiroDiaDoTrimestre = new DateOnly(inicio.Year, inicio.Month, 1);
                    while (data <= fim)
                    {
                        var ultimoDia = primeiroDiaDoTrimestre.AddMonths(3).AddDays(-1);
                        parts.Add(new Part
                        {
                            inicio = data,
                            fim = ultimoDia <= fim ? ultimoDia : fim,
                        });
                        primeiroDiaDoTrimestre = primeiroDiaDoTrimestre.AddMonths(3);
                        data = primeiroDiaDoTrimestre;
                    }
                    break;

                case Particionamento.Mensal:
                    var primeiroDiaDoMes = new DateOnly(inicio.Year, inicio.Month, 1);
                    while (data <= fim)
                    {
                        var ultimoDia = primeiroDiaDoMes.AddMonths(1).AddDays(-1);
                        parts.Add(new Part
                        {
                            inicio = data,
                            fim = ultimoDia <= fim ? ultimoDia : fim,
                        });
                        primeiroDiaDoMes = primeiroDiaDoMes.AddMonths(1);
                        data = primeiroDiaDoMes;
                    }
                    break;

                case Particionamento.Quinzenal:
                    while (data <= fim)
                    {
                        var ultimoDia = data.AddDays(15-1);
                        parts.Add(new Part
                        {
                            inicio = data,
                            fim = ultimoDia <= fim ? ultimoDia : fim,
                        });
                        data = data.AddDays(15);
                    }
                    break;

                case Particionamento.Semanal:
                    while (data <= fim)
                    {
                        var ultimoDia = data.AddDays(7 - 1);
                        parts.Add(new Part
                        {
                            inicio = data,
                            fim = ultimoDia <= fim ? ultimoDia : fim,
                        });
                        data = data.AddDays(7);
                    }
                    break;

                case Particionamento.Diario:
                    while (data <= fim)
                    {
                        parts.Add(new Part
                        {
                            inicio = data,
                            fim = data,
                        });
                        data = data.AddDays(1);
                    }
                    break;

                default:
                    parts.Add(new Part {
                        inicio = inicio,
                        fim = fim,
                    });
                    break;
            }

            return parts;
        }
    }
}
