// BOLeecher - Copyright 2022 by André Vicentini (avtvicentini)

using Newtonsoft.Json;

namespace BOLeecher
{
    internal enum Estado
    {
        INICIANDO,
        BAIXANDO,
        FINALIZADA,
        IGNORADA,
        FALHOU,
    }

    internal delegate void OnPartitionInitialized(int num, string name);
    internal delegate void OnPartitionProgress(int num, string msg);
    internal delegate void OnPartitionFinished(int num);
    internal delegate void OnPartitionError(int num, string msg);
    internal delegate Task<RelatorioCtx?> OnLogon(Relatorio relatorio);

    internal struct PartitionCallbacks { 
        internal OnPartitionProgress onPartitionProgress;
        internal OnPartitionFinished onPartitionFinished;
        internal OnPartitionError onPartitionError;
    }

    internal class Particao
    {
        public int num;
        public DateOnly inicio;
        public DateOnly fim;
        public Relatorio relatorio;
        public Formato formato;
        public Dictionary<string, string> parametros;
        public string pasta;
        public bool sobrescrever;
        public Estado estado = Estado.INICIANDO;
        public int tentativas = 0;
        public PartitionCallbacks cbs;

        public async Task processar(            
            Semaphore? sem,
            OnLogon onLogon
        ) {
            try {
                if(sem != null) { 
                    sem.WaitOne();
                }

                ++tentativas;

                var nomeArquivo = $"{pasta}/{getNomeArquivo()}.{getExtensaoArquivo()}";

                if(!sobrescrever) {
                    if(File.Exists(nomeArquivo)) { 
                        cbs.onPartitionFinished(num);
                        estado = Estado.IGNORADA;
                        return;
                    }
                }

                var doc = new HtmlAgilityPack.HtmlDocument();
                var idConsulta = getIdConsulta(relatorio);

                var ctx = await onLogon(relatorio);
                if(ctx == null) { 
                    return;
                }

                var client = ctx?.client;
                var bttoken = ctx?.bttoken;

                if(client == null || bttoken == null) { 
                    return;
                }

                string tidTime = $"{Leecher.idAct}-{idConsulta}-{nowInSeconds()}";
                string csrfToken = "";

                {
                    cbs.onPartitionProgress(num, "Gerando...");
                    var res = await portalGet(
                        client,
                        "/AnalyticalReporting/WebiView.do?defaultView=true&cafWebSesInit=true&opendocTarget=infoviewOpenDocFrame&appKind=InfoView&service=%2FInfoView%2Fcommon%2FappService.do&loc=pt&pvl=pt_BR&ctx=standalone&pref=maxOpageU%3D10%3BmaxOpageUt%3D200%3BmaxOpageC%3D10%3Btz%3DAmerica%2FSao_Paulo%3BmUnit%3Dinch%3BshowFilters%3Dtrue%3BsmtpFrom%3Dtrue%3BpromptForUnsavedData%3Dtrue%3B" +
                        $"&bttoken={bttoken}&actId={Leecher.idAct}&objIds={idConsulta}&containerId={Leecher.idPasta}&tidtime={tidTime}"
                    );
                    if (!res.IsSuccessStatusCode) {
                        estado = Estado.FALHOU;
                        cbs.onPartitionError(num, "'WebiView.do' falhou!");
                        return;
                    }

                    var page = await res.Content.ReadAsStringAsync();
                    doc.LoadHtml(page);
                    if (page.IndexOf("name=\"errMsg\"") > -1) {
                        cbs.onPartitionError(num, doc.DocumentNode.SelectSingleNode("//*[@name='errMsg']").Attributes["value"].Value);
                        estado = Estado.FALHOU;
                        return;
                    }

                    tidTime = doc.DocumentNode.SelectSingleNode("//*[@name='tidtime']").Attributes["value"].Value;
                    csrfToken = doc.DocumentNode.SelectSingleNode("//*[@name='CSRF_TOKEN_COOKIE']").Attributes["value"].Value;
                }

                if (csrfToken.Length == 0) {
                    cbs.onPartitionError(num, "CSRF token não encontrado!");
                    estado = Estado.FALHOU;
                    return;
                }

                string entry = "";
                string docName = "";
                string iReportId = "";

                {
                    cbs.onPartitionProgress(num, "Gerando....");
                    var form = new[] {
                        new KeyValuePair<string, string>("bttoken", bttoken),
                        new KeyValuePair<string, string>("CSRF_TOKEN_COOKIE", csrfToken),
                        new KeyValuePair<string, string>("id", idConsulta),
                        new KeyValuePair<string, string>("objIds", idConsulta),
                        new KeyValuePair<string, string>("actId", Leecher.idAct),
                        new KeyValuePair<string, string>("containerId", Leecher.idPasta),
                        new KeyValuePair<string, string>("defaultView", "true"),
                        new KeyValuePair<string, string>("cafWebSesInit", "true"),
                        new KeyValuePair<string, string>("opendocTarget", "infoviewOpenDocFrame"),
                        new KeyValuePair<string, string>("appKind", "InfoView"),
                        new KeyValuePair<string, string>("service", "%2FInfoView%2Fcommon%2FappService.do"),
                        new KeyValuePair<string, string>("loc", "pt"),
                        new KeyValuePair<string, string>("pvl", "pt_BR"),
                        new KeyValuePair<string, string>("ctx", "standalone"),
                        new KeyValuePair<string, string>("pref", "maxOpageU%3D10%3BmaxOpageUt%3D200%3BmaxOpageC%3D10%3Btz%3DAmerica%2FSao_Paulo%3BmUnit%3Dinch%3BshowFilters%3Dtrue%3BsmtpFrom%3Dtrue%3BpromptForUnsavedData%3Dtrue%3B"),
                        new KeyValuePair<string, string>("tidtime", tidTime),
                        new KeyValuePair<string, string>("kind", "Webi"),
                        new KeyValuePair<string, string>("iventrystore", "widtoken"),
                        new KeyValuePair<string, string>("ViewType", "H"),
                        new KeyValuePair<string, string>("entSession", "InfoViewCE_ENTERPRISESESSION"),
                        new KeyValuePair<string, string>("lang", "pt")
                    };
                    var res = await portalPost(
                        client,
                        "/AnalyticalReporting/webiDHTML/viewer/viewDocument.jsp",
                        form
                    );
                    if (!res.IsSuccessStatusCode) {
                        cbs.onPartitionError(num, "'viewDocument.jsp' falhou!");
                        estado = Estado.FALHOU;
                        return;
                    }

                    var page = await res.Content.ReadAsStringAsync();
                    var p = page.IndexOf("\"strEntry\"");
                    if (p == -1) {
                        cbs.onPartitionError(num, "strEntry não encontrado!");
                        estado = Estado.FALHOU;
                        return;
                    }
                    entry = page.Substring(p + 12, 22);

                    doc.LoadHtml(page);
                    var scripts = doc.DocumentNode.SelectNodes("//script");
                    foreach (var script in scripts) {
                        var text = script.InnerText;
                        var dsp = text.IndexOf("DS =");
                        if (dsp > -1 && dsp < 4) {
                            var ds = text.Substring(4);
                            dynamic obj = JsonConvert.DeserializeObject(ds);
                            if (obj == null) {
                                cbs.onPartitionError(num, "strDocName não encontrado!");
                                estado = Estado.FALHOU;
                                return;
                            }
                            docName = obj.strDocName;
                            iReportId = obj.iReportID;
                            break;
                        }
                    }
                }

                if (docName.Length == 0)
                {
                    cbs.onPartitionError(num, "strDocName não encontrado!");
                    estado = Estado.FALHOU;
                    return;
                }
                if (iReportId.Length == 0)
                {
                    cbs.onPartitionError(num, "iReportID não encontrado!");
                    estado = Estado.FALHOU;
                    return;
                }

                {
                    cbs.onPartitionProgress(num, "Gerando.....");
                    var res = await portalGet(
                        client,
                        $"/AnalyticalReporting/webiDHTML/viewer/report.jsp?sPageMode=&sReportMode=Viewing&iPage=&iFoldPanel=0&zoom=100&isInteractive=false&isStructure=false&appKind=InfoView&sBid=iViewerID={1+num}&iReport=0" +
                        $"&sEntry={entry}&iReportID={iReportId}"
                    );
                    if (!res.IsSuccessStatusCode) {
                        cbs.onPartitionError(num, "'report.jsp' falhou!");
                        estado = Estado.FALHOU;
                        return;
                    }
                }

                {
                    cbs.onPartitionProgress(num, "Gerando......");
                    var res = await portalGet(
                        client,
                        $"/AnalyticalReporting/webiDHTML/viewer/ajaxWomForViewing.jsp?iViewerID={1+num}&url=&ajaxErrorCB=&postCB=" +
                        $"&sEntry={entry}&iReportID={iReportId}"
                    );
                    if (!res.IsSuccessStatusCode) {
                        cbs.onPartitionError(num, "'ajaxWomForViewing.jsp' falhou!");
                        estado = Estado.FALHOU;
                        return;
                    }
                }

                List<Arg> args = new List<Arg>();

                {
                    cbs.onPartitionProgress(num, "Gerando.......");
                    var res = await portalGet(
                        client,
                        $"/AnalyticalReporting/webiDHTML/viewer/ajaxCheckPrompts.jsp?sPageMode=QuickDisplay&sReportMode=Viewing&iPage=1&zoom=100&isInteractive=false&isStructure=false&appKind=InfoView&widx&url=&postCB=&ajaxErrorCB=&iViewerID={1+num}&iReport=0" +
                        $"&sEntry={entry}&iReportID={iReportId}"
                    );
                    if (!res.IsSuccessStatusCode) {
                        cbs.onPartitionError(num, "'ajaxCheckPrompts.jsp' falhou\r\n");
                        estado = Estado.FALHOU;
                        return;
                    }

                    var page = (await res.Content.ReadAsStringAsync()).Replace("\r\n", null).Replace("\\\"", "\"");
                    dynamic prompts = JsonConvert.DeserializeObject(page.Substring(25, page.Length - 27));

                    var _params = getParametrosConsulta(relatorio);

                    var index = 0;
                    foreach (var elm in prompts) {
                        List<ArgDataProvider> dpInfo = new List<ArgDataProvider>();
                        foreach (var dp in elm.dataproviderInfo) {
                            dpInfo.Add(new ArgDataProvider {
                                name = dp.name,
                                id = dp.id,
                                memberSelectionMode = dp.memberSelectionMode
                            });
                        }

                        string key = elm.key;
                        object values = _params[key];

                        args.Add(new Arg {
                            id = elm.id,
                            index = 1 + index,
                            key = elm.key,
                            dataType = elm.dataType,
                            values = values.GetType() == typeof(string[])?
                                ((string[])values).Select(v => new ArgValue
                                {
                                    caption = v,
                                    key = ""
                                }).ToArray():
                                new[] {
                                    new ArgValue {
                                        caption = values.ToString(),
                                        key = ""
                                    }
                                },
                            deps = new string[] { },
                            dataproviderInfo = dpInfo.ToArray(),
                        });
                        ++index;
                    }
                }

                {
                    cbs.onPartitionProgress(num, "Gerando........");
                    var form = new[] {
                        new KeyValuePair<string, string>("sPV", JsonConvert.SerializeObject(args.ToArray())),
                        new KeyValuePair<string, string>("bttoken", bttoken),
                        new KeyValuePair<string, string>("CSRF_TOKEN_COOKIE", csrfToken),
                        new KeyValuePair<string, string>("keyDate", ""),
                        new KeyValuePair<string, string>("sEmptyLab", "%5BEMPTY_VALUE%5D")
                    };

                    var res = await portalPost(
                        client,
                        $"/AnalyticalReporting/webiDHTML/viewer/processPrompts.jsp?iViewerID={1+num}&iReport=0&sPageMode=QuickDisplay&sReportMode=Viewing&iPage=1&zoom=100&isInteractive=false&isStructure=false&appKind=InfoView&setKeyDateFirst=true" +
                        $"&sEntry={entry}&iReportID={iReportId}",
                        form
                    );
                    if (!res.IsSuccessStatusCode) {
                        cbs.onPartitionError(num, "'processPrompts.jsp' falhou!");
                        estado = Estado.FALHOU;
                        return;
                    }

                    var page = await res.Content.ReadAsStringAsync();
                    if (page.IndexOf("BENCH_ERROR") > -1) {
                        doc.LoadHtml(page);
                        cbs.onPartitionError(num, doc.DocumentNode.SelectSingleNode("//*[@name='BENCH_ERROR']").Attributes["value"].Value);
                        estado = Estado.FALHOU;
                        return;
                    }

                    var p = page.IndexOf("&sEntry=");
                    entry = page.Substring(p + 8, 22);
                }

                estado = Estado.BAIXANDO;

                {
                    cbs.onPartitionProgress(num, "Baixando...");
                    var form = new[] {
                        new KeyValuePair<string, string>("bttoken", bttoken),
                        new KeyValuePair<string, string>("CSRF_TOKEN_COOKIE", csrfToken),
                        new KeyValuePair<string, string>($"check_{iReportId}", "on"),
                        new KeyValuePair<string, string>("check_SelectAllReport", "on"),
                        new KeyValuePair<string, string>("check_SelectAllData", "on"),
                        new KeyValuePair<string, string>("check_DP0", "on"),
                        new KeyValuePair<string, string>("Export", "on"),
                        new KeyValuePair<string, string>("fileTypeList", getTipoArquivo()),
                        new KeyValuePair<string, string>("txtCharset", ""),
                        new KeyValuePair<string, string>("cbCharDelimiter", ""),
                        new KeyValuePair<string, string>("cbColSep", "Tab"),
                        new KeyValuePair<string, string>("cbCharset", "UTF-8"),
                    };

                    var res = await portalPost(
                        client,
                        (formato != Formato.CSV?
                            $"/AnalyticalReporting/webiDHTML/viewer/downloadPDForXLS.jsp?sPageMode=QuickDisplay&sReportMode=Viewing&iPage=1&zoom=100&isInteractive=false&isStructure=false&appKind=InfoView&doctype=wid&viewType={getViewType()}&saveReport=N&iViewerID={1+num}&iReport=0":
                            $"/AnalyticalReporting/webiDHTML/viewer/processCSVOptions.jsp?iViewerID={1+num}&sPageMode=QuickDisplay&sReportMode=Viewing&iPage=1&zoom=100&isInteractive=false&isStructure=false&appKind=InfoView&doctype=wid&viewType=COp&saveReport=N")
                            +
                        $"&sEntry={entry}&iReportID={iReportId}",
                        form
                    );
                    if (!res.IsSuccessStatusCode) {
                        cbs.onPartitionError(num, formato != Formato.CSV? "'downloadPDForXLS.jsp' falhou!": "'processCSVOptions.jsp' falhou!");
                        estado = Estado.FALHOU;
                        return;
                    }
                }

                Stream? arquivo = null;

                {
                    cbs.onPartitionProgress(num, "Baixando......");
                    var res = await portalGet(
                        client,
                        formato != Formato.CSV?
                            $"/AnalyticalReporting/webiDHTML/DownloadPDForXLS/{entry}/{Uri.EscapeDataString(docName)}":
                            $"/AnalyticalReporting/webiDHTML/DownloadCSV/{entry}/{Uri.EscapeDataString(docName)}"
                    );
                    if (!res.IsSuccessStatusCode) {
                        cbs.onPartitionError(num, formato != Formato.CSV? "'/DownloadPDForXLS' falhou!": "'/DownloadCSV' falhou!");
                        estado = Estado.FALHOU;
                        return;
                    }

                    arquivo = await res.Content.ReadAsStreamAsync();
                }

                {
                    cbs.onPartitionProgress(num, "Baixando.........");
                    var res = await portalGet(client,
                        $"/AnalyticalReporting/webiDHTML/viewer/checkDownloadProcess.jsp?iViewerID={1+num}&id={nowInSeconds()}&url=&postCB=&ajaxErrorCB=");
                    if (!res.IsSuccessStatusCode) {
                        cbs.onPartitionError(num, "'checkDownloadProcess.jsp' falhou!");
                        estado = Estado.FALHOU;
                        return;
                    }

                    var page = await res.Content.ReadAsStringAsync();
                    dynamic obj = JsonConvert.DeserializeObject(page);
                    if (obj == null || obj.downloadProcessOK == false) {
                        cbs.onPartitionError(num, "Download falhou!");
                        estado = Estado.FALHOU;
                        return;
                    }

                    using (var stream = File.Create(nomeArquivo)) {
                        arquivo.CopyTo(stream);
                    }
                }

                cbs.onPartitionFinished(num);
                estado = Estado.FINALIZADA;
            }
            catch (Exception ex) {
                cbs.onPartitionError(num, ex.Message);
                estado = Estado.FALHOU;
            }
            finally {
                if(sem != null) { 
                    sem.Release();
                }
            }
        }

        private async Task<HttpResponseMessage> portalGet(
            HttpClient client,
            string path
        ) {
            return await client.GetAsync($"{Leecher.baseUrl}{Leecher.portalPath}{path}");
        }

        private async Task<HttpResponseMessage> portalPost(
            HttpClient client,
            string path,
            KeyValuePair<string, string>[] fields
        ) {
            var form = new FormUrlEncodedContent(fields);
            return await client.PostAsync($"{Leecher.baseUrl}{Leecher.portalPath}{path}", form);
        }

        private long nowInSeconds() {
            return (long)DateTime.Today.Subtract(DateTime.UnixEpoch).TotalMilliseconds;
        }

        private string getTipoArquivo() {
            switch (formato) {
                case Formato.TXT:
                    return "TXT";
                case Formato.Excel:
                    return "XLSX";
                case Formato.PDF:
                    return "PDF";
                case Formato.CSV:
                    return "CSVArch";
                default:
                    return "TXT";
            }
        }

        private string getViewType() {
            switch (formato) {
                case Formato.TXT:
                    return "T";
                case Formato.Excel:
                    return "XO";
                case Formato.PDF:
                    return "P";
                case Formato.CSV:
                    return "COp";
                default:
                    return "T";
            }
        }

        private string getExtensaoArquivo() {
            switch (formato) {
                case Formato.TXT:
                    return "txt";
                case Formato.Excel:
                    return "xlsx";
                case Formato.PDF:
                    return "pdf";
                case Formato.CSV:
                    return "csv";
                default:
                    return "unk";
            }
        }

        internal string getNomeArquivo() {
            if(relatorio.quebra == Particionamento.Nenhum) { 
                return relatorio.nome;
            } 
            else {
                return $"{relatorio.nome}-{inicio.ToString("yyyyMMdd")}-{fim.ToString("yyyyMMdd")}";
            }
        }

        private Dictionary<string, object> getParametrosConsulta(
            Relatorio relatorio
        ) {
            var res = new Dictionary<string, object>();
            
            foreach(var param in relatorio.parametros) {
                res.Add(param.key, param.valor ?? "");
            }

            return res;
        }

        private string getIdConsulta(
            Relatorio relatorio
        ) {
            return relatorio.id;
        }
    }
}