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
    public partial class frmCustomerInitialDebtPaymentType_2 : DevExpress.XtraEditors.XtraForm
    {
        #region Свойства
        private UniXP.Common.CProfile m_objProfile;
        private UniXP.Common.MENUITEM m_objMenuItem;
        private System.Boolean m_bOnlyView;
        private System.Boolean m_bIsChanged;
        private System.Boolean m_bDisableEvents;
        private System.Boolean m_bNewObject;
        private enumPaymentType m_enumPaymentType;
        private List<CChildDepart> m_objCustomerList;
        private List<CCustomerInitialDebt> m_objCustomerInitialDebtList;
        private CCustomerInitialDebt m_objSelectedCustomerInitialDebt;
        private CPaymentType m_objPaymentTypeDefault;

        private DevExpress.XtraGrid.Views.Base.ColumnView ColumnView
        {
            get { return gridControlEarningList.MainView as DevExpress.XtraGrid.Views.Base.ColumnView; }
        }
        /// <summary>
        /// Возвращает ссылку на выбранную в списке задолженность
        /// </summary>
        /// <returns>ссылка на задолженность</returns>
        private CCustomerInitialDebt SelectedCustomerInitialDebt
        {
            get
            {
                CCustomerInitialDebt objRet = null;
                try
                {
                    if ((((DevExpress.XtraGrid.Views.Grid.GridView)gridControlEarningList.MainView).RowCount > 0) &&
                        (((DevExpress.XtraGrid.Views.Grid.GridView)gridControlEarningList.MainView).FocusedRowHandle >= 0))
                    {
                        System.Guid uuidID = (System.Guid)(((DevExpress.XtraGrid.Views.Grid.GridView)gridControlEarningList.MainView)).GetFocusedRowCellValue("ID");

                        objRet = m_objCustomerInitialDebtList.SingleOrDefault<CCustomerInitialDebt>(x => x.ID.CompareTo(uuidID) == 0);
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

        // потоки
        public System.Threading.Thread ThreadLoadCustomerList { get; set; }
        public System.Threading.Thread ThreadLoadCustomerInitialDebtList { get; set; }

        public System.Threading.ManualResetEvent EventStopThread { get; set; }
        public System.Threading.ManualResetEvent EventThreadStopped { get; set; }

        public delegate void LoadCustomerListDelegate(List<CChildDepart> objCustomerList, System.Int32 iRowCountInLis);
        public LoadCustomerListDelegate m_LoadCustomerListDelegate;

        public delegate void LoadCustomerInitialDebtListDelegate(List<CCustomerInitialDebt> objCustomerInitialDebtList, System.Int32 iRowCountInList);
        public LoadCustomerInitialDebtListDelegate m_LoadCustomerInitialDebtListDelegate;
      
        private const System.Int32 iThreadSleepTime = 1000;
        private const System.String strWaitCustomer = "ждите... идет заполнение списка";
        private System.Boolean m_bThreadFinishJob;
        private const System.String strRegistryTools = "\\CCustomerInitalDebtListTools\\";
        private const System.Int32 iWaitingpanelIndex = 0;
        private const System.Int32 iWaitingpanelHeight = 35;
        private const System.String m_strModeReadOnly = "Режим просмотра";
        private const System.String m_strModeEdit = "Режим редактирования";
        private const int INT_tableLayoutPanelDebitDocumentsColumnStyles0Width = 220;
        private const string STR_DebitDocumentList = "Журнал документов на оплату";

        #endregion

        #region Конструктор
        public frmCustomerInitialDebtPaymentType_2(UniXP.Common.MENUITEM objMenuItem)
        {
            InitializeComponent();

            m_objMenuItem = objMenuItem;
            m_objProfile = objMenuItem.objProfile;
            m_bThreadFinishJob = false;
            m_objCustomerList = new List<CChildDepart>();
            m_objCustomerInitialDebtList = new List<CCustomerInitialDebt>();
            m_objSelectedCustomerInitialDebt = null;
            m_enumPaymentType = enumPaymentType.PaymentForm2;
            m_objPaymentTypeDefault = null;

            AddGridColumns();
            dtBeginDate.DateTime = new DateTime(System.DateTime.Today.Year-15, System.DateTime.Today.Month, 1);
            dtEndDate.DateTime = System.DateTime.Today;
            RestoreLayoutFromRegistry();

            SearchProcessWoring.Visible = false;
            tabControl.ShowTabHeader = DevExpress.Utils.DefaultBoolean.False;
            m_bOnlyView = false;
            m_bIsChanged = false;
            m_bDisableEvents = false;
            m_bNewObject = false;

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

        #region Открытие формы
        private void frmCustomerInitialDebtPaymentType_2_Shown(object sender, EventArgs e)
        {
            try
            {
                RestoreLayoutFromRegistry();

                LoadComboBox();

                StartThreadLoadCustomerInitialDebtList();

                StartThreadLoadCustomerList();

            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("frmCustomerInitialDebtPaymentType_2_Shown().\n\nТекст ошибки: " + f.Message, "Ошибка",
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
            AddGridColumn(ColumnView, "Date", "Дата");
            AddGridColumn(ColumnView, "CompanyCode", "Компания");
            AddGridColumn(ColumnView, "ChildDepartCode", "Код дочернего");
            AddGridColumn(ColumnView, "ChildDepartName", "Дочерний клиент");
            AddGridColumn(ColumnView, "CurrencyCode", "Валюта");
            AddGridColumn(ColumnView, "InitialDebt", "Сумма задолженности");
            AddGridColumn(ColumnView, "AmountPaid", "Оплачено");
            AddGridColumn(ColumnView, "Saldo", "Сальдо");
            AddGridColumn(ColumnView, "InterbaseID", "УИ");

            foreach (DevExpress.XtraGrid.Columns.GridColumn objColumn in ColumnView.Columns)
            {
                if (objColumn.FieldName == "ID")
                {
                    objColumn.Visible = false;
                }

                if ((objColumn.FieldName == "InitialDebt") || (objColumn.FieldName == "AmountPaid") || (objColumn.FieldName == "Saldo"))
                {
                    objColumn.DisplayFormat.FormatType = DevExpress.Utils.FormatType.Numeric;
                    objColumn.DisplayFormat.FormatString = "### ### ##0.00";
                    objColumn.SummaryItem.FieldName = objColumn.FieldName;
                    objColumn.SummaryItem.DisplayFormat = "Итого: {0:### ### ##0.00}";
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
                m_LoadCustomerListDelegate = new LoadCustomerListDelegate(LoadCustomerList);
                m_objCustomerList.Clear();

                barBtnAdd.Enabled = false;
                barBtnEdit.Enabled = false;
                barBtnDelete.Enabled = false;

                barBtnRefresh.Enabled = false;

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
                List<CChildDepart> objCustomerList = CChildDepart.GetChildDepartList(m_objProfile, null, System.Guid.Empty);


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
                if ((objCustomerList != null) && (objCustomerList.Count > 0) && (cboxCustomer.Properties.Items.Count < iRowCountInList))
                {
                    cboxCustomer.Properties.Items.AddRange(objCustomerList);
                    editorEarningChildCust.Properties.Items.AddRange(objCustomerList);
                    m_objCustomerList.AddRange(objCustomerList);
                }
                else
                {
                    cboxCustomer.Text = "";

                    barBtnAdd.Enabled = !m_bOnlyView;
                    barBtnEdit.Enabled = (gridViewEarningList.FocusedRowHandle >= 0);
                    barBtnDelete.Enabled = ((!m_bOnlyView) && (gridViewEarningList.FocusedRowHandle >= 0) && (System.Convert.ToDecimal(gridViewEarningList.GetRowCellValue(gridViewEarningList.FocusedRowHandle, "Expense")) == 0));
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
                StartThreadLoadCustomerInitialDebtList();
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
                if ((e.KeyChar == (char)Keys.Enter) && (barBtnRefresh.Visible == true))
                {
                    StartThreadLoadCustomerInitialDebtList();
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
        /// Стартует поток, в котором загружается список задолженностей
        /// </summary>
        public void StartThreadLoadCustomerInitialDebtList()
        {
            try
            {
                // инициализируем делегаты
                m_LoadCustomerInitialDebtListDelegate = new LoadCustomerInitialDebtListDelegate(LoadCustomerInitialDebtListInGrid);
                m_objCustomerInitialDebtList.Clear();

                barBtnAdd.Enabled = false;
                barBtnEdit.Enabled = false;
                barBtnDelete.Enabled = false;
                barBtnRefresh.Enabled = false;

                gridControlEarningList.DataSource = null;
                SearchProcessWoring.Visible = true;
                SearchProcessWoring.Refresh();

                gridControlEarningList.MouseDoubleClick -= new MouseEventHandler(gridControlEarningList_MouseDoubleClick);

                // запуск потока
                System.DateTime dtBeginDate = this.dtBeginDate.DateTime;
                System.DateTime dtEndDate = this.dtEndDate.DateTime;
                System.Guid uuidCustomerId = (((cboxCustomer.SelectedItem == null) || (System.Convert.ToString(cboxCustomer.SelectedItem) == "") || (cboxCustomer.Text == strWaitCustomer)) ? System.Guid.Empty : ((CChildDepart)cboxCustomer.SelectedItem).ID);
                System.Guid uuidCompanyId = (((cboxCompany.SelectedItem == null) || (System.Convert.ToString(cboxCompany.SelectedItem) == "") || (cboxCompany.Text == strWaitCustomer)) ? System.Guid.Empty : ((CCompany)cboxCompany.SelectedItem).ID);
                System.Guid uuidPaymentTypeId = ((m_objPaymentTypeDefault == null) ? System.Guid.Empty : m_objPaymentTypeDefault.ID);

                this.ThreadLoadCustomerInitialDebtList = new System.Threading.Thread(unused => LoadCustomerInitialDebtListInThread(dtBeginDate,
                    dtEndDate, uuidCustomerId, uuidCompanyId, uuidPaymentTypeId));

                this.ThreadLoadCustomerInitialDebtList.Start();
                Thread.Sleep(1000);

            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("StartThreadLoadCustomerInitialDebtList().\n\nТекст ошибки: " + f.Message, "Ошибка",
                    System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }

            return;
        }


        /// <summary>
        /// Загружает список задолженностей
        /// </summary>
        public void LoadCustomerInitialDebtListInThread(System.DateTime dtBeginDate, System.DateTime dtEndDate,
            System.Guid uuidCustomerId, System.Guid uuidCompanyId, System.Guid uuidPaymentTypeId)
        {
            try
            {
                System.String strErr = "";
                List<CCustomerInitialDebt> objCustomerInitialDebtList = CCustomerInitialDebtDataBaseModel.GetCustomerInitialDebtList(m_objProfile,
                    null, dtBeginDate, dtEndDate, uuidPaymentTypeId, uuidCompanyId, uuidCustomerId, System.Guid.Empty, ref strErr);

                if (uuidCustomerId.CompareTo(System.Guid.Empty) != 0)
                {
                    objCustomerInitialDebtList = objCustomerInitialDebtList.Where<CCustomerInitialDebt>(x => x.Customer.ID.CompareTo(uuidCustomerId) == 0).ToList<CCustomerInitialDebt>();
                }

                if (uuidCompanyId.CompareTo(System.Guid.Empty) != 0)
                {
                    objCustomerInitialDebtList = objCustomerInitialDebtList.Where<CCustomerInitialDebt>(x => x.Company.ID.CompareTo(uuidCompanyId) == 0).ToList<CCustomerInitialDebt>();
                }

                List<CCustomerInitialDebt> objAddCustomerInitialDebtList = new List<CCustomerInitialDebt>();
                if ((objCustomerInitialDebtList != null) && (objCustomerInitialDebtList.Count > 0))
                {
                    System.Int32 iRecCount = 0;
                    System.Int32 iRecAllCount = 0;
                    foreach (CCustomerInitialDebt objCustomerInitialDebt in objCustomerInitialDebtList)
                    {
                        objAddCustomerInitialDebtList.Add(objCustomerInitialDebt);
                        iRecCount++;
                        iRecAllCount++;

                        if (iRecCount == 1000)
                        {
                            iRecCount = 0;
                            Thread.Sleep(1000);
                            this.Invoke(m_LoadCustomerInitialDebtListDelegate, new Object[] { objAddCustomerInitialDebtList, iRecAllCount });
                            objAddCustomerInitialDebtList.Clear();
                        }
                    }
                    if (iRecCount != 1000)
                    {
                        iRecCount = 0;
                        this.Invoke(m_LoadCustomerInitialDebtListDelegate, new Object[] { objAddCustomerInitialDebtList, iRecAllCount });
                        objAddCustomerInitialDebtList.Clear();
                    }

                }

                objCustomerInitialDebtList = null;
                objAddCustomerInitialDebtList = null;
                this.Invoke(m_LoadCustomerInitialDebtListDelegate, new Object[] { null, 0 });
                this.m_bThreadFinishJob = true;
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("LoadCustomerInitialDebtListInThread.\n\nТекст ошибки: " + f.Message, "Ошибка",
                   System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }
            finally
            {
            }
            return;
        }

        /// <summary>
        /// загружает в журнал список задолженностей
        /// </summary>
        /// <param name="objCustomerInitialDebtList">список задолженностей</param>
        /// <param name="iRowCountInList">количество строк, которые требуется загрузить в журнал</param>
        private void LoadCustomerInitialDebtListInGrid(List<CCustomerInitialDebt> objCustomerInitialDebtList, System.Int32 iRowCountInList)
        {
            try
            {
                if ((objCustomerInitialDebtList != null) && (objCustomerInitialDebtList.Count > 0) && (gridViewEarningList.RowCount < iRowCountInList))
                {
                    m_objCustomerInitialDebtList.AddRange(objCustomerInitialDebtList);
                    if (gridControlEarningList.DataSource == null)
                    {
                        gridControlEarningList.DataSource = m_objCustomerInitialDebtList;
                    }
                    gridControlEarningList.RefreshDataSource();
                }
                else
                {
                    Thread.Sleep(1000);
                    SearchProcessWoring.Visible = false;

                    barBtnAdd.Enabled = !m_bOnlyView;
                    barBtnEdit.Enabled = (gridViewEarningList.FocusedRowHandle >= 0);
                    barBtnDelete.Enabled = ((!m_bOnlyView) && (gridViewEarningList.FocusedRowHandle >= 0));
                    barBtnRefresh.Enabled = true;
                    gridControlEarningList.RefreshDataSource();

                    foreach (DevExpress.XtraGrid.Columns.GridColumn objColumn in gridViewEarningList.Columns)
                    {
                        if (objColumn.Visible == true)
                        {
                            objColumn.BestFit();
                        }
                    }


                    Cursor = Cursors.Default;

                    gridControlEarningList.MouseDoubleClick += new MouseEventHandler(gridControlEarningList_MouseDoubleClick);
                }
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("LoadCustomerInitialDebtListInGrid.\n\nТекст ошибки: " + f.Message, "Ошибка",
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
            try
            {
                cboxCustomer.Properties.Items.Clear();
                cboxCustomer.Properties.Items.Add(new CChildDepart());

                cboxCompany.Properties.Items.Clear();
                editorEarningCompany.Properties.Items.Clear();

                cboxCompany.Properties.Items.AddRange(CCompany.GetCompanyList(m_objProfile, null));
                //cboxCompany.SelectedItem = ((cboxCompany.Properties.Items.Count > 0) ? cboxCompany.Properties.Items[0] : null);

                editorEarningCompany.Properties.Items.AddRange(cboxCompany.Properties.Items);

                List<CCurrency> objCurrencylist = CCurrency.GetCurrencyList(m_objProfile, null);
                editorEarningCurrency.Properties.Items.Clear();

                if (objCurrencylist != null)
                {
                    // идентификатор валюты учёта
                    CCurrency objCurrenyAccounting = objCurrencylist.SingleOrDefault<CCurrency>(x => x.IsMain);

                    // список валют для платежа
                    if (m_enumPaymentType == enumPaymentType.PaymentForm1)
                    {
                        editorEarningCurrency.Properties.Items.AddRange(objCurrencylist.Where<CCurrency>(x => x.IsNationalCurrency).ToList<CCurrency>());
                    }
                    else
                    {
                        editorEarningCurrency.Properties.Items.AddRange(objCurrencylist.Where<CCurrency>(x => x.IsNationalCurrency == false).ToList<CCurrency>());
                    }
                }

                editorEarningPaymentType.Properties.Items.Clear();
                if (m_enumPaymentType == enumPaymentType.PaymentForm1)
                {
                    editorEarningPaymentType.Properties.Items.AddRange(CPaymentType.GetPaymentTypeList(m_objProfile, null, System.Guid.Empty).Where<CPaymentType>(x => x.Payment_Id.Equals(1)).ToList<CPaymentType>());
                }
                else
                {
                    editorEarningPaymentType.Properties.Items.AddRange(CPaymentType.GetPaymentTypeList(m_objProfile, null, System.Guid.Empty).Where<CPaymentType>(x => x.Payment_Id.Equals(2)).ToList<CPaymentType>());
                }

                List<CPaymentType> objPaymentTypeList = CPaymentType.GetPaymentTypeList(m_objProfile, null, System.Guid.Empty);
                if ((objPaymentTypeList != null) && (objPaymentTypeList.Count > 0))
                {
                    m_objPaymentTypeDefault = objPaymentTypeList.SingleOrDefault<CPaymentType>(x => x.Payment_Id == System.Convert.ToInt32(enumPaymentType.PaymentForm2));
                }
                objPaymentTypeList = null;


            }
            catch (System.Exception f)
            {
                SendMessageToLog("LoadComboBox. Текст ошибки: " + f.Message);
            }
            return;
        }

        #endregion

        #region Свойства задолженности
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
        /// Возвращает ссылку на выбранную в списке задолженность
        /// </summary>
        /// <returns>ссылка на задолженность</returns>
        private CCustomerInitialDebt GetSelectedEarning()
        {
            CCustomerInitialDebt objRet = null;
            try
            {
                if ((((DevExpress.XtraGrid.Views.Grid.GridView)gridControlEarningList.MainView).RowCount > 0) &&
                    (((DevExpress.XtraGrid.Views.Grid.GridView)gridControlEarningList.MainView).FocusedRowHandle >= 0))
                {
                    System.Guid uuidID = (System.Guid)(((DevExpress.XtraGrid.Views.Grid.GridView)gridControlEarningList.MainView)).GetFocusedRowCellValue("ID");

                    objRet = m_objCustomerInitialDebtList.SingleOrDefault<CCustomerInitialDebt>(x => x.ID.CompareTo(uuidID) == 0);
                }
            }//try
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка поиска выбранной задолженности. Текст ошибки: " + f.Message);
            }
            finally
            {
            }

            return objRet;
        }

        /// <summary>
        /// Определяет, какая задолженность выбрана в журнале и отображает её свойства
        /// </summary>
        private void FocusedEarningChanged()
        {
            try
            {
                ShowEarningProperties(GetSelectedEarning());

                barBtnAdd.Enabled = !m_bOnlyView;
                barBtnEdit.Enabled = (gridViewEarningList.FocusedRowHandle >= 0);
                barBtnDelete.Enabled = ((!m_bOnlyView) && (gridViewEarningList.FocusedRowHandle >= 0) && (System.Convert.ToDecimal(gridViewEarningList.GetRowCellValue(gridViewEarningList.FocusedRowHandle, "Expense")) == 0));

                mitmsNewEarning.Enabled = barBtnAdd.Enabled;
                mitmsEditEarning.Enabled = barBtnEdit.Enabled;
                mitmsDeleteEarning.Enabled = barBtnDelete.Enabled;

            }
            catch (System.Exception f)
            {
                SendMessageToLog("Отображение свойств задолженности. Текст ошибки: " + f.Message);
            }

            return;
        }

        /// <summary>
        /// Отображает свойства задолженности
        /// </summary>
        /// <param name="objEarning">задолженность</param>
        private void ShowEarningProperties(CCustomerInitialDebt objEarning)
        {
            try
            {
                this.tableLayoutPanelEarningProperties.SuspendLayout();

                txtEarningChildDepartCode.Text = "";
                txtEarningDate.Text = "";
                txtEarningPayer.Text = "";
                txtEarningCurrency.Text = "";
                calcEarningCurrencyValue.Value = 0;
                calcEarningExpense.Value = 0;
                calcEarningSaldo.Value = 0;

                if (objEarning != null)
                {
                    txtEarningChildDepartCode.Text = objEarning.ChildDepartCode;
                    txtEarningDate.Text = objEarning.Date.ToShortDateString();
                    txtEarningPayer.Text = objEarning.CustomerName;
                    txtEarningCurrency.Text = objEarning.CurrencyCode;
                    calcEarningCurrencyValue.Value = objEarning.InitialDebt;
                    calcEarningExpense.Value = objEarning.AmountPaid;
                    calcEarningSaldo.Value = objEarning.Saldo;
                }

                this.tableLayoutPanelEarningProperties.ResumeLayout(false);
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Отображение свойств задолженности. Текст ошибки: " + f.Message);
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

                editorEarningCompany.Properties.ReadOnly = bSet;
                editorEarningPaymentType.Properties.ReadOnly = bSet;
                editorEarningCurValue.Properties.ReadOnly = bSet;
                editorEarningCustomer.Properties.ReadOnly = bSet;

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
                editorEarningCompany.Properties.Appearance.BackColor = ((editorEarningCompany.SelectedItem == null) ? System.Drawing.Color.Tomato : System.Drawing.Color.White);
                editorEarningCurrency.Properties.Appearance.BackColor = ((editorEarningCurrency.SelectedItem == null) ? System.Drawing.Color.Tomato : System.Drawing.Color.White);
                editorEarningPaymentType.Properties.Appearance.BackColor = ((editorEarningPaymentType.SelectedItem == null) ? System.Drawing.Color.Tomato : System.Drawing.Color.White);
                editorEarningChildCust.Properties.Appearance.BackColor = ((editorEarningChildCust.SelectedItem == null) ? System.Drawing.Color.Tomato : System.Drawing.Color.White);
                editorEarningCustomer.Properties.Appearance.BackColor = ((editorEarningCustomer.SelectedItem == null) ? System.Drawing.Color.Tomato : System.Drawing.Color.White);
                editorEarningDate.Properties.Appearance.BackColor = ((editorEarningDate.DateTime == System.DateTime.MinValue) ? System.Drawing.Color.Tomato : System.Drawing.Color.White);
                editorEarningCurValue.Properties.Appearance.BackColor = ((editorEarningCurValue.Value <= 0) ? System.Drawing.Color.Tomato : System.Drawing.Color.White);

                bRet = ((editorEarningCurrency.SelectedItem != null) &&
                    (editorEarningPaymentType.SelectedItem != null) && (editorEarningChildCust.SelectedItem != null) &&
                    (editorEarningDate.DateTime != System.DateTime.MinValue) && (editorEarningCurValue.Value > 0)
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

                if (sender == editorEarningChildCust)
                {
                    LoadCustomerForChildDepart((editorEarningChildCust.SelectedItem == null) ? null : (CChildDepart)editorEarningChildCust.SelectedItem);

                    if (m_objSelectedCustomerInitialDebt != null)
                    {
                        if (m_objSelectedCustomerInitialDebt.Customer != null)
                        {
                            editorEarningCustomer.SelectedItem = editorEarningCustomer.Properties.Items.Cast<CCustomer>().FirstOrDefault<CCustomer>(x => x.ID.CompareTo(m_objSelectedCustomerInitialDebt.Customer.ID) == 0);
                        }

                        if (editorEarningCustomer.SelectedItem == null)
                        {
                            editorEarningCustomer.SelectedItem = ((editorEarningCustomer.Properties.Items.Count > 0) ? editorEarningCustomer.Properties.Items[0] : null);
                        }
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

                //if ((m_objSelectedCustomerInitialDebt != null) && (m_objSelectedCustomerInitialDebt.Customer != null))
                //{
                //    if (editorEarningCustomer.Properties.Items.Cast<CCustomer>().FirstOrDefault<CCustomer>(x => x.ID.CompareTo(m_objSelectedCustomerInitialDebt.Customer.ID) == 0) == null)
                //    {
                //        editorEarningCustomer.Properties.Items.Add(m_objSelectedCustomerInitialDebt.Customer);
                //    }
                //}

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
                SendMessageToLog(String.Format("Ошибка изменения свойств задолженности. Текст ошибки: {0}", f.Message));
            }
            finally
            {
            }

            return;
        }

        #endregion

        #region Редактировать задолженность
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

                editorEarningCompany.SelectedItem = null;
                editorEarningPaymentType.SelectedItem = null;
                editorEarningCurValue.Value = 0;
                editorEarningExpense.Value = 0;
                editorEarningSaldo.Value = 0;
                editorEarningChildCust.SelectedItem = null;
                editorEarningCustomer.SelectedItem = null;
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
        /// Загружает свойства задолженности для редактирования
        /// </summary>
        /// <param name="objEarning">задолженность</param>
        /// <param name="bNewObject">признак "новый платеж"</param>
        public void EditEarning(CCustomerInitialDebt objEarning, System.Boolean bNewObject)
        {
            if (objEarning == null) { return; }
            m_bDisableEvents = true;
            m_bNewObject = bNewObject;
            try
            {
                m_objSelectedCustomerInitialDebt = objEarning;

                this.tableLayoutPanelBackground.SuspendLayout();

                ClearControls();

                editorEarningDate.DateTime = m_objSelectedCustomerInitialDebt.Date;
                editorEarningDocNum.Text = m_objSelectedCustomerInitialDebt.DocNum;
                editorEarningCurrency.SelectedItem = (m_objSelectedCustomerInitialDebt.Currency == null) ? null : editorEarningCurrency.Properties.Items.Cast<CCurrency>().SingleOrDefault<CCurrency>(x => x.ID.CompareTo(m_objSelectedCustomerInitialDebt.Currency.ID) == 0);

                editorEarningCompany.SelectedItem = (m_objSelectedCustomerInitialDebt.Company == null) ? null : editorEarningCompany.Properties.Items.Cast<CCompany>().SingleOrDefault<CCompany>(x => x.ID.CompareTo(m_objSelectedCustomerInitialDebt.Company.ID) == 0);
                editorEarningPaymentType.SelectedItem = (m_objSelectedCustomerInitialDebt.PaymentType == null) ? null : editorEarningPaymentType.Properties.Items.Cast<CPaymentType>().SingleOrDefault<CPaymentType>(x => x.ID.CompareTo(m_objSelectedCustomerInitialDebt.PaymentType.ID) == 0);

                editorEarningCurValue.Value = m_objSelectedCustomerInitialDebt.InitialDebt;
                editorEarningExpense.Value = m_objSelectedCustomerInitialDebt.AmountPaid;
                editorEarningSaldo.Value = m_objSelectedCustomerInitialDebt.Saldo;

                editorEarningChildCust.SelectedItem = (m_objSelectedCustomerInitialDebt.ChildDepart == null) ? null : editorEarningChildCust.Properties.Items.Cast<CChildDepart>().SingleOrDefault<CChildDepart>(x => x.ID.CompareTo(m_objSelectedCustomerInitialDebt.ChildDepart.ID) == 0);

                LoadCustomerForChildDepart(m_objSelectedCustomerInitialDebt.ChildDepart);

                if ((m_objSelectedCustomerInitialDebt != null) && (m_objSelectedCustomerInitialDebt.Customer != null))
                {
                    if (editorEarningCustomer.Properties.Items.Cast<CCustomer>().FirstOrDefault<CCustomer>(x => x.ID.CompareTo(m_objSelectedCustomerInitialDebt.Customer.ID) == 0) == null)
                    {
                        editorEarningCustomer.Properties.Items.Add(m_objSelectedCustomerInitialDebt.Customer);
                    }
                }

                editorEarningCustomer.SelectedItem = (m_objSelectedCustomerInitialDebt.Customer == null) ? null : editorEarningCustomer.Properties.Items.Cast<CCustomer>().FirstOrDefault<CCustomer>(x => x.ID.CompareTo(m_objSelectedCustomerInitialDebt.Customer.ID) == 0);


                SetPropertiesModified(false);
                ValidateProperties();

                SetModeReadOnly(true);
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка редактирования задолженности. Текст ошибки: " + f.Message);
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

        #region Новая задолженность
        private void barBtnAdd_Click(object sender, EventArgs e)
        {
            try
            {
                this.Cursor = Cursors.WaitCursor;
                CChildDepart objChildDepart = (((cboxCustomer.SelectedItem == null) || (cboxCustomer.Text == "")) ? null : (CChildDepart)cboxCustomer.SelectedItem);

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
        /// Новая задолженность
        /// </summary>
        /// <param name="objChildDepart">дочерний клиент</param>
        public void NewEarning(CChildDepart objChildDepart)
        {
            try
            {
                m_bNewObject = true;
                m_bDisableEvents = true;

                m_objSelectedCustomerInitialDebt = new CCustomerInitialDebt() { ChildDepart = objChildDepart };

                this.tableLayoutPanelBackground.SuspendLayout();

                ClearControls();

                editorEarningDate.DateTime = System.DateTime.Today;
                editorEarningCompany.SelectedItem = (m_objSelectedCustomerInitialDebt.Company == null) ? null : editorEarningCompany.Properties.Items.Cast<CCompany>().SingleOrDefault<CCompany>(x => x.ID.CompareTo(m_objSelectedCustomerInitialDebt.Company.ID) == 0);
                editorEarningPaymentType.SelectedItem = (m_objSelectedCustomerInitialDebt.PaymentType == null) ? ((editorEarningPaymentType.Properties.Items.Count > 0) ? editorEarningPaymentType.Properties.Items[0] : null) : editorEarningPaymentType.Properties.Items.Cast<CPaymentType>().SingleOrDefault<CPaymentType>(x => x.ID.CompareTo(m_objSelectedCustomerInitialDebt.PaymentType.ID) == 0);
                editorEarningCurrency.SelectedItem = (m_objSelectedCustomerInitialDebt.Currency == null) ? ((editorEarningCurrency.Properties.Items.Count > 0) ? editorEarningCurrency.Properties.Items[0] : null) : editorEarningCurrency.Properties.Items.Cast<CCurrency>().SingleOrDefault<CCurrency>(x => x.ID.CompareTo(m_objSelectedCustomerInitialDebt.Currency.ID) == 0);
                editorEarningChildCust.SelectedItem = (m_objSelectedCustomerInitialDebt.ChildDepart == null) ? null : editorEarningChildCust.Properties.Items.Cast<CChildDepart>().SingleOrDefault<CChildDepart>(x => x.ID.CompareTo(m_objSelectedCustomerInitialDebt.ChildDepart.ID) == 0);

                LoadCustomerForChildDepart(m_objSelectedCustomerInitialDebt.ChildDepart);


                if ((m_objSelectedCustomerInitialDebt != null) && (m_objSelectedCustomerInitialDebt.Customer != null))
                {
                    if (editorEarningCustomer.Properties.Items.Cast<CCustomer>().FirstOrDefault<CCustomer>(x => x.ID.CompareTo(m_objSelectedCustomerInitialDebt.Customer.ID) == 0) == null)
                    {
                        editorEarningCustomer.Properties.Items.Add(m_objSelectedCustomerInitialDebt.Customer);
                    }
                }

                editorEarningCustomer.SelectedItem = (m_objSelectedCustomerInitialDebt.Customer == null) ? null : editorEarningCustomer.Properties.Items.Cast<CCustomer>().FirstOrDefault<CCustomer>(x => x.ID.CompareTo(m_objSelectedCustomerInitialDebt.Customer.ID) == 0);

                if ((editorEarningChildCust.SelectedItem != null) && (editorEarningCustomer.SelectedItem == null))
                {
                    editorEarningCustomer.SelectedItem = ((editorEarningCustomer.Properties.Items.Count > 0) ? editorEarningCustomer.Properties.Items[0] : null);
                }

                btnEdit.Enabled = false;
                btnNewEarning.Enabled = false;
                btnCancel.Enabled = true;

                SetModeReadOnly(false);
                SetPropertiesModified(true);
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка создания начальной задолженности. Текст ошибки: " + f.Message);
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

        #region Удалить задолженность
        /// <summary>
        /// Удаляет задолженность
        /// </summary>
        private void DeleteEarning(CCustomerInitialDebt objEarning)
        {
            if (objEarning == null) { return; }
            System.String strErr = "";

            try
            {
                System.Int32 iFocusedRowHandle = gridViewEarningList.FocusedRowHandle;
                if (DevExpress.XtraEditors.XtraMessageBox.Show(String.Format("Подтвердите, пожалуйста, удаление задолженности.\n\nДочерний клиент: {0}\n\nСумма: {1}", objEarning.ChildDepartCode, System.String.Format("{0,10:G}: ", objEarning.InitialDebt)), "Подтверждение",
                    System.Windows.Forms.MessageBoxButtons.YesNo, System.Windows.Forms.MessageBoxIcon.Question) == DialogResult.No) { return; }

                if ( CCustomerInitialDebtDataBaseModel.RemoveObjectFromDataBase(objEarning.ID, m_objProfile, ref strErr) == true)
                {
                    m_objCustomerInitialDebtList.Remove(objEarning);
                    gridControlEarningList.RefreshDataSource();

                    DevExpress.XtraEditors.XtraMessageBox.Show("Задолженность удалена", "Информация",
                    System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Information);
                }
                else
                {
                    DevExpress.XtraEditors.XtraMessageBox.Show(strErr, "Предупреждение",
                    System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Warning);

                    SendMessageToLog("Удаление задолженности. Текст ошибки: " + strErr);
                }
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Удаление задолженности. Текст ошибки: " + f.Message);
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
                DeleteEarning(GetSelectedEarning());
            }//try
            catch (System.Exception f)
            {
                SendMessageToLog("Удаление задолженности. Текст ошибки: " + f.Message);
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
                        "Выйти из редактора задолженности без сохранения изменений?", "Подтверждение",
                        System.Windows.Forms.MessageBoxButtons.YesNoCancel, System.Windows.Forms.MessageBoxIcon.Question) != System.Windows.Forms.DialogResult.Yes)
                    {
                        return;
                    }
                }

                tabControl.SelectedTabPage = tabPageViewer;
                if (m_objSelectedCustomerInitialDebt != null)
                {
                    System.Int32 iIndxSelectedObject = m_objCustomerInitialDebtList.IndexOf(m_objCustomerInitialDebtList.SingleOrDefault<CCustomerInitialDebt>(x => x.ID.CompareTo(m_objSelectedCustomerInitialDebt.ID) == 0));
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
                System.String CustomerInitalDebt_DocNum = editorEarningDocNum.Text;
                System.DateTime CustomerInitalDebt_Date = editorEarningDate.DateTime;
                System.Guid Customer_Guid = ((editorEarningCustomer.SelectedItem == null) ? (System.Guid.Empty) : ((CCustomer)editorEarningCustomer.SelectedItem).ID);
                System.Guid Currency_Guid = ((editorEarningCurrency.SelectedItem == null) ? (System.Guid.Empty) : ((CCurrency)editorEarningCurrency.SelectedItem).ID);
                System.Guid Company_Guid = ((editorEarningCompany.SelectedItem == null) ? (System.Guid.Empty) : ((CCompany)editorEarningCompany.SelectedItem).ID);
                System.Guid PaymentType_Guid = ((editorEarningPaymentType.SelectedItem == null) ? (System.Guid.Empty) : ((CPaymentType)editorEarningPaymentType.SelectedItem).ID);
                System.Guid ChildDepart_Guid = ((editorEarningChildCust.SelectedItem == null) ? (System.Guid.Empty) : ((CChildDepart)editorEarningChildCust.SelectedItem).ID);
                System.Decimal CustomerInitalDebt_Value = editorEarningCurValue.Value;
                System.Guid CustomerInitalDebt_Guid = ((m_bNewObject == true) ? System.Guid.Empty : m_objSelectedCustomerInitialDebt.ID);
                System.Int32 CustomerInitalDebt_Id = ((m_bNewObject == true) ? 0 : m_objSelectedCustomerInitialDebt.InterbaseID);

                // проверка значений
                if( CCustomerInitialDebtDataBaseModel.IsAllParametersValidPaymentType_2( Customer_Guid, Currency_Guid, 
                    CustomerInitalDebt_Date,  CustomerInitalDebt_DocNum, CustomerInitalDebt_Value, Company_Guid, 
                    ChildDepart_Guid, PaymentType_Guid, ref strErr ) == true)
                {
                    if (m_bNewObject == true)
                    {
                        // новая запись
                        bOkSave = CCustomerInitialDebtDataBaseModel.AddNewObjectToDataBase( Customer_Guid, Currency_Guid,
                            CustomerInitalDebt_Date, CustomerInitalDebt_DocNum, CustomerInitalDebt_Value, 
                            Company_Guid, ChildDepart_Guid, PaymentType_Guid,
                            ref CustomerInitalDebt_Guid, ref CustomerInitalDebt_Id,
                            m_objProfile, ref strErr);

                        if (bOkSave == true)
                        {
                            m_objSelectedCustomerInitialDebt.ID = CustomerInitalDebt_Guid;
                            m_objSelectedCustomerInitialDebt.InterbaseID = CustomerInitalDebt_Id;
                        }
                    }
                    else
                    {
                        bOkSave = CCustomerInitialDebtDataBaseModel.EditObjectInDataBase( CustomerInitalDebt_Guid, Customer_Guid, Currency_Guid,
                            CustomerInitalDebt_Date, CustomerInitalDebt_DocNum,
                            CustomerInitalDebt_Value, Company_Guid,
                            ChildDepart_Guid, PaymentType_Guid,
                            m_objProfile, ref strErr );
                    }
                }

                if (bOkSave == true)
                {
                    m_objSelectedCustomerInitialDebt.DocNum = CustomerInitalDebt_DocNum;
                    m_objSelectedCustomerInitialDebt.Date = CustomerInitalDebt_Date;
                    m_objSelectedCustomerInitialDebt.ChildDepart = editorEarningChildCust.Properties.Items.Cast<CChildDepart>().SingleOrDefault<CChildDepart>(x => x.ID.Equals(ChildDepart_Guid));
                    m_objSelectedCustomerInitialDebt.Customer = editorEarningCustomer.Properties.Items.Cast<CCustomer>().FirstOrDefault<CCustomer>(x => x.ID.Equals(Customer_Guid));
                    m_objSelectedCustomerInitialDebt.Currency = editorEarningCurrency.Properties.Items.Cast<CCurrency>().SingleOrDefault<CCurrency>(x => x.ID.Equals(Currency_Guid));
                    m_objSelectedCustomerInitialDebt.Company = editorEarningCompany.Properties.Items.Cast<CCompany>().SingleOrDefault<CCompany>(x => x.ID.Equals(Company_Guid));
                    m_objSelectedCustomerInitialDebt.PaymentType = editorEarningPaymentType.Properties.Items.Cast<CPaymentType>().SingleOrDefault<CPaymentType>(x => x.ID.Equals(PaymentType_Guid));

                    m_objSelectedCustomerInitialDebt.InitialDebt = CustomerInitalDebt_Value;

                    if (m_bNewObject == true)
                    {
                        m_objCustomerInitialDebtList.Add(m_objSelectedCustomerInitialDebt);
                    }
                    gridControlEarningList.RefreshDataSource();

                    editorEarningSaldo.Value = m_objSelectedCustomerInitialDebt.Saldo;
                    editorEarningCurValue.Value = m_objSelectedCustomerInitialDebt.InitialDebt;
                }

                bRet = bOkSave;
            }
            catch (System.Exception f)
            {
                strErr = f.Message;
                SendMessageToLog("Ошибка сохранения изменений в начальной задолженности. Текст ошибки: " + f.Message);
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
                    DevExpress.XtraEditors.XtraMessageBox.Show(strErr, "Внимание",
                        System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Warning);
                }

            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка сохранения изменений в начальной задолженности. Текст ошибки: " + f.Message);
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
                    for (System.Int32 i = 0; i < iRowsCount; i++)
                    {
                        foreach (DevExpress.XtraGrid.Columns.GridColumn objColumn in gridViewEarningList.Columns)
                        {
                            if (objColumn.Visible == false) { continue; }

                            worksheet.Cells[iCurrentRow, objColumn.VisibleIndex + 1].Value = gridViewEarningList.GetRowCellValue(i, objColumn);
                            if (objColumn.FieldName == "Date")
                            {
                                worksheet.Cells[iCurrentRow, objColumn.VisibleIndex + 1].Style.Numberformat.Format = "DD.MM.YYYY";
                            }
                            if ((objColumn.FieldName == "InitialDebt") || (objColumn.FieldName == "AmountPaid") ||
                                (objColumn.FieldName == "Saldo"))
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
                    worksheet.Cells[System.Convert.ToInt32(lblEarningCompany.Tag), iColumnIndxValue].Value = editorEarningCompany.Text;
                    iPropertiesCount++;

                    worksheet.Cells[System.Convert.ToInt32(lblEarningCurrency.Tag), iColumnIndxCaption].Value = lblEarningCurrency.Text;
                    worksheet.Cells[System.Convert.ToInt32(lblEarningCurrency.Tag), iColumnIndxValue].Value = editorEarningCurrency.Text;
                    iPropertiesCount++;

                    worksheet.Cells[System.Convert.ToInt32(lblEarningPaymentType.Tag), iColumnIndxCaption].Value = lblEarningPaymentType.Text;
                    worksheet.Cells[System.Convert.ToInt32(lblEarningPaymentType.Tag), iColumnIndxValue].Value = editorEarningPaymentType.Text;
                    iPropertiesCount++;

                    worksheet.Cells[System.Convert.ToInt32(lblEarningDate.Tag), iColumnIndxCaption].Value = lblEarningDate.Text;
                    worksheet.Cells[System.Convert.ToInt32(lblEarningDate.Tag), iColumnIndxValue].Value = editorEarningDate.Text;
                    iPropertiesCount++;

                    worksheet.Cells[System.Convert.ToInt32(lblEarningDocNum.Tag), iColumnIndxCaption].Value = lblEarningDocNum.Text;
                    worksheet.Cells[System.Convert.ToInt32(lblEarningDocNum.Tag), iColumnIndxValue].Value = editorEarningDocNum.Text;
                    iPropertiesCount++;

                    worksheet.Cells[System.Convert.ToInt32(lblEarningValue.Tag), iColumnIndxCaption].Value = lblEarningValue.Text;
                    worksheet.Cells[System.Convert.ToInt32(lblEarningValue.Tag), iColumnIndxValue].Value = editorEarningCurValue.Text;
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

        private void contextMenuStripEarningList_Opened(object sender, EventArgs e)
        {
            try
            {
                mitmsEditEarning.Enabled = (SelectedCustomerInitialDebt != null);
                mitmsDeleteEarning.Enabled = ((SelectedCustomerInitialDebt != null) && (SelectedCustomerInitialDebt.AmountPaid == 0));
            }
            catch (System.Exception f)
            {
                SendMessageToLog("contextMenuStripEarningList_Opened. Текст ошибки: " + f.Message);
            }

            return;
        }

    }

    public class CustomerInitialDebtPaymentType_2_Editor : PlugIn.IClassTypeView
    {
        public override void Run(UniXP.Common.MENUITEM objMenuItem, System.String strCaption)
        {
            frmCustomerInitialDebtPaymentType_2 obj = new frmCustomerInitialDebtPaymentType_2(objMenuItem) { Text = strCaption, MdiParent = objMenuItem.objProfile.m_objMDIManager.MdiParent, Visible = true };
        }


    }
}
