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
    public partial class frmCustomerInitialDebtPaymentType_1 : DevExpress.XtraEditors.XtraForm
    {
        #region Свойства
        private UniXP.Common.CProfile m_objProfile;
        private UniXP.Common.MENUITEM m_objMenuItem;
        private System.Boolean m_bOnlyView;
        private System.Boolean m_bIsChanged;
        private System.Boolean m_bDisableEvents;
        private System.Boolean m_bNewObject;
        private enumPaymentType m_enumPaymentType;
        private List<CCustomer> m_objCustomerList;
        private List<CCustomerInitialDebt> m_objCustomerInitialDebtList;
        private CCustomerInitialDebt m_objSelectedCustomerInitialDebt;
        private CPaymentType m_objPaymentTypeDefault;

        private DevExpress.XtraGrid.Views.Base.ColumnView ColumnView
        {
            get { return gridControlEarningList.MainView as DevExpress.XtraGrid.Views.Base.ColumnView; }
        }

        // потоки
        public System.Threading.Thread ThreadLoadCustomerList { get; set; }
        public System.Threading.Thread ThreadLoadCustomerInitialDebtList { get; set; }

        public System.Threading.ManualResetEvent EventStopThread { get; set; }
        public System.Threading.ManualResetEvent EventThreadStopped { get; set; }

        public delegate void LoadCustomerListDelegate(List<CCustomer> objCustomerList, System.Int32 iRowCountInLis);
        public LoadCustomerListDelegate m_LoadCustomerListDelegate;

        public delegate void LoadCustomerInitialDebtListDelegate(List<CCustomerInitialDebt> objCustomerInitialDebtList, System.Int32 iRowCountInList);
        public LoadCustomerInitialDebtListDelegate m_LoadCustomerInitialDebtListDelegate;

        private const System.Int32 iThreadSleepTime = 1000;
        private const System.String strWaitCustomer = "ждите... идет заполнение списка";
        private System.Boolean m_bThreadFinishJob;
        private const System.String strRegistryTools = "\\CustomerInitalDebtListTools\\";
        private const System.Int32 iWaitingpanelIndex = 0;
        private const System.Int32 iWaitingpanelHeight = 35;
        private const System.String m_strModeReadOnly = "Режим просмотра";
        private const System.String m_strModeEdit = "Режим редактирования";


        #endregion

        #region Конструктор
        public frmCustomerInitialDebtPaymentType_1(UniXP.Common.MENUITEM objMenuItem)
        {
            InitializeComponent();

            m_objMenuItem = objMenuItem;
            m_objProfile = objMenuItem.objProfile;
            m_bThreadFinishJob = false;
            m_objCustomerList = new List<CCustomer>();
            m_objCustomerInitialDebtList = new List<CCustomerInitialDebt>();
            m_objSelectedCustomerInitialDebt = null;
            m_enumPaymentType = enumPaymentType.PaymentForm1;
            m_objPaymentTypeDefault = null;

            AddGridColumns();
            dtBeginDate.DateTime = new DateTime(System.DateTime.Today.Year - 15, System.DateTime.Today.Month, 1);
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

        #region Открытие формы

        private int GenerateGroupKeyId()
        {
            Random rnd = new Random(DateTime.Now.Millisecond);
            return rnd.Next(1, 10000);
        }

        private void frmCustomerInitialDebtPaymentType_1_Shown(object sender, EventArgs e)
        {
            try
            {
                LoadComboBox();

                StartThreadLoadCustomerInitialDebtList();

                StartThreadLoadCustomerList();

            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("frmCustomerInitialDebtPaymentType_1_Shown().\n\nТекст ошибки: " + f.Message, "Ошибка",
                    System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Error);
            }

            return;
        }

        private void frmCustomerInitialDebtPaymentType_1_FormClosing(object sender, FormClosingEventArgs e)
        {
            try
            {
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("frmCustomerInitialDebtPaymentType_1_FormClosing.\n\nТекст ошибки: " + f.Message, "Ошибка",
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
            AddGridColumn(ColumnView, "Date", "Дата");
            AddGridColumn(ColumnView, "DocNum", "№ док-та");
            AddGridColumn(ColumnView, "CustomerName", "Клиент");
            AddGridColumn(ColumnView, "InitialDebt", "Сумма задолженности");
            AddGridColumn(ColumnView, "AmountPaid", "Оплачено");
            AddGridColumn(ColumnView, "Saldo", "Сальдо");
            AddGridColumn(ColumnView, "InterbaseID", "УИ");


            foreach (DevExpress.XtraGrid.Columns.GridColumn objColumn in ColumnView.Columns)
            {
                if(objColumn.FieldName == "ID")
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

        #region Выпадающие списки
        /// <summary>
        /// Загружает собдержимое выпадающих списков
        /// </summary>
        private void LoadComboBox()
        {
            try
            {
                cboxCustomer.Properties.Items.Clear();
                cboxCustomer.Properties.Items.Add(new CCustomer());

                cboxCompany.Properties.Items.Clear();

                editorEarningCompanyDst.Properties.Items.Clear();
                List<CCompany> objCompanyList = CCompany.GetCompanyListActive(m_objProfile, null);
                if (objCompanyList != null)
                {
                    cboxCompany.Properties.Items.AddRange(objCompanyList);
                }
                cboxCompany.SelectedItem = ((cboxCompany.Properties.Items.Count > 0) ? cboxCompany.Properties.Items[0] : null);

                editorEarningCompanyDst.Properties.Items.AddRange(cboxCompany.Properties.Items);

                editorEarningCurrency.Properties.Items.Clear();
                if (m_enumPaymentType == enumPaymentType.PaymentForm1)
                {
                    editorEarningCurrency.Properties.Items.AddRange(CCurrency.GetCurrencyList(m_objProfile, null).Where<CCurrency>(x => x.IsNationalCurrency).ToList<CCurrency>());
                }
                else
                {
                    editorEarningCurrency.Properties.Items.AddRange(CCurrency.GetCurrencyList(m_objProfile, null));
                }
                editorEarningPaymentType.Properties.Items.Clear();
                if (m_enumPaymentType == enumPaymentType.PaymentForm1)
                {
                    editorEarningPaymentType.Properties.Items.AddRange(CPaymentType.GetPaymentTypeList(m_objProfile, null, System.Guid.Empty).Where<CPaymentType>(x => x.Payment_Id.Equals(1)).ToList<CPaymentType>());
                }
                else
                {
                    editorEarningPaymentType.Properties.Items.AddRange(CPaymentType.GetPaymentTypeList(m_objProfile, null, System.Guid.Empty));
                }

                List<CPaymentType> objPaymentTypeList = CPaymentType.GetPaymentTypeList(m_objProfile, null, System.Guid.Empty);
                if ((objPaymentTypeList != null) && (objPaymentTypeList.Count > 0))
                {
                    m_objPaymentTypeDefault = objPaymentTypeList.SingleOrDefault<CPaymentType>(x => x.Payment_Id == System.Convert.ToInt32(enumPaymentType.PaymentForm1));
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

        #region Свойства записи в журнале
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
        }

        private void gridViewEarningList_FocusedRowChanged(object sender, DevExpress.XtraGrid.Views.Base.FocusedRowChangedEventArgs e)
        {
            try
            {
                FocusedCustomerInitialDebtChanged();
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
                FocusedCustomerInitialDebtChanged();
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
        /// <returns>ссылка на начальную задолженность</returns>
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

                        objRet = m_objCustomerInitialDebtList.Single<CCustomerInitialDebt>(x => x.ID.CompareTo(uuidID) == 0);
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
        }

        /// <summary>
        /// Определяет, какая задолженность выбрана в журнале и отображает её свойства
        /// </summary>
        private void FocusedCustomerInitialDebtChanged()
        {
            try
            {
                ShowCustomerInitialDebtProperties(SelectedCustomerInitialDebt);

                barBtnAdd.Enabled = !m_bOnlyView;
                barBtnEdit.Enabled = (gridViewEarningList.FocusedRowHandle >= 0);
                barBtnDelete.Enabled = ((!m_bOnlyView) && (gridViewEarningList.FocusedRowHandle >= 0));
                barBtnEarningHistoryView.Enabled = (gridViewEarningList.FocusedRowHandle >= 0);
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
        /// <param name="objCustomerInitialDebt">задолженность</param>
        private void ShowCustomerInitialDebtProperties(CCustomerInitialDebt objCustomerInitialDebt)
        {
            try
            {
                this.tableLayoutPanelEarningProperties.SuspendLayout();

                txtEarningDoc.Text = "";
                txtEarningDate.Text = "";
                calcEarningValue.Value = 0;
                calcEarningExpense.Value = 0;
                calcEarningSaldo.Value = 0;
                txtEarningPayer.Text = "";

                if (objCustomerInitialDebt != null)
                {
                    txtEarningDoc.Text = objCustomerInitialDebt.DocNum;
                    txtEarningDate.Text = objCustomerInitialDebt.Date.ToShortDateString();
                    calcEarningValue.Value = System.Convert.ToDecimal(objCustomerInitialDebt.InitialDebt);
                    calcEarningExpense.Value = System.Convert.ToDecimal(objCustomerInitialDebt.AmountPaid);
                    calcEarningSaldo.Value = System.Convert.ToDecimal(objCustomerInitialDebt.Saldo);
                    txtEarningPayer.Text = objCustomerInitialDebt.CustomerName;
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
                barBtnEarningHistoryView.Enabled = false;

                gridControlEarningList.MouseDoubleClick -= new MouseEventHandler(gridControlEarningList_MouseDoubleClick);

                // запуск потока
                this.ThreadLoadCustomerList = new System.Threading.Thread(LoadCustomerListInThread);
                this.ThreadLoadCustomerList.Start();
            }
            catch (System.Exception f)
            {
                DevExpress.XtraEditors.XtraMessageBox.Show("StartThreadLoadCustomerList().\n\nТекст ошибки: " + f.Message, "Ошибка",
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
                List<CCustomer> objCustomerList = CCustomer.GetCustomerListWithoutAdvancedProperties(m_objProfile, null, null);


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
                    cboxCustomer.Properties.Items.AddRange(objCustomerList);

                    editorEarningCustomer.Properties.Items.AddRange(objCustomerList);
                    m_objCustomerList.AddRange(objCustomerList);
                }
                else
                {
                    cboxCustomer.Text = "";
                    barBtnAdd.Enabled = !m_bOnlyView;
                    barBtnEdit.Enabled = (gridViewEarningList.FocusedRowHandle >= 0);
                    barBtnDelete.Enabled = ((!m_bOnlyView) && (gridViewEarningList.FocusedRowHandle >= 0));
                    barBtnEarningHistoryView.Enabled = (gridViewEarningList.FocusedRowHandle >= 0);
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
                m_LoadCustomerInitialDebtListDelegate = new LoadCustomerInitialDebtListDelegate( LoadCustomerInitialDebtListInGrid );
                m_objCustomerInitialDebtList.Clear();

                barBtnAdd.Enabled = false;
                barBtnEdit.Enabled = false;
                barBtnDelete.Enabled = false;
                barBtnRefresh.Enabled = false;
                barBtnEarningHistoryView.Enabled = false;

                gridControlEarningList.DataSource = null;
                SearchProcessWoring.Visible = true;
                SearchProcessWoring.Refresh();

                gridControlEarningList.MouseDoubleClick -= new MouseEventHandler(gridControlEarningList_MouseDoubleClick);

                // запуск потока
                System.DateTime dtBeginDate = this.dtBeginDate.DateTime;
                System.DateTime dtEndDate = this.dtEndDate.DateTime;
                System.Guid uuidCustomerId = (((cboxCustomer.SelectedItem == null) || (System.Convert.ToString(cboxCustomer.SelectedItem) == "") || (cboxCustomer.Text == strWaitCustomer)) ? System.Guid.Empty : ((CCustomer)cboxCustomer.SelectedItem).ID);
                System.Guid uuidCompanyId = (((cboxCompany.SelectedItem == null) || (System.Convert.ToString(cboxCompany.SelectedItem) == "") || (cboxCompany.Text == strWaitCustomer)) ? System.Guid.Empty : ((CCompany)cboxCompany.SelectedItem).ID);
                System.Guid uuidPaymentTypeId = ((m_objPaymentTypeDefault == null) ? System.Guid.Empty : m_objPaymentTypeDefault.ID);

                this.ThreadLoadCustomerInitialDebtList = new System.Threading.Thread( unused => LoadCustomerInitialDebtListInThread(dtBeginDate,
                    dtEndDate, uuidCustomerId, uuidCompanyId, uuidPaymentTypeId ) );

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
        public void LoadCustomerInitialDebtListInThread( System.DateTime dtBeginDate, System.DateTime dtEndDate,
            System.Guid uuidCustomerId, System.Guid uuidCompanyId, System.Guid uuidPaymentTypeId )
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
                    barBtnEarningHistoryView.Enabled = (gridViewEarningList.FocusedRowHandle >= 0);
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

                editorEarningCompanyDst.Properties.ReadOnly = bSet;
                editorEarningPaymentType.Properties.ReadOnly = bSet;
                editorEarningValue.Properties.ReadOnly = bSet;
                editorEarningCustomer.Properties.ReadOnly = bSet;
                editorEarningpayerDetail.Properties.ReadOnly = bSet;

                btnEdit.Enabled = bSet;
                btnNewEarning.Enabled = bSet;

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
                editorEarningCompanyDst.Properties.Appearance.BackColor = ((editorEarningCompanyDst.SelectedItem == null) ? System.Drawing.Color.Tomato : System.Drawing.Color.White);
                editorEarningCurrency.Properties.Appearance.BackColor = ((editorEarningCurrency.SelectedItem == null) ? System.Drawing.Color.Tomato : System.Drawing.Color.White);
                editorEarningCustomer.Properties.Appearance.BackColor = ((editorEarningCustomer.SelectedItem == null) ? System.Drawing.Color.Tomato : System.Drawing.Color.White);
                editorEarningPaymentType.Properties.Appearance.BackColor = ((editorEarningPaymentType.SelectedItem == null) ? System.Drawing.Color.Tomato : System.Drawing.Color.White);
                editorEarningCustomer.Properties.Appearance.BackColor = ((editorEarningCustomer.SelectedItem == null) ? System.Drawing.Color.Tomato : System.Drawing.Color.White);
                editorEarningDate.Properties.Appearance.BackColor = ((editorEarningDate.DateTime == System.DateTime.MinValue) ? System.Drawing.Color.Tomato : System.Drawing.Color.White);
                editorEarningValue.Properties.Appearance.BackColor = ((editorEarningValue.Value <= 0) ? System.Drawing.Color.Tomato : System.Drawing.Color.White);

                bRet = ((editorEarningCompanyDst.SelectedItem != null) && (editorEarningCurrency.SelectedItem != null) &&
                    (editorEarningPaymentType.SelectedItem != null) && (editorEarningCustomer.SelectedItem != null) &&
                    (editorEarningDate.DateTime != System.DateTime.MinValue) && (editorEarningValue.Value > 0)
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
                SendMessageToLog(String.Format("Ошибка изменения свойств начальной задолженности. Текст ошибки: {0}", f.Message));
            }
            finally
            {
            }

            return;
        }

        #endregion

        #region Редактировать начальную задолженность
        private void barBtnEdit_Click(object sender, EventArgs e)
        {
            try
            {
                EditCustomerInitialDebt(SelectedCustomerInitialDebt, false);

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

                EditCustomerInitialDebt(SelectedCustomerInitialDebt, false);

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

                editorEarningCompanyDst.SelectedItem = null;
                editorEarningPaymentType.SelectedItem = null;
                editorEarningValue.Value = 0;
                editorEarningExpense.Value = 0;
                editorEarningSaldo.Value = 0;
                editorEarningCustomer.SelectedItem = null;
                editorEarningpayerDetail.Text = "";
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
        /// Загружает свойства начальной задолженности для редактирования
        /// </summary>
        /// <param name="objCustomerInitialDebt">начальная задолженность</param>
        /// <param name="bNewObject">признак "новый платеж"</param>
        public void EditCustomerInitialDebt(CCustomerInitialDebt objCustomerInitialDebt, System.Boolean bNewObject)
        {
            if (objCustomerInitialDebt == null) { return; }
            m_bDisableEvents = true;
            m_bNewObject = bNewObject;
            try
            {
                m_objSelectedCustomerInitialDebt = objCustomerInitialDebt;

                this.tableLayoutPanelBackground.SuspendLayout();

                ClearControls();

                editorEarningDate.DateTime = m_objSelectedCustomerInitialDebt.Date;
                editorEarningDocNum.Text = m_objSelectedCustomerInitialDebt.DocNum;
                editorEarningCurrency.SelectedItem = (m_objSelectedCustomerInitialDebt.Currency == null) ? null : editorEarningCurrency.Properties.Items.Cast<CCurrency>().SingleOrDefault<CCurrency>(x => x.ID.CompareTo(m_objSelectedCustomerInitialDebt.Currency.ID) == 0);

                editorEarningCompanyDst.SelectedItem = (m_objSelectedCustomerInitialDebt.Company == null) ? null : editorEarningCompanyDst.Properties.Items.Cast<CCompany>().SingleOrDefault<CCompany>(x => x.ID.CompareTo(m_objSelectedCustomerInitialDebt.Company.ID) == 0);
                editorEarningPaymentType.SelectedItem = (m_objSelectedCustomerInitialDebt.PaymentType == null) ? null : editorEarningPaymentType.Properties.Items.Cast<CPaymentType>().SingleOrDefault<CPaymentType>(x => x.ID.CompareTo(m_objSelectedCustomerInitialDebt.PaymentType.ID) == 0);

                editorEarningValue.Value = m_objSelectedCustomerInitialDebt.InitialDebt;
                editorEarningExpense.Value = m_objSelectedCustomerInitialDebt.AmountPaid;
                editorEarningSaldo.Value = m_objSelectedCustomerInitialDebt.Saldo;

                editorEarningCustomer.SelectedItem = (m_objSelectedCustomerInitialDebt.Customer == null) ? null : editorEarningCustomer.Properties.Items.Cast<CCustomer>().SingleOrDefault<CCustomer>(x => x.ID.CompareTo(m_objSelectedCustomerInitialDebt.Customer.ID) == 0);


                editorEarningpayerDetail.Text = "";

                SetPropertiesModified(false);
                ValidateProperties();

                SetModeReadOnly(true);
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка редактирования начальной задолженности. Текст ошибки: " + f.Message);
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

        #region Новая начальная задолженность
        private void barBtnAdd_Click(object sender, EventArgs e)
        {
            try
            {
                this.Cursor = Cursors.WaitCursor;
                CCompany objCompany = ((cboxCompany.SelectedItem == null) ? null : (CCompany)cboxCompany.SelectedItem);

                NewCustomerInitialDebt(objCompany);

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
        /// <param name="objCompany">компания</param>
        public void NewCustomerInitialDebt(CCompany objCompany)
        {
            try
            {
                m_bNewObject = true;
                m_bDisableEvents = true;

                m_objSelectedCustomerInitialDebt = new CCustomerInitialDebt { Company = objCompany };

                this.tableLayoutPanelBackground.SuspendLayout();

                ClearControls();

                editorEarningDate.DateTime = System.DateTime.Today;
                editorEarningCompanyDst.SelectedItem = (m_objSelectedCustomerInitialDebt.Company == null) ? null : editorEarningCompanyDst.Properties.Items.Cast<CCompany>().SingleOrDefault<CCompany>(x => x.ID.CompareTo(m_objSelectedCustomerInitialDebt.Company.ID) == 0);
                editorEarningPaymentType.SelectedItem = (m_objSelectedCustomerInitialDebt.PaymentType == null) ? ((editorEarningPaymentType.Properties.Items.Count > 0) ? editorEarningPaymentType.Properties.Items[0] : null) : editorEarningPaymentType.Properties.Items.Cast<CPaymentType>().SingleOrDefault<CPaymentType>(x => x.ID.CompareTo(m_objSelectedCustomerInitialDebt.PaymentType.ID) == 0);
                editorEarningCurrency.SelectedItem = (m_objSelectedCustomerInitialDebt.Currency == null) ? ((editorEarningCurrency.Properties.Items.Count > 0) ? editorEarningCurrency.Properties.Items[0] : null) : editorEarningCurrency.Properties.Items.Cast<CCurrency>().SingleOrDefault<CCurrency>(x => x.ID.CompareTo(m_objSelectedCustomerInitialDebt.Currency.ID) == 0);

                btnEdit.Enabled = false;
                btnNewEarning.Enabled = false;
                btnCancel.Enabled = true;

                SetModeReadOnly(false);
                SetPropertiesModified(true);
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Ошибка создания задолженности. Текст ошибки: " + f.Message);
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
 
        #endregion

        #region Удалить задолженность
        /// <summary>
        /// Удаляет задолженность
        /// </summary>
        /// <param name="objCustomerInitialDebt"></param>
        private void DeleteCustomerInitialDebt(CCustomerInitialDebt objCustomerInitialDebt)
        {
            if (objCustomerInitialDebt == null) { return; }
            System.String strErr = "";

            try
            {
                System.Int32 iFocusedRowHandle = gridViewEarningList.FocusedRowHandle;
                if (DevExpress.XtraEditors.XtraMessageBox.Show(String.Format("Подтвердите, пожалуйста, удаление начальной задолженности.\n\nКлиент: {0}\n\nСумма: {1}", objCustomerInitialDebt.CustomerName, System.String.Format("{0,10:G}: ", objCustomerInitialDebt.InitialDebt)), "Подтверждение",
                    System.Windows.Forms.MessageBoxButtons.YesNo, System.Windows.Forms.MessageBoxIcon.Question) == DialogResult.No) { return; }

                if (CCustomerInitialDebtDataBaseModel.RemoveObjectFromDataBase(objCustomerInitialDebt.ID, m_objProfile, ref strErr) == true)
                {
                    StartThreadLoadCustomerInitialDebtList();
                }
                else
                {
                    DevExpress.XtraEditors.XtraMessageBox.Show(strErr, "Предупреждение",
                    System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Warning);

                    SendMessageToLog("Удаление начальной задолженности. Текст ошибки: " + strErr);
                }
            }
            catch (System.Exception f)
            {
                SendMessageToLog("Удаление начальной задолженности. Текст ошибки: " + f.Message);
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
                DeleteCustomerInitialDebt(SelectedCustomerInitialDebt);
            }//try
            catch (System.Exception f)
            {
                SendMessageToLog("Удаление начальной задолженности. Текст ошибки: " + f.Message);
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
        private System.Boolean bSaveCustomerInitialDebtPropertiesInDataBase(ref System.String strErr)
        {
            System.Boolean bRet = false;
            System.Boolean bOkSave = false;

            Cursor = Cursors.WaitCursor;
            try
            {
                System.String CustomerInitalDebt_DocNum = editorEarningDocNum.Text;
                System.DateTime CustomerInitalDebt_Date = editorEarningDate.DateTime;
                System.String Earning_CustomerText = editorEarningpayerDetail.Text;
                System.Guid Customer_Guid = ((editorEarningCustomer.SelectedItem == null) ? (System.Guid.Empty) : ((CCustomer)editorEarningCustomer.SelectedItem).ID);
                System.Guid Currency_Guid = ((editorEarningCurrency.SelectedItem == null) ? (System.Guid.Empty) : ((CCurrency)editorEarningCurrency.SelectedItem).ID);
                System.Guid Company_Guid = ((editorEarningCompanyDst.SelectedItem == null) ? (System.Guid.Empty) : ((CCompany)editorEarningCompanyDst.SelectedItem).ID);
                System.Guid PaymentType_Guid = ((editorEarningPaymentType.SelectedItem == null) ? (System.Guid.Empty) : ((CPaymentType)editorEarningPaymentType.SelectedItem).ID);
                System.Guid ChildDepart_Guid = System.Guid.Empty;
                System.Decimal CustomerInitalDebt_Value = editorEarningValue.Value;
                System.Guid CustomerInitalDebt_Guid = ((m_bNewObject == true) ? System.Guid.Empty : m_objSelectedCustomerInitialDebt.ID);
                System.Int32 CustomerInitalDebt_Id = ((m_bNewObject == true) ? 0 : m_objSelectedCustomerInitialDebt.InterbaseID);

                // проверка значений
                if (CCustomerInitialDebtDataBaseModel.IsAllParametersValidPaymentType_1( Customer_Guid, Currency_Guid,
                        CustomerInitalDebt_Date, CustomerInitalDebt_DocNum, CustomerInitalDebt_Value, Company_Guid,
                        ChildDepart_Guid, PaymentType_Guid, ref strErr ) == true )
                {
                    if (m_bNewObject == true)
                    {
                        // новая задолженность
                        bOkSave = CCustomerInitialDebtDataBaseModel.AddNewObjectToDataBase(Customer_Guid, Currency_Guid,
                            CustomerInitalDebt_Date, CustomerInitalDebt_DocNum, CustomerInitalDebt_Value, Company_Guid,
                            ChildDepart_Guid, PaymentType_Guid,  ref CustomerInitalDebt_Guid, ref CustomerInitalDebt_Id,
                            m_objProfile, ref strErr);

                        if (bOkSave == true)
                        {
                            m_objSelectedCustomerInitialDebt.ID = CustomerInitalDebt_Guid;
                            m_objSelectedCustomerInitialDebt.InterbaseID = CustomerInitalDebt_Id;
                        }
                    }
                    else
                    {
                        bOkSave = CCustomerInitialDebtDataBaseModel.EditObjectInDataBase( CustomerInitalDebt_Guid, Customer_Guid, 
                            Currency_Guid, CustomerInitalDebt_Date, CustomerInitalDebt_DocNum,
                            CustomerInitalDebt_Value, Company_Guid, ChildDepart_Guid, PaymentType_Guid,
                            m_objProfile, ref strErr);
                    }
                }

                if (bOkSave == true)
                {
                    m_objSelectedCustomerInitialDebt.DocNum = CustomerInitalDebt_DocNum;
                    m_objSelectedCustomerInitialDebt.Date = CustomerInitalDebt_Date;
                    m_objSelectedCustomerInitialDebt.Customer = editorEarningCustomer.Properties.Items.Cast<CCustomer>().SingleOrDefault<CCustomer>(x => x.ID.Equals(Customer_Guid));
                    m_objSelectedCustomerInitialDebt.Currency = editorEarningCurrency.Properties.Items.Cast<CCurrency>().SingleOrDefault<CCurrency>(x => x.ID.Equals(Currency_Guid));
                    m_objSelectedCustomerInitialDebt.Company = editorEarningCompanyDst.Properties.Items.Cast<CCompany>().SingleOrDefault<CCompany>(x => x.ID.Equals(Company_Guid));
                    m_objSelectedCustomerInitialDebt.PaymentType = editorEarningPaymentType.Properties.Items.Cast<CPaymentType>().SingleOrDefault<CPaymentType>(x => x.ID.Equals(PaymentType_Guid));
                    m_objSelectedCustomerInitialDebt.InitialDebt = CustomerInitalDebt_Value;

                    if (m_bNewObject == true)
                    {
                        m_objCustomerInitialDebtList.Add(m_objSelectedCustomerInitialDebt);
                    }
                    gridControlEarningList.RefreshDataSource();

                    editorEarningSaldo.Value = ( editorEarningExpense.Value - m_objSelectedCustomerInitialDebt.InitialDebt );

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
                if (bSaveCustomerInitialDebtPropertiesInDataBase(ref strErr) == true)
                {
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
        /// Экспорт журнала начальных задолженностей в MS Excel
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
        /// Экспорт свойств начальной задолженности в MS Excel
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

        #region Навигация в редакторе задолженности
        private void editorEarningValue_KeyPress(object sender, KeyPressEventArgs e)
        {
            if ((m_bIsChanged == true) && (e.KeyChar == (char)Keys.Return))
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
            }
        }

        private void editorEarningDocNum_EditValueChanging(object sender, DevExpress.XtraEditors.Controls.ChangingEventArgs e)
        {
        }

        #endregion

        #region Сторно оплаты
        private void DePayPaidDocument(CCustomerInitialDebt objPaidDocument)
        {
            try
            {
                if (objPaidDocument == null)
                {
                    DevExpress.XtraEditors.XtraMessageBox.Show("Программе не удалось определить документ для сторно оплаты.", "Внимание!",
                        System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Warning);

                    return;
                }

                if (objPaidDocument.AmountPaid == 0)
                {
                    DevExpress.XtraEditors.XtraMessageBox.Show("Оплата по документу полностью отсторирована.", "Внимание!",
                        System.Windows.Forms.MessageBoxButtons.OK, System.Windows.Forms.MessageBoxIcon.Information);

                    return;
                }

                System.Guid CustomerInitialDebt_Guid = objPaidDocument.ID;
                System.Decimal DEC_AMOUNT = 0;
                System.Decimal CustomerInitalDebt_AmountPaid = 0;
                System.Decimal CustomerInitalDebt_Saldo = 0;

                System.Int32 ERROR_NUM = 0;
                System.String strErr = System.String.Empty;

                System.Int32 iRet = CCustomerInitialDebtDataBaseModel.DePayCustomerInitialDebtForm1(m_objProfile, null,
                    CustomerInitialDebt_Guid, ref DEC_AMOUNT, ref CustomerInitalDebt_AmountPaid, ref CustomerInitalDebt_Saldo,
                    ref ERROR_NUM, ref strErr);

                if ((iRet == 0) && (ERROR_NUM == 0))
                {
                    CCustomerInitialDebt objItem = m_objCustomerInitialDebtList.SingleOrDefault<CCustomerInitialDebt>(x => x.ID.CompareTo(CustomerInitialDebt_Guid) == 0);
                    if (objItem != null)
                    {
                        objItem.AmountPaid = CustomerInitalDebt_AmountPaid;

                        gridControlEarningList.RefreshDataSource();
                        SendMessageToLog(System.String.Format("Произведено сторно. Сумма: {0:### ### ##0}  Документ № {1}  от {2}  Задолженность по документу: {3:### ### ##0.00}", DEC_AMOUNT, objItem.DocNum, objItem.Date.ToShortDateString(), CustomerInitalDebt_Saldo));

                        DevExpress.XtraEditors.XtraMessageBox.Show(System.String.Format("Произведено сторно. Сумма: {0:### ### ##0}  \nДокумент № {1}  от {2}  \nЗадолженность по документу: {3:### ### ##0.00}", DEC_AMOUNT, objItem.DocNum, objItem.Date.ToShortDateString(), CustomerInitalDebt_Saldo), "Внимание!",
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

        private void mitemDecPayCustomerInitialDebtForm1_Click(object sender, EventArgs e)
        {
            try
            {
                if (gridViewEarningList.RowCount == 0) { return; }
                if (SelectedCustomerInitialDebt == null) { return; }

                DePayPaidDocument(SelectedCustomerInitialDebt);
            }
            catch (System.Exception f)
            {
                SendMessageToLog("mitemDecPayCustomerInitialDebtForm1_Click. Текст ошибки: " + f.Message);
            }

            return;
        }

        private void contextMenuStripEarningList_Opened(object sender, EventArgs e)
        {
            try
            {
                mitmsEditEarning.Enabled = (SelectedCustomerInitialDebt != null);
                mitmsDeleteEarning.Enabled = ((SelectedCustomerInitialDebt != null) && (SelectedCustomerInitialDebt.AmountPaid == 0));
                mitemDecPayCustomerInitialDebtForm1.Enabled = ((SelectedCustomerInitialDebt != null) && (SelectedCustomerInitialDebt.AmountPaid > 0));
            }
            catch (System.Exception f)
            {
                SendMessageToLog("contextMenuStripEarningList_Opened. Текст ошибки: " + f.Message);
            }

            return;
        }
        #endregion



    }

    public class CustomerInitialDebtPaymentType_1_Editor : PlugIn.IClassTypeView
    {
        public override void Run(UniXP.Common.MENUITEM objMenuItem, System.String strCaption)
        {
            frmCustomerInitialDebtPaymentType_1 obj = new frmCustomerInitialDebtPaymentType_1(objMenuItem) 
            { 
                Text = strCaption, MdiParent = objMenuItem.objProfile.m_objMDIManager.MdiParent, Visible = true 
            };
        }
    }

}
