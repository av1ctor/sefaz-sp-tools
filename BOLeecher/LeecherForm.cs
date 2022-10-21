// BOLeecher - Copyright 2022 by André Vicentini (avtvicentini)

using System.Data;
using System.Text.RegularExpressions;

namespace BOLeecher
{
    public partial class LeecherForm : Form {
        private readonly Relatorio[] relatorios;
        private HashSet<Relatorio> relatoriosSelecionados = new HashSet<Relatorio>();
        private bool processando = false;
        private Leecher? leecher = null;

        public LeecherForm() {
            relatorios = Leecher.carregarDefinicaoDeRelatorios();

            InitializeComponent();
        }

        private void Form1_Load(object sender, EventArgs e) {
            tentativasField.Value = 3;
            conexoesField.Value = 1;
            iniciarGridRelatorios();
            iniciarGridParametros();
            iniciarGridParticoes();
        }

        private void handleRelatoriosGridClick(object sender, DataGridViewCellEventArgs args) {
            if(args.ColumnIndex == 0) {
                var relatorio = relatorios[args.RowIndex];
                
                if ((bool)relatoriosGrid.Rows[args.RowIndex].Cells[0].Value == true) {
                    relatoriosSelecionados.Add(relatorio);

                    var paramsToAdd = new List<RelatorioParametro>();
                    foreach(var parametro in relatorio.parametros) {
                        var cnt = 0;
                        for(var i = 0; i < parametrosGrid.Rows.Count; i++) {
                            var row = parametrosGrid.Rows[i];
                            if (row.Cells[0].Value.Equals(parametro.nome)) {
                                cnt += 1;
                                break;
                            }
                        }
                        if(cnt == 0) {
                            paramsToAdd.Add(parametro);
                        }
                    }

                    foreach(var param in paramsToAdd) {
                        var i = parametrosGrid.Rows.Add(new string[] {
                            param.nome,
                            param.valor?.ToString() ?? ""
                        });

                        if (param.descricao != null) {
                            parametrosGrid[1, i].ToolTipText = param.descricao;
                        }
                    }
                }
                else {
                    relatoriosSelecionados.Remove(relatorio);

                    foreach (var parametro in relatorio.parametros) {
                        for (var i = 0; i < parametrosGrid.Rows.Count;) {
                            var row = parametrosGrid.Rows[i];
                            if (row.Cells[0].Value.Equals(parametro.nome)) {
                                var cnt = 0;
                                foreach(var rel in relatoriosSelecionados) {
                                    cnt += rel.parametros.Exists(x => x.nome == parametro.nome) ? 1 : 0;
                                    break;
                                }
                                if(cnt == 0) {
                                    parametrosGrid.Rows.RemoveAt(i);
                                } 
                                else {
                                    ++i;
                                }
                            }
                            else {
                                ++i;
                            }
                        }
                    }
                }
            }
        }

        private void iniciarGridRelatorios() {
            relatoriosGrid.Columns.Insert(0, new DataGridViewCheckBoxColumn() { 
                Name = "Gerar",
                HeaderText = "Gerar",
                Width = 45,
            });

            relatoriosGrid.Columns.Insert(1, new DataGridViewTextBoxColumn() {
                Name = "Nome",
                HeaderText = "Nome",
                Width = 360,
                ReadOnly = true,
            });

            var quebraCol = new DataGridViewComboBoxColumn() {
                Name = "Particionamento",
                HeaderText = "Particionamento",
                Width = 130,
            };

            quebraCol.Items.AddRange(new[] { "Nenhum", "Anual", "Semestral", "Trimestral", "Mensal", "Quinzenal", "Semanal", "Diario" });

            relatoriosGrid.Columns.Insert(2, quebraCol);

            foreach (var relatorio in relatorios)
            {
                int i = relatoriosGrid.Rows.Add(new object[] { false, relatorio.nome, relatorio.quebra.ToString() });
                if(!relatorio.particionavel) {
                    relatoriosGrid[2, i].ReadOnly = true;
                }
            }

            relatoriosGrid.CellValueChanged += new DataGridViewCellEventHandler(handleRelatoriosGridClick);

            relatoriosGrid.AutoSizeRowsMode = DataGridViewAutoSizeRowsMode.None;
            relatoriosGrid.AllowUserToResizeRows = false;
        }

        private void iniciarGridParametros() {
            parametrosGrid.Columns.Insert(0, new DataGridViewTextBoxColumn() {
                Name = "Nome",
                HeaderText = "Nome",
                Width = 270,
                ReadOnly = true,
            });
            
            parametrosGrid.Columns.Insert(1, new DataGridViewTextBoxColumn() {
                Name = "Valor",
                HeaderText = "Valor",
                Width = 265,
                ReadOnly = false,
            });

            parametrosGrid.AutoSizeRowsMode = DataGridViewAutoSizeRowsMode.None;
            parametrosGrid.AllowUserToResizeRows = false;
        }

        private void iniciarGridParticoes() {
            particoesGrid.Columns.Insert(0, new DataGridViewTextBoxColumn() { 
                Name = "Num",
                HeaderText = "#",
                Width = 30,
                ReadOnly = true,
            });

            particoesGrid.Columns.Insert(1, new DataGridViewTextBoxColumn() {
                Name = "Nome",
                HeaderText = "Nome",
                Width = 225,
                ReadOnly = true,
            });

            particoesGrid.Columns.Insert(2, new DataGridViewTextBoxColumn() {
                Name = "Estado",
                HeaderText = "Estado",
                Width = 280,
                ReadOnly = true,
            });

            particoesGrid.AutoSizeRowsMode = DataGridViewAutoSizeRowsMode.None;
            particoesGrid.AllowUserToResizeRows = false;
        }

        Mutex particoesGridMutex = new Mutex();

        private void onPartitionInitialized(int num, string name) {
            particoesGrid.Rows.Add(new string[] { 
                $"{1+num}", name, "Aguardando"
            });
        }

        delegate void setParticoesGridEstadoCb(int num, string msg);

        private void setParticoesGridEstado(
            int num,
            string msg
        ) {
            if(particoesGrid.InvokeRequired) { 
                this.Invoke(
                    new setParticoesGridEstadoCb(setParticoesGridEstado),
                    new object[] { num, msg }
                );
            }
            else { 
                particoesGrid[2, num].Value = msg;
                particoesGrid.FirstDisplayedScrollingRowIndex = num;
            }
        }

        private void onPartitionProgress(int num, string msg) {
            try {
                particoesGridMutex.WaitOne();
                setParticoesGridEstado(num, msg);
            }
            finally { 
                particoesGridMutex.ReleaseMutex();
            }
        }

        private void onPartitionFinished(int num) {
            try {
                particoesGridMutex.WaitOne();
                setParticoesGridEstado(num, "Finalizado");
            }
            finally { 
                particoesGridMutex.ReleaseMutex();
            }
        }

        private void onPartitionError(int num, string msg) {
            try {
                particoesGridMutex.WaitOne();
                setParticoesGridEstado(num, $"Erro: {msg}");
            }
            finally { 
                particoesGridMutex.ReleaseMutex();
            }
        }

        Mutex statusBarMutex = new Mutex();
        
        delegate void setStatusBarCb(string msg);

        private void setStatusBar(
            string msg
        ) {
            if(statusBar.InvokeRequired) { 
                this.Invoke(
                    new setStatusBarCb(setStatusBar),
                    new object[] { msg }
                );
            }
            else { 
                statusBar.Items[0].Text = msg;
            }
        }

        private void onProgress(string msg) {
            try {
                statusBarMutex.WaitOne();
                setStatusBar($"Info: {msg}");
            }
            finally {
                statusBarMutex.ReleaseMutex();
            }
        }
        
        private void onError(string msg) {
            try {
                statusBarMutex.WaitOne();
                setStatusBar($"Erro: {msg}");
            }
            finally {
                statusBarMutex.ReleaseMutex();
            }
        }

        private void onProcessFinished() { 
            processando = false;
            leecher = null;
        }

        private bool validate() {
            if (relatoriosSelecionados.Count == 0)
            {
                onError("Nenhum relatório selecionado");
                return false;
            }

            if (tentativasField.Value < 1 || tentativasField.Value > 10) {
                onError("Número inválido de tentativas");
                return false;
            }

            if (conexoesField.Value < 1 || conexoesField.Value > Leecher.maxConexoes)
            {
                onError("Número inválido de conexões simultâneas");
                return false;
            }

            if (pastaField.Text.Length == 0) {
                onError("Pasta destino não definida");
                return false;
            }

            if (usuarioField.Text.Length == 0) {
                onError("Usuário não definido");
                return false;
            }

            if (senhaField.Text.Length == 0) {
                onError("Senha não definida");
                return false;
            }

            return true;
        }

        private void processarBtn_Click(
            object sender, EventArgs e
        ) {
            if (!validate()) {
                return;
            }

            if(processando && leecher != null) { 
                var alert = new AlertForm("Há relatórios sendo gerados. Deseja realmente reiniciar?");
                if(alert.ShowDialog() == DialogResult.Cancel) {
                    return;
                }
                leecher.reprocessar(onProcessFinished);
                return;
            }

            var preparados = preparaRelatorios(relatoriosSelecionados.ToList());
            if(preparados.Item2 != null)
            {
                onError(preparados.Item2);
                return;
            }

            leecher = new Leecher()
                .comTentativas((int)tentativasField.Value)
                .comConexoes((int)conexoesField.Value)
                .comFormato(formatoField.Text)
                .comPasta(pastaField.Text)
                .comSobrescrever(sobrescreverChk.Checked)
                .comUsuario(usuarioField.Text, senhaField.Text)
                .comRelatorios(preparados.Item1)
                .comCallbacks(new Callbacks {
                    onProgress = onProgress,
                    onError = onError,
                    onPartitionInitialized = onPartitionInitialized,
                    onPartitionProgress = onPartitionProgress,
                    onPartitionError = onPartitionError,
                    onPartitionFinished = onPartitionFinished,
                });

            particoesGrid.Rows.Clear();

            processando = true;
            
            leecher.processar(onProcessFinished);
        }

        private DataGridViewRow? encontrarRowPorNome(
            DataGridView grid,
            string key,
            int colIndex
        ) {
            for (var i = 0; i < grid.RowCount; i++)
            {
                var row = grid.Rows[i];
                if (row.Cells[colIndex].Value.Equals(key))
                {
                    return row;
                }
            }

            return null;
        }

        private (List<Relatorio>, string?) preparaRelatorios(
            List<Relatorio> relatorios
        ) {
            var res = new List<Relatorio>();
            
            foreach(var relatorio in relatorios) {
                var row = encontrarRowPorNome(relatoriosGrid, relatorio.nome, 1);

                var parametros = new List<RelatorioParametro>();
                if(row != null) { 
                    foreach(var param in relatorio.parametros) {
                        var r = encontrarRowPorNome(parametrosGrid, param.nome, 0);
                        var valor = param.hidden != null && param.hidden.Value ?
                            param.valor :
                            converterValor(r?.Cells[1].Value.ToString() ?? "", param);

                        if(param.opcional == null || !param.opcional.Value) {
                            if(valor == null || (valor.GetType() == typeof(string) && String.IsNullOrEmpty((string)valor))) { 
                                return (res, $"Parâmetro '{param.nome}' vazio ou inválido");
                            }
                        }

                        parametros.Add(new RelatorioParametro {
                            key = param.key,
                            nome = param.nome,
                            tipo = param.tipo,
                            formato = param.formato,
                            valor = valor,
                        });
                    }
                }
                
                res.Add(new Relatorio() {
                    id = relatorio.id,
                    nome = relatorio.nome,
                    particionavel = relatorio.particionavel,
                    quebra = Enum.Parse<Particionamento>(row?.Cells[2].Value.ToString() ?? "Nenhum", true),
                    parametros = parametros,
                });
            }

            return (res, null);
        }

        private object converterValor(
            string value, 
            RelatorioParametro param
        ) {
            switch (param.tipo) {
                case ParametroTipo.Data:
                    if(DateOnly.TryParse(value, out DateOnly date)) { 
                        return date;
                    }
                    return null;

                case ParametroTipo.Numerico:
                    if(param.multiplo != null && param.multiplo.Value) {
                        return value.Split(param.separador ?? ";").Select(v => limparNumerico(v)).ToArray();
                    }

                    return limparNumerico(value);

                default:
                    if(param.multiplo != null && param.multiplo.Value) {
                        return value.Split(param.separador ?? ";");
                    }
                    
                    return value;
            }
        }

        private string limparNumerico(
            string value
        ){
            
            return Regex.Replace(value, "[^0-9]", "");
        }

        private void sairBtn_Click(
            object sender, EventArgs e
        ) {
            if(processando) { 
                var alert = new AlertForm("Há relatórios sendo gerados. Deseja realmente sair?"); 
                if(alert.ShowDialog() == DialogResult.OK) { 
                    Close();
                }
            }
            else { 
                Close();
            }
        }

        private void sobre_Click(object sender, EventArgs e) {
            var form = new AboutForm();
            form.ShowDialog();
        }

        private void fecharToolStripMenuItem_Click(object sender, EventArgs e) {
            Close();
        }

        private void selecionarPastaBtn_Click(object sender, EventArgs e) {
            folderBrowserDialog1.ShowDialog();
            pastaField.Text = folderBrowserDialog1.SelectedPath;
        }

    }
}