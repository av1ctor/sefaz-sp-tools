using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace BOLeecher {
    public delegate void OnResponse(bool isOk);

    public partial class AlertForm : Form {
        public AlertForm(
            string msg
        ) {
            InitializeComponent();

            msgLbl.Text = msg;
        }

        private void cancelBtn_Click(object sender, EventArgs e) {
            DialogResult = DialogResult.Cancel;
            Close();
        }

        private void okBtn_Click(object sender, EventArgs e)
        {
            DialogResult = DialogResult.OK;
            Close();
        }
    }
}
