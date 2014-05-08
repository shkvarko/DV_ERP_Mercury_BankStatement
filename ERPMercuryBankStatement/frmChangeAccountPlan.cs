using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using ERP_Mercury.Common;

namespace ERPMercuryBankStatement
{
    public partial class frmChangeAccountPlan : DevExpress.XtraEditors.XtraForm
    {
        public CEarning CurrentEarning { get; set; }
        
        public frmChangeAccountPlan()
        {
            InitializeComponent();

            CurrentEarning = null;
        }

        public void EditEarning(CEarning objEarning, List<CAccountPlan> objAccountPlanList, List<CBudgetProject> objBudgetProjectList)
        {
            try
            {
                CurrentEarning = objEarning;

                editorEarningAccountPlan.Properties.Items.Clear();
                if ((objAccountPlanList != null) && (objAccountPlanList.Count > 0))
                {
                    editorEarningAccountPlan.Properties.Items.AddRange(objAccountPlanList);
                }

                editorEarningProjectDst.Properties.Items.Clear();
                if ((objBudgetProjectList != null) && (objBudgetProjectList.Count > 0))
                {
                    editorEarningProjectDst.Properties.Items.AddRange(objBudgetProjectList);
                }

                if (CurrentEarning != null)
                {

                    editorEarningDate.DateTime = CurrentEarning.Date;
                    editorEarningValue.Value = CurrentEarning.Value;
                    editorEarningAccount.SelectedItem = (CurrentEarning.Account == null) ? null : editorEarningAccount.Properties.Items.Cast<CAccount>().SingleOrDefault<CAccount>(x => x.ID.CompareTo(CurrentEarning.Account.ID) == 0);
                    editorEarningCustomer.Properties.Items.Add(CurrentEarning.CustomerName);
                    editorEarningCustomer.SelectedIndex = 0;
                    editorEarningValue.Value = CurrentEarning.Value;
                    editorEarningAccountPlan.SelectedItem = (CurrentEarning.AccountPlan == null) ? null : editorEarningAccountPlan.Properties.Items.Cast<CAccountPlan>().SingleOrDefault<CAccountPlan>(x => x.ID.CompareTo(CurrentEarning.AccountPlan.ID) == 0);
                    
                    editorEarningProjectDst.SelectedItem = (CurrentEarning.BudgetProjectDst == null) ? null : editorEarningProjectDst.Properties.Items.Cast<CBudgetProject>().SingleOrDefault<CBudgetProject>(x => x.ID.CompareTo(CurrentEarning.BudgetProjectDst.ID) == 0);
                }

            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show(
                    "EditEarning.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally
            {
                DialogResult = System.Windows.Forms.DialogResult.None;
                ShowDialog();
            }
            return;

        }

        private System.Boolean SetEarningProperties()
        {
            System.Boolean bRet = false;
            try
            {
                if (CurrentEarning != null)
                {
                    CurrentEarning.AccountPlan = ((editorEarningAccountPlan.SelectedItem == null) ? null : (CAccountPlan)editorEarningAccountPlan.SelectedItem);
                    CurrentEarning.BudgetProjectDst = ((editorEarningProjectDst.SelectedItem == null) ? null : (CBudgetProject)editorEarningProjectDst.SelectedItem);

                    bRet = true;
                }
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show(
                    "SetEarningProperties.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }


            return bRet;
        }

        private void btnCancel_Click(object sender, EventArgs e)
        {
            DialogResult = System.Windows.Forms.DialogResult.Cancel;
            Close();
        }

        private void btnSave_Click(object sender, EventArgs e)
        {
            try
            {
                if (SetEarningProperties() == true)
                {
                    DialogResult = System.Windows.Forms.DialogResult.OK;
                    Close();
                }
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show(
                    "btnSave_Click.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }

            return;
        }
    }
}
