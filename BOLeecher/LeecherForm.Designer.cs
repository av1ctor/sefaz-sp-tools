namespace BOLeecher
{
    partial class LeecherForm
    {
        /// <summary>
        ///  Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        ///  Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        ///  Required method for Designer support - do not modify
        ///  the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.maskedTextBox1 = new System.Windows.Forms.MaskedTextBox();
            this.label1 = new System.Windows.Forms.Label();
            this.CNPJ = new System.Windows.Forms.Label();
            this.maskedTextBox2 = new System.Windows.Forms.MaskedTextBox();
            this.maskedTextBox3 = new System.Windows.Forms.MaskedTextBox();
            this.label2 = new System.Windows.Forms.Label();
            this.maskedTextBox4 = new System.Windows.Forms.MaskedTextBox();
            this.label3 = new System.Windows.Forms.Label();
            this.folderBrowserDialog1 = new System.Windows.Forms.FolderBrowserDialog();
            this.processarBtn = new System.Windows.Forms.Button();
            this.sairBtn = new System.Windows.Forms.Button();
            this.menuBar = new System.Windows.Forms.MenuStrip();
            this.ajudaToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.sobreToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.arquivoToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.fecharToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.paramsTab = new System.Windows.Forms.TabPage();
            this.sobrescreverChk = new System.Windows.Forms.CheckBox();
            this.conexoesField = new System.Windows.Forms.NumericUpDown();
            this.label4 = new System.Windows.Forms.Label();
            this.tentativasField = new System.Windows.Forms.NumericUpDown();
            this.formatoField = new System.Windows.Forms.ComboBox();
            this.label14 = new System.Windows.Forms.Label();
            this.pastaField = new System.Windows.Forms.TextBox();
            this.label11 = new System.Windows.Forms.Label();
            this.senhaField = new System.Windows.Forms.TextBox();
            this.label8 = new System.Windows.Forms.Label();
            this.label10 = new System.Windows.Forms.Label();
            this.selecionarPastaBtn = new System.Windows.Forms.Button();
            this.usuarioField = new System.Windows.Forms.TextBox();
            this.label9 = new System.Windows.Forms.Label();
            this.parametrosGrid = new System.Windows.Forms.DataGridView();
            this.relsTab = new System.Windows.Forms.TabPage();
            this.relatoriosGrid = new System.Windows.Forms.DataGridView();
            this.tabControl1 = new System.Windows.Forms.TabControl();
            this.procTab = new System.Windows.Forms.TabPage();
            this.particoesGrid = new System.Windows.Forms.DataGridView();
            this.statusBar = new System.Windows.Forms.StatusStrip();
            this.toolStripStatusLabel1 = new System.Windows.Forms.ToolStripStatusLabel();
            this.menuBar.SuspendLayout();
            this.paramsTab.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.conexoesField)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.tentativasField)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.parametrosGrid)).BeginInit();
            this.relsTab.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.relatoriosGrid)).BeginInit();
            this.tabControl1.SuspendLayout();
            this.procTab.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.particoesGrid)).BeginInit();
            this.statusBar.SuspendLayout();
            this.SuspendLayout();
            // 
            // maskedTextBox1
            // 
            this.maskedTextBox1.Location = new System.Drawing.Point(43, 49);
            this.maskedTextBox1.Name = "maskedTextBox1";
            this.maskedTextBox1.Size = new System.Drawing.Size(232, 23);
            this.maskedTextBox1.TabIndex = 0;
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(43, 24);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(38, 15);
            this.label1.TabIndex = 1;
            this.label1.Text = "label1";
            // 
            // CNPJ
            // 
            this.CNPJ.AutoSize = true;
            this.CNPJ.Location = new System.Drawing.Point(45, 32);
            this.CNPJ.Name = "CNPJ";
            this.CNPJ.Size = new System.Drawing.Size(34, 15);
            this.CNPJ.TabIndex = 0;
            this.CNPJ.Text = "CNPJ";
            // 
            // maskedTextBox2
            // 
            this.maskedTextBox2.Location = new System.Drawing.Point(50, 52);
            this.maskedTextBox2.Mask = "00.000.000/0000-00";
            this.maskedTextBox2.Name = "maskedTextBox2";
            this.maskedTextBox2.Size = new System.Drawing.Size(94, 23);
            this.maskedTextBox2.TabIndex = 1;
            // 
            // maskedTextBox3
            // 
            this.maskedTextBox3.Location = new System.Drawing.Point(50, 110);
            this.maskedTextBox3.Mask = "0000-00";
            this.maskedTextBox3.Name = "maskedTextBox3";
            this.maskedTextBox3.Size = new System.Drawing.Size(94, 23);
            this.maskedTextBox3.TabIndex = 3;
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Location = new System.Drawing.Point(50, 90);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(36, 15);
            this.label2.TabIndex = 2;
            this.label2.Text = "Início";
            // 
            // maskedTextBox4
            // 
            this.maskedTextBox4.Location = new System.Drawing.Point(169, 110);
            this.maskedTextBox4.Mask = "0000-00";
            this.maskedTextBox4.Name = "maskedTextBox4";
            this.maskedTextBox4.Size = new System.Drawing.Size(94, 23);
            this.maskedTextBox4.TabIndex = 5;
            // 
            // label3
            // 
            this.label3.AutoSize = true;
            this.label3.Location = new System.Drawing.Point(169, 90);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(36, 15);
            this.label3.TabIndex = 4;
            this.label3.Text = "Início";
            // 
            // processarBtn
            // 
            this.processarBtn.Location = new System.Drawing.Point(221, 466);
            this.processarBtn.Name = "processarBtn";
            this.processarBtn.Size = new System.Drawing.Size(75, 27);
            this.processarBtn.TabIndex = 11;
            this.processarBtn.Text = "Iniciar";
            this.processarBtn.UseVisualStyleBackColor = true;
            this.processarBtn.Click += new System.EventHandler(this.processarBtn_Click);
            // 
            // sairBtn
            // 
            this.sairBtn.Location = new System.Drawing.Point(302, 466);
            this.sairBtn.Name = "sairBtn";
            this.sairBtn.Size = new System.Drawing.Size(75, 27);
            this.sairBtn.TabIndex = 12;
            this.sairBtn.Text = "Sair";
            this.sairBtn.UseVisualStyleBackColor = true;
            this.sairBtn.Click += new System.EventHandler(this.sairBtn_Click);
            // 
            // menuBar
            // 
            this.menuBar.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.ajudaToolStripMenuItem,
            this.arquivoToolStripMenuItem});
            this.menuBar.Location = new System.Drawing.Point(0, 0);
            this.menuBar.Name = "menuBar";
            this.menuBar.Size = new System.Drawing.Size(627, 24);
            this.menuBar.TabIndex = 30;
            this.menuBar.Text = "menuStrip1";
            // 
            // ajudaToolStripMenuItem
            // 
            this.ajudaToolStripMenuItem.Alignment = System.Windows.Forms.ToolStripItemAlignment.Right;
            this.ajudaToolStripMenuItem.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.sobreToolStripMenuItem});
            this.ajudaToolStripMenuItem.Name = "ajudaToolStripMenuItem";
            this.ajudaToolStripMenuItem.Size = new System.Drawing.Size(50, 20);
            this.ajudaToolStripMenuItem.Text = "&Ajuda";
            // 
            // sobreToolStripMenuItem
            // 
            this.sobreToolStripMenuItem.Name = "sobreToolStripMenuItem";
            this.sobreToolStripMenuItem.Size = new System.Drawing.Size(104, 22);
            this.sobreToolStripMenuItem.Text = "&Sobre";
            this.sobreToolStripMenuItem.Click += new System.EventHandler(this.sobre_Click);
            // 
            // arquivoToolStripMenuItem
            // 
            this.arquivoToolStripMenuItem.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.fecharToolStripMenuItem});
            this.arquivoToolStripMenuItem.Name = "arquivoToolStripMenuItem";
            this.arquivoToolStripMenuItem.Size = new System.Drawing.Size(61, 20);
            this.arquivoToolStripMenuItem.Text = "A&rquivo";
            // 
            // fecharToolStripMenuItem
            // 
            this.fecharToolStripMenuItem.Name = "fecharToolStripMenuItem";
            this.fecharToolStripMenuItem.Size = new System.Drawing.Size(109, 22);
            this.fecharToolStripMenuItem.Text = "&Fechar";
            this.fecharToolStripMenuItem.Click += new System.EventHandler(this.fecharToolStripMenuItem_Click);
            // 
            // paramsTab
            // 
            this.paramsTab.Controls.Add(this.sobrescreverChk);
            this.paramsTab.Controls.Add(this.conexoesField);
            this.paramsTab.Controls.Add(this.label4);
            this.paramsTab.Controls.Add(this.tentativasField);
            this.paramsTab.Controls.Add(this.formatoField);
            this.paramsTab.Controls.Add(this.label14);
            this.paramsTab.Controls.Add(this.pastaField);
            this.paramsTab.Controls.Add(this.label11);
            this.paramsTab.Controls.Add(this.senhaField);
            this.paramsTab.Controls.Add(this.label8);
            this.paramsTab.Controls.Add(this.label10);
            this.paramsTab.Controls.Add(this.selecionarPastaBtn);
            this.paramsTab.Controls.Add(this.usuarioField);
            this.paramsTab.Controls.Add(this.label9);
            this.paramsTab.Controls.Add(this.parametrosGrid);
            this.paramsTab.Location = new System.Drawing.Point(4, 24);
            this.paramsTab.Name = "paramsTab";
            this.paramsTab.Padding = new System.Windows.Forms.Padding(3);
            this.paramsTab.Size = new System.Drawing.Size(595, 503);
            this.paramsTab.TabIndex = 1;
            this.paramsTab.Text = "Parâmetros";
            this.paramsTab.UseVisualStyleBackColor = true;
            // 
            // sobrescreverChk
            // 
            this.sobrescreverChk.AutoSize = true;
            this.sobrescreverChk.Location = new System.Drawing.Point(463, 375);
            this.sobrescreverChk.Name = "sobrescreverChk";
            this.sobrescreverChk.Size = new System.Drawing.Size(93, 19);
            this.sobrescreverChk.TabIndex = 6;
            this.sobrescreverChk.Text = "Sobrescrever";
            this.sobrescreverChk.UseVisualStyleBackColor = true;
            // 
            // conexoesField
            // 
            this.conexoesField.Location = new System.Drawing.Point(308, 416);
            this.conexoesField.Maximum = new decimal(new int[] {
            10,
            0,
            0,
            0});
            this.conexoesField.Minimum = new decimal(new int[] {
            1,
            0,
            0,
            0});
            this.conexoesField.Name = "conexoesField";
            this.conexoesField.Size = new System.Drawing.Size(270, 23);
            this.conexoesField.TabIndex = 8;
            this.conexoesField.Value = new decimal(new int[] {
            1,
            0,
            0,
            0});
            // 
            // label4
            // 
            this.label4.AutoSize = true;
            this.label4.Location = new System.Drawing.Point(308, 398);
            this.label4.Name = "label4";
            this.label4.Size = new System.Drawing.Size(125, 15);
            this.label4.TabIndex = 46;
            this.label4.Text = "Conexões simultâneas";
            // 
            // tentativasField
            // 
            this.tentativasField.Location = new System.Drawing.Point(18, 416);
            this.tentativasField.Maximum = new decimal(new int[] {
            10,
            0,
            0,
            0});
            this.tentativasField.Minimum = new decimal(new int[] {
            1,
            0,
            0,
            0});
            this.tentativasField.Name = "tentativasField";
            this.tentativasField.Size = new System.Drawing.Size(270, 23);
            this.tentativasField.TabIndex = 7;
            this.tentativasField.Value = new decimal(new int[] {
            1,
            0,
            0,
            0});
            // 
            // formatoField
            // 
            this.formatoField.FormattingEnabled = true;
            this.formatoField.Items.AddRange(new object[] {
            "CSV",
            "Excel",
            "PDF",
            "TXT"});
            this.formatoField.Location = new System.Drawing.Point(308, 372);
            this.formatoField.Name = "formatoField";
            this.formatoField.Size = new System.Drawing.Size(135, 23);
            this.formatoField.TabIndex = 5;
            this.formatoField.Text = "Excel";
            // 
            // label14
            // 
            this.label14.AutoSize = true;
            this.label14.Location = new System.Drawing.Point(18, 398);
            this.label14.Name = "label14";
            this.label14.Size = new System.Drawing.Size(59, 15);
            this.label14.TabIndex = 45;
            this.label14.Text = "Tentativas";
            // 
            // pastaField
            // 
            this.pastaField.Location = new System.Drawing.Point(18, 372);
            this.pastaField.Name = "pastaField";
            this.pastaField.Size = new System.Drawing.Size(230, 23);
            this.pastaField.TabIndex = 4;
            // 
            // label11
            // 
            this.label11.AutoSize = true;
            this.label11.Location = new System.Drawing.Point(308, 442);
            this.label11.Name = "label11";
            this.label11.Size = new System.Drawing.Size(39, 15);
            this.label11.TabIndex = 44;
            this.label11.Text = "Senha";
            // 
            // senhaField
            // 
            this.senhaField.Location = new System.Drawing.Point(308, 460);
            this.senhaField.Name = "senhaField";
            this.senhaField.PasswordChar = '*';
            this.senhaField.Size = new System.Drawing.Size(270, 23);
            this.senhaField.TabIndex = 10;
            // 
            // label8
            // 
            this.label8.AutoSize = true;
            this.label8.Location = new System.Drawing.Point(308, 354);
            this.label8.Name = "label8";
            this.label8.Size = new System.Drawing.Size(52, 15);
            this.label8.TabIndex = 39;
            this.label8.Text = "Formato";
            // 
            // label10
            // 
            this.label10.AutoSize = true;
            this.label10.Location = new System.Drawing.Point(18, 442);
            this.label10.Name = "label10";
            this.label10.Size = new System.Drawing.Size(47, 15);
            this.label10.TabIndex = 43;
            this.label10.Text = "Usuário";
            // 
            // selecionarPastaBtn
            // 
            this.selecionarPastaBtn.Location = new System.Drawing.Point(254, 372);
            this.selecionarPastaBtn.Name = "selecionarPastaBtn";
            this.selecionarPastaBtn.Size = new System.Drawing.Size(34, 23);
            this.selecionarPastaBtn.TabIndex = 3;
            this.selecionarPastaBtn.Text = "...";
            this.selecionarPastaBtn.UseVisualStyleBackColor = true;
            this.selecionarPastaBtn.Click += new System.EventHandler(this.selecionarPastaBtn_Click);
            // 
            // usuarioField
            // 
            this.usuarioField.Location = new System.Drawing.Point(18, 460);
            this.usuarioField.Name = "usuarioField";
            this.usuarioField.Size = new System.Drawing.Size(270, 23);
            this.usuarioField.TabIndex = 9;
            // 
            // label9
            // 
            this.label9.AutoSize = true;
            this.label9.Location = new System.Drawing.Point(18, 354);
            this.label9.Name = "label9";
            this.label9.Size = new System.Drawing.Size(35, 15);
            this.label9.TabIndex = 42;
            this.label9.Text = "Pasta";
            // 
            // parametrosGrid
            // 
            this.parametrosGrid.AllowUserToAddRows = false;
            this.parametrosGrid.AllowUserToDeleteRows = false;
            this.parametrosGrid.BackgroundColor = System.Drawing.SystemColors.ControlLightLight;
            this.parametrosGrid.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.DisableResizing;
            this.parametrosGrid.Location = new System.Drawing.Point(18, 18);
            this.parametrosGrid.Name = "parametrosGrid";
            this.parametrosGrid.RowHeadersVisible = false;
            this.parametrosGrid.RowTemplate.Height = 25;
            this.parametrosGrid.Size = new System.Drawing.Size(560, 333);
            this.parametrosGrid.TabIndex = 2;
            // 
            // relsTab
            // 
            this.relsTab.Controls.Add(this.relatoriosGrid);
            this.relsTab.Location = new System.Drawing.Point(4, 24);
            this.relsTab.Name = "relsTab";
            this.relsTab.Padding = new System.Windows.Forms.Padding(3);
            this.relsTab.Size = new System.Drawing.Size(595, 503);
            this.relsTab.TabIndex = 0;
            this.relsTab.Text = "Relatórios";
            this.relsTab.UseVisualStyleBackColor = true;
            // 
            // relatoriosGrid
            // 
            this.relatoriosGrid.AllowUserToAddRows = false;
            this.relatoriosGrid.AllowUserToDeleteRows = false;
            this.relatoriosGrid.BackgroundColor = System.Drawing.SystemColors.ControlLightLight;
            this.relatoriosGrid.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.DisableResizing;
            this.relatoriosGrid.Location = new System.Drawing.Point(18, 18);
            this.relatoriosGrid.Name = "relatoriosGrid";
            this.relatoriosGrid.RowHeadersVisible = false;
            this.relatoriosGrid.RowTemplate.Height = 25;
            this.relatoriosGrid.Size = new System.Drawing.Size(560, 466);
            this.relatoriosGrid.TabIndex = 2;
            // 
            // tabControl1
            // 
            this.tabControl1.Controls.Add(this.relsTab);
            this.tabControl1.Controls.Add(this.paramsTab);
            this.tabControl1.Controls.Add(this.procTab);
            this.tabControl1.Location = new System.Drawing.Point(12, 35);
            this.tabControl1.Name = "tabControl1";
            this.tabControl1.SelectedIndex = 0;
            this.tabControl1.Size = new System.Drawing.Size(603, 531);
            this.tabControl1.TabIndex = 1;
            // 
            // procTab
            // 
            this.procTab.Controls.Add(this.particoesGrid);
            this.procTab.Controls.Add(this.sairBtn);
            this.procTab.Controls.Add(this.processarBtn);
            this.procTab.Location = new System.Drawing.Point(4, 24);
            this.procTab.Name = "procTab";
            this.procTab.Padding = new System.Windows.Forms.Padding(3);
            this.procTab.Size = new System.Drawing.Size(595, 503);
            this.procTab.TabIndex = 2;
            this.procTab.Text = "Progresso";
            this.procTab.UseVisualStyleBackColor = true;
            // 
            // particoesGrid
            // 
            this.particoesGrid.AllowUserToAddRows = false;
            this.particoesGrid.AllowUserToDeleteRows = false;
            this.particoesGrid.BackgroundColor = System.Drawing.SystemColors.ControlLightLight;
            this.particoesGrid.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.DisableResizing;
            this.particoesGrid.Location = new System.Drawing.Point(18, 18);
            this.particoesGrid.Name = "particoesGrid";
            this.particoesGrid.RowHeadersVisible = false;
            this.particoesGrid.RowTemplate.Height = 25;
            this.particoesGrid.Size = new System.Drawing.Size(560, 437);
            this.particoesGrid.TabIndex = 17;
            // 
            // statusBar
            // 
            this.statusBar.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.toolStripStatusLabel1});
            this.statusBar.Location = new System.Drawing.Point(0, 582);
            this.statusBar.Name = "statusBar";
            this.statusBar.Size = new System.Drawing.Size(627, 22);
            this.statusBar.TabIndex = 31;
            this.statusBar.Text = "statusStrip1";
            // 
            // toolStripStatusLabel1
            // 
            this.toolStripStatusLabel1.AutoSize = false;
            this.toolStripStatusLabel1.DisplayStyle = System.Windows.Forms.ToolStripItemDisplayStyle.Text;
            this.toolStripStatusLabel1.ImageAlign = System.Drawing.ContentAlignment.MiddleLeft;
            this.toolStripStatusLabel1.Name = "toolStripStatusLabel1";
            this.toolStripStatusLabel1.Size = new System.Drawing.Size(610, 17);
            this.toolStripStatusLabel1.TextAlign = System.Drawing.ContentAlignment.MiddleLeft;
            // 
            // LeecherForm
            // 
            this.ClientSize = new System.Drawing.Size(627, 604);
            this.Controls.Add(this.statusBar);
            this.Controls.Add(this.tabControl1);
            this.Controls.Add(this.menuBar);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedSingle;
            this.MainMenuStrip = this.menuBar;
            this.MaximizeBox = false;
            this.MaximumSize = new System.Drawing.Size(643, 643);
            this.MinimumSize = new System.Drawing.Size(643, 643);
            this.Name = "LeecherForm";
            this.Text = "BOLeecher";
            this.Load += new System.EventHandler(this.Form1_Load);
            this.menuBar.ResumeLayout(false);
            this.menuBar.PerformLayout();
            this.paramsTab.ResumeLayout(false);
            this.paramsTab.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.conexoesField)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.tentativasField)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.parametrosGrid)).EndInit();
            this.relsTab.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.relatoriosGrid)).EndInit();
            this.tabControl1.ResumeLayout(false);
            this.procTab.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.particoesGrid)).EndInit();
            this.statusBar.ResumeLayout(false);
            this.statusBar.PerformLayout();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private MaskedTextBox maskedTextBox1;
        private Label label1;
        private Label CNPJ;
        private MaskedTextBox maskedTextBox2;
        private MaskedTextBox maskedTextBox3;
        private Label label2;
        private MaskedTextBox maskedTextBox4;
        private Label label3;
        private FolderBrowserDialog folderBrowserDialog1;
        private GroupBox groupBox2;
        private Button processarBtn;
        private Button sairBtn;
        private Label label15;
        private TextBox relatorioField;
        private MenuStrip menuBar;
        private ToolStripMenuItem ajudaToolStripMenuItem;
        private ToolStripMenuItem sobreToolStripMenuItem;
        private ToolStripMenuItem arquivoToolStripMenuItem;
        private ToolStripMenuItem fecharToolStripMenuItem;
        private TabPage paramsTab;
        private TabPage relsTab;
        private TabControl tabControl1;
        private TabPage procTab;
        private DataGridView relatoriosGrid;
        private DataGridView parametrosGrid;
        private NumericUpDown conexoesField;
        private Label label4;
        private NumericUpDown tentativasField;
        private Label label14;
        private TextBox pastaField;
        private Label label11;
        private ComboBox formatoField;
        private TextBox senhaField;
        private Label label8;
        private Label label10;
        private Button selecionarPastaBtn;
        private TextBox usuarioField;
        private Label label9;
        private DataGridView particoesGrid;
        private StatusStrip statusBar;
        private ToolStripStatusLabel toolStripStatusLabel1;
        private CheckBox sobrescreverChk;
    }
}