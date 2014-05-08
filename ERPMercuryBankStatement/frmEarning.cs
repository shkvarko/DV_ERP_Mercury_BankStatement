using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading;
using System.Windows.Forms;
using ERP_Mercury.Common;
using OfficeOpenXml;
using DevExpress.Data;
using DevExpress.Utils;

namespace ERPMercuryBankStatement
{
    public enum enumPaymentType
    {
        Unkown = 0,
        PaymentForm1 = 1,
        PaymentForm2 = 2
    }

    public partial class frmEarning : DevExpress.XtraEditors.XtraForm
    {
        #region Свойства
        private UniXP.Common.CProfile m_objProfile;
        private UniXP.Common.MENUITEM m_objMenuItem;
        private System.Boolean m_bOnlyView;
        private System.Boolean m_bIsChanged;
        private System.Boolean m_bDisableEvents;
        private System.Boolean m_bNewObject;
        private enumPaymentType m_enumPaymentType;
        private System.Int32 m_GroupKeyId;        
        private List<CCustomer> m_objCustomerList;
        private List<CEarning> m_objEarningList;
        private CEarning m_objSelectedEarning;
        private List<CDebitDocument> m_objDebitDocumentList;
        private List<CEarningHistory> m_objEarningHistoryList;
        private List<CPaidDocument> m_objPaidDocumentList;
        public List<CDebitDocument> m_objResultAutoPaid;
        private List<CEarning> m_objReportEarningArjList;
        private List<CDebitDocument> m_objReportDebtorList;

        private DevExpress.XtraGrid.Views.Base.ColumnView ColumnView
        {
            get { return gridControlEarningList.MainView as DevExpress.XtraGrid.Views.Base.ColumnView; }
        }

        private DevExpress.XtraGrid.Views.Base.ColumnView ColumnViewDebitDoc
        {
            get { return gridControlDebitDocList.MainView as DevExpress.XtraGrid.Views.Base.ColumnView; }
        }

        private DevExpress.XtraGrid.Views.Base.ColumnView ColumnViewEarningHistory
        {
            get { return gridControlEarningHistoryList.MainView as DevExpress.XtraGrid.Views.Base.ColumnView; }
        }

        private DevExpress.XtraGrid.Views.Base.ColumnView ColumnViewPaidDocument
        {
            get { return gridControlPaidDocumentList.MainView as DevExpress.XtraGrid.Views.Base.ColumnView; }
        }

        private DevExpress.XtraGrid.Views.Base.ColumnView ColumnViewAutoPaidDocument
        {
            get { return gridControlAutoPaidDocList.MainView as DevExpress.XtraGrid.Views.Base.ColumnView; }
        }

        private DevExpress.XtraGrid.Views.Base.ColumnView ColumnViewReportEarningArj
        {
            get { return gridControlReportEarningArj.MainView as DevExpress.XtraGrid.Views.Base.ColumnView; }
        }

        private DevExpress.XtraGrid.Views.Base.ColumnView ColumnViewReportDebtor
        {
            get { return gridControlReportDebtor.MainView as DevExpress.XtraGrid.Views.Base.ColumnView; }
        }

        // потоки
        public System.Threading.Thread ThreadLoadCustomerList { get; set; }
        public System.Threading.Thread ThreadLoadEarningList { get; set; }
        public System.Threading.Thread ThreadLoadDebitDocumentList { get; set; }
        public System.Threading.Thread ThreadLoadEarningHistoryList { get; set; }
        public System.Threading.Thread ThreadLoadPaidDocumentList { get; set; }
        public System.Threading.Thread ThreadPayDocumentList { get; set; }
        public System.Threading.Thread ThreadAutoPayDocumentList { get; set; }
        public System.Threading.Thread ThreadReportEarningArj { get; set; }
        public System.Threading.Thread ThreadReportDebtor { get; set; }

        public System.Threading.ManualResetEvent EventStopThread { get; set; }
        public System.Threading.ManualResetEvent EventThreadStopped { get; set; }

        public delegate void LoadCustomerListDelegate(List<CCustomer> objCustomerList, System.Int32 iRowCountInLis);
        public LoadCustomerListDelegate m_LoadCustomerListDelegate;

        public delegate void LoadEarningListDelegate(List<CEarning> objEarningList, System.Int32 iRowCountInList);
        public LoadEarningListDelegate m_LoadEarningListDelegate;

        public delegate void LoadDebitDocumentListDelegate(List<CDebitDocument> objDebitDocumentList, System.Int32 iRowCountInList);
        public LoadDebitDocumentListDelegate m_LoadDebitDocumentListDelegate;

        public delegate void LoadEarningHistoryListDelegate(List<CEarningHistory> objEarningHistoryList, System.Int32 iRowCountInList);
        public LoadEarningHistoryListDelegate m_LoadEarningHistoryListDelegate;

        public delegate void LoadPaidDocumentListDelegate(List<CPaidDocument> objPaidDocumentList, System.Int32 iRowCountInList);
        public LoadPaidDocumentListDelegate m_LoadPaidDocumentListDelegate;

        public delegate void LoadReportEarningArjDelegate(List<CEarning> objReportEarningArjList, System.Int32 iRowCountInList);
        public LoadReportEarningArjDelegate m_LoadReportEarningArjDelegate;

        public delegate void LoadReportDebtorDelegate(List<CDebitDocument> objReportDebtorList, System.Int32 iRowCountInList);
        public LoadReportDebtorDelegate m_LoadReportDebtorDelegate;
        
        public delegate void SetPaymentInDebitDocumentDelegate(System.Int32 iWaybill_Id, System.Int32 ERROR_NUM, System.String ERROR_STR,
            System.Decimal FINDED_MONEY, System.Decimal ALLFINDED_MONEY, 
            System.String DOC_NUM, System.DateTime DOC_DATE, System.Decimal DOC_SALDO, 
            System.Decimal EARNING_EXPENSE, System.Decimal EARNING_SALDO, 
            System.Int32 iCurrentIndex, System.Int32 iAllObjectCount, System.Boolean bLastPayment, 
            System.Boolean bPreparePayment);
        public SetPaymentInDebitDocumentDelegate m_SetPaymentInDebitDocumentDelegate;

        public delegate void SetInfoInSearchProcessWoringDelegate(System.Int32 iCurrentIndex, System.Int32 iAllObjectCount,
            System.Decimal EARNING_VALUE, System.String CUSTOMER_NAME, System.Decimal DEBIT_ALLVALUE
            );
        public SetInfoInSearchProcessWoringDelegate m_SetInfoInSearchProcessWoringDelegate;

        public delegate void SetResultAutoPayDebitDocumentListDelegate(System.Int32 ERROR_NUM, System.String ERROR_STR, 
            System.String CUSTOMER_NAME,  System.Decimal FINDED_MONEY, System.Decimal ALLFINDED_MONEY, System.Int32 DOC_ID,
            System.String DOC_NUM, System.DateTime DOC_DATE, System.Decimal DOC_TOTALPRICE, System.Decimal DOC_SALDO,
            System.Boolean bLastPayment);
        public SetResultAutoPayDebitDocumentListDelegate m_SetResultAutoPayDebitDocumentListDelegate;


        private const System.Int32 iThreadSleepTime = 1000;
        private const System.String strWaitCustomer = "ждите... идет заполнение списка";
        private System.Boolean m_bThreadFinishJob;
        private const System.String strRegistryTools = "\\EarningListTools\\";
        private const System.Int32 iWaitingpanelIndex = 0;
        private const System.Int32 iWaitingpanelHeight = 35;
        private const System.String m_strModeReadOnly = "Режим просмотра";
        private const System.String m_strModeEdit = "Режим редактирования";
        private const string STR_IncludeInManualPay = "IncludeInManualPay";
        private const System.Int32 m_iPaymentForWaybillId = 0;
        

        #endregion

        #region Конструктор
        public frmEarning(UniXP.Common.MENUITEM objMenuItem)
        {
            InitializeComponent();

            m_objMenuItem = objMenuItem;
            m_objProfile = objMenuItem.objProfile;
            m_bThreadFinishJob = false;
            m_objCustomerList = new List<CCustomer>();
            m_objEarningList = new List<CEarning>();
            m_objDebitDocumentList = new List<CDebitDocument>();
            m_objEarningHistoryList = new List<CEarningHistory>();
            m_objPaidDocumentList = new List<CPaidDocument>();
            m_objResultAutoPaid = new List<CDebitDocument>();
            m_objReportEarningArjList = new List<CEarning>();
            m_objReportDebtorList = new List<CDebitDocument>();
            m_objSelectedEarning = null;
            m_enumPaymentType = enumPaymentType.PaymentForm1;
            m_GroupKeyId = GenerateGroupKeyId();

            AddGridColumns();
            dtBeginDate.DateTime = System.DateTime.Today; // new DateTime(System.DateTime.Today.Year, System.DateTime.Today.Month, 1);
            dtEndDate.DateTime = System.DateTime.Today;
            dtBeginDatePaidDocument.DateTime = System.DateTime.Today; 
            dtEndDatePaidDocument.DateTime = System.DateTime.Today;
            dtBeginDateReportEarningArj.DateTime = System.DateTime.Today;
            dtEnddateReportEarningArj.DateTime = System.DateTime.Today; 
            RestoreLayoutFromRegistry();

            SearchProcessWoring.Visible = false;
            tabControl.ShowTabHeader = DevExpress.Utils.DefaultBoolean.False;
            m_bOnlyView = false;
            m_bIsChanged = false;
            m_bDisableEvents = false;
            m_bNewObject = false;

        }
        #endregion

        #region Открытие формы

        private int GenerateGroupKeyId()
        {
            Random rnd = new Random(DateTime.Now.Millisecond);
            return rnd.Next(1, 10000);
        }

        private void frmEarning_Shown(object sender, EventArgs e)
        {
            try
            {
                LoadComboBox();

                StartThreadLoadEarningList();

                StartThreadLoadCustomerList();

                if (m_objProfile.GetClientsRight().GetState(Consts.strDR_PaymentsForm1OnlyViewReports) == true)
                {
                    tabControl.SelectedTabPage = tabPageReports;
                    btnReportEarningArjreturnToEarningList.Visible = false;
                    btnReportDebtorReturnToEarningList.Visible = false;

                    tableLayoutPanel29.ColumnStyles[0].Width = 0;
                    tableLayoutPanel31.ColumnStyles[0].Width = 0;
                }
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("frmEarning_Shown().\n\nТекст ошибки: " + f.Message, "Ошибка",
                    System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }

            return;
        }

        private void frmEarning_FormClosing(object sender, FormClosingEventArgs e)
        {
            try
            {
                if ((ThreadAutoPayDocumentList != null) && (ThreadAutoPayDocumentList.IsAlive == true))
                {
                    e.Cancel = true;

                    DevExpress.XtraEditors.XtraMessageBox.Show("Пожалуйста, дождитесь завершения операции автоматической оплаты задолженности", "Внимание",
                       System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Warning);

                }
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("frmEarning_FormClosing.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally
            {
            }

            return;
        }


        #endregion

        #region Настройки грида
        private void AddGridColumns()
        {
            ColumnView.Columns.Clear();
        
            AddGridColumn(ColumnView, "ID", "Идентификатор");
            AddGridColumn(ColumnView, "GroupKeyId", "№ выписки");
            AddGridColumn(ColumnView, "Date", "Дата платежа");
            AddGridColumn(ColumnView, "DocNom", "№ док-та");
            AddGridColumn(ColumnView, "AccountNumber", "Счёт плательщика");
            AddGridColumn(ColumnView, "CodeBank", "Код банка");
            AddGridColumn(ColumnView, "CurrencyCode", "Валюта");
            AddGridColumn(ColumnView, "Value", "Сумма платежа");
            AddGridColumn(ColumnView, "Expense", "Сумма расходов");
            AddGridColumn(ColumnView, "Saldo", "Сальдо");
            AddGridColumn(ColumnView, "CustomerName", "Плательщик");
            AddGridColumn(ColumnView, STR_IncludeInManualPay, "Ручная оплата");
            AddGridColumn(ColumnView, "EarningTypeName", "Вид платежа");
            
            AddGridColumn(ColumnView, "CustomrText", "Описание плательщика");
            AddGridColumn(ColumnView, "DetailsPayment", "Назначение платежа");
            AddGridColumn(ColumnView, "InterBaseID", "УИ");
            AddGridColumn(ColumnView, "EarningType_Id", "Вид платежа (код)");

            foreach (DevExpress.XtraGrid.Columns.GridColumn objColumn in ColumnView.Columns)
            {
                objColumn.OptionsColumn.AllowEdit = (objColumn.FieldName == STR_IncludeInManualPay);
                objColumn.OptionsColumn.AllowFocus = (objColumn.FieldName == STR_IncludeInManualPay);
                objColumn.OptionsColumn.ReadOnly = (objColumn.FieldName != STR_IncludeInManualPay);

                if ((objColumn.FieldName == "ID") || (objColumn.FieldName == "CustomrText") || (objColumn.FieldName == "EarningType_Id"))
                {
                    objColumn.Visible = false;
                }

                if ((objColumn.FieldName == "Value") || (objColumn.FieldName == "Expense") || (objColumn.FieldName == "Saldo"))
                {
                    objColumn.DisplayFormat.FormatType = DevExpress.Utils.FormatType.Numeric;
                    objColumn.DisplayFormat.FormatString = "### ### ### ##0.00";
                    objColumn.SummaryItem.FieldName = objColumn.FieldName;
                    objColumn.SummaryItem.DisplayFormat = "Итого: {0:### ### ### ##0.00}";
                    objColumn.SummaryItem.SummaryType = DevExpress.Data.SummaryItemType.Sum;
                }

            }

            // журнал документов на оплату
            ColumnViewDebitDoc.Columns.Clear();

            AddGridColumn(ColumnViewDebitDoc, "SrcCode", "Тип документа");
            AddGridColumn(ColumnViewDebitDoc, "Waybill_Id", "УИ документа");
            AddGridColumn(ColumnViewDebitDoc, "Waybill_ShipMode", "Вид отгрузки");
            AddGridColumn(ColumnViewDebitDoc, "Waybill_IsPaid", "");
            AddGridColumn(ColumnViewDebitDoc, "Waybill_Num", "ТТН №");
            AddGridColumn(ColumnViewDebitDoc, "Waybill_BeginDate", "Дата ТТН");
            AddGridColumn(ColumnViewDebitDoc, "Waybill_EndDate", "Оплатить ТТН до");
            AddGridColumn(ColumnViewDebitDoc, "Waybill_TotalPrice", "Сумма");
            AddGridColumn(ColumnViewDebitDoc, "Waybill_AmountPaid", "Оплачено");
            AddGridColumn(ColumnViewDebitDoc, "Waybill_Saldo", "Сальдо");
            AddGridColumn(ColumnViewDebitDoc, "Waybill_DateLastPaid", "Дата оплаты");
            AddGridColumn(ColumnViewDebitDoc, "Waybill_ShipModeName", "Вид отгрузки");
            AddGridColumn(ColumnViewDebitDoc, "Stock_Name", "Склад отгрузки");
            AddGridColumn(ColumnViewDebitDoc, "Customer_Name", "Клиент");

            foreach (DevExpress.XtraGrid.Columns.GridColumn objColumn in ColumnViewDebitDoc.Columns)
            {
                objColumn.OptionsColumn.AllowEdit = false;
                objColumn.OptionsColumn.AllowFocus = false;
                objColumn.OptionsColumn.ReadOnly = true;

                if ((objColumn.FieldName == "SrcCode") || 
                    (objColumn.FieldName == "Waybill_Id") ||
                    (objColumn.FieldName == "Waybill_ShipMode"))
                {
                    objColumn.Visible = false;
                }

                if(objColumn.FieldName == "Waybill_IsPaid")
                {
                    objColumn.Width = 16;
                    objColumn.OptionsColumn.AllowSize = false;
                    objColumn.OptionsColumn.AllowMove = false;
                    objColumn.OptionsColumn.FixedWidth = true;    
                }

                if ((objColumn.FieldName == "Waybill_TotalPrice") || (objColumn.FieldName == "Waybill_Saldo") || (objColumn.FieldName == "Waybill_AmountPaid"))
                {
                    objColumn.DisplayFormat.FormatType = DevExpress.Utils.FormatType.Numeric;
                    objColumn.DisplayFormat.FormatString = "### ### ##0";
                    objColumn.SummaryItem.FieldName = objColumn.FieldName;
                    objColumn.SummaryItem.DisplayFormat = "Итого: {0:### ### ##0}";
                    objColumn.SummaryItem.SummaryType = DevExpress.Data.SummaryItemType.Sum;
                }
            }

            // журнал истории оплат
            ColumnViewEarningHistory.Columns.Clear();

            AddGridColumn(ColumnViewEarningHistory, "OperName", "Вид операции");
            AddGridColumn(ColumnViewEarningHistory, "Waybill_Id", "УИ документа");
            AddGridColumn(ColumnViewEarningHistory, "Waybill_ShipDate", "Дата отгрузки ТТН");
            AddGridColumn(ColumnViewEarningHistory, "Waybill_Num", "ТТН №");
            AddGridColumn(ColumnViewEarningHistory, "Company_Acronym", "Компания");
            AddGridColumn(ColumnViewEarningHistory, "Customer_Name", "Клиент");
            AddGridColumn(ColumnViewEarningHistory, "Waybill_TotalPrice", "Сумма ТТН, руб.");
            AddGridColumn(ColumnViewEarningHistory, "Payment_Value", "Сумма оплаты (операции)");
            AddGridColumn(ColumnViewEarningHistory, "Waybill_Saldo", "Сальдо ТТН, руб.");
            AddGridColumn(ColumnViewEarningHistory, "Payment_OperDate", "Дата разноски");
            AddGridColumn(ColumnViewEarningHistory, "Earning_BankDate", "Дата платежа");
            
            foreach (DevExpress.XtraGrid.Columns.GridColumn objColumn in ColumnViewEarningHistory.Columns)
            {
                objColumn.OptionsColumn.AllowEdit = false;
                objColumn.OptionsColumn.AllowFocus = false;
                objColumn.OptionsColumn.ReadOnly = true;

                if(objColumn.FieldName == "Waybill_Id")
                {
                    objColumn.Visible = false;
                }

                if ((objColumn.FieldName == "Waybill_TotalPrice") || (objColumn.FieldName == "Waybill_Saldo") || (objColumn.FieldName == "Payment_Value"))
                {
                    objColumn.DisplayFormat.FormatType = DevExpress.Utils.FormatType.Numeric;
                    objColumn.DisplayFormat.FormatString = "### ### ##0";
                    objColumn.SummaryItem.FieldName = objColumn.FieldName;
                    objColumn.SummaryItem.DisplayFormat = "Итого: {0:### ### ##0}";
                    objColumn.SummaryItem.SummaryType = DevExpress.Data.SummaryItemType.Sum;
                }
            }

            // журнал оплаченных документов
            ColumnViewPaidDocument.Columns.Clear();

            AddGridColumn(ColumnViewPaidDocument, "Waybill_Id", "УИ документа");
            AddGridColumn(ColumnViewPaidDocument, "Waybill_BeginDate", "Дата ТТН");
            AddGridColumn(ColumnViewPaidDocument, "Drop", " ");
            AddGridColumn(ColumnViewPaidDocument, "strWaybill_ShipDate", "Дата отгрузки ТТН");
            AddGridColumn(ColumnViewPaidDocument, "Waybill_Num", "ТТН №");
            AddGridColumn(ColumnViewPaidDocument, "Company_Acronym", "Компания");
            AddGridColumn(ColumnViewPaidDocument, "Customer_Name", "Клиент");
            AddGridColumn(ColumnViewPaidDocument, "Depart_Code", "Подр-е");
            AddGridColumn(ColumnViewPaidDocument, "Waybill_Quantity", "Кол-во");
            AddGridColumn(ColumnViewPaidDocument, "Waybill_TotalPrice", "Сумма ТТН, руб.");
            AddGridColumn(ColumnViewPaidDocument, "Waybill_RetAllPrice", "Сумма возврата, руб.");
            AddGridColumn(ColumnViewPaidDocument, "Waybill_AmountPaid", "Сумма оплаты");
            AddGridColumn(ColumnViewPaidDocument, "Waybill_Saldo", "Сальдо ТТН, руб.");

            foreach (DevExpress.XtraGrid.Columns.GridColumn objColumn in ColumnViewPaidDocument.Columns)
            {
                objColumn.OptionsColumn.AllowEdit = false;
                objColumn.OptionsColumn.AllowFocus = false;
                objColumn.OptionsColumn.ReadOnly = true;

                if (objColumn.FieldName == "Waybill_Id")
                {
                    objColumn.Visible = false;
                }

                if ((objColumn.FieldName == "Waybill_TotalPrice") || (objColumn.FieldName == "Waybill_Saldo") ||
                    (objColumn.FieldName == "Waybill_Quantity") || (objColumn.FieldName == "Waybill_RetAllPrice") || (objColumn.FieldName == "Waybill_AmountPaid"))
                {
                    objColumn.DisplayFormat.FormatType = DevExpress.Utils.FormatType.Numeric;
                    objColumn.DisplayFormat.FormatString = "### ### ##0";
                    objColumn.SummaryItem.FieldName = objColumn.FieldName;
                    objColumn.SummaryItem.DisplayFormat = "Итого: {0:### ### ##0}";
                    objColumn.SummaryItem.SummaryType = DevExpress.Data.SummaryItemType.Sum;
                }
            }


            // журнал автоматически оплаченных документов
            ColumnViewAutoPaidDocument.Columns.Clear();

            AddGridColumn(ColumnViewAutoPaidDocument, "Waybill_Num", "ТТН №");
            AddGridColumn(ColumnViewAutoPaidDocument, "Waybill_BeginDate", "Дата ТТН");
            AddGridColumn(ColumnViewAutoPaidDocument, "Waybill_TotalPrice", "Сумма ТТН");
            AddGridColumn(ColumnViewAutoPaidDocument, "Waybill_AmountPaid", "Оплачено (авто)");
            AddGridColumn(ColumnViewAutoPaidDocument, "Waybill_Saldo", "Сальдо ТТН");
            AddGridColumn(ColumnViewAutoPaidDocument, "Customer_Name", "Клиент");

            foreach (DevExpress.XtraGrid.Columns.GridColumn objColumn in ColumnViewAutoPaidDocument.Columns)
            {
                objColumn.OptionsColumn.AllowEdit = false;
                objColumn.OptionsColumn.AllowFocus = false;
                objColumn.OptionsColumn.ReadOnly = true;

                if ((objColumn.FieldName == "Waybill_TotalPrice") || (objColumn.FieldName == "Waybill_Saldo") || (objColumn.FieldName == "Waybill_AmountPaid"))
                {
                    objColumn.DisplayFormat.FormatType = DevExpress.Utils.FormatType.Numeric;
                    objColumn.DisplayFormat.FormatString = "### ### ##0";
                    objColumn.SummaryItem.FieldName = objColumn.FieldName;
                    objColumn.SummaryItem.DisplayFormat = "Итого: {0:### ### ##0}";
                    objColumn.SummaryItem.SummaryType = DevExpress.Data.SummaryItemType.Sum;
                }
            }

            // отчёт "Архив платежей"
            ColumnViewReportEarningArj.Columns.Clear();

            AddGridColumn(ColumnViewReportEarningArj, "DetailsPayment", "Назначение платежа");
            AddGridColumn(ColumnViewReportEarningArj, "Date", "Дата платежа");
            AddGridColumn(ColumnViewReportEarningArj, "CustomerName", "Плательщик");
            AddGridColumn(ColumnViewReportEarningArj, "Value", "Сумма платежа");
            AddGridColumn(ColumnViewReportEarningArj, "Expense", "Сумма расходов");
            AddGridColumn(ColumnViewReportEarningArj, "Saldo", "Сальдо");
            

            foreach (DevExpress.XtraGrid.Columns.GridColumn objColumn in ColumnViewReportEarningArj.Columns)
            {
                objColumn.OptionsColumn.AllowEdit = false;
                objColumn.OptionsColumn.AllowFocus = false;
                objColumn.OptionsColumn.ReadOnly = true;

                if ((objColumn.FieldName == "Value") || (objColumn.FieldName == "Expense") || (objColumn.FieldName == "Saldo"))
                {
                    objColumn.DisplayFormat.FormatType = DevExpress.Utils.FormatType.Numeric;
                    objColumn.DisplayFormat.FormatString = "### ### ### ##0";
                    objColumn.SummaryItem.FieldName = objColumn.FieldName;
                    objColumn.SummaryItem.DisplayFormat = "Итого: {0:### ### ### ##0}";
                    objColumn.SummaryItem.SummaryType = DevExpress.Data.SummaryItemType.Sum;
                }
            }

            // отчёт "Дебиторы"
            ColumnViewReportDebtor.Columns.Clear();

            //AddGridColumn(ColumnViewReportDebtor, "Debt_Type", "Тип");
            AddGridColumn(ColumnViewReportDebtor, "Waybill_Id", "УИ документа");
            AddGridColumn(ColumnViewReportDebtor, "Waybill_ShipMode", "Вид отгрузки");
            AddGridColumn(ColumnViewReportDebtor, "Waybill_Num", "ТТН №");
            AddGridColumn(ColumnViewReportDebtor, "Waybill_ShipDate", "Отгружено");
            AddGridColumn(ColumnViewReportDebtor, "Waybill_TotalPrice", "К оплате");
            AddGridColumn(ColumnViewReportDebtor, "Waybill_AmountPaid", "Оплачено");
            AddGridColumn(ColumnViewReportDebtor, "Waybill_Saldo", "Сальдо");

            AddGridColumn(ColumnViewReportDebtor, "CustomerLimit_ApprovedSumma", "Лимит, руб.");
            AddGridColumn(ColumnViewReportDebtor, "CustomerLimit_ApprovedDays", "Отсрочка, дней");
            AddGridColumn(ColumnViewReportDebtor, "Waybill_ExpDays", "Просрочено, дней");
            
            AddGridColumn(ColumnViewReportDebtor, "Waybill_ShipModeName", "Вид отгрузки");
            AddGridColumn(ColumnViewReportDebtor, "Customer_Name", "Клиент");
            AddGridColumn(ColumnViewReportDebtor, "Depart_Code", "Подр-е");
            AddGridColumn(ColumnViewReportDebtor, "Stock_Name", "Склад отгрузки");

            foreach (DevExpress.XtraGrid.Columns.GridColumn objColumn in ColumnViewReportDebtor.Columns)
            {
                objColumn.OptionsColumn.AllowEdit = false;
                objColumn.OptionsColumn.AllowFocus = false;
                objColumn.OptionsColumn.ReadOnly = true;

                if ((objColumn.FieldName == "SrcCode") ||
                    (objColumn.FieldName == "Waybill_Id") ||
                    (objColumn.FieldName == "Waybill_ShipMode"))
                {
                    objColumn.Visible = false;
                }

                if ((objColumn.FieldName == "Waybill_TotalPrice") || (objColumn.FieldName == "Waybill_Saldo") ||
                    (objColumn.FieldName == "Waybill_AmountPaid") || (objColumn.FieldName == "CustomerLimit_ApprovedSumma") ||
                    (objColumn.FieldName == "CustomerLimit_ApprovedDays") || (objColumn.FieldName == "Waybill_ExpDays"))
                {
                    objColumn.DisplayFormat.FormatType = DevExpress.Utils.FormatType.Numeric;
                    objColumn.DisplayFormat.FormatString = "### ### ### ##0";
                }
                if ((objColumn.FieldName == "Waybill_TotalPrice") || (objColumn.FieldName == "Waybill_Saldo") ||
                    (objColumn.FieldName == "Waybill_AmountPaid") )
                {
                    objColumn.SummaryItem.FieldName = objColumn.FieldName;
                    objColumn.SummaryItem.DisplayFormat = "Итого: {0:### ### ### ##0}";
                    objColumn.SummaryItem.SummaryType = DevExpress.Data.SummaryItemType.Sum;
                }
            }


        }
        private void AddGridColumn(DevExpress.XtraGrid.Views.Base.ColumnView view, string fieldName, string caption) { AddGridColumn(view, fieldName, caption, null); }
        private void AddGridColumn(DevExpress.XtraGrid.Views.Base.ColumnView view, string fieldName, string caption, DevExpress.XtraEditors.Repository.RepositoryItem item) { AddGridColumn(view, fieldName, caption, item, "", DevExpress.Utils.FormatType.None); }
        private void AddGridColumn(DevExpress.XtraGrid.Views.Base.ColumnView view, string fieldName, string caption, DevExpress.XtraEditors.Repository.RepositoryItem item, string format, DevExpress.Utils.FormatType type)
        {
            DevExpress.XtraGrid.Columns.GridColumn column = view.Columns.AddField(fieldName);
            column.Caption = caption;
            column.ColumnEdit = item;
            column.DisplayFormat.FormatType = type;
            column.DisplayFormat.FormatString = format;
            column.VisibleIndex = view.VisibleColumns.Count;
        }

        #region Настройки внешнего вида журналов
        /// <summary>
        /// Считывает настройки журналов из реестра
        /// </summary>
        public void RestoreLayoutFromRegistry()
        {
            System.String strReestrPath = this.m_objProfile.GetRegKeyBase();
            strReestrPath += (strRegistryTools);
            try
            {
                gridViewEarningList.RestoreLayoutFromRegistry(strReestrPath + gridViewEarningList.Name);
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show(
                "Ошибка загрузки настроек журнала платежей.\n\nТекст ошибки : " + f.Message, "Внимание",
                System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally // очищаем занимаемые ресурсы
            {
            }

            return;
        }
        /// <summary>
        /// Записывает настройки журналов в реестр
        /// </summary>
        public void SaveLayoutToRegistry()
        {
            System.String strReestrPath = this.m_objProfile.GetRegKeyBase();
            strReestrPath += (strRegistryTools);
            try
            {
                gridViewEarningList.SaveLayoutToRegistry(strReestrPath + gridViewEarningList.Name);
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show(
                "Ошибка записи настроек журнала платежей.\n\nТекст ошибки : " + f.Message, "Внимание",
                System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally // очищаем занимаемые ресурсы
            {
            }

            return;
        }
        #endregion

        #endregion

        #region Потоки
        /// <summary>
        /// Стартует поток, в котором загружается список клиентов
        /// </summary>
        public void StartThreadLoadCustomerList()
        {
            try
            {
                // инициализируем делегаты
                m_LoadCustomerListDelegate = new LoadCustomerListDelegate( LoadCustomerList );
                m_objCustomerList.Clear();

                barBtnAdd.Enabled = false;
                barBtnEdit.Enabled = false;
                btnCopyEarning.Enabled = false;
                barBtnDelete.Enabled = false;
                barBtnRefresh.Enabled = false;
                barBtnDebitDocumentList.Enabled = false;
                barBtnEarningHistoryView.Enabled = false;
                barBtnPaidDocumentList.Enabled = false;
                btnAutoPayEarningList.Enabled = false;

                gridControlEarningList.MouseDoubleClick -= new MouseEventHandler(gridControlEarningList_MouseDoubleClick);

                // запуск потока
                this.ThreadLoadCustomerList = new System.Threading.Thread(LoadCustomerListInThread);
                this.ThreadLoadCustomerList.Start();
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("StartThreadWithLoadData().\n\nТекст ошибки: " + f.Message, "Ошибка",
                    System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }

            return;
        }
        /// <summary>
        /// Загружает список клиентов
        /// </summary>
        public void LoadCustomerListInThread()
        {
            try
            {
                List<CCustomer> objCustomerList = CCustomer.GetCustomerListWithoutAdvancedProperties( m_objProfile, null, null );


                List<CCustomer> objAddCustomerList = new List<CCustomer>();
                if ((objCustomerList != null) && (objCustomerList.Count > 0))
                {
                    System.Int32 iRecCount = 0;
                    System.Int32 iRecAllCount = 0;
                    foreach (CCustomer objCustomer in objCustomerList)
                    {
                        objAddCustomerList.Add(objCustomer);
                        iRecCount++;
                        iRecAllCount++;

                        if (iRecCount == 1000)
                        {
                            iRecCount = 0;
                            Thread.Sleep(1000);
                            this.Invoke(m_LoadCustomerListDelegate, new Object[] { objAddCustomerList, iRecAllCount });
                            objAddCustomerList.Clear();
                        }

                    }
                    if (iRecCount != 1000)
                    {
                        iRecCount = 0;
                        this.Invoke(m_LoadCustomerListDelegate, new Object[] { objAddCustomerList, iRecAllCount });
                        objAddCustomerList.Clear();
                    }

                }

                objCustomerList = null;
                objAddCustomerList = null;
                this.Invoke(m_LoadCustomerListDelegate, new Object[] { null, 0 });
                this.m_bThreadFinishJob = true;
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("LoadCustomerListInThread.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally
            {
            }
            return;
        }
        /// <summary>
        /// загружает в combobox список клиентов
        /// </summary>
        /// <param name="objCustomerList">список клиентов</param>
        /// <param name="iRowCountInList">количество строк, которые требуется загрузить в combobox</param>
        private void LoadCustomerList(List<CCustomer> objCustomerList, System.Int32 iRowCountInList)
        {
            try
            {
                cboxCustomer.Text = strWaitCustomer;
                if ((objCustomerList != null) && (objCustomerList.Count > 0) && (cboxCustomer.Properties.Items.Count < iRowCountInList))
                {
                    cboxCustomer.Properties.Items.AddRange( objCustomerList );
                    cboxCustomerPaidDocument.Properties.Items.AddRange(objCustomerList);
                    cboxCustomerReportDebtor.Properties.Items.AddRange(objCustomerList);
                    cboxCustomerReportEarningArj.Properties.Items.AddRange(objCustomerList);

                    editorEarningCustomer.Properties.Items.AddRange(objCustomerList);
                    m_objCustomerList.AddRange(objCustomerList);
                }
                else
                {
                    cboxCustomer.Text = "";
                    cboxCustomerPaidDocument.Text = "";
                    barBtnAdd.Enabled = !m_bOnlyView;
                    barBtnEdit.Enabled = ( gridViewEarningList.FocusedRowHandle >= 0);
                    btnCopyEarning.Enabled = (gridViewEarningList.FocusedRowHandle >= 0);
                    barBtnDelete.Enabled = ((!m_bOnlyView) && (gridViewEarningList.FocusedRowHandle >= 0));
                    barBtnDebitDocumentList.Enabled = (gridViewEarningList.FocusedRowHandle >= 0);
                    barBtnEarningHistoryView.Enabled = (gridViewEarningList.FocusedRowHandle >= 0);
                    barBtnPaidDocumentList.Enabled = true;
                    barBtnRefresh.Enabled = true;
                    btnAutoPayEarningList.Enabled = (gridViewEarningList.RowCount >= 0);
                    
                    gridControlEarningList.MouseDoubleClick += new MouseEventHandler(gridControlEarningList_MouseDoubleClick);
                }
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("LoadCustomerList.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally
            {
            }
            return;
        }

        private void barBtnRefresh_Click(object sender, EventArgs e)
        {
            try
            {
                StartThreadLoadEarningList();
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("barBtnRefresh_Click.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally
            {
            }
            return;

        }
        private void dtBeginDate_KeyPress(object sender, KeyPressEventArgs e)
        {
            try
            {
                if( (e.KeyChar == (char)Keys.Enter) && ( barBtnRefresh.Visible == true ) )
                {
                    StartThreadLoadEarningList();
                }
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("dtBeginDate_KeyPress.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally
            {
            }
            return;

        }

        /// <summary>
        /// Стартует поток, в котором загружается список платежей
        /// </summary>
        public void StartThreadLoadEarningList()
        {
            try
            {
                // инициализируем делегаты
                m_LoadEarningListDelegate = new LoadEarningListDelegate(LoadEarningListInGrid);
                m_objEarningList.Clear();

                barBtnAdd.Enabled = false;
                barBtnEdit.Enabled = false;
                btnCopyEarning.Enabled = false;
                barBtnDelete.Enabled = false;
                barBtnRefresh.Enabled = false;
                barBtnDebitDocumentList.Enabled = false;
                barBtnEarningHistoryView.Enabled = false;
                barBtnPaidDocumentList.Enabled = false;
                btnAutoPayEarningList.Enabled = false;

                gridControlEarningList.DataSource = null;
                SearchProcessWoring.Visible = true;
                SearchProcessWoring.Refresh();

                //gridControlEarningList.MouseDoubleClick -= new MouseEventHandler(gridControlEarningList_MouseDoubleClick);

                // запуск потока
                this.ThreadLoadEarningList = new System.Threading.Thread(LoadEarningListInThread);
                this.ThreadLoadEarningList.Start();
                Thread.Sleep(1000);

            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("StartThreadLoadEarningList().\n\nТекст ошибки: " + f.Message, "Ошибка",
                    System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }

            return;
        }


        /// <summary>
        /// Загружает список платежей
        /// </summary>
        public void LoadEarningListInThread()
        {
            try
            {
                System.Guid uuidCustomerId = (((cboxCustomer.SelectedItem == null) || (System.Convert.ToString(cboxCustomer.SelectedItem) == "") || (cboxCustomer.Text == strWaitCustomer)) ? System.Guid.Empty : ((CCustomer)cboxCustomer.SelectedItem).ID);
                System.Guid uuidCompanyId = (((cboxCompany.SelectedItem == null) || (System.Convert.ToString(cboxCompany.SelectedItem) == "") || (cboxCompany.Text == strWaitCustomer)) ? System.Guid.Empty : ((CCompany)cboxCompany.SelectedItem).ID);
                System.DateTime dtBeginDate = this.dtBeginDate.DateTime;
                System.DateTime dtEndDate = this.dtEndDate.DateTime;
                
                System.String strErr = "";
                List<CEarning> objEarningList = CEarningDataBaseModel.GetEarningList( m_objProfile, null, dtBeginDate, dtEndDate, uuidCompanyId, uuidCustomerId, ref strErr );

                List<CEarning> objAddEarningList = new List<CEarning>();
                if ((objEarningList != null) && (objEarningList.Count > 0))
                {
                    System.Int32 iRecCount = 0;
                    System.Int32 iRecAllCount = 0;
                    foreach (CEarning objEarning in objEarningList)
                    {
                        objAddEarningList.Add(objEarning);
                        iRecCount++;
                        iRecAllCount++;

                        if (iRecCount == 1000)
                        {
                            iRecCount = 0;
                            Thread.Sleep(1000);
                            this.Invoke(m_LoadEarningListDelegate, new Object[] { objAddEarningList, iRecAllCount });
                            objAddEarningList.Clear();
                        }

                    }
                    if (iRecCount != 1000)
                    {
                        iRecCount = 0;
                        this.Invoke(m_LoadEarningListDelegate, new Object[] { objAddEarningList, iRecAllCount });
                        objAddEarningList.Clear();
                    }

                }

                objEarningList = null;
                objAddEarningList = null;
                this.Invoke(m_LoadEarningListDelegate, new Object[] { null, 0 });
                this.m_bThreadFinishJob = true;
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("LoadEarningListInThread.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally
            {
            }
            return;
        }

        /// <summary>
        /// загружает в журнал список платежей
        /// </summary>
        /// <param name="objEarningList">список платежей</param>
        /// <param name="iRowCountInList">количество строк, которые требуется загрузить в журнал</param>
        private void LoadEarningListInGrid(List<CEarning> objEarningList, System.Int32 iRowCountInList)
        {
            try
            {
                if ((objEarningList != null) && (objEarningList.Count > 0) &&  ( gridViewEarningList.RowCount < iRowCountInList) )
                {
                    m_objEarningList.AddRange(objEarningList);
                    if (gridControlEarningList.DataSource == null)
                    {
                        gridControlEarningList.DataSource = m_objEarningList;
                    }
                    gridControlEarningList.RefreshDataSource();
                }
                else
                {
                    Thread.Sleep(1000);
                    SearchProcessWoring.Visible = false;

                    barBtnAdd.Enabled = !m_bOnlyView;
                    barBtnEdit.Enabled = (gridViewEarningList.FocusedRowHandle >= 0);
                    btnCopyEarning.Enabled = (gridViewEarningList.FocusedRowHandle >= 0); ;
                    barBtnDelete.Enabled = ((!m_bOnlyView) && (gridViewEarningList.FocusedRowHandle >= 0));
                    barBtnRefresh.Enabled = true;
                    barBtnDebitDocumentList.Enabled = (gridViewEarningList.FocusedRowHandle >= 0);
                    barBtnEarningHistoryView.Enabled = (gridViewEarningList.FocusedRowHandle >= 0);
                    btnAutoPayEarningList.Enabled = (gridViewEarningList.RowCount >= 0);
                    barBtnPaidDocumentList.Enabled = true;
                    gridControlEarningList.RefreshDataSource();

                    foreach (DevExpress.XtraGrid.Columns.GridColumn objColumn in gridViewEarningList.Columns)
                    {
                        if (objColumn.Visible == true)
                        {
                            objColumn.BestFit();
                        }
                    }


                    Cursor = Cursors.Default;

                    //gridControlEarningList.MouseDoubleClick += new MouseEventHandler(gridControlEarningList_MouseDoubleClick);
                }
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("LoadEarningListInGrid.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally
            {
            }
            return;
        }
        /// <summary>
        /// Стартует поток, в котором загружается список документов на оплату
        /// </summary>
        public void StartThreadLoadDebitDocumentList()
        {
            try
            {
                // инициализируем делегаты
                m_LoadDebitDocumentListDelegate = new LoadDebitDocumentListDelegate(LoadDebitDocumentListInGrid);
                m_objDebitDocumentList.Clear();

                gridControlDebitDocList.DataSource = null;

                // запуск потока
                this.ThreadLoadDebitDocumentList = new System.Threading.Thread(LoadDebitDocumentListInThread);
                this.ThreadLoadDebitDocumentList.Start();
                Thread.Sleep(1000);

            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("StartThreadLoadDebitDocumentList().\n\nТекст ошибки: " + f.Message, "Ошибка",
                    System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }

            return;
        }


        /// <summary>
        /// Загружает список документов на оплату
        /// </summary>
        public void LoadDebitDocumentListInThread()
        {
            try
            {
                System.Guid uuidCustomerId = (( m_objSelectedEarning.Customer == null) ? System.Guid.Empty : m_objSelectedEarning.Customer.ID);
                System.Guid uuidCompanyId = ((m_objSelectedEarning.Company == null) ? System.Guid.Empty : m_objSelectedEarning.Company.ID);

                System.String strErr = "";
                List<CDebitDocument> objDebitDocumentList = CPaymentDataBaseModel.GetDebitDocumentFormPay1List(m_objProfile, null, uuidCompanyId, uuidCustomerId, ref strErr);

                List<CDebitDocument> objAddDebitDocumentList = new List<CDebitDocument>();
                if ((objDebitDocumentList != null) && (objDebitDocumentList.Count > 0))
                {
                    System.Int32 iRecCount = 0;
                    System.Int32 iRecAllCount = 0;
                    foreach (CDebitDocument objDebitDocument in objDebitDocumentList)
                    {
                        objAddDebitDocumentList.Add(objDebitDocument);
                        iRecCount++;
                        iRecAllCount++;

                        if (iRecCount == 1000)
                        {
                            iRecCount = 0;
                            Thread.Sleep(1000);
                            this.Invoke(m_LoadDebitDocumentListDelegate, new Object[] { objAddDebitDocumentList, iRecAllCount });
                            objAddDebitDocumentList.Clear();
                        }

                    }
                    if (iRecCount != 1000)
                    {
                        iRecCount = 0;
                        this.Invoke(m_LoadDebitDocumentListDelegate, new Object[] { objAddDebitDocumentList, iRecAllCount });
                        objAddDebitDocumentList.Clear();
                    }

                }

                objDebitDocumentList = null;
                objAddDebitDocumentList = null;
                this.Invoke(m_LoadDebitDocumentListDelegate, new Object[] { null, 0 });
                this.m_bThreadFinishJob = true;
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("LoadDebitDocumentListInThread.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally
            {
            }
            return;
        }

        /// <summary>
        /// загружает в журнал список документов на оплату
        /// </summary>
        /// <param name="objDebitDocumentList">список документов на оплату</param>
        /// <param name="iRowCountInList">количество строк, которые требуется загрузить в журнал</param>
        private void LoadDebitDocumentListInGrid(List<CDebitDocument> objDebitDocumentList, System.Int32 iRowCountInList)
        {
            try
            {
                if ((objDebitDocumentList != null) && (objDebitDocumentList.Count > 0) && (gridViewDebitDocumentList.RowCount < iRowCountInList))
                {
                    m_objDebitDocumentList.AddRange(objDebitDocumentList);
                    if (gridControlDebitDocList.DataSource == null)
                    {
                        gridControlDebitDocList.DataSource = m_objDebitDocumentList;
                    }
                    gridControlDebitDocList.RefreshDataSource();
                }
                else
                {
                    Thread.Sleep(1000);

                    gridControlDebitDocList.RefreshDataSource();

                    pictureBoxInfoInDebitDocList.Image = ERPMercuryBankStatement.Properties.Resources.SpreadSheet_Total;
                    lblEarningInfoInpayDebitDocument.Text = (String.Format("Остаток платежа:\t{0:### ### ##0.00}", m_objSelectedEarning.Saldo));
                }
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("LoadDebitDocumentListInGrid.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally
            {
            }
            return;
        }

        /// <summary>
        /// Стартует поток, в котором загружается журнал разноски оплат
        /// </summary>
        public void StartThreadLoadEarningHistoryList()
        {
            try
            {
                // инициализируем делегаты
                m_LoadEarningHistoryListDelegate = new LoadEarningHistoryListDelegate(LoadEarningHistoryListInGrid);
                m_objEarningHistoryList.Clear();

                gridControlEarningHistoryList.DataSource = null;

                // запуск потока
                this.ThreadLoadEarningHistoryList = new System.Threading.Thread(LoadEarningHistoryListInThread);
                this.ThreadLoadEarningHistoryList.Start();
                Thread.Sleep(1000);

            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("StartThreadLoadEarningHistoryList().\n\nТекст ошибки: " + f.Message, "Ошибка",
                    System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }

            return;
        }


        /// <summary>
        /// Загружает журнал разноски платежей
        /// </summary>
        public void LoadEarningHistoryListInThread()
        {
            try
            {
                System.String strErr = "";
                List<CEarningHistory> objEarningHistoryList = CPaymentDataBaseModel.GetEarningHistoryList(m_objProfile, null, m_objSelectedEarning.ID, ref strErr);

                List<CEarningHistory> objAddEarningHistoryList = new List<CEarningHistory>();
                if ((objEarningHistoryList != null) && (objEarningHistoryList.Count > 0))
                {
                    System.Int32 iRecCount = 0;
                    System.Int32 iRecAllCount = 0;
                    foreach (CEarningHistory objEarningHistory in objEarningHistoryList)
                    {
                        objAddEarningHistoryList.Add(objEarningHistory);
                        iRecCount++;
                        iRecAllCount++;

                        if (iRecCount == 1000)
                        {
                            iRecCount = 0;
                            Thread.Sleep(1000);
                            this.Invoke(m_LoadEarningHistoryListDelegate, new Object[] { objAddEarningHistoryList, iRecAllCount });
                            objAddEarningHistoryList.Clear();
                        }

                    }
                    if (iRecCount != 1000)
                    {
                        iRecCount = 0;
                        this.Invoke(m_LoadEarningHistoryListDelegate, new Object[] { objAddEarningHistoryList, iRecAllCount });
                        objAddEarningHistoryList.Clear();
                    }

                }

                objEarningHistoryList = null;
                objAddEarningHistoryList = null;
                this.Invoke(m_LoadEarningHistoryListDelegate, new Object[] { null, 0 });
                this.m_bThreadFinishJob = true;
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("LoadEarningHistoryListInThread.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally
            {
            }
            return;
        }

        /// <summary>
        /// загружает в журнал историю разноски оплат
        /// </summary>
        /// <param name="objEarningHistoryList">журнал разноски оплат</param>
        /// <param name="iRowCountInList">количество строк, которые требуется загрузить в журнал</param>
        private void LoadEarningHistoryListInGrid(List<CEarningHistory> objEarningHistoryList, System.Int32 iRowCountInList)
        {
            try
            {
                if ((objEarningHistoryList != null) && (objEarningHistoryList.Count > 0) && (gridViewEarningHistoryList.RowCount < iRowCountInList))
                {
                    m_objEarningHistoryList.AddRange(objEarningHistoryList);
                    if (gridControlEarningHistoryList.DataSource == null)
                    {
                        gridControlEarningHistoryList.DataSource = m_objEarningHistoryList;
                    }
                    gridControlEarningHistoryList.RefreshDataSource();
                }
                else
                {
                    Thread.Sleep(1000);

                    gridControlEarningHistoryList.RefreshDataSource();

                    pictureBoxInfoInEarningHistoryList.Image = ERPMercuryBankStatement.Properties.Resources.SpreadSheet_Total_Check;
                    lblEarningInfoInEarningHistory.Text = (String.Format("Остаток платежа:\t{0:### ### ##0.00}", m_objSelectedEarning.Saldo));

                }
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("LoadEarningHistoryListInGrid.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally
            {
            }
            return;
        }

        /// <summary>
        /// Стартует поток, в котором загружается список оплаченных документов
        /// </summary>
        public void StartThreadLoadPaidDocumentList()
        {
            try
            {
                // инициализируем делегаты
                m_LoadPaidDocumentListDelegate = new LoadPaidDocumentListDelegate(LoadPaidDocumentListInGrid);
                m_objDebitDocumentList.Clear();

                gridControlPaidDocumentList.DataSource = null;
                m_objPaidDocumentList.Clear();
                lblPaidDocumentList.Text = strWaitCustomer;
                lblPaidDocumentList.ForeColor = Color.Red;
                lblPaidDocumentList.Refresh();
                btnRefreshPaidDocumentList.Enabled = false;

                calcDePaySum.Value = 0;
                dateDePayDate.EditValue = null;
                btnDePayPaidDocument.Enabled = false;

                // запуск потока
                this.ThreadLoadPaidDocumentList = new System.Threading.Thread(LoadPaidDocumentListInThread);
                this.ThreadLoadPaidDocumentList.Start();
                Thread.Sleep(1000);

            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("StartThreadLoadPaidDocumentList().\n\nТекст ошибки: " + f.Message, "Ошибка",
                    System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }

            return;
        }


        /// <summary>
        /// Загружает список оплаченных документов
        /// </summary>
        public void LoadPaidDocumentListInThread()
        {
            try
            {
                System.Guid uuidCustomerId = (((cboxCustomerPaidDocument.SelectedItem == null) || (cboxCustomerPaidDocument.Text.Equals(System.String.Empty))) ? System.Guid.Empty : ((CCustomer)cboxCustomerPaidDocument.SelectedItem).ID);
                System.Guid uuidCompanyId = ((cboxCompanyPaidDocument.SelectedItem == null) ? System.Guid.Empty : ((CCompany)cboxCompanyPaidDocument.SelectedItem).ID);
                System.DateTime dtBeginDate = dtBeginDatePaidDocument.DateTime;
                System.DateTime dtEndDate = dtEndDatePaidDocument.DateTime;
                System.String strWaybillNum = txtWaybillNumPaidDocument.Text;

                System.String strErr = "";
                List<CPaidDocument> objPaidDocumentList = CPaymentDataBaseModel.GetPaidDocumentFormPay1List(m_objProfile, null,
                    uuidCompanyId, uuidCustomerId, dtBeginDate, dtEndDate, strWaybillNum, ref strErr);

                List<CPaidDocument> objAddPaidDocumentList = new List<CPaidDocument>();
                if ((objPaidDocumentList != null) && (objPaidDocumentList.Count > 0))
                {
                    System.Int32 iRecCount = 0;
                    System.Int32 iRecAllCount = 0;
                    foreach (CPaidDocument objPaidDocument in objPaidDocumentList)
                    {
                        objAddPaidDocumentList.Add(objPaidDocument);
                        iRecCount++;
                        iRecAllCount++;

                        if (iRecCount == 1000)
                        {
                            iRecCount = 0;
                            Thread.Sleep(1000);
                            this.Invoke(m_LoadPaidDocumentListDelegate, new Object[] { objAddPaidDocumentList, iRecAllCount });
                            objAddPaidDocumentList.Clear();
                        }

                    }
                    if (iRecCount != 1000)
                    {
                        iRecCount = 0;
                        this.Invoke(m_LoadPaidDocumentListDelegate, new Object[] { objAddPaidDocumentList, iRecAllCount });
                        objAddPaidDocumentList.Clear();
                    }

                }

                objPaidDocumentList = null;
                objAddPaidDocumentList = null;
                this.Invoke(m_LoadPaidDocumentListDelegate, new Object[] { null, 0 });
                this.m_bThreadFinishJob = true;
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("LoadPaidDocumentListInThread.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally
            {
            }
            return;
        }

        /// <summary>
        /// загружает в журнал список оплаченных документов
        /// </summary>
        /// <param name="objPaidDocumentList">список оплаченных документов</param>
        /// <param name="iRowCountInList">количество строк, которые требуется загрузить в журнал</param>
        private void LoadPaidDocumentListInGrid(List<CPaidDocument> objPaidDocumentList, System.Int32 iRowCountInList)
        {
            try
            {
                if ((objPaidDocumentList != null) && (objPaidDocumentList.Count > 0) && (gridViewPaidDocumentList.RowCount < iRowCountInList))
                {
                    m_objPaidDocumentList.AddRange(objPaidDocumentList);
                    if (gridControlPaidDocumentList.DataSource == null)
                    {
                        gridControlPaidDocumentList.DataSource = m_objPaidDocumentList;
                    }
                    gridControlPaidDocumentList.RefreshDataSource();
                }
                else
                {
                    Thread.Sleep(1000);
                    lblPaidDocumentList.Text = "Журнал оплаченных накладных";
                    lblPaidDocumentList.ForeColor = Color.Black;
                    gridControlPaidDocumentList.RefreshDataSource();
                    btnRefreshPaidDocumentList.Enabled = true;
                }
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("LoadPaidDocumentListInGrid.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally
            {
            }
            return;
        }

        /// <summary>
        /// Стартует поток, в котором загружается отчёт "Архив платежей"
        /// </summary>
        public void StartThreadLoadReportEarningArjList()
        {
            try
            {
                // инициализируем делегаты
                m_LoadReportEarningArjDelegate = new LoadReportEarningArjDelegate( LoadReportEarningArjInGrid );
                m_objReportEarningArjList.Clear();

                btnRefreshReportEarningArj.Enabled = false;
                btnPrintReportEarningArj.Enabled = false;
                cboxCompanyReportEarningArj.Enabled = false;
                cboxCustomerReportEarningArj.Enabled = false;
                dtBeginDateReportEarningArj.Enabled = false;
                dtEnddateReportEarningArj.Enabled = false;

                gridControlReportEarningArj.DataSource = null;
                panelProgressBarReportEarningArj.Visible = true;
                progressBarControlReportEarningArj.Position = 5;
                panelProgressBarReportEarningArj.Refresh();
                this.Update();

                // запуск потока
                this.ThreadReportEarningArj = new System.Threading.Thread(LoadReportEarningArjInThread);
                this.ThreadReportEarningArj.Start();
//                Thread.Sleep(1000);

            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("StartThreadLoadReportEarningArjList().\n\nТекст ошибки: " + f.Message, "Ошибка",
                    System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }

            return;
        }


        /// <summary>
        /// Загружает отчёт "Архив платежей"
        /// </summary>
        public void LoadReportEarningArjInThread()
        {
            try
            {
                System.Guid uuidCompanyId = (((cboxCompanyReportEarningArj.SelectedItem == null) || (System.Convert.ToString(cboxCompanyReportEarningArj.SelectedItem) == "") || (cboxCompanyReportEarningArj.Text == strWaitCustomer)) ? System.Guid.Empty : ((CCompany)cboxCompanyReportEarningArj.SelectedItem).ID);
                System.Int32 iCustomerId = (((cboxCustomerReportEarningArj.SelectedItem == null) || (System.Convert.ToString(cboxCustomerReportEarningArj.SelectedItem) == "") || (cboxCustomerReportEarningArj.Text == strWaitCustomer)) ? 0 : ((CCustomer)cboxCustomerReportEarningArj.SelectedItem).InterBaseID);

                System.DateTime dtBeginDate = this.dtBeginDateReportEarningArj.DateTime;
                System.DateTime dtEndDate = this.dtEnddateReportEarningArj.DateTime;

                System.String strErr = "";

                if (m_objReportEarningArjList == null) { m_objReportEarningArjList = new List<CEarning>(); }
                m_objReportEarningArjList.Clear();

                List<CEarning> objEarningList = CPaymentDataBaseModel.GetReportEarningArj(m_objProfile, null, dtBeginDate, dtEndDate, uuidCompanyId,
                    ref strErr, m_objProfile.GetClientsRight().GetState(Consts.strDR_PaymentsForm1OnlyViewReports));
                if ((objEarningList != null) && (objEarningList.Count > 0) && (iCustomerId != 0))
                {
                    objEarningList = objEarningList.Where<CEarning>(x => x.Customer.InterBaseID == iCustomerId).ToList<CEarning>();
                }

                List<CEarning> objAddEarningList = new List<CEarning>();
                if ((objEarningList != null) && (objEarningList.Count > 0))
                {
                    System.Int32 iRecCount = 0;
                    System.Int32 iRecAllCount = objEarningList.Count;
                    foreach (CEarning objEarning in objEarningList)
                    {
                        objAddEarningList.Add(objEarning);
                        iRecCount++;

                        if (iRecCount == 100)
                        {
                            iRecCount = 0;
                            Thread.Sleep(100);
                            this.Invoke(m_LoadReportEarningArjDelegate, new Object[] { objAddEarningList, iRecAllCount });
                            objAddEarningList.Clear();
                        }

                    }
                    if (iRecCount != 100)
                    {
                        iRecCount = 0;
                        this.Invoke(m_LoadReportEarningArjDelegate, new Object[] { objAddEarningList, iRecAllCount });
                        objAddEarningList.Clear();
                    }

                }

                objEarningList = null;
                objAddEarningList = null;
                this.Invoke(m_LoadReportEarningArjDelegate, new Object[] { null, 0 });
                this.m_bThreadFinishJob = true;
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("LoadReportEarningArjInThread.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally
            {
            }
            return;
        }

        /// <summary>
        /// загружает в журнал отчёт "Архив платежей"
        /// </summary>
        /// <param name="objEarningList">список платежей</param>
        /// <param name="iRowCountInList">количество строк, которые требуется загрузить в журнал</param>
        private void LoadReportEarningArjInGrid(List<CEarning> objEarningList, System.Int32 iRowCountInList )
        {
            try
            {
                if ((objEarningList != null) && (objEarningList.Count > 0) && ( gridViewReportEarningArj.RowCount < iRowCountInList))
                {
                    m_objReportEarningArjList.AddRange(objEarningList);
                    if ( gridControlReportEarningArj.DataSource == null)
                    {
                        gridControlReportEarningArj.DataSource = m_objReportEarningArjList;
                    }

                    this.tableLayoutPanelReports.SuspendLayout();
                    ((System.ComponentModel.ISupportInitialize)(this.gridControlReportEarningArj)).BeginInit();
                    ((System.ComponentModel.ISupportInitialize)(this.gridViewReportEarningArj)).BeginInit();
                    
                    gridControlReportEarningArj.RefreshDataSource();
                    //foreach (DevExpress.XtraGrid.Columns.GridColumn objColumn in gridViewReportEarningArj.Columns)
                    //{
                    //    if (objColumn.Visible == true)
                    //    {
                    //        objColumn.BestFit();
                    //    }
                    //}

                    this.tableLayoutPanelReports.ResumeLayout(false);
                    ((System.ComponentModel.ISupportInitialize)(this.gridControlReportEarningArj)).EndInit();
                    ((System.ComponentModel.ISupportInitialize)(this.gridViewReportEarningArj)).EndInit();

                    System.Double iPart = m_objReportEarningArjList.Count;
                    System.Double iAll = iRowCountInList;
                    System.Double iPosition = (iPart / iAll) * 100;

                    progressBarControlReportEarningArj.Position = System.Convert.ToInt32(iPosition);
                    this.Update();

                }
                else
                {
                    //Thread.Sleep(1000);

                    btnRefreshReportEarningArj.Enabled = true;
                    btnPrintReportEarningArj.Enabled = true;
                    cboxCompanyReportEarningArj.Enabled = true;
                    cboxCustomerReportEarningArj.Enabled = true;
                    dtBeginDateReportEarningArj.Enabled = true;
                    dtEnddateReportEarningArj.Enabled = true;

                    progressBarControlReportEarningArj.Position = 100;
                    this.Update();

                    panelProgressBarReportEarningArj.Visible = false;

                    this.tableLayoutPanelReports.SuspendLayout();
                    ((System.ComponentModel.ISupportInitialize)(this.gridControlReportEarningArj)).BeginInit();
                    ((System.ComponentModel.ISupportInitialize)(this.gridViewReportEarningArj)).BeginInit();

                    gridControlReportEarningArj.RefreshDataSource();
                    foreach (DevExpress.XtraGrid.Columns.GridColumn objColumn in gridViewReportEarningArj.Columns)
                    {
                        if (objColumn.Visible == true)
                        {
                            objColumn.BestFit();
                        }
                    }

                    this.tableLayoutPanelReports.ResumeLayout(false);
                    ((System.ComponentModel.ISupportInitialize)(this.gridControlReportEarningArj)).EndInit();
                    ((System.ComponentModel.ISupportInitialize)(this.gridViewReportEarningArj)).EndInit();



                    Cursor = Cursors.Default;

                }
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("LoadReportEarningArjInGrid.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally
            {
            }
            return;
        }

        /// <summary>
        /// Стартует поток, в котором загружается отчёт "Дебиторы"
        /// </summary>
        public void StartThreadLoadReportDebtor()
        {
            try
            {
                // инициализируем делегаты
                m_LoadReportDebtorDelegate = new LoadReportDebtorDelegate(LoadReportDebtorInGrid);
                m_objReportDebtorList.Clear();

                btnRefreshReportDebtor.Enabled = false;
                btnPrintReportDebtor.Enabled = false;
                cboxCompanyReportDebtor.Enabled = false;
                cboxCustomerReportDebtor.Enabled = false;
                cboxCustomerReportEarningArj.Enabled = false;

                gridControlReportDebtor.DataSource = null;
                panelProgressBarReportDebtor.Visible = true;
                progressBarControlReportDebtor.Position = 2;
                panelProgressBarReportDebtor.Refresh();
                this.Update();

                // запуск потока
                this.ThreadReportDebtor = new System.Threading.Thread(LoadReportDebtorInThread);
                this.ThreadReportDebtor.Start();
                //                Thread.Sleep(1000);

            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("StartThreadLoadReportDebtor().\n\nТекст ошибки: " + f.Message, "Ошибка",
                    System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }

            return;
        }


        /// <summary>
        /// Загружает отчёт "Дебиторы"
        /// </summary>
        public void LoadReportDebtorInThread()
        {
            try
            {
                System.Guid uuidCompanyId = (((cboxCompanyReportDebtor.SelectedItem == null) || (System.Convert.ToString(cboxCompanyReportDebtor.SelectedItem) == "") || (cboxCompanyReportDebtor.Text == strWaitCustomer)) ? System.Guid.Empty : ((CCompany)cboxCompanyReportDebtor.SelectedItem).ID);
                System.Guid uuidCustomerId = (((cboxCustomerReportDebtor.SelectedItem == null) || (System.Convert.ToString(cboxCustomerReportDebtor.SelectedItem) == "") || (cboxCustomerReportDebtor.Text == strWaitCustomer)) ? System.Guid.Empty : ((CCustomer)cboxCustomerReportDebtor.SelectedItem).ID);

                System.String strErr = "";

                if (m_objReportDebtorList == null) { m_objReportDebtorList = new List<CDebitDocument>(); }
                m_objReportDebtorList.Clear();

                List<CDebitDocument> objDebitDocumentList = CPaymentDataBaseModel.GetReportDebtor(m_objProfile, null, uuidCompanyId, uuidCustomerId, ref strErr);

                List<CDebitDocument> objAddDebitDocumentList = new List<CDebitDocument>();
                if ((objDebitDocumentList != null) && (objDebitDocumentList.Count > 0))
                {
                    System.Int32 iRecCount = 0;
                    System.Int32 iRecAllCount = objDebitDocumentList.Count; 
                    
                    foreach (CDebitDocument objDebitDocument in objDebitDocumentList)
                    {
                        objAddDebitDocumentList.Add(objDebitDocument);
                        iRecCount++;

                        if (iRecCount == 100)
                        {
                            iRecCount = 0;
                            Thread.Sleep(100);
                            this.Invoke(m_LoadReportDebtorDelegate, new Object[] { objAddDebitDocumentList, iRecAllCount });
                            objAddDebitDocumentList.Clear();
                        }

                    }
                    if (iRecCount != 100)
                    {
                        iRecCount = 0;
                        this.Invoke(m_LoadReportDebtorDelegate, new Object[] { objAddDebitDocumentList, iRecAllCount });
                        objAddDebitDocumentList.Clear();
                    }

                }

                objDebitDocumentList = null;
                objAddDebitDocumentList = null;
                this.Invoke(m_LoadReportDebtorDelegate, new Object[] { null, 0 });
                this.m_bThreadFinishJob = true;
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("LoadReportDebtorInThread.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally
            {
            }
            return;
        }

        /// <summary>
        /// загружает в журнал отчёт "Дебиторы"
        /// </summary>
        /// <param name="objDebitDocumentList">список неоплаченных документов</param>
        /// <param name="iRowCountInList">количество строк, которые требуется загрузить в журнал</param>
        private void LoadReportDebtorInGrid(List<CDebitDocument> objDebitDocumentList, System.Int32 iRowCountInList)
        {
            try
            {
                if ((objDebitDocumentList != null) && (objDebitDocumentList.Count > 0) && (gridViewReportDebtor.RowCount < iRowCountInList))
                {
                    m_objReportDebtorList.AddRange(objDebitDocumentList);
                    if (gridControlReportDebtor.DataSource == null)
                    {
                        gridControlReportDebtor.DataSource = m_objReportDebtorList;
                    }

                    this.tableLayoutPanelReportDebtor.SuspendLayout();
                    ((System.ComponentModel.ISupportInitialize)(this.gridControlReportDebtor)).BeginInit();
                    ((System.ComponentModel.ISupportInitialize)(this.gridViewReportDebtor)).BeginInit();

                    gridControlReportDebtor.RefreshDataSource();

                    this.tableLayoutPanelReportDebtor.ResumeLayout(false);
                    ((System.ComponentModel.ISupportInitialize)(this.gridControlReportDebtor)).EndInit();
                    ((System.ComponentModel.ISupportInitialize)(this.gridViewReportDebtor)).EndInit();

                    System.Double iPart = m_objReportDebtorList.Count;
                    System.Double iAll = iRowCountInList;
                    System.Double iPosition = (iPart / iAll) * 100;

                    progressBarControlReportDebtor.Position = System.Convert.ToInt32(iPosition);
                    this.Update();

                }
                else
                {
                    btnRefreshReportDebtor.Enabled = true;
                    btnPrintReportDebtor.Enabled = true;
                    cboxCompanyReportDebtor.Enabled = true;
                    cboxCustomerReportDebtor.Enabled = true;

                    progressBarControlReportDebtor.Position = 100;
                    this.Update();

                    panelProgressBarReportDebtor.Visible = false;

                    this.tableLayoutPanelReportDebtor.SuspendLayout();
                    ((System.ComponentModel.ISupportInitialize)(this.gridControlReportDebtor)).BeginInit();
                    ((System.ComponentModel.ISupportInitialize)(this.gridViewReportDebtor)).BeginInit();

                    gridControlReportDebtor.RefreshDataSource();
                    foreach (DevExpress.XtraGrid.Columns.GridColumn objColumn in gridViewReportDebtor.Columns)
                    {
                        if (objColumn.Visible == true)
                        {
                            objColumn.BestFit();
                        }
                    }

                    this.tableLayoutPanelReportDebtor.ResumeLayout(false);
                    ((System.ComponentModel.ISupportInitialize)(this.gridControlReportDebtor)).EndInit();
                    ((System.ComponentModel.ISupportInitialize)(this.gridViewReportDebtor)).EndInit();

                    Cursor = Cursors.Default;
                }
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("LoadReportDebtorInGrid.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally
            {
            }
            return;
        }
        #endregion

        #region Выпадающие списки
        /// <summary>
        /// Загружает собдержимое выпадающих списков
        /// </summary>
        private void LoadComboBox()
        {
            System.String strErr = System.String.Empty; 
            try
            {
                cboxCustomer.Properties.Items.Clear();
                cboxCustomer.Properties.Items.Add(new CCustomer());

                cboxCustomerPaidDocument.Properties.Items.Clear();
                cboxCustomerPaidDocument.Properties.Items.Add(new CCustomer());

                cboxCustomerReportDebtor.Properties.Items.Clear();
                cboxCustomerReportDebtor.Properties.Items.Add(new CCustomer());

                editorEarningType.Properties.Items.Clear();

                cboxCompany.Properties.Items.Clear();
                cboxCompanyPaidDocument.Properties.Items.Clear();
                
                cboxCompanyReportEarningArj.Properties.Items.Clear();
                cboxCustomerReportEarningArj.Properties.Items.Add(new CCustomer());

                cboxCompanyReportDebtor.Properties.Items.Clear();

                editorEarningCompanyPayer.Properties.Items.Clear();
                editorEarningCompanyDst.Properties.Items.Clear();
                List<CCompany> objCompanyList = CCompany.GetCompanyListActive(m_objProfile, null);
                if (objCompanyList != null)
                {
                    cboxCompany.Properties.Items.AddRange(objCompanyList);
                    cboxCompanyPaidDocument.Properties.Items.AddRange(objCompanyList);
                    cboxCompanyReportEarningArj.Properties.Items.AddRange(objCompanyList);
                    cboxCompanyReportDebtor.Properties.Items.AddRange(objCompanyList);
                }

                cboxCompany.SelectedItem = ((cboxCompany.Properties.Items.Count > 0) ? cboxCompany.Properties.Items[0] : null);
                cboxCompanyReportEarningArj.SelectedItem = ((cboxCompanyReportEarningArj.Properties.Items.Count > 0) ? cboxCompanyReportEarningArj.Properties.Items[0] : null);
                cboxCompanyReportDebtor.SelectedItem = ((cboxCompanyReportDebtor.Properties.Items.Count > 0) ? cboxCompanyReportDebtor.Properties.Items[0] : null);

                editorEarningCompanyPayer.Properties.Items.Add(new CCompany());
                editorEarningCompanyPayer.Properties.Items.AddRange(cboxCompany.Properties.Items);
                editorEarningCompanyDst.Properties.Items.AddRange(cboxCompany.Properties.Items);

                editorEarningCurrency.Properties.Items.Clear();
                editorEarningCurrency.Properties.Items.AddRange(CCurrency.GetCurrencyList(m_objProfile, null));

                // 2014.01.13
                // предоставляется возможность выбора валюты платежа
                //if (m_enumPaymentType == enumPaymentType.PaymentForm1)
                //{
                //    editorEarningCurrency.Properties.Items.AddRange(CCurrency.GetCurrencyList(m_objProfile, null).Where<CCurrency>(x => x.IsNationalCurrency).ToList<CCurrency>());
                //}
                //else
                //{
                //    editorEarningCurrency.Properties.Items.AddRange(CCurrency.GetCurrencyList(m_objProfile, null));
                //}
                editorEarningPaymentType.Properties.Items.Clear();
                if (m_enumPaymentType == enumPaymentType.PaymentForm1)
                {
                    editorEarningPaymentType.Properties.Items.AddRange(CPaymentType.GetPaymentTypeList(m_objProfile, null, System.Guid.Empty).Where<CPaymentType>(x=>x.Payment_Id.Equals(1)).ToList<CPaymentType>());
                }
                else
                {
                    editorEarningPaymentType.Properties.Items.AddRange(CPaymentType.GetPaymentTypeList(m_objProfile, null, System.Guid.Empty));
                }
                editorEarningAccountPlan.Properties.Items.Clear();
                //editorEarningAccountPlan.Properties.Items.Add( new CAccountPlan() );
                editorEarningAccountPlan.Properties.Items.AddRange(CAccountPlanDataBaseModel.GetAccountPlanList(m_objProfile, null, ref strErr));

                editorEarningProjectSrc.Properties.Items.Clear();
                editorEarningProjectSrc.Properties.Items.Add(new CBudgetProject());

                editorEarningProjectDst.Properties.Items.Clear();
                //editorEarningProjectDst.Properties.Items.Add(new CBudgetProject());

                editorEarningProjectSrc.Properties.Items.AddRange(CBudgetProjectDataBaseModel.GetBudgetProjectList(m_objProfile, null, ref strErr));
                editorEarningProjectDst.Properties.Items.AddRange(editorEarningProjectSrc.Properties.Items);

                List<CEarningType> objEarningTypeList = CEarningType.GetEarningTypeList( m_objProfile, ref strErr );
                if ((objEarningTypeList != null) && (objEarningTypeList.Count > 0))
                {
                    editorEarningType.Properties.Items.AddRange(objEarningTypeList);
                }
                objEarningTypeList = null;

            }
            catch (System.Exception f)
            {
                SendMessageToLog("LoadComboBox. Текст ошибки: " + f.Message);
            }
            return;
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
        #endregion

        #region Свойства платежа
        private void gridViewEarningList_RowCellStyle(object sender, DevExpress.XtraGrid.Views.Grid.RowCellStyleEventArgs e)
        {
            try
            {
                if (e.RowHandle != gridViewEarningList.FocusedRowHandle)
                {
                    if (e.Column.FieldName == "Saldo" && (System.Convert.ToDecimal(gridViewEarningList.GetRowCellValue(e.RowHandle, e.Column)) == 0))
                    {
                        e.Appearance.Font = new Font(AppearanceObject.DefaultFont, FontStyle.Bold);
                        e.Appearance.ForeColor = Color.Navy;
                    }

                    if (e.Column.FieldName == "CustomerName" && (((System.String)(gridViewEarningList.GetRowCellValue(e.RowHandle, e.Column))) == ERP_Mercury.Global.Consts.strCustomerNotIndefined))
                    {
                        e.Appearance.Font = new Font(AppearanceObject.DefaultFont, FontStyle.Bold);
                        e.Appearance.ForeColor = Color.Red;
                    }

                    
                }
            }
            catch (System.Exception f)
            {
                SendMessageToLog("gridViewEarningList_RowCellStyle. Текст ошибки: " + f.Message);
            }

            return;
        }

        private void contextMenuStripEarningList_Opening(object sender, CancelEventArgs e)
        {
            try
            {
                System.Boolean bEarningForPayment = ( System.Convert.ToInt32( gridViewEarningList.GetRowCellValue(gridViewEarningList.FocusedRowHandle, gridViewEarningList.Columns["EarningType_Id"]) ) == 0 );
                mitmsEarningHistory.Enabled = ((gridViewEarningList.RowCount > 0) && (gridViewEarningList.FocusedRowHandle >= 0));
                mitmsPayDebitDocument.Enabled = ((gridViewEarningList.RowCount > 0) && (gridViewEarningList.FocusedRowHandle >= 0) && 
                    (System.Convert.ToDecimal(gridViewEarningList.GetRowCellValue(gridViewEarningList.FocusedRowHandle, gridViewEarningList.Columns["Saldo"])) > 0) &&
                    (bEarningForPayment == true));
                mitemCopyEarningToolStripMenuItem.Enabled = (SelectedEarning != null);
            }
            catch (System.Exception f)
            {
                SendMessageToLog("contextMenuStripEarningList_Opening. Текст ошибки: " + f.Message);
            }

            return;

        }

        private void gridViewEarningList_FocusedRowChanged(object sender, DevExpress.XtraGrid.Views.Base.FocusedRowChangedEventArgs e)
        {
            try
            {
                FocusedEarningChanged();
            }
            catch (System.Exception f)
            {
                SendMessageToLog("gridViewEarningList_FocusedRowChanged. Текст ошибки: " + f.Message);
            }

            return;
        }

        private void gridViewEarningList_RowCountChanged(object sender, EventArgs e)
        {
            try
            {
                FocusedEarningChanged();
            }
            catch (System.Exception f)
            {
                SendMessageToLog("gridViewEarningList_RowCountChanged. Текст ошибки: " + f.Message);
            }

            return;
        }

        /// <summary>
        /// Возвращает ссылку на выбранный в списке платёж
        /// </summary>
        /// <returns>ссылка на платёж</returns>
        private CEarning SelectedEarning
        {
            get
            {
                CEarning objRet = null;
                try
                {
                    if ((((DevExpress.XtraGrid.Views.Grid.GridView)gridControlEarningList.MainView).RowCount > 0) &&
                        (((DevExpress.XtraGrid.Views.Grid.GridView)gridControlEarningList.MainView).FocusedRowHandle >= 0))
                    {
                        System.Guid uuidID = (System.Guid)(((DevExpress.XtraGrid.Views.Grid.GridView)gridControlEarningList.MainView)).GetFocusedRowCellValue("ID");

                        objRet = m_objEarningList.Single<CEarning>(x => x.ID.CompareTo(uuidID) == 0);
                    }
                }//try
                catch (System.Exception f)
                {
                    SendMessageToLog("Ошибка поиска выбранного платежа. Текст ошибки: " + f.Message);
                }
                finally
                {
                }

                return objRet;
            }
        }

        /// <summary>
        /// Определяет, какой платёж выбран в журнале и отображает его свойства
        /// </summary>
        private void FocusedEarningChanged()
        {
            try
            {
                ShowEarningProperties(SelectedEarning);

                barBtnAdd.Enabled = !m_bOnlyView;
                barBtnEdit.Enabled = ( gridViewEarningList.FocusedRowHandle >= 0);
                btnCopyEarning.Enabled = (gridViewEarningList.FocusedRowHandle >= 0);
                barBtnDelete.Enabled = ((!m_bOnlyView) && (gridViewEarningList.FocusedRowHandle >= 0));
                barBtnDebitDocumentList.Enabled = ((gridViewEarningList.FocusedRowHandle >= 0) && (System.Convert.ToDecimal(gridViewEarningList.GetRowCellValue(gridViewEarningList.FocusedRowHandle, gridViewEarningList.Columns["Saldo"])) > 0));
                barBtnEarningHistoryView.Enabled = (gridViewEarningList.FocusedRowHandle >= 0);
                btnAutoPayEarningList.Enabled = (gridViewEarningList.RowCount > 0);
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Отображение свойств платежа. Текст ошибки: " + f.Message);
            }

            return;
        }

        /// <summary>
        /// Отображает свойства платежа
        /// </summary>
        /// <param name="objEarning">платёж</param>
        private void ShowEarningProperties( CEarning objEarning )
        {
            try
            {
                this.tableLayoutPanelEarningProperties.SuspendLayout();

                txtEarningDoc.Text = "";
                txtEarningDate.Text = "";
                txtEarningBankCode.Text = "";
                txtEarningAccountNumber.Text = "";
                calcEarningValue.Value = 0;
                calcEarningExpense.Value = 0;
                calcEarningSaldo.Value = 0;

                txtEarningPayer.Text = "";
                txtPayerDescrpn.Text = "";
                txtEarningDetail.Text = "";

                if (objEarning != null)
                {
                    txtEarningDoc.Text = objEarning.DocNom;
                    txtEarningDate.Text = objEarning.Date.ToShortDateString();
                    txtEarningBankCode.Text = objEarning.CodeBank;
                    txtEarningAccountNumber.Text = objEarning.AccountNumber;
                    calcEarningValue.Value = System.Convert.ToDecimal(objEarning.Value);
                    calcEarningExpense.Value = System.Convert.ToDecimal(objEarning.Expense);
                    calcEarningSaldo.Value = System.Convert.ToDecimal(objEarning.Saldo);
                    txtEarningPayer.Text = objEarning.CustomerName;
                    txtPayerDescrpn.Text = objEarning.CustomrText;
                    txtEarningDetail.Text = objEarning.DetailsPayment;

                }

                this.tableLayoutPanelEarningProperties.ResumeLayout(false);
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Отображение свойств платежа. Текст ошибки: " + f.Message);
            }
            return;
        }

        #endregion

        #region Режим просмотра/редактирования
        /// <summary>
        /// Устанавливает режим просмотра/редактирования
        /// </summary>
        /// <param name="bSet">true - режим просмотра; false - режим редактирования</param>
        private void SetModeReadOnly(System.Boolean bSet)
        {
            try
            {
                editorEarningDate.Properties.ReadOnly = bSet;
                editorEarningDocNum.Properties.ReadOnly = bSet;
                editorEarningCurrency.Properties.ReadOnly = bSet;
                editorEarningIsBonus.Properties.ReadOnly = bSet;

                editorEarningCompanyDst.Properties.ReadOnly = bSet;
                editorEarningPaymentType.Properties.ReadOnly = bSet;
                editorEarningValue.Properties.ReadOnly = bSet;
                //editorEarningExpense.Properties.ReadOnly = bSet;
                //editorEarningSaldo.Properties.ReadOnly = bSet;
                editorEarningCustomer.Properties.ReadOnly = bSet;
                editorEarningpayerDetail.Properties.ReadOnly = bSet;
                editorEarningAccount.Properties.ReadOnly = bSet;
                editorEarningBank.Properties.ReadOnly = bSet;
                editorEarningDetail.Properties.ReadOnly = bSet;
                editorEarningCompanyPayer.Properties.ReadOnly = bSet;
                editorEarningAccountPlan.Properties.ReadOnly = bSet;
                editorEarningProjectSrc.Properties.ReadOnly = bSet;
                editorEarningProjectDst.Properties.ReadOnly = bSet;
                editorEarningType.Properties.ReadOnly = bSet;

                btnSelectAccount.Enabled = !bSet;
                btnGenerateGroupKey.Enabled = ( ( !bSet ) && ( m_bNewObject == true ) );

                btnEdit.Enabled = bSet;
                btnNewEarning.Enabled = bSet;

                layoutControlGroupAdvancedOperation.Expanded = false;
                
                dateEditMoneyToReturnOperationDate.Properties.ReadOnly = !bSet;
                calcEditMoneyToReturn.Properties.ReadOnly = !bSet;
                btnReturnMoneyToCustomer.Enabled = bSet;

                lblEditMode.Text = ((bSet == true) ? m_strModeReadOnly : m_strModeEdit);
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
        private void btnEdit_Click(object sender, EventArgs e)
        {
            try
            {
                SetModeReadOnly(false);
                btnEdit.Enabled = false;
                btnNewEarning.Enabled = false;
                m_bNewObject = false;

                SetPropertiesModified(true);
                //editorEarningType.Properties.ReadOnly = true;

            }
            catch (System.Exception f)
            {
                SendMessageToLog("btnEdit_Click. Текст ошибки: " + f.Message);
            }
            finally
            {
            }
            return;
        }
        private void SetPropertiesModified(System.Boolean bModified)
        {
            try
            {
                m_bIsChanged = bModified;
                btnSave.Enabled = (m_bIsChanged && (ValidateProperties() == true));
                btnCancel.Enabled = true;
            }
            catch (System.Exception f)
            {
                SendMessageToLog("SetPropertiesModified. Текст ошибки: " + f.Message);
            }
            finally
            {
            }

            return;
        }

        #endregion

        #region Индикация изменений
        /// <summary>
        /// Проверяет содержимое элементов управления
        /// </summary>
        private System.Boolean ValidateProperties()
        {
            System.Boolean bRet = true;
            try
            {
                editorEarningCompanyDst.Properties.Appearance.BackColor = ((editorEarningCompanyDst.SelectedItem == null) ? System.Drawing.Color.Tomato : System.Drawing.Color.White);
                editorEarningCurrency.Properties.Appearance.BackColor = ((editorEarningCurrency.SelectedItem == null) ? System.Drawing.Color.Tomato : System.Drawing.Color.White);
                editorEarningPaymentType.Properties.Appearance.BackColor = ((editorEarningPaymentType.SelectedItem == null) ? System.Drawing.Color.Tomato : System.Drawing.Color.White);
                editorEarningCustomer.Properties.Appearance.BackColor = ((editorEarningCustomer.SelectedItem == null) ? System.Drawing.Color.Tomato : System.Drawing.Color.White);
                editorEarningAccount.Properties.Appearance.BackColor = ((editorEarningAccount.SelectedItem == null) ? System.Drawing.Color.Tomato : System.Drawing.Color.White);
                editorEarningBank.Properties.Appearance.BackColor = ((editorEarningBank.SelectedItem == null) ? System.Drawing.Color.Tomato : System.Drawing.Color.White);
                editorEarningDate.Properties.Appearance.BackColor = ((editorEarningDate.DateTime == System.DateTime.MinValue) ? System.Drawing.Color.Tomato : System.Drawing.Color.White);
                editorEarningValue.Properties.Appearance.BackColor = ((editorEarningValue.Value <= 0) ? System.Drawing.Color.Tomato : System.Drawing.Color.White);

                editorEarningProjectDst.Properties.Appearance.BackColor = ((editorEarningProjectDst.SelectedItem == null) ? System.Drawing.Color.Tomato : System.Drawing.Color.White);
                editorEarningAccountPlan.Properties.Appearance.BackColor = ((editorEarningAccountPlan.SelectedItem == null) ? System.Drawing.Color.Tomato : System.Drawing.Color.White);

                // в том случае, если выбран хотя бы один из дополнительных параметров, необходимо указать все остальные
                System.Boolean bRetAdvParam = true;
                System.Boolean bExistsProjectSrc = ((editorEarningProjectSrc.SelectedItem != null) && (((CBudgetProject)editorEarningProjectSrc.SelectedItem)).ID.CompareTo(System.Guid.Empty) != 0);
                System.Boolean bExistsCompanyPayer = ((editorEarningCompanyPayer.SelectedItem != null) && (((CCompany)editorEarningCompanyPayer.SelectedItem)).ID.CompareTo(System.Guid.Empty) != 0);

                if( ( bExistsCompanyPayer == true) || (bExistsProjectSrc == true) )
                {
                    bRetAdvParam = ((bExistsProjectSrc == true) && (bExistsCompanyPayer == true));
                }

                if (bRetAdvParam == true)
                {
                    editorEarningProjectSrc.Properties.Appearance.BackColor = System.Drawing.Color.White;
                    editorEarningCompanyPayer.Properties.Appearance.BackColor = System.Drawing.Color.White;
                }
                else
                {
                    editorEarningProjectSrc.Properties.Appearance.BackColor = ((bExistsProjectSrc == true) ? System.Drawing.Color.White : System.Drawing.Color.Tomato);
                    editorEarningCompanyPayer.Properties.Appearance.BackColor = ((bExistsCompanyPayer == true) ? System.Drawing.Color.White : System.Drawing.Color.Tomato);
                }

                bRet = ((editorEarningCompanyDst.SelectedItem != null) && (editorEarningCurrency.SelectedItem != null) &&
                    (editorEarningPaymentType.SelectedItem != null) && (editorEarningProjectDst.SelectedItem != null) &&
                    (editorEarningAccount.SelectedItem != null) && (editorEarningAccountPlan.SelectedItem != null) && 
                    (editorEarningBank.SelectedItem != null) &&
                    (editorEarningDate.DateTime != System.DateTime.MinValue) && (editorEarningValue.Value > 0) && (bRetAdvParam == true)
                    );

            }
            catch (System.Exception f)
            {
                SendMessageToLog("ValidateProperties. Текст ошибки: " + f.Message);
            }

            return bRet;
        }
        private void cboxEarningPropertie_SelectedValueChanged(object sender, EventArgs e)
        {
            try
            {
                if (m_bDisableEvents == true) { return; }

                if( sender == editorEarningCustomer )
                {
                    LoadAccountsForCustomer((editorEarningCustomer.SelectedItem == null) ? null : (CCustomer)editorEarningCustomer.SelectedItem);

                    if (m_objSelectedEarning != null)
                    {
                        if (m_objSelectedEarning.Account != null)
                        {
                            // у платежа указан счёт
                            editorEarningAccount.SelectedItem = editorEarningAccount.Properties.Items.Cast<CAccount>().SingleOrDefault<CAccount>(x => x.ID.CompareTo( m_objSelectedEarning.Account.ID ) == 0);
                        }

                        if (editorEarningAccount.SelectedItem == null)
                        {
                            editorEarningAccount.SelectedItem = ((editorEarningAccount.Properties.Items.Count > 0) ? editorEarningAccount.Properties.Items[0] : null);
                        }
                    }


                }

                if (sender == editorEarningAccount)
                {
                    if (editorEarningAccount.SelectedItem != null)
                    {
                        editorEarningBank.Properties.Items.Clear();
                        editorEarningBank.Properties.Items.Add(((CAccount)editorEarningAccount.SelectedItem).Bank);
                        editorEarningBank.SelectedIndex = 0;
                    }
                }

                if (sender == editorEarningPaymentType)
                {
                    if ((editorEarningPaymentType.SelectedItem != null) &&
                        (m_bNewObject == true))
                    {
                        LoadAccountPlanForPaymentType(((CPaymentType)editorEarningPaymentType.SelectedItem).ID);
                    }
                }

                SetPropertiesModified(true);
            }//try
            catch (System.Exception f)
            {
                SendMessageToLog(String.Format("Ошибка изменения свойства {0}. Текст ошибки: {1}", ((DevExpress.XtraEditors.ComboBoxEdit)sender).ToolTip, f.Message));
            }
            finally
            {
            }

            return;
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

        /// <summary>
        /// Загружает список счетов клиента
        /// </summary>
        /// <param name="objCustomer">клиент</param>
        private void LoadAccountsForCustomer( CCustomer objCustomer )
        {
            System.String strErr = System.String.Empty;
            Cursor = Cursors.WaitCursor;
            try
            {
                //this.tableLayoutPanelBackground.SuspendLayout();

                // очистка выпадающих списков с банками и расчётными счетами
                editorEarningAccount.SelectedItem = null;
                editorEarningBank.SelectedItem = null;
                
                editorEarningAccount.Properties.Items.Clear();
                editorEarningBank.Properties.Items.Clear();

                if(objCustomer == null) {return;}

                // запрашиваем список счетов клиента
                List<CAccount> objAccountListForCustomer = CAccount.GetAccountListForCustomer(m_objProfile, null, objCustomer.ID, ref strErr);

                if( objAccountListForCustomer != null )
                {
                    editorEarningAccount.Properties.Items.AddRange( objAccountListForCustomer );
                }

                if ((m_objSelectedEarning != null) && (m_objSelectedEarning.Account != null))
                {
                    if (editorEarningAccount.Properties.Items.Cast<CAccount>().SingleOrDefault<CAccount>(x => x.ID.CompareTo(m_objSelectedEarning.Account.ID) == 0) == null)
                    {
                        editorEarningAccount.Properties.Items.Add(m_objSelectedEarning.Account);
                    }
                }

            }
            catch (System.Exception f)
            {
                SendMessageToLog(String.Format("Ошибка загрузки списка счетов. Текст ошибки: {0}", f.Message));
            }
            finally
            {
                //this.tableLayoutPanelBackground.ResumeLayout(false);
                Cursor = Cursors.Default;
            }

            return;
        }

        private void txtEarningPropertie_EditValueChanging(object sender, DevExpress.XtraEditors.Controls.ChangingEventArgs e)
        {
            try
            {
                if (m_bDisableEvents == true) { return; }
                if (e.NewValue != null)
                {
                    SetPropertiesModified(true);
                    if ((sender.GetType().Name == "TextEdit") &&
                        (((DevExpress.XtraEditors.TextEdit)sender).Properties.ReadOnly == false))
                    {
                        System.String strValue = (System.String)e.NewValue;
                        ((DevExpress.XtraEditors.TextEdit)sender).Properties.Appearance.BackColor = (strValue == "") ? System.Drawing.Color.Tomato : System.Drawing.Color.White;
                    }
                }
            }//try
            catch (System.Exception f)
            {
                SendMessageToLog(String.Format("Ошибка изменения свойств платежа. Текст ошибки: {0}", f.Message));
            }
            finally
            {
            }

            return;
        }

        #endregion

        #region Редактировать платёж
        private void barBtnEdit_Click(object sender, EventArgs e)
        {
            try
            {
                EditEarning(SelectedEarning, false);

                SetModeReadOnly(false);
                btnEdit.Enabled = false;
                btnNewEarning.Enabled = false;
                SetPropertiesModified(true);
            }
            catch (System.Exception f)
            {
                SendMessageToLog("btnEdit_Click. Текст ошибки: " + f.Message);
            }
            finally
            {
            }
            return;
        }

        private void gridControlEarningList_MouseDoubleClick(object sender, MouseEventArgs e)
        {
            try
            {
                this.Cursor = Cursors.WaitCursor;

                EditEarning(SelectedEarning, false);

                //LoadDebitDocumentListInThread();

            }//try
            catch (System.Exception f)
            {
                SendMessageToLog(f.Message);
            }
            finally
            {
                this.Cursor = Cursors.Default;
            }

            return;
        }
        /// <summary>
        /// очистка содержимого элементов управления
        /// </summary>
        private void ClearControls()
        {
            try
            {
                editorEarningDate.DateTime = System.DateTime.MinValue;
                editorEarningDocNum.Text = "";
                editorEarningCurrency.SelectedItem = null;
                editorEarningIsBonus.CheckState = CheckState.Unchecked;

                editorEarningCompanyDst.SelectedItem = null;
                editorEarningPaymentType.SelectedItem = null;
                editorEarningValue.Value = 0;
                editorEarningExpense.Value = 0;
                editorEarningSaldo.Value = 0;
                editorEarningCustomer.SelectedItem = null;
                editorEarningpayerDetail.Text = "";
                editorEarningAccount.SelectedItem = null;
                editorEarningBank.SelectedItem = null;
                editorEarningAccount.Properties.Items.Clear();
                editorEarningBank.Properties.Items.Clear();
                editorEarningiKey.Value = 0;

                editorEarningDetail.Text = "";
                editorEarningCompanyPayer.SelectedItem = null;
                editorEarningAccountPlan.SelectedItem = null;
                editorEarningProjectSrc.SelectedItem = null;
                editorEarningProjectDst.SelectedItem = null;
                editorEarningType.SelectedItem = null;

                calcEditMoneyToReturn.Value = 0;
                dateEditMoneyToReturnOperationDate.EditValue = null;

            }
            catch (System.Exception f)
            {
                SendMessageToLog("ClearControls. Текст ошибки: " + f.Message);
            }
            finally
            {
            }
            return;
        }

        /// <summary>
        /// Загружает свойства платежа для редактирования
        /// </summary>
        /// <param name="objEarning">платеж</param>
        /// <param name="bNewObject">признак "новый платеж"</param>
        public void EditEarning(CEarning objEarning, System.Boolean bNewObject)
        {
            if (objEarning == null) { return; }
            m_bDisableEvents = true;
            m_bNewObject = bNewObject;
            try
            {
                m_objSelectedEarning = objEarning;

                this.tableLayoutPanelBackground.SuspendLayout();

                ClearControls();

                editorEarningDate.DateTime = m_objSelectedEarning.Date;
                editorEarningDocNum.Text = m_objSelectedEarning.DocNom;
                editorEarningCurrency.SelectedItem = (m_objSelectedEarning.Currency == null) ? null : editorEarningCurrency.Properties.Items.Cast<CCurrency>().SingleOrDefault<CCurrency>(x => x.ID.CompareTo(m_objSelectedEarning.Currency.ID) == 0);
                editorEarningIsBonus.Checked = m_objSelectedEarning.IsBonusEarning;

                editorEarningCompanyDst.SelectedItem = (m_objSelectedEarning.Company == null) ? null : editorEarningCompanyDst.Properties.Items.Cast<CCompany>().SingleOrDefault<CCompany>(x => x.ID.CompareTo(m_objSelectedEarning.Company.ID) == 0);
                editorEarningPaymentType.SelectedItem = (m_objSelectedEarning.PaymentType == null) ? null : editorEarningPaymentType.Properties.Items.Cast<CPaymentType>().SingleOrDefault<CPaymentType>(x => x.ID.CompareTo(m_objSelectedEarning.PaymentType.ID) == 0);
                editorEarningType.SelectedItem = (m_objSelectedEarning.EarningType == null) ? null : editorEarningType.Properties.Items.Cast<CEarningType>().SingleOrDefault<CEarningType>(x => x.ID.CompareTo(m_objSelectedEarning.EarningType.ID) == 0);

                editorEarningValue.Value = m_objSelectedEarning.Value;
                editorEarningExpense.Value = m_objSelectedEarning.Expense;
                editorEarningSaldo.Value = m_objSelectedEarning.Saldo;
                editorEarningiKey.Value = m_objSelectedEarning.GroupKeyId;

                editorEarningCustomer.SelectedItem = (m_objSelectedEarning.Customer == null) ? null : editorEarningCustomer.Properties.Items.Cast<CCustomer>().SingleOrDefault<CCustomer>(x => x.ID.CompareTo(m_objSelectedEarning.Customer.ID) == 0);

                LoadAccountsForCustomer(m_objSelectedEarning.Customer);

                if ((m_objSelectedEarning != null) && (m_objSelectedEarning.Account != null))
                {
                    if (editorEarningAccount.Properties.Items.Cast<CAccount>().SingleOrDefault<CAccount>(x => x.ID.CompareTo(m_objSelectedEarning.Account.ID) == 0) == null)
                    {
                        editorEarningAccount.Properties.Items.Add(m_objSelectedEarning.Account);
                    }
                }
                
                editorEarningpayerDetail.Text = m_objSelectedEarning.CustomrText;
                editorEarningAccount.SelectedItem = (m_objSelectedEarning.Account == null) ? null : editorEarningAccount.Properties.Items.Cast<CAccount>().SingleOrDefault<CAccount>(x => x.ID.CompareTo( m_objSelectedEarning.Account.ID) == 0);

                if (editorEarningAccount.SelectedItem != null)
                {
                    editorEarningBank.Properties.Items.Clear();
                    editorEarningBank.Properties.Items.Add(m_objSelectedEarning.Account.Bank);
                    editorEarningBank.SelectedItem = editorEarningBank.Properties.Items[0];
                }

                editorEarningDetail.Text = m_objSelectedEarning.DetailsPayment;
                editorEarningCompanyPayer.SelectedItem = (m_objSelectedEarning.CompanyPayer == null) ? null : editorEarningCompanyPayer.Properties.Items.Cast<CCompany>().SingleOrDefault<CCompany>(x => x.ID.CompareTo(m_objSelectedEarning.CompanyPayer.ID) == 0);
                editorEarningAccountPlan.SelectedItem = (m_objSelectedEarning.AccountPlan == null) ? null : editorEarningAccountPlan.Properties.Items.Cast<CAccountPlan>().SingleOrDefault<CAccountPlan>(x => x.ID.CompareTo(m_objSelectedEarning.AccountPlan.ID) == 0);
                editorEarningProjectSrc.SelectedItem = (m_objSelectedEarning.BudgetProjectSrc == null) ? null : editorEarningProjectSrc.Properties.Items.Cast<CBudgetProject>().SingleOrDefault<CBudgetProject>(x => x.ID.CompareTo(m_objSelectedEarning.BudgetProjectSrc.ID) == 0);
                editorEarningProjectDst.SelectedItem = (m_objSelectedEarning.BudgetProjectDst == null) ? null : editorEarningProjectDst.Properties.Items.Cast<CBudgetProject>().SingleOrDefault<CBudgetProject>(x => x.ID.CompareTo(m_objSelectedEarning.BudgetProjectDst.ID) == 0);

                calcEditMoneyToReturn.Value = m_objSelectedEarning.Saldo;
                dateEditMoneyToReturnOperationDate.EditValue = System.DateTime.Today;

                SetPropertiesModified(false);
                ValidateProperties();

                SetModeReadOnly(true);
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка редактирования платежа. Текст ошибки: " + f.Message);
            }
            finally
            {
                this.tableLayoutPanelBackground.ResumeLayout(false);
                m_bDisableEvents = false;
                btnCancel.Enabled = true;
                tabControl.SelectedTabPage = tabPageEditor;
            }
            return;
        }
        #endregion

        #region Новый платёж
        private void barBtnAdd_Click(object sender, EventArgs e)
        {
            try
            {
                this.Cursor = Cursors.WaitCursor;
                CCompany objCompany = ((cboxCompany.SelectedItem == null) ? null : (CCompany)cboxCompany.SelectedItem);

                NewEarning(objCompany);

            }//try
            catch (System.Exception f)
            {
                SendMessageToLog(f.Message);
            }
            finally
            {
                this.Cursor = Cursors.Default;
            }

            return;
        }

        /// <summary>
        /// Новый платёж
        /// </summary>
        /// <param name="objCompany">компания-получатель средств</param>
        public void NewEarning(CCompany objCompany)
        {
            try
            {
                m_bNewObject = true;
                m_bDisableEvents = true;

                m_objSelectedEarning = new CEarning() { Company = objCompany};

                this.tableLayoutPanelBackground.SuspendLayout();

                ClearControls();

                editorEarningIsBonus.Checked = false;
                editorEarningDate.DateTime = System.DateTime.Today;

                editorEarningCompanyDst.SelectedItem = (m_objSelectedEarning.Company == null) ? null : editorEarningCompanyDst.Properties.Items.Cast<CCompany>().SingleOrDefault<CCompany>(x => x.ID.CompareTo(m_objSelectedEarning.Company.ID) == 0);
                editorEarningPaymentType.SelectedItem = (m_objSelectedEarning.PaymentType == null) ? ((editorEarningPaymentType.Properties.Items.Count > 0) ? editorEarningPaymentType.Properties.Items[0] : null) : editorEarningPaymentType.Properties.Items.Cast<CPaymentType>().SingleOrDefault<CPaymentType>(x => x.ID.CompareTo(m_objSelectedEarning.PaymentType.ID) == 0);
                editorEarningCurrency.SelectedItem = (m_objSelectedEarning.Currency == null) ? ((editorEarningCurrency.Properties.Items.Count > 0) ? editorEarningCurrency.Properties.Items.Cast<CCurrency>().SingleOrDefault<CCurrency>( x => x.IsNationalCurrency == true ) : null) : editorEarningCurrency.Properties.Items.Cast<CCurrency>().SingleOrDefault<CCurrency>(x => x.ID.CompareTo(m_objSelectedEarning.Currency.ID) == 0);
                editorEarningType.SelectedItem = (m_objSelectedEarning.EarningType == null) ? ((editorEarningType.Properties.Items.Count > 0) ? editorEarningType.Properties.Items.Cast<CEarningType>().SingleOrDefault<CEarningType>(x => x.IsDefault == true) : null) : editorEarningType.Properties.Items.Cast<CEarningType>().SingleOrDefault<CEarningType>(x => x.ID.CompareTo(m_objSelectedEarning.EarningType.ID) == 0);
                editorEarningiKey.Value = m_GroupKeyId;

                LoadAccountPlanForPaymentType(((CPaymentType)editorEarningPaymentType.SelectedItem).ID);

                btnEdit.Enabled = false;
                btnNewEarning.Enabled = false;
                btnCancel.Enabled = true;

                SetModeReadOnly(false);
                SetPropertiesModified(true);


            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка создания платежа. Текст ошибки: " + f.Message);
            }
            finally
            {
                tableLayoutPanelBackground.ResumeLayout(false);
                m_bDisableEvents = false;

                if (tabControl.SelectedTabPage != tabPageEditor)
                { 
                    tabControl.SelectedTabPage = tabPageEditor;
                }
                editorEarningValue.Focus();
                editorEarningValue.SelectAll();
            }
            return;
        }
        private void btnGenerateGroupKey_Click(object sender, EventArgs e)
        {
            try
            {
                m_GroupKeyId = GenerateGroupKeyId();
                if (m_bNewObject == true)
                {
                    editorEarningiKey.Value = m_GroupKeyId;
                }
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка генерации номера выписки. Текст ошибки: " + f.Message);
            }
            return;
        }

        #endregion

        #region Копировать платеж

        /// <summary>
        /// Копирует реквизиты платежа в новый платеж
        /// </summary>
        /// <param name="objEarning">исходный платеж</param>
        public void CopyEarning(CEarning objEarning)
        {
            if (objEarning == null) { return; }
            m_bDisableEvents = true;
            m_bNewObject = true;
            try
            {
                m_objSelectedEarning = new CEarning();

                this.tableLayoutPanelBackground.SuspendLayout();

                ClearControls();

                editorEarningDate.DateTime = System.DateTime.Today;
                editorEarningDocNum.Text = objEarning.DocNom;
                editorEarningCurrency.SelectedItem = (objEarning.Currency == null) ? null : editorEarningCurrency.Properties.Items.Cast<CCurrency>().SingleOrDefault<CCurrency>(x => x.ID.CompareTo(objEarning.Currency.ID) == 0);
                editorEarningIsBonus.Checked = m_objSelectedEarning.IsBonusEarning;

                editorEarningCompanyDst.SelectedItem = (objEarning.Company == null) ? null : editorEarningCompanyDst.Properties.Items.Cast<CCompany>().SingleOrDefault<CCompany>(x => x.ID.CompareTo(objEarning.Company.ID) == 0);
                editorEarningPaymentType.SelectedItem = (objEarning.PaymentType == null) ? null : editorEarningPaymentType.Properties.Items.Cast<CPaymentType>().SingleOrDefault<CPaymentType>(x => x.ID.CompareTo(objEarning.PaymentType.ID) == 0);
                editorEarningType.SelectedItem = (objEarning.EarningType == null) ? null : editorEarningType.Properties.Items.Cast<CEarningType>().SingleOrDefault<CEarningType>(x => x.ID.CompareTo(objEarning.EarningType.ID) == 0);

                editorEarningValue.Value = objEarning.Value;
                editorEarningExpense.Value = 0;
                editorEarningiKey.Value = m_GroupKeyId;

                editorEarningCustomer.SelectedItem = (objEarning.Customer == null) ? null : editorEarningCustomer.Properties.Items.Cast<CCustomer>().SingleOrDefault<CCustomer>(x => x.ID.CompareTo(objEarning.Customer.ID) == 0);

                LoadAccountsForCustomer(objEarning.Customer);

                if ((objEarning != null) && (objEarning.Account != null))
                {
                    if (editorEarningAccount.Properties.Items.Cast<CAccount>().SingleOrDefault<CAccount>(x => x.ID.CompareTo(objEarning.Account.ID) == 0) == null)
                    {
                        editorEarningAccount.Properties.Items.Add(objEarning.Account);
                    }
                }

                editorEarningpayerDetail.Text = objEarning.CustomrText;
                editorEarningAccount.SelectedItem = (objEarning.Account == null) ? null : editorEarningAccount.Properties.Items.Cast<CAccount>().SingleOrDefault<CAccount>(x => x.ID.CompareTo(objEarning.Account.ID) == 0);

                if (editorEarningAccount.SelectedItem != null)
                {
                    editorEarningBank.Properties.Items.Clear();
                    editorEarningBank.Properties.Items.Add(objEarning.Account.Bank);
                    editorEarningBank.SelectedItem = editorEarningBank.Properties.Items[0];
                }

                editorEarningDetail.Text = objEarning.DetailsPayment;
                editorEarningCompanyPayer.SelectedItem = (objEarning.CompanyPayer == null) ? null : editorEarningCompanyPayer.Properties.Items.Cast<CCompany>().SingleOrDefault<CCompany>(x => x.ID.CompareTo(objEarning.CompanyPayer.ID) == 0);
                editorEarningAccountPlan.SelectedItem = (objEarning.AccountPlan == null) ? null : editorEarningAccountPlan.Properties.Items.Cast<CAccountPlan>().SingleOrDefault<CAccountPlan>(x => x.ID.CompareTo(objEarning.AccountPlan.ID) == 0);
                editorEarningProjectSrc.SelectedItem = (objEarning.BudgetProjectSrc == null) ? null : editorEarningProjectSrc.Properties.Items.Cast<CBudgetProject>().SingleOrDefault<CBudgetProject>(x => x.ID.CompareTo(objEarning.BudgetProjectSrc.ID) == 0);
                editorEarningProjectDst.SelectedItem = (objEarning.BudgetProjectDst == null) ? null : editorEarningProjectDst.Properties.Items.Cast<CBudgetProject>().SingleOrDefault<CBudgetProject>(x => x.ID.CompareTo(objEarning.BudgetProjectDst.ID) == 0);

                calcEditMoneyToReturn.Value = m_objSelectedEarning.Saldo;
                dateEditMoneyToReturnOperationDate.EditValue = System.DateTime.Today;

                SetPropertiesModified(false);
                ValidateProperties();

                SetModeReadOnly(true);
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка копирования платежа. Текст ошибки: " + f.Message);
            }
            finally
            {
                this.tableLayoutPanelBackground.ResumeLayout(false);
                m_bDisableEvents = false;
                btnCancel.Enabled = true;
                tabControl.SelectedTabPage = tabPageEditor;
            }
            return;
        }

        private void btnCopyEarning_Click(object sender, EventArgs e)
        {
            try
            {
                CopyEarning(SelectedEarning);

                SetModeReadOnly(false);
                btnEdit.Enabled = false;
                btnNewEarning.Enabled = false;
                SetPropertiesModified(true);
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка копирования платежа. Текст ошибки: " + f.Message);
            }
            finally
            {
            }
            return;
        }

        private void mitemCopyEarningToolStripMenuItem_Click(object sender, EventArgs e)
        {

        }

        #endregion

        #region Удалить платёж
        /// <summary>
        /// Удаляет платёж
        /// </summary>
        private void DeleteEarning(CEarning objEarning)
        {
            if (objEarning == null) { return; }
            System.String strErr = "";

            try
            {
                System.Int32 iFocusedRowHandle = gridViewEarningList.FocusedRowHandle;
                if (DevExpress.XtraEditors.XtraMessageBox.Show(String.Format("Подтвердите, пожалуйста, удаление платежа.\n\nКлиент: {0}\n\nСумма: {1}", objEarning.CustomerName, System.String.Format("{0,10:G}: ", objEarning.Value)), "Подтверждение",
                    System.Windows.Forms.MessageBoxButtons.YesNo, System.Windows.Forms.MessageBoxIcon.Question) == DialogResult.No) { return; }

                if (CEarningDataBaseModel.RemoveObjectFromDataBase(objEarning.ID, m_objProfile, ref strErr) == true)
                {
                    StartThreadLoadEarningList();
                }
                else
                {
                    DevExpress.XtraEditors.XtraMessageBox.Show(strErr, "Предупреждение",
                    System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Warning);

                    SendMessageToLog("Удаление платежа. Текст ошибки: " + strErr);
                }
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Удаление платежа. Текст ошибки: " + f.Message);
            }
            finally
            {
            }
            return;
        }
        private void barBtnDelete_Click(object sender, EventArgs e)
        {
            try
            {
                DeleteEarning( SelectedEarning );
            }//try
            catch (System.Exception f)
            {
                SendMessageToLog("Удаление платежа. Текст ошибки: " + f.Message);
            }
            finally
            {
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
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка отмены изменений. Текст ошибки: " + f.Message);
            }
            finally
            {
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
                if (m_bIsChanged == true)
                {
                    if (DevExpress.XtraEditors.XtraMessageBox.Show(
                        "Выйти из редактора платежей без сохранения изменений?", "Подтверждение",
                        System.Windows.Forms.MessageBoxButtons.YesNoCancel, System.Windows.Forms.MessageBoxIcon.Question) != System.Windows.Forms.DialogResult.Yes  )
                    {
                        return;
                    }
                }

                tabControl.SelectedTabPage = tabPageViewer;
                if (m_objSelectedEarning != null)
                {
                    System.Int32 iIndxSelectedObject = m_objEarningList.IndexOf(m_objEarningList.SingleOrDefault<CEarning>(x => x.ID.CompareTo(m_objSelectedEarning.ID) == 0));
                    if( iIndxSelectedObject >= 0 )
                    {
                        gridViewEarningList.FocusedRowHandle = gridViewEarningList.GetRowHandle( iIndxSelectedObject );
                    }
                }
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка отмены изменений. Текст ошибки: " + f.Message);
            }
            finally
            {
            }

            return;

        }
        #endregion

        #region Сохранить изменения
        /// <summary>
        /// Сохраняет изменения в базе данных
        /// </summary>
        /// <returns>true - удачное завершение операции;false - ошибка</returns>
        private System.Boolean bSaveEarningPropertiesInDataBase(ref System.String strErr)
        {
            System.Boolean bRet = false;
            System.Boolean bOkSave = false;

            Cursor = Cursors.WaitCursor;
            try
            {
                System.String Earning_DocNum = editorEarningDocNum.Text;
                System.DateTime Earning_Date = editorEarningDate.DateTime;
                System.Guid Earning_AccountGuid = ((editorEarningAccount.SelectedItem == null) ? System.Guid.Empty : ((CAccount)editorEarningAccount.SelectedItem).ID);
                System.String Earning_CustomerText = editorEarningpayerDetail.Text;
                System.String Earning_DetailsPaymentText = editorEarningDetail.Text;
                System.Int32 Earning_iKey = System.Convert.ToInt32( editorEarningiKey.Value );
                System.Boolean Earning_IsBonus = editorEarningIsBonus.Checked;
                System.Guid Earning_CustomerGuid = ((editorEarningCustomer.SelectedItem == null) ? (System.Guid.Empty) : ((CCustomer)editorEarningCustomer.SelectedItem).ID);
                System.Guid Earning_CurrencyGuid = ((editorEarningCurrency.SelectedItem == null) ? (System.Guid.Empty) : ((CCurrency)editorEarningCurrency.SelectedItem).ID);
                System.Guid Earning_CompanyGuid = ((editorEarningCompanyDst.SelectedItem == null) ? (System.Guid.Empty) : ((CCompany)editorEarningCompanyDst.SelectedItem).ID);
                System.Guid PaymentType_Guid = ((editorEarningPaymentType.SelectedItem == null) ? (System.Guid.Empty) : ((CPaymentType)editorEarningPaymentType.SelectedItem).ID);
                System.Guid EarningType_Guid = ((editorEarningType.SelectedItem == null) ? (System.Guid.Empty) : ((CEarningType)editorEarningType.SelectedItem).ID);

                System.Guid CompanyPayer_Guid = ((editorEarningCompanyPayer.SelectedItem == null) ? (System.Guid.Empty) : ((CCompany)editorEarningCompanyPayer.SelectedItem).ID);
                System.Guid AccountPlan_Guid = ((editorEarningAccountPlan.SelectedItem == null) ? (System.Guid.Empty) : ((CAccountPlan)editorEarningAccountPlan.SelectedItem).ID);
                System.Guid BudgetProjectSRC_Guid = ((editorEarningProjectSrc.SelectedItem == null) ? (System.Guid.Empty) : ((CBudgetProject)editorEarningProjectSrc.SelectedItem).ID);
                System.Guid BudgetProjectDST_Guid = ((editorEarningProjectDst.SelectedItem == null) ? (System.Guid.Empty) : ((CBudgetProject)editorEarningProjectDst.SelectedItem).ID);

                System.Guid ChildDepart_Guid = System.Guid.Empty;
                System.Decimal Earning_Value = editorEarningValue.Value;
                System.Decimal Earning_CurrencyRate = 0;
                System.Decimal Earning_CurrencyValue = 0;
                System.Guid Earning_Guid = ((m_bNewObject == true) ? System.Guid.Empty : m_objSelectedEarning.ID);

                // проверка значений
                if (CEarningDataBaseModel.IsAllParametersValid(Earning_CustomerGuid, Earning_CurrencyGuid,
                Earning_Date, Earning_DocNum, Earning_AccountGuid, Earning_Value, Earning_CompanyGuid,
                Earning_CurrencyRate, Earning_CurrencyValue, Earning_CustomerText,
                Earning_DetailsPaymentText, Earning_iKey, BudgetProjectSRC_Guid,
                BudgetProjectDST_Guid, CompanyPayer_Guid, ChildDepart_Guid,
                AccountPlan_Guid, PaymentType_Guid, Earning_IsBonus, EarningType_Guid,
                ref strErr) == true)
                {
                    if (m_bNewObject == true)
                    {
                        // новый платёж
                        bOkSave = CEarningDataBaseModel.AddNewObjectToDataBase( Earning_CustomerGuid,
                            Earning_CurrencyGuid, Earning_Date, Earning_DocNum, Earning_AccountGuid,
                            Earning_Value, Earning_CompanyGuid,
                            Earning_CurrencyRate, Earning_CurrencyValue, Earning_CustomerText,
                            Earning_DetailsPaymentText, Earning_iKey, BudgetProjectSRC_Guid,
                            BudgetProjectDST_Guid, CompanyPayer_Guid, ChildDepart_Guid,
                            AccountPlan_Guid, PaymentType_Guid, Earning_IsBonus, EarningType_Guid,
                            ref Earning_Guid, m_objProfile, ref strErr );

                        if (bOkSave == true)
                        {
                            m_objSelectedEarning.ID = Earning_Guid;
                        }
                    }
                    else
                    {
                        bOkSave = CEarningDataBaseModel.EditObjectInDataBase(Earning_Guid, Earning_CustomerGuid,
                            Earning_CurrencyGuid, Earning_Date, Earning_DocNum, Earning_AccountGuid,
                            Earning_Value, Earning_CompanyGuid,
                            Earning_CurrencyRate, Earning_CurrencyValue, Earning_CustomerText,
                            Earning_DetailsPaymentText, Earning_iKey, BudgetProjectSRC_Guid,
                            BudgetProjectDST_Guid, CompanyPayer_Guid, ChildDepart_Guid,
                            AccountPlan_Guid, PaymentType_Guid, Earning_IsBonus, EarningType_Guid,
                            m_objProfile, ref strErr);
                    }
                }

                if (bOkSave == true)
                {
                    m_objSelectedEarning.DocNom = Earning_DocNum;
                    m_objSelectedEarning.Date = Earning_Date;
                    m_objSelectedEarning.CustomrText = Earning_CustomerText;
                    m_objSelectedEarning.DetailsPayment = Earning_DetailsPaymentText;
                    m_objSelectedEarning.IsBonusEarning = Earning_IsBonus;
                    m_objSelectedEarning.Customer = editorEarningCustomer.Properties.Items.Cast<CCustomer>().SingleOrDefault<CCustomer>(x => x.ID.Equals(Earning_CustomerGuid));
                    m_objSelectedEarning.Currency = editorEarningCurrency.Properties.Items.Cast<CCurrency>().SingleOrDefault<CCurrency>(x => x.ID.Equals(Earning_CurrencyGuid));
                    m_objSelectedEarning.Company = editorEarningCompanyDst.Properties.Items.Cast<CCompany>().SingleOrDefault<CCompany>(x => x.ID.Equals(Earning_CompanyGuid));
                    m_objSelectedEarning.CompanyPayer = editorEarningCompanyPayer.Properties.Items.Cast<CCompany>().SingleOrDefault<CCompany>(x => x.ID.Equals(CompanyPayer_Guid));
                    m_objSelectedEarning.PaymentType = editorEarningPaymentType.Properties.Items.Cast<CPaymentType>().SingleOrDefault<CPaymentType>(x => x.ID.Equals(PaymentType_Guid));
                    m_objSelectedEarning.EarningType = editorEarningType.Properties.Items.Cast<CEarningType>().SingleOrDefault<CEarningType>(x => x.ID.Equals(EarningType_Guid));
                    m_objSelectedEarning.AccountPlan = editorEarningAccountPlan.Properties.Items.Cast<CAccountPlan>().SingleOrDefault<CAccountPlan>(x => x.ID.Equals(AccountPlan_Guid));
                    m_objSelectedEarning.Account = editorEarningAccount.Properties.Items.Cast<CAccount>().SingleOrDefault<CAccount>(x => x.ID.Equals(Earning_AccountGuid));
                    if (m_objSelectedEarning.Account != null)
                    {
                        m_objSelectedEarning.CodeBank = m_objSelectedEarning.Account.Bank.Code;
                        m_objSelectedEarning.AccountNumber = m_objSelectedEarning.Account.AccountNumber;
                    }
                    m_objSelectedEarning.BudgetProjectSrc = editorEarningProjectSrc.Properties.Items.Cast<CBudgetProject>().SingleOrDefault<CBudgetProject>(x => x.ID.Equals(BudgetProjectSRC_Guid));
                    m_objSelectedEarning.BudgetProjectDst = editorEarningProjectDst.Properties.Items.Cast<CBudgetProject>().SingleOrDefault<CBudgetProject>(x => x.ID.Equals(BudgetProjectDST_Guid));
                    m_objSelectedEarning.Value = Earning_Value;
                    m_objSelectedEarning.CurRate = Earning_CurrencyRate;
                    m_objSelectedEarning.CurValue = Earning_CurrencyValue;
                    m_objSelectedEarning.GroupKeyId = System.Convert.ToInt32(editorEarningiKey.Value);
                    m_objSelectedEarning.Saldo = (m_objSelectedEarning.Value - m_objSelectedEarning.Expense);

                    if (m_bNewObject == true)
                    {
                        m_objEarningList.Add(m_objSelectedEarning);
                    }
                    gridControlEarningList.RefreshDataSource();

                    editorEarningSaldo.Value = (m_objSelectedEarning.Value - editorEarningExpense.Value);

                }

                bRet = bOkSave;
            }
            catch (System.Exception f)
            {
                strErr = f.Message;
                SendMessageToLog("Ошибка сохранения изменений в платеже. Текст ошибки: " + f.Message);
            }
            finally
            {
                Cursor = Cursors.Default;
            }
            return bRet;
        }


        private void btnSave_Click(object sender, EventArgs e)
        {
            try
            {
                System.String strErr = "";
                if (bSaveEarningPropertiesInDataBase(ref strErr) == true)
                {
                    //tabControl.SelectedTabPage = tabPageViewer;
                    SetPropertiesModified(false);
                    SetModeReadOnly(true);
                }
                else
                {
                    DevExpress.XtraEditors.XtraMessageBox.Show( strErr, "Внимание",
                        System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Warning);
                }

            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка сохранения изменений в платеже. Текст ошибки: " + f.Message);
            }
            return;
        }

        #endregion

        #region Печать
        /// <summary>
        /// Экспорт журнала платежей в MS Excel
        /// </summary>
        /// <param name="strFileName">имя файла MS Excel</param>
        private void ExportToExcelEarningList(string strFileName)
        {
            try
            {
                this.Cursor = Cursors.WaitCursor;

                System.IO.FileInfo newFile = new System.IO.FileInfo(strFileName);
                if (newFile.Exists)
                {
                    newFile.Delete();
                    newFile = new System.IO.FileInfo(strFileName);
                }

                using (ExcelPackage package = new ExcelPackage(newFile))
                {
                    ExcelWorksheet worksheet = package.Workbook.Worksheets.Add(this.Text);

                    foreach (DevExpress.XtraGrid.Columns.GridColumn objColumn in gridViewEarningList.Columns)
                    {
                        if (objColumn.Visible == false) { continue; }

                        worksheet.Cells[1, objColumn.VisibleIndex + 1].Value = objColumn.Caption;
                    }

                    using (var range = worksheet.Cells[1, 1, 1, gridViewEarningList.Columns.Count])
                    {
                        range.Style.Font.Bold = true;
                        range.Style.Font.Size = 14;
                        //range.Style.Fill.PatternType = OfficeOpenXml.Style.ExcelFillStyle.Solid;
                        //range.Style.Fill.BackgroundColor.SetColor(Color.DarkBlue);
                        //range.Style.Font.Color.SetColor(Color.White);
                    }

                    System.Int32 iCurrentRow = 2;
                    System.Int32 iRowsCount = gridViewEarningList.RowCount;
                    for (System.Int32 i = 0; i < iRowsCount; i++ )
                    {
                        foreach (DevExpress.XtraGrid.Columns.GridColumn objColumn in gridViewEarningList.Columns)
                        {
                            if (objColumn.Visible == false) { continue; }

                            worksheet.Cells[iCurrentRow, objColumn.VisibleIndex + 1].Value = gridViewEarningList.GetRowCellValue(i, objColumn);
                            if (objColumn.FieldName == "Date")
                            {
                                worksheet.Cells[iCurrentRow, objColumn.VisibleIndex + 1].Style.Numberformat.Format = "DD.MM.YYYY";
                            }
                        }
                        iCurrentRow++;
                    }

                    iCurrentRow--;
                    worksheet.Cells[1, 1, iCurrentRow, gridViewEarningList.Columns.Count].AutoFitColumns(0);
                    worksheet.Cells[1, 1, iCurrentRow, gridViewEarningList.Columns.Count].Style.Border.Top.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    worksheet.Cells[1, 1, iCurrentRow, gridViewEarningList.Columns.Count].Style.Border.Left.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    worksheet.Cells[1, 1, iCurrentRow, gridViewEarningList.Columns.Count].Style.Border.Right.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    worksheet.Cells[1, 1, iCurrentRow, gridViewEarningList.Columns.Count].Style.Border.Bottom.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;

                    worksheet.PrinterSettings.FitToWidth = 1;

                    worksheet = null;

                    package.Save();

                    try
                    {
                        using (System.Diagnostics.Process process = new System.Diagnostics.Process())
                        {
                            process.StartInfo.FileName = strFileName;
                            process.StartInfo.Verb = "Open";
                            process.StartInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Normal;
                            process.Start();
                        }
                    }
                    catch
                    {
                        DevExpress.XtraEditors.XtraMessageBox.Show(this, "Системе не удалось найти приложение, чтобы открыть файл.", Application.ProductName, MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }

                }

            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show(
                    "Ошибка экспорта в MS Excel.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally
            {
                this.Cursor = System.Windows.Forms.Cursors.Default;
            }
        }

        /// <summary>
        /// Экспорт журнала платежей в MS Excel
        /// </summary>
        /// <param name="strFileName">имя файла MS Excel</param>
        private void ExportToExcelEarning(string strFileName)
        {
            try
            {
                this.Cursor = Cursors.WaitCursor;

                System.IO.FileInfo newFile = new System.IO.FileInfo(strFileName);
                if (newFile.Exists)
                {
                    newFile.Delete();
                    newFile = new System.IO.FileInfo(strFileName);
                }

                using (ExcelPackage package = new ExcelPackage(newFile))
                {
                    ExcelWorksheet worksheet = package.Workbook.Worksheets.Add(this.Text);
                    System.Int32 iColumnIndxCaption = 1;
                    System.Int32 iColumnIndxValue = 2;
                    System.Int32 iPropertiesCount = 0;

                    worksheet.Cells[System.Convert.ToInt32(lblEarningCompany.Tag), iColumnIndxCaption].Value = lblEarningCompany.Text;
                    worksheet.Cells[System.Convert.ToInt32(lblEarningCompany.Tag), iColumnIndxValue].Value = editorEarningCompanyDst.Text;
                    iPropertiesCount++;

                    worksheet.Cells[System.Convert.ToInt32(lblEarningCurrency.Tag), iColumnIndxCaption].Value = lblEarningCurrency.Text;
                    worksheet.Cells[System.Convert.ToInt32(lblEarningCurrency.Tag), iColumnIndxValue].Value = editorEarningCurrency.Text;
                    iPropertiesCount++;

                    worksheet.Cells[System.Convert.ToInt32(lblEarningPaymentType.Tag), iColumnIndxCaption].Value = lblEarningPaymentType.Text;
                    worksheet.Cells[System.Convert.ToInt32(lblEarningPaymentType.Tag), iColumnIndxValue].Value = editorEarningPaymentType.Text;
                    iPropertiesCount++;

                    worksheet.Cells[System.Convert.ToInt32(editorEarningIsBonus.Tag), iColumnIndxCaption].Value = editorEarningIsBonus.Text;
                    worksheet.Cells[System.Convert.ToInt32(editorEarningIsBonus.Tag), iColumnIndxValue].Value = (editorEarningIsBonus.Checked ? "+" : "");
                    iPropertiesCount++;

                    worksheet.Cells[System.Convert.ToInt32(lblEarningDate.Tag), iColumnIndxCaption].Value = lblEarningDate.Text;
                    worksheet.Cells[System.Convert.ToInt32(lblEarningDate.Tag), iColumnIndxValue].Value = editorEarningDate.Text;
                    iPropertiesCount++;

                    worksheet.Cells[System.Convert.ToInt32(lblEarningDocNum.Tag), iColumnIndxCaption].Value = lblEarningDocNum.Text;
                    worksheet.Cells[System.Convert.ToInt32(lblEarningDocNum.Tag), iColumnIndxValue].Value = editorEarningDocNum.Text;
                    iPropertiesCount++;

                    worksheet.Cells[System.Convert.ToInt32(lblEarningValue.Tag), iColumnIndxCaption].Value = lblEarningValue.Text;
                    worksheet.Cells[System.Convert.ToInt32(lblEarningValue.Tag), iColumnIndxValue].Value = editorEarningValue.Text;
                    iPropertiesCount++;

                    worksheet.Cells[System.Convert.ToInt32(lblEarningExpense.Tag), iColumnIndxCaption].Value = lblEarningExpense.Text;
                    worksheet.Cells[System.Convert.ToInt32(lblEarningExpense.Tag), iColumnIndxValue].Value = editorEarningExpense.Text;
                    iPropertiesCount++;

                    worksheet.Cells[System.Convert.ToInt32(lblEarningSaldo.Tag), iColumnIndxCaption].Value = lblEarningSaldo.Text;
                    worksheet.Cells[System.Convert.ToInt32(lblEarningSaldo.Tag), iColumnIndxValue].Value = editorEarningSaldo.Text;
                    iPropertiesCount++;

                    worksheet.Cells[System.Convert.ToInt32(lblEarningPayer.Tag), iColumnIndxCaption].Value = lblEarningPayer.Text;
                    worksheet.Cells[System.Convert.ToInt32(lblEarningPayer.Tag), iColumnIndxValue].Value = editorEarningCustomer.Text;
                    iPropertiesCount++;

                    worksheet.Cells[System.Convert.ToInt32(lblEarningPayerDescrpn.Tag), iColumnIndxCaption].Value = lblEarningPayerDescrpn.Text;
                    worksheet.Cells[System.Convert.ToInt32(lblEarningPayerDescrpn.Tag), iColumnIndxValue].Value = editorEarningpayerDetail.Text;
                    iPropertiesCount++;

                    worksheet.Cells[System.Convert.ToInt32(lblEarningAccount.Tag), iColumnIndxCaption].Value = lblEarningAccount.Text;
                    worksheet.Cells[System.Convert.ToInt32(lblEarningAccount.Tag), iColumnIndxValue].Value = editorEarningAccount.Text;
                    iPropertiesCount++;

                    worksheet.Cells[System.Convert.ToInt32(lblEarningBank.Tag), iColumnIndxCaption].Value = lblEarningBank.Text;
                    worksheet.Cells[System.Convert.ToInt32(lblEarningBank.Tag), iColumnIndxValue].Value = editorEarningBank.Text;
                    iPropertiesCount++;

                    worksheet.Cells[System.Convert.ToInt32(lblEarningObject.Tag), iColumnIndxCaption].Value = lblEarningObject.Text;
                    worksheet.Cells[System.Convert.ToInt32(lblEarningObject.Tag), iColumnIndxValue].Value = editorEarningDetail.Text;
                    iPropertiesCount++;

                    worksheet.Cells[System.Convert.ToInt32(lblEarningCompanySrc.Tag), iColumnIndxCaption].Value = lblEarningCompanySrc.Text;
                    worksheet.Cells[System.Convert.ToInt32(lblEarningCompanySrc.Tag), iColumnIndxValue].Value = editorEarningCompanyPayer.Text;
                    iPropertiesCount++;

                    worksheet.Cells[System.Convert.ToInt32(lblEarningAccountPlan.Tag), iColumnIndxCaption].Value = lblEarningAccountPlan.Text;
                    worksheet.Cells[System.Convert.ToInt32(lblEarningAccountPlan.Tag), iColumnIndxValue].Value = editorEarningAccountPlan.Text;
                    iPropertiesCount++;

                    worksheet.Cells[System.Convert.ToInt32(lblEarningBudgetProjectSrc.Tag), iColumnIndxCaption].Value = lblEarningBudgetProjectSrc.Text;
                    worksheet.Cells[System.Convert.ToInt32(lblEarningBudgetProjectSrc.Tag), iColumnIndxValue].Value = editorEarningProjectSrc.Text;
                    iPropertiesCount++;

                    worksheet.Cells[System.Convert.ToInt32(lblEarningBudgetProjectDst.Tag), iColumnIndxCaption].Value = lblEarningBudgetProjectDst.Text;
                    worksheet.Cells[System.Convert.ToInt32(lblEarningBudgetProjectDst.Tag), iColumnIndxValue].Value = editorEarningProjectDst.Text;
                    iPropertiesCount++;

                    using (var range = worksheet.Cells[1, iColumnIndxCaption, iPropertiesCount, iColumnIndxCaption])
                    {
                        range.Style.Font.Bold = true;
                        range.Style.Font.Size = 12;
                        //range.Style.Fill.PatternType = OfficeOpenXml.Style.ExcelFillStyle.Solid;
                        //range.Style.Fill.BackgroundColor.SetColor(Color.DarkBlue);
                        //range.Style.Font.Color.SetColor(Color.White);
                    }

                    worksheet.Cells[1, iColumnIndxCaption, iPropertiesCount, iColumnIndxValue].AutoFitColumns(0);

                    worksheet.Cells[1, iColumnIndxCaption, iPropertiesCount, iColumnIndxValue].Style.Border.Top.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    worksheet.Cells[1, iColumnIndxCaption, iPropertiesCount, iColumnIndxValue].Style.Border.Left.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    worksheet.Cells[1, iColumnIndxCaption, iPropertiesCount, iColumnIndxValue].Style.Border.Right.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    worksheet.Cells[1, iColumnIndxCaption, iPropertiesCount, iColumnIndxValue].Style.Border.Bottom.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;

                    worksheet.PrinterSettings.FitToWidth = 1;

                    worksheet = null;

                    package.Save();

                    try
                    {
                        using (System.Diagnostics.Process process = new System.Diagnostics.Process())
                        {
                            process.StartInfo.FileName = strFileName;
                            process.StartInfo.Verb = "Open";
                            process.StartInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Normal;
                            process.Start();
                        }
                    }
                    catch
                    {
                        DevExpress.XtraEditors.XtraMessageBox.Show(this, "Системе не удалось найти приложение, чтобы открыть файл.", Application.ProductName, MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }

                }

            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show(
                    "Ошибка экспорта в MS Excel.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally
            {
                this.Cursor = System.Windows.Forms.Cursors.Default;
            }
        }

        private void barbtnPrint_Click(object sender, EventArgs e)
        {
            try
            {
                ExportToExcelEarningList(String.Format("{0}{1}.xlsx", System.IO.Path.GetTempPath(), this.Text));
            }
            catch (System.Exception f)
            {
                SendMessageToLog("btnPrint_Click. Текст ошибки: " + f.Message);
            }

            return;
        }
        private void btnPrintEarningProperties_Click(object sender, EventArgs e)
        {
            try
            {
                ExportToExcelEarning(String.Format("{0}{1}.xlsx", System.IO.Path.GetTempPath(), "Платёж"));
            }
            catch (System.Exception f)
            {
                SendMessageToLog("btnPrint_Click. Текст ошибки: " + f.Message);
            }

            return;
        }
        #endregion

        #region Вызов редактора расчётных счетов

        private void SelectAccount()
        {
            try
            {
                frmAccountList AccountListFrm = new frmAccountList(m_objMenuItem);

                if (AccountListFrm != null)
                {
                    if (AccountListFrm.ShowDialog() == System.Windows.Forms.DialogResult.OK)
                    {
                        // в том случае, если плательщик указан, но выбранный в журнале расчётный счёт отсутствует у клиента, 
                        // то выводим приглашение о присвоении счёта клиенту
                        if (AccountListFrm.SelectedAccount != null)
                        {

                            CAccount objItem = editorEarningAccount.Properties.Items.Cast<CAccount>().SingleOrDefault<CAccount>(x => x.ID.Equals(AccountListFrm.SelectedAccount));
                            if (objItem == null)
                            {
                                editorEarningAccount.Properties.Items.Add(AccountListFrm.SelectedAccount);
                            }
                            editorEarningAccount.SelectedItem = editorEarningAccount.Properties.Items.Cast<CAccount>().SingleOrDefault<CAccount>(x => x.ID.Equals(AccountListFrm.SelectedAccount.ID));
                            editorEarningBank.SelectedItem = editorEarningBank.Properties.Items.Cast<CBank>().SingleOrDefault<CBank>(x => x.Code == AccountListFrm.SelectedAccount.Bank.Code);
                        }
                    }

                    AccountListFrm.Dispose();
                }

                AccountListFrm = null;
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show(
                    "Текст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }

            return;
        }

        private void btnSelectAccount_Click(object sender, EventArgs e)
        {
            try
            {
                SelectAccount();
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show(
                    "btnSelectAccount_Click. Текст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }

            return;
        }

        #endregion

        #region Журнал документов на оплату
        private void btnCancelPay_Click(object sender, EventArgs e)
        {
            try
            {
                tabControl.SelectedTabPage = tabPageViewer;
                if (m_objSelectedEarning != null)
                {
                    System.Int32 iIndxSelectedObject = m_objEarningList.IndexOf(m_objEarningList.SingleOrDefault<CEarning>(x => x.ID.CompareTo(m_objSelectedEarning.ID) == 0));
                    if (iIndxSelectedObject >= 0)
                    {
                        gridViewEarningList.FocusedRowHandle = gridViewEarningList.GetRowHandle(iIndxSelectedObject);
                    }
                }
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка отмены изменений. Текст ошибки: " + f.Message);
            }
            finally
            {
            }

            return;
        }

        /// <summary>
        /// Отображает журнал документов на оплату
        /// </summary>
        /// <param name="objEarning">платеж</param>
        public void ShowDebitDocumentList(CEarning objEarning)
        {
            if (objEarning == null) { return; }
            m_bDisableEvents = true;
            m_bNewObject = false;
            try
            {
                m_objSelectedEarning = objEarning;

                txtEarningDocDebitDoc.Text = "";
                txtEarningDateDebitDoc.Text = "";
                txtEarningBankCodeDebitDoc.Text = "";
                txtEarningAccountNumberDebitDoc.Text = "";
                calcEarningValueDebitDoc.Value = 0;
                calcEarningSaldoDebitDoc.Value = 0;
                calcEarningExpenseDebitDoc.Value = 0;

                txtEarningPayerDebitDoc.Text = "";
                txtPayerDescrpnDebitDoc.Text = "";
                txtEarningDetailDebitDoc.Text = "";

                if (objEarning != null)
                {
                    txtEarningDocDebitDoc.Text = objEarning.DocNom;
                    txtEarningDateDebitDoc.Text = objEarning.Date.ToShortDateString();
                    txtEarningBankCodeDebitDoc.Text = objEarning.CodeBank;
                    txtEarningAccountNumberDebitDoc.Text = objEarning.AccountNumber;
                    calcEarningValueDebitDoc.Value = System.Convert.ToDecimal(objEarning.Value);
                    calcEarningSaldoDebitDoc.Value = System.Convert.ToDecimal(objEarning.Saldo);
                    calcEarningExpenseDebitDoc.Value = System.Convert.ToDecimal(objEarning.Expense);
                    txtEarningPayerDebitDoc.Text = objEarning.CustomerName;
                    txtPayerDescrpnDebitDoc.Text = objEarning.CustomrText;
                    txtEarningDetailDebitDoc.Text = objEarning.DetailsPayment;
                }

                lblEarningInfoInpayDebitDocument.Text = strWaitCustomer;
                lblCaptionDebitDocumentList.Text = "Журнал документов на оплату";
                if (m_objSelectedEarning.Company != null)
                {
                    lblCaptionDebitDocumentList.Text += (String.Format("\t\tкомпания: {0}", m_objSelectedEarning.Company.Name));
                }

                if (m_objSelectedEarning.Customer != null)
                {
                    lblCaptionDebitDocumentList.Text += (String.Format("\tклиент: {0}", m_objSelectedEarning.Customer.FullName));
                }

                pictureBoxInfoInDebitDocList.Image = ERPMercuryBankStatement.Properties.Resources.Warning_32;
                lblEarningInfoInpayDebitDocument.Text = strWaitCustomer;

                StartThreadLoadDebitDocumentList();

            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка загрузки журнала документов на оплату. Текст ошибки: " + f.Message);
            }
            finally
            {
                tabControl.SelectedTabPage = tabPageDebitDocList;
                tabPageDebitDocList.Refresh();
            }
            return;
        }
        private void barBtnDebitDocumentList_Click(object sender, EventArgs e)
        {
            try
            {
                ShowDebitDocumentList(SelectedEarning);
            }
            catch (System.Exception f)
            {
                SendMessageToLog("barBtnDebitDocumentList_Click. Текст ошибки: " + f.Message);
            }
        }

        /// <summary>
        /// Экспорт журнала документов на оплату в MS Excel
        /// </summary>
        /// <param name="strFileName">имя файла MS Excel</param>
        private void ExportToExcelDebitDocumentList(string strFileName)
        {
            try
            {
                this.Cursor = Cursors.WaitCursor;

                System.IO.FileInfo newFile = new System.IO.FileInfo(strFileName);
                if (newFile.Exists)
                {
                    newFile.Delete();
                    newFile = new System.IO.FileInfo(strFileName);
                }

                using (ExcelPackage package = new ExcelPackage(newFile))
                {
                    ExcelWorksheet worksheet = package.Workbook.Worksheets.Add(this.Text);

                    foreach (DevExpress.XtraGrid.Columns.GridColumn objColumn in gridViewDebitDocumentList.Columns)
                    {
                        if (objColumn.Visible == false) { continue; }

                        worksheet.Cells[1, objColumn.VisibleIndex + 1].Value = objColumn.Caption;
                    }

                    using (var range = worksheet.Cells[1, 1, 1, gridViewDebitDocumentList.Columns.Count])
                    {
                        range.Style.Font.Bold = true;
                        range.Style.Font.Size = 14;
                        //range.Style.Fill.PatternType = OfficeOpenXml.Style.ExcelFillStyle.Solid;
                        //range.Style.Fill.BackgroundColor.SetColor(Color.DarkBlue);
                        //range.Style.Font.Color.SetColor(Color.White);
                    }

                    System.Int32 iCurrentRow = 2;
                    System.Int32 iRowsCount = gridViewDebitDocumentList.RowCount;
                    for (System.Int32 i = 0; i < iRowsCount; i++)
                    {
                        foreach (DevExpress.XtraGrid.Columns.GridColumn objColumn in gridViewDebitDocumentList.Columns)
                        {
                            if (objColumn.Visible == false) { continue; }

                            worksheet.Cells[iCurrentRow, objColumn.VisibleIndex + 1].Value = gridViewDebitDocumentList.GetRowCellValue(i, objColumn);
                            if ((objColumn.FieldName == "Waybill_BeginDate") || (objColumn.FieldName == "Waybill_EndDate") || (objColumn.FieldName == "Waybill_DateLastPaid"))
                            {
                                worksheet.Cells[iCurrentRow, objColumn.VisibleIndex + 1].Style.Numberformat.Format = "DD.MM.YYYY";
                            }
                        }
                        iCurrentRow++;
                    }

                    iCurrentRow--;
                    worksheet.Cells[1, 1, iCurrentRow, gridViewEarningHistoryList.Columns.Count].AutoFitColumns(0);
                    worksheet.Cells[1, 1, iCurrentRow, gridViewEarningHistoryList.Columns.Count].Style.Border.Top.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    worksheet.Cells[1, 1, iCurrentRow, gridViewEarningHistoryList.Columns.Count].Style.Border.Left.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    worksheet.Cells[1, 1, iCurrentRow, gridViewEarningHistoryList.Columns.Count].Style.Border.Right.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    worksheet.Cells[1, 1, iCurrentRow, gridViewEarningHistoryList.Columns.Count].Style.Border.Bottom.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;

                    worksheet.PrinterSettings.FitToWidth = 1;

                    worksheet = null;

                    package.Save();

                    try
                    {
                        using (System.Diagnostics.Process process = new System.Diagnostics.Process())
                        {
                            process.StartInfo.FileName = strFileName;
                            process.StartInfo.Verb = "Open";
                            process.StartInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Normal;
                            process.Start();
                        }
                    }
                    catch
                    {
                        DevExpress.XtraEditors.XtraMessageBox.Show(this, "Системе не удалось найти приложение, чтобы открыть файл.", Application.ProductName, MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }

                }

            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show(
                    "Ошибка экспорта в MS Excel.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally
            {
                this.Cursor = System.Windows.Forms.Cursors.Default;
            }
        }
        private void btnPrintDebitDocumentList_Click(object sender, EventArgs e)
        {
            try
            {
                ExportToExcelDebitDocumentList(String.Format("{0}{1}.xlsx", System.IO.Path.GetTempPath(), (String.Format("{0} журнал документов на оплату", this.Text))));
            }
            catch (System.Exception f)
            {
                SendMessageToLog("btnPrint_Click. Текст ошибки: " + f.Message);
            }

            return;
        }

        private void gridViewDebitDocumentList_FocusedRowChanged(object sender, DevExpress.XtraGrid.Views.Base.FocusedRowChangedEventArgs e)
        {
            try
            {
                btnPayDebitDocument.Enabled = ((m_objSelectedEarning != null) && (m_objSelectedEarning.Saldo > 0) && (gridViewDebitDocumentList.RowCount > 0) && (gridViewDebitDocumentList.FocusedRowHandle >= 0));
            }
            catch (System.Exception f)
            {
                SendMessageToLog("gridViewDebitDocumentList_FocusedRowChanged. Текст ошибки: " + f.Message);
            }

            return;
        }

        private void gridViewDebitDocumentList_RowCountChanged(object sender, EventArgs e)
        {
            try
            {
                btnPayDebitDocument.Enabled = ((m_objSelectedEarning != null) && (m_objSelectedEarning.Saldo > 0) && (gridViewDebitDocumentList.RowCount > 0) && (gridViewDebitDocumentList.FocusedRowHandle >= 0));
            }
            catch (System.Exception f)
            {
                SendMessageToLog("gridViewDebitDocumentList_RowCountChanged. Текст ошибки: " + f.Message);
            }

            return;
        }
        private void contextMenuStripDebitDocument_Opening(object sender, CancelEventArgs e)
        {
            try
            {
               mitmsStartpayDebitDocument.Enabled = ((m_objSelectedEarning != null) && (m_objSelectedEarning.Saldo > 0) && (gridViewDebitDocumentList.RowCount > 0) && (gridViewDebitDocumentList.FocusedRowHandle >= 0));
            }
            catch (System.Exception f)
            {
                SendMessageToLog("contextMenuStripDebitDocument_Opening. Текст ошибки: " + f.Message);
            }

            return;
        }

        #endregion

        #region Оплата

        /// <summary>
        /// Оплата конкретного документа
        /// </summary>
        /// <param name="objDebitDocument">документ на оплату</param>
        private void PayDebitDocument(CDebitDocument objDebitDocument)
        {
            try
            {
                if (m_objSelectedEarning == null)
                {
                    DevExpress.XtraEditors.XtraMessageBox.Show( "Программе не удалось определить платёж для оплаты.", "Внимание!",
                        System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Warning);

                    return;
                }

                if (objDebitDocument == null)
                {
                    DevExpress.XtraEditors.XtraMessageBox.Show( "Программе не удалось определить документ для оплаты.", "Внимание!",
                        System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Warning);

                    return;
                }

                if (objDebitDocument.Waybill_Saldo == 0 )
                {
                    DevExpress.XtraEditors.XtraMessageBox.Show("Докумен уже оплачен (сальдо равно нулю).", "Внимание!",
                        System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Warning);

                    return;
                }

                System.Decimal FINDED_MONEY = 0;
                System.String DOC_NUM = System.String.Empty;  
                System.DateTime DOC_DATE = System.DateTime.MinValue; 
                System.Decimal	DOC_SALDO = 0;
                System.Decimal EARNING_SALDO = 0;
                System.Decimal EARNING_EXPENSE = 0;
                System.Int32 ERROR_NUM = 0;  
                System.String strErr = System.String.Empty;

                System.Int32 iRet = CPaymentDataBaseModel.PayDebitDocumentForm1( m_objProfile, null,
                    m_objSelectedEarning.ID, objDebitDocument.Waybill_Id, ref FINDED_MONEY,
                    ref DOC_NUM,  ref DOC_DATE, ref DOC_SALDO, ref EARNING_SALDO, ref EARNING_EXPENSE, ref ERROR_NUM, ref strErr );
                if( (iRet == 0) && ( ERROR_NUM == 0 ) )
                {
                    CDebitDocument objItem = m_objDebitDocumentList.SingleOrDefault<CDebitDocument>(x => x.Waybill_Id.Equals(objDebitDocument.Waybill_Id));
                    if (objItem != null)
                    {
                        objItem.Waybill_Saldo = DOC_SALDO;
                        if (objItem.Waybill_Saldo == 0) { m_objDebitDocumentList.Remove(objItem); }

                        if (m_objSelectedEarning != null)
                        {
                            m_objSelectedEarning.Expense = EARNING_EXPENSE;
                            m_objSelectedEarning.Saldo = EARNING_SALDO;

                            calcEarningExpenseDebitDoc.Value = m_objSelectedEarning.Expense;
                            calcEarningSaldoDebitDoc.Value = m_objSelectedEarning.Saldo;
                            lblEarningInfoInpayDebitDocument.Text = (String.Format("Остаток платежа:\t{0:### ### ##0.00}", m_objSelectedEarning.Saldo));

                        }

                        gridControlDebitDocList.RefreshDataSource();
                        SendMessageToLog(System.String.Format("Произведена оплата. Сумма: {0:### ### ##0}  Документ № {1}  от {2}  Остаток платежа: {3:### ### ##0.00}", FINDED_MONEY, DOC_NUM, DOC_DATE, EARNING_SALDO));

                        DevExpress.XtraEditors.XtraMessageBox.Show(System.String.Format("Произведена оплата. Сумма: {0:### ### ##0}  \nДокумент № {1}  от {2}\nОстаток платежа: {3:### ### ##0.00}", FINDED_MONEY, DOC_NUM, DOC_DATE, EARNING_SALDO), "Внимание!",
                            System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Information);

                        return;
                    }
                }
                else
                {
                    DevExpress.XtraEditors.XtraMessageBox.Show(strErr, "Внимание!",
                        System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
                }

            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка оплаты. Текст ошибки: " + f.Message);
            }

            return;
        }

        /// <summary>
        /// Запускает процедуру оплаты долгов в зависимости от выбранного варианта
        /// </summary>
        private void PayDebitDocumentsWithVariant()
        {
            try
            {
                if ((gridViewDebitDocumentList.RowCount == 0) || (gridViewDebitDocumentList.FocusedRowHandle < 0)) { return; }

                switch (radioGroupPayVariant.SelectedIndex)
                {
                    case 0:
                        {
                            // Авто
                            StartThreadPayDebitDocumentList();

                            break;
                        }
                    case 1:
                        {
                            // Ручная
                            if ((((DevExpress.XtraGrid.Views.Grid.GridView)gridControlDebitDocList.MainView).RowCount > 0) &&
                                (((DevExpress.XtraGrid.Views.Grid.GridView)gridControlDebitDocList.MainView).FocusedRowHandle >= 0))
                            {
                                System.Int32 iID = (System.Int32)(((DevExpress.XtraGrid.Views.Grid.GridView)gridControlDebitDocList.MainView)).GetFocusedRowCellValue("Waybill_Id");

                                CDebitDocument objSelectedDebitDocument = m_objDebitDocumentList.SingleOrDefault<CDebitDocument>(x => x.Waybill_Id.Equals(iID));

                                if (objSelectedDebitDocument != null)
                                {
                                    PayDebitDocument(objSelectedDebitDocument);
                                }

                                objSelectedDebitDocument = null;
                            }
                            break;
                        }
                    default:
                        break;

                }
            }
            catch (System.Exception f)
            {
                SendMessageToLog("PayDebitDocumentsWithVariant. Текст ошибки: " + f.Message);
            }

            return;
        }
        
        private void btnPayDebitDocument_Click(object sender, EventArgs e)
        {
            try
            {
                PayDebitDocumentsWithVariant();
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка оплаты. Текст ошибки: " + f.Message);
            }

            return;
        }

        /// <summary>
        /// Стартует поток, в котором оплачиваются долги клиента
        /// </summary>
        public void StartThreadPayDebitDocumentList()
        {
            try
            {
                if (m_objSelectedEarning == null)
                {
                    DevExpress.XtraEditors.XtraMessageBox.Show("Программе не удалось определить платёж для оплаты.", "Внимание!",
                        System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Warning);

                    return;
                }

                if (gridViewDebitDocumentList.RowCount == 0)
                {
                    DevExpress.XtraEditors.XtraMessageBox.Show("Список документов на оплату пуст.", "Внимание!",
                        System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Warning);

                    return;
                }

                //
                lblEarningInfoInpayDebitDocument.Text = "идёт процесс оплаты задолженности....";
                lblEarningInfoInpayDebitDocument.Refresh();
                Cursor = Cursors.WaitCursor;


                // инициализируем делегаты
                m_SetPaymentInDebitDocumentDelegate = new SetPaymentInDebitDocumentDelegate(SetPaymentInDebitDocument);

                // список документов для оплаты
                List<CDebitDocument> objDebitDocumentList = new List<CDebitDocument>();
                for (System.Int32 i = 0; i < gridViewDebitDocumentList.RowCount; i++)
                {
                    objDebitDocumentList.Add(m_objDebitDocumentList[gridViewDebitDocumentList.GetDataSourceRowIndex(i)]);
                }

                // запуск потока
                this.ThreadPayDocumentList = new System.Threading.Thread(unused => PayDebitDocumentListInThread(objDebitDocumentList));
                this.ThreadPayDocumentList.Start();

                Thread.Sleep(1000);

            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("StartThreadLoadDebitDocumentList().\n\nТекст ошибки: " + f.Message, "Ошибка",
                    System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }

            return;
        }

        public void PayDebitDocumentListInThread(List<CDebitDocument> objDebitDocumentList)
        {
            try
            {

                if ((objDebitDocumentList == null) || (objDebitDocumentList.Count == 0))
                {
                    DevExpress.XtraEditors.XtraMessageBox.Show("Список документов на оплату пуст.", "Внимание!",
                        System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Warning);

                    return;
                }

                System.Decimal FINDED_MONEY = 0;
                System.Decimal ALLFINDED_MONEY = 0;

                System.String DOC_NUM = System.String.Empty;
                System.DateTime DOC_DATE = System.DateTime.MinValue;
                System.Decimal DOC_SALDO = 0;
                System.Decimal EARNING_SALDO = m_objSelectedEarning.Saldo;
                System.Decimal EARNING_EXPENSE = m_objSelectedEarning.Expense;
                System.Int32 ERROR_NUM = 0;
                System.String strErr = System.String.Empty;
                System.Int32 iCurrentIndex = 0;
                System.Int32 iAllObjectCount = objDebitDocumentList.Count;
                System.Int32 iRet = 0;

                foreach (CDebitDocument objDebitDocument in objDebitDocumentList)
                {
                    iCurrentIndex++;

                    FINDED_MONEY = 0;
                    DOC_NUM = System.String.Empty;
                    DOC_DATE = System.DateTime.MinValue;
                    DOC_SALDO = 0;
                    ERROR_NUM = 0;
                    strErr = System.String.Empty;

                    if( (EARNING_SALDO > 0) && (objDebitDocument.Waybill_Saldo < 0))
                    {

                        Thread.Sleep(1000);
                        this.Invoke(m_SetPaymentInDebitDocumentDelegate, new Object[] { objDebitDocument.Waybill_Id, ERROR_NUM, strErr, 
                               FINDED_MONEY, ALLFINDED_MONEY, DOC_NUM, DOC_DATE, DOC_SALDO, 
                               EARNING_EXPENSE, EARNING_SALDO, 
                               iCurrentIndex, iAllObjectCount, ( iCurrentIndex ==  iAllObjectCount), true
                            });

                        iRet = CPaymentDataBaseModel.PayDebitDocumentForm1(m_objProfile, null,
                            m_objSelectedEarning.ID, objDebitDocument.Waybill_Id, ref FINDED_MONEY,
                            ref DOC_NUM, ref DOC_DATE, ref DOC_SALDO, ref EARNING_SALDO, ref EARNING_EXPENSE, ref ERROR_NUM, ref strErr);

                        ALLFINDED_MONEY += (FINDED_MONEY);

                        Thread.Sleep(1000);
                        this.Invoke(m_SetPaymentInDebitDocumentDelegate, new Object[] { objDebitDocument.Waybill_Id, ERROR_NUM, strErr, 
                               FINDED_MONEY, ALLFINDED_MONEY, DOC_NUM, DOC_DATE, DOC_SALDO, 
                               EARNING_EXPENSE, EARNING_SALDO, 
                               iCurrentIndex, iAllObjectCount, ( iCurrentIndex ==  iAllObjectCount), false
                            });
                    }

                    if (iCurrentIndex == iAllObjectCount)
                    {
                        Thread.Sleep(1000);
                        this.Invoke(m_SetPaymentInDebitDocumentDelegate, new Object[] { objDebitDocument.Waybill_Id, ERROR_NUM, strErr, 
                               FINDED_MONEY, ALLFINDED_MONEY, DOC_NUM, DOC_DATE, DOC_SALDO, 
                               EARNING_EXPENSE, EARNING_SALDO, 
                               iCurrentIndex, iAllObjectCount, ( iCurrentIndex ==  iAllObjectCount), false
                            });
                    }

                }

            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка оплаты. Текст ошибки: " + f.Message);
            }

            return;
        }

        public void SetPaymentInDebitDocument(System.Int32 iWaybill_Id, System.Int32 ERROR_NUM, System.String ERROR_STR, 
            System.Decimal FINDED_MONEY, System.Decimal ALLFINDED_MONEY, 
            System.String DOC_NUM, System.DateTime DOC_DATE, System.Decimal DOC_SALDO, 
            System.Decimal EARNING_EXPENSE, System.Decimal EARNING_SALDO, 
            System.Int32 iCurrentIndex, System.Int32 iAllObjectCount, System.Boolean bLastPayment, System.Boolean bPreparePayment
            )
        {
            try
            {
                if (bPreparePayment == true)
                {
                    SendMessageToLog(System.String.Format("Обрабатывается запись №{0:### ### ##0}  из {1:### ### ##0}", iCurrentIndex, iAllObjectCount));
                    lblEarningInfoInpayDebitDocument.Text = System.String.Format("Оплачивается документ № {0}  от {1}  Остаток платежа: {2:### ### ##0.00}", DOC_NUM, DOC_DATE, EARNING_SALDO);


                    lblEarningInfoInpayDebitDocument.Refresh();
                    
                    return;
                }
                if (ERROR_NUM == 0)
                {
                    CDebitDocument objItem = m_objDebitDocumentList.SingleOrDefault<CDebitDocument>(x => x.Waybill_Id.Equals(iWaybill_Id));
                    if (objItem != null)
                    {
                        objItem.Waybill_Saldo = DOC_SALDO;
                        objItem.Waybill_IsPaid = true;

                        if (m_objSelectedEarning != null)
                        {
                            m_objSelectedEarning.Expense = EARNING_EXPENSE;
                            m_objSelectedEarning.Saldo = EARNING_SALDO;

                            calcEarningExpenseDebitDoc.Value = m_objSelectedEarning.Expense;
                            calcEarningSaldoDebitDoc.Value = m_objSelectedEarning.Saldo;
                            
                        }

                        if (bLastPayment == false)
                        {
                            lblEarningInfoInpayDebitDocument.Text = System.String.Format("Произведена оплата. Сумма: {0:### ### ##0}  Документ № {1}  от {2}  Остаток платежа: {3:### ### ##0.00}", FINDED_MONEY, DOC_NUM, DOC_DATE, EARNING_SALDO);
                            SendMessageToLog(System.String.Format("Обработана запись №{0:### ### ##0}  из {1:### ### ##0}", iCurrentIndex, iAllObjectCount));
                            SendMessageToLog(System.String.Format("Произведена оплата. Сумма: {0:### ### ##0}  Документ № {1}  от {2}  Остаток платежа: {3:### ### ##0.00}", FINDED_MONEY, DOC_NUM, DOC_DATE, EARNING_SALDO));
                        }

                        gridControlDebitDocList.RefreshDataSource();
                        lblEarningInfoInpayDebitDocument.Refresh();
                    }
                }
                else
                {
                    SendMessageToLog(ERROR_STR);
                }

                if (bLastPayment == true)
                {
                    Cursor = Cursors.Default;

                    lblEarningInfoInpayDebitDocument.Text = (String.Format("Остаток платежа:\t{0:### ### ##0.00}", m_objSelectedEarning.Saldo));

                    DevExpress.XtraEditors.XtraMessageBox.Show(System.String.Format("Произведена оплата.\nИтоговая сумаа оплаты по накладным: {0:### ### ##0}\n\nОстаток платежа: {1:### ### ##0.00}", ALLFINDED_MONEY, EARNING_SALDO), "Внимание!",
                        System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Information);

                }
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("SetPaymentInDebitDocument.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally
            {
            }
            return;
        }

        private void gridViewDebitDocumentList_CustomDrawCell(object sender, DevExpress.XtraGrid.Views.Base.RowCellCustomDrawEventArgs e)
        {
            try
            {
                if (e.Column.FieldName == "Waybill_IsPaid")
                {

                    if ((e.CellValue != null) && (System.Convert.ToBoolean(e.CellValue) == true))
                    {
                        System.Drawing.Image img = ERPMercuryBankStatement.Properties.Resources.check2;

                        Rectangle rImg = new Rectangle(e.Bounds.X - 6 + e.Bounds.Width / 2, e.Bounds.Y + (e.Bounds.Height - img.Size.Height) / 2, img.Width, img.Height);
                        e.Graphics.DrawImage(img, rImg);
                        Rectangle r = e.Bounds;
                        e.Handled = true;
                    }

                }
                else
                {
                    e.Handled = false;
                }

            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("gridViewDebitDocumentList_CustomDrawCell\n" + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            return;
        }

        /// <summary>
        /// Стартует поток, в котором оплачиваются долги клиента
        /// </summary>
        public void StartThreadAutoPayDebitDocumentList()
        {
            try
            {
                if (gridViewEarningList.RowCount == 0)
                {
                    DevExpress.XtraEditors.XtraMessageBox.Show("Список платежей пуст.", "Внимание!",
                        System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Warning);

                    return;
                }

                // список платежей
                List<CEarning> objEarningList = new List<CEarning>();
                for (System.Int32 i = 0; i < gridViewEarningList.RowCount; i++)
                {
                    if( (System.Convert.ToBoolean(gridViewEarningList.GetRowCellValue(i, STR_IncludeInManualPay)) == false) &&
                        (System.Convert.ToInt32(gridViewEarningList.GetRowCellValue(i, "EarningType_Id")) == 0))
                    {
                        objEarningList.Add(m_objEarningList[gridViewEarningList.GetDataSourceRowIndex(i)]);
                    }

                }

                System.Decimal dcmlAllEarningSaldo = objEarningList.Sum<CEarning>(x => x.Saldo);

                if (DevExpress.XtraEditors.XtraMessageBox.Show(String.Format("Общая сумма остатка платежей для разноски по долгам\nсоставляет\t:{0:### ### ### ##0.00}\nПодтвердите начало автоматической разноски платежей.", dcmlAllEarningSaldo), "Подтверждение",
                    System.Windows.Forms.MessageBoxButtons.YesNo, System.Windows.Forms.MessageBoxIcon.Question) == System.Windows.Forms.DialogResult.No)
                {
                    return;
                }

                if (m_objResultAutoPaid == null)
                {
                    m_objResultAutoPaid = new List<CDebitDocument>();
                }
                else
                {
                    m_objResultAutoPaid.Clear();
                }
                //
                SearchProcessWoring.Visible = true;
                SearchProcessWoring.Refresh();
                Cursor = Cursors.WaitCursor;

                // инициализируем делегаты
                m_SetInfoInSearchProcessWoringDelegate = new SetInfoInSearchProcessWoringDelegate( SetInfoInSearchProcessWoring );
                m_SetResultAutoPayDebitDocumentListDelegate = new SetResultAutoPayDebitDocumentListDelegate(SetResultAutoPayDebitDocumentList);


                // запуск потока
                this.ThreadPayDocumentList = new System.Threading.Thread(unused => AutoPayDebitDocumentListInThread(objEarningList));
                this.ThreadPayDocumentList.Start();

                Thread.Sleep(1000);

            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("StartThreadLoadDebitDocumentList().\n\nТекст ошибки: " + f.Message, "Ошибка",
                    System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }

            return;
        }

        public void AutoPayDebitDocumentListInThread(List<CEarning> objEarningList)
        {
            try
            {

                if ((objEarningList == null) || (objEarningList.Count == 0))
                {
                    DevExpress.XtraEditors.XtraMessageBox.Show("Список платежей для разноски пуст.", "Внимание!",
                        System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Warning);

                    return;
                }

                System.Decimal FINDED_MONEY = 0;
                System.Decimal ALLFINDED_MONEY = 0;
                System.Decimal EARNINGFINDED_MONEY = 0;

                System.Int32 DOC_ID = 0;
                System.String DOC_NUM = System.String.Empty;
                System.DateTime DOC_DATE = System.DateTime.MinValue;
                System.Decimal DOC_SALDO = 0;
                System.Decimal EARNING_SALDO = 0;
                System.Decimal EARNING_EXPENSE = 0;
                System.Int32 ERROR_NUM = 0;
                System.String strErr = System.String.Empty;
                System.Int32 iCurrentIndex = 0;
                System.Int32 iAllObjectCount = objEarningList.Count;
                System.Int32 iRet = 0;


                foreach (CEarning objEarning in objEarningList)
                {
                    iCurrentIndex++;

                    FINDED_MONEY = 0;
                    EARNINGFINDED_MONEY = 0;

                    DOC_ID = 0;
                    DOC_NUM = System.String.Empty;
                    DOC_DATE = System.DateTime.MinValue;
                    DOC_SALDO = 0;
                    EARNING_SALDO = objEarning.Saldo;
                    EARNING_EXPENSE = objEarning.Expense;
                    ERROR_NUM = 0;
                    strErr = System.String.Empty;
                    iRet = 0;

                    if ((EARNING_SALDO > 0) && (objEarning.Company != null) && (objEarning.Customer != null) && ( objEarning.IsTransitEarning == false ) )
                    {
                        List<CDebitDocument> objDebitDocumentList = CPaymentDataBaseModel.GetDebitDocumentFormPay1List(m_objProfile, null, 
                            objEarning.Company.ID, objEarning.Customer.ID, ref strErr);
                        if ((objDebitDocumentList != null) && (objDebitDocumentList.Count > 0))
                        {
                            // выводится информация о платеже и задолженности клиента
                            Thread.Sleep(1000);
                            this.Invoke(m_SetInfoInSearchProcessWoringDelegate, new Object[] { iCurrentIndex, iAllObjectCount, objEarning.Saldo, objEarning.CustomerName, 
                                         objDebitDocumentList.Sum<CDebitDocument>(x=>x.Waybill_Saldo) });

                            foreach (CDebitDocument objDebitDocument in objDebitDocumentList)
                            {
                                FINDED_MONEY = 0;
                                DOC_ID = objDebitDocument.Waybill_Id;
                                DOC_NUM = System.String.Empty;
                                DOC_DATE = System.DateTime.MinValue;
                                DOC_SALDO = 0;
                                ERROR_NUM = 0;
                                strErr = System.String.Empty;

                                if ((EARNING_SALDO > 0) && (objDebitDocument.Waybill_Saldo < 0))
                                {
                                    // оплата накладной
                                    iRet = CPaymentDataBaseModel.PayDebitDocumentForm1(m_objProfile, null,
                                        objEarning.ID, objDebitDocument.Waybill_Id, ref FINDED_MONEY,
                                        ref DOC_NUM, ref DOC_DATE, ref DOC_SALDO, ref EARNING_SALDO, ref EARNING_EXPENSE, ref ERROR_NUM, ref strErr);

                                    ALLFINDED_MONEY += (FINDED_MONEY);
                                    EARNINGFINDED_MONEY += (FINDED_MONEY);

                                    objEarning.Expense = EARNING_EXPENSE;
                                    objEarning.Saldo = EARNING_SALDO;

                                    // добавялется запись в журнал оплаченных ТТН 
                                    Thread.Sleep(1000);
                                    this.Invoke(m_SetResultAutoPayDebitDocumentListDelegate, new Object[] { ERROR_NUM, strErr, objEarning.CustomerName,
                                    FINDED_MONEY, ALLFINDED_MONEY, DOC_ID, DOC_NUM, DOC_DATE, objDebitDocument.Waybill_TotalPrice, DOC_SALDO,
                                    false});

                                }
                                else { break; }
                            }

                        }
                    }

                    if (iCurrentIndex == iAllObjectCount)
                    {
                        // все платежи обработаны, выводится сообщение о завершении процесса 
                        System.String strTmp = System.String.Empty;
                        System.DateTime dtTmp = System.DateTime.Today;
                        System.Int32 intTmp = 0;
                        System.Decimal dcmlTmp = 0;

                        Thread.Sleep(2000);
                        this.Invoke(m_SetResultAutoPayDebitDocumentListDelegate, new Object[] { intTmp, strTmp, strTmp, 
                            dcmlTmp, ALLFINDED_MONEY, intTmp,  strTmp, dtTmp, dcmlTmp, dcmlTmp,
                            true});
                    }


                }


            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка оплаты. Текст ошибки: " + f.Message);
            }

            return;
        }

        public void SetInfoInSearchProcessWoring(System.Int32 iCurrentIndex, System.Int32 iAllObjectCount, 
            System.Decimal EARNING_VALUE, System.String CUSTOMER_NAME, System.Decimal DEBIT_ALLVALUE
            )
        {
            try
            {
                if (SearchProcessWoring.Visible == false) { SearchProcessWoring.Visible = true; }
                
                SendMessageToLog(System.String.Format("Обрабатывается запись №{0:### ### ##0}  из {1:### ### ##0}", iCurrentIndex, iAllObjectCount));
                SendMessageToLog(System.String.Format("Остаток платежа:\t{0:### ### ##0.00}\t  Клиент: {1}\t  Задолженность: {2:### ### ##0.00}", EARNING_VALUE, CUSTOMER_NAME, DEBIT_ALLVALUE));
                
                labelControl10.Text = System.String.Format("Сумма платежа:\t{0:### ### ##0.00}\t  Клиент: {1}\t  Задолженность:\t{2:### ### ##0.00}", EARNING_VALUE, CUSTOMER_NAME, DEBIT_ALLVALUE);
                labelControl10.Refresh();
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("SetInfoInSearchProcessWoring.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally
            {
            }
            return;
        }

        public void SetResultAutoPayDebitDocumentList(System.Int32 ERROR_NUM, System.String ERROR_STR, 
            System.String CUSTOMER_NAME,    System.Decimal FINDED_MONEY, System.Decimal ALLFINDED_MONEY, System.Int32 DOC_ID,
            System.String DOC_NUM, System.DateTime DOC_DATE, System.Decimal DOC_TOTALPRICE, System.Decimal DOC_SALDO,
            System.Boolean bLastPayment
            )
        {
            try
            {
                if (bLastPayment == true)
                {
                    Cursor = Cursors.Default;

                    SearchProcessWoring.Visible = false;
                    gridControlEarningList.RefreshDataSource();

                    gridControlAutoPaidDocList.DataSource = m_objResultAutoPaid;

                    tabControl.SelectedTabPage = tabPageAutoPaidDocList;

                    DevExpress.XtraEditors.XtraMessageBox.Show(System.String.Format("Автоматическая оплата задолженности завершена.\nИтоговая сумма оплаты по накладным: {0:### ### ##0}", ALLFINDED_MONEY), "Внимание!",
                        System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Information);
                }
                else
                {
                    if (ERROR_NUM == 0)
                    {
                        if (FINDED_MONEY > 0)
                        {
                            CDebitDocument objItem = m_objResultAutoPaid.SingleOrDefault<CDebitDocument>(x => x.Waybill_Id == DOC_ID);

                            if (objItem != null)
                            {
                                objItem.Waybill_AmountPaid += FINDED_MONEY;
                                objItem.Waybill_Saldo = DOC_SALDO;
                            }
                            else
                            {
                                m_objResultAutoPaid.Add(new CDebitDocument()
                                {
                                    Customer_Name = CUSTOMER_NAME,
                                    Waybill_Id = DOC_ID,
                                    Waybill_Num = DOC_NUM,
                                    Waybill_BeginDate = DOC_DATE,
                                    Waybill_TotalPrice = DOC_TOTALPRICE,
                                    Waybill_AmountPaid = FINDED_MONEY,
                                    Waybill_Saldo = DOC_SALDO
                                });
                            }

                            gridControlEarningList.RefreshDataSource();
                        }
                    }
                    else
                    {
                        SendMessageToLog(ERROR_STR);
                    }

                }
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("SetResultAutoPayDebitDocumentList.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally
            {
            }
            return;
        }

        private void simpleButton2_Click(object sender, EventArgs e)
        {
            try
            {
                tabControl.SelectedTabPage = tabPageViewer;
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка отмены изменений. Текст ошибки: " + f.Message);
            }
            finally
            {
            }

            return;
        }

        private void simpleButton1_Click(object sender, EventArgs e)
        {
            StartThreadAutoPayDebitDocumentList();
        }

        /// <summary>
        /// Экспорт журнала оплаченных документов в MS Excel
        /// </summary>
        /// <param name="strFileName">имя файла MS Excel</param>
        private void ExportToExcelAutoPaidDocumentList(string strFileName)
        {
            try
            {
                this.Cursor = Cursors.WaitCursor;

                System.IO.FileInfo newFile = new System.IO.FileInfo(strFileName);
                if (newFile.Exists)
                {
                    newFile.Delete();
                    newFile = new System.IO.FileInfo(strFileName);
                }

                using (ExcelPackage package = new ExcelPackage(newFile))
                {
                    ExcelWorksheet worksheet = package.Workbook.Worksheets.Add(this.Text);

                    foreach (DevExpress.XtraGrid.Columns.GridColumn objColumn in gridViewAutoPaidDocList.Columns)
                    {
                        if (objColumn.Visible == false) { continue; }

                        worksheet.Cells[1, objColumn.VisibleIndex + 1].Value = objColumn.Caption;
                    }

                    using (var range = worksheet.Cells[1, 1, 1, gridViewAutoPaidDocList.Columns.Count])
                    {
                        range.Style.Font.Bold = true;
                        range.Style.Font.Size = 14;
                    }

                    System.Int32 iCurrentRow = 2;
                    System.Int32 iRowsCount = gridViewAutoPaidDocList.RowCount;
                    for (System.Int32 i = 0; i < iRowsCount; i++)
                    {
                        foreach (DevExpress.XtraGrid.Columns.GridColumn objColumn in gridViewAutoPaidDocList.Columns)
                        {
                            if (objColumn.Visible == false) { continue; }

                            worksheet.Cells[iCurrentRow, objColumn.VisibleIndex + 1].Value = gridViewAutoPaidDocList.GetRowCellValue(i, objColumn);
                            if ((objColumn.FieldName == "Waybill_BeginDate") || (objColumn.FieldName == "strWaybill_ShipDate"))
                            {
                                worksheet.Cells[iCurrentRow, objColumn.VisibleIndex + 1].Style.Numberformat.Format = "DD.MM.YYYY";
                            }
                            if ((objColumn.FieldName == "Waybill_AllPrice") || (objColumn.FieldName == "Waybill_TotalPrice") ||
                                (objColumn.FieldName == "Waybill_RetAllPrice") || (objColumn.FieldName == "Waybill_AmountPaid") ||
                                (objColumn.FieldName == "Waybill_Saldo"))
                            {
                                worksheet.Cells[iCurrentRow, objColumn.VisibleIndex + 1].Style.Numberformat.Format = "# ### ### ##0.00";
                            }
                        }
                        iCurrentRow++;
                    }

                    iCurrentRow--;
                    worksheet.Cells[1, 1, iCurrentRow, gridViewPaidDocumentList.Columns.Count].AutoFitColumns(0);
                    worksheet.Cells[1, 1, iCurrentRow, gridViewPaidDocumentList.Columns.Count].Style.Border.Top.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    worksheet.Cells[1, 1, iCurrentRow, gridViewPaidDocumentList.Columns.Count].Style.Border.Left.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    worksheet.Cells[1, 1, iCurrentRow, gridViewPaidDocumentList.Columns.Count].Style.Border.Right.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    worksheet.Cells[1, 1, iCurrentRow, gridViewPaidDocumentList.Columns.Count].Style.Border.Bottom.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;

                    worksheet.PrinterSettings.FitToWidth = 1;

                    worksheet = null;

                    package.Save();

                    try
                    {
                        using (System.Diagnostics.Process process = new System.Diagnostics.Process())
                        {
                            process.StartInfo.FileName = strFileName;
                            process.StartInfo.Verb = "Open";
                            process.StartInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Normal;
                            process.Start();
                        }
                    }
                    catch
                    {
                        DevExpress.XtraEditors.XtraMessageBox.Show(this, "Системе не удалось найти приложение, чтобы открыть файл.", Application.ProductName, MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }

                }

            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show(
                    "Ошибка экспорта в MS Excel.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally
            {
                this.Cursor = System.Windows.Forms.Cursors.Default;
            }
        }

        private void btnPrintAutoPaidDocList_Click(object sender, EventArgs e)
        {
            try
            {
                ExportToExcelAutoPaidDocumentList(String.Format("{0}{1}.xlsx", System.IO.Path.GetTempPath(), (String.Format("{0} журнал автоматически оплаченных накладных", this.Text))));
            }
            catch (System.Exception f)
            {
                SendMessageToLog("btnPrintPaidDocument_Click. Текст ошибки: " + f.Message);
            }

            return;
        }

        #endregion

        #region Журнал разноски платежей

        private void ViewEarningHistory(CEarning objEarning)
        {
            if (objEarning == null) { return; }
            m_bDisableEvents = true;
            m_bNewObject = false;
            try
            {
                m_objSelectedEarning = objEarning;

                txtEarningDocEarningHistory.Text = "";
                txtEarningDateEarningHistory.Text = "";
                txtEarningBankCodeEarningHistory.Text = "";
                txtEarningAccountNumberEarningHistory.Text = "";
                calcEarningValueEarningHistory.Value = 0;
                calcEarningSaldoEarningHistory.Value = 0;
                calcEarningExpenseEarningHistory.Value = 0;

                txtEarningPayerEarningHistory.Text = "";
                txtPayerDescrpnEarningHistory.Text = "";
                txtEarningDetailEarningHistory.Text = "";

                if (objEarning != null)
                {
                    txtEarningDocEarningHistory.Text = objEarning.DocNom;
                    txtEarningDateEarningHistory.Text = objEarning.Date.ToShortDateString();
                    txtEarningBankCodeEarningHistory.Text = objEarning.CodeBank;
                    txtEarningAccountNumberEarningHistory.Text = objEarning.AccountNumber;
                    calcEarningValueEarningHistory.Value = System.Convert.ToDecimal(objEarning.Value);
                    calcEarningSaldoEarningHistory.Value = System.Convert.ToDecimal(objEarning.Saldo);
                    calcEarningExpenseEarningHistory.Value = System.Convert.ToDecimal(objEarning.Expense);
                    txtEarningPayerEarningHistory.Text = objEarning.CustomerName;
                    txtPayerDescrpnEarningHistory.Text = objEarning.CustomrText;
                    txtEarningDetailEarningHistory.Text = objEarning.DetailsPayment;
                }

                lblEarningInfoInEarningHistory.Text = strWaitCustomer;
                lblCaptionEarningHistoryList.Text = "История разноски платежа по долгам";
                if (m_objSelectedEarning.Company != null)
                {
                    lblCaptionEarningHistoryList.Text += (String.Format("\t\tкомпания: {0}", m_objSelectedEarning.Company.Name));
                }

                if (m_objSelectedEarning.Customer != null)
                {
                    lblCaptionEarningHistoryList.Text += (String.Format("\tклиент: {0}", m_objSelectedEarning.Customer.FullName));
                }

                pictureBoxInfoInEarningHistoryList.Image = ERPMercuryBankStatement.Properties.Resources.Warning_32;

                StartThreadLoadEarningHistoryList();

            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка загрузки журнала разноски платежей. Текст ошибки: " + f.Message);
            }
            finally
            {
                tabControl.SelectedTabPage = tabPageEarningHistory;
                tabPageEarningHistory.Refresh();
            }
            return;
        }

        private void btnCancelViewEarningHistory_Click(object sender, EventArgs e)
        {
            try
            {
                tabControl.SelectedTabPage = tabPageViewer;
                if (m_objSelectedEarning != null)
                {
                    System.Int32 iIndxSelectedObject = m_objEarningList.IndexOf(m_objEarningList.SingleOrDefault<CEarning>(x => x.ID.CompareTo(m_objSelectedEarning.ID) == 0));
                    if (iIndxSelectedObject >= 0)
                    {
                        gridViewEarningList.FocusedRowHandle = gridViewEarningList.GetRowHandle(iIndxSelectedObject);
                    }
                }
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Текст ошибки: " + f.Message);
            }
            finally
            {
            }

            return;
        }

        /// <summary>
        /// Экспорт журнала разноски оплат в MS Excel
        /// </summary>
        /// <param name="strFileName">имя файла MS Excel</param>
        private void ExportToExcelEarningHistoryList(string strFileName)
        {
            try
            {
                this.Cursor = Cursors.WaitCursor;

                System.IO.FileInfo newFile = new System.IO.FileInfo(strFileName);
                if (newFile.Exists)
                {
                    newFile.Delete();
                    newFile = new System.IO.FileInfo(strFileName);
                }

                using (ExcelPackage package = new ExcelPackage(newFile))
                {
                    ExcelWorksheet worksheet = package.Workbook.Worksheets.Add(this.Text);

                    foreach (DevExpress.XtraGrid.Columns.GridColumn objColumn in gridViewEarningHistoryList.Columns)
                    {
                        if (objColumn.Visible == false) { continue; }

                        worksheet.Cells[1, objColumn.VisibleIndex + 1].Value = objColumn.Caption;
                    }

                    using (var range = worksheet.Cells[1, 1, 1, gridViewEarningHistoryList.Columns.Count])
                    {
                        range.Style.Font.Bold = true;
                        range.Style.Font.Size = 14;
                        //range.Style.Fill.PatternType = OfficeOpenXml.Style.ExcelFillStyle.Solid;
                        //range.Style.Fill.BackgroundColor.SetColor(Color.DarkBlue);
                        //range.Style.Font.Color.SetColor(Color.White);
                    }

                    System.Int32 iCurrentRow = 2;
                    System.Int32 iRowsCount = gridViewEarningHistoryList.RowCount;
                    for (System.Int32 i = 0; i < iRowsCount; i++)
                    {
                        foreach (DevExpress.XtraGrid.Columns.GridColumn objColumn in gridViewEarningHistoryList.Columns)
                        {
                            if (objColumn.Visible == false) { continue; }

                            worksheet.Cells[iCurrentRow, objColumn.VisibleIndex + 1].Value = gridViewEarningHistoryList.GetRowCellValue(i, objColumn);
                            if( (objColumn.FieldName == "Waybill_ShipDate") || (objColumn.FieldName == "Payment_OperDate") || 
                                (objColumn.FieldName == "Earning_BankDate") )
                            {
                                worksheet.Cells[iCurrentRow, objColumn.VisibleIndex + 1].Style.Numberformat.Format = "DD.MM.YYYY";
                            }
                        }
                        iCurrentRow++;
                    }

                    iCurrentRow--;
                    worksheet.Cells[1, 1, iCurrentRow, gridViewEarningHistoryList.Columns.Count].AutoFitColumns(0);
                    worksheet.Cells[1, 1, iCurrentRow, gridViewEarningHistoryList.Columns.Count].Style.Border.Top.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    worksheet.Cells[1, 1, iCurrentRow, gridViewEarningHistoryList.Columns.Count].Style.Border.Left.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    worksheet.Cells[1, 1, iCurrentRow, gridViewEarningHistoryList.Columns.Count].Style.Border.Right.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    worksheet.Cells[1, 1, iCurrentRow, gridViewEarningHistoryList.Columns.Count].Style.Border.Bottom.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;

                    worksheet.PrinterSettings.FitToWidth = 1;

                    worksheet = null;

                    package.Save();

                    try
                    {
                        using (System.Diagnostics.Process process = new System.Diagnostics.Process())
                        {
                            process.StartInfo.FileName = strFileName;
                            process.StartInfo.Verb = "Open";
                            process.StartInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Normal;
                            process.Start();
                        }
                    }
                    catch
                    {
                        DevExpress.XtraEditors.XtraMessageBox.Show(this, "Системе не удалось найти приложение, чтобы открыть файл.", Application.ProductName, MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }

                }

            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show(
                    "Ошибка экспорта в MS Excel.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally
            {
                this.Cursor = System.Windows.Forms.Cursors.Default;
            }
        }

        private void btnPrintEarningHistory_Click(object sender, EventArgs e)
        {
            try
            {
                ExportToExcelEarningHistoryList(String.Format("{0}{1}.xlsx", System.IO.Path.GetTempPath(), (String.Format("{0} журнал разноски оплат", this.Text))));
            }
            catch (System.Exception f)
            {
                SendMessageToLog("btnPrint_Click. Текст ошибки: " + f.Message);
            }

            return;
        }

        private void barBtnEarningHistoryView_Click(object sender, EventArgs e)
        {
            try
            {
                ViewEarningHistory(SelectedEarning);
            }
            catch (System.Exception f)
            {
                SendMessageToLog("barBtnEarningHistoryView_Click. Текст ошибки: " + f.Message);
            }

            return;
        }

        #endregion

        #region Сторно
        /// <summary>
        /// Возвращает ссылку на выбранный в списке оплаченный документ
        /// </summary>
        /// <returns>ссылка на оплаченный документ</returns>
        private CPaidDocument SelectedPaidDocument
        {
            get
            {
                CPaidDocument objRet = null;
                try
                {
                    if ((((DevExpress.XtraGrid.Views.Grid.GridView)gridControlPaidDocumentList.MainView).RowCount > 0) &&
                        (((DevExpress.XtraGrid.Views.Grid.GridView)gridControlPaidDocumentList.MainView).FocusedRowHandle >= 0))
                    {
                        System.Int32 idID = (System.Int32)(((DevExpress.XtraGrid.Views.Grid.GridView)gridControlPaidDocumentList.MainView)).GetFocusedRowCellValue("Waybill_Id");

                        objRet = m_objPaidDocumentList.SingleOrDefault<CPaidDocument>(x => x.Waybill_Id.CompareTo(idID) == 0);
                    }
                }//try
                catch (System.Exception f)
                {
                    SendMessageToLog("Ошибка поиска оплаченного документа. Текст ошибки: " + f.Message);
                }
                finally
                {
                }

                return objRet;
            }
        }
        private void calcDePaySum_EditValueChanging(object sender, DevExpress.XtraEditors.Controls.ChangingEventArgs e)
        {
            try
            {
                CPaidDocument objItem = SelectedPaidDocument;
                if ((objItem == null) || ((e.NewValue != null) && (System.Convert.ToDecimal(e.NewValue) > objItem.Waybill_AmountPaid)))
                {
                    e.Cancel = true;
                }
            }
            catch (System.Exception f)
            {
                SendMessageToLog("calcDePaySum_EditValueChanging. Текст ошибки: " + f.Message);
            }

            return;
        }

        private void LoadInfoForDePayOperation(CPaidDocument objPaidDocument)
        {
            try
            {
                calcDePaySum.Value = 0;
                dateDePayDate.EditValue = null;
                btnDePayPaidDocument.Enabled = false;

                if (objPaidDocument == null) { return; }
                if (objPaidDocument.Waybill_AmountPaid == 0)
                {
                    return;
                }

                calcDePaySum.Value = System.Convert.ToDecimal(objPaidDocument.Waybill_AmountPaid);
                dateDePayDate.DateTime = System.DateTime.Today;
                btnDePayPaidDocument.Enabled = (calcDePaySum.Value > 0);
            }
            catch (System.Exception f)
            {
                SendMessageToLog("LoadInfoForDePayOperation. Текст ошибки: " + f.Message);
            }

            return;
        }
        private void btnDePayPaidDocument_Click(object sender, EventArgs e)
        {
            try
            {
                DePayPaidDocument(SelectedPaidDocument);
            }
            catch (System.Exception f)
            {
                SendMessageToLog("btnDePayPaidDocument_Click. Текст ошибки: " + f.Message);
            }

            return;
        }

        private void DePayPaidDocument(CPaidDocument objPaidDocument)
        {
            try
            {
                if (objPaidDocument == null)
                {
                    DevExpress.XtraEditors.XtraMessageBox.Show("Программе не удалось определить документ для сторно оплаты.", "Внимание!",
                        System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Warning);

                    return;
                }

                if( objPaidDocument.Waybill_AmountPaid == 0)
                {
                    DevExpress.XtraEditors.XtraMessageBox.Show("Оплата по документу полностью отсторирована.", "Внимание!",
                        System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Information);

                    return;
                }

                System.Int32 Waybill_Id = objPaidDocument.Waybill_Id;
                System.Decimal AMOUNT = calcDePaySum.Value;
                System.DateTime DATELASTPAID = dateDePayDate.DateTime;
                System.Decimal DEC_AMOUNT = 0;
                System.Decimal WAYBILL_AMOUNTPAID = 0;
                System.Decimal WAYBILL_SALDO = 0;

                System.Int32 ERROR_NUM = 0;
                System.String strErr = System.String.Empty;

                System.Int32 iRet = CPaymentDataBaseModel.DePayDebitDocumentForm1(m_objProfile, null,
                    System.Guid.Empty, Waybill_Id, AMOUNT, DATELASTPAID, 
                    ref DEC_AMOUNT,  ref WAYBILL_AMOUNTPAID, ref WAYBILL_SALDO,
                    ref ERROR_NUM, ref strErr);
                if ((iRet == 0) && (ERROR_NUM == 0))
                {
                    CPaidDocument objItem = m_objPaidDocumentList.SingleOrDefault<CPaidDocument>(x => x.Waybill_Id.Equals(objPaidDocument.Waybill_Id));
                    if (objItem != null)
                    {
                        objItem.Waybill_AmountPaid = WAYBILL_AMOUNTPAID;
                        objItem.Waybill_Saldo = WAYBILL_SALDO;
                        if (objItem.Waybill_AmountPaid == 0) 
                        {
                            m_objPaidDocumentList.Remove(objItem); 
                        }

                        LoadInfoForDePayOperation(objItem);

                        gridControlPaidDocumentList.RefreshDataSource();
                        SendMessageToLog(System.String.Format("Произведено сторно. Сумма: {0:### ### ##0}  Документ № {1}  от {2}  Задолженность по документу: {3:### ### ##0.00}", DEC_AMOUNT, objItem.Waybill_Num, objItem.Waybill_BeginDate.ToShortDateString(), WAYBILL_SALDO));

                        DevExpress.XtraEditors.XtraMessageBox.Show(System.String.Format("Произведено сторно. Сумма: {0:### ### ##0}  \nДокумент № {1}  от {2}  \nЗадолженность по документу: {3:### ### ##0.00}", DEC_AMOUNT, objItem.Waybill_Num, objItem.Waybill_BeginDate.ToShortDateString(), WAYBILL_SALDO), "Внимание!",
                            System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Information);

                        return;
                    }
                }
                else
                {
                    DevExpress.XtraEditors.XtraMessageBox.Show(strErr, "Внимание!",
                        System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
                }

            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка операции Сторно. Текст ошибки: " + f.Message);
            }

            return;
        }

        private void btnRefreshPaidDocumentList_Click(object sender, EventArgs e)
        {
            try
            {
                StartThreadLoadPaidDocumentList();
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("btnRefreshPaidDocumentList_Click.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally
            {
            }
            return;
        }
        private void dtBeginDatePaidDocument_KeyPress(object sender, KeyPressEventArgs e)
        {
            try
            {
                if ((e.KeyChar == (char)Keys.Enter) && (barBtnRefresh.Visible == true))
                {
                    StartThreadLoadPaidDocumentList();
                }
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("dtBeginDatePaidDocument_KeyPress.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally
            {
            }
            return;
        }
        private void ViewPaidDocumentList()
        {
            try
            {
                tabControl.SelectedTabPage = tabPagePaidDocList;
                tabPagePaidDocList.Refresh();

                LoadInfoForDePayOperation(SelectedPaidDocument);
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка загрузки журнала оплаченных документов. Текст ошибки: " + f.Message);
            }
            finally
            {
            }
            return;
        }
        private void gridViewPaidDocumentList_FocusedRowChanged(object sender, DevExpress.XtraGrid.Views.Base.FocusedRowChangedEventArgs e)
        {
            LoadInfoForDePayOperation(SelectedPaidDocument);
        }

        private void gridViewPaidDocumentList_RowCountChanged(object sender, EventArgs e)
        {
            LoadInfoForDePayOperation(SelectedPaidDocument);
        }
        private void barBtnPaidDocumentList_Click(object sender, EventArgs e)
        {
            try
            {
                ViewPaidDocumentList();
            }
            catch (System.Exception f)
            {
                SendMessageToLog("barBtnPaidDocumentList_Click. Текст ошибки: " + f.Message);
            }

            return;
        }

        private void btnClosePaidDocument_Click(object sender, EventArgs e)
        {
            try
            {
                tabControl.SelectedTabPage = tabPageViewer;
                if (m_objSelectedEarning != null)
                {
                    System.Int32 iIndxSelectedObject = m_objEarningList.IndexOf(m_objEarningList.SingleOrDefault<CEarning>(x => x.ID.CompareTo(m_objSelectedEarning.ID) == 0));
                    if (iIndxSelectedObject >= 0)
                    {
                        gridViewEarningList.FocusedRowHandle = gridViewEarningList.GetRowHandle(iIndxSelectedObject);
                    }
                }
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Текст ошибки: " + f.Message);
            }
            finally
            {
            }

            return;
        }
        /// <summary>
        /// Экспорт журнала оплаченных документов в MS Excel
        /// </summary>
        /// <param name="strFileName">имя файла MS Excel</param>
        private void ExportToExcelPaidDocumentList(string strFileName)
        {
            try
            {
                this.Cursor = Cursors.WaitCursor;

                System.IO.FileInfo newFile = new System.IO.FileInfo(strFileName);
                if (newFile.Exists)
                {
                    newFile.Delete();
                    newFile = new System.IO.FileInfo(strFileName);
                }

                using (ExcelPackage package = new ExcelPackage(newFile))
                {
                    ExcelWorksheet worksheet = package.Workbook.Worksheets.Add(this.Text);

                    foreach (DevExpress.XtraGrid.Columns.GridColumn objColumn in gridViewPaidDocumentList.Columns)
                    {
                        if (objColumn.Visible == false) { continue; }

                        worksheet.Cells[1, objColumn.VisibleIndex + 1].Value = objColumn.Caption;
                    }

                    using (var range = worksheet.Cells[1, 1, 1, gridViewPaidDocumentList.Columns.Count])
                    {
                        range.Style.Font.Bold = true;
                        range.Style.Font.Size = 14;
                    }

                    System.Int32 iCurrentRow = 2;
                    System.Int32 iRowsCount = gridViewPaidDocumentList.RowCount;
                    for (System.Int32 i = 0; i < iRowsCount; i++)
                    {
                        foreach (DevExpress.XtraGrid.Columns.GridColumn objColumn in gridViewPaidDocumentList.Columns)
                        {
                            if (objColumn.Visible == false) { continue; }

                            worksheet.Cells[iCurrentRow, objColumn.VisibleIndex + 1].Value = gridViewPaidDocumentList.GetRowCellValue(i, objColumn);
                            if ((objColumn.FieldName == "Waybill_BeginDate") || (objColumn.FieldName == "strWaybill_ShipDate"))
                            {
                                worksheet.Cells[iCurrentRow, objColumn.VisibleIndex + 1].Style.Numberformat.Format = "DD.MM.YYYY";
                            }
                            if ((objColumn.FieldName == "Waybill_AllPrice") || (objColumn.FieldName == "Waybill_TotalPrice") ||
                                (objColumn.FieldName == "Waybill_RetAllPrice") || (objColumn.FieldName == "Waybill_AmountPaid") ||
                                (objColumn.FieldName == "Waybill_Saldo"))
                            {
                                worksheet.Cells[iCurrentRow, objColumn.VisibleIndex + 1].Style.Numberformat.Format = "# ### ### ##0.00";
                            }
                        }
                        iCurrentRow++;
                    }

                    iCurrentRow--;
                    worksheet.Cells[1, 1, iCurrentRow, gridViewPaidDocumentList.Columns.Count].AutoFitColumns(0);
                    worksheet.Cells[1, 1, iCurrentRow, gridViewPaidDocumentList.Columns.Count].Style.Border.Top.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    worksheet.Cells[1, 1, iCurrentRow, gridViewPaidDocumentList.Columns.Count].Style.Border.Left.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    worksheet.Cells[1, 1, iCurrentRow, gridViewPaidDocumentList.Columns.Count].Style.Border.Right.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    worksheet.Cells[1, 1, iCurrentRow, gridViewPaidDocumentList.Columns.Count].Style.Border.Bottom.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;

                    worksheet.PrinterSettings.FitToWidth = 1;

                    worksheet = null;

                    package.Save();

                    try
                    {
                        using (System.Diagnostics.Process process = new System.Diagnostics.Process())
                        {
                            process.StartInfo.FileName = strFileName;
                            process.StartInfo.Verb = "Open";
                            process.StartInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Normal;
                            process.Start();
                        }
                    }
                    catch
                    {
                        DevExpress.XtraEditors.XtraMessageBox.Show(this, "Системе не удалось найти приложение, чтобы открыть файл.", Application.ProductName, MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }

                }

            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show(
                    "Ошибка экспорта в MS Excel.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally
            {
                this.Cursor = System.Windows.Forms.Cursors.Default;
            }
        }
        private void btnPrintPaidDocument_Click(object sender, EventArgs e)
        {
            try
            {
                ExportToExcelPaidDocumentList(String.Format("{0}{1}.xlsx", System.IO.Path.GetTempPath(), (String.Format("{0} журнал оплаченных накладных", this.Text))));
            }
            catch (System.Exception f)
            {
                SendMessageToLog("btnPrintPaidDocument_Click. Текст ошибки: " + f.Message);
            }

            return;
        }

        #endregion

        #region Навигация в редакторе платежа
        private void editorEarningValue_KeyPress(object sender, KeyPressEventArgs e)
        {
            if( ( m_bIsChanged == true ) &&  (e.KeyChar == (char)Keys.Return))
            {
                e.Handled = true;
                editorEarningDate.Focus();
            }
        }
        private void editorEarningDate_KeyPress(object sender, KeyPressEventArgs e)
        {
            if ((m_bIsChanged == true) && (e.KeyChar == (char)Keys.Return))
            {
                e.Handled = true;
                editorEarningDocNum.Focus();
            }
        }
        private void editorEarningDocNum_KeyPress(object sender, KeyPressEventArgs e)
        {
            if ((m_bIsChanged == true) && (e.KeyChar == (char)Keys.Return))
            {
                e.Handled = true;
                editorEarningCustomer.Focus();
            }
        }
        private void editorEarningCustomer_KeyPress(object sender, KeyPressEventArgs e)
        {
            if ((m_bIsChanged == true) && (e.KeyChar == (char)Keys.Return))
            {
                e.Handled = true;
                btnSave.Focus();
                //editorEarningpayerDetail.Focus();
            }
        }
        private void editorEarningpayerDetail_KeyPress(object sender, KeyPressEventArgs e)
        {
            if ((m_bIsChanged == true) && (e.KeyChar == (char)Keys.Return))
            {
                e.Handled = true;
                editorEarningAccount.Focus();
            }
        }
        private void editorEarningAccount_KeyPress(object sender, KeyPressEventArgs e)
        {
            if ((m_bIsChanged == true) && (e.KeyChar == (char)Keys.Return))
            {
                e.Handled = true;
                editorEarningDetail.Focus();
            }
        }
        private void editorEarningDetail_KeyPress(object sender, KeyPressEventArgs e)
        {
            if ((m_bIsChanged == true) && (e.KeyChar == (char)Keys.Return))
            {
                e.Handled = true;
                btnSave.Focus();
            }
        }
        #endregion

        #region Возврат средств клиенту
        private void editorEarningSaldo_EditValueChanged(object sender, EventArgs e)
        {
            calcEditMoneyToReturn.Value = editorEarningSaldo.Value;
        }
        private void calcEditMoneyToreturn_EditValueChanging(object sender, DevExpress.XtraEditors.Controls.ChangingEventArgs e)
        {
            try
            {
                CEarning objItem = m_objSelectedEarning;
                if ((objItem == null) || ((e.NewValue != null) && (System.Convert.ToDecimal(e.NewValue) > editorEarningSaldo.Value)))
                {
                    e.Cancel = true;
                }
            }
            catch (System.Exception f)
            {
                SendMessageToLog("calcEditMoneyToreturn_EditValueChanging. Текст ошибки: " + f.Message);
            }

            return;
        }
        /// <summary>
        /// Возврат средств клиенту
        /// </summary>
        /// <param name="objEarning">Платёж</param>
        /// <param name="OPERATION_MONEY">Сумма возврата</param>
        /// <param name="OPERATION_DATE">Дата операции</param>
        private void ReturnMoneyToCustomer(CEarning objEarning, System.Decimal OPERATION_MONEY, System.DateTime OPERATION_DATE)
        {
            try
            {
                if( (objEarning == null) || (objEarning.ID.CompareTo( System.Guid.Empty ) == 0) )
                {
                    DevExpress.XtraEditors.XtraMessageBox.Show("Программе не удалось определить платёж для операции возврата средств клиенту.", "Внимание!",
                        System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Warning);

                    return;
                }

                if ((objEarning.Customer == null) || (objEarning.Customer.ID.CompareTo( System.Guid.Empty ) == 0))
                {
                    DevExpress.XtraEditors.XtraMessageBox.Show("Программе не удалось определить клиента для операции возврата средств.", "Внимание!",
                        System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Warning);

                    return;
                }

                if (OPERATION_MONEY == 0)
                {
                    DevExpress.XtraEditors.XtraMessageBox.Show("Сумма возврата должна быть блльше нуля и не превышать остаток платежа.", "Внимание!",
                        System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Information);

                    return;
                }

                System.Decimal WRITEOFF_MONEY = 0;
                System.Int32 ERROR_NUM = 0;
                System.String strErr = System.String.Empty;

                System.Int32 iRet = CPaymentDataBaseModel.WriteOffReturnMoneyToCustomerForm1(m_objProfile, null,
                    objEarning.ID,  OPERATION_MONEY,  OPERATION_DATE, ref  WRITEOFF_MONEY, ref ERROR_NUM, ref strErr);
                if ((iRet == 0) && (ERROR_NUM == 0))
                {

                    objEarning.Expense += (WRITEOFF_MONEY);
                    objEarning.Saldo = (objEarning.Value - objEarning.Expense );
                    editorEarningSaldo.Value = objEarning.Saldo;

                    gridControlEarningList.RefreshDataSource();

                    SendMessageToLog(System.String.Format("Произведен возврат средств клиенту. Сумма возврата: {0:### ### ##0.00}  Клиент: {1}", WRITEOFF_MONEY, objEarning.Customer.FullName ) );

                    DevExpress.XtraEditors.XtraMessageBox.Show(System.String.Format("Произведен возврат средств клиенту. Сумма возврата: {0:### ### ##0.00}  \nКлиент: {1}", WRITEOFF_MONEY, objEarning.Customer.FullName ), "Внимание!",
                        System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Information);
                    
                }
                else
                {
                    DevExpress.XtraEditors.XtraMessageBox.Show(strErr, "Внимание!",
                        System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
                }

            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка операции возврата средств клиенту. Текст ошибки: " + f.Message);
            }

            return;
        }

        private void btnReturnMoneyToCustomer_Click(object sender, EventArgs e)
        {
            try
            {
                if (m_bNewObject == true) { return; }
                if (editorEarningSaldo.Value == 0) { return; }
                if (calcEditMoneyToReturn.Value == 0) { return; }
                if (dateEditMoneyToReturnOperationDate.EditValue == null) { return; }
                if ((m_objSelectedEarning == null) || (m_objSelectedEarning.ID.CompareTo(System.Guid.Empty) == 0)) { return; }
                if ((m_objSelectedEarning.Customer == null) || (m_objSelectedEarning.Customer.ID.CompareTo(System.Guid.Empty) == 0)) { return; }


                System.Decimal OPERATION_MONEY = calcEditMoneyToReturn.Value;
                System.DateTime OPERATION_DATE = dateEditMoneyToReturnOperationDate.DateTime;

                if (DevExpress.XtraEditors.XtraMessageBox.Show(System.String.Format("Возврат средств  клиенту.\n\nСумма возврата: {0:### ### ##0}\nКлиент: {1}\n\nПодтвердите, пожалуйста, начало операции.", OPERATION_MONEY, m_objSelectedEarning.Customer.FullName), "Подтверждение",
                    System.Windows.Forms.MessageBoxButtons.YesNoCancel,
                    System.Windows.Forms.MessageBoxIcon.Question) == DialogResult.Yes)
                {
                    ReturnMoneyToCustomer( m_objSelectedEarning, OPERATION_MONEY, OPERATION_DATE );
                }


            }
            catch (System.Exception f)
            {
                SendMessageToLog("btnReturnMoneyToCustomer_Click. Текст ошибки: " + f.Message);
            }

            return;

        }

        #endregion

        #region Отчёт "Архив платежей"

        private void btnRefreshReportEarningArj_Click(object sender, EventArgs e)
        {
            try
            {
                StartThreadLoadReportEarningArjList();
            }
            catch (System.Exception f)
            {
                SendMessageToLog("btnRefreshReportEarningArj_Click. Текст ошибки: " + f.Message);
            }

            return;
        }
        private void dtBeginDateReportEarningArj_KeyPress(object sender, KeyPressEventArgs e)
        {
            try
            {
                if ((e.KeyChar == (char)Keys.Enter) && (btnRefreshReportEarningArj.Enabled == true))
                {
                    StartThreadLoadReportEarningArjList();
                }
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("dtBeginDateReportEarningArj_KeyPress.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally
            {
            }
            return;
        }
        private void ExportToExcelReportEarningArj(string strFileName)
        {
            try
            {
                this.Cursor = Cursors.WaitCursor;

                System.IO.FileInfo newFile = new System.IO.FileInfo(strFileName);
                if (newFile.Exists)
                {
                    newFile.Delete();
                    newFile = new System.IO.FileInfo(strFileName);
                }

                using (ExcelPackage package = new ExcelPackage(newFile))
                {
                    ExcelWorksheet worksheet = package.Workbook.Worksheets.Add(this.Text);

                    foreach (DevExpress.XtraGrid.Columns.GridColumn objColumn in gridViewReportEarningArj.Columns)
                    {
                        if (objColumn.Visible == false) { continue; }

                        worksheet.Cells[1, objColumn.VisibleIndex + 1].Value = objColumn.Caption;
                    }

                    using (var range = worksheet.Cells[1, 1, 1, gridViewReportEarningArj.Columns.Count])
                    {
                        range.Style.Font.Bold = true;
                        range.Style.Font.Size = 14;
                        //range.Style.Fill.PatternType = OfficeOpenXml.Style.ExcelFillStyle.Solid;
                        //range.Style.Fill.BackgroundColor.SetColor(Color.DarkBlue);
                        //range.Style.Font.Color.SetColor(Color.White);
                    }

                    System.Int32 iCurrentRow = 2;
                    System.Int32 iRowsCount = gridViewReportEarningArj.RowCount;
                    for (System.Int32 i = 0; i < iRowsCount; i++)
                    {
                        foreach (DevExpress.XtraGrid.Columns.GridColumn objColumn in gridViewReportEarningArj.Columns)
                        {
                            if (objColumn.Visible == false) { continue; }

                            worksheet.Cells[iCurrentRow, objColumn.VisibleIndex + 1].Value = gridViewReportEarningArj.GetRowCellValue(i, objColumn);
                            if(objColumn.FieldName == "Date")
                            {
                                worksheet.Cells[iCurrentRow, objColumn.VisibleIndex + 1].Style.Numberformat.Format = "DD.MM.YYYY";
                            }
                            if ((objColumn.FieldName == "Value") || (objColumn.FieldName == "Expense") || (objColumn.FieldName == "Saldo"))
                            {
                                worksheet.Cells[iCurrentRow, objColumn.VisibleIndex + 1].Style.Numberformat.Format = "# ### ### ##0.00";
                            }

                        }
                        iCurrentRow++;
                    }

                    iCurrentRow--;
                    worksheet.Cells[1, 1, iCurrentRow, gridViewReportEarningArj.Columns.Count].AutoFitColumns(0);
                    worksheet.Cells[1, 1, iCurrentRow, gridViewReportEarningArj.Columns.Count].Style.Border.Top.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    worksheet.Cells[1, 1, iCurrentRow, gridViewReportEarningArj.Columns.Count].Style.Border.Left.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    worksheet.Cells[1, 1, iCurrentRow, gridViewReportEarningArj.Columns.Count].Style.Border.Right.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    worksheet.Cells[1, 1, iCurrentRow, gridViewReportEarningArj.Columns.Count].Style.Border.Bottom.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;

                    worksheet.PrinterSettings.FitToWidth = 1;

                    worksheet = null;

                    package.Save();

                    try
                    {
                        using (System.Diagnostics.Process process = new System.Diagnostics.Process())
                        {
                            process.StartInfo.FileName = strFileName;
                            process.StartInfo.Verb = "Open";
                            process.StartInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Normal;
                            process.Start();
                        }
                    }
                    catch
                    {
                        DevExpress.XtraEditors.XtraMessageBox.Show(this, "Системе не удалось найти приложение, чтобы открыть файл.", Application.ProductName, MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }

                }

            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show(
                    "Ошибка экспорта в MS Excel.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally
            {
                this.Cursor = System.Windows.Forms.Cursors.Default;
            }
        }

        private void btnPrintReportEarningArj_Click(object sender, EventArgs e)
        {
            try
            {
                ExportToExcelReportEarningArj(String.Format("{0}{1}.xlsx", System.IO.Path.GetTempPath(), (String.Format("{0} архив платежей", this.Text))));
            }
            catch (System.Exception f)
            {
                SendMessageToLog("btnPrint_Click. Текст ошибки: " + f.Message);
            }

            return;
        }
        private void btnReportEarningArjreturnToEarningList_Click(object sender, EventArgs e)
        {
            try
            {
                tabControl.SelectedTabPage = tabPageViewer;
                if (m_objSelectedEarning != null)
                {
                    System.Int32 iIndxSelectedObject = m_objEarningList.IndexOf(m_objEarningList.SingleOrDefault<CEarning>(x => x.ID.CompareTo(m_objSelectedEarning.ID) == 0));
                    if (iIndxSelectedObject >= 0)
                    {
                        gridViewEarningList.FocusedRowHandle = gridViewEarningList.GetRowHandle(iIndxSelectedObject);
                    }
                }
            }
            catch (System.Exception f)
            {
                SendMessageToLog("btnReportEarningArjreturnToEarningList_Click. Текст ошибки: " + f.Message);
            }
            finally
            {
            }

            return;
        }
        private void btnReports_Click(object sender, EventArgs e)
        {
            try
            {
                tabControl.SelectedTabPage = tabPageReports;
                tabPageReports.Refresh();

                btnRefreshReportEarningArj.Focus();
            }
            catch (System.Exception f)
            {
                SendMessageToLog("btnReports_Click. Текст ошибки: " + f.Message);
            }
            finally
            {
            }
            return;
        }

        #endregion

        #region отчёт "Должники"
        private void btnRefreshReportDebtor_Click(object sender, EventArgs e)
        {
            try
            {
               StartThreadLoadReportDebtor();
            }
            catch (System.Exception f)
            {
                SendMessageToLog("btnRefreshReportDebtor_Click. Текст ошибки: " + f.Message);
            }

            return;
        }
        private void cboxCompanyReportDebtor_KeyPress(object sender, KeyPressEventArgs e)
        {
            try
            {
                if ((e.KeyChar == (char)Keys.Enter) && (btnRefreshReportDebtor.Enabled == true))
                {
                    StartThreadLoadReportDebtor();
                }
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("cboxCompanyReportDebtor_KeyPress.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally
            {
            }
            return;
        }
        private void ExportToExcelReportDebtor(string strFileName)
        {
            try
            {
                this.Cursor = Cursors.WaitCursor;

                System.IO.FileInfo newFile = new System.IO.FileInfo(strFileName);
                if (newFile.Exists)
                {
                    newFile.Delete();
                    newFile = new System.IO.FileInfo(strFileName);
                }

                using (ExcelPackage package = new ExcelPackage(newFile))
                {
                    ExcelWorksheet worksheet = package.Workbook.Worksheets.Add(this.Text);

                    foreach (DevExpress.XtraGrid.Columns.GridColumn objColumn in gridViewReportDebtor.Columns)
                    {
                        if (objColumn.Visible == false) { continue; }

                        worksheet.Cells[1, objColumn.VisibleIndex + 1].Value = objColumn.Caption;
                    }

                    using (var range = worksheet.Cells[1, 1, 1, gridViewReportDebtor.Columns.Count])
                    {
                        range.Style.Font.Bold = true;
                        range.Style.Font.Size = 14;
                    }

                    System.Int32 iCurrentRow = 2;
                    System.Int32 iRowsCount = gridViewReportDebtor.RowCount;
                    for (System.Int32 i = 0; i < iRowsCount; i++)
                    {
                        foreach (DevExpress.XtraGrid.Columns.GridColumn objColumn in gridViewReportDebtor.Columns)
                        {
                            if (objColumn.Visible == false) { continue; }

                            worksheet.Cells[iCurrentRow, objColumn.VisibleIndex + 1].Value = gridViewReportDebtor.GetRowCellValue(i, objColumn);
                            if(objColumn.FieldName == "Waybill_ShipDate")
                            {
                                worksheet.Cells[iCurrentRow, objColumn.VisibleIndex + 1].Style.Numberformat.Format = "DD.MM.YYYY";
                            }
                            if ((objColumn.FieldName == "Waybill_TotalPrice") || (objColumn.FieldName == "Waybill_AmountPaid") || 
                                (objColumn.FieldName == "Waybill_Saldo") || (objColumn.FieldName == "CustomerLimit_ApprovedSumma"))
                            {
                                worksheet.Cells[iCurrentRow, objColumn.VisibleIndex + 1].Style.Numberformat.Format = "# ### ### ### ##0.00";
                            }
                            if ((objColumn.FieldName == "CustomerLimit_ApprovedDays") || (objColumn.FieldName == "Waybill_ExpDays"))
                            {
                                worksheet.Cells[iCurrentRow, objColumn.VisibleIndex + 1].Style.Numberformat.Format = "# ### ### ### ##0";
                            }

                        }
                        iCurrentRow++;
                    }

                    iCurrentRow--;
                    worksheet.Cells[1, 1, iCurrentRow, gridViewReportDebtor.Columns.Count].AutoFitColumns(0);
                    worksheet.Cells[1, 1, iCurrentRow, gridViewReportDebtor.Columns.Count].Style.Border.Top.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    worksheet.Cells[1, 1, iCurrentRow, gridViewReportDebtor.Columns.Count].Style.Border.Left.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    worksheet.Cells[1, 1, iCurrentRow, gridViewReportDebtor.Columns.Count].Style.Border.Right.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    worksheet.Cells[1, 1, iCurrentRow, gridViewReportDebtor.Columns.Count].Style.Border.Bottom.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;

                    worksheet.PrinterSettings.FitToWidth = 1;

                    worksheet = null;

                    package.Save();

                    try
                    {
                        using (System.Diagnostics.Process process = new System.Diagnostics.Process())
                        {
                            process.StartInfo.FileName = strFileName;
                            process.StartInfo.Verb = "Open";
                            process.StartInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Normal;
                            process.Start();
                        }
                    }
                    catch
                    {
                        DevExpress.XtraEditors.XtraMessageBox.Show(this, "Системе не удалось найти приложение, чтобы открыть файл.", Application.ProductName, MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }

                }

            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show(
                    "Ошибка экспорта в MS Excel.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally
            {
                this.Cursor = System.Windows.Forms.Cursors.Default;
            }
        }

        private void btnPrintReportDebtor_Click(object sender, EventArgs e)
        {
            try
            {
                ExportToExcelReportDebtor(String.Format("{0}{1}.xlsx", System.IO.Path.GetTempPath(), (String.Format("{0} Должники", this.Text))));
            }
            catch (System.Exception f)
            {
                SendMessageToLog("btnPrintReportDebtor_Click. Текст ошибки: " + f.Message);
            }

            return;
        }
        #endregion

    }

    public class EarningEditor : PlugIn.IClassTypeView
    {
        public override void Run(UniXP.Common.MENUITEM objMenuItem, System.String strCaption)
        {
            frmEarning obj = new frmEarning(objMenuItem) { Text = strCaption, MdiParent = objMenuItem.objProfile.m_objMDIManager.MdiParent, Visible = true };
        }
    }

}
