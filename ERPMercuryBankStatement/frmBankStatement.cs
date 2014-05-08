using System;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
using System.Globalization;
using System.Data;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Windows.Forms;
using ERP_Mercury.Common;

namespace ERPMercuryBankStatement
{
    public enum enBank
    {
        Unkown = -1,
        Paritet = 0,
        Zepter = 1
    };

    public partial class frmBankStatement : Form
    {
        #region Свойства
        //---
        private UniXP.Common.CProfile m_objProfile;
        private UniXP.Common.MENUITEM m_objMenuItem;
        private enumPaymentType m_enumPaymentType;

        private CEarning m_objSelectedEarning;
        ////private CCurrency m_objCurrency;


        private System.Boolean m_bIsChanged;

        private System.Boolean m_bDisableEvents;
        private System.Boolean m_bNewEarning;
        private System.Boolean m_bIsReadOnly;

        private const System.Int32 iMinControlItemHeight = 20;
        private const System.Int32 iPanel1WidthDef = 350;

        //private DateTime dtBarValue;
        //---

        public List<ERP_Mercury.Common.CEarning> m_objEarningList;
        public CEarning m_objEarningImport;
        public List<CEarning> m_objEarningImportList;

        public CEarning objEaImp; //= new CEarning(); (CEarning) m_objEarningImport.Clone();
        public CEaL objEaL;

        //private ERP_Mercury.Common.CCurrencyRate m_objSelectedEarning;

        public System.Boolean IsChanged
        {
            get { return m_bIsChanged; }
        }
        //private System.Boolean m_bIsNew;

        //private System.Boolean m_bOnlyView;
        //private bool bStartProg;
        private System.DateTime dtB = System.DateTime.Now.Date, dtE = System.DateTime.Now.Date;
        private System.Guid guidCompany;
        private StreamReader sr = StreamReader.Null;
        private System.Guid guigTemp = System.Guid.Empty;
        private System.String strAccountCompany = "", strCopanyName = "", strBankCodMain="";
        private List<string> listFreeAccount = new List<string>();
        //private bool bflDeInit=false;
        private System.Int32 iResEa;
        private CEarning objEarningForSaveEa;
        private System.String strErrEa = "";
        public int iK = 0;
      #endregion

        #region События
        // Создаем закрытое поле, ссылающееся на заголовок списка делегатов
        private EventHandler<ChangeEarningPropertieEventArgs> m_ChangeEarningProperties;
        // Создаем в классе член-событие
        public event EventHandler<ChangeEarningPropertieEventArgs> ChangeEarningProperties
        {
            add
            {
                // берем закрытую блокировку и добавляем обработчик
                // (передаваемый по значению) в список делегатов
                m_ChangeEarningProperties += value;
            }
            remove
            {
                // берем закрытую блокировку и удаляем обработчик
                // (передаваемый по значению) из списка делегатов
                m_ChangeEarningProperties -= value;
            }
        }
        /// <summary>
        /// Инициирует событие и уведомляет о нем зарегистрированные объекты
        /// </summary>
        /// <param name="e"></param>
        protected virtual void OnChangeEarningProperties(ChangeEarningPropertieEventArgs e)
        {
            // Сохраняем поле делегата во временном поле для обеспечение безопасности потока
            EventHandler<ChangeEarningPropertieEventArgs> temp = m_ChangeEarningProperties;
            // Если есть зарегистрированные объектв, уведомляем их
            if (temp != null) temp(this, e);
        }
        public void SimulateChangeEarningProperties(CEarning objEarning, enumActionSaveCancel enActionType, System.Boolean bIsNewEarning)
        {
            // Создаем объект, хранящий информацию, которую нужно передать
            // объектам, получающим уведомление о событии
            ChangeEarningPropertieEventArgs e = new ChangeEarningPropertieEventArgs(objEarning, enActionType, bIsNewEarning);

            // Вызываем виртуальный метод, уведомляющий наш объект о возникновении события
            // Если нет типа, переопределяющего этот метод, наш объект уведомит все объекты, 
            // подписавшиеся на уведомление о событии
            OnChangeEarningProperties(e);
        }
        #endregion

        #region Конструктор
        public frmBankStatement(UniXP.Common.CProfile objProfile, UniXP.Common.MENUITEM objMenuItem)
        {
            System.Globalization.CultureInfo ci = new System.Globalization.CultureInfo("ru-RU");
            ci.NumberFormat.CurrencyDecimalSeparator = ".";
            ci.NumberFormat.NumberDecimalSeparator = ".";
            System.Threading.Thread.CurrentThread.CurrentCulture = ci;

            InitializeComponent();
            //---
            m_objProfile = objProfile;
            m_objMenuItem = objMenuItem;
            m_bIsChanged = false;
            m_bDisableEvents = false;
            m_bNewEarning = false;
            m_enumPaymentType = enumPaymentType.PaymentForm1;

            m_objSelectedEarning = null;

            LoadComboBoxItems();
            m_bIsReadOnly = false;
            CheckClientsRight();

            SetModeReadOnly(true);

            ShowWarningPnl(false);

            dtB = System.DateTime.Now.Date;
            dtE = System.DateTime.Now.Date;

            deBegin.EditValue = dtB; // System.DateTime.Now.Date;
            deEnd.EditValue = dtE;                       // System.DateTime.Now.Date; 

            TabControl.ShowTabHeader = DevExpress.Utils.DefaultBoolean.False;

            //deCurDate.Enabled = true;
            deBegin.Enabled = true;
            deEnd.Enabled = true;
          
            DateBar.Visible = true;
            EnableRemoveButton(false);
            VisibleProgressBar(false);
        }
        #endregion

        #region Проверка динамических прав
        /// <summary>
        /// Проверка динамических прав
        /// </summary>
        private void CheckClientsRight()
        {
            try
            {
                if (m_objProfile.GetClientsRight().GetState(ERP_Mercury.Global.Consts.strDR_ViewEarning) == false)
                {
                    btnEdit.Visible = false;
                    btnPrint.Visible = false;
                    btnSave.Visible = false; //*
                    DateBar.Visible = false;
                }
                else
                {
                    //btnEdit.Visible = true;
                    //btnPrint.Visible = true;
                    btnSave.Visible = true;//*
                    DateBar.Visible = true;
                }
                //objClientRights = null;
            }
            catch (System.Exception f)
            {
                SendMessageToLog("CheckClientsRight. Текст ошибки: " + f.Message);
            }
            finally
            {
            }
            return;
        }

        #endregion

        #region Обновление выпадающих списков
        /// <summary>
        /// Обновление выпадающих списков
        /// </summary>
        /// <returns>true - все списки успешно обновлены; false - ошибка</returns>
        public System.Boolean LoadComboBoxItems()
        {
            System.Boolean bRet = false;
            try
            {
                // Клиенты
                reItemcboxEarningCustomer.Items.Clear();
                List<CCustomer> objCustomerList = CCustomer.GetCustomerList(m_objProfile, null) ;
                if (objCustomerList != null)
                {
                    //----
                    objCustomerList.Add(new CCustomer(System.Guid.Empty, 0, "0", "", "--- Клиент не найден ---", "0", "0", "0", null, null));
                    //----

                    //reItemcboxEarningCustomer.Items.AddRange(objCustomerList);

                    reItemLookUpEarningCustomer.DataSource = objCustomerList;
                    reItemLookUpEarningCustomer.Columns.AddRange(new DevExpress.XtraEditors.Controls.LookUpColumnInfo[] { 
                        new DevExpress.XtraEditors.Controls.LookUpColumnInfo("FullName", "Клиент", 30, DevExpress.Utils.FormatType.None, "", true, DevExpress.Utils.HorzAlignment.Default, DevExpress.Data.ColumnSortOrder.None) });
                    reItemLookUpEarningCustomer.DisplayMember = "FullName"; // поле для отображения
                    reItemLookUpEarningCustomer.ValueMember = "ID"; // поле для связи
                    //reItemLookUpEarningCustomer.NullText = "[Выберите клиента]";

                    // перенсено в дизайнер
                    //cEarningImpCustomer.FieldName = "ID"; 
                }
                
               
                // банки
                repItemcboxCodeBank.Items.Clear();
                List<CBank> objBankList = CBank.GetBankList(m_objProfile, null, null);
                if (objBankList != null)
                {
                    //repItemcboxCodeBank.Items.AddRange(objBankList);

                    reItemLookUpEarningCodBank.DataSource = objBankList;
                    reItemLookUpEarningCodBank.Columns.AddRange(new DevExpress.XtraEditors.Controls.LookUpColumnInfo[] { 
                        new DevExpress.XtraEditors.Controls.LookUpColumnInfo("Code", "Код", 5, DevExpress.Utils.FormatType.None, "", true, DevExpress.Utils.HorzAlignment.Default, DevExpress.Data.ColumnSortOrder.None),
                        new DevExpress.XtraEditors.Controls.LookUpColumnInfo("Name", "Банк", 30, DevExpress.Utils.FormatType.None, "", true, DevExpress.Utils.HorzAlignment.Default, DevExpress.Data.ColumnSortOrder.None)
                    });

                    reItemLookUpEarningCodBank.DisplayMember = "Code";
                    reItemLookUpEarningCodBank.ValueMember = "Code";
                    reItemLookUpEarningCodBank.NullText = "[Выберите код банка]";

                    // перенсено в дизайнер
                    //сEarningCodeBank.FieldName = "Code";

                }

                // Компании в СBox сверху 
                repItemcBoxCompany.Items.Clear();
                List<CCompany> objCompanyList = CCompany.GetCompanyListActive(m_objProfile, null);
                if (objCompanyList != null)
                {
                    repItemcBoxCompany.Items.AddRange(objCompanyList);
                }

                System.String strErr = System.String.Empty;

                editorEarningAccountPlan.Properties.Items.Clear();
                editorEarningAccountPlan.Properties.Items.AddRange(CAccountPlanDataBaseModel.GetAccountPlanList(m_objProfile, null, ref strErr));

                editorEarningProjectDst.Properties.Items.Clear();
                editorEarningProjectDst.Properties.Items.AddRange(CBudgetProjectDataBaseModel.GetBudgetProjectList(m_objProfile, null, ref strErr));

                if (m_enumPaymentType == enumPaymentType.PaymentForm1)
                {
                    List<CPaymentType> objPaymentTypeList = CPaymentType.GetPaymentTypeList(m_objProfile, null, System.Guid.Empty).Where<CPaymentType>(x => x.Payment_Id.Equals(1)).ToList<CPaymentType>();
                    if ((objPaymentTypeList != null) && (objPaymentTypeList.Count > 0))
                    {
                        LoadAccountPlanForPaymentType(objPaymentTypeList[0].ID);
                    }
                }


                bRet = true;
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка обновления выпадающих списков.\n Текст ошибки: " + f.Message);
            }
            finally
            {
            }

            return bRet;
        }

        /// <summary>
        /// Устанавливает значение по умолчанию для плана счетов и проекта-назначения
        /// </summary>
        /// <param name="uuidPaymentTypeId">УИ формы оплаты</param>
        private void LoadAccountPlanForPaymentType(System.Guid uuidPaymentTypeId)
        {
            try
            {
                System.String ACCOUNTPLAN_1C_CODE = System.String.Empty;
                System.Guid ACCOUNTPLAN_GUID = System.Guid.Empty;
                System.String BUDGETPROJECT_DST_NAME = System.String.Empty;
                System.Guid BUDGETPROJECT_DST_GUID = System.Guid.Empty;
                System.String COMPANY_ACRONYM = System.String.Empty;
                System.Int32 ERROR_NUM = 0;
                System.String strErr = System.String.Empty;

                if (CPaymentDataBaseModel.GetEarningSettingsDefault(m_objProfile, null,
                        uuidPaymentTypeId, ref ACCOUNTPLAN_1C_CODE, ref ACCOUNTPLAN_GUID,
                        ref BUDGETPROJECT_DST_NAME, ref BUDGETPROJECT_DST_GUID, ref COMPANY_ACRONYM,
                        ref ERROR_NUM, ref strErr) == 0)
                {
                    editorEarningAccountPlan.SelectedItem = (ACCOUNTPLAN_GUID.CompareTo(System.Guid.Empty) == 0) ? null : editorEarningAccountPlan.Properties.Items.Cast<CAccountPlan>().SingleOrDefault<CAccountPlan>(x => x.ID.CompareTo(ACCOUNTPLAN_GUID) == 0);
                    editorEarningProjectDst.SelectedItem = (BUDGETPROJECT_DST_GUID.CompareTo(System.Guid.Empty) == 0) ? null : editorEarningProjectDst.Properties.Items.Cast<CBudgetProject>().SingleOrDefault<CBudgetProject>(x => x.ID.CompareTo(BUDGETPROJECT_DST_GUID) == 0);
                }

            }
            catch (System.Exception f)
            {
                SendMessageToLog(String.Format("LoadAccountPlanForPaymentType. Текст ошибки: {0}", f.Message));
            }
            finally
            {
            }

            return;

        }


        #endregion

        #region Индикация изменений
        private void SetPropertiesModified(System.Boolean bModified)
        {
            //ValidateProperties();
            //if (m_bIsChanged == bModified) { return; }
            m_bIsChanged = bModified;
            btnSave.Enabled = m_bIsChanged;//*
            btnCancel.Enabled = btnSave.Enabled;//*
            if (m_bIsChanged == true)
            {
                SimulateChangeEarningProperties(m_objSelectedEarning, enumActionSaveCancel.Unkown, m_bNewEarning);
            }
        }
        #endregion

        #region Валидация
        public System.Boolean IsCtrlParamValid(ref System.String strErr)
        {
            System.Boolean bRet = false;
            try
            {

                if (trListEarningImport.Nodes.Count > 0)
                {
                    foreach (DevExpress.XtraTreeList.Nodes.TreeListNode objItem in trListEarningImport.Nodes)
                    {
                        // Проверка на заполнение кода банка
                        if (System.String.IsNullOrEmpty(Convert.ToString(objItem.GetValue(сEarningImpCodeBank))))
                        {
                            trListEarningImport.SetFocusedNode(objItem);
                            trListEarningImport.SetColumnError(сEarningImpCodeBank, "Код банка не заполнен");
                            strErr = "Код банка не заполнен";
                            return bRet;
                        }
                        
                        // Проверка на заполнение клиента
                        if (System.String.IsNullOrEmpty(Convert.ToString(objItem.GetValue(cEarningImpCustomer))))
                        {
                            trListEarningImport.SetFocusedNode(objItem);
                            trListEarningImport.SetColumnError(cEarningImpCustomer, "Не выбран клиент");
                            strErr = "Не выбран клиент";
                            return bRet;
                        }

                    }                
                }

                bRet = true;

            }
            catch (System.Exception f)
            {
                strErr = "Ошибка валидации свойств TreeList. Текст ошибки: " + f.Message;
            }
            return bRet;
        }
        #endregion

        #region Выписки
        /// <summary>
        /// Добавляет в список курсы валют
        /// </summary>
        /*
        private void AddEarning()
        {
            try
            {
                //if (treelistEarning.Enabled == false) { treelistEarning.Enabled = true; }
                if (m_objSelectedEarning.EarningList == null) { m_objSelectedEarning.EarningList = new List<CEarning>(); }
                System.Boolean bNotFullNode = false;
                foreach (DevExpress.XtraTreeList.Nodes.TreeListNode objItem in treelistEarning.Nodes)
                {
                    //if ((System.String)objItem.GetValue(cCurrRateValue) == "")
                    if (Convert.ToString(objItem.GetValue(cEarningValue)) == "")
                    {
                        treelistEarning.FocusedNode = objItem;
                        bNotFullNode = true;
                        break;
                    }
                }
                if (bNotFullNode == true) { return; }

                CEarning objEarning = new CEarning();

                //objEarning.CurRateDate = DateTime.Today.Date;  //.IsMain = false;
                //objEarning.CurrencyIsPricing = false;
                DevExpress.XtraTreeList.Nodes.TreeListNode objNode = treelistEarning.AppendNode(new object[] { objEarning.DocNom, objEarning.CodeBank, objEarning.AccountNumber, objEarning.Value, objEarning.CustomrText, objEarning.DetailsPayment }, null);
                objNode.Tag = objEarning;
                treelistEarning.FocusedNode = objNode;
                SetPropertiesModified(true);
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка добавления выписки в список. Текст ошибки: " + f.Message);
            }
            finally
            {
            }
            return;
        }
        */

        /// <summary>
        /// Удаляет выписку из списка
        /// </summary>
        /// <param name="objNode">удаляемый узел в дереве</param>
        private void DeleteEarningCo(DevExpress.XtraTreeList.Nodes.TreeListNode objNode)
        {
            try
            {
                if ((objNode == null) || (trListEarningImport.Nodes.Count == 0)) { return; }

                if (m_objSelectedEarning.EarningForDeleteList == null) { m_objSelectedEarning.EarningForDeleteList = new List<CEarning>(); }
                DevExpress.XtraTreeList.Nodes.TreeListNode objPrevNode = objNode.PrevNode;
                m_objSelectedEarning.EarningForDeleteList.Add((CEarning)objNode.Tag);

                // при удалении строки из treeList? удаляем и возможную запись из listFreeAccount
                RemoveItemFreeAccountList(((CEarning)objNode.Tag).AccountNumber);
                
                trListEarningImport.Nodes.Remove(objNode);
                if (objPrevNode == null)
                {
                    if (trListEarningImport.Nodes.Count > 0)
                    {
                        trListEarningImport.FocusedNode = trListEarningImport.Nodes[0];
                    }
                }
                else
                {
                    trListEarningImport.FocusedNode = objPrevNode;
                }

                SetPropertiesModified(true);
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка удаления платежа из выписки. Текст ошибки: " + f.Message);
            }
            finally
            {
            }
            return;
        }

        /// <summary>
        /// Выполняет проверку кода банка
        /// </summary>
        /// <param name="strBankCode">код банка</param>
        /// <returns>true - ошибок нет; false - номер расчетного счета не соответсвует установленным требованиям</returns>
        private System.Boolean IsCodeBankValid (System.String strBankCode)
        {
            System.Boolean bRet = false;
            try
            {
                if ((strBankCode == "") || (System.String.IsNullOrEmpty(strBankCode))) { return bRet; }

                bRet = true;
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка проверки значения кода банка. Текст ошибки: " + f.Message);
            }
            finally
            {
            }
            return bRet;
        }


        private void RemoveItemFreeAccountList(string strAccount)
        {
            try
            {
                int idel = -1;
                idel = listFreeAccount.FindIndex(s => s == strAccount);
                if (idel != -1)
                {
                    listFreeAccount.Remove(strAccount);
                }
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка удаления записи из listFreeAccount. Текст ошибки: " + f.Message);
            }
        }

     
        #endregion
        
        #region Журнал сообщений
        private void SendMessageToLog(System.String strMessage)
        {
            try
            {
                m_objMenuItem.SimulateNewMessage(strMessage);
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show(
                    "SendMessageToLog.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }

            return;
        }
        private void SetWarningInfo(System.String strMessage)
        {
            try
            {
                lblWarningInfo.Text = strMessage;
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show(
                    "SetWarningInfo.\n Текст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
        }
        private void ShowWarningPnl(System.Boolean bShow)
        {
            System.Int32 iRowWarnigHeith = 40;//45
            System.Int32 iRowBtnHeith = 30;
            try
            {
                if (bShow == true)
                {
                    tableLayoutPanel5.RowStyles[0].Height = iRowWarnigHeith;
                }
                else
                {
                    tableLayoutPanel5.RowStyles[0].Height = 0;
                }
                tableLayoutPanel5.Size = new Size(tableLayoutPanel5.Size.Width,
                    (System.Convert.ToInt32(tableLayoutPanel5.RowStyles[0].Height + iRowBtnHeith)));
                tableLayoutPanel5.Refresh();
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show(
                    "ShowWarningPnl.\n Текст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
        }
        #endregion

        #region Загрузка списка выписок
        /// <summary>
        /// Загружаем список выписок
        /// </summary>
        /// <returns>true - удачное завершение операции; false - ошибка</returns>
        public System.Boolean LoadEarningList()
        {
            System.Boolean bRet = false;
            this.Cursor = Cursors.WaitCursor;
            try
            {
                treelistEarning.Nodes.Clear();
                m_objEarningList = ERP_Mercury.Common.CEarning.GetEarningList(m_objProfile, null, dtB, dtE, guidCompany);

                foreach (ERP_Mercury.Common.CEarning objEarning in m_objEarningList)
                {
                    DevExpress.XtraTreeList.Nodes.TreeListNode objNode = treelistEarning.AppendNode(new object[] {objEarning.Date, objEarning.DocNom, 
                        objEarning.CodeBank, objEarning.AccountNumber, objEarning.Value, objEarning.Expense, 
                        objEarning.Saldo, (objEarning.Customer).ToString().Trim(), objEarning.CustomrText, objEarning.DetailsPayment }, null);
                    objNode.Tag = objEarning;
                }
                bRet = true;
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка обновления списка валют. Текст ошибки: " + f.Message);
            }
            finally
            {
                this.Cursor = Cursors.Default;
                //TabControl.SelectedTabPage = tabViewer;
                this.Refresh();
            }
            return bRet;
        }

        //#endregion

        //#region Редактировать курсы валют
        /// <summary>
        /// Возвращает ссылку на выбранного в списке поставщика
        /// </summary> 
        /// <returns>ссылка на компанию</returns>
        private ERP_Mercury.Common.CEarning GetSelectedEarning()
        {
            ERP_Mercury.Common.CEarning objRet = null;
            try
            {
                /*var ty = treelistEarning.Nodes[1].Tag;
                var y = (treelistEarning.Nodes.TreeList.FocusedNode).Tag ;*/

                if (treelistEarning.Nodes.Count > 0)
                {
                    System.Int32 strInterBaseID = (((CEarning)treelistEarning.Nodes.TreeList.FocusedNode.Tag).InterBaseID);
                    System.Guid uuidID = (((CEarning)treelistEarning.Nodes.TreeList.FocusedNode.Tag).ID);

                    if ((m_objEarningList != null) && (m_objEarningList.Count > 0) && (uuidID.CompareTo(System.Guid.Empty) != 0))
                    {
                        foreach (ERP_Mercury.Common.CEarning objEarning in m_objEarningList)
                        {
                            if (objEarning.ID.CompareTo(uuidID) == 0)
                            {
                                objRet = objEarning;
                                break;
                            }
                        }
                    }
                }

            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка поиска выбранного курса валюты. Текст ошибки: " + f.Message);
            }
            finally
            {
            }
            return objRet;
        }
        #endregion

        #region Настройка свойств элементов управления
        
        //private void ShowTreeLisrIB(System.Boolean bShow)
        //{
        //    //System.Int32 iRowWarnigHeith = 145;
        //    //System.Int32 iRowBtnHeith = 130;
        //    //System.Int32 iRowTrIbHeithSt = 80;
        //    //System.Single iRowTrMainHeithHalf, iRowTrMainHeithDouble;
        //    //System.Single iRowTrIbHeith = Convert.ToSingle(tableLayoutPanel1.RowStyles[1].Height);
        //    //System.Single iRowTrIbHeith = Convert.ToSingle(tableLayoutPanel1.RowStyles[1].Height);

        //    tableLayoutPanel1.RowStyles[0].SizeType = SizeType.Percent; // Main
        //    tableLayoutPanel1.RowStyles[1].SizeType = SizeType.Percent; // IB

        //    try
        //    {
        //        if (bShow == true)
        //        {
        //            tableLayoutPanel1.RowStyles[0].Height = 50;
        //            tableLayoutPanel1.RowStyles[1].Height = 50;
        //            //groupPaymentInfo.Visible = bShow;
        //            //groupPaymentInfo.Visible = bShow;

        //            /*
        //            iRowTrMainHeithHalf= (tableLayoutPanel1.RowStyles[0].Height)/2;
        //            tableLayoutPanel1.RowStyles[0].Height = iRowTrMainHeithHalf;
        //            tableLayoutPanel1.RowStyles[1].Height = iRowTrMainHeithHalf;
        //            groupPaymentInfo.Visible = bShow;
        //            */
        //            //--------------------------------
        //            /*
        //            tableLayoutPanel1.RowStyles[1].Height = iRowTrIbHeithSt;
        //            tableLayoutPanel1.RowStyles[0].Height -= iRowTrIbHeithSt; //iRowTrIbHeith;
        //            groupPaymentInfo.Visible = bShow;
        //            */
        //        }
        //        else
        //        {
        //            tableLayoutPanel1.RowStyles[0].Height = 100;
        //            tableLayoutPanel1.RowStyles[1].Height = 0;
        //            //groupPaymentInfo.Visible = bShow;

        //            /*
        //            iRowTrMainHeithDouble = tableLayoutPanel1.RowStyles[0].Height*2;
        //            tableLayoutPanel1.RowStyles[1].Height = 0;
        //            tableLayoutPanel1.RowStyles[0].Height = iRowTrMainHeithDouble;
        //            groupPaymentInfo.Visible = bShow;
        //             */
        //            //-------------------------------
        //            /*
        //            tableLayoutPanel1.RowStyles[1].Height = 0;
        //            tableLayoutPanel1.RowStyles[0].Height += iRowTrIbHeith;
        //            groupPaymentInfo.Visible = bShow;
        //            */
        //        }
        //        /*
        //        tableLayoutPanel1.Size = new Size(tableLayoutPanel1.Size.Width,
        //            (System.Convert.ToInt32(tableLayoutPanel5.RowStyles[1].Height + iRowTrIbHeithSt)));
        //        */
        //        tableLayoutPanel1.Refresh();
        //    }
        //    catch (System.Exception f)
        //    {
        //        DevExpress.XtraEditors.XtraMessageBox.Show(
        //            "ShowWarningPnl.\n Текст ошибки: " + f.Message, "Ошибка",
        //           System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
        //    }
        //} 

        private void EnableControlOnBar(System.Boolean bBar)
        {
            cBoxBank.Enabled = bBar;
            btnOpen.Enabled = bBar;
        }

        private void EnableDEBegEnd(System.Boolean bBar)
        {
            deBegin.Enabled = bBar;
            deEnd.Enabled = bBar;
            cboxCompany.Enabled = bBar;
        }
        #endregion
        
        #region Новая выписка (импорт выписки)
        /// <summary>
        /// Новая выписка (только инициализация) (импорт выписки)
        /// </summary>
        public void NewEarning()
        {
            m_bDisableEvents = true;
            m_bNewEarning = true;

            try
            {
                ShowWarningPnl(false);
                EnableControlOnBar(true);
                //ShowOpenFileBar(true);
                EnableDEBegEnd(false);
                //ClearAllTreeList(false);

                this.Refresh();

                m_objSelectedEarning = new ERP_Mercury.Common.CEarning();

                if (m_objSelectedEarning.EarningForDeleteList == null) { m_objSelectedEarning.EarningForDeleteList = new List<CEarning>(); }
                else { m_objSelectedEarning.EarningForDeleteList.Clear(); }


                this.SuspendLayout();

                treelistEarning.Nodes.Clear();
                trListEarningImport.Nodes.Clear();
                
                SetModeReadOnly(false);
                btnEdit.Enabled = false;
                SetPropertiesModified(true);
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка создания клиента. Текст ошибки: " + f.Message);
            }
            finally
            {
                this.ResumeLayout(false);
                m_bDisableEvents = false;
                m_bNewEarning = false;
            }
            return;
        }
        #endregion

        #region Сохранить изменения
        /// <summary>
        /// Сохраняет изменения в базе данных
        /// </summary>
        /// <returns>true - удачное завершение операции;false - ошибка</returns>
        
        private System.Boolean bSaveChanges()
        {
            System.Boolean bRet = false;
            System.Boolean bOkSave = false;
            System.Int32 iRes;
            //System.Int32 i=0;
            CEarning objEarningForSave = new CEarning();
            objEarningForSaveEa = new CEarning();
            VisibleProgressBar(true);
            EanbledButtonOkCansel(true);
            
            //frmWait form = new frmWait();
            //---
            try
            {
                if (objEarningForSave.EarningList == null) { objEarningForSave.EarningList = new List<CEarning>(); }
                if (objEarningForSave.AccountList == null) { objEarningForSave.AccountList = new List<CAccount>(); }

                if (objEarningForSaveEa.EarningList == null) { objEarningForSaveEa.EarningList = new List<CEarning>(); }
                if (objEarningForSaveEa.AccountList == null) { objEarningForSaveEa.AccountList = new List<CAccount>(); }

                trListEarningImport.MoveFirst();
                foreach (DevExpress.XtraTreeList.Nodes.TreeListNode objNode in trListEarningImport.Nodes)
                {
                    if (objNode.Tag == null) { continue; }

                    objEarningForSave.EarningList.Add((CEarning)objNode.Tag);
                }

                CEarning eaList = new CEarning();
                CAccount accountTemp = new CAccount();
                int i = 0;

                foreach (var ea in objEarningForSave.EarningList)
                {
                    foreach (var faList in listFreeAccount)
                    {
                        eaList.AccountNumber = ea.AccountNumber;
                        if (eaList.AccountNumber==faList && ea.Customer.ID != Guid.Empty )
                        {
                            CBank objBabk = GetBankByBankCod(ea.CodeBank); // получаем объект CBank по его коду
                            CAccountType objAccountType = GetAccountType();

                            if (objBabk!=null && objAccountType != null )
                            {

                                if (objEarningForSave.EarningList[i].AccountList == null)
                                {
                                    objEarningForSave.EarningList[i].AccountList = new List<CAccount>();
                                }

                                accountTemp = new CAccount(System.Guid.Empty, objBabk, ea.Currency, eaList.AccountNumber, "р/с добавлен при импорте выписки",objAccountType, false); ;
                                objEarningForSave.EarningList[i].AccountList.Add(accountTemp);
                            }
                            else
                            {
                                MessageBox.Show("Не удалось определить код банка и тип р/с. Продолжение работы невозможно.");
                                return bRet;
                                // ошибка. НЕ проводить импорт.
                            }
                        }
                    }
                    i++;
                }


                objEarningForSave.EarningForDeleteList = m_objSelectedEarning.EarningForDeleteList;
                
                //objEarningForSave.AccountList = eaList.AccountList; // ???

                System.String strErr = "";
                strErrEa = "";
                if (m_bNewEarning == true)
                {
                    //bOkSave = objEarningForSave.Add(m_objProfile);
                    if ((objEarningForSave.EarningList != null) && (objEarningForSave.EarningList.Count > 0))
                    {
                        foreach (CEarning objEarning in objEarningForSave.EarningList) { objEarning.ID = System.Guid.Empty; }
                        //iRes = (CEarning.SaveEarningList(objEarningForSave.EarningList, null, m_objProfile, null, ref strErr) == true) ? 0 : -1; // ориганальный вариант
                        //iRes = (SaveEarningListCEa(objEarningForSave.EarningList, null, m_objProfile, null, ref strErr) == true) ? 0 : -1; // ориганальный вариант

                        objEarningForSaveEa = objEarningForSave;
    
                        //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                        //RunWorkerAsync() вызывет событие DoWork и управление передаётся в обработчик события backgroundWorker_DoWork. Весь код
                        // который написан в обработчике backgroundWorker_DoWork запускается как асинхронная задача в отдельном потоке.

                        backgroundWorker.RunWorkerAsync();
                        // Для отладки -- закоментить работу с потоками в этих {} и раскоментить строчку ниже
                        //iResEa = (SaveEarningListCEa(objEarningForSaveEa.EarningList,null, m_objProfile, null, GetKey(), ref strErrEa) == true) ? 0 : -1;
                        //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                        while (backgroundWorker.IsBusy)
                        {
                            //Thread.Sleep(200);
                            Application.DoEvents();
                        }
                        
                        //MessageBox.Show("Управление вернулось в основной поток");
                        //MessageBox.Show(strErr);
                        
                        iRes = iResEa;
                        strErr=strErrEa;

                        bOkSave = (iRes == 0) ? true : false; // ориганальное написанте

                        //bOkSave = (iResEa == 0) ? true : false;
                        //SendMessageToLog(strErr);
                        //backgroundWorker.ReportProgress(100/objEarningForSave.EarningList.Count);
                    }
                }

                //SendMessageToLog(strErr);
                if (bOkSave == true)
                {
                    // проверить как работает эта строка
                    //m_objSelectedCurrencyRate.CurrRateList = objEarningForSave.CurrRateList;
                    m_objSelectedEarning.EarningList = objEarningForSave.EarningList;

                    ShowWarningPnl(false);
                    bRet = true;
                }
                else
                {
                    SetWarningInfo(strErr);
                    ShowWarningPnl(true);
                }
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка сохранения изменений в выписке. Текст ошибки: " + f.Message);
            }
            finally
            {
                objEarningForSave = null;
                EanbledButtonOkCansel(true);
                //VisibleProgressBar(false);
            }
            return bRet;
        }

        /// <summary>
        /// Обработучик события DoWork. Весь код обработчика запускается как асинхранная задача в отдельном потоке
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void backgroundWorker_DoWork(object sender, DoWorkEventArgs e)
        {
            //MessageBox.Show("Начинает работать отдельный поток DoWork");
            // для работы с потоками раскоментировать
            iResEa = (SaveEarningListCEa(objEarningForSaveEa.EarningList, null, m_objProfile, null, GetKey(), ref strErrEa) == true) ? 0 : -1;
            //MessageBox.Show("Результат работы" + iResEa.ToString() + " Вернулись ошибки:" + strErrEa.ToString()); 
        }

        private void backgroundWorker_ProgressChanged(object sender, ProgressChangedEventArgs e)
        {
            OnProgressChanged(sender, e);
        }

        private void backgroundWorker_RunWorkerCompleted(object sender, RunWorkerCompletedEventArgs e)
        {
            OnWorkCompleted(sender, e);
        }

        private void OnWorkCompleted(object sender, RunWorkerCompletedEventArgs e)
        {
            if (iResEa==0)
            {
                progressBar.EditValue = 100;   
            }
            VisibleProgressBar(false);
        }

        private void OnProgressChanged(object sender, ProgressChangedEventArgs e)
        {
            // инкремент значения progressBar на велечину e.ProgressPercentage
            progressBar.EditValue = e.ProgressPercentage;
        }

        private void EanbledButtonOkCansel(System.Boolean bState)
        {
            btnSave.Enabled = bState;
            btnCancel.Enabled = bState;
        }
        
        /// <summary>
        /// Сохраняет в БД список выписок
        /// </summary>
        /// <param name="objEarningList">список выписок для сохранения</param>
        /// <param name="objEarningForDeleteList">список выписок для удаления</param>
        /// <param name="objProfile">профайл</param>
        /// <param name="cmdSQL">SQL-команда</param>
        /// <param name="strErr">сообщение об ошибке</param>
        /// <returns>true - удачное завершение; false - ошибка</returns>
        public System.Boolean SaveEarningListCEa(List<CEarning> objEarningList, List<CEarning> objEarningForDeleteList, 
            UniXP.Common.CProfile objProfile, System.Data.SqlClient.SqlCommand cmdSQL, 
            System.Int32 iKey, ref System.String strErr)
        {
            if ((objEarningList == null) && (objEarningForDeleteList == null)) { return true; }
            System.Boolean bRet = false;
            System.Int32 nEac = 0, j=0;
            System.Boolean EmptyCustomer = false;
            System.Data.SqlClient.SqlConnection DBConnection = null;
            System.Data.SqlClient.SqlCommand cmd = null;
            System.Data.SqlClient.SqlTransaction DBTransaction = null;
            try
            {
                // для начала проверим, что нам пришло в списке
                if ((objEarningList != null) && (objEarningList.Count > 0))
                {
                    System.Boolean bIsAllValid = true;
                    foreach (CEarning objItem in objEarningList)
                    {
                        if (objItem.IsAllParametersValid(true, ref strErr) == false)
                        {
                            if (strErr == "Не указан клиент !")
                            {
                                EmptyCustomer = true;
                            }
                            else
                            {
                                bIsAllValid = false;
                                break;
                            }
                        }
                    }
                    if (bIsAllValid == false)
                    {
                        return bRet;
                    }

                    if (EmptyCustomer)
                    {
                        DialogResult mes = MessageBox.Show("Обнаружены проводки, у которых не указан клиент. Импортировать выписку в таком виде ?", "Не указан клиент", MessageBoxButtons.YesNo, MessageBoxIcon.Question, MessageBoxDefaultButton.Button2);
                        if (mes == DialogResult.No)
                        {
                            bIsAllValid = false;
                            return bRet;
                        }
                    }
                }

                if (cmdSQL == null)
                {
                    DBConnection = objProfile.GetDBSource();
                    if (DBConnection == null)
                    {
                        strErr = "Не удалось получить соединение с базой данных.";
                        return bRet;
                    }
                    DBTransaction = DBConnection.BeginTransaction();
                    cmd = new System.Data.SqlClient.SqlCommand();
                    cmd.Connection = DBConnection;
                    cmd.Transaction = DBTransaction;
                    cmd.CommandType = System.Data.CommandType.StoredProcedure;
                }
                else
                {
                    cmd = cmdSQL;
                    cmd.Parameters.Clear();
                }

                System.Int32 iRes = 0;
                if ((objEarningForDeleteList != null) && (objEarningForDeleteList.Count > 0))
                {
                    foreach (CEarning objEarning in objEarningForDeleteList)
                    {
                        if (objEarning.ID.CompareTo(System.Guid.Empty) == 0) { continue; }
                        // Раскоментить, если будет написан метод Remove 27.01.2012
                        //iRes = (objEarning.Remove(objProfile, cmd, ref strErr, true) == true) ? 0 : 1;
                        if (iRes != 0) { break; }
                    }
                }

                if (iRes == 0)
                {
                    if ((objEarningList != null) && (objEarningList.Count > 0))
                    {
                        nEac = objEarningList.Count;
                        
                        // теперь в цикле добавим в БД каждый член из списка
                        foreach (CEarning objEarning in objEarningList)
                        {
                            /*
                            if (iK == 0)
                            {
                                objEarning.AccountList = objAccountList;
                                iK++;
                            }
                            */
                            if (objEarning.ID.CompareTo(System.Guid.Empty) == 0)
                            {
                                j++;
                                iRes = (objEarning.Add(objProfile, null, iKey, ref strErr) == true) ? 0 : -1; // ориганальный вариант
                                backgroundWorker.ReportProgress((int)(nEac * j) / 100); // отправляем в backgroundWorker отчет о ходе выполнения

                                /*if (j==objEarningList.Count-1)
                                {*/
                                    // ADD
                                    //j++;
                                    //iRes = (objEarning.Add(objProfile, null, strKey, ref strErr) == true) ? 0 : -1; // ориганальный вариант
                                    //backgroundWorker.ReportProgress((int)(nEac * j) / 100); // отправляем в backgroundWorker отчет о ходе выполнения
                                /*}
                                else
                                {
                                    // ADD
                                    j++;
                                    iRes = (objEarning.Add(objProfile, null, false, ref DBTransaction,  ref strErr) == true) ? 0 : -1; // ориганальный вариант
                                    backgroundWorker.ReportProgress((int)(nEac * j) / 100); // отправляем в backgroundWorker отчет о ходе выполнения
                                }*/
                            }
                            else
                            {
                                // UPDATE
                                //iRes = (objEarning.Update(objProfile, cmd, ref strErr) == true) ? 0 : -1;
                            }

                            if (iRes != 0) { break; }
                        }
                    }
                }

                if (cmdSQL == null)
                {
                    if (iRes == 0)
                    {
                        // подтверждаем транзакцию
                        DBTransaction.Commit();
                    }
                    else
                    {
                        // откатываем транзакцию
                        DBTransaction.Rollback();
                    }
                    DBConnection.Close();
                }

                bRet = (iRes == 0);
            }
            catch (System.Exception f)
            {
                if (cmdSQL == null)
                {
                    DBTransaction.Rollback();
                }
                strErr = f.Message;
            }
            finally
            {
                if (DBConnection != null)
                {
                    DBConnection.Close();
                }
            }
            return bRet;
        }

        #endregion

        private void VisibleProgressBar(System.Boolean bfl)
        {
            if (!bfl) progressBar.EditValue = 0;

            //MessageBox.Show("прогрес бар будет " + bfl.ToString());
            progressBar.Visible = bfl;
        }
        
        /*
        private void ClearProgressBar ()
        {
            progressBar.EditValue = 0;
        }
        */
        #region Режим просмотра/редактирования
        /// <summary>
        /// Устанавливает режим просмотра/редактирования
        /// </summary>
        /// <param name="bSet">true - режим просмотра; false - режим редактирования</param>
        public void SetModeReadOnly(System.Boolean bSet)
        {
            try
            {
                //treelistEarning.OptionsBehavior.Editable = !bSet;

                if (m_bNewEarning) // если будет происходить добавление записи, то показываем TreeLisrIB
                {
                    //ShowTreeLisrIB(true);
                }
                else
                {
                    //ShowTreeLisrIB(false);
                }

                m_bIsReadOnly = bSet;
                btnEdit.Enabled = bSet;

                btnCancel.Enabled = !bSet;
                btnSave.Enabled = !bSet;
                btnPrint.Enabled = bSet;
            }
            catch (System.Exception f)
            {
                SendMessageToLog("SetModeReadOnly. Текст ошибки: " + f.Message);
            }
            finally
            {
            }
            return;
        }
        #endregion
        
        private void deBegin_EditValueChanged(object sender, EventArgs e)
        {
            try
            {
                if (Convert.ToDateTime(deEnd.EditValue) == Convert.ToDateTime("01.01.0001"))
                {
                    LoadEarningList();
                }
                else
                {
                    dtB = Convert.ToDateTime(deBegin.EditValue); // DateTime.Date;
                    dtE = Convert.ToDateTime(deEnd.EditValue);
                    guidCompany = (cboxCompany.EditValue == null)
                                      ? System.Guid.Empty
                                      : ((CCompany) cboxCompany.EditValue).ID;
                    LoadEarningList();
                }
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка изменения даты 'с'. Текст ошибки: " + f.Message);
            }
            finally
            {
            }
        }

        private void deEnd_EditValueChanged(object sender, EventArgs e)
        {
            try
            {

                if (Convert.ToDateTime(deBegin.EditValue) == Convert.ToDateTime("01.01.0001"))
                {
                    LoadEarningList();
                }
                else
                {
                    dtB = Convert.ToDateTime(deBegin.EditValue); // DateTime.Date;
                    dtE = Convert.ToDateTime(deEnd.EditValue);
                    guidCompany = (cboxCompany.EditValue == null)
                                      ? System.Guid.Empty
                                      : ((CCompany) cboxCompany.EditValue).ID;
                    LoadEarningList();
                }
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка изменения даты 'по'. Текст ошибки: " + f.Message);
            }
            finally
            {
            }
        }

        private void cboxCompany_EditValueChanged(object sender, EventArgs e)
        {
            try
            {
                dtB = Convert.ToDateTime(deBegin.EditValue);
                dtE = Convert.ToDateTime(deEnd.EditValue);
                guidCompany = (cboxCompany.EditValue == null) ? System.Guid.Empty : ((CCompany) cboxCompany.EditValue).ID;
                LoadEarningList();
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка выбора компании. Текст ошибки: " + f.Message);
            }
            finally
            {
            }
        }

        private void EnableRemoveButton (System.Boolean bShow)
        {
            barBtnDelRow.Enabled = bShow;
        }
        
        private void barBtnImport_ItemClick(object sender, DevExpress.XtraBars.ItemClickEventArgs e)
        {
            try
            {
               this.Cursor = Cursors.WaitCursor;

                if (OpenPaymentFail())
                {
                    NewEarning();
                    AnalysisBankStatement2();
//                    AnalysisBankStatement();
                    LoadEarningCompanyStaticPanel();
                    TabControl.SelectedTabPage = tabEditor;
                    EnableRemoveButton(true);
                }
                
                /*
                if (AnalysisBankStatement())
                {
                    LoadEarningCompanyStaticPanel();
                    TabControl.SelectedTabPage = tabEditor;
                }
                */
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка импорта выписки. Текст ошибки: " + f.Message);
            }
            finally 
            {
                this.Cursor = Cursors.Default;
            }
        }
        
        /// <summary>
        /// Идентифицируем файл как банковскую выписку и определяем банк
        /// </summary>
        /// <returns></returns>
        private System.Boolean AnalysisBankStatement()
        {
            System.Boolean bRet = false;
            System.String line = "", strErr = "";
            int k = 0;
            try
            {
                while ((line = sr.ReadLine()) != null)
                {
                    if (k == 1) // для паритет-совместимой выписки
                    {
                        if (GetNumValidBank(line) == 1)
                        {
                            strErr = "";
                            ShowWarningPnl(false);

                            strBankCodMain = GetBankCodFromHeader(line); // получаем код банка
                            AnalysisParitetBakn(); // вызов метода разбора, для паритет банка
                            break;
                        }
                        if (GetNumValidBank(line) == 0)
                        {
                            strErr = "Невозможно идентифицировать файл, как банковскую выписку. Импорт невозможен.";
                            ShowWarningPnl(true);
                            SetWarningInfo(strErr);
                        }                       
                    }

                    if (k== 4) // для ЦептерБанк-совместимой выписки
                    {
                        if (GetNumValidBank(line)==2)
                        {
                            strErr = "";
                            ShowWarningPnl(false);

                            AnalysisCepterBakn();
                            break;
                        }
                        if (GetNumValidBank(line) == 0)
                        {
                            strErr = "Невозможно идентифицировать файл, как банковскую выписку. Импорт невозможен.";
                            ShowWarningPnl(true);
                            SetWarningInfo(strErr);
                        }       
                    }
                    k++;
                }
                return bRet;
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка идентификации банка. Текст ошибки: " + f.Message);
            }
            finally
            {
            }
            return bRet;
        }


        /// <summary>
        /// Идентифицируем файл как банковскую выписку и определяем банк
        /// </summary>
        /// <returns></returns>
        private System.Boolean AnalysisBankStatement2()
        {
            System.Boolean bRet = false;
            try
            {
                // определяем, что за банк указан в выписке 
                enBank enBankInFile = GetBankFromCaption(sr);
                switch (enBankInFile)
                {
                    case enBank.Unkown:
                        ShowWarningPnl(true);
                        SetWarningInfo("Невозможно идентифицировать файл, как банковскую выписку. Импорт невозможен.");
                        break;
                    case enBank.Paritet:
                        AnalysisParitetBakn(); // вызов метода разбора для паритет банка
                        bRet = true;
                        break;
                    case enBank.Zepter:
                        AnalysisCepterBakn(); // вызов метода разбора для ЦептерБанк-совместимой выписки
                        bRet = true;
                        break;
                    default:
                        break;
                }

            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка идентификации банка. Текст ошибки: " + f.Message);
            }
            finally
            {
            }
            return bRet;
        }
        
        #region Определение, какого банка выписка
        /// <summary>
        /// Считывает из файла строки и определяет, какому банку принадлежит выписка
        /// </summary>
        /// <param name="StrRead">файловый поток</param>
        /// <returns>возвращает информацию, что за банк указан в выписке</returns>
        private enBank GetBankFromCaption(StreamReader StrRead)
        {
            enBank Ret = enBank.Unkown;
            try
            {
                System.String strLine = "";

                while ((strLine = StrRead.ReadLine()) != null)
                {
                    if (GetNumValidBank(strLine) == 1)
                    {
                        Ret = enBank.Paritet;
                        break;
                    }
                    else if (GetNumValidBank(strLine) == 2)
                    {
                        Ret = enBank.Zepter;
                        break;
                    }
                }  
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Не удалось определить принадлежность выписки к банку. Текст ошибки: " + f.Message);
            }
            finally
            {
                StrRead.BaseStream.Position = 0;
            }

            return Ret;
        }

        #endregion


        #region Методы разбора

        /// <summary>
        /// Разбор выписки Паритетбанк
        /// </summary>
        private void /*System.Boolean*/ AnalysisParitetBakn()
        {
            try
            {
                //System.Boolean bRet = false;
                System.String line = ""; //, strErr = "";
                int k = 0, l = 1;
                System.String strCurrencyAbbr = "";
                System.Guid guCompanyId = System.Guid.Empty, guCurrencyId = System.Guid.Empty;
                System.DateTime dDate = System.DateTime.MinValue;
                m_objEarningImport = new CEarning();

                if (m_objEarningImport.Currency == null) { m_objEarningImport.Currency = new CCurrency(); } // Инициализируем m_objEarningListImport.Currency
                if (m_objEarningImport.Company == null){m_objEarningImport.Company = new CCompany();} // Инициализируем m_objEarningListImport.Currency
                if (m_objEarningImport.Customer == null){m_objEarningImport.Customer = new CCustomer();} // Инициализируем m_objEarningListImport.Customer
                if (m_objEarningImport.EarningList == null){m_objEarningImport.EarningList = new List<CEarning>();}

                while ((line = sr.ReadLine()) != null)
                {
                    switch (k)
                    {
                        case 0:
                            {
                                m_objEarningImport.Date = Convert.ToDateTime(GetDateBankStatement(line));
                                dDate = m_objEarningImport.Date;
                            }
                            break;
                        case 3:
                            {
                                m_objEarningImport.Currency.CurrencyAbbr = GetCurrencyBankStatement(line);// Abbr валюты
                                m_objEarningImport.Currency.ID =GetGuidCyrrencyBankStatement(GetCurrencyBankStatement(line)); // GUID валюты
                                strCurrencyAbbr = m_objEarningImport.Currency.CurrencyAbbr;
                                guCurrencyId = m_objEarningImport.Currency.ID;

                                m_objEarningImport.Company.ID =GetGuidCompanyBankStatement(GetAccountBankStatement(line)); // GUID компании
                                m_objEarningImport.Company.Name =GetCompanyNameBankStatement(GetAccountBankStatement(line)); // наименование сомпании
                                guCompanyId = m_objEarningImport.Company.ID;
                                strCopanyName = m_objEarningImport.Company.Name;

                                //m_objEarningImport.Company.AccountList.Add(GetAccountBankStatement(line).ToList());
                                strAccountCompany = GetAccountBankStatement(line);
                            }
                            break;
                        case 4:
                            {
                                GetCompanyBankStatement(line);
                            }
                            break;
                        default:
                            {
                                if (k >= 13 && GetAccountPlat(line) != "" && l == 1)
                                {
                                    m_objEarningImport.DocNom = GetDocNumPlat(line); // № документа
                                    m_objEarningImport.CodeBank = GetBankCodPlat(line); // код банка
//                                    m_objEarningImport.AccountNumber = GetAccountPlat(line); // расчетный счет
                                    m_objEarningImport.Account = new CAccount() { AccountNumber = GetAccountPlat(line) };

                                    m_objEarningImport.Customer.ID =GetGuidCustomerBankStatement(m_objEarningImport.AccountNumber,m_objEarningImport.CodeBank); // GUID клиета
                                    m_objEarningImport.Customer.ShortName =GetCustomerNameBankStatement(m_objEarningImport.AccountNumber,m_objEarningImport.CodeBank);// Наименование клиета

                                    m_objEarningImport.Value = GetSumPlat(line); // сумма платежа
                                    m_objEarningImport.Saldo = m_objEarningImport.Value - 0; // сальдо
                                    m_objEarningImport.CustomrText = GetCustomerTextPlat(line);// текст, с описанием клиента
                                    m_objEarningImport.CurRate = GetCurrencyRate(); // курс ценообразования
                                    m_objEarningImport.CurValue = m_objEarningImport.Value/m_objEarningImport.CurRate;// сумма в EUR

                                    // эти поля переписываются из ранее заполненных переменных, на каждой итерации, т.к. они нужны для каждого экземпляра выписки
                                    m_objEarningImport.Company.ID = guCompanyId;
                                    m_objEarningImport.Company.Name = strCopanyName;
                                    m_objEarningImport.Currency.CurrencyAbbr = strCurrencyAbbr;
                                    m_objEarningImport.Currency.ID = guCurrencyId;
                                    m_objEarningImport.Date = dDate;

                                    l = 0;
                                    break;
                                }
                                if (l == 0)
                                {
                                    // Достаточно присвоить line. Т.к. строка уже буждет в line 
                                    m_objEarningImport.DetailsPayment = line.Replace("xxx", "").Trim();

                                    l = 1; // устанавливаем флаг

                                    SaveUnknownAccountCustomer(m_objEarningImport); // сохраняем список неизвестных клиентских р/с
                                    AddToImportList(m_objEarningImport); // формируем List

                                    m_objEarningImport = new CEarning();
                                    if (m_objEarningImport.Currency == null)
                                    {
                                        m_objEarningImport.Currency = new CCurrency();
                                    } // Инициализируем m_objEarningListImport.Currency
                                    if (m_objEarningImport.Company == null)
                                    {
                                        m_objEarningImport.Company = new CCompany();
                                    } // Инициализируем m_objEarningListImport.Currency
                                    if (m_objEarningImport.Customer == null)
                                    {
                                        m_objEarningImport.Customer = new CCustomer();
                                    } // Инициализируем m_objEarningListImport.Customer
                                    if (m_objEarningImport.EarningList == null)
                                    {
                                        m_objEarningImport.EarningList = new List<CEarning>();
                                    }

                                    // Работет, но впоследствии с этим treeList ничего нельзя сделать
                                    //LoadEarningImportList(m_objEarningImport); // загружаем строку в treeList
                                }
                            }
                            break;
                    }
                    k++;
                }
                // вызвать метод который заполнит трее лист
                AddBankCodeForEmptyRow();
                LoadEarningToTreeList();
                SetAccountPlanForEarningList();
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка разбора выписки Паритетбанк. Текст ошибки: " + f.Message);
            }
            finally
            {
            }
        }


         /// <summary>
         /// Разбор выписки ЦептерБанка
         /// </summary>
         private void AnalysisCepterBakn()
         {
             try
             {
                 //System.Boolean bRet = false;
                 System.String line = ""; //, strErr = "";
                 int k = 0, l = 0;
                 System.String strCurrencyAbbr = "";
                 System.Guid guCompanyId = System.Guid.Empty, guCurrencyId = System.Guid.Empty;
                 System.DateTime dDate = System.DateTime.MinValue;
                 m_objEarningImport = new CEarning();

                 if (m_objEarningImport.Currency == null) { m_objEarningImport.Currency = new CCurrency(); } // Инициализируем m_objEarningListImport.Currency
                 if (m_objEarningImport.Company == null) { m_objEarningImport.Company = new CCompany(); } // Инициализируем m_objEarningListImport.Currency
                 if (m_objEarningImport.Customer == null) { m_objEarningImport.Customer = new CCustomer(); } // Инициализируем m_objEarningListImport.Customer
                 if (m_objEarningImport.EarningList == null) { m_objEarningImport.EarningList = new List<CEarning>(); }

                 while ((line = sr.ReadLine()) != null)
                 {
                     switch (k)
                     {
                         case 0:
                             {
                                 m_objEarningImport.CodeBank = GetBankCodeCepter(line); // код банка (из "шапки")
                             }
                             break;
                         case 2:
                             {
                                 m_objEarningImport.Date = Convert.ToDateTime(GetDateEarnigCepter(line)); // дата выписки (из "шапки")
                                 dDate = m_objEarningImport.Date;
                             }
                             break;
                         case 5:
                             {
                                 strAccountCompany = GetAccountBankStatement(line); // р/с компании (из "шапки")
                                 m_objEarningImport.Currency.CurrencyAbbr = GetCurrencyBankStatementCepter(line);// Abbr валюты (из "шапки")
                                 
                                 m_objEarningImport.Currency.ID = GetGuidCyrrencyBankStatement(m_objEarningImport.Currency.CurrencyAbbr); // GUID валюты
                                 strCurrencyAbbr = m_objEarningImport.Currency.CurrencyAbbr;
                                 guCurrencyId = m_objEarningImport.Currency.ID;
                             }
                             break;
                         case 6:
                             {
                                 m_objEarningImport.Company.ID = GetGuidCompanyBankStatement(strAccountCompany); // GUID компании
                                 m_objEarningImport.Company.Name = GetCompanyNameBankStatement(strAccountCompany); // наименование сомпании
                                 guCompanyId = m_objEarningImport.Company.ID;
                                 strCopanyName = m_objEarningImport.Company.Name;
                             }
                             break;
                         default:
                             {
                                 if (k >= 11 && IsKreditCepter(line) && l == 0)
                                 {
                                     m_objEarningImport.DocNom =  GetDocNumPlat(line); // № документа
                                     m_objEarningImport.CodeBank = GetBankCodPlat(line); // код банка
                                     //m_objEarningImport.AccountNumber = GetAccountPlatCepter(line); // расчетный счет
                                     m_objEarningImport.Account = new CAccount() { AccountNumber = GetAccountPlatCepter(line) }; m_objEarningImport.Value = GetSumPlatCepter(line); // сумма платежа

                                     m_objEarningImport.Customer.ID = GetGuidCustomerBankStatement(m_objEarningImport.AccountNumber, m_objEarningImport.CodeBank); // GUID клиета
                                     m_objEarningImport.Customer.ShortName = GetCustomerNameBankStatement(m_objEarningImport.AccountNumber, m_objEarningImport.CodeBank);// Наименование клиета

                                     m_objEarningImport.Saldo = m_objEarningImport.Value - 0; // сальдо
                                     m_objEarningImport.CurRate = GetCurrencyRate(); // курс ценообразования
                                     m_objEarningImport.CurValue = m_objEarningImport.Value / m_objEarningImport.CurRate;// сумма в EUR

                                     // эти поля переписываются из ранее заполненных переменных, на каждой итерации, т.к. они нужны для каждого экземпляра выписки
                                     m_objEarningImport.Company.ID = guCompanyId;
                                     m_objEarningImport.Company.Name = strCopanyName;
                                     m_objEarningImport.Currency.CurrencyAbbr = strCurrencyAbbr;
                                     m_objEarningImport.Currency.ID = guCurrencyId;
                                     m_objEarningImport.Date = dDate;

                                     l = 1;
                                     break;
                                 }
                                 if (k >= 11 && l == 1)
                                 {
                                     m_objEarningImport.CustomrText = line;// текст, с описанием клиента
                                     l = 2;
                                     break;
                                 }
                                 if (k >= 11 && l == 2)
                                 {
                                     // Достаточно присвоить line. Т.к. строка уже буждет в line 
                                     m_objEarningImport.DetailsPayment = line.Trim();
                                     l = 0;

                                     SaveUnknownAccountCustomer(m_objEarningImport); // сохраняем список неизвестных клиентских р/с
                                     AddToImportList(m_objEarningImport); // формируем List

                                     InitEarningImport(); //Инициализация m_objEarningImport
                                 }
                             }
                             break;
                     }
                     k++; 
                 }
                 // вызвать метод который заполнит трее лист
                 AddBankCodeForEmptyRow();
                 LoadEarningToTreeList();
                 SetAccountPlanForEarningList();
             }
             catch (System.Exception f)
             {
                SendMessageToLog("Ошибка разбора выписки ЦептерБанка. Текст ошибки: " + f.Message);
             }
             finally
             {
             }
         }
        
        /// <summary>
        /// Инициализация m_objEarningImport
        /// </summary>
        private void InitEarningImport()
        {
            m_objEarningImport = new CEarning();
            if (m_objEarningImport.Currency == null) { m_objEarningImport.Currency = new CCurrency(); } // Инициализируем m_objEarningListImport.Currency
            if (m_objEarningImport.Company == null) { m_objEarningImport.Company = new CCompany(); } // Инициализируем m_objEarningListImport.Currency
            if (m_objEarningImport.Customer == null) { m_objEarningImport.Customer = new CCustomer(); } // Инициализируем m_objEarningListImport.Customer
            if (m_objEarningImport.EarningList == null) { m_objEarningImport.EarningList = new List<CEarning>(); }
            if (editorEarningAccountPlan.SelectedItem != null)
            {
                m_objEarningImport.AccountPlan = (CAccountPlan)editorEarningAccountPlan.SelectedItem;
            }

            if (editorEarningProjectDst.SelectedItem != null)
            {
                m_objEarningImport.BudgetProjectDst = (CBudgetProject)editorEarningProjectDst.SelectedItem;
            }
        }
        /// <summary>
        /// Устанавливает значения плана счетов и проекта для списка проводок
        /// </summary>
        private void SetAccountPlanForEarningList()
        {
            try
            {
                CAccountPlan objAccountPlan = null;
                CBudgetProject objBudgetProjectDst = null;

                if (editorEarningAccountPlan.SelectedItem != null)
                {
                    objAccountPlan = (CAccountPlan)editorEarningAccountPlan.SelectedItem;
                }

                if (editorEarningProjectDst.SelectedItem != null)
                {
                    objBudgetProjectDst = (CBudgetProject)editorEarningProjectDst.SelectedItem;
                }


                this.tableLayoutPanel4.SuspendLayout();
                ((System.ComponentModel.ISupportInitialize)(this.trListEarningImport)).BeginInit();

                foreach (DevExpress.XtraTreeList.Nodes.TreeListNode objNode in trListEarningImport.Nodes)
                {
                    if (objNode.Tag == null) { continue; }
                    
                    ((CEarning)objNode.Tag).AccountPlan = objAccountPlan;
                    ((CEarning)objNode.Tag).BudgetProjectDst = objBudgetProjectDst;

                    objNode.SetValue(colEarningImportAccountPlan, ((CEarning)objNode.Tag).AccountPlanName);
                    objNode.SetValue(colEarningProjectDst, ((CEarning)objNode.Tag).BudgetProjectDstName);
                }

                this.tableLayoutPanel4.ResumeLayout(false);
                ((System.ComponentModel.ISupportInitialize)(this.trListEarningImport)).EndInit();

            }
            catch (System.Exception f)
            {
                SendMessageToLog("SetAccountPlanForEarningList. Текст ошибки: " + f.Message);
            }
            return;
        }

        private void btnSetAccountPlanToEarningList_Click(object sender, EventArgs e)
        {
            try
            {
                Cursor = Cursors.WaitCursor;
                SetAccountPlanForEarningList();
            }
            catch (System.Exception f)
            {
                SendMessageToLog("SetAccountPlanForEarningList. Текст ошибки: " + f.Message);
            }
            finally
            {
                Cursor = Cursors.Default;
            }
            return;
        }


        #endregion
        
        #region Работа с файлами
        /// <summary>
        /// Инициализация открытия файла выписки
        /// </summary>
        /// <returns></returns>
        private System.Boolean OpenPaymentFail()
        {
            System.Boolean bRet = false;
             System.String strFailExtens;
            try
            {
                if (openFileDialog.ShowDialog() == DialogResult.OK)
                {
                    strFailExtens= openFileDialog.FileName.Remove(0,(openFileDialog.FileName.Count() - 3));
                    if (strFailExtens=="rtf")
                    {
                        ConvertRtfToTxt(openFileDialog.FileName);
                        InitFileStream();
                    }

                    if (strFailExtens == "txt")
                    {
                        InitFileStream();
                    }
                    bRet = true;
                }
                else
                {
                    return bRet;
                }
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка открытия файла. Текст ошибки: " + f.Message);
            }
            finally
            {
            }
            return bRet;

        }
        /// <summary>
        /// Конвертируем 
        /// </summary>
        /// <param name="strFileName"></param>
        /// <returns></returns>
        private System.Boolean ConvertRtfToTxt(System.String strFileName )
        {
            System.Boolean bRet = false;
            try
            {
                string directoryPath = Path.GetDirectoryName(strFileName);

                System.Windows.Forms.RichTextBox rtBox = new System.Windows.Forms.RichTextBox();
                string s = System.IO.File.ReadAllText(strFileName);
                rtBox.Rtf = s;
                string plainText = rtBox.Text;
                System.IO.File.WriteAllText(directoryPath + "\\output.txt", plainText, Encoding.Default); // записываем в файл output.txt
                openFileDialog.FileName = directoryPath + "\\output.txt"; // изменям путь к файлу, чтобы он указывал на файл output.txt
                bRet = true;
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка открытия преодразования rtf файла в output.txt Текст ошибки: " + f.Message);
            }
            finally
            {
            }
            return bRet;
        }

        /// <summary>
        ///  Инициализируем FileStream и StreamReader 
        /// </summary>
        private void InitFileStream()
        {
            FileInfo f = new FileInfo(openFileDialog.FileName);
            FileStream fs = f.Open(FileMode.Open, FileAccess.Read, FileShare.ReadWrite);
            sr = new StreamReader(fs, Encoding.Default);
        }
        #endregion

        #region Логика разбора "паритетбанк совместимой" выписки
        /// <summary>
        /// Проверяем на Паритетбанк банк
        /// </summary>
        /// <param name="strLine"></param>
        /// <returns>1 - паритетбанк</returns>
        /// <returns>0 - не паритетбанк</returns>
        private System.Int32 IsParitetBank(System.String strLine)
        {
            int iBnk = 0;
            try
            {
                Regex r = new Regex(@"ОАО\s""Паритетбанк""\s+МФО\s153001782");
                Match m = r.Match(strLine); //Результат
                if (m.Success)
                {
                    iBnk = 1;
                }
                else
                {
                    iBnk = 0;
                }
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка проверки на Паритетбанк. Текст ошибки: " + f.Message);
            }
            return iBnk;
        }



        /// <summary>
        /// Получаем банковский код Паритетбанка
        /// </summary>
        /// <param name="strLine"></param>
        /// <returns>код банка</returns>
        private System.String GetBankCodFromHeader(System.String strLine)
        {
            string strCodeBank = "";
            try
            {
                string strLi= strLine.Trim();
                strCodeBank = strLi.Remove(0, strLi.Count() - 3);
                return strCodeBank;
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка получения кода банка из 'шапки' выписки. Текст ошибки: " + f.Message);
            }
            return "";
        }


        private System.String GetDateBankStatement(System.String strLine)
        {
            System.String strDate = "";
            try
            {
                System.Int32 i = 1;
                //System.Boolean bRes = false;
                //Regex r = new Regex(@"\d*\/\d*");
                Regex r = new Regex(@"\d+");
                MatchCollection m = r.Matches(strLine); //Результат
                foreach (Match match in m)
                {
                    if (i < 3)
                    {
                        strDate += match.Value + ".";
                    }
                    else
                    {
                        strDate += match.Value;
                    }
                    i++;
                }
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка получения даты выписки. Текст ошибки: " + f.Message);
            }
            return strDate;
        }

        private System.String GetCurrencyBankStatement(string strLine)
        {
            Regex r = new Regex(@"(?<=\d\s{5})\w+");
            Match m = r.Match(strLine); //Результат
            return m.Value;
        }
        /// <summary>
        /// Получит р/с компании из "шапки" выписки
        /// </summary>
        /// <param name="strLine"></param>
        /// <returns></returns>
        private System.String GetAccountBankStatement(string strLine)
        {
            Regex r = new Regex(@"\d{13}");
            Match m = r.Match(strLine); //Результат
            return m.Value;
        }


        private System.String GetCompanyBankStatement(string strLine)
        {
            Regex r = new Regex(@"(?<=Наименование)\s([^#]+)");
            Match m = r.Match(strLine); //Результат
            return m.Value.Trim();
        }


        private System.String GetAccountPlat(string strLine)
        {
            Regex r = new Regex(@"\d{13}(?=\s{22})");
            Match m = r.Match(strLine); //Результат
            return m.Value.Trim();
        }

        private System.Decimal /*System.String*/ GetSumPlat(string strLine)
        {
            String strTemp;
            Regex r = new Regex(@"\d{13}\s+([^.]+).\d+");
            Match m = r.Match(strLine); //Результат

            System.String dcmlSeparator = CultureInfo.CurrentCulture.NumberFormat.CurrencyDecimalSeparator;

            strTemp = m.Value.Remove(0, 13).Trim().Replace(" ", "").Replace(".", dcmlSeparator); // 
            strTemp.Replace(",", dcmlSeparator);
            
            //Decimal y = Convert.ToDecimal(strTemp);
            return Convert.ToDecimal(strTemp); //strTemp; 
        }

        private System.String GetCustomerTextPlat(string strLine)
        {
            String strTemp;
            Regex r = new Regex(@"\.00\s+([^\=]+)");
            Match m = r.Match(strLine); //Результат
            strTemp = m.Value.Replace(".00", "").Trim(); //.Remove(0, 13).Trim().Replace(" ", "").Replace(".", ","); // 
            //Decimal y = Convert.ToDecimal(strTemp);))
            //---
            Regex r2 = new Regex(@"\s+([^\=]+)");
            Match m2 = r2.Match(strTemp); //Результат
            strTemp = m2.Value;
            //---
            return strTemp.Trim();
        }


        private System.String GetBankCodPlat(string strLine)
        {
            String strTemp;
            Regex r = new Regex(@"\d+\s(?=\d{13})");
            Match m = r.Match(strLine); //Результат
            if (m.Value.Count() >= 4)
            {
                strTemp = m.Value.TrimEnd().Remove(0, m.Value.Count() - 4);
                return strTemp;
            }
            else
            {
                return "";
            }
        }

        private System.String GetDocNumPlat(string strLine)
        {
            String strTemp;
            Regex r = new Regex(@"^\d+\s+");
            Match m = r.Match(strLine); //Результат
            strTemp = m.Value.Trim();
            return strTemp;
        }

        private System.Boolean IsMov(string strLine)
        {
            //String strTemp;
            Regex r = new Regex(@"ОБОРОТЫ\s{12,}\d+");
            Match m = r.Match(strLine); //Результат 
            return m.Success;
        }

        private System.Decimal GetSumOborot(string strLine)
        {
            String strTemp;
            Regex r = new Regex(@"\.\d+\s+([^\=]+)");
            Match m = r.Match(strLine); //Результат
            strTemp = m.Value.Replace(".00", "").Trim(); //.Remove(0, 13).Trim().Replace(" ", "").Replace(".", ","); // 
            return Convert.ToDecimal(strTemp);
        }
        #endregion

        #region Логика разбора ЦептерБанк совместимой выписки
        /// <summary>
        /// Проверяем на ЦептерБанк
        /// </summary>
        /// <param name="strLine"></param>
        /// <returns>1 - Цептербанк</returns>
        /// <returns>0 - не Цептербанк</returns>
        private System.Int32 IsCepterBank(System.String strLine)
        {
            int iBnk = 0;
            try
            {
                Regex r = new Regex(@"ЗАО\s'ЦЕПТЕР БАНК'");
//                Regex r = new Regex(@"ЗАО\s'ЦЕПТЕР БАНК' Г.МИНСК,");
                Match m = r.Match(strLine); //Результат
                if (m.Success)
                {
                    iBnk = 1;
                }
                else
                {
                    iBnk = 0;
                }
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка проверки на Цептербанк. Текст ошибки: " + f.Message);
            }
            return iBnk;
        }

        private System.String GetBankCodeCepter(System.String strLine)
        {
            return strLine.Trim().Remove(0, strLine.Count() - 3);
        }

        /// <summary>
        /// Получит дату из "шапки" выписки 
        /// </summary>
        /// <param name="strLine"></param>
        /// <returns>string</returns>
        private System.String GetDateEarnigCepter(string strLine)
        {
            Regex r = new Regex(@"\d+.\d+.\d+");
            Match m = r.Match(strLine); //Результат
            return m.Value;
        }

        /// <summary>
        /// Получит Abbr валюты из "шапки" выписки 
        /// </summary>
        /// <param name="strLine"></param>
        /// <returns>string</returns>
        private System.String GetCurrencyBankStatementCepter(string strLine)
        {
            Regex r = new Regex(@"(?<=\d{13}\s)\w+");
            Match m = r.Match(strLine); //Результат
            return m.Value;
        }
        /// <summary>
        /// Проверяе
        /// </summary>
        /// <param name="strLine"></param>
        /// <returns></returns>
        private System.Boolean IsKreditCepter(string strLine)
        {
            Regex r = new Regex(@"\d{13}\t\t([^\t]+)");
            Match m = r.Match(strLine); //Результат 
            return m.Success;

        }

        private System.String GetAccountPlatCepter(string strLine)
        {
            Regex r = new Regex(@"\t\d{13}\t");
            Match m = r.Match(strLine); //Результат
            return m.Value.Trim();
        }

        private System.Decimal GetSumPlatCepter(string strLine)
        {
            String strTemp;
            Regex r = new Regex(@"\d{13}\s+([^.]+)");
            Match m = r.Match(strLine); //Результат
            strTemp = m.Value.Remove(0, 13).Trim().Replace(" ", ""); // 
            //Decimal y = Convert.ToDecimal(strTemp);
            return Convert.ToDecimal(strTemp); //strTemp; 
        }
        #endregion


        #region Вспомогательные методы


        private System.Int32 GetNumValidBank(System.String strLine)
        {
            int iBnk = 0;
            try
            {
                if (IsParitetBank(strLine) == 1)
                {
                    iBnk = 1; // 1 флаг для Паритета
                }

                if (IsCepterBank(strLine) == 1)
                {
                    iBnk = 2; // 2 флаг для Цептера
                }
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка проверки банка. Текст ошибки: " + f.Message);
            }
            return iBnk;
        }
        
        private System.Guid GetGuidCyrrencyBankStatement(System.String sCur)
        {
            List<CCurrency> objCurList = CCurrency.GetCurrencyListForCurrency(m_objProfile, null);

            if (sCur == "BYR")
            {
                IEnumerable<Guid> cur = from currency in objCurList.AsEnumerable()
                                        where currency.CurrencyAbbr == sCur
                                        select currency.ID;

                foreach (System.Guid val in cur)
                {
                    guigTemp = val;

                }

                if (guigTemp == System.Guid.Empty)
                {
                    GetGuidCyrrencyBankStatement("BYB");
                }
            }
            else
            {
                IEnumerable<Guid> cur = from currency in objCurList.AsEnumerable()
                                        where currency.CurrencyAbbr == sCur
                                        select currency.ID;

                foreach (System.Guid val in cur)
                {
                    guigTemp = val;
                }
            }  

            return guigTemp;

        }

        private System.Guid GetGuidCompanyBankStatement(System.String sAccount)
        {
            System.Guid gTmp = System.Guid.Empty;

            List<CCompany> objCompany = CCompany.GetCompanyByAccount(m_objProfile, null, sAccount);

            foreach (var val in objCompany)
            {
                gTmp = val.ID;
            }

            return gTmp;
        }

        private System.String GetCompanyNameBankStatement(System.String sAccount)
        {
            System.String strTmp = "";

            List<CCompany> objCompany = CCompany.GetCompanyByAccount(m_objProfile, null, sAccount);

            foreach (var val in objCompany)
            {
                strTmp = val.Name;
            }

            return strTmp;
        }

        private System.Guid GetGuidCustomerBankStatement(System.String sAccount, System.String sBankCod)
        {
            System.Guid gTmp = System.Guid.Empty;
            System.String strErr = "";

            CCustomer objCustomer = CCustomer.GetCustomerByAccountAndBankCod(m_objProfile, null, sAccount, sBankCod, ref strErr);
            if (objCustomer != null)
            {
                gTmp = objCustomer.ID;
            }

            return gTmp;
        }

        private System.String GetCustomerNameBankStatement(System.String sAccount, System.String sBankCod)
        {
            System.String strTmp = "";
            System.String strErr = "";

            CCustomer objCustomer = CCustomer.GetCustomerByAccountAndBankCod(m_objProfile, null, sAccount, sBankCod, ref strErr);
            if (objCustomer != null)
            {
                strTmp = objCustomer.ShortName;
            }

            return strTmp;
        }

        private System.Decimal GetCurrencyRate()
        {
            List<ERP_Mercury.Common.CCurrencyRate> m_objCurrencyRateListPricing;
            System.Decimal valCurRate = 0;

            m_objCurrencyRateListPricing = ERP_Mercury.Common.CCurrencyRate.GetCurrencyRateListPricing(m_objProfile, null);

            foreach (ERP_Mercury.Common.CCurrencyRate objCurrRate in m_objCurrencyRateListPricing)
            {
                valCurRate = objCurrRate.CurrencyRateValue;
            }
            return valCurRate;
        }

        private CBank GetBankByBankCod(System.String sbankCod)
        {
            CBank varBank = new CBank();
            List<CBank> objBankList = CBank.GetBankList(m_objProfile, null, null);

            //objBankList = objBankList.First();

            IEnumerable<CBank> objBabk = from bank in objBankList.AsEnumerable()
                                         where bank.Code == sbankCod
                                         select bank;

           

            foreach (CBank valobjBank in objBabk)
            {
                varBank = valobjBank;
            }

            return varBank;  
        }

        private CAccountType GetAccountType()
        {
            List<CAccountType> objAccountType = CAccountType.GetAccountTypeList(m_objProfile, null);
            CAccountType varAccountType = objAccountType.First();

            return varAccountType;
        }
        #endregion

        #region Находим р/с у которых нет клиентов
        /// <summary>
        /// Загружаем в List список неизвестный клиентских р/с
        /// </summary>
        private void SaveUnknownAccountCustomer(CEarning objEarning)
        {
            // присутствует р/с, а клиент не найден
            if (objEarning.Customer.ID==System.Guid.Empty && System.String.IsNullOrEmpty(objEarning.AccountNumber)==false)
            {
                listFreeAccount.Add(objEarning.AccountNumber);
            }
        }

        #endregion
        

        public System.Boolean AddToImportList(CEarning objEarning)
        {
            System.Boolean bRet = false;
            //this.Cursor = Cursors.WaitCursor;
            try
            {
                if (objEaL == null) { objEaL = new CEaL(); }
                objEaL.Add(objEarning);
                
                bRet = true;
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка добавления в List списка платежей, импортируемый из выписки. Текст ошибки: " + f.Message);
            }
            finally
            {
                //this.Cursor = Cursors.Default;
                this.Refresh();
            }
            return bRet;
        }


        /// <summary>
        /// Загружаем в TreeList список выписок
        /// </summary>
        /// <returns>true - удачное завершение операции; false - ошибка</returns>
        public System.Boolean LoadEarningImportList(CEarning objEarning)
        {
            System.Boolean bRet = false;
            this.Cursor = Cursors.WaitCursor;
            try
            {
                //treelistEarning.Nodes.Clear();
                //m_objEarningList = ERP_Mercury.Common.CEarning.GetEarningList(m_objProfile, null, dtB, dtE, guidCompany);

                DevExpress.XtraTreeList.Nodes.TreeListNode objNode = trListEarningImport.AppendNode(new object[] { objEarning.Date, objEarning.DocNom, 
                    objEarning.CodeBank, objEarning.AccountNumber, objEarning.Currency, objEarning.Value, objEarning.Expense, objEarning.Saldo, 
                    objEarning.Customer.ShortName /*(objEarning.Customer).ToString().Trim()*/, 
                    objEarning.CustomrText, objEarning.DetailsPayment, 
                    objEarning.AccountPlanName, objEarning.BudgetProjectDstName}, null);
                objNode.Tag = objEarning;
                
                /*
                foreach (ERP_Mercury.Common.CEarning objEarning in objEar.EarningList)// m_objEarningImport.EarningList
                {
                    DevExpress.XtraTreeList.Nodes.TreeListNode objNode = treelistEarning.AppendNode(new object[] { objEarning.DocNom, objEarning.CodeBank, objEarning.AccountNumber, objEarning.Value, (objEarning.Customer).ToString().Trim(), objEarning.CustomrText, objEarning.DetailsPayment }, null);
                    objNode.Tag = objEarning;
                }
                */
                bRet = true;
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка обновления списка платежей, импортируемый из выписки. Текст ошибки: " + f.Message);
            }
            finally
            {
                this.Cursor = Cursors.Default;
                TabControl.SelectedTabPage = tabEditor;
                this.Refresh();
                //m_objEarningImport.EarningList.Clear();

            }
            return bRet;
        }

        /// <summary>
        /// Загружаем в TreeList список выписок
        /// </summary>
        /// <returns>true - удачное завершение операции; false - ошибка</returns>
        public System.Boolean LoadEarningList(CEarning objEar)
        {
            System.Boolean bRet = false;
            this.Cursor = Cursors.WaitCursor;
            try
            {
                //treelistEarning.Nodes.Clear();
                //m_objEarningList = ERP_Mercury.Common.CEarning.GetEarningList(m_objProfile, null, dtB, dtE, guidCompany);
                
                //DevExpress.XtraTreeList.Nodes.TreeListNode objNode = trListEarningImport.AppendNode(new object[] { objEarning.Date, objEarning.DocNom, objEarning.CodeBank, objEarning.AccountNumber, objEarning.Currency, objEarning.Value, objEarning.Expense, objEarning.Saldo, objEarning.Customer.ShortName /*(objEarning.Customer).ToString().Trim()*/, objEarning.CustomrText, objEarning.DetailsPayment }, null);
                //objNode.Tag = objEarning;


                foreach (ERP_Mercury.Common.CEarning objEarning in objEar.EarningList)// m_objEarningImport.EarningList
                {
                    DevExpress.XtraTreeList.Nodes.TreeListNode objNode = trListEarningImport.AppendNode(new object[] { objEarning.Date, objEarning.DocNom, 
                        objEarning.CodeBank, objEarning.AccountNumber, objEarning.Currency, 
                        objEarning.Value, objEarning.Expense, objEarning.Saldo, objEarning.Customer.ShortName /*(objEarning.Customer).ToString().Trim()*/, 
                        objEarning.CustomrText, objEarning.DetailsPayment, 
                        objEarning.AccountPlanName, objEarning.BudgetProjectDstName    }, null);
                    objNode.Tag = objEarning;
                }
                
                bRet = true;
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка обновления списка платежей, импортируемый из выписки. Текст ошибки: " + f.Message);
            }
            finally
            {
                this.Cursor = Cursors.Default;
                TabControl.SelectedTabPage = tabEditor;
                this.Refresh();
                //m_objEarningImport.EarningList.Clear();

            }
            return bRet;
        }



        public System.Boolean LoadEarningToTreeList()
        {
            System.Boolean bRet = false;
            //this.Cursor = Cursors.WaitCursor;
            try
            {
                //treelistEarning.Nodes.Clear();

                foreach (ERP_Mercury.Common.CEarning objEarning in objEaL.EarningList)
                {
                    DevExpress.XtraTreeList.Nodes.TreeListNode objNode = trListEarningImport.AppendNode(new object[] { objEarning.Date, objEarning.DocNom, 
                        objEarning.CodeBank, objEarning.AccountNumber, objEarning.Currency, 
                        objEarning.Value, objEarning.Expense, objEarning.Saldo, objEarning.Customer.ID /*ShortName*/ /*(objEarning.Customer).ToString().Trim()*/, 
                        objEarning.CustomrText, objEarning.DetailsPayment, 
                        objEarning.AccountPlanName, objEarning.BudgetProjectDstName
                    }, null);
                    objNode.Tag = objEarning;
                }

                bRet = true;
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка обновления списка платежей, импортируемый из выписки. Текст ошибки: " + f.Message);
            }
            finally
            {
                objEaL.EarningList.Clear();
                
                //this.Cursor = Cursors.Default;
                TabControl.SelectedTabPage = tabEditor;
                this.Refresh();
                //m_objEarningImport.EarningList.Clear();
            }
            return bRet;
        }

        /// <summary>
        /// В проводках с незаполненным кодом банка, меняем "" на код банка который прислсл выписку.
        /// </summary>
        /// <returns></returns>
        public System.Boolean AddBankCodeForEmptyRow()
        {
            System.Boolean bRet = false;
            int i = 0;
            try
            {
                foreach (ERP_Mercury.Common.CEarning objEarning in objEaL.EarningList)
                {
                    
                    if (objEarning.CodeBank == System.String.Empty)
                    {
                        objEaL.EarningList[i].CodeBank = strBankCodMain;
                    }
                    i++;
                }

                bRet = true;
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка обновления списка платежей, импортируемый из выписки. Текст ошибки: " + f.Message);
            }
            return bRet;
        }

        private System.Boolean LoadEarningCompanyStaticPanel()
        {
            System.Boolean bRet = false;
            this.Cursor = Cursors.WaitCursor;
            try
            {
                txtCompany.Text = "";
                txtAccountN.Text = "";
                if (strCopanyName!="")
                {
                    txtCompany.Text = strCopanyName; //m_objEarningImport.Company.Name;
                }
                if (strAccountCompany!="")
                {
                    txtAccountN.Text = strAccountCompany;
                }
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка панели общей информации о компании из выписки. Текст ошибки: " + f.Message);
            }
            finally
            {
                this.Cursor = Cursors.Default;
                //TabControl.SelectedTabPage = tabEditor;
                this.Refresh();
            }
            return bRet;
        }

        private void contextMenuStripEarning_Opening(object sender, CancelEventArgs e)
        {

        }

        private void contextMenuStrip1_Opening(object sender, CancelEventArgs e)
        {

        }

        private void contextMenuStrip1_Opening_1(object sender, CancelEventArgs e)
        {

        }

        private void trListEarningImport_MouseClick(object sender, MouseEventArgs e)
        {
            try
            {
                // потом раскоментировать 19.03
                //if (m_bIsReadOnly == true) { return; }
                if (e.Button == MouseButtons.Right)
                {
                    // попробуем определить, что же у нас под мышкой
                    DevExpress.XtraTreeList.TreeListHitInfo hi = ((DevExpress.XtraTreeList.TreeList)sender).CalcHitInfo(new Point(e.X, e.Y));
                    if ((hi == null) || (hi.Node == null))
                    {
                        mitemDeleteCurrRate.Enabled = false;
                    }
                    else
                    {
                        // выделяем узел
                        mitemDeleteCurrRate.Enabled = true;
                        hi.Node.TreeList.FocusedNode = hi.Node;
                    }
                    contextMenuStripEarning.Show(((DevExpress.XtraTreeList.TreeList)sender), new Point(e.X, e.Y));
                    
                }
            }
            catch (System.Exception f)
            {
                SendMessageToLog("trListEarningImport_MouseClick. Текст ошибки: " + f.Message);
            }
            finally
            {
            }
            return;
        }


        private void trListEarningImport_CellValueChanging(object sender, DevExpress.XtraTreeList.CellValueChangedEventArgs e)
        {
            if (m_bDisableEvents == true) { return; }
            try
            {
                //System.Int32 iPosNode = trListEarningImport.GetNodeIndex(e.Node);
              
                // Предупреждение при изменениии кода банка
                if ((e.Column == сEarningImpCodeBank) && (e.Value != null))
                {
                    if ( ((System.String)e.Value != ((CEarning)e.Node.Tag).CodeBank ) && (((CEarning)e.Node.Tag).CodeBank != System.String.Empty) )
                    {
                        DialogResult result = MessageBox.Show("Вы действительно хотите изменить код банка '" + ((CEarning)e.Node.Tag).CodeBank  + "' на другой ?", "Изменение кода банка", MessageBoxButtons.YesNo, MessageBoxIcon.Question );

                        if (result == DialogResult.No)
                        {
                            return;
                        }
                    }
                }
                
                // Код банка
                if ((e.Column == сEarningImpCodeBank) && (e.Value != null))
                {
                    ((CEarning)e.Node.Tag).CodeBank = e.Value.ToString();
                    e.Node.SetValue(сEarningImpCodeBank, ((CEarning)e.Node.Tag).CodeBank);
                }

                // Предупреждение при изменениии клиента
                /*
                if ((e.Column == cEarningImpCustomer) && (e.Value != null))
                {
                    if ( ((System.Guid)e.Value != ((CEarning)e.Node.Tag).Customer.ID) && (((CEarning)e.Node.Tag).Customer.ID != System.Guid.Empty) )
                    {
                        DialogResult result = MessageBox.Show("Вы действительно хотите изменить клиента '" + ((CEarning)e.Node.Tag).Customer.ShortName.Trim() + "' на другого ?", "Изменение клиента", MessageBoxButtons.YesNo, MessageBoxIcon.Question );

                        if (result == DialogResult.No)
                        {
                            return;
                        }
                    }
                }
                */

                // № документа
                if ((e.Column == cEarningImpNumDoc) && (e.Value != null))
                {
                    ((CEarning)e.Node.Tag).DocNom = (System.String)e.Value;
                    e.Node.SetValue(cEarningImpNumDoc, ((CEarning)e.Node.Tag).DocNom);
                }

                // Клиент
                if ((e.Column == cEarningImpCustomer) && (e.Value != null))
                {
                    ((CEarning)e.Node.Tag).Customer.ID = (System.Guid)e.Value; //((CCustomer) e.Value).ID;

                    e.Node.SetValue(cEarningImpCustomer, ((CEarning)e.Node.Tag).Customer.ID); // ItemLockUpEdit сам находит значение ShortName (Name) по ID
                }


                //// для true
                //if ((e.Column == cCurrRatePricing) && (e.Value != null) && (((System.Boolean)e.Value) == true))
                //{
                //    ((CCurrencyRate)e.Node.Tag).CurrencyIsPricing = true;
                //    e.Node.SetValue(cCurrRatePricing, true);
                //}
                //// для false
                //if ((e.Column == cCurrRatePricing) && (e.Value != null) && (((System.Boolean)e.Value) == false))
                //{
                //    ((CCurrencyRate)e.Node.Tag).CurrencyIsPricing = false;
                //    e.Node.SetValue(cCurrRatePricing, false);
                //}

                //if ((e.Column == cCurrRateCurrRateIn) && (e.Value != null))
                //{
                //    ((CCurrencyRate)e.Node.Tag).CurrencyAbbrIn = Convert.ToString(e.Value);
                //    ((CCurrencyRate)e.Node.Tag).CurrencyInGuide = ((CCurrency)e.Value).ID;
                //}

                //if ((e.Column == cCurrRateCurrRateOut) && (e.Value != null))
                //{
                //    ((CCurrencyRate)e.Node.Tag).CurrencyAbbrOut = Convert.ToString(e.Value);
                //    ((CCurrencyRate)e.Node.Tag).CurrencyOutGuide = ((CCurrency)e.Value).ID;
                //}

                SetPropertiesModified(true);
            }
            catch (System.Exception f)
            {
                SendMessageToLog("treeListAccounts_CellValueChanged. Текст ошибки: " + f.Message);
            }
            finally
            {
            }
            return;
        }

        private void trListEarningImport_CustomDrawNodeCell(object sender, DevExpress.XtraTreeList.CustomDrawNodeCellEventArgs e)
        {
            try
            {
                if ((e.Node == trListEarningImport.FocusedNode && e.Column != trListEarningImport.FocusedColumn) || e.Node == null || e.Column == null || e.Node.Tag == null) return;
                if (e.Node.GetValue(сEarningImpCodeBank) == null) { return; }

                // проверяем на незаполненный код банка
                if (e.Node.GetValue(сEarningImpCodeBank).ToString() == strBankCodMain)
                {
                    //e.Appearance.Font = new Font(DevExpress.Utils.AppearanceObject.DefaultFont, FontStyle.Strikeout);
                    e.Appearance.ForeColor = Color.Red;

                    // !!! в этом обработчике, нельзя изменять содержимое ноды. Это приводит к ошибке времени выполнения !!!

                    // Код банка
                    //if (e.Column == сEarningImpCodeBank)
                    //{
                    //    ((CEarning)e.Node.Tag).CodeBank = "000"; //e.Value.ToString();
                    //    e.Node.SetValue(сEarningImpCodeBank,"000" /*((CEarning)e.Node.Tag).CodeBank*/);
                    //}
                }
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show(
                    "Ошибка treeList_CustomDrawNodeCell.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally
            {
            }
            return;
            

            //if (((CEarning)e.Node.Tag).DocNom == "19" )
            //{
            //    MessageBox.Show("!!!");
            //    //e.Appearance.BackColor = Color.Red;
            //}


            // код банка
            //if (e.Column.Name == сEarningImpCodeBank.Name)
            //{
            //    if (IsCodeBankValid(((CEarning)e.Node.Tag).CodeBank) == false)
            //    {
            //        e.Appearance.BackColor = Color.Red;
            //        //trListEarningImport.SetColumnError(сEarningImpCodeBank, "Код банка не заполнен");
            //    }

            //else
            //{
            //    ((CEarning)e.Node.Tag).CodeBank = Convert.ToString(e.Value);
            //    e.Node.SetValue(сEarningImpCodeBank, ((CEarning)e.Node.Tag).CodeBank);
            //}
            //}
        }



        private void mitemDeleteCurrRate_Click(object sender, EventArgs e)
        {
            try
            {
                DeleteEarningCo(trListEarningImport.FocusedNode);
            }
            catch (System.Exception f)
            {
                SendMessageToLog("mitemDeleteCurrRate_Click. Текст ошибки: " + f.Message);
            }
            finally
            {
            }
            return;
        }

        #region Ok
        private void btnSave_Click(object sender, EventArgs e)
        {
            try
            {
                lblWarningInfo.Text = "";
                m_bNewEarning = true;       // добавил временно
                
                System.String strErr = "";
                if (IsCtrlParamValid(ref strErr) == false)
                { 
                    SetWarningInfo(strErr); ShowWarningPnl(true);
                    return;
                }
                //this.Cursor = Cursors.WaitCursor;        
                EanbledButtonOkCansel(false);
                
                if (bSaveChanges() == true)
                {
                    SimulateChangeEarningProperties(m_objSelectedEarning, enumActionSaveCancel.Save, m_bNewEarning);
                    // если всё прошло хорошо, нужно перейти в режим редактирования
                    SetModeReadOnly(true);
                    //ShowNBRBBar(false);
                    EnableDEBegEnd(true);
                    ShowWarningPnl(false);

                    MessageBox.Show("Импорт данных успешно завершён", "Импорт данных", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    LoadEarningList();
                    // VisibleProgressBar(false);
                    TabControl.SelectedTabPage = tabViewer;
                    EnableRemoveButton(false);
                }
                
                //ShowBarManager(true);
                
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка сохранения изменений в выписке. Текст ошибки: " + f.Message);
            }
            finally
            {
                //EnableRemoveButton(false);
                this.Cursor = System.Windows.Forms.Cursors.Default;
                // здесь нужно перейти в режим редактирования
                //ShowWarningPnl(false);
                EanbledButtonOkCansel(true);
            }
            return;
        }
        #endregion

        #region Отмена
        private void btnCancel_Click(object sender, EventArgs e)
        {
            try
            {
                Cancel();
                //ClearAllTreeList(true);

                //LoadCurrencyRateList();
                SetModeReadOnly(true);
                EnableRemoveButton(false);
                //ShowBarManager(true);
                //EnableDEBegEnd(true);
                TabControl.SelectedTabPage = tabEditor;
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка отмены изменений в описании курсов. Текст ошибки: " + f.Message);
            }
            finally
            {
                TabControl.SelectedTabPage = tabViewer;
            }

            return;
        }
        /// <summary>
        /// Отмена внесенных изменений
        /// </summary>
        private void Cancel()
        {
            try
            {
                ClearEarningCompanyStaticPanel();
                ClearImportTreeList();
                EnableDEBegEnd(true);
                //ShowTreeLisrIB(false);
                //ShowNBRBBar(false);
                ShowWarningPnl(false);
                SimulateChangeEarningProperties(m_objSelectedEarning, enumActionSaveCancel.Cancel, m_bNewEarning);

            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка отмены изменений в банковской выписке. Текст ошибки: " + f.Message);
            }
            finally
            {
            }
            return;
        }
        #endregion

        /// <summary>
        /// Получить GUID в текстовом виде
        /// </summary>
        /// <returns></returns>
        private string GetGuidKey()
        {
            return System.Guid.NewGuid().ToString();
        }

        /// <summary>
        /// Получить случайное число для ключа
        /// </summary>
        /// <returns></returns>
        private int GetKey()
        {
            Random rnd = new Random(DateTime.Now.Millisecond);
            return rnd.Next(1, 1000000);
        }


        private void ClearImportTreeList()
        {
            try
            {
                trListEarningImport.ClearNodes();
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка очистки TreeList с импортированными данными. Текст ошибки: " + f.Message);
            }

        }

        public void ClearEarningCompanyStaticPanel()
        {
            try
            {
                txtCompany.Text = "";
                txtAccountN.Text = "";
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка очистки TreeList с импортированными данными. Текст ошибки: " + f.Message);
            }

        }

        private void barBtnDelRow_ItemClick(object sender, DevExpress.XtraBars.ItemClickEventArgs e)
        {
            try
            {
                DeleteEarningCo(trListEarningImport.FocusedNode);
            }
            catch (System.Exception f)
            {
                SendMessageToLog("mitemDeleteCurrRate_Click. Текст ошибки: " + f.Message);
            }
            finally
            {
            }
            return;
        }

        private void deBegin_ItemClick(object sender, DevExpress.XtraBars.ItemClickEventArgs e)
        {

        }

        private void trListEarningImport_CustomDrawNodeImages(object sender, DevExpress.XtraTreeList.CustomDrawNodeImagesEventArgs e)
        {
            try
            {
                System.Int32 iImgIndx = -1;
                int Y = e.SelectRect.Top + (e.SelectRect.Height - imageCollection.Images[0].Height) / 2;
                if ((e.Node != null) && ((e.Node.GetValue(сEarningImpCodeBank) != null) || (e.Node.GetValue(cEarningCustomer) != null)) )
                {                   
                    System.String strBankCode=e.Node.GetValue(сEarningImpCodeBank).ToString();
                    Guid guidCustomer = (System.Guid)e.Node.GetValue(cEarningImpCustomer);

                    if (strBankCode ==  System.String.Empty || guidCustomer == Guid.Empty)
                    {
                        iImgIndx = 1;
                    }
                    else
                    {
                        iImgIndx = 0;
                    }
                }
                try
                {
                    e.Graphics.DrawImage(imageCollection.Images[iImgIndx], new Point(e.SelectRect.X, Y));
                    e.Handled = true;
                }
                catch { }

            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("Ошибка отображения иконок списка выписок.\nТекст ошибки: " + f.Message, "Ошибка",System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
        }

        private void progressBar_CustomDisplayText(object sender, DevExpress.XtraEditors.Controls.CustomDisplayTextEventArgs e)
        {
            e.DisplayText = "Ждите, идёт сохранение...";
        }

        #region Редактирование реквизитов платежа
        /// <summary>
        /// редактирование реквизитов платежа
        /// </summary>
        /// <param name="objNode">узел дерева, связанный с платежем</param>
        private void EditEarning( DevExpress.XtraTreeList.Nodes.TreeListNode objNode )
        {
            try
            {
                if ((objNode == null) || (objNode.Tag == null)) { return; }

                CEarning objEarning = (CEarning)objNode.Tag;

                if (objEarning == null) { return; }

                using (frmChangeAccountPlan objFrmChangeAccountPlan = new frmChangeAccountPlan())
                {
                    objFrmChangeAccountPlan.EditEarning(objEarning, 
                        editorEarningAccountPlan.Properties.Items.Cast<CAccountPlan>().ToList<CAccountPlan>(),
                        editorEarningProjectDst.Properties.Items.Cast<CBudgetProject>().ToList<CBudgetProject>());

                    if (objFrmChangeAccountPlan.DialogResult == System.Windows.Forms.DialogResult.OK)
                    {
                        objNode.SetValue(colEarningImportAccountPlan, objEarning.AccountPlanName);
                        objNode.SetValue(colEarningProjectDst, objEarning.BudgetProjectDstName);

                        objNode.TreeList.Refresh();
                    }
                    
                }
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show(
                    "EditEarning.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }

            return;

        }

        private void trListEarningImport_MouseDoubleClick(object sender, MouseEventArgs e)
        {
            try
            {
                if ((trListEarningImport.Nodes.Count == 0) || (trListEarningImport.FocusedNode == null)) { return; }
                if ((trListEarningImport.FocusedColumn == colEarningImportAccountPlan) || (trListEarningImport.FocusedColumn == colEarningProjectDst))
                {
                    EditEarning(trListEarningImport.FocusedNode);
                }
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show(
                    "trListEarningImport_MouseDoubleClick.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }

            return;
        }
        private void mitemEditEarning_Click(object sender, EventArgs e)
        {
            try
            {
                if ((trListEarningImport.Nodes.Count == 0) || (trListEarningImport.FocusedNode == null)) { return; }
                if ((trListEarningImport.FocusedColumn == colEarningImportAccountPlan) || (trListEarningImport.FocusedColumn == colEarningProjectDst))
                {
                    EditEarning(trListEarningImport.FocusedNode);
                }
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show(
                    "mitemEditEarning_Click.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }

            return;
        }
        private void contextMenuStripImport_Opening(object sender, CancelEventArgs e)
        {
            try
            {
                mitemEditEarning.Enabled = ((trListEarningImport.Nodes.Count > 0) && (trListEarningImport.FocusedNode != null) &&
                    ((trListEarningImport.FocusedColumn == colEarningImportAccountPlan) || (trListEarningImport.FocusedColumn == colEarningProjectDst))
                    );
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show(
                    "contextMenuStripImport_Opening.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }

            return;
        }
        #endregion



    }

    public class BankStatementEditor : PlugIn.IClassTypeView
    {
        public override void Run(UniXP.Common.MENUITEM objMenuItem, System.String strCaption)
        {
            frmBankStatement obj = new frmBankStatement(objMenuItem.objProfile, objMenuItem);
            obj.Text = strCaption;
            obj.MdiParent = objMenuItem.objProfile.m_objMDIManager.MdiParent;
            obj.Visible = true;
        }
    }

    /// <summary>
    /// Класс – хранящий информацию, которая передается получателям уведомления о событии
    /// </summary>
    public partial class ChangeEarningPropertieEventArgs : EventArgs
    {
        private readonly CEarning m_objEarning;
        public CEarning Earning
        {
            get { return m_objEarning; }
        }

        private readonly enumActionSaveCancel m_enActionType;
        public enumActionSaveCancel ActionType
        {
            get { return m_enActionType; }
        }

        private readonly System.Boolean m_bIsNewEarning;
        public System.Boolean IsNewEarning
        {
            get { return m_bIsNewEarning; }
        }

        public ChangeEarningPropertieEventArgs(CEarning objEarning, enumActionSaveCancel enActionType, System.Boolean bIsNewEarning)
        {
            m_objEarning = objEarning;
            m_enActionType = enActionType;
            m_bIsNewEarning = bIsNewEarning;
        }
    }

}
