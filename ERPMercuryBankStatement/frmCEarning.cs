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

namespace ERPMercuryBankStatement
{
    public enum enumPayMode
    {
        enUnkown = -1,
        enEarningPayAllDocuments = 0,
        enEarningPayOneDocument = 1,
        enAllEarningspayOneDocument = 2
    }

    public partial class frmCEarning : DevExpress.XtraEditors.XtraForm
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
        
        private List<CChildDepart> m_objCustomerList;
        private List<CEarning> m_objEarningList;
        private List<CEarning> m_objReportEarningArjList;
        private CEarning m_objSelectedEarning;
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

                        objRet = m_objEarningList.SingleOrDefault<CEarning>(x => x.ID.CompareTo(uuidID) == 0);
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
        private List<CDebitDocument> m_objDebitDocumentList;
        private List<CEarningHistory> m_objEarningHistoryList;
        private List<CPaidDocument> m_objPaidDocumentList;
        private List<CDebitDocument> m_objReportDebtorList;

        private System.Guid m_uuidCurrenyAccounting;
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
        public System.Threading.Thread ThreadReportEarningArj { get; set; }
        public System.Threading.Thread ThreadReportDebtor { get; set; }

        public System.Threading.ManualResetEvent EventStopThread { get; set; }
        public System.Threading.ManualResetEvent EventThreadStopped { get; set; }

        public delegate void LoadCustomerListDelegate(List<CChildDepart> objCustomerList, System.Int32 iRowCountInLis);
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

        private const System.Int32 iThreadSleepTime = 1000;
        private const System.String strWaitCustomer = "ждите... идет заполнение списка";
        private System.Boolean m_bThreadFinishJob;
        private const System.String strRegistryTools = "\\CEarningListTools\\";
        private const System.Int32 iWaitingpanelIndex = 0;
        private const System.Int32 iWaitingpanelHeight = 35;
        private const System.String m_strModeReadOnly = "Режим просмотра";
        private const System.String m_strModeEdit = "Режим редактирования";
        private const int INT_tableLayoutPanelDebitDocumentsColumnStyles0Width = 220;
        private const string STR_DebitDocumentList = "Журнал документов на оплату";

        private DevExpress.XtraTab.XtraTabPage m_objSelectedTabPage;
        private enumPayMode m_enPayMode;
        #endregion

        public frmCEarning(UniXP.Common.MENUITEM objMenuItem)
        {
            InitializeComponent();

            m_objMenuItem = objMenuItem;
            m_objProfile = objMenuItem.objProfile;
            m_bThreadFinishJob = false;
            m_objCustomerList = new List<CChildDepart>();
            m_objEarningList = new List<CEarning>();
            m_objReportEarningArjList = new List<CEarning>();
            m_objDebitDocumentList = new List<CDebitDocument>();
            m_objEarningHistoryList = new List<CEarningHistory>();
            m_objPaidDocumentList = new List<CPaidDocument>();
            m_objReportDebtorList = new List<CDebitDocument>();
            m_objSelectedEarning = null;
            m_enumPaymentType = enumPaymentType.PaymentForm2;

            AddGridColumns();
            dtBeginDate.DateTime = System.DateTime.Today; // new DateTime(System.DateTime.Today.Year, System.DateTime.Today.Month, 1);
            dtEndDate.DateTime = System.DateTime.Today;
            dtEndDateReportDebtor.DateTime = System.DateTime.Today;
            
            dtBeginDatePaidDocument.DateTime = System.DateTime.Today.AddMonths(-1);
            dtEndDatePaidDocument.DateTime = System.DateTime.Today;
            dtBeginDateDebitDocument.DateTime = System.DateTime.Today.AddMonths(-1);
            dtEndDateDebitDocument.DateTime = System.DateTime.Today;
            dtBeginDateReportEarningArj.DateTime = System.DateTime.Today;
            dtEnddateReportEarningArj.DateTime = System.DateTime.Today; 

            SearchProcessWoring.Visible = false;
            tabControl.ShowTabHeader = DevExpress.Utils.DefaultBoolean.False;
            m_bOnlyView = false;
            m_bIsChanged = false;
            m_bDisableEvents = false;
            m_bNewObject = false;
            m_uuidCurrenyAccounting = System.Guid.Empty;
            m_GroupKeyId = GenerateGroupKeyId();
            m_objSelectedTabPage = null;
            m_enPayMode = enumPayMode.enUnkown;
        }

        private int GenerateGroupKeyId()
        {
            Random rnd = new Random(DateTime.Now.Millisecond);
            return rnd.Next(1, 10000);
        }

        #region Открытие формы
        private void frmCEarning_Shown(object sender, EventArgs e)
        {
            try
            {
                RestoreLayoutFromRegistry();

                LoadComboBox();

                StartThreadLoadEarningList();

                StartThreadLoadCustomerList();

                if (m_objProfile.GetClientsRight().GetState(Consts.strDR_PaymentsForm2OnlyViewReports) == true)
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
                DevExpress.XtraEditors.XtraMessageBox.Show("frmCEarning_Shown().\n\nТекст ошибки: " + f.Message, "Ошибка",
                    System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }

            return;
        }

        #endregion

        #region Настройки грида
        private void AddGridColumns()
        {
            ColumnView.Columns.Clear();
        
            AddGridColumn(ColumnView, "ID", "Идентификатор");
            AddGridColumn(ColumnView, "Date", "Дата платежа");
            AddGridColumn(ColumnView, "ChildDepartCode", "Код дочернего");
            //AddGridColumn(ColumnView, "CustomerName", "Клиент");
            AddGridColumn(ColumnView, "ChildDepartName", "Дочерний клиент");            
            AddGridColumn(ColumnView, "CurrencyCode", "Валюта");
            AddGridColumn(ColumnView, "CurValue", "Сумма");
            AddGridColumn(ColumnView, "CurRate", "Курс");
            AddGridColumn(ColumnView, "Value", "Сумма в ОВУ");
            AddGridColumn(ColumnView, "Expense", "Расход");
            AddGridColumn(ColumnView, "Saldo", "Остаток");
            AddGridColumn(ColumnView, "IsBonusEarning", "Бонус");
            AddGridColumn(ColumnView, "BudgetProjectDstName", "Проект-назначение");
            AddGridColumn(ColumnView, "AccountPlanName", "План счетов");
            AddGridColumn(ColumnView, "EarningTypeName", "Вид платежа");

            foreach (DevExpress.XtraGrid.Columns.GridColumn objColumn in ColumnView.Columns)
            {
                objColumn.OptionsColumn.AllowEdit = false;
                objColumn.OptionsColumn.AllowFocus = false;
                objColumn.OptionsColumn.ReadOnly = true;
                
                if ((objColumn.FieldName == "ID") || (objColumn.FieldName == "CustomrText"))
                {
                    objColumn.Visible = false;
                }

                if( (objColumn.FieldName == "Value") || (objColumn.FieldName == "CurValue") || (objColumn.FieldName == "Expense") )
                {
                    objColumn.DisplayFormat.FormatType = DevExpress.Utils.FormatType.Numeric;
                    objColumn.DisplayFormat.FormatString = "### ### ##0.00";
                    objColumn.SummaryItem.FieldName = objColumn.FieldName;
                    objColumn.SummaryItem.DisplayFormat = "Итого: {0:### ### ##0.00}";
                    objColumn.SummaryItem.SummaryType = DevExpress.Data.SummaryItemType.Sum;
                }
                if ( objColumn.FieldName == "Saldo")
                {
                    objColumn.DisplayFormat.FormatType = DevExpress.Utils.FormatType.Numeric;
                    objColumn.DisplayFormat.FormatString = "### ### ##0.000";
                    objColumn.SummaryItem.FieldName = objColumn.FieldName;
                    objColumn.SummaryItem.DisplayFormat = "Итого: {0:### ### ##0.000}";
                    objColumn.SummaryItem.SummaryType = DevExpress.Data.SummaryItemType.Sum;
                }
                if (objColumn.FieldName == "CurRate")
                {
                    objColumn.DisplayFormat.FormatType = DevExpress.Utils.FormatType.Numeric;
                    objColumn.DisplayFormat.FormatString = "### ### ##0.00";
                    objColumn.SummaryItem.FieldName = objColumn.FieldName;
                    objColumn.SummaryItem.SummaryType = DevExpress.Data.SummaryItemType.Sum;
                }
            }

            // журнал истории оплат
            ColumnViewEarningHistory.Columns.Clear();

            AddGridColumn(ColumnViewEarningHistory, "Waybill_Id", "УИ документа");
            AddGridColumn(ColumnViewEarningHistory, "Waybill_ShipDate", "Дата отгрузки ТТН");
            AddGridColumn(ColumnViewEarningHistory, "Waybill_Num", "ТТН №");
            AddGridColumn(ColumnViewEarningHistory, "Company_Acronym", "Компания");
            AddGridColumn(ColumnViewEarningHistory, "Currency_Code", "Код дочернего");
            AddGridColumn(ColumnViewEarningHistory, "ChildCust_Name", "Дочерний клиент");
            AddGridColumn(ColumnViewEarningHistory, "Customer_Name", "Клиент");
            AddGridColumn(ColumnViewEarningHistory, "Waybill_CurrencyTotalPrice", "Сумма ТТН.");
            AddGridColumn(ColumnViewEarningHistory, "Payment_Value", "Сумма оплаты");
            AddGridColumn(ColumnViewEarningHistory, "Waybill_CurrencySaldo", "Сальдо ТТН.");
            AddGridColumn(ColumnViewEarningHistory, "Payment_OperDate", "Дата разноски");
            AddGridColumn(ColumnViewEarningHistory, "Earning_BankDate", "Дата платежа");
            AddGridColumn(ColumnViewEarningHistory, "Waybill_Bonus", "Бонус");
            AddGridColumn(ColumnViewEarningHistory, "Drop", "Отгрузка");

            foreach (DevExpress.XtraGrid.Columns.GridColumn objColumn in ColumnViewEarningHistory.Columns)
            {
                objColumn.OptionsColumn.AllowEdit = false;
                objColumn.OptionsColumn.AllowFocus = false;
                objColumn.OptionsColumn.ReadOnly = true;

                if (objColumn.FieldName == "Waybill_Id")
                {
                    objColumn.Visible = false;
                }

                if(objColumn.FieldName == "Payment_Value")
                {
                    objColumn.DisplayFormat.FormatType = DevExpress.Utils.FormatType.Numeric;
                    objColumn.DisplayFormat.FormatString = "### ### ##0.00";
                    objColumn.SummaryItem.FieldName = objColumn.FieldName;
                    objColumn.SummaryItem.DisplayFormat = "Итого: {0:### ### ##0.00}";
                    objColumn.SummaryItem.SummaryType = DevExpress.Data.SummaryItemType.Sum;
                }
                if ((objColumn.FieldName == "Payment_Value") || (objColumn.FieldName == "Waybill_CurrencyTotalPrice" ) ||
                    (objColumn.FieldName == "Waybill_CurrencySaldo"))
                {
                    objColumn.DisplayFormat.FormatType = DevExpress.Utils.FormatType.Numeric;
                    objColumn.DisplayFormat.FormatString = "### ### ##0.00";
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
            AddGridColumn(ColumnViewPaidDocument, "Depart_Code", "Дочерний клиент");
            AddGridColumn(ColumnViewPaidDocument, "Customer_Name", "Клиент");
            AddGridColumn(ColumnViewPaidDocument, "Waybill_Quantity", "Кол-во");
            AddGridColumn(ColumnViewPaidDocument, "Waybill_CurrencyTotalPrice", "Сумма ТТН.");
            //AddGridColumn(ColumnViewPaidDocument, "Waybill_RetAllPrice", "Сумма возврата, руб.");
            AddGridColumn(ColumnViewPaidDocument, "Waybill_CurrencyAmountPaid", "Сумма оплаты");
            AddGridColumn(ColumnViewPaidDocument, "Waybill_CurrencySaldo", "Сальдо ТТН");
            AddGridColumn(ColumnViewPaidDocument, "Waybill_Bonus", "Бонус");

            foreach (DevExpress.XtraGrid.Columns.GridColumn objColumn in ColumnViewPaidDocument.Columns)
            {
                objColumn.OptionsColumn.AllowEdit = false;
                objColumn.OptionsColumn.AllowFocus = false;
                objColumn.OptionsColumn.ReadOnly = true;

                if (objColumn.FieldName == "Waybill_Id")
                {
                    objColumn.Visible = false;
                }

                if ((objColumn.FieldName == "Waybill_CurrencyTotalPrice") || (objColumn.FieldName == "Waybill_CurrencySaldo") ||
                    (objColumn.FieldName == "Waybill_CurrencyAmountPaid"))
                {
                    objColumn.DisplayFormat.FormatType = DevExpress.Utils.FormatType.Numeric;
                    objColumn.DisplayFormat.FormatString = "### ### ##0.00";
                    objColumn.SummaryItem.FieldName = objColumn.FieldName;
                    objColumn.SummaryItem.DisplayFormat = "Итого: {0:### ### ##0.00}";
                    objColumn.SummaryItem.SummaryType = DevExpress.Data.SummaryItemType.Sum;
                }

                if(objColumn.FieldName == "Waybill_Quantity")
                {
                    objColumn.DisplayFormat.FormatType = DevExpress.Utils.FormatType.Numeric;
                    objColumn.DisplayFormat.FormatString = "### ### ##0";
                    objColumn.SummaryItem.FieldName = objColumn.FieldName;
                    objColumn.SummaryItem.DisplayFormat = "Итого: {0:### ### ##0}";
                    objColumn.SummaryItem.SummaryType = DevExpress.Data.SummaryItemType.Sum;
                }
            }

            // журнал документов на оплату
            ColumnViewDebitDoc.Columns.Clear();

            AddGridColumn(ColumnViewDebitDoc, "SrcCode", "Тип документа");
            AddGridColumn(ColumnViewDebitDoc, "Waybill_Id", "УИ документа");
            AddGridColumn(ColumnViewDebitDoc, "Waybill_ShipMode", "Вид отгрузки");
            AddGridColumn(ColumnViewDebitDoc, "Waybill_Num", "ТТН №");
            AddGridColumn(ColumnViewDebitDoc, "Waybill_BeginDate", "Дата ТТН");
            AddGridColumn(ColumnViewDebitDoc, "Waybill_Shipped", "Отгружена");
            AddGridColumn(ColumnViewDebitDoc, "ChildCust_Code", "Дочерний клиент");
            AddGridColumn(ColumnViewDebitDoc, "Waybill_TotalPrice", "Сумма");
            AddGridColumn(ColumnViewDebitDoc, "Waybill_AmountPaid", "Оплачено");
            AddGridColumn(ColumnViewDebitDoc, "Waybill_Saldo", "Сальдо");
            AddGridColumn(ColumnViewDebitDoc, "Waybill_Bonus", "Бонус");
            AddGridColumn(ColumnViewDebitDoc, "Customer_Name", "Клиент");
            AddGridColumn(ColumnViewDebitDoc, "Waybill_DateLastPaid", "Дата оплаты");
            AddGridColumn(ColumnViewDebitDoc, "Waybill_ShipModeName", "Вид отгрузки");
            AddGridColumn(ColumnViewDebitDoc, "Stock_Name", "Склад отгрузки");

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

                if ((objColumn.FieldName == "Waybill_TotalPrice") || (objColumn.FieldName == "Waybill_Saldo") || (objColumn.FieldName == "Waybill_AmountPaid"))
                {
                    objColumn.DisplayFormat.FormatType = DevExpress.Utils.FormatType.Numeric;
                    objColumn.DisplayFormat.FormatString = "### ### ##0.00";
                    objColumn.SummaryItem.FieldName = objColumn.FieldName;
                    objColumn.SummaryItem.DisplayFormat = "Итого: {0:### ### ##0.00}";
                    objColumn.SummaryItem.SummaryType = DevExpress.Data.SummaryItemType.Sum;
                }
            }


            // отчёт "Архив платежей"
            ColumnViewReportEarningArj.Columns.Clear();

            //AddGridColumn(ColumnViewReportEarningArj, "DetailsPayment", "Назначение платежа");
            AddGridColumn(ColumnViewReportEarningArj, "Date", "Дата платежа");
            AddGridColumn(ColumnViewReportEarningArj, "ChildDepartCode", "Дочерний клиент");
            AddGridColumn(ColumnViewReportEarningArj, "CustomerName", "Клиент");
            AddGridColumn(ColumnViewReportEarningArj, "Value", "Сумма платежа");
            AddGridColumn(ColumnViewReportEarningArj, "CurrencyCode", "Валюта");
            AddGridColumn(ColumnViewReportEarningArj, "Expense", "Сумма расходов");
            AddGridColumn(ColumnViewReportEarningArj, "Saldo", "Сальдо");
            AddGridColumn(ColumnViewReportEarningArj, "CurRate", "Курс к валюте учёта");
            AddGridColumn(ColumnViewReportEarningArj, "IsBonusEarning", "Бонус");

            foreach (DevExpress.XtraGrid.Columns.GridColumn objColumn in ColumnViewReportEarningArj.Columns)
            {
                objColumn.OptionsColumn.AllowEdit = false;
                objColumn.OptionsColumn.AllowFocus = false;
                objColumn.OptionsColumn.ReadOnly = true;

                if ((objColumn.FieldName == "Value") || (objColumn.FieldName == "Expense") || (objColumn.FieldName == "Saldo"))
                {
                    objColumn.DisplayFormat.FormatType = DevExpress.Utils.FormatType.Numeric;
                    objColumn.DisplayFormat.FormatString = "### ### ### ##0.00";
                    objColumn.SummaryItem.FieldName = objColumn.FieldName;
                    objColumn.SummaryItem.DisplayFormat = "Итого: {0:### ### ### ##0.00}";
                    objColumn.SummaryItem.SummaryType = DevExpress.Data.SummaryItemType.Sum;
                }
            }


            // отчёт "Дебиторы"
            ColumnViewReportDebtor.Columns.Clear();

            AddGridColumn(ColumnViewReportDebtor, "Debt_Type", "Тип");
            AddGridColumn(ColumnViewReportDebtor, "Waybill_Id", "УИ документа");
            AddGridColumn(ColumnViewReportDebtor, "ChildCust_Code", "Код дочернего кл-та");
            AddGridColumn(ColumnViewReportDebtor, "ChildCust_Name", "Дочерний клиент");
            AddGridColumn(ColumnViewReportDebtor, "Waybill_Num", "ТТН №");
            AddGridColumn(ColumnViewReportDebtor, "Waybill_ShipDate", "Отгружено");
            AddGridColumn(ColumnViewReportDebtor, "Waybill_TotalPrice", "К оплате");
            AddGridColumn(ColumnViewReportDebtor, "Waybill_AmountPaid", "Оплачено");
            AddGridColumn(ColumnViewReportDebtor, "Waybill_Saldo", "Сальдо");
            AddGridColumn(ColumnViewReportDebtor, "Waybill_ExpDays", "Просрочено, дней");

            AddGridColumn(ColumnViewReportDebtor, "Customer_Name", "Клиент");
            AddGridColumn(ColumnViewReportDebtor, "Depart_Code", "Подр-е");

            foreach (DevExpress.XtraGrid.Columns.GridColumn objColumn in ColumnViewReportDebtor.Columns)
            {
                objColumn.OptionsColumn.AllowEdit = false;
                objColumn.OptionsColumn.AllowFocus = false;
                objColumn.OptionsColumn.ReadOnly = true;

                if( ( objColumn.FieldName == "Waybill_Id" ) || ( objColumn.FieldName == "Waybill_ShipMode" ) )
                {
                    objColumn.Visible = false;
                }

                if( objColumn.FieldName == "Waybill_ExpDays" )
                {
                    objColumn.DisplayFormat.FormatType = DevExpress.Utils.FormatType.Numeric;
                    objColumn.DisplayFormat.FormatString = "### ### ### ##0";
                }
                if ((objColumn.FieldName == "Waybill_TotalPrice") || (objColumn.FieldName == "Waybill_Saldo") ||
                    (objColumn.FieldName == "Waybill_AmountPaid"))
                {
                    objColumn.DisplayFormat.FormatType = DevExpress.Utils.FormatType.Numeric;
                    objColumn.DisplayFormat.FormatString = "### ### ### ##0.00";
                }
                if ((objColumn.FieldName == "Waybill_TotalPrice") || (objColumn.FieldName == "Waybill_Saldo") ||
                    (objColumn.FieldName == "Waybill_AmountPaid"))
                {
                    objColumn.SummaryItem.FieldName = objColumn.FieldName;
                    objColumn.SummaryItem.DisplayFormat = "Итого: {0:### ### ### ##0.00}";
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
                barBtnDelete.Enabled = false;

                barBtnRefresh.Enabled = false;
                barBtnDebitDocumentList.Enabled = false;
                barBtnEarningHistoryView.Enabled = false;
                barBtnPaidDocumentList.Enabled = false;

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
                List<CChildDepart> objCustomerList = CChildDepart.GetChildDepartList( m_objProfile, null, System.Guid.Empty );


                List<CChildDepart> objAddCustomerList = new List<CChildDepart>();
                if ((objCustomerList != null) && (objCustomerList.Count > 0))
                {
                    System.Int32 iRecCount = 0;
                    System.Int32 iRecAllCount = 0;
                    foreach (CChildDepart objCustomer in objCustomerList)
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
        private void LoadCustomerList(List<CChildDepart> objCustomerList, System.Int32 iRowCountInList)
        {
            try
            {
                cboxCustomer.Text = strWaitCustomer;
                cboxChildCustomerPaidDocument.Text = strWaitCustomer;
                cboxChildCustomerReportDebtor.Text = strWaitCustomer;
                if ((objCustomerList != null) && (objCustomerList.Count > 0) && (cboxCustomer.Properties.Items.Count < iRowCountInList))
                {
                    cboxCustomer.Properties.Items.AddRange( objCustomerList );
                    cboxChildCustomerPaidDocument.Properties.Items.AddRange(objCustomerList);
                    cboxChildCustomerDebitDocument.Properties.Items.AddRange(objCustomerList);
                    cboxChildCustomerReportEarningArj.Properties.Items.AddRange(objCustomerList);
                    cboxChildCustomerReportDebtor.Properties.Items.AddRange(objCustomerList);
                    editorEarningChildCust.Properties.Items.AddRange(objCustomerList);
                    m_objCustomerList.AddRange(objCustomerList);
                }
                else
                {
                    cboxCustomer.Text = "";
                    cboxChildCustomerPaidDocument.Text = "";
                    cboxChildCustomerReportEarningArj.Text = "";
                    cboxChildCustomerReportDebtor.Text = "";

                    barBtnAdd.Enabled = !m_bOnlyView;
                    barBtnEdit.Enabled = (gridViewEarningList.FocusedRowHandle >= 0);
                    barBtnDelete.Enabled = ((!m_bOnlyView) && (gridViewEarningList.FocusedRowHandle >= 0) && (System.Convert.ToDecimal(gridViewEarningList.GetRowCellValue(gridViewEarningList.FocusedRowHandle, "Expense")) == 0));
                    barBtnDebitDocumentList.Enabled = !m_bOnlyView;
                    barBtnEarningHistoryView.Enabled = (gridViewEarningList.FocusedRowHandle >= 0);
                    barBtnPaidDocumentList.Enabled = true;
                    barBtnRefresh.Enabled = true;

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
                barBtnDelete.Enabled = false;
                barBtnRefresh.Enabled = false;
                barBtnDebitDocumentList.Enabled = false;
                barBtnEarningHistoryView.Enabled = false;
                barBtnPaidDocumentList.Enabled = false;

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
                System.Guid uuidCustomerId = (((cboxCustomer.SelectedItem == null) || (System.Convert.ToString(cboxCustomer.SelectedItem) == "") || (cboxCustomer.Text == strWaitCustomer)) ? System.Guid.Empty : ((CChildDepart)cboxCustomer.SelectedItem).ID);
                System.Guid uuidCompanyId = System.Guid.Empty;
                System.DateTime dtBeginDate = this.dtBeginDate.DateTime;
                System.DateTime dtEndDate = this.dtEndDate.DateTime;
                
                System.String strErr = "";
                List<CEarning> objEarningList = CEarningDataBaseModel.GetСEarningList(m_objProfile, null, dtBeginDate, dtEndDate, uuidCompanyId, uuidCustomerId, ref strErr);

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
                    barBtnDelete.Enabled = ((!m_bOnlyView) && (gridViewEarningList.FocusedRowHandle >= 0) && (System.Convert.ToDecimal( gridViewEarningList.GetRowCellValue(gridViewEarningList.FocusedRowHandle, "Expense")) == 0));
                    barBtnRefresh.Enabled = true;
                    barBtnDebitDocumentList.Enabled = !m_bOnlyView;
                    barBtnEarningHistoryView.Enabled = (gridViewEarningList.FocusedRowHandle >= 0);
                    barBtnPaidDocumentList.Enabled = true;

                    gridControlEarningList.RefreshDataSource();

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
                List<CEarningHistory> objEarningHistoryList = CPaymentDataBaseModel.GetCEarningHistoryList(m_objProfile, null, m_objSelectedEarning.ID, ref strErr);

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
                m_objPaidDocumentList.Clear();

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
                System.Guid uuidChildDepartId = (((cboxChildCustomerPaidDocument.SelectedItem == null) || (cboxChildCustomerPaidDocument.Text.Equals(System.String.Empty))) ? System.Guid.Empty : ((CChildDepart)cboxChildCustomerPaidDocument.SelectedItem).ID);
                System.Guid uuidCustomerId = (((cboxCustomerPaidDocument.SelectedItem == null) || (cboxCustomerPaidDocument.Text.Equals(System.String.Empty))) ? System.Guid.Empty : ((CCustomer)cboxCustomerPaidDocument.SelectedItem).ID);
                System.Guid uuidCompanyId = ((cboxCompanyPaidDocument.SelectedItem == null) ? System.Guid.Empty : ((CCompany)cboxCompanyPaidDocument.SelectedItem).ID);
                System.DateTime dtBeginDate = dtBeginDatePaidDocument.DateTime;
                System.DateTime dtEndDate = dtEndDatePaidDocument.DateTime;
                System.String strWaybillNum = txtWaybillNumPaidDocument.Text;

                System.String strErr = "";
                List<CPaidDocument> objPaidDocumentList = CPaymentDataBaseModel.GetPaidDocumentFormPay2List(m_objProfile, null,
                    uuidCompanyId, uuidCustomerId, uuidChildDepartId, dtBeginDate, dtEndDate, strWaybillNum, ref strErr);

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
                System.Guid uuidChildDepartId = ((cboxChildCustomerDebitDocument.SelectedItem == null) ? System.Guid.Empty : ((CChildDepart)cboxChildCustomerDebitDocument.SelectedItem).ID);
                System.Guid uuidCustomerId = ((cboxCustomerDebitDocument.SelectedItem == null) ? System.Guid.Empty : ((CCustomer)cboxCustomerDebitDocument.SelectedItem).ID);
                System.Guid uuidCompanyId = ((cboxCompanyDebitDocument.SelectedItem == null) ? System.Guid.Empty : ((CCompany)cboxCompanyDebitDocument.SelectedItem).ID);

                System.String strErr = "";
                List<CDebitDocument> objDebitDocumentList = CPaymentDataBaseModel.GetDebitDocumentFormPay2List(m_objProfile, null, uuidCompanyId, uuidCustomerId, 
                    uuidChildDepartId, dtBeginDateDebitDocument.DateTime, dtEndDateDebitDocument.DateTime,  ref strErr);

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

                    if (m_enPayMode == enumPayMode.enEarningPayOneDocument)
                    {
                        pictureBoxInfoInDebitDocList.Image = ERPMercuryBankStatement.Properties.Resources.SpreadSheet_Total;
                        if (m_objSelectedEarning != null)
                        {
                            lblEarningInfoInpayDebitDocument.Text = (String.Format("Остаток платежа:\t{0:### ### ##0.00}", m_objSelectedEarning.Saldo));
                        }
                    }
                    else if (m_enPayMode == enumPayMode.enAllEarningspayOneDocument)
                    {
                        lblEarningInfoInpayDebitDocument.Text = "";
                        pictureBoxInfoInDebitDocList.Image = ERPMercuryBankStatement.Properties.Resources.SpreadSheet_Total;
                    }

                    btnRefreshDebitDocumentList.Enabled = true;
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
        /// Стартует поток, в котором загружается отчёт "Архив платежей"
        /// </summary>
        public void StartThreadLoadReportEarningArjList()
        {
            try
            {
                // инициализируем делегаты
                m_LoadReportEarningArjDelegate = new LoadReportEarningArjDelegate(LoadReportEarningArjInGrid);
                m_objReportEarningArjList.Clear();

                btnRefreshReportEarningArj.Enabled = false;
                btnPrintReportEarningArj.Enabled = false;
                cboxChildCustomerReportEarningArj.Enabled = false;
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
                System.Guid uuidChildDepartId = (((cboxChildCustomerReportEarningArj.SelectedItem == null) || (System.Convert.ToString(cboxChildCustomerReportEarningArj.SelectedItem) == "") || (cboxChildCustomerReportEarningArj.Text == strWaitCustomer)) ? System.Guid.Empty : ((CChildDepart)cboxChildCustomerReportEarningArj.SelectedItem).ID);
                System.DateTime dtBeginDate = this.dtBeginDateReportEarningArj.DateTime;
                System.DateTime dtEndDate = this.dtEnddateReportEarningArj.DateTime;

                System.String strErr = "";

                if (m_objReportEarningArjList == null) { m_objReportEarningArjList = new List<CEarning>(); }
                m_objReportEarningArjList.Clear();

                List<CEarning> objEarningList = CPaymentDataBaseModel.GetReportCEarningArj(m_objProfile, null, dtBeginDate, dtEndDate, uuidChildDepartId, ref strErr);

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
        private void LoadReportEarningArjInGrid(List<CEarning> objEarningList, System.Int32 iRowCountInList)
        {
            try
            {
                if ((objEarningList != null) && (objEarningList.Count > 0) && (gridViewReportEarningArj.RowCount < iRowCountInList))
                {
                    m_objReportEarningArjList.AddRange(objEarningList);
                    if (gridControlReportEarningArj.DataSource == null)
                    {
                        gridControlReportEarningArj.DataSource = m_objReportEarningArjList;
                    }

                    this.tableLayoutPanelReports.SuspendLayout();
                    ((System.ComponentModel.ISupportInitialize)(this.gridControlReportEarningArj)).BeginInit();
                    ((System.ComponentModel.ISupportInitialize)(this.gridViewReportEarningArj)).BeginInit();

                    gridControlReportEarningArj.RefreshDataSource();

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
                    cboxChildCustomerReportEarningArj.Enabled = true;
                    dtBeginDateReportEarningArj.Enabled = true;
                    dtEnddateReportEarningArj.Enabled = true;

                    progressBarControlReportEarningArj.Position = 100;
                    this.Update();

                    panelProgressBarReportEarningArj.Visible = false;

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
                dtEndDateReportDebtor.Enabled = false;
                cboxChildCustomerReportDebtor.Enabled = false;

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
                System.DateTime dtEndDate = dtEndDateReportDebtor.DateTime;
                System.Guid uuidChildDepartId = (((cboxChildCustomerReportDebtor.SelectedItem == null) || (System.Convert.ToString(cboxChildCustomerReportDebtor.SelectedItem) == "") || (cboxChildCustomerReportDebtor.Text == strWaitCustomer)) ? System.Guid.Empty : ((CChildDepart)cboxChildCustomerReportDebtor.SelectedItem).ID);

                System.String strErr = "";

                if (m_objReportDebtorList == null) { m_objReportDebtorList = new List<CDebitDocument>(); }
                m_objReportDebtorList.Clear();

                List<CDebitDocument> objDebitDocumentList = CPaymentDataBaseModel.GetReportCDebtor(m_objProfile, null, uuidChildDepartId, dtEndDate, ref strErr);

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
                    cboxChildCustomerReportDebtor.Enabled = true;
                    dtEndDateReportDebtor.Enabled = true;

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
            System.String strErr = "";
            try
            {
                cboxCustomer.Properties.Items.Clear();
                cboxCustomer.Properties.Items.Add(new CChildDepart());

                cboxChildCustomerPaidDocument.Properties.Items.Clear();
                cboxChildCustomerDebitDocument.Properties.Items.Clear();
                cboxChildCustomerReportEarningArj.Properties.Items.Clear();
                cboxChildCustomerReportEarningArj.Properties.Items.Add(new CChildDepart());
                cboxChildCustomerReportDebtor.Properties.Items.Clear();
                cboxChildCustomerReportDebtor.Properties.Items.Add(new CChildDepart());
                

                editorEarningCompanyPayer.Properties.Items.Clear();
                editorEarningCompanyDst.Properties.Items.Clear();
                editorEarningType.Properties.Items.Clear();
                cboxCompanyPaidDocument.Properties.Items.Clear();
                cboxCompanyDebitDocument.Properties.Items.Clear();
                cboxCompany.Properties.Items.Clear();

                cboxCompany.Properties.Items.AddRange(CCompany.GetCompanyList(m_objProfile, null));
                cboxCompany.SelectedItem = ((cboxCompany.Properties.Items.Count > 0) ? cboxCompany.Properties.Items[0] : null);

                editorEarningCompanyPayer.Properties.Items.Add(new CCompany());
                editorEarningCompanyPayer.Properties.Items.AddRange(cboxCompany.Properties.Items);
                editorEarningCompanyDst.Properties.Items.AddRange(cboxCompany.Properties.Items);

                cboxCompanyPaidDocument.Properties.Items.Add(new CCompany());
                cboxCompanyPaidDocument.Properties.Items.AddRange(cboxCompany.Properties.Items);

                cboxCompanyDebitDocument.Properties.Items.Add(new CCompany());
                cboxCompanyDebitDocument.Properties.Items.AddRange(cboxCompany.Properties.Items);

                List<CCurrency> objCurrencylist = CCurrency.GetCurrencyList(m_objProfile, null);
                editorEarningCurrency.Properties.Items.Clear();

                if (objCurrencylist != null)
                {
                    // идентификатор валюты учёта
                    CCurrency objCurrenyAccounting = objCurrencylist.SingleOrDefault<CCurrency>(x=>x.IsMain);
                    m_uuidCurrenyAccounting = ( ( objCurrenyAccounting != null ) ? objCurrenyAccounting.ID : System.Guid.Empty );

                    // список валют для платежа
                    
                    // 2014.01.13
                    // отображается весь список валют
                    editorEarningCurrency.Properties.Items.AddRange(objCurrencylist);
                    //if (m_enumPaymentType == enumPaymentType.PaymentForm1)
                    //{
                    //    editorEarningCurrency.Properties.Items.AddRange(objCurrencylist.Where<CCurrency>(x => x.IsNationalCurrency).ToList<CCurrency>());
                    //}
                    //else
                    //{
                    //    editorEarningCurrency.Properties.Items.AddRange(objCurrencylist.Where<CCurrency>(x => x.IsNationalCurrency == false).ToList<CCurrency>());
                    //}
                }

                editorEarningPaymentType.Properties.Items.Clear();
                if (m_enumPaymentType == enumPaymentType.PaymentForm1)
                {
                    editorEarningPaymentType.Properties.Items.AddRange(CPaymentType.GetPaymentTypeList(m_objProfile, null, System.Guid.Empty).Where<CPaymentType>(x=>x.Payment_Id.Equals(1)).ToList<CPaymentType>());
                }
                else
                {
                    editorEarningPaymentType.Properties.Items.AddRange(CPaymentType.GetPaymentTypeList(m_objProfile, null, System.Guid.Empty).Where<CPaymentType>(x => x.Payment_Id.Equals(2)).ToList<CPaymentType>());
                }

                
                editorEarningAccountPlan.Properties.Items.Clear();
                //editorEarningAccountPlan.Properties.Items.Add(new CAccountPlan());
                editorEarningAccountPlan.Properties.Items.AddRange(CAccountPlanDataBaseModel.GetAccountPlanList(m_objProfile, null, ref strErr));

                editorEarningProjectSrc.Properties.Items.Clear();
                editorEarningProjectSrc.Properties.Items.Add(new CBudgetProject());

                editorEarningProjectDst.Properties.Items.Clear();
                //editorEarningProjectDst.Properties.Items.Add(new CBudgetProject());

                editorEarningProjectSrc.Properties.Items.AddRange( CBudgetProjectDataBaseModel.GetBudgetProjectList( m_objProfile, null, ref strErr));
                editorEarningProjectDst.Properties.Items.AddRange(editorEarningProjectSrc.Properties.Items);

                List<CEarningType> objEarningTypeList = CEarningType.GetEarningTypeList(m_objProfile, ref strErr);
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
        private CEarning GetSelectedEarning()
        {
            CEarning objRet = null;
            try
            {
                if ((((DevExpress.XtraGrid.Views.Grid.GridView) gridControlEarningList.MainView).RowCount > 0) &&
                    (((DevExpress.XtraGrid.Views.Grid.GridView)gridControlEarningList.MainView).FocusedRowHandle >= 0))
                {
                    System.Guid uuidID = (System.Guid)(((DevExpress.XtraGrid.Views.Grid.GridView)gridControlEarningList.MainView)).GetFocusedRowCellValue("ID");

                    objRet = m_objEarningList.SingleOrDefault<CEarning>(x => x.ID.CompareTo(uuidID) == 0);
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

        /// <summary>
        /// Определяет, какой платёж выбран в журнале и отображает его свойства
        /// </summary>
        private void FocusedEarningChanged()
        {
            try
            {
                ShowEarningProperties(GetSelectedEarning());

                barBtnAdd.Enabled = !m_bOnlyView;
                barBtnEdit.Enabled = (gridViewEarningList.FocusedRowHandle >= 0);
                barBtnDelete.Enabled = ((!m_bOnlyView) && (gridViewEarningList.FocusedRowHandle >= 0) && (System.Convert.ToDecimal(gridViewEarningList.GetRowCellValue(gridViewEarningList.FocusedRowHandle, "Expense")) == 0));
                barBtnDebitDocumentList.Enabled = !m_bOnlyView;
                barBtnEarningHistoryView.Enabled = (gridViewEarningList.FocusedRowHandle >= 0);

                mitmsNewEarning.Enabled = barBtnAdd.Enabled;
                mitmsEditEarning.Enabled = barBtnEdit.Enabled;
                mitmsDeleteEarning.Enabled = barBtnDelete.Enabled;

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

                txtEarningChildDepartCode.Text = "";
                txtEarningDate.Text = "";
                txtEarningPayer.Text = "";
                txtEarningCurrency.Text = "";
                calcEarningCurrencyValue.Value = 0;
                calcEarningCurrencyRate.Value = 0;
                calcEarningValue.Value = 0;
                calcEarningExpense.Value = 0;
                calcEarningSaldo.Value = 0;
                checkEarningIsBonus.Checked = false;
                txtEarningAccountPlan.Text = "";
                txtEarningBudgetProjectDst.Text = "";

                if (objEarning != null)
                {
                    txtEarningChildDepartCode.Text = objEarning.ChildDepartCode;
                    txtEarningDate.Text = objEarning.Date.ToShortDateString();
                    txtEarningPayer.Text = objEarning.CustomerName;
                    txtEarningCurrency.Text = objEarning.CurrencyCode;
                    calcEarningCurrencyValue.Value = objEarning.CurValue;
                    calcEarningCurrencyRate.Value = objEarning.CurRate;
                    calcEarningValue.Value = objEarning.Value;
                    calcEarningExpense.Value = objEarning.Expense;
                    calcEarningSaldo.Value = objEarning.Saldo;
                    checkEarningIsBonus.Checked = objEarning.IsBonusEarning;
                    txtEarningAccountPlan.Text = objEarning.AccountPlanName;
                    txtEarningBudgetProjectDst.Text = objEarning.BudgetProjectDstName;

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
                btnSelectAccount.Enabled = !bSet;
                editorEarningType.Properties.ReadOnly = bSet;

                btnEdit.Enabled = bSet;
                btnNewEarning.Enabled = bSet;

                btnEarningHistory.Enabled = bSet;
                btnPayment.Enabled = bSet;

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
                editorEarningType.Properties.ReadOnly = true;
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
                //editorEarningCompanyDst.Properties.Appearance.BackColor = ((editorEarningCompanyDst.SelectedItem == null) ? System.Drawing.Color.Tomato : System.Drawing.Color.White);
                editorEarningCurrency.Properties.Appearance.BackColor = ((editorEarningCurrency.SelectedItem == null) ? System.Drawing.Color.Tomato : System.Drawing.Color.White);
                editorEarningPaymentType.Properties.Appearance.BackColor = ((editorEarningPaymentType.SelectedItem == null) ? System.Drawing.Color.Tomato : System.Drawing.Color.White);
                editorEarningChildCust.Properties.Appearance.BackColor = ((editorEarningChildCust.SelectedItem == null) ? System.Drawing.Color.Tomato : System.Drawing.Color.White);
                editorEarningCustomer.Properties.Appearance.BackColor = ((editorEarningCustomer.SelectedItem == null) ? System.Drawing.Color.Tomato : System.Drawing.Color.White);
                //editorEarningAccount.Properties.Appearance.BackColor = ((editorEarningAccount.SelectedItem == null) ? System.Drawing.Color.Tomato : System.Drawing.Color.White);
                //editorEarningBank.Properties.Appearance.BackColor = ((editorEarningBank.SelectedItem == null) ? System.Drawing.Color.Tomato : System.Drawing.Color.White);
                editorEarningDate.Properties.Appearance.BackColor = ((editorEarningDate.DateTime == System.DateTime.MinValue) ? System.Drawing.Color.Tomato : System.Drawing.Color.White);
                editorEarningValue.Properties.Appearance.BackColor = ((editorEarningValue.Value <= 0) ? System.Drawing.Color.Tomato : System.Drawing.Color.White);

                editorEarningProjectDst.Properties.Appearance.BackColor = ((editorEarningProjectDst.SelectedItem == null) ? System.Drawing.Color.Tomato : System.Drawing.Color.White);
                editorEarningAccountPlan.Properties.Appearance.BackColor = ((editorEarningAccountPlan.SelectedItem == null) ? System.Drawing.Color.Tomato : System.Drawing.Color.White);

                // в том случае, если выбран хотя бы один из дополнительных параметров, необходимо указать все остальные
                System.Boolean bRetAdvParam = true;
                System.Boolean bExistsProjectSrc = ((editorEarningProjectSrc.SelectedItem != null) && (((CBudgetProject)editorEarningProjectSrc.SelectedItem)).ID.CompareTo(System.Guid.Empty) != 0);
                System.Boolean bExistsCompanyPayer = ((editorEarningCompanyPayer.SelectedItem != null) && (((CCompany)editorEarningCompanyPayer.SelectedItem)).ID.CompareTo(System.Guid.Empty) != 0);

                if ((bExistsCompanyPayer == true) || (bExistsProjectSrc == true))
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

                bRet = ((editorEarningCurrency.SelectedItem != null) &&
                    (editorEarningPaymentType.SelectedItem != null) &&  (editorEarningChildCust.SelectedItem != null) &&
                    (editorEarningProjectDst.SelectedItem != null) && (editorEarningAccountPlan.SelectedItem != null) &&
                    (editorEarningDate.DateTime != System.DateTime.MinValue) && (editorEarningValue.Value > 0) && (bRetAdvParam == true)
                    );

            }
            catch (System.Exception f)
            {
                SendMessageToLog("ValidateProperties. Текст ошибки: " + f.Message);
            }

            return bRet;
        }
        /// <summary>
        /// пересчёт курса и суммы в валюте учёта
        /// </summary>
        private void RecalcEarningValue()
        {
            System.String strErr = "";

            try
            {
                System.Guid uuidEarningCurrencyId = ( ( editorEarningCurrency.SelectedItem != null ) ? ((CCurrency)editorEarningCurrency.SelectedItem).ID : System.Guid.Empty );
                System.Decimal dcmlEarningValue = editorEarningValue.Value;
                System.Decimal dcmlEarningCurValue = 0;
                System.Decimal dcmlCurrencyRate = 0;
                System.DateTime dtEarningdate = editorEarningDate.DateTime;
                

                if ((uuidEarningCurrencyId.CompareTo(System.Guid.Empty) != 0) &&
                    (m_uuidCurrenyAccounting.CompareTo(System.Guid.Empty) != 0) &&
                    (dcmlEarningValue > 0) && ( System.DateTime.Compare( dtEarningdate, System.DateTime.MinValue ) > 0 ))
                {
                    // 2014.02.05
                    // возвращается сколько валюты содержится в 1 единице валюты учета
                    dcmlCurrencyRate = CCurrencyRate.GetCurrencyRate(m_objProfile, null,
                        m_uuidCurrenyAccounting, uuidEarningCurrencyId, dtEarningdate, ref strErr);

                    if (dcmlCurrencyRate == 0)
                    {
                        SendMessageToLog(String.Format("Ошибка пересчёта суммы в валюту учёта. Текст ошибки: {0}", strErr));
                    }

                    dcmlEarningCurValue = ((dcmlCurrencyRate > 0) ? (dcmlEarningValue / dcmlCurrencyRate) : 0);
                }

                if (editorEarningCurRate.Value.Equals(dcmlCurrencyRate) == false)
                {
                    editorEarningCurRate.Value = dcmlCurrencyRate;
                }

                if (editorEarningCurValue.Value.Equals(dcmlEarningCurValue) == false)
                {
                    editorEarningCurValue.Value = dcmlEarningCurValue;
                }
            }
            catch (System.Exception f)
            {
                SendMessageToLog(String.Format("Ошибка пересчёта суммы в валюту учёта. Текст ошибки: {0}", f.Message));
            }
            finally
            {
            }

            return;
        }

        private void cboxEarningPropertie_SelectedValueChanged(object sender, EventArgs e)
        {
            try
            {
                if (m_bDisableEvents == true) { return; }

                if( sender == editorEarningChildCust )
                {
                    LoadCustomerForChildDepart((editorEarningChildCust.SelectedItem == null) ? null : (CChildDepart)editorEarningChildCust.SelectedItem);

                    if (m_objSelectedEarning != null)
                    {
                        if (m_objSelectedEarning.Customer != null)
                        {
                            editorEarningCustomer.SelectedItem = editorEarningCustomer.Properties.Items.Cast<CCustomer>().FirstOrDefault<CCustomer>(x => x.ID.CompareTo(m_objSelectedEarning.Customer.ID) == 0);
                        }

                        if (editorEarningCustomer.SelectedItem == null)
                        {
                            editorEarningCustomer.SelectedItem = ((editorEarningCustomer.Properties.Items.Count > 0) ? editorEarningCustomer.Properties.Items[0] : null);
                        }
                    }
                }
                if ((sender == editorEarningValue) || (sender == editorEarningCurrency))
                {
                    RecalcEarningValue();
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
                    editorEarningCompanyDst.SelectedItem = (COMPANY_ACRONYM == "") ? null : editorEarningCompanyDst.Properties.Items.Cast<CCompany>().SingleOrDefault<CCompany>(x => x.Abbr == COMPANY_ACRONYM);
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
        /// <summary>
        /// загружает список клиентов для дочернего подразделения
        /// </summary>
        /// <param name="objChildDepart">дочернее подразделение</param>
        private void LoadCustomerForChildDepart(CChildDepart objChildDepart)
        {
            System.String strErr = System.String.Empty;
            Cursor = Cursors.WaitCursor;
            try
            {
                // очистка выпадающих списков с банками и расчётными счетами
                editorEarningCustomer.SelectedItem = null;
                editorEarningCustomer.Properties.Items.Clear();

                if (objChildDepart == null) { return; }

                List<CCustomer> objCustomerListForChildDepart = CCustomer.GetCustomerListForChildDepart(m_objProfile,
                    null, objChildDepart.ID, ref strErr);

                if (objCustomerListForChildDepart != null)
                {
                    editorEarningCustomer.Properties.Items.AddRange(objCustomerListForChildDepart);
                }

                if ((m_objSelectedEarning != null) && (m_objSelectedEarning.Customer != null))
                {
                    if (editorEarningCustomer.Properties.Items.Cast<CCustomer>().FirstOrDefault<CCustomer>(x => x.ID.CompareTo(m_objSelectedEarning.Customer.ID) == 0) == null)
                    {
                        editorEarningCustomer.Properties.Items.Add(m_objSelectedEarning.Customer);
                    }
                }

            }
            catch (System.Exception f)
            {
                SendMessageToLog(String.Format("Ошибка загрузки списка клиентов для дочернего подразделения. Текст ошибки: {0}", f.Message));
            }
            finally
            {
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
                EditEarning(GetSelectedEarning(), false);

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

                EditEarning(GetSelectedEarning(), false);

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
                editorEarningCurValue.Value = 0;
                editorEarningCurRate.Value = 0;
                editorEarningValue.Value = 0;
                editorEarningExpense.Value = 0;
                editorEarningSaldo.Value = 0;
                editorEarningChildCust.SelectedItem = null;
                editorEarningCustomer.SelectedItem = null;
                editorEarningpayerDetail.Text = "";
                editorEarningAccount.SelectedItem = null;
                editorEarningBank.SelectedItem = null;
                editorEarningAccount.Properties.Items.Clear();
                editorEarningBank.Properties.Items.Clear();
                editorEarningType.SelectedItem = null;

                editorEarningDetail.Text = "";
                editorEarningCompanyPayer.SelectedItem = null;
                editorEarningAccountPlan.SelectedItem = null;
                editorEarningProjectSrc.SelectedItem = null;
                editorEarningProjectDst.SelectedItem = null;
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

                editorEarningCurValue.Value = m_objSelectedEarning.CurValue;
                editorEarningCurRate.Value = m_objSelectedEarning.CurRate;
                editorEarningValue.Value = m_objSelectedEarning.Value;
                editorEarningExpense.Value = m_objSelectedEarning.Expense;
                editorEarningSaldo.Value = m_objSelectedEarning.Saldo;

                editorEarningChildCust.SelectedItem = (m_objSelectedEarning.ChildDepart == null) ? null : editorEarningChildCust.Properties.Items.Cast<CChildDepart>().SingleOrDefault<CChildDepart>(x => x.ID.CompareTo(m_objSelectedEarning.ChildDepart.ID) == 0);

                LoadCustomerForChildDepart(m_objSelectedEarning.ChildDepart);

                if ((m_objSelectedEarning != null) && (m_objSelectedEarning.Customer != null))
                {
                    if ( editorEarningCustomer.Properties.Items.Cast<CCustomer>().FirstOrDefault<CCustomer>(x => x.ID.CompareTo(m_objSelectedEarning.Customer.ID) == 0) == null)
                    {
                        editorEarningCustomer.Properties.Items.Add(m_objSelectedEarning.Customer);
                    }
                }

                editorEarningCustomer.SelectedItem = (m_objSelectedEarning.Customer == null) ? null : editorEarningCustomer.Properties.Items.Cast<CCustomer>().FirstOrDefault<CCustomer>(x => x.ID.CompareTo(m_objSelectedEarning.Customer.ID) == 0);

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
                CChildDepart objChildDepart = (( (cboxCustomer.SelectedItem == null) || (cboxCustomer.Text == "") ) ? null : (CChildDepart)cboxCustomer.SelectedItem);

                NewEarning(objChildDepart);

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
        /// <param name="objChildDepart">дочерний клиент</param>
        public void NewEarning(CChildDepart objChildDepart)
        {
            try
            {
                m_bNewObject = true;
                m_bDisableEvents = true;

                m_objSelectedEarning = new CEarning() { ChildDepart = objChildDepart };

                this.tableLayoutPanelBackground.SuspendLayout();

                ClearControls();

                editorEarningIsBonus.Checked = false;
                editorEarningDate.DateTime = System.DateTime.Today;
                editorEarningCompanyDst.SelectedItem = (m_objSelectedEarning.Company == null) ? null : editorEarningCompanyDst.Properties.Items.Cast<CCompany>().SingleOrDefault<CCompany>(x => x.ID.CompareTo(m_objSelectedEarning.Company.ID) == 0);
                editorEarningPaymentType.SelectedItem = (m_objSelectedEarning.PaymentType == null) ? ((editorEarningPaymentType.Properties.Items.Count > 0) ? editorEarningPaymentType.Properties.Items[0] : null) : editorEarningPaymentType.Properties.Items.Cast<CPaymentType>().SingleOrDefault<CPaymentType>(x => x.ID.CompareTo(m_objSelectedEarning.PaymentType.ID) == 0);
                editorEarningCurrency.SelectedItem = (m_objSelectedEarning.Currency == null) ? ((editorEarningCurrency.Properties.Items.Count > 0) ? (editorEarningCurrency.Properties.Items.Cast<CCurrency>().SingleOrDefault<CCurrency>(x=>x.IsMain == true)) : null) : editorEarningCurrency.Properties.Items.Cast<CCurrency>().SingleOrDefault<CCurrency>(x => x.ID.CompareTo(m_objSelectedEarning.Currency.ID) == 0);
                editorEarningType.SelectedItem = (m_objSelectedEarning.EarningType == null) ? ((editorEarningType.Properties.Items.Count > 0) ? editorEarningType.Properties.Items.Cast<CEarningType>().SingleOrDefault<CEarningType>(x => x.IsDefault == true) : null) : editorEarningType.Properties.Items.Cast<CEarningType>().SingleOrDefault<CEarningType>(x => x.ID.CompareTo(m_objSelectedEarning.EarningType.ID) == 0);

                editorEarningChildCust.SelectedItem = (m_objSelectedEarning.ChildDepart == null) ? null : editorEarningChildCust.Properties.Items.Cast<CChildDepart>().SingleOrDefault<CChildDepart>(x => x.ID.CompareTo(m_objSelectedEarning.ChildDepart.ID) == 0);

                LoadCustomerForChildDepart(m_objSelectedEarning.ChildDepart);


                if ((m_objSelectedEarning != null) && (m_objSelectedEarning.Customer != null))
                {
                    if (editorEarningCustomer.Properties.Items.Cast<CCustomer>().FirstOrDefault<CCustomer>(x => x.ID.CompareTo(m_objSelectedEarning.Customer.ID) == 0) == null)
                    {
                        editorEarningCustomer.Properties.Items.Add(m_objSelectedEarning.Customer);
                    }
                }

                editorEarningCustomer.SelectedItem = (m_objSelectedEarning.Customer == null) ? null : editorEarningCustomer.Properties.Items.Cast<CCustomer>().FirstOrDefault<CCustomer>(x => x.ID.CompareTo(m_objSelectedEarning.Customer.ID) == 0);

                if ((editorEarningChildCust.SelectedItem != null) && (editorEarningCustomer.SelectedItem == null))
                {
                    editorEarningCustomer.SelectedItem = ((editorEarningCustomer.Properties.Items.Count > 0) ? editorEarningCustomer.Properties.Items[0] : null);
                }

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
                { tabControl.SelectedTabPage = tabPageEditor; }
            }
            return;
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
                if (DevExpress.XtraEditors.XtraMessageBox.Show(String.Format("Подтвердите, пожалуйста, удаление платежа.\n\nДочерний клиент: {0}\n\nСумма: {1}", objEarning.ChildDepartCode, System.String.Format("{0,10:G}: ", objEarning.Value)), "Подтверждение",
                    System.Windows.Forms.MessageBoxButtons.YesNo, System.Windows.Forms.MessageBoxIcon.Question) == DialogResult.No) { return; }

                if (CEarningDataBaseModel.RemoveCEarningFromDataBase(objEarning.ID, m_objProfile, ref strErr) == true)
                {
                    m_objEarningList.Remove(objEarning);
                    gridControlEarningList.RefreshDataSource();

                    DevExpress.XtraEditors.XtraMessageBox.Show("Платёж удалён", "Информация",
                    System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Information);
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
                DeleteEarning( GetSelectedEarning() );
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
                        System.Windows.Forms.MessageBoxButtons.YesNoCancel, System.Windows.Forms.MessageBoxIcon.Question) != System.Windows.Forms.DialogResult.Yes)
                    {
                        return;
                    }
                }

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
                System.Int32 Earning_iKey = 0;
                System.Boolean Earning_IsBonus = editorEarningIsBonus.Checked;
                System.Guid Earning_CustomerGuid = ((editorEarningCustomer.SelectedItem == null) ? (System.Guid.Empty) : ((CCustomer)editorEarningCustomer.SelectedItem).ID);
                System.Guid Earning_CurrencyGuid = ((editorEarningCurrency.SelectedItem == null) ? (System.Guid.Empty) : ((CCurrency)editorEarningCurrency.SelectedItem).ID);
                System.Guid Earning_CompanyGuid = ((editorEarningCompanyDst.SelectedItem == null) ? (System.Guid.Empty) : ((CCompany)editorEarningCompanyDst.SelectedItem).ID);
                System.Guid PaymentType_Guid = ((editorEarningPaymentType.SelectedItem == null) ? (System.Guid.Empty) : ((CPaymentType)editorEarningPaymentType.SelectedItem).ID);
                System.Guid EarningType_Guid = ((editorEarningType.SelectedItem == null) ? (System.Guid.Empty) : ((CEarningType)editorEarningType.SelectedItem).ID);
                System.Guid ChildDepart_Guid = ((editorEarningChildCust.SelectedItem == null) ? (System.Guid.Empty) : ((CChildDepart)editorEarningChildCust.SelectedItem).ID);
                System.Decimal Earning_Value = editorEarningValue.Value;
                System.Decimal Earning_CurrencyRate = editorEarningCurRate.Value;
                System.Decimal Earning_CurrencyValue = editorEarningCurValue.Value;
                System.Guid Earning_Guid = ((m_bNewObject == true) ? System.Guid.Empty : m_objSelectedEarning.ID);

                System.Guid CompanyPayer_Guid = ((editorEarningCompanyPayer.SelectedItem == null) ? (System.Guid.Empty) : ((CCompany)editorEarningCompanyPayer.SelectedItem).ID);
                System.Guid AccountPlan_Guid = ((editorEarningAccountPlan.SelectedItem == null) ? (System.Guid.Empty) : ((CAccountPlan)editorEarningAccountPlan.SelectedItem).ID);
                System.Guid BudgetProjectSRC_Guid = ((editorEarningProjectSrc.SelectedItem == null) ? (System.Guid.Empty) : ((CBudgetProject)editorEarningProjectSrc.SelectedItem).ID);
                System.Guid BudgetProjectDST_Guid = ((editorEarningProjectDst.SelectedItem == null) ? (System.Guid.Empty) : ((CBudgetProject)editorEarningProjectDst.SelectedItem).ID);


                // проверка значений
                if (CEarningDataBaseModel.IsAllParametersValidInCEarning(Earning_CustomerGuid, Earning_CurrencyGuid,
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
                        bOkSave = CEarningDataBaseModel.AddNewCEarningToDataBase( Earning_CustomerGuid,
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
                        bOkSave = CEarningDataBaseModel.EditCEarningInDataBase(Earning_Guid, Earning_CustomerGuid,
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
                    m_objSelectedEarning.ChildDepart = editorEarningChildCust.Properties.Items.Cast<CChildDepart>().SingleOrDefault<CChildDepart>(x => x.ID.Equals(ChildDepart_Guid));
                    m_objSelectedEarning.Customer = editorEarningCustomer.Properties.Items.Cast<CCustomer>().FirstOrDefault<CCustomer>(x => x.ID.Equals(Earning_CustomerGuid));
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
                    m_objSelectedEarning.Saldo = (m_objSelectedEarning.Value - m_objSelectedEarning.Expense);

                    if (m_bNewObject == true)
                    {
                        m_objEarningList.Add(m_objSelectedEarning);
                    }
                    gridControlEarningList.RefreshDataSource();

                    editorEarningSaldo.Value = (m_objSelectedEarning.Value - editorEarningExpense.Value);
                    editorEarningValue.Value = m_objSelectedEarning.Value;
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
                            if ((objColumn.FieldName == "CurValue") || (objColumn.FieldName == "CurRate") ||
                                (objColumn.FieldName == "Value") || (objColumn.FieldName == "Expense") || (objColumn.FieldName == "Saldo")) 
                            {
                                worksheet.Cells[iCurrentRow, objColumn.VisibleIndex + 1].Style.Numberformat.Format = "# ##0.000";
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

        #region Журнал разноски платежей

        private void ViewEarningHistory(CEarning objEarning)
        {
            if (objEarning == null) { return; }
            m_bDisableEvents = true;
            m_bNewObject = false;
            try
            {
                m_objSelectedEarning = objEarning;

                txtEarningDateEarningHistory.Text = "";
                calcEarningValueEarningHistory.Value = 0;
                calcEarningSaldoEarningHistory.Value = 0;
                calcEarningExpenseEarningHistory.Value = 0;
                txtEarningPayerEarningHistory.Text = "";
                txtChildCustDebitDoc.Text = "";
                checkBonusDebitDoc.Checked = false;
                txtChildCustEarningHistory.Text = "";

                if (objEarning != null)
                {
                    txtEarningDateEarningHistory.Text = objEarning.Date.ToShortDateString();
                    calcEarningValueEarningHistory.Value = System.Convert.ToDecimal(objEarning.Value);
                    calcEarningSaldoEarningHistory.Value = System.Convert.ToDecimal(objEarning.Saldo);
                    calcEarningExpenseEarningHistory.Value = System.Convert.ToDecimal(objEarning.Expense);
                    txtEarningPayerEarningHistory.Text = objEarning.CustomerName;
                    txtChildCustDebitDoc.Text = objEarning.ChildDepartCode;
                    checkBonusDebitDoc.Checked = objEarning.IsBonusEarning;
                    txtChildCustEarningHistory.Text = objEarning.ChildDepartCode;
                }

                lblEarningInfoInEarningHistory.Text = strWaitCustomer;
                lblCaptionEarningHistoryList.Text = "История разноски платежа по долгам";
                //if (m_objSelectedEarning.Company != null)
                //{
                //    lblCaptionEarningHistoryList.Text += (String.Format("\t\tкомпания: {0}", m_objSelectedEarning.Company.Name));
                //}

                if (m_objSelectedEarning.Customer != null)
                {
                    lblCaptionEarningHistoryList.Text += (String.Format("\tдочерний клиент: {0}", m_objSelectedEarning.ChildDepartCode));
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
                tabControl.SelectedTabPage = m_objSelectedTabPage;

                if (tabControl.SelectedTabPage == tabPageViewer)
                {
                    if (m_objSelectedEarning != null)
                    {
                        System.Int32 iIndxSelectedObject = m_objEarningList.IndexOf(m_objEarningList.SingleOrDefault<CEarning>(x => x.ID.CompareTo(m_objSelectedEarning.ID) == 0));
                        if (iIndxSelectedObject >= 0)
                        {
                            gridViewEarningList.FocusedRowHandle = gridViewEarningList.GetRowHandle(iIndxSelectedObject);
                        }
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
                            if ((objColumn.FieldName == "Waybill_ShipDate") || (objColumn.FieldName == "Payment_OperDate") ||
                                (objColumn.FieldName == "Earning_BankDate"))
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
                m_objSelectedTabPage = tabPageViewer;
                ViewEarningHistory(SelectedEarning);
            }
            catch (System.Exception f)
            {
                SendMessageToLog("barBtnEarningHistoryView_Click. Текст ошибки: " + f.Message);
            }

            return;
        }

        private void btnEarningHistory_Click(object sender, EventArgs e)
        {
            try
            {
                m_objSelectedTabPage = tabPageEditor;
                ViewEarningHistory(SelectedEarning);
            }
            catch (System.Exception f)
            {
                SendMessageToLog("btnEarningHistory_Click. Текст ошибки: " + f.Message);
            }

            return;

        }

        #endregion

        #region Оплата

        /// <summary>
        /// Оплата документа
        /// </summary>
        /// <param name="objDebitDocument"></param>
        private void PayDebitDocument(CDebitDocument objDebitDocument)
        {
            try
            {
                if (objDebitDocument == null)
                {
                    DevExpress.XtraEditors.XtraMessageBox.Show("Программе не удалось определить документ для оплаты.", "Внимание!",
                        System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Warning);

                    return;
                }

                if (objDebitDocument.Waybill_Saldo == 0)
                {
                    DevExpress.XtraEditors.XtraMessageBox.Show("Докумен уже оплачен (сальдо равно нулю).", "Внимание!",
                        System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Warning);

                    return;
                }

                System.Guid ChildDepartID = System.Guid.Empty;

                if( m_enPayMode == enumPayMode.enEarningPayOneDocument)
                {
                    if ((m_objSelectedEarning == null) || (m_objSelectedEarning.ChildDepart == null))
                    {
                        DevExpress.XtraEditors.XtraMessageBox.Show("Программе не удалось определить дочернего клиента.", "Внимание!",
                            System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Warning);

                        return;
                    }
                    else
                    {
                        ChildDepartID = m_objSelectedEarning.ChildDepart.ID;
                    }
                }
                else if (m_enPayMode == enumPayMode.enAllEarningspayOneDocument)
                {
                    CChildDepart objSelectedChildDepart = m_objCustomerList.SingleOrDefault<CChildDepart>(x => x.Code.Equals(objDebitDocument.ChildCust_Code));
                    ChildDepartID = ((objSelectedChildDepart != null) ? objSelectedChildDepart.ID : System.Guid.Empty);
                }
                
                System.Decimal FINDED_MONEY = 0;
                System.String DOCUMENT_NUM = System.String.Empty;
                System.DateTime DOCUMENT_DATE = System.DateTime.MinValue;
                System.Decimal DOCUMENT_CURRENCYSALDO = 0;
                System.Decimal DOCUMENT_CURRENCYAMOUNTPAID = 0;
                System.Int32 ERROR_NUM = 0;
                System.String strErr = System.String.Empty;

                System.Int32 iRet = CPaymentDataBaseModel.PayDebitDocumentForm2(m_objProfile, null,
                    objDebitDocument.Waybill_Id, ChildDepartID, ref FINDED_MONEY,
                    ref DOCUMENT_NUM, ref DOCUMENT_DATE, ref DOCUMENT_CURRENCYSALDO, ref DOCUMENT_CURRENCYAMOUNTPAID, 
                    ref ERROR_NUM, ref strErr);

                if ((iRet == 0) && (ERROR_NUM == 0))
                {
                    CDebitDocument objItem = m_objDebitDocumentList.SingleOrDefault<CDebitDocument>(x => x.Waybill_Id.Equals(objDebitDocument.Waybill_Id));
                    if (objItem != null)
                    {
                        objItem.Waybill_Saldo = DOCUMENT_CURRENCYSALDO;
                        if (objItem.Waybill_Saldo == 0) { m_objDebitDocumentList.Remove(objItem); }

                        gridControlDebitDocList.RefreshDataSource();
                        SendMessageToLog(System.String.Format("Произведена оплата. Сумма: {0:### ### ##0}  Документ № {1}  от {2}  Сальдо док-та: {3:### ### ##0.00}", FINDED_MONEY, DOCUMENT_NUM, DOCUMENT_DATE, DOCUMENT_CURRENCYSALDO));

                        DevExpress.XtraEditors.XtraMessageBox.Show(System.String.Format("Произведена оплата. Сумма: {0:### ### ##0}  \nДокумент № {1}  от {2}\nСальдо док-та: {3:### ### ##0.00}", FINDED_MONEY, DOCUMENT_NUM, DOCUMENT_DATE, DOCUMENT_CURRENCYSALDO), "Внимание!",
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
        /// Оплата документа
        /// </summary>
        /// <param name="objDebitDocument">Накладная на оплату</param>
        /// <param name="objEarning">Платёж</param>
        private void PayDebitDocument(CDebitDocument objDebitDocument, CEarning objEarning)
        {
            try
            {
                if (objEarning == null)
                {
                    DevExpress.XtraEditors.XtraMessageBox.Show("Программе не удалось определить платёж.", "Внимание!",
                        System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Warning);

                    return;
                }

                if (objDebitDocument == null)
                {
                    DevExpress.XtraEditors.XtraMessageBox.Show("Программе не удалось определить документ для оплаты.", "Внимание!",
                        System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Warning);

                    return;
                }

                if (objDebitDocument.Waybill_Saldo == 0)
                {
                    DevExpress.XtraEditors.XtraMessageBox.Show("Докумен уже оплачен (сальдо равно нулю).", "Внимание!",
                        System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Warning);

                    return;
                }

                System.Decimal EARNING_SALDO = 0;
                System.Decimal EARNING_EXPENSE = 0;
                System.String DOCUMENT_NUM = System.String.Empty;
                System.DateTime DOCUMENT_DATE = System.DateTime.MinValue;
                System.Decimal DOCUMENT_CURRENCYSALDO = 0;
                System.Decimal DOCUMENT_CURRENCYAMOUNTPAID = 0;
                System.Int32 ERROR_NUM = 0;
                System.String strErr = System.String.Empty;

                System.Int32 iRet = CPaymentDataBaseModel.PayDebitDocumentForm2(m_objProfile, null,
                    objEarning.ID, objDebitDocument.Waybill_Id, ref EARNING_SALDO, ref EARNING_EXPENSE,
                    ref DOCUMENT_NUM, ref DOCUMENT_DATE, ref DOCUMENT_CURRENCYSALDO, ref DOCUMENT_CURRENCYAMOUNTPAID,
                    ref ERROR_NUM, ref strErr);

                if ((iRet == 0) && (ERROR_NUM == 0))
                {
                    CDebitDocument objItem = m_objDebitDocumentList.SingleOrDefault<CDebitDocument>(x => x.Waybill_Id.Equals(objDebitDocument.Waybill_Id));
                    if (objItem != null)
                    {
                        objItem.Waybill_Saldo = DOCUMENT_CURRENCYSALDO;
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
                        SendMessageToLog(System.String.Format("Произведена оплата. Документ № {0}  от {1} Сальдо: {2:### ### ##0}   Остаток платежа: {3:### ### ##0.00}", DOCUMENT_NUM, DOCUMENT_DATE, DOCUMENT_CURRENCYSALDO, EARNING_SALDO));

                        DevExpress.XtraEditors.XtraMessageBox.Show(System.String.Format("Произведена оплата. \nДокумент № {0}  от {1}\nСальдо: {2:### ### ##0}  \nОстаток платежа: {3:### ### ##0.00}", DOCUMENT_NUM, DOCUMENT_DATE, DOCUMENT_CURRENCYSALDO, EARNING_SALDO), "Внимание!",
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

        private void PayDebitDocuments(CEarning objEarning)
        {
            try
            {
                if (objEarning == null)
                {
                    DevExpress.XtraEditors.XtraMessageBox.Show("Программе не удалось определить платёж.", "Внимание!",
                        System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Warning);

                    return;
                }

                if (objEarning.Saldo == 0)
                {
                    DevExpress.XtraEditors.XtraMessageBox.Show("Платёж полностью разнесён по долгам.", "Внимание!",
                        System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Warning);

                    return;
                }


                System.Int32 ID_START = 0;
                System.Int32 ID_END = 0;
                System.Decimal EARNING_SALDO = 0;
                System.Decimal EARNING_EXPENSE = 0;
                
                System.Int32 ERROR_NUM = 0;
                System.String strErr = System.String.Empty;

                System.Int32 iRet = CPaymentDataBaseModel.PayDebitDocumentsForm2(m_objProfile, null, objEarning.ID,
                    ref ID_START, ref ID_END, ref EARNING_SALDO, ref EARNING_EXPENSE,
                    ref ERROR_NUM, ref strErr);

                if ((iRet == 0) && (ERROR_NUM == 0))
                {
                    if (objEarning != null)
                    {
                        m_objSelectedEarning.Expense = EARNING_EXPENSE;
                        m_objSelectedEarning.Saldo = EARNING_SALDO;
                    }

                    SendMessageToLog(System.String.Format("Результат операции: {0} Произведена оплата. Расход платежа: {1:### ### ##0.00}  Остаток платежа: {2:### ### ##0.00}", strErr, EARNING_EXPENSE, EARNING_SALDO));

                    DevExpress.XtraEditors.XtraMessageBox.Show(System.String.Format("Результат операции: {0}\nРасход платежа: {1:### ### ##0.00}\nОстаток платежа: {2:### ### ##0.00}", strErr, EARNING_EXPENSE, EARNING_SALDO), "Внимание!",
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
                SendMessageToLog("Ошибка оплаты. Текст ошибки: " + f.Message);
            }

            return;
        }

        private void btnPayDebitDocument_Click(object sender, EventArgs e)
        {
            try
            {
                if ((gridViewDebitDocumentList.RowCount == 0) || (gridViewDebitDocumentList.FocusedRowHandle < 0)) { return; }

                if ((((DevExpress.XtraGrid.Views.Grid.GridView)gridControlDebitDocList.MainView).RowCount > 0) &&
                    (((DevExpress.XtraGrid.Views.Grid.GridView)gridControlDebitDocList.MainView).FocusedRowHandle >= 0))
                {
                    System.Int32 iID = (System.Int32)(((DevExpress.XtraGrid.Views.Grid.GridView)gridControlDebitDocList.MainView)).GetFocusedRowCellValue("Waybill_Id");

                    CDebitDocument objSelectedDebitDocument = m_objDebitDocumentList.SingleOrDefault<CDebitDocument>(x => x.Waybill_Id.Equals(iID));

                    if( m_enPayMode == enumPayMode.enEarningPayOneDocument )
                    {
                        if( (objSelectedDebitDocument != null) && (SelectedEarning != null))
                        {
                            PayDebitDocument(objSelectedDebitDocument, SelectedEarning);
                        }
                    }
                    else if( m_enPayMode == enumPayMode.enAllEarningspayOneDocument )
                    {
                        if( objSelectedDebitDocument != null)
                        {
                            PayDebitDocument(objSelectedDebitDocument);
                        }
                    }

                    objSelectedDebitDocument = null;
                }

            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка оплаты. Текст ошибки: " + f.Message);
            }

            return;
        }

        private void btnPayment_Click(object sender, EventArgs e)
        {
            try
            {
                PayDebitDocuments(m_objSelectedEarning);

                editorEarningExpense.Value = m_objSelectedEarning.Expense;
                editorEarningSaldo.Value = m_objSelectedEarning.Saldo;
            }
            catch (System.Exception f)
            {
                SendMessageToLog("btnPayment_Click. Текст ошибки: " + f.Message);
            }

            return;
        }

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

        private void gridViewDebitDocumentListFocusedRowChanged()
        {
            try
            {
                switch (m_enPayMode)
                {
                    case enumPayMode.enAllEarningspayOneDocument:
                        {
                            btnPayDebitDocument.Enabled = (
                                (gridViewDebitDocumentList.RowCount > 0) && 
                                (gridViewDebitDocumentList.FocusedRowHandle >= 0) && 
                                ( System.Convert.ToDecimal( gridViewDebitDocumentList.GetFocusedRowCellValue("Waybill_Saldo") ) < 0 )
                                );
                            break;
                        }
                    case enumPayMode.enEarningPayOneDocument:
                        {
                            btnPayDebitDocument.Enabled = (
                                (m_objSelectedEarning != null) && 
                                (m_objSelectedEarning.Saldo > 0) && 
                                (gridViewDebitDocumentList.RowCount > 0) && 
                                (gridViewDebitDocumentList.FocusedRowHandle >= 0) && 
                                ( System.Convert.ToDecimal( gridViewDebitDocumentList.GetFocusedRowCellValue("Waybill_Saldo") ) < 0 )
                            );
                            break;
                        }
                    default:
                        {
                            btnPayDebitDocument.Enabled = false;
                            break;
                        }
                }
            }
            catch (System.Exception f)
            {
                SendMessageToLog("FocusedRowChanged. Текст ошибки: " + f.Message);
            }

            return;
        }

        private void gridViewDebitDocumentList_FocusedRowChanged(object sender, DevExpress.XtraGrid.Views.Base.FocusedRowChangedEventArgs e)
        {
            try
            {
                gridViewDebitDocumentListFocusedRowChanged();
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
                gridViewDebitDocumentListFocusedRowChanged();
            }
            catch (System.Exception f)
            {
                SendMessageToLog("gridViewDebitDocumentList_FocusedRowChanged. Текст ошибки: " + f.Message);
            }

            return;
        }

        private void ShowDebitDocumentList()
        {
            try
            {
                m_enPayMode = enumPayMode.enAllEarningspayOneDocument;

                tableLayoutPanelDebitDocuments.ColumnStyles[0].Width = 0;
                cboxCustomerDebitDocument.SelectedItem = null;
                cboxCustomerDebitDocument.Properties.Items.Clear();

                cboxChildCustomerDebitDocument.SelectedItem = null;
                cboxChildCustomerDebitDocument.Properties.Items.Clear();
                cboxChildCustomerDebitDocument.Properties.Items.AddRange(cboxCustomer.Properties.Items.Cast<CChildDepart>().ToList<CChildDepart>());

                lblCaptionDebitDocumentList.Text = STR_DebitDocumentList;
                lblEarningInfoInpayDebitDocument.Text = "";
                pictureBoxInfoInDebitDocList.Image = ERPMercuryBankStatement.Properties.Resources.SpreadSheet_Total;

                m_objDebitDocumentList.Clear();
                gridControlDebitDocList.RefreshDataSource();

                tabControl.SelectedTabPage = tabPageDebitDocList;
                tabPageDebitDocList.Refresh();
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

        /// <summary>
        /// Отображает журнал документов на оплату
        /// </summary>
        /// <param name="objEarning">платеж</param>
        public void ShowDebitDocumentList(CEarning objEarning)
        {
            if (objEarning == null) { return; }
            m_bDisableEvents = true;
            m_bNewObject = false;
            m_enPayMode = enumPayMode.enEarningPayOneDocument;

            try
            {
                m_objSelectedEarning = objEarning;

                txtEarningDateDebitDoc.Text = "";
                txtChildCustDebitDoc.Text = "";
                txtEarningPayerDebitDoc.Text = "";
                calcEarningValueDebitDoc.Value = 0;
                calcEarningSaldoDebitDoc.Value = 0;
                calcEarningExpenseDebitDoc.Value = 0;
                editorEarningIsBonusDebitDoc.Checked = false;

                if (objEarning != null)
                {
                    txtEarningDateDebitDoc.Text = objEarning.Date.ToShortDateString();
                    txtChildCustDebitDoc.Text = objEarning.ChildDepartCode;
                    txtEarningPayerDebitDoc.Text = objEarning.CustomerName;

                    calcEarningValueDebitDoc.Value = System.Convert.ToDecimal(objEarning.Value);
                    calcEarningSaldoDebitDoc.Value = System.Convert.ToDecimal(objEarning.Saldo);
                    calcEarningExpenseDebitDoc.Value = System.Convert.ToDecimal(objEarning.Expense);
                    editorEarningIsBonusDebitDoc.Checked = objEarning.IsBonusEarning;
                }

                if (objEarning.ChildDepart != null)
                {
                    cboxChildCustomerDebitDocument.Properties.Items.Clear();
                    cboxChildCustomerDebitDocument.Properties.Items.Add(objEarning.ChildDepart);
                    cboxChildCustomerDebitDocument.SelectedItem = cboxChildCustomerDebitDocument.Properties.Items[0];
                }

                if (m_objSelectedEarning.Customer != null)
                {
                    lblCaptionDebitDocumentList.Text = (String.Format("Журнал документов на оплату{0}", String.Format("\tдочерний клиент: {0}", m_objSelectedEarning.ChildDepartCode)));
                }

                tableLayoutPanelDebitDocuments.ColumnStyles[0].Width = INT_tableLayoutPanelDebitDocumentsColumnStyles0Width;
                pictureBoxInfoInDebitDocList.Image = ERPMercuryBankStatement.Properties.Resources.SpreadSheet_Total;
                lblEarningInfoInpayDebitDocument.Text = (String.Format("Остаток платежа:\t{0:### ### ##0.00}", objEarning.Saldo));

                m_objDebitDocumentList.Clear();
                gridControlDebitDocList.RefreshDataSource();


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

                if (objPaidDocument.Waybill_AmountPaid == 0)
                {
                    DevExpress.XtraEditors.XtraMessageBox.Show("Оплата по документу полностью отсторирована.", "Внимание!",
                        System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Information);

                    return;
                }

                Cursor = Cursors.WaitCursor;

                System.Int32 Waybill_Id = objPaidDocument.Waybill_Id;
                System.Decimal AMOUNT = calcDePaySum.Value;
                System.DateTime DATELASTPAID = dateDePayDate.DateTime;
                System.Decimal DEC_AMOUNT = 0;
                System.Decimal WAYBILL_AMOUNTPAID = 0;
                System.Decimal WAYBILL_SALDO = 0;

                System.Int32 ERROR_NUM = 0;
                System.String strErr = System.String.Empty;

                System.Int32 iRet = CPaymentDataBaseModel.DePayDebitDocumentForm2(m_objProfile, null,
                    System.Guid.Empty, Waybill_Id, AMOUNT, DATELASTPAID,
                    ref DEC_AMOUNT, ref WAYBILL_AMOUNTPAID, ref WAYBILL_SALDO,
                    ref ERROR_NUM, ref strErr);
                if ((iRet == 0) && (ERROR_NUM == 0))
                {
                    CPaidDocument objItem = m_objPaidDocumentList.SingleOrDefault<CPaidDocument>(x => x.Waybill_Id.Equals(objPaidDocument.Waybill_Id));
                    if (objItem != null)
                    {
                        System.Int32 iIndxItem = m_objPaidDocumentList.IndexOf(objItem);

                        objItem.Waybill_AmountPaid = WAYBILL_AMOUNTPAID;
                        objItem.Waybill_Saldo = WAYBILL_SALDO;
                        if (objItem.Waybill_AmountPaid == 0)
                        {
                            m_objPaidDocumentList.Remove(objItem);
                        }

                        LoadInfoForDePayOperation(objItem);

                        gridControlPaidDocumentList.RefreshDataSource();

                        if (gridViewPaidDocumentList.RowCount > 0)
                        {
                            iIndxItem--;
                            if (iIndxItem < 0) { iIndxItem = 0; }
                            if (iIndxItem < gridViewPaidDocumentList.RowCount)
                            {
                                gridViewPaidDocumentList.FocusedRowHandle = iIndxItem;
                            }
                        }
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
            finally
            {
                Cursor = Cursors.Default;
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

        private void cboxChildCustomerDebitDocument_SelectedValueChanged(object sender, EventArgs e)
        {
            try
            {
                cboxCustomerDebitDocument.SelectedItem = null;
                cboxCustomerDebitDocument.Properties.Items.Clear();

                if (cboxChildCustomerDebitDocument.SelectedItem != null)
                {
                    System.String strErr = "";

                    List<CCustomer> objCustomerListForChildDepart = CCustomer.GetCustomerListForChildDepart(m_objProfile,
                        null, ((CChildDepart)cboxChildCustomerDebitDocument.SelectedItem).ID, ref strErr);

                    if (objCustomerListForChildDepart != null)
                    {
                        cboxCustomerDebitDocument.Properties.Items.AddRange(objCustomerListForChildDepart);
                    }
                }

                //cboxCustomerDebitDocument.SelectedItem = ((cboxCustomerDebitDocument.Properties.Items.Count > 0) ? cboxCustomerDebitDocument.Properties.Items[0] : null);
            }
            catch (System.Exception f)
            {
                SendMessageToLog("cboxChildCustomerDebitDocument_SelectedValueChanged. Текст ошибки: " + f.Message);
            }

            return;
        }
        private void mitmsPayDebitDocument_Click(object sender, EventArgs e)
        {
            try
            {
                if (SelectedEarning == null) { return; }
                ShowDebitDocumentList(SelectedEarning);
            }
            catch (System.Exception f)
            {
                SendMessageToLog("mitmsPayDebitDocument_Click. Текст ошибки: " + f.Message);
            }

            return;
        }

        #endregion

        #region Контекстное меню и кнопки на панели управления

        private void contextMenuStripEarningList_Opened(object sender, EventArgs e)
        {
            try
            {
                mitmsPayDebitDocument.Enabled = ((SelectedEarning != null) && (SelectedEarning.Saldo > 0) );
                mitmsPayDebitDocuments.Enabled = mitmsPayDebitDocument.Enabled;

                mitmsEarningHistory.Enabled = (gridViewEarningList.FocusedRowHandle >= 0);
            }
            catch (System.Exception f)
            {
                SendMessageToLog("contextMenuStripEarningList_Opened. Текст ошибки: " + f.Message);
            }

            return;
        }

        private void btnRefreshDebitDocumentList_Click(object sender, EventArgs e)
        {
            try
            {
                //if (cboxChildCustomerDebitDocument.SelectedItem == null)
                //{
                //    DevExpress.XtraEditors.XtraMessageBox.Show("Укажите, пожалуйста, дочернего клиента!", "Информация",
                //        System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Information);

                //    return;
                //}
                btnRefreshDebitDocumentList.Enabled = false;
                pictureBoxInfoInDebitDocList.Image = ERPMercuryBankStatement.Properties.Resources.Warning_32;
                lblEarningInfoInpayDebitDocument.Text = strWaitCustomer;

                panel1.Refresh();

                StartThreadLoadDebitDocumentList();
            }
            catch (System.Exception f)
            {
                SendMessageToLog("btnRefreshDebitDocumentList_Click. Текст ошибки: " + f.Message);
            }

            return;
        }

        private void mitmsPayDebitDocuments_Click(object sender, EventArgs e)
        {
            try
            {
                m_objSelectedEarning = SelectedEarning;

                if (m_objSelectedEarning != null)
                {
                    m_enPayMode = enumPayMode.enEarningPayAllDocuments;

                    PayDebitDocuments(m_objSelectedEarning);

                    gridControlEarningList.RefreshDataSource();
                    ShowEarningProperties(m_objSelectedEarning);
                }
            }
            catch (System.Exception f)
            {
                SendMessageToLog("barBtnDebitDocumentList_Click. Текст ошибки: " + f.Message);
            }

            return;

        }

        private void barBtnDebitDocumentList_Click(object sender, EventArgs e)
        {
            try
            {
                m_enPayMode = enumPayMode.enAllEarningspayOneDocument;

                ShowDebitDocumentList();

            }
            catch (System.Exception f)
            {
                SendMessageToLog("barBtnDebitDocumentList_Click. Текст ошибки: " + f.Message);
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
                            if (objColumn.FieldName == "Date")
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
                            if (objColumn.FieldName == "Waybill_ShipDate")
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

        private void cboxChildCustomerReportDebtor_KeyPress(object sender, KeyPressEventArgs e)
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
                DevExpress.XtraEditors.XtraMessageBox.Show("cboxChildCustomerReportDebtor_KeyPress.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally
            {
            }
            return;
        }
        #endregion


    }

    public class CEarningEditor : PlugIn.IClassTypeView
    {
        public override void Run(UniXP.Common.MENUITEM objMenuItem, System.String strCaption)
        {
            frmCEarning obj = new frmCEarning(objMenuItem) { Text = strCaption, MdiParent = objMenuItem.objProfile.m_objMDIManager.MdiParent, Visible = true };
        }


    }

}
