using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace ERPMercuryBankStatement
{
    /// <summary>
    /// Класс "Документ, на основании которого возникла задолженность клиента перед компанией"
    /// </summary>
    public class CDebitDocument
    {
        public System.Int32 SrcCode {get; set;}
        public System.Int32 Waybill_Id {get; set;}
        public System.String Waybill_Num {get; set;}
        public System.DateTime Waybill_BeginDate {get; set;}
        public System.String Customer_Name {get; set;}
        public System.Decimal Waybill_TotalPrice {get; set;}
        public System.DateTime Waybill_EndDate {get; set;}
        public System.Decimal Waybill_AmountPaid {get; set;}
        public System.DateTime Waybill_DateLastPaid {get; set;}
        public System.Decimal Waybill_Saldo {get; set;}
        public System.String Stock_Name {get; set;}
        public System.Int32 Waybill_ShipMode {get; set;}
        public System.String Waybill_ShipModeName {get; set;}
        public System.Int32 ChildCust_Id { get; set; }
        public System.String ChildCust_Code { get; set; }
        public System.String ChildCust_Name { get; set; }
        public System.Boolean Waybill_Bonus { get; set; }
        public System.Boolean Waybill_Shipped { get; set; }
        public System.DateTime Waybill_ShipDate { get; set; }
        public System.Decimal Waybill_Quantity { get; set; }
        public System.Boolean Waybill_IsPaid { get; set; }
        public System.String Depart_Code { get; set; }
        public System.String Debt_Type { get; set; }
        public System.Int32 Waybill_ExpDays { get; set; }
        public System.Decimal CustomerLimit_ApprovedSumma { get; set; }
        public System.Int32 CustomerLimit_ApprovedDays { get; set; }

        public CDebitDocument()
        {
            SrcCode = 0;
            Waybill_Id = 0;
            Waybill_Num = System.String.Empty;
            Waybill_BeginDate = System.DateTime.MinValue;
            Customer_Name = System.String.Empty;
            Waybill_TotalPrice = 0;
            Waybill_EndDate = System.DateTime.MinValue;
            Waybill_AmountPaid = 0;
            Waybill_DateLastPaid = System.DateTime.MinValue;
            Waybill_Saldo = 0;
            Stock_Name = System.String.Empty;
            Waybill_ShipMode = 0;
            Waybill_ShipModeName = System.String.Empty;
            ChildCust_Id = 0;
            ChildCust_Code = System.String.Empty;
            ChildCust_Name = System.String.Empty;
            Waybill_Bonus = false;
            Waybill_Shipped = false;
            Waybill_ShipDate = System.DateTime.MinValue;
            Waybill_Quantity = 0;
            Waybill_IsPaid = false;
            Depart_Code = System.String.Empty;
            Debt_Type = System.String.Empty;
            Waybill_ExpDays = 0;
            CustomerLimit_ApprovedSumma = 0;
            CustomerLimit_ApprovedDays = 0;
        }
    }
    /// <summary>
    /// Класс "Разноска оплат"
    /// </summary>
    public class CEarningHistory
    {
        public System.Int32 Waybill_Id {get; set;}
        public System.String Waybill_Num {get; set;}
        public System.DateTime Waybill_ShipDate {get; set;}
        public System.Decimal Waybill_TotalPrice {get; set;}
        public System.Decimal Waybill_Saldo {get; set;}
        public System.Decimal Payment_Value {get; set;}
        public System.Boolean Waybill_Bonus {get; set;}
        public System.Boolean Waybill_Shipped {get; set;}
        public System.Int32 Customer_Id {get; set;}
        public System.Int32 Company_Id {get; set;}
        public System.Int32 ChildCust_Id {get; set;}
        public System.String Currency_Code {get; set;}
        public System.String Customer_Name {get; set;}
        public System.String Company_Acronym {get; set;}
        public System.String Company_Name {get; set;}
        public System.DateTime Payment_OperDate {get; set;}
        public System.DateTime Earning_BankDate {get; set;}
        public System.Decimal Waybill_CurrencyTotalPrice { get; set; }
        public System.Decimal Waybill_CurrencySaldo { get; set; }
        public System.String ChildCust_Code { get; set; }
        public System.String ChildCust_Name { get; set; }
        public System.String Drop {get; set;}
        public System.Int32 OperCode { get; set; }
        public System.String OperName { get; set; }

        public CEarningHistory()
        {
            Waybill_Id = 0;
            Waybill_Num = System.String.Empty;
            Waybill_ShipDate = System.DateTime.MinValue;
            Waybill_TotalPrice  = 0;
            Waybill_Saldo = 0;
            Payment_Value = 0;
            Waybill_Bonus = false;
            Waybill_Shipped = false;
            Customer_Id = 0;
            Company_Id = 0;
            ChildCust_Id = 0;
            Currency_Code = System.String.Empty;
            Customer_Name = System.String.Empty;
            Company_Acronym = System.String.Empty;
            Company_Name = System.String.Empty;
            Payment_OperDate = System.DateTime.MinValue;
            Earning_BankDate = System.DateTime.MinValue;
            Waybill_CurrencyTotalPrice = 0;
            Waybill_CurrencySaldo = 0;
            ChildCust_Code = System.String.Empty;
            ChildCust_Name = System.String.Empty;
            Drop = System.String.Empty;
            OperCode = 0;
            OperName = System.String.Empty;
        }
    }

    /// <summary>
    /// Класс "Оплаченный документ"
    /// </summary>
    public class CPaidDocument
    {
        public System.String Currency_Code { get; set; }
        public System.Int32 Waybill_Id { get; set; }
        public System.String Waybill_Num { get; set; }
        public System.Int32 Waybill_Shipped { get; set; }
        public System.Int32 Customer_Id { get; set; }
        public System.Int32 Company_Id { get; set; }
        public System.Int32 ChildCust_Id { get; set; }
        public System.Int32 Stock_Id { get; set; }
        public System.String Depart_Code { get; set; }
        public System.String Customer_Name { get; set; }
        public System.String Company_Acronym { get; set; }
        public System.DateTime Waybill_BeginDate { get; set; }
        public System.DateTime Waybill_ShipDate { get; set; }
        public System.String strWaybill_ShipDate
        {
            get { return ((Waybill_ShipDate.CompareTo(System.DateTime.MinValue) == 0) ? "" : Waybill_ShipDate.ToShortDateString()); }
        }
        public System.String Stock_Name { get; set; }
        public System.Int32 Waybill_ShipModeId { get; set; }
        public System.String Waybill_ShipModeName { get; set; }
        public System.Int32 Waybill_MoneyBonusId { get; set; }
        public System.Boolean Waybill_Bonus { get { return ((Waybill_MoneyBonusId > 0) ? true : false); } }
        public System.Int32 PaymentForm_id { get; set; }
        public System.Int32 Waybill_ExportModeId { get; set; }
        public System.Decimal Waybill_AllPrice { get; set; }
        public System.Decimal Waybill_TotalPrice { get; set; }
        public System.Decimal Waybill_RetAllPrice { get; set; }
        public System.Decimal Waybill_AmountPaid { get; set; }
        public System.Decimal Waybill_Saldo { get; set; }
        public System.DateTime Waybill_DateLastPaid { get; set; }
        public System.Decimal Waybill_CurrencyAllPrice { get; set; }
        public System.Decimal Waybill_CurrencyTotalPrice { get; set; }
        public System.Decimal Waybill_CurrencyRetAllPrice { get; set; }
        public System.Decimal Waybill_CurrencyAmountPaid { get; set; }
        public System.Decimal Waybill_CurrencySaldo { get; set; }
        public System.Decimal Waybill_Quantity { get; set; }
        public System.Int32 Waybill_ReturnId { get; set; }
        public System.String Drop
        {
            get
            {
                System.String result = System.String.Empty;
                switch (Waybill_Shipped)
                {
                    case -1:
                        result = "+";
                        break;
                    case 0:
                        result = "";
                        break;
                    case 1:
                        result = "отгружена";
                        break;
                    default:
                        result = "";
                        break;
                }
                return result;
            }
        }
        public System.String ChildCust_Code { get; set; }
        public System.String ChildCust_Name { get; set; }

        public CPaidDocument()
        {
            Currency_Code = System.String.Empty;
            Waybill_Id = 0;
            Waybill_Num = System.String.Empty;
            Waybill_Shipped = 0;
            Customer_Id = 0;
            Company_Id = 0;
            ChildCust_Id = 0;
            Stock_Id = 0;
            Depart_Code = System.String.Empty;
            Customer_Name = System.String.Empty;
            Company_Acronym = System.String.Empty;
            Waybill_BeginDate = System.DateTime.MinValue;
            Waybill_ShipDate = System.DateTime.MinValue;
            Stock_Name = System.String.Empty;
            Waybill_ShipModeId = 0;
            Waybill_ShipModeName = System.String.Empty;
            Waybill_MoneyBonusId = 0;
            PaymentForm_id = 0;
            Waybill_ExportModeId = 0;
            Waybill_AllPrice = 0;
            Waybill_TotalPrice = 0;
            Waybill_RetAllPrice = 0;
            Waybill_AmountPaid = 0;
            Waybill_Saldo = 0;
            Waybill_DateLastPaid = System.DateTime.MinValue;
            Waybill_CurrencyAllPrice = 0;
            Waybill_CurrencyTotalPrice = 0;
            Waybill_CurrencyRetAllPrice = 0;
            Waybill_CurrencyAmountPaid = 0;
            Waybill_CurrencySaldo = 0;
            Waybill_Quantity = 0;
            Waybill_ReturnId = 0;
            ChildCust_Code = System.String.Empty;
            ChildCust_Name = System.String.Empty;

        }
    }

    public static class CPaymentDataBaseModel
    {
        private const int INT_cmdCommandTimeout = 600;
        #region Настройки по умолчанию для созданиянового платежа
        /// <summary>
        /// Запрашивает настройки по-умолчанию для создания нового платежа
        /// </summary>
        /// <param name="objProfile">профайл</param>
        /// <param name="cmdSQL">SQL-команда</param>
        /// <param name="uuidPaymentTypeId">УИ формы оплаты</param>
        /// <param name="ACCOUNTPLAN_1C_CODE">код плана счетов в 1С</param>
        /// <param name="ACCOUNTPLAN_GUID">УИ плана счетов</param>
        /// <param name="BUDGETPROJECT_DST_NAME">наименование проекта-назначения</param>
        /// <param name="BUDGETPROJECT_DST_GUID">УИ проекта-назначения</param>
        /// <param name="COMPANT_ACRONYM">компания по умолчанию</param>
        /// <param name="ERROR_NUM">№ ошибки</param>
        /// <param name="strErr">сообщение об ошибке</param>
        /// <returns>идентификатор плана счетов и проекта-назначения</returns>
        public static System.Int32 GetEarningSettingsDefault(UniXP.Common.CProfile objProfile, System.Data.SqlClient.SqlCommand cmdSQL,
            System.Guid uuidPaymentTypeId, ref System.String ACCOUNTPLAN_1C_CODE, ref System.Guid ACCOUNTPLAN_GUID,
            ref System.String BUDGETPROJECT_DST_NAME, ref System.Guid BUDGETPROJECT_DST_GUID, ref System.String COMPANT_ACRONYM,
            ref System.Int32 ERROR_NUM, ref System.String strErr)
        {
            System.Int32 iRet = -1;

            if (uuidPaymentTypeId.CompareTo(System.Guid.Empty) == 0)
            {
                strErr += ("Не указан идентификатор формы оплаты.");
                return iRet;
            }

            System.Data.SqlClient.SqlConnection DBConnection = null;
            System.Data.SqlClient.SqlCommand cmd = null;
            try
            {
                if (cmdSQL == null)
                {
                    DBConnection = objProfile.GetDBSource();
                    if (DBConnection == null)
                    {
                        strErr += ("Не удалось получить соединение с базой данных.");
                        return iRet;
                    }
                    cmd = new System.Data.SqlClient.SqlCommand();
                    cmd.Connection = DBConnection;
                    cmd.CommandType = System.Data.CommandType.StoredProcedure;
                }
                else
                {
                    cmd = cmdSQL;
                    cmd.Parameters.Clear();
                }

                cmd.CommandText = System.String.Format("[{0}].[dbo].[usp_GetEarningSettingsDefault]", objProfile.GetOptionsDllDBName());
                cmd.Parameters.Clear();
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@RETURN_VALUE", System.Data.SqlDbType.Int, 4, System.Data.ParameterDirection.ReturnValue, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@PaymentType_Guid", System.Data.SqlDbType.UniqueIdentifier));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_NUM", System.Data.SqlDbType.Int, 8, System.Data.ParameterDirection.Output, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_MES", System.Data.SqlDbType.NVarChar, 4000) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ACCOUNTPLAN_1C_CODE", System.Data.SqlDbType.NVarChar, 128) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ACCOUNTPLAN_GUID", System.Data.SqlDbType.UniqueIdentifier) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@BUDGETPROJECT_DST_NAME", System.Data.SqlDbType.NVarChar, 128) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@BUDGETPROJECT_DST_GUID", System.Data.SqlDbType.UniqueIdentifier) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@COMPANT_ACRONYM", System.Data.SqlDbType.NVarChar, 128) { Direction = System.Data.ParameterDirection.Output });

                cmd.Parameters["@PaymentType_Guid"].Value = uuidPaymentTypeId;

                iRet = cmd.ExecuteNonQuery();

                iRet = System.Convert.ToInt32(cmd.Parameters["@ERROR_NUM"].Value);

                if (cmd.Parameters["@ERROR_NUM"].Value != System.DBNull.Value) { ERROR_NUM = (System.Convert.ToInt32(cmd.Parameters["@ERROR_NUM"].Value)); }
                if (cmd.Parameters["@ERROR_MES"].Value != System.DBNull.Value) { strErr += (System.Convert.ToString(cmd.Parameters["@ERROR_MES"].Value)); }
                if (cmd.Parameters["@ACCOUNTPLAN_1C_CODE"].Value != System.DBNull.Value) { ACCOUNTPLAN_1C_CODE = (System.Convert.ToString(cmd.Parameters["@ACCOUNTPLAN_1C_CODE"].Value)); }
                if (cmd.Parameters["@ACCOUNTPLAN_GUID"].Value != System.DBNull.Value) { ACCOUNTPLAN_GUID = (System.Guid)cmd.Parameters["@ACCOUNTPLAN_GUID"].Value; }
                if (cmd.Parameters["@BUDGETPROJECT_DST_NAME"].Value != System.DBNull.Value) { BUDGETPROJECT_DST_NAME = (System.Convert.ToString(cmd.Parameters["@BUDGETPROJECT_DST_NAME"].Value)); }
                if (cmd.Parameters["@BUDGETPROJECT_DST_GUID"].Value != System.DBNull.Value) { BUDGETPROJECT_DST_GUID = (System.Guid)cmd.Parameters["@BUDGETPROJECT_DST_GUID"].Value; }
                if (cmd.Parameters["@COMPANT_ACRONYM"].Value != System.DBNull.Value) { COMPANT_ACRONYM = (System.Convert.ToString(cmd.Parameters["@COMPANT_ACRONYM"].Value)); }

                if (cmdSQL == null)
                {
                    cmd.Dispose();
                    DBConnection.Close();
                }
            }
            catch (System.Exception f)
            {
                strErr += (String.Format("\nНе удалось получить настройки для платежа.\nТекст ошибки: {0}", f.Message));
            }

            return iRet;
        }
        #endregion

        #region Список документов на оплату по форме 1
        /// <summary>
        /// Возвращает список документов для оплаты по форме 1
        /// </summary>
        /// <param name="objProfile">профайл</param>
        /// <param name="cmdSQL">SQL-команда</param>
        /// <param name="uuidCompanyId">идентификатор компании</param>
        /// <param name="uuidCustomerId">идентификатор клиента</param>
        /// <param name="strErr"соообщение об ошибке></param>
        /// <returns>список платежей</returns>
        public static List<CDebitDocument> GetDebitDocumentFormPay1List(UniXP.Common.CProfile objProfile,
            System.Data.SqlClient.SqlCommand cmdSQL,
            System.Guid uuidCompanyId, System.Guid uuidCustomerId,
            ref System.String strErr)
        {
            List<CDebitDocument> objList = new List<CDebitDocument>();

            if ((uuidCompanyId.CompareTo(System.Guid.Empty) == 0) ||
                (uuidCustomerId.CompareTo(System.Guid.Empty) == 0))
            {
                return objList;
            }

            System.Data.SqlClient.SqlConnection DBConnection = null;
            System.Data.SqlClient.SqlCommand cmd = null;
            try
            {
                if (cmdSQL == null)
                {
                    DBConnection = objProfile.GetDBSource();
                    if (DBConnection == null)
                    {
                        strErr += ("Не удалось получить соединение с базой данных.");
                        return objList;
                    }
                    cmd = new System.Data.SqlClient.SqlCommand();
                    cmd.Connection = DBConnection;
                    cmd.CommandType = System.Data.CommandType.StoredProcedure;
                }
                else
                {
                    cmd = cmdSQL;
                    cmd.Parameters.Clear();
                }

                cmd.CommandText = System.String.Format("[{0}].[dbo].[usp_GetDocForm1ForPaymentFromIB]", objProfile.GetOptionsDllDBName());
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@RETURN_VALUE", System.Data.SqlDbType.Int, 4, System.Data.ParameterDirection.ReturnValue, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_NUM", System.Data.SqlDbType.Int, 8, System.Data.ParameterDirection.Output, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_MES", System.Data.SqlDbType.NVarChar, 4000) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Customer_Guid", System.Data.DbType.Guid));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Company_Guid", System.Data.DbType.Guid));
                cmd.Parameters["@ERROR_MES"].Direction = System.Data.ParameterDirection.Output;

                cmd.Parameters["@Customer_Guid"].Value = uuidCustomerId;
                cmd.Parameters["@Company_Guid"].Value = uuidCompanyId;

                System.Data.SqlClient.SqlDataReader rs = cmd.ExecuteReader();
                System.Int32 iRecordCount = 0;
                if (rs.HasRows)
                {
                    CDebitDocument objDebitDocument = null;
                    while (rs.Read())
                    {
                        iRecordCount++;

                        objDebitDocument = new CDebitDocument();

                        objDebitDocument.SrcCode = ((rs["SRC"] == System.DBNull.Value) ? 0 : (System.Int32)rs["SRC"]);
                        objDebitDocument.Waybill_Id = ((rs["WAYBILL_ID"] == System.DBNull.Value) ? 0 : (System.Int32)rs["WAYBILL_ID"]);
                        objDebitDocument.Waybill_Num = ((rs["WAYBILL_NUM"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["WAYBILL_NUM"]);
                        objDebitDocument.Waybill_BeginDate = ((rs["WAYBILL_BEGINDATE"] == System.DBNull.Value) ? System.DateTime.MinValue : (System.DateTime)rs["WAYBILL_BEGINDATE"]);
                        objDebitDocument.Customer_Name = ((rs["CUSTOMER_NAME"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["CUSTOMER_NAME"]);
                        objDebitDocument.Waybill_TotalPrice = ((rs["WAYBILL_TOTALPRICE"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_TOTALPRICE"]));
                        objDebitDocument.Waybill_EndDate = ((rs["WAYBILL_ENDDATE"] == System.DBNull.Value) ? System.DateTime.MinValue : (System.DateTime)rs["WAYBILL_ENDDATE"]);
                        objDebitDocument.Waybill_AmountPaid = ((rs["WAYBILL_AMOUNTPAID"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_AMOUNTPAID"]));
                        objDebitDocument.Waybill_DateLastPaid = ((rs["WAYBILL_DATELASTPAID"] == System.DBNull.Value) ? System.DateTime.MinValue : (System.DateTime)rs["WAYBILL_DATELASTPAID"]);
                        objDebitDocument.Waybill_Saldo = ((rs["WAYBILL_SALDO"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_SALDO"]));
                        objDebitDocument.Stock_Name = ((rs["STOCK_NAME"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["STOCK_NAME"]);
                        objDebitDocument.Waybill_ShipMode = ((rs["WAYBILL_SHIPMODE"] == System.DBNull.Value) ? 0 : (System.Int32)rs["WAYBILL_SHIPMODE"]);
                        objDebitDocument.Waybill_ShipModeName = ((rs["WAYBILL_SHIPMODE_NAME"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["WAYBILL_SHIPMODE_NAME"]);

                        if (objDebitDocument != null) { objList.Add(objDebitDocument); }
                    }
                }
                rs.Dispose();
                if (cmdSQL == null)
                {
                    cmd.Dispose();
                    DBConnection.Close();
                }
            }
            catch (System.Exception f)
            {
                strErr += (String.Format("\nНе удалось получить список задолженностей.\nТекст ошибки: {0}", f.Message));
            }
            return objList;
        }

        #endregion

        #region Оплата задолженности по форме 1
        /// <summary>
        /// Регистрирует оплату документа по форме 1
        /// </summary>
        /// <param name="objProfile">профайл</param>
        /// <param name="cmdSQL">SQL-команда</param>
        /// <param name="uuidEarningId">УИ платежа</param>
        /// <param name="iWaybillId">УИ документа на оплату</param>
        /// <param name="FINDED_MONEY">сумма разноски</param>
        /// <param name="DOC_NUM">№ оплаченного документа</param>
        /// <param name="DOC_DATE">Дата оплаченного документа</param>
        /// <param name="DOC_SALDO">Сальдо документа</param>
        /// <param name="EARNING_SALDO">Сальдо платежа</param>
        /// <param name="EARNING_EXPENSE">Расход платежа</param>
        /// <param name="ERROR_NUM">№ ошибки</param>
        /// <param name="strErr">сообщение об ошибке</param>
        /// <returns>0 - удачное завершение операции</returns>
        public static System.Int32 PayDebitDocumentForm1( UniXP.Common.CProfile objProfile, System.Data.SqlClient.SqlCommand cmdSQL,
            System.Guid uuidEarningId, System.Int32 iWaybillId, ref System.Decimal FINDED_MONEY,
            ref System.String DOC_NUM,  ref System.DateTime DOC_DATE, ref System.Decimal DOC_SALDO, 
            ref System.Decimal EARNING_SALDO, ref System.Decimal EARNING_EXPENSE,
            ref System.Int32 ERROR_NUM, ref System.String strErr )
        {
            System.Int32 iRet = -1;

            if ((uuidEarningId.CompareTo(System.Guid.Empty) == 0) ||
                (iWaybillId <= 0))
            {
                strErr += ("Не указан идентификатор платежа или документа на оплату.");
                return iRet;
            }

            System.Data.SqlClient.SqlConnection DBConnection = null;
            System.Data.SqlClient.SqlCommand cmd = null;
            try
            {
                if (cmdSQL == null)
                {
                    DBConnection = objProfile.GetDBSource();
                    if (DBConnection == null)
                    {
                        strErr += ("Не удалось получить соединение с базой данных.");
                        return iRet;
                    }
                    cmd = new System.Data.SqlClient.SqlCommand();
                    cmd.Connection = DBConnection;
                    cmd.CommandType = System.Data.CommandType.StoredProcedure;
                }
                else
                {
                    cmd = cmdSQL;
                    cmd.Parameters.Clear();
                }

                cmd.CommandText = System.String.Format("[{0}].[dbo].[usp_PayDebitDocumentForm1ToSQLandIB]", objProfile.GetOptionsDllDBName());
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@RETURN_VALUE", System.Data.SqlDbType.Int, 4, System.Data.ParameterDirection.ReturnValue, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Earning_Guid", System.Data.SqlDbType.UniqueIdentifier));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Waybill_Id", System.Data.SqlDbType.Int));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_NUM", System.Data.SqlDbType.Int, 8, System.Data.ParameterDirection.Output, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_MES", System.Data.SqlDbType.NVarChar, 4000) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@FINDED_MONEY", System.Data.SqlDbType.Money) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@DOC_SALDO", System.Data.SqlDbType.Money) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@EARNING_SALDO", System.Data.SqlDbType.Money) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@EARNING_EXPENSE", System.Data.SqlDbType.Money) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@DOC_NUM", System.Data.SqlDbType.NVarChar, 128) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@DOC_DATE", System.Data.SqlDbType.Date) { Direction = System.Data.ParameterDirection.Output });

                cmd.Parameters["@Earning_Guid"].Value = uuidEarningId;
                cmd.Parameters["@Waybill_Id"].Value = iWaybillId;

                iRet = cmd.ExecuteNonQuery();

                iRet = System.Convert.ToInt32(cmd.Parameters["@ERROR_NUM"].Value);

                if (cmd.Parameters["@ERROR_NUM"].Value != System.DBNull.Value) { ERROR_NUM = (System.Convert.ToInt32(cmd.Parameters["@ERROR_NUM"].Value)); }
                if (cmd.Parameters["@ERROR_MES"].Value != System.DBNull.Value) { strErr += (System.Convert.ToString(cmd.Parameters["@ERROR_MES"].Value)); }
                if (cmd.Parameters["@FINDED_MONEY"].Value != System.DBNull.Value) { FINDED_MONEY = (System.Convert.ToDecimal(cmd.Parameters["@FINDED_MONEY"].Value)); }
                if (cmd.Parameters["@DOC_SALDO"].Value != System.DBNull.Value) { DOC_SALDO = (System.Convert.ToDecimal(cmd.Parameters["@DOC_SALDO"].Value)); }
                if (cmd.Parameters["@EARNING_SALDO"].Value != System.DBNull.Value) { EARNING_SALDO = (System.Convert.ToDecimal(cmd.Parameters["@EARNING_SALDO"].Value)); }
                if (cmd.Parameters["@EARNING_EXPENSE"].Value != System.DBNull.Value) { EARNING_EXPENSE = (System.Convert.ToDecimal(cmd.Parameters["@EARNING_EXPENSE"].Value)); }
                if (cmd.Parameters["@DOC_NUM"].Value != System.DBNull.Value) { DOC_NUM = (System.Convert.ToString(cmd.Parameters["@DOC_NUM"].Value)); }
                if (cmd.Parameters["@DOC_DATE"].Value != System.DBNull.Value) { DOC_DATE = (System.Convert.ToDateTime(cmd.Parameters["@DOC_DATE"].Value)); }

                if (cmdSQL == null)
                {
                    cmd.Dispose();
                    DBConnection.Close();
                }
            }
            catch (System.Exception f)
            {
                strErr += (String.Format("\nНе удалось выполнить оплату документа.\nТекст ошибки: {0}", f.Message));
            }

            return iRet;
        }

        #endregion

        #region Список документов на оплату по форме 2
        /// <summary>
        /// Возвращает список документов для оплаты по форме 2
        /// </summary>
        /// <param name="objProfile">профайл</param>
        /// <param name="cmdSQL">SQL-команда</param>
        /// <param name="uuidCompanyId">идентификатор компании</param>
        /// <param name="uuidCustomerId">идентификатор клиента</param>
        /// <param name="strErr"соообщение об ошибке></param>
        /// <returns>список платежей</returns>
        public static List<CDebitDocument> GetDebitDocumentFormPay2List(UniXP.Common.CProfile objProfile,
            System.Data.SqlClient.SqlCommand cmdSQL,
            System.Guid uuidCompanyId, System.Guid uuidCustomerId, System.Guid uuidChildDeparId, 
            System.DateTime dtBeginDate, System.DateTime dtEndDate,
            ref System.String strErr)
        {
            List<CDebitDocument> objList = new List<CDebitDocument>();

            System.Data.SqlClient.SqlConnection DBConnection = null;
            System.Data.SqlClient.SqlCommand cmd = null;
            try
            {
                if (cmdSQL == null)
                {
                    DBConnection = objProfile.GetDBSource();
                    if (DBConnection == null)
                    {
                        strErr += ("Не удалось получить соединение с базой данных.");
                        return objList;
                    }
                    cmd = new System.Data.SqlClient.SqlCommand();
                    cmd.Connection = DBConnection;
                    cmd.CommandType = System.Data.CommandType.StoredProcedure;
                }
                else
                {
                    cmd = cmdSQL;
                    cmd.Parameters.Clear();
                }
                cmd.CommandTimeout = INT_cmdCommandTimeout;
                cmd.CommandText = System.String.Format("[{0}].[dbo].[usp_GetDocForm2ForPaymentFromIB]", objProfile.GetOptionsDllDBName());
                cmd.Parameters.Clear();
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@RETURN_VALUE", System.Data.SqlDbType.Int, 4, System.Data.ParameterDirection.ReturnValue, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_NUM", System.Data.SqlDbType.Int, 8, System.Data.ParameterDirection.Output, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_MES", System.Data.SqlDbType.NVarChar, 4000) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Begin_Date", System.Data.SqlDbType.Date));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@End_Date", System.Data.SqlDbType.Date));

                if (uuidCustomerId.CompareTo(System.Guid.Empty) != 0)
                {
                    cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Customer_Guid", System.Data.SqlDbType.UniqueIdentifier));
                    cmd.Parameters["@Customer_Guid"].Value = uuidCustomerId;
                }
                if (uuidCompanyId.CompareTo(System.Guid.Empty) != 0)
                {
                    cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Company_Guid", System.Data.SqlDbType.UniqueIdentifier));
                    cmd.Parameters["@Company_Guid"].Value = uuidCompanyId;
                }
                if (uuidChildDeparId.CompareTo(System.Guid.Empty) != 0)
                {
                    cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ChildDepart_Guid", System.Data.SqlDbType.UniqueIdentifier));
                    cmd.Parameters["@ChildDepart_Guid"].Value = uuidChildDeparId;
                }
                cmd.Parameters["@Begin_Date"].Value = dtBeginDate;
                cmd.Parameters["@End_Date"].Value = dtEndDate;

                System.Data.SqlClient.SqlDataReader rs = cmd.ExecuteReader();
                System.Int32 iRecordCount = 0;
                if (rs.HasRows)
                {
                    CDebitDocument objDebitDocument = null;
                    while (rs.Read())
                    {
                        iRecordCount++;

                        objDebitDocument = new CDebitDocument();

                        objDebitDocument.SrcCode = ((rs["SRC"] == System.DBNull.Value) ? 0 : (System.Int32)rs["SRC"]);
                        objDebitDocument.Waybill_Id = ((rs["WAYBILL_ID"] == System.DBNull.Value) ? 0 : (System.Int32)rs["WAYBILL_ID"]);
                        objDebitDocument.Waybill_Num = ((rs["WAYBILL_NUM"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["WAYBILL_NUM"]);
                        objDebitDocument.Waybill_BeginDate = ((rs["WAYBILL_BEGINDATE"] == System.DBNull.Value) ? System.DateTime.MinValue : (System.DateTime)rs["WAYBILL_BEGINDATE"]);
                        objDebitDocument.Customer_Name = ((rs["CUSTOMER_NAME"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["CUSTOMER_NAME"]);
                        objDebitDocument.Waybill_TotalPrice = ((rs["WAYBILL_TOTALPRICE"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_TOTALPRICE"]));
                        objDebitDocument.Waybill_EndDate = ((rs["WAYBILL_ENDDATE"] == System.DBNull.Value) ? System.DateTime.MinValue : (System.DateTime)rs["WAYBILL_ENDDATE"]);
                        objDebitDocument.Waybill_AmountPaid = ((rs["WAYBILL_AMOUNTPAID"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_AMOUNTPAID"]));
                        objDebitDocument.Waybill_DateLastPaid = ((rs["WAYBILL_DATELASTPAID"] == System.DBNull.Value) ? System.DateTime.MinValue : (System.DateTime)rs["WAYBILL_DATELASTPAID"]);
                        objDebitDocument.Waybill_Saldo = ((rs["WAYBILL_SALDO"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_SALDO"]));
                        objDebitDocument.Stock_Name = ((rs["STOCK_NAME"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["STOCK_NAME"]);
                        objDebitDocument.Waybill_ShipMode = ((rs["WAYBILL_SHIPMODE"] == System.DBNull.Value) ? 0 : (System.Int32)rs["WAYBILL_SHIPMODE"]);
                        objDebitDocument.Waybill_ShipModeName = ((rs["WAYBILL_SHIPMODE_NAME"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["WAYBILL_SHIPMODE_NAME"]);

                        objDebitDocument.Waybill_ShipDate = ((rs["WAYBILL_SHIPDATE"] == System.DBNull.Value) ? System.DateTime.MinValue : (System.DateTime)rs["WAYBILL_SHIPDATE"]);

                        objDebitDocument.ChildCust_Id = ((rs["CHILDCUST_ID"] == System.DBNull.Value) ? 0 : (System.Int32)rs["CHILDCUST_ID"]);
                        objDebitDocument.ChildCust_Code = ((rs["CHILDCUST_CODE"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["CHILDCUST_CODE"]);
                        objDebitDocument.ChildCust_Name = ((rs["CHILDCUST_NAME"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["CHILDCUST_NAME"]);

                        if( rs["WAYBILL_MONEYBONUS"] != System.DBNull.Value )
                        {
                            objDebitDocument.Waybill_Bonus = ( ( (System.Int32)rs["WAYBILL_MONEYBONUS"]) > 0 );
                        }
                        if( objDebitDocument.Waybill_ShipDate.CompareTo(System.DateTime.MinValue) != 0 )
                        {
                            objDebitDocument.Waybill_Shipped = true;
                        }

                        objDebitDocument.Waybill_Quantity = ((rs["WAYBILL_QUANTITY"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_QUANTITY"]));

                        objList.Add(objDebitDocument);
                    }
                }
                rs.Dispose();
                if (cmdSQL == null)
                {
                    cmd.Dispose();
                    DBConnection.Close();
                }
            }
            catch (System.Exception f)
            {
                strErr += (String.Format("\nНе удалось получить список задолженностей по форме 2.\nТекст ошибки: {0}", f.Message));
            }
            return objList;
        }

        #endregion

        #region Оплата задолженности по форме 2
        /// <summary>
        /// Регистрирует оплату документа по форме 2 в автоматическом режиме
        /// </summary>
        /// <param name="objProfile">профайл</param>
        /// <param name="cmdSQL">SQL-команда</param>
        /// <param name="uuidEarningId">УИ платежа</param>
        /// <param name="EARNING_SALDO">Сальдо платежа</param>
        /// <param name="EARNING_EXPENSE">Расход платежа</param>
        /// <param name="ERROR_NUM">№ ошибки</param>
        /// <param name="strErr">сообщение об ошибке</param>
        /// <returns>0 - удачное завершение операции</returns>
        public static System.Int32 PayDebitDocumentsForm2(UniXP.Common.CProfile objProfile, System.Data.SqlClient.SqlCommand cmdSQL,
            System.Guid uuidEarningId, ref System.Int32 ID_START, ref System.Int32 ID_END, 
            ref System.Decimal EARNING_SALDO, ref System.Decimal EARNING_EXPENSE,
            ref System.Int32 ERROR_NUM, ref System.String strErr)
        {
            System.Int32 iRet = -1;

            if (uuidEarningId.CompareTo(System.Guid.Empty) == 0)
            {
                strErr += ("Не указан идентификатор платежа.");
                return iRet;
            }

            System.Data.SqlClient.SqlConnection DBConnection = null;
            System.Data.SqlClient.SqlCommand cmd = null;
            try
            {
                if (cmdSQL == null)
                {
                    DBConnection = objProfile.GetDBSource();
                    if (DBConnection == null)
                    {
                        strErr += ("Не удалось получить соединение с базой данных.");
                        return iRet;
                    }
                    cmd = new System.Data.SqlClient.SqlCommand();
                    cmd.Connection = DBConnection;
                    cmd.CommandType = System.Data.CommandType.StoredProcedure;
                }
                else
                {
                    cmd = cmdSQL;
                    cmd.Parameters.Clear();
                }

                cmd.CommandTimeout = INT_cmdCommandTimeout;
                cmd.CommandText = System.String.Format("[{0}].[dbo].[usp_PayDebitDocumentsForm2ToSQLandIB]", objProfile.GetOptionsDllDBName());
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@RETURN_VALUE", System.Data.SqlDbType.Int, 4, System.Data.ParameterDirection.ReturnValue, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Earning_Guid", System.Data.SqlDbType.UniqueIdentifier));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_NUM", System.Data.SqlDbType.Int, 8, System.Data.ParameterDirection.Output, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_MES", System.Data.SqlDbType.NVarChar, 4000) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ID_START", System.Data.SqlDbType.Int) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ID_END", System.Data.SqlDbType.Int) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@EARNING_SALDO", System.Data.SqlDbType.Money) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@EARNING_EXPENSE", System.Data.SqlDbType.Money) { Direction = System.Data.ParameterDirection.Output });

                cmd.Parameters["@Earning_Guid"].Value = uuidEarningId;

                iRet = cmd.ExecuteNonQuery();

                iRet = System.Convert.ToInt32(cmd.Parameters["@ERROR_NUM"].Value);

                if (cmd.Parameters["@ERROR_NUM"].Value != System.DBNull.Value) { ERROR_NUM = (System.Convert.ToInt32(cmd.Parameters["@ERROR_NUM"].Value)); }
                if (cmd.Parameters["@ERROR_MES"].Value != System.DBNull.Value) { strErr += (System.Convert.ToString(cmd.Parameters["@ERROR_MES"].Value)); }
                if (cmd.Parameters["@ID_START"].Value != System.DBNull.Value) { ID_START = (System.Convert.ToInt32(cmd.Parameters["@ID_START"].Value)); }
                if (cmd.Parameters["@ID_END"].Value != System.DBNull.Value) { ID_END = (System.Convert.ToInt32(cmd.Parameters["@ID_END"].Value)); }
                if (cmd.Parameters["@EARNING_SALDO"].Value != System.DBNull.Value) { EARNING_SALDO = (System.Convert.ToDecimal(cmd.Parameters["@EARNING_SALDO"].Value)); }
                if (cmd.Parameters["@EARNING_EXPENSE"].Value != System.DBNull.Value) { EARNING_EXPENSE = (System.Convert.ToDecimal(cmd.Parameters["@EARNING_EXPENSE"].Value)); }

                if (cmdSQL == null)
                {
                    cmd.Dispose();
                    DBConnection.Close();
                }
            }
            catch (System.Exception f)
            {
                strErr += (String.Format("\nНе удалось выполнить разноску платежа по долгам.\nТекст ошибки: {0}", f.Message));
            }

            return iRet;
        }

        /// <summary>
        /// Регистрирует оплату документа по форме 2 в ручном режиме без привязки к конкретному платежу
        /// </summary>
        /// <param name="objProfile">профайл</param>
        /// <param name="cmdSQL">SQL-команда</param>
        /// <param name="iWaybillId">УИ накладной</param>
        /// <param name="DOCUMENT_NUM">№ оплаченной ТТН</param>
        /// <param name="DOCUMENT_DATE">Дата оплаченной ТТН</param>
        /// <param name="DOCUMENT_CURRENCYSALDO">Сальдо ТТН</param>
        /// <param name="DOCUMENT_CURRENCYAMOUNTPAID">Олачено итого задолженности по ТТН</param>
        /// <param name="ERROR_NUM">№ ошибки</param>
        /// <param name="strErr">сообщение об ошибке</param>
        /// <returns>0 - удачное завершение операции</returns>
        public static System.Int32 PayDebitDocumentForm2(UniXP.Common.CProfile objProfile, System.Data.SqlClient.SqlCommand cmdSQL,
            System.Int32 iWaybillId, System.Guid uuidChildDepartId,
            ref System.Decimal FINDED_MONEY,  ref System.String DOCUMENT_NUM, ref System.DateTime DOCUMENT_DATE,
            ref System.Decimal DOCUMENT_CURRENCYSALDO, ref System.Decimal DOCUMENT_CURRENCYAMOUNTPAID,
            ref System.Int32 ERROR_NUM, ref System.String strErr)
        {
            System.Int32 iRet = -1;

            if (uuidChildDepartId.CompareTo(System.Guid.Empty) == 0)
            {
                strErr += ("Не указан дочерний клиент.");
                return iRet;
            }

            if (iWaybillId == 0)
            {
                strErr += ("Не указана накладная для оплаты.");
                return iRet;
            }

            System.Data.SqlClient.SqlConnection DBConnection = null;
            System.Data.SqlClient.SqlCommand cmd = null;
            try
            {
                if (cmdSQL == null)
                {
                    DBConnection = objProfile.GetDBSource();
                    if (DBConnection == null)
                    {
                        strErr += ("Не удалось получить соединение с базой данных.");
                        return iRet;
                    }
                    cmd = new System.Data.SqlClient.SqlCommand();
                    cmd.Connection = DBConnection;
                    cmd.CommandType = System.Data.CommandType.StoredProcedure;
                }
                else
                {
                    cmd = cmdSQL;
                    cmd.Parameters.Clear();
                }

                cmd.CommandTimeout = 600;
                cmd.CommandText = System.String.Format("[{0}].[dbo].[usp_PayDebitDocumentForm2ToSQLandIB]", objProfile.GetOptionsDllDBName());
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@RETURN_VALUE", System.Data.SqlDbType.Int, 4, System.Data.ParameterDirection.ReturnValue, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Waybill_Id", System.Data.SqlDbType.Int));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ChildDepart_Guid", System.Data.SqlDbType.UniqueIdentifier));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_NUM", System.Data.SqlDbType.Int, 8, System.Data.ParameterDirection.Output, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_MES", System.Data.SqlDbType.NVarChar, 4000) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@FINDED_MONEY", System.Data.SqlDbType.Money) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@DOCUMENT_NUM", System.Data.SqlDbType.NVarChar, 128) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@DOCUMENT_DATE", System.Data.SqlDbType.Date) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@DOCUMENT_CURRENCYSALDO", System.Data.SqlDbType.Money) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@DOCUMENT_CURRENCYAMOUNTPAID", System.Data.SqlDbType.Money) { Direction = System.Data.ParameterDirection.Output });


                cmd.Parameters["@Waybill_Id"].Value = iWaybillId;
                cmd.Parameters["@ChildDepart_Guid"].Value = uuidChildDepartId;

                iRet = cmd.ExecuteNonQuery();

                iRet = System.Convert.ToInt32(cmd.Parameters["@ERROR_NUM"].Value);

                if (cmd.Parameters["@ERROR_NUM"].Value != System.DBNull.Value) { ERROR_NUM = (System.Convert.ToInt32(cmd.Parameters["@ERROR_NUM"].Value)); }
                if (cmd.Parameters["@ERROR_MES"].Value != System.DBNull.Value) { strErr += (System.Convert.ToString(cmd.Parameters["@ERROR_MES"].Value)); }
                if (cmd.Parameters["@FINDED_MONEY"].Value != System.DBNull.Value) { FINDED_MONEY = (System.Convert.ToDecimal(cmd.Parameters["@FINDED_MONEY"].Value)); }
                if (cmd.Parameters["@DOCUMENT_CURRENCYSALDO"].Value != System.DBNull.Value) { DOCUMENT_CURRENCYSALDO = (System.Convert.ToDecimal(cmd.Parameters["@DOCUMENT_CURRENCYSALDO"].Value)); }
                if (cmd.Parameters["@DOCUMENT_CURRENCYAMOUNTPAID"].Value != System.DBNull.Value) { DOCUMENT_CURRENCYAMOUNTPAID = (System.Convert.ToDecimal(cmd.Parameters["@DOCUMENT_CURRENCYAMOUNTPAID"].Value)); }
                if (cmd.Parameters["@DOCUMENT_NUM"].Value != System.DBNull.Value) { DOCUMENT_NUM = (System.Convert.ToString(cmd.Parameters["@DOCUMENT_NUM"].Value)); }
                if (cmd.Parameters["@DOCUMENT_DATE"].Value != System.DBNull.Value) { DOCUMENT_DATE = (System.Convert.ToDateTime(cmd.Parameters["@DOCUMENT_DATE"].Value)); }

                if (cmdSQL == null)
                {
                    cmd.Dispose();
                    DBConnection.Close();
                }
            }
            catch (System.Exception f)
            {
                strErr += (String.Format("\nНе удалось выполнить оплату документа.\nТекст ошибки: {0}", f.Message));
            }

            return iRet;
        }
        /// <summary>
        /// Регистрирует оплату документа по форме 2 в ручном режиме с привязкой к конкретному платежу
        /// </summary>
        /// <param name="objProfile">профайл</param>
        /// <param name="cmdSQL">SQL-команда</param>
        /// <param name="iWaybillId">УИ накладной</param>
        /// <param name="uuidEarningId">УИ платежа</param>
        /// <param name="EARNING_SALDO">Сальдо платежа</param>
        /// <param name="EARNING_EXPENSE">Расход платежа</param>
        /// <param name="DOCUMENT_NUM">№ оплаченной ТТН</param>
        /// <param name="DOCUMENT_DATE">Дата оплаченной ТТН</param>
        /// <param name="DOCUMENT_CURRENCYSALDO">Сальдо ТТН</param>
        /// <param name="DOCUMENT_CURRENCYAMOUNTPAID">Олачено итого задолженности по ТТН</param>
        /// <param name="ERROR_NUM">№ ошибки</param>
        /// <param name="strErr">сообщение об ошибке</param>
        /// <returns>0 - удачное завершение операции</returns>
        public static System.Int32 PayDebitDocumentForm2(UniXP.Common.CProfile objProfile, System.Data.SqlClient.SqlCommand cmdSQL,
            System.Guid uuidEarningId, System.Int32 iWaybillId, 
            ref System.Decimal EARNING_SALDO, ref System.Decimal EARNING_EXPENSE, 
            ref System.String DOCUMENT_NUM, ref System.DateTime DOCUMENT_DATE,
            ref System.Decimal DOCUMENT_CURRENCYSALDO, ref System.Decimal DOCUMENT_CURRENCYAMOUNTPAID,
            ref System.Int32 ERROR_NUM, ref System.String strErr)
        {
            System.Int32 iRet = -1;

            if (uuidEarningId.CompareTo(System.Guid.Empty) == 0)
            {
                strErr += ("Не указан идентификатор платежа.");
                return iRet;
            }

            if (iWaybillId == 0)
            {
                strErr += ("Не указана накладная для оплаты.");
                return iRet;
            }

            System.Data.SqlClient.SqlConnection DBConnection = null;
            System.Data.SqlClient.SqlCommand cmd = null;
            try
            {
                if (cmdSQL == null)
                {
                    DBConnection = objProfile.GetDBSource();
                    if (DBConnection == null)
                    {
                        strErr += ("Не удалось получить соединение с базой данных.");
                        return iRet;
                    }
                    cmd = new System.Data.SqlClient.SqlCommand();
                    cmd.Connection = DBConnection;
                    cmd.CommandType = System.Data.CommandType.StoredProcedure;
                }
                else
                {
                    cmd = cmdSQL;
                    cmd.Parameters.Clear();
                }

                cmd.CommandTimeout = 600;
                cmd.Parameters.Clear();
                cmd.CommandText = System.String.Format("[{0}].[dbo].[usp_PayDebitDocumentForm2ByEarningToSQLandIB]", objProfile.GetOptionsDllDBName());
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@RETURN_VALUE", System.Data.SqlDbType.Int, 4, System.Data.ParameterDirection.ReturnValue, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Waybill_Id", System.Data.SqlDbType.Int));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Earning_Guid", System.Data.SqlDbType.UniqueIdentifier));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_NUM", System.Data.SqlDbType.Int, 8, System.Data.ParameterDirection.Output, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_MES", System.Data.SqlDbType.NVarChar, 4000) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@EARNING_SALDO", System.Data.SqlDbType.Money) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@EARNING_EXPENSE", System.Data.SqlDbType.Money) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@DOCUMENT_NUM", System.Data.SqlDbType.NVarChar, 128) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@DOCUMENT_DATE", System.Data.SqlDbType.Date) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@DOCUMENT_CURRENCYSALDO", System.Data.SqlDbType.Money) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@DOCUMENT_CURRENCYAMOUNTPAID", System.Data.SqlDbType.Money) { Direction = System.Data.ParameterDirection.Output });


                cmd.Parameters["@Waybill_Id"].Value = iWaybillId;
                cmd.Parameters["@Earning_Guid"].Value = uuidEarningId;

                iRet = cmd.ExecuteNonQuery();

                iRet = System.Convert.ToInt32(cmd.Parameters["@ERROR_NUM"].Value);

                if (cmd.Parameters["@ERROR_NUM"].Value != System.DBNull.Value) { ERROR_NUM = (System.Convert.ToInt32(cmd.Parameters["@ERROR_NUM"].Value)); }
                if (cmd.Parameters["@ERROR_MES"].Value != System.DBNull.Value) { strErr += (System.Convert.ToString(cmd.Parameters["@ERROR_MES"].Value)); }
                if (cmd.Parameters["@EARNING_SALDO"].Value != System.DBNull.Value) { EARNING_SALDO = (System.Convert.ToDecimal(cmd.Parameters["@EARNING_SALDO"].Value)); }
                if (cmd.Parameters["@EARNING_EXPENSE"].Value != System.DBNull.Value) { EARNING_EXPENSE = (System.Convert.ToDecimal(cmd.Parameters["@EARNING_EXPENSE"].Value)); }
                if (cmd.Parameters["@DOCUMENT_CURRENCYSALDO"].Value != System.DBNull.Value) { DOCUMENT_CURRENCYSALDO = (System.Convert.ToDecimal(cmd.Parameters["@DOCUMENT_CURRENCYSALDO"].Value)); }
                if (cmd.Parameters["@DOCUMENT_CURRENCYAMOUNTPAID"].Value != System.DBNull.Value) { DOCUMENT_CURRENCYAMOUNTPAID = (System.Convert.ToDecimal(cmd.Parameters["@DOCUMENT_CURRENCYAMOUNTPAID"].Value)); }
                if (cmd.Parameters["@DOCUMENT_NUM"].Value != System.DBNull.Value) { DOCUMENT_NUM = (System.Convert.ToString(cmd.Parameters["@DOCUMENT_NUM"].Value)); }
                if (cmd.Parameters["@DOCUMENT_DATE"].Value != System.DBNull.Value) { DOCUMENT_DATE = (System.Convert.ToDateTime(cmd.Parameters["@DOCUMENT_DATE"].Value)); }

                if (cmdSQL == null)
                {
                    cmd.Dispose();
                    DBConnection.Close();
                }
            }
            catch (System.Exception f)
            {
                strErr += (String.Format("\nНе удалось выполнить оплату документа.\nТекст ошибки: {0}", f.Message));
            }

            return iRet;
        }

        #endregion

        #region История разноски платежей
        public static List<CEarningHistory> GetEarningHistoryList(UniXP.Common.CProfile objProfile,
            System.Data.SqlClient.SqlCommand cmdSQL, System.Guid uuidEarningId, 
            ref System.String strErr)
        {
            List<CEarningHistory> objList = new List<CEarningHistory>();

            if(uuidEarningId.CompareTo(System.Guid.Empty) == 0)
            {
                return objList;
            }

            System.Data.SqlClient.SqlConnection DBConnection = null;
            System.Data.SqlClient.SqlCommand cmd = null;
            try
            {
                if (cmdSQL == null)
                {
                    DBConnection = objProfile.GetDBSource();
                    if (DBConnection == null)
                    {
                        strErr += ("Не удалось получить соединение с базой данных.");
                        return objList;
                    }
                    cmd = new System.Data.SqlClient.SqlCommand();
                    cmd.Connection = DBConnection;
                    cmd.CommandType = System.Data.CommandType.StoredProcedure;
                }
                else
                {
                    cmd = cmdSQL;
                    cmd.Parameters.Clear();
                }

                cmd.CommandText = System.String.Format("[{0}].[dbo].[usp_GetEarningHistoryFromIB]", objProfile.GetOptionsDllDBName());
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@RETURN_VALUE", System.Data.SqlDbType.Int, 4, System.Data.ParameterDirection.ReturnValue, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_NUM", System.Data.SqlDbType.Int, 8, System.Data.ParameterDirection.Output, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_MES", System.Data.SqlDbType.NVarChar, 4000) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Earning_Guid", System.Data.DbType.Guid));

                cmd.Parameters["@Earning_Guid"].Value = uuidEarningId;

                System.Data.SqlClient.SqlDataReader rs = cmd.ExecuteReader();
                System.Int32 iRecordCount = 0;
                if (rs.HasRows)
                {
                    CEarningHistory objEarningHistory = null;
                    while (rs.Read())
                    {
                        iRecordCount++;

                        objEarningHistory = new CEarningHistory();

                        objEarningHistory.Waybill_Id = ((rs["WAYBILL_ID"] == System.DBNull.Value) ? 0 : (System.Int32)rs["WAYBILL_ID"]);
                        objEarningHistory.Waybill_Num = ((rs["WAYBILL_NUM"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["WAYBILL_NUM"]);
                        objEarningHistory.Waybill_ShipDate = ((rs["WAYBILL_SHIPDATE"] == System.DBNull.Value) ? System.DateTime.MinValue : (System.DateTime)rs["WAYBILL_SHIPDATE"]);
                        objEarningHistory.Customer_Name = ((rs["CUSTOMER_NAME"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["CUSTOMER_NAME"]);
                        objEarningHistory.Waybill_TotalPrice = ((rs["WAYBILL_TOTALPRICE"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_TOTALPRICE"]));
                        objEarningHistory.Waybill_Saldo = ((rs["WAYBILL_SALDO"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_SALDO"]));
                        objEarningHistory.Company_Name = ((rs["COMPANY_NAME"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["COMPANY_NAME"]);
                        objEarningHistory.Payment_Value = ((rs["PAYMENTS_VALUE"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["PAYMENTS_VALUE"]));
                        objEarningHistory.Waybill_Bonus = ((rs["WAYBILL_BONUS"] == System.DBNull.Value) ? false : System.Convert.ToBoolean(rs["WAYBILL_BONUS"]));
                        objEarningHistory.Waybill_Shipped = ((rs["WAYBILL_SHIPPED"] == System.DBNull.Value) ? false : System.Convert.ToBoolean(rs["WAYBILL_SHIPPED"]));
                        objEarningHistory.Customer_Id = ((rs["CUSTOMER_ID"] == System.DBNull.Value) ? 0 : (System.Int32)rs["CUSTOMER_ID"]);
                        objEarningHistory.Company_Id = ((rs["COMPANY_ID"] == System.DBNull.Value) ? 0 : (System.Int32)rs["COMPANY_ID"]);
                        objEarningHistory.ChildCust_Id = ((rs["CHILDCUST_ID"] == System.DBNull.Value) ? 0 : (System.Int32)rs["CHILDCUST_ID"]);
                        objEarningHistory.Currency_Code = ((rs["CURRENCY_CODE"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["CURRENCY_CODE"]);
                        objEarningHistory.Company_Acronym = ((rs["COMPANY_ACRONYM"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["COMPANY_ACRONYM"]);
                        objEarningHistory.Payment_OperDate = ((rs["PAYMENTS_OPERDATE"] == System.DBNull.Value) ? System.DateTime.MinValue : (System.DateTime)rs["PAYMENTS_OPERDATE"]);
                        objEarningHistory.Earning_BankDate = ((rs["BANKDATE"] == System.DBNull.Value) ? System.DateTime.MinValue : (System.DateTime)rs["BANKDATE"]);
                        objEarningHistory.OperCode = ((rs["PAYMENTS_PAYMENTSCODE"] == System.DBNull.Value) ? 0 : (System.Int32)rs["PAYMENTS_PAYMENTSCODE"]);
                        objEarningHistory.OperName = ((rs["PaymentOperationType_Name"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["PaymentOperationType_Name"]);

                        if (objEarningHistory != null) { objList.Add(objEarningHistory); }
                    }
                }
                rs.Dispose();
                if (cmdSQL == null)
                {
                    cmd.Dispose();
                    DBConnection.Close();
                }
            }
            catch (System.Exception f)
            {
                strErr += (String.Format("\nНе удалось получить историю разноски платежей.\nТекст ошибки: {0}", f.Message));
            }
            return objList;
        }

        public static List<CEarningHistory> GetCEarningHistoryList(UniXP.Common.CProfile objProfile,
            System.Data.SqlClient.SqlCommand cmdSQL, System.Guid uuidEarningId,
            ref System.String strErr)
        {
            List<CEarningHistory> objList = new List<CEarningHistory>();

            if (uuidEarningId.CompareTo(System.Guid.Empty) == 0)
            {
                return objList;
            }

            System.Data.SqlClient.SqlConnection DBConnection = null;
            System.Data.SqlClient.SqlCommand cmd = null;
            try
            {
                if (cmdSQL == null)
                {
                    DBConnection = objProfile.GetDBSource();
                    if (DBConnection == null)
                    {
                        strErr += ("Не удалось получить соединение с базой данных.");
                        return objList;
                    }
                    cmd = new System.Data.SqlClient.SqlCommand();
                    cmd.Connection = DBConnection;
                    cmd.CommandType = System.Data.CommandType.StoredProcedure;
                }
                else
                {
                    cmd = cmdSQL;
                    cmd.Parameters.Clear();
                }

                cmd.CommandText = System.String.Format("[{0}].[dbo].[usp_GetCEarningHistoryFromIB]", objProfile.GetOptionsDllDBName());
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@RETURN_VALUE", System.Data.SqlDbType.Int, 4, System.Data.ParameterDirection.ReturnValue, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_NUM", System.Data.SqlDbType.Int, 8, System.Data.ParameterDirection.Output, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_MES", System.Data.SqlDbType.NVarChar, 4000) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Earning_Guid", System.Data.DbType.Guid));

                cmd.Parameters["@Earning_Guid"].Value = uuidEarningId;

                System.Data.SqlClient.SqlDataReader rs = cmd.ExecuteReader();
                System.Int32 iRecordCount = 0;
                if (rs.HasRows)
                {
                    CEarningHistory objEarningHistory = null;
                    while (rs.Read())
                    {
                        iRecordCount++;

                        objEarningHistory = new CEarningHistory();

                        objEarningHistory.Waybill_Id = ((rs["WAYBILL_ID"] == System.DBNull.Value) ? 0 : (System.Int32)rs["WAYBILL_ID"]);
                        objEarningHistory.Waybill_Num = ((rs["WAYBILL_NUM"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["WAYBILL_NUM"]);
                        objEarningHistory.Waybill_ShipDate = ((rs["WAYBILL_SHIPDATE"] == System.DBNull.Value) ? System.DateTime.MinValue : (System.DateTime)rs["WAYBILL_SHIPDATE"]);
                        objEarningHistory.Customer_Name = ((rs["CUSTOMER_NAME"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["CUSTOMER_NAME"]);

                        //objEarningHistory.Waybill_TotalPrice = ((rs["WAYBILL_TOTALPRICE"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_TOTALPRICE"]));
                        //objEarningHistory.Waybill_Saldo = ((rs["WAYBILL_SALDO"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_SALDO"]));
                        
                        objEarningHistory.Company_Name = ((rs["COMPANY_NAME"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["COMPANY_NAME"]);
                        objEarningHistory.Payment_Value = ((rs["PAYMENTS_VALUE"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["PAYMENTS_VALUE"]));
                        objEarningHistory.Waybill_Bonus = ((rs["WAYBILL_BONUS"] == System.DBNull.Value) ? false : System.Convert.ToBoolean(rs["WAYBILL_BONUS"]));
                        objEarningHistory.Customer_Id = ((rs["CUSTOMER_ID"] == System.DBNull.Value) ? 0 : (System.Int32)rs["CUSTOMER_ID"]);
                        objEarningHistory.Company_Id = ((rs["COMPANY_ID"] == System.DBNull.Value) ? 0 : (System.Int32)rs["COMPANY_ID"]);
                        objEarningHistory.ChildCust_Id = ((rs["CHILDCUST_ID"] == System.DBNull.Value) ? 0 : (System.Int32)rs["CHILDCUST_ID"]);
                        objEarningHistory.Currency_Code = ((rs["CURRENCY_CODE"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["CURRENCY_CODE"]);
                        objEarningHistory.Company_Acronym = ((rs["COMPANY_ACRONYM"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["COMPANY_ACRONYM"]);
                        objEarningHistory.Payment_OperDate = ((rs["PAYMENTS_OPERDATE"] == System.DBNull.Value) ? System.DateTime.MinValue : (System.DateTime)rs["PAYMENTS_OPERDATE"]);
                        objEarningHistory.Earning_BankDate = ((rs["BANKDATE"] == System.DBNull.Value) ? System.DateTime.MinValue : (System.DateTime)rs["BANKDATE"]);

                        objEarningHistory.Waybill_CurrencyTotalPrice = ((rs["WAYBILL_CURRENCYTOTALPRICE"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_CURRENCYTOTALPRICE"]));
                        objEarningHistory.Waybill_CurrencySaldo = ((rs["WAYBILL_CURRENCYSALDO"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_CURRENCYSALDO"]));
                        objEarningHistory.ChildCust_Code = ((rs["CHILDCUST_CODE"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["CHILDCUST_CODE"]);
                        objEarningHistory.ChildCust_Name = ((rs["CHILDCUST_NAME"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["CHILDCUST_NAME"]);

                        if(rs["WAYBILL_SHIPPED"] == System.DBNull.Value)
                        {
                            objEarningHistory.Waybill_Shipped = false;
                            objEarningHistory.Drop = "";
                        }
                        else
                        {
                            switch (System.Convert.ToInt32(rs["WAYBILL_SHIPPED"]))
                            {
                                case -1:
                                    objEarningHistory.Drop = "+";
                                    objEarningHistory.Waybill_Shipped = false;
                                    break;
                                case 0:
                                    objEarningHistory.Drop = "";
                                    objEarningHistory.Waybill_Shipped = false;
                                    break;
                                case 1:
                                    objEarningHistory.Drop = "отгружена";
                                    objEarningHistory.Waybill_Shipped = true;
                                    break;
                                default:
                                    objEarningHistory.Drop = "";
                                    objEarningHistory.Waybill_Shipped = false;
                                    break;
                            }
                        }

                        if (objEarningHistory != null) { objList.Add(objEarningHistory); }
                    }
                }
                rs.Dispose();
                if (cmdSQL == null)
                {
                    cmd.Dispose();
                    DBConnection.Close();
                }
            }
            catch (System.Exception f)
            {
                strErr += (String.Format("\nНе удалось получить историю разноски платежей.\nТекст ошибки: {0}", f.Message));
            }
            return objList;
        }
        
        #endregion

        #region Список оплаченных документов по форме 1
        /// <summary>
        /// Возвращает список оплаченных документов по форме 1
        /// </summary>
        /// <param name="objProfile">профайл</param>
        /// <param name="cmdSQL">SQL-команда</param>
        /// <param name="uuidCompanyId">идентификатор компании</param>
        /// <param name="uuidCustomerId">идентификатор клиента</param>
        /// <param name="dtBeginDate">начало периода для поиска</param>
        /// <param name="dtEndDate">конец периода для поиска</param>
        /// <param name="strWaybillNum">№ накладной</param>
        /// <param name="strErr"соообщение об ошибке></param>
        /// <returns>список оплаченных документов</returns>
        public static List<CPaidDocument> GetPaidDocumentFormPay1List(UniXP.Common.CProfile objProfile,
            System.Data.SqlClient.SqlCommand cmdSQL,
            System.Guid uuidCompanyId, System.Guid uuidCustomerId, System.DateTime dtBeginDate, System.DateTime dtEndDate, System.String strWaybillNum,
            ref System.String strErr)
        {
            List<CPaidDocument> objList = new List<CPaidDocument>();

            if(uuidCompanyId.CompareTo(System.Guid.Empty) == 0)
            {
                return objList;
            }

            System.Data.SqlClient.SqlConnection DBConnection = null;
            System.Data.SqlClient.SqlCommand cmd = null;
            try
            {
                if (cmdSQL == null)
                {
                    DBConnection = objProfile.GetDBSource();
                    if (DBConnection == null)
                    {
                        strErr += ("Не удалось получить соединение с базой данных.");
                        return objList;
                    }
                    cmd = new System.Data.SqlClient.SqlCommand();
                    cmd.Connection = DBConnection;
                    cmd.CommandType = System.Data.CommandType.StoredProcedure;
                }
                else
                {
                    cmd = cmdSQL;
                    cmd.Parameters.Clear();
                }

                cmd.CommandText = System.String.Format("[{0}].[dbo].[usp_GetDocForm1ForDecPaymentFromIB]", objProfile.GetOptionsDllDBName());
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@RETURN_VALUE", System.Data.SqlDbType.Int, 4, System.Data.ParameterDirection.ReturnValue, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_NUM", System.Data.SqlDbType.Int, 8, System.Data.ParameterDirection.Output, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_MES", System.Data.SqlDbType.NVarChar, 4000) { Direction = System.Data.ParameterDirection.Output });
                if (uuidCustomerId.CompareTo(System.Guid.Empty) != 0)
                {
                    cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Customer_Guid", System.Data.SqlDbType.UniqueIdentifier));
                    cmd.Parameters["@Customer_Guid"].Value = uuidCustomerId;
                }
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Begin_Date", System.Data.SqlDbType.Date));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@End_Date", System.Data.SqlDbType.Date));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Company_Guid", System.Data.SqlDbType.UniqueIdentifier));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Waybill_Num", System.Data.DbType.String));

                cmd.Parameters["@Company_Guid"].Value = uuidCompanyId;
                cmd.Parameters["@Begin_Date"].Value = dtBeginDate;
                cmd.Parameters["@End_Date"].Value = dtEndDate;
                cmd.Parameters["@Waybill_Num"].Value = strWaybillNum;

                System.Data.SqlClient.SqlDataReader rs = cmd.ExecuteReader();
                System.Int32 iRecordCount = 0;
                if (rs.HasRows)
                {
                    CPaidDocument objPaidDocument = null;
                    while (rs.Read())
                    {
                        iRecordCount++;

                        objPaidDocument = new CPaidDocument();
                        objPaidDocument.Currency_Code = ((rs["CURRENCY_CODE"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["CURRENCY_CODE"]);
                        objPaidDocument.Waybill_Id = ((rs["WAYBILL_ID"] == System.DBNull.Value) ? 0 : (System.Int32)rs["WAYBILL_ID"]);
                        objPaidDocument.Waybill_Shipped = ((rs["WAYBILL_SHIPPED"] == System.DBNull.Value) ? 0 : (System.Int32)rs["WAYBILL_SHIPPED"]);
                        objPaidDocument.Waybill_Num = ((rs["WAYBILL_NUM"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["WAYBILL_NUM"]);
                        objPaidDocument.Customer_Id = ((rs["CUSTOMER_ID"] == System.DBNull.Value) ? 0 : (System.Int32)rs["CUSTOMER_ID"]);
                        objPaidDocument.Depart_Code = ((rs["DEPART_CODE"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["DEPART_CODE"]);
                        objPaidDocument.Customer_Name = ((rs["CUSTOMER_NAME"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["CUSTOMER_NAME"]);
                        objPaidDocument.Waybill_BeginDate = ((rs["WAYBILL_BEGINDATE"] == System.DBNull.Value) ? System.DateTime.MinValue : (System.DateTime)rs["WAYBILL_BEGINDATE"]);
                        objPaidDocument.Waybill_ShipDate = ((rs["WAYBILL_SHIPDATE"] == System.DBNull.Value) ? System.DateTime.MinValue : (System.DateTime)rs["WAYBILL_SHIPDATE"]);
                        objPaidDocument.Waybill_AllPrice = ((rs["WAYBILL_ALLPRICE"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_ALLPRICE"]));
                        objPaidDocument.Waybill_TotalPrice = ((rs["WAYBILL_TOTALPRICE"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_TOTALPRICE"]));
                        objPaidDocument.Waybill_RetAllPrice = ((rs["WAYBILL_RETALLPRICE"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_RETALLPRICE"]));
                        objPaidDocument.Waybill_AmountPaid = ((rs["WAYBILL_AMOUNTPAID"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_AMOUNTPAID"]));
                        objPaidDocument.Waybill_DateLastPaid = ((rs["WAYBILL_DATELASTPAID"] == System.DBNull.Value) ? System.DateTime.MinValue : (System.DateTime)rs["WAYBILL_DATELASTPAID"]);
                        objPaidDocument.Waybill_Saldo = ((rs["WAYBILL_SALDO"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_SALDO"]));

                        objPaidDocument.Waybill_CurrencyAllPrice = ((rs["WAYBILL_CURRENCYALLPRICE"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_CURRENCYALLPRICE"]));
                        objPaidDocument.Waybill_CurrencyTotalPrice = ((rs["WAYBILL_CURRENCYTOTALPRICE"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_CURRENCYTOTALPRICE"]));
                        objPaidDocument.Waybill_CurrencyAmountPaid = ((rs["WAYBILL_CURRENCYAMOUNTPAID"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_CURRENCYAMOUNTPAID"]));
                        objPaidDocument.Waybill_CurrencySaldo = ((rs["WAYBILL_CURRENCYSALDO"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_CURRENCYSALDO"]));
                        objPaidDocument.Stock_Name = ((rs["STOCK_NAME"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["STOCK_NAME"]);
                        objPaidDocument.Company_Acronym = ((rs["COMPANY_ACRONYM"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["COMPANY_ACRONYM"]);
                        objPaidDocument.Waybill_ShipModeId = ((rs["WAYBILL_SHIPMODE"] == System.DBNull.Value) ? 0 : (System.Int32)rs["WAYBILL_SHIPMODE"]);
                        objPaidDocument.Waybill_ShipModeName = ((rs["WAYBILL_SHIPMODE_NAME"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["WAYBILL_SHIPMODE_NAME"]);

                        objPaidDocument.Stock_Id = ((rs["STOCK_ID"] == System.DBNull.Value) ? 0 : (System.Int32)rs["STOCK_ID"]);
                        objPaidDocument.ChildCust_Id = ((rs["CHILDCUST_ID"] == System.DBNull.Value) ? 0 : (System.Int32)rs["CHILDCUST_ID"]);
                        objPaidDocument.Company_Id = ((rs["COMPANY_ID"] == System.DBNull.Value) ? 0 : (System.Int32)rs["COMPANY_ID"]);
                        objPaidDocument.PaymentForm_id = ((rs["PAYMENTFORM_ID"] == System.DBNull.Value) ? 0 : (System.Int32)rs["PAYMENTFORM_ID"]);
                        objPaidDocument.Waybill_ExportModeId = ((rs["WAYBILL_EXPORTMODE"] == System.DBNull.Value) ? 0 : (System.Int32)rs["WAYBILL_EXPORTMODE"]);
                        objPaidDocument.Waybill_ReturnId = ((rs["WAYBILL_RETURN"] == System.DBNull.Value) ? 0 : (System.Int32)rs["WAYBILL_RETURN"]);
                        objPaidDocument.Waybill_Quantity = ((rs["QUANTITY"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["QUANTITY"]));
                        objPaidDocument.Waybill_MoneyBonusId = ((rs["WAYBILL_MONEYBONUS"] == System.DBNull.Value) ? 0 : (System.Int32)rs["WAYBILL_MONEYBONUS"]);
                        if (objPaidDocument != null) { objList.Add(objPaidDocument); }
                    }
                }
                rs.Dispose();
                if (cmdSQL == null)
                {
                    cmd.Dispose();
                    DBConnection.Close();
                }
            }
            catch (System.Exception f)
            {
                strErr += (String.Format("\nНе удалось получить список оплаченных документов.\nТекст ошибки: {0}", f.Message));
            }
            return objList;
        }

        #endregion

        #region Список оплаченных документов по форме 2
        /// <summary>
        /// Возвращает список оплаченных документов по форме 1
        /// </summary>
        /// <param name="objProfile">профайл</param>
        /// <param name="cmdSQL">SQL-команда</param>
        /// <param name="uuidCompanyId">идентификатор компании</param>
        /// <param name="uuidCustomerId">идентификатор клиента</param>
        /// <param name="uuidChildDepartId">идентификатор клиента</param>
        /// <param name="dtBeginDate">начало периода для поиска</param>
        /// <param name="dtEndDate">конец периода для поиска</param>
        /// <param name="strWaybillNum">№ накладной</param>
        /// <param name="strErr"соообщение об ошибке></param>
        /// <returns>список оплаченных документов</returns>
        public static List<CPaidDocument> GetPaidDocumentFormPay2List(UniXP.Common.CProfile objProfile,
            System.Data.SqlClient.SqlCommand cmdSQL,
            System.Guid uuidCompanyId, System.Guid uuidCustomerId, System.Guid uuidChildDepartId, 
            System.DateTime dtBeginDate, System.DateTime dtEndDate, System.String strWaybillNum,
            ref System.String strErr)
        {
            List<CPaidDocument> objList = new List<CPaidDocument>();

            System.Data.SqlClient.SqlConnection DBConnection = null;
            System.Data.SqlClient.SqlCommand cmd = null;
            try
            {
                if (cmdSQL == null)
                {
                    DBConnection = objProfile.GetDBSource();
                    if (DBConnection == null)
                    {
                        strErr += ("Не удалось получить соединение с базой данных.");
                        return objList;
                    }
                    cmd = new System.Data.SqlClient.SqlCommand();
                    cmd.Connection = DBConnection;
                    cmd.CommandType = System.Data.CommandType.StoredProcedure;
                }
                else
                {
                    cmd = cmdSQL;
                    cmd.Parameters.Clear();
                }

                cmd.CommandText = System.String.Format("[{0}].[dbo].[usp_GetDocForm2ForDecPaymentFromIB]", objProfile.GetOptionsDllDBName());
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@RETURN_VALUE", System.Data.SqlDbType.Int, 4, System.Data.ParameterDirection.ReturnValue, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_NUM", System.Data.SqlDbType.Int, 8, System.Data.ParameterDirection.Output, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_MES", System.Data.SqlDbType.NVarChar, 4000) { Direction = System.Data.ParameterDirection.Output });
                if (uuidCustomerId.CompareTo(System.Guid.Empty) != 0)
                {
                    cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Customer_Guid", System.Data.SqlDbType.UniqueIdentifier));
                    cmd.Parameters["@Customer_Guid"].Value = uuidCustomerId;
                }
                if (uuidChildDepartId.CompareTo(System.Guid.Empty) != 0)
                {
                    cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ChildDepart_Guid", System.Data.SqlDbType.UniqueIdentifier));
                    cmd.Parameters["@ChildDepart_Guid"].Value = uuidChildDepartId;
                }
                if (uuidCompanyId.CompareTo(System.Guid.Empty) != 0)
                {
                    cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Company_Guid", System.Data.SqlDbType.UniqueIdentifier));
                    cmd.Parameters["@Company_Guid"].Value = uuidCompanyId;
                }
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Begin_Date", System.Data.SqlDbType.Date));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@End_Date", System.Data.SqlDbType.Date));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Waybill_Num", System.Data.DbType.String));

                cmd.Parameters["@Begin_Date"].Value = dtBeginDate;
                cmd.Parameters["@End_Date"].Value = dtEndDate;
                cmd.Parameters["@Waybill_Num"].Value = strWaybillNum;

                System.Data.SqlClient.SqlDataReader rs = cmd.ExecuteReader();
                System.Int32 iRecordCount = 0;
                if (rs.HasRows)
                {
                    CPaidDocument objPaidDocument = null;
                    while (rs.Read())
                    {
                        iRecordCount++;

                        objPaidDocument = new CPaidDocument();
                        objPaidDocument.Currency_Code = ((rs["CURRENCY_CODE"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["CURRENCY_CODE"]);
                        objPaidDocument.Waybill_Id = ((rs["WAYBILL_ID"] == System.DBNull.Value) ? 0 : (System.Int32)rs["WAYBILL_ID"]);
                        objPaidDocument.Waybill_Shipped = ((rs["WAYBILL_SHIPPED"] == System.DBNull.Value) ? 0 : (System.Int32)rs["WAYBILL_SHIPPED"]);
                        objPaidDocument.Waybill_Num = ((rs["WAYBILL_NUM"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["WAYBILL_NUM"]);
                        objPaidDocument.Customer_Id = ((rs["CUSTOMER_ID"] == System.DBNull.Value) ? 0 : (System.Int32)rs["CUSTOMER_ID"]);
                        objPaidDocument.Depart_Code = ((rs["DEPART_CODE"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["DEPART_CODE"]);
                        objPaidDocument.Customer_Name = ((rs["CUSTOMER_NAME"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["CUSTOMER_NAME"]);
                        objPaidDocument.Waybill_BeginDate = ((rs["WAYBILL_BEGINDATE"] == System.DBNull.Value) ? System.DateTime.MinValue : (System.DateTime)rs["WAYBILL_BEGINDATE"]);
                        objPaidDocument.Waybill_ShipDate = ((rs["WAYBILL_SHIPDATE"] == System.DBNull.Value) ? System.DateTime.MinValue : (System.DateTime)rs["WAYBILL_SHIPDATE"]);
                        objPaidDocument.Waybill_AllPrice = ((rs["WAYBILL_ALLPRICE"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_ALLPRICE"]));
                        objPaidDocument.Waybill_TotalPrice = ((rs["WAYBILL_TOTALPRICE"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_TOTALPRICE"]));
                        objPaidDocument.Waybill_RetAllPrice = ((rs["WAYBILL_RETALLPRICE"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_RETALLPRICE"]));
                        objPaidDocument.Waybill_AmountPaid = ((rs["WAYBILL_AMOUNTPAID"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_AMOUNTPAID"]));
                        objPaidDocument.Waybill_DateLastPaid = ((rs["WAYBILL_DATELASTPAID"] == System.DBNull.Value) ? System.DateTime.MinValue : (System.DateTime)rs["WAYBILL_DATELASTPAID"]);
                        objPaidDocument.Waybill_Saldo = ((rs["WAYBILL_SALDO"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_SALDO"]));

                        objPaidDocument.Waybill_CurrencyAllPrice = ((rs["WAYBILL_CURRENCYALLPRICE"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_CURRENCYALLPRICE"]));
                        objPaidDocument.Waybill_CurrencyTotalPrice = ((rs["WAYBILL_CURRENCYTOTALPRICE"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_CURRENCYTOTALPRICE"]));
                        objPaidDocument.Waybill_CurrencyAmountPaid = ((rs["WAYBILL_CURRENCYAMOUNTPAID"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_CURRENCYAMOUNTPAID"]));
                        objPaidDocument.Waybill_CurrencySaldo = ((rs["WAYBILL_CURRENCYSALDO"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_CURRENCYSALDO"]));
                        objPaidDocument.Stock_Name = ((rs["STOCK_NAME"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["STOCK_NAME"]);
                        objPaidDocument.Company_Acronym = ((rs["COMPANY_ACRONYM"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["COMPANY_ACRONYM"]);
                        objPaidDocument.Waybill_ShipModeId = ((rs["WAYBILL_SHIPMODE"] == System.DBNull.Value) ? 0 : (System.Int32)rs["WAYBILL_SHIPMODE"]);
                        objPaidDocument.Waybill_ShipModeName = ((rs["WAYBILL_SHIPMODE_NAME"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["WAYBILL_SHIPMODE_NAME"]);

                        objPaidDocument.Stock_Id = ((rs["STOCK_ID"] == System.DBNull.Value) ? 0 : (System.Int32)rs["STOCK_ID"]);
                        objPaidDocument.ChildCust_Id = ((rs["CHILDCUST_ID"] == System.DBNull.Value) ? 0 : (System.Int32)rs["CHILDCUST_ID"]);
                        objPaidDocument.ChildCust_Code = ((rs["DEPART_CODE"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["DEPART_CODE"]);
                        objPaidDocument.ChildCust_Name = ((rs["CHILDCUST_NAME"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["CHILDCUST_NAME"]);
                        objPaidDocument.Company_Id = ((rs["COMPANY_ID"] == System.DBNull.Value) ? 0 : (System.Int32)rs["COMPANY_ID"]);
                        objPaidDocument.PaymentForm_id = ((rs["PAYMENTFORM_ID"] == System.DBNull.Value) ? 0 : (System.Int32)rs["PAYMENTFORM_ID"]);
                        objPaidDocument.Waybill_ExportModeId = ((rs["WAYBILL_EXPORTMODE"] == System.DBNull.Value) ? 0 : (System.Int32)rs["WAYBILL_EXPORTMODE"]);
                        objPaidDocument.Waybill_ReturnId = ((rs["WAYBILL_RETURN"] == System.DBNull.Value) ? 0 : (System.Int32)rs["WAYBILL_RETURN"]);
                        objPaidDocument.Waybill_Quantity = ((rs["QUANTITY"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["QUANTITY"]));
                        objPaidDocument.Waybill_MoneyBonusId = ((rs["WAYBILL_MONEYBONUS"] == System.DBNull.Value) ? 0 : (System.Int32)rs["WAYBILL_MONEYBONUS"]);
                        if (objPaidDocument != null) { objList.Add(objPaidDocument); }
                    }
                }
                rs.Dispose();
                if (cmdSQL == null)
                {
                    cmd.Dispose();
                    DBConnection.Close();
                }
            }
            catch (System.Exception f)
            {
                strErr += (String.Format("\nНе удалось получить список оплаченных документов.\nТекст ошибки: {0}", f.Message));
            }
            return objList;
        }

        #endregion

        #region Сторно оплаты по форме 1
        /// <summary>
        /// Сторно оплаты по форме 1
        /// </summary>
        /// <param name="objProfile">профайл</param>
        /// <param name="cmdSQL">SQL-команда</param>
        /// <param name="Earning_Guid">УИ платежа</param>
        /// <param name="Waybill_Id">УИ оплаченного документа</param>
        /// <param name="AMOUNT">сумма к Сторно</param>
        /// <param name="DATELASTPAID">дата операции</param>
        /// <param name="DEC_AMOUNT">отсторнированная сумма</param>
        /// <param name="WAYBILL_AMOUNTPAID">оплачено по документу</param>
        /// <param name="WAYBILL_SALDO">Сальдо документа</param>
        /// <param name="ERROR_NUM">№ ошибки</param>
        /// <param name="strErr">сообщение об ошибке</param>
        /// <returns>0 - удачное завершение операции</returns>
        public static System.Int32 DePayDebitDocumentForm1(UniXP.Common.CProfile objProfile, System.Data.SqlClient.SqlCommand cmdSQL,
            System.Guid Earning_Guid, System.Int32 Waybill_Id, System.Decimal AMOUNT, System.DateTime DATELASTPAID, 
            ref System.Decimal DEC_AMOUNT,  ref System.Decimal WAYBILL_AMOUNTPAID, ref System.Decimal WAYBILL_SALDO,
            ref System.Int32 ERROR_NUM, ref System.String strErr)
        {
            System.Int32 iRet = -1;

            if(Waybill_Id <= 0)
            {
                strErr += ("Не указан идентификатор оплаченного документа.");
                return iRet;
            }

            System.Data.SqlClient.SqlConnection DBConnection = null;
            System.Data.SqlClient.SqlCommand cmd = null;
            try
            {
                if (cmdSQL == null)
                {
                    DBConnection = objProfile.GetDBSource();
                    if (DBConnection == null)
                    {
                        strErr += ("Не удалось получить соединение с базой данных.");
                        return iRet;
                    }
                    cmd = new System.Data.SqlClient.SqlCommand();
                    cmd.Connection = DBConnection;
                    cmd.CommandType = System.Data.CommandType.StoredProcedure;
                }
                else
                {
                    cmd = cmdSQL;
                    cmd.Parameters.Clear();
                }

                cmd.CommandText = System.String.Format("[{0}].[dbo].[usp_DecPayDocumentForm1ToSQLandIB]", objProfile.GetOptionsDllDBName());
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@RETURN_VALUE", System.Data.SqlDbType.Int, 4, System.Data.ParameterDirection.ReturnValue, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Waybill_Id", System.Data.SqlDbType.Int));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@AMOUNT", System.Data.SqlDbType.Money));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@DATELASTPAID", System.Data.SqlDbType.Date));

                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_NUM", System.Data.SqlDbType.Int, 8, System.Data.ParameterDirection.Output, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_MES", System.Data.SqlDbType.NVarChar, 4000) { Direction = System.Data.ParameterDirection.Output });

                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@DEC_AMOUNT", System.Data.SqlDbType.Money) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@WAYBILL_AMOUNTPAID", System.Data.SqlDbType.Money) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@WAYBILL_SALDO", System.Data.SqlDbType.Money) { Direction = System.Data.ParameterDirection.Output });

                if (Earning_Guid.CompareTo(System.Guid.Empty) != 0)
                {
                    cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Earning_Guid", System.Data.SqlDbType.UniqueIdentifier));
                    cmd.Parameters["@Earning_Guid"].Value = Earning_Guid;
                }
                cmd.Parameters["@Waybill_Id"].Value = Waybill_Id;
                cmd.Parameters["@AMOUNT"].Value = AMOUNT;
                cmd.Parameters["@DATELASTPAID"].Value = DATELASTPAID;

                iRet = cmd.ExecuteNonQuery();

                iRet = System.Convert.ToInt32(cmd.Parameters["@ERROR_NUM"].Value);

                if (cmd.Parameters["@ERROR_NUM"].Value != System.DBNull.Value) { ERROR_NUM = (System.Convert.ToInt32(cmd.Parameters["@ERROR_NUM"].Value)); }
                if (cmd.Parameters["@ERROR_MES"].Value != System.DBNull.Value) { strErr += (System.Convert.ToString(cmd.Parameters["@ERROR_MES"].Value)); }
                if (cmd.Parameters["@DEC_AMOUNT"].Value != System.DBNull.Value) { DEC_AMOUNT = (System.Convert.ToDecimal(cmd.Parameters["@DEC_AMOUNT"].Value)); }
                if (cmd.Parameters["@WAYBILL_AMOUNTPAID"].Value != System.DBNull.Value) { WAYBILL_AMOUNTPAID = (System.Convert.ToDecimal(cmd.Parameters["@WAYBILL_AMOUNTPAID"].Value)); }
                if (cmd.Parameters["@WAYBILL_SALDO"].Value != System.DBNull.Value) { WAYBILL_SALDO = (System.Convert.ToDecimal(cmd.Parameters["@WAYBILL_SALDO"].Value)); }

                if (cmdSQL == null)
                {
                    cmd.Dispose();
                    DBConnection.Close();
                }
            }
            catch (System.Exception f)
            {
                strErr += (String.Format("\nНе удалось выполнить Сторно документа.\nТекст ошибки: {0}", f.Message));
            }

            return iRet;
        }

        #endregion

        #region Сторно оплаты по форме 2
        /// <summary>
        /// Сторно оплаты по форме 2
        /// </summary>
        /// <param name="objProfile">профайл</param>
        /// <param name="cmdSQL">SQL-команда</param>
        /// <param name="Earning_Guid">УИ платежа</param>
        /// <param name="Waybill_Id">УИ оплаченного документа</param>
        /// <param name="AMOUNT">сумма к Сторно</param>
        /// <param name="DATELASTPAID">дата операции</param>
        /// <param name="DEC_AMOUNT">отсторнированная сумма</param>
        /// <param name="WAYBILL_CURRENCYAMOUNTPAID">оплачено по документу</param>
        /// <param name="WAYBILL_CURRENCYSALDO">Сальдо документа</param>
        /// <param name="ERROR_NUM">№ ошибки</param>
        /// <param name="strErr">сообщение об ошибке</param>
        /// <returns>0 - удачное завершение операции</returns>
        public static System.Int32 DePayDebitDocumentForm2(UniXP.Common.CProfile objProfile, System.Data.SqlClient.SqlCommand cmdSQL,
            System.Guid Earning_Guid, System.Int32 Waybill_Id, System.Decimal AMOUNT, System.DateTime DATELASTPAID,
            ref System.Decimal DEC_AMOUNT, ref System.Decimal WAYBILL_CURRENCYAMOUNTPAID, ref System.Decimal WAYBILL_CURRENCYSALDO,
            ref System.Int32 ERROR_NUM, ref System.String strErr)
        {
            System.Int32 iRet = -1;

            if (Waybill_Id <= 0)
            {
                strErr += ("Не указан идентификатор оплаченного документа.");
                return iRet;
            }

            System.Data.SqlClient.SqlConnection DBConnection = null;
            System.Data.SqlClient.SqlCommand cmd = null;
            try
            {
                if (cmdSQL == null)
                {
                    DBConnection = objProfile.GetDBSource();
                    if (DBConnection == null)
                    {
                        strErr += ("Не удалось получить соединение с базой данных.");
                        return iRet;
                    }
                    cmd = new System.Data.SqlClient.SqlCommand();
                    cmd.Connection = DBConnection;
                    cmd.CommandType = System.Data.CommandType.StoredProcedure;
                }
                else
                {
                    cmd = cmdSQL;
                    cmd.Parameters.Clear();
                }

                cmd.CommandTimeout = 600;
                cmd.CommandText = System.String.Format("[{0}].[dbo].[usp_DecPayDocumentForm2ToSQLandIB]", objProfile.GetOptionsDllDBName());
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@RETURN_VALUE", System.Data.SqlDbType.Int, 4, System.Data.ParameterDirection.ReturnValue, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Waybill_Id", System.Data.SqlDbType.Int));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@AMOUNT", System.Data.SqlDbType.Money));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@DATELASTPAID", System.Data.SqlDbType.Date));

                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_NUM", System.Data.SqlDbType.Int, 8, System.Data.ParameterDirection.Output, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_MES", System.Data.SqlDbType.NVarChar, 4000) { Direction = System.Data.ParameterDirection.Output });

                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@DEC_AMOUNT", System.Data.SqlDbType.Money) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@WAYBILL_CURRENCYAMOUNTPAID", System.Data.SqlDbType.Money) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@WAYBILL_CURRENCYSALDO", System.Data.SqlDbType.Money) { Direction = System.Data.ParameterDirection.Output });

                if (Earning_Guid.CompareTo(System.Guid.Empty) != 0)
                {
                    cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Earning_Guid", System.Data.SqlDbType.UniqueIdentifier));
                    cmd.Parameters["@Earning_Guid"].Value = Earning_Guid;
                }
                cmd.Parameters["@Waybill_Id"].Value = Waybill_Id;
                cmd.Parameters["@AMOUNT"].Value = AMOUNT;
                cmd.Parameters["@DATELASTPAID"].Value = DATELASTPAID;

                iRet = cmd.ExecuteNonQuery();

                iRet = System.Convert.ToInt32(cmd.Parameters["@ERROR_NUM"].Value);

                if (cmd.Parameters["@ERROR_NUM"].Value != System.DBNull.Value) { ERROR_NUM = (System.Convert.ToInt32(cmd.Parameters["@ERROR_NUM"].Value)); }
                if (cmd.Parameters["@ERROR_MES"].Value != System.DBNull.Value) { strErr += (System.Convert.ToString(cmd.Parameters["@ERROR_MES"].Value)); }
                if (cmd.Parameters["@DEC_AMOUNT"].Value != System.DBNull.Value) { DEC_AMOUNT = (System.Convert.ToDecimal(cmd.Parameters["@DEC_AMOUNT"].Value)); }
                if (cmd.Parameters["@WAYBILL_CURRENCYAMOUNTPAID"].Value != System.DBNull.Value) { WAYBILL_CURRENCYAMOUNTPAID = (System.Convert.ToDecimal(cmd.Parameters["@WAYBILL_CURRENCYAMOUNTPAID"].Value)); }
                if (cmd.Parameters["@WAYBILL_CURRENCYSALDO"].Value != System.DBNull.Value) { WAYBILL_CURRENCYSALDO = (System.Convert.ToDecimal(cmd.Parameters["@WAYBILL_CURRENCYSALDO"].Value)); }

                if (cmdSQL == null)
                {
                    cmd.Dispose();
                    DBConnection.Close();
                }
            }
            catch (System.Exception f)
            {
                strErr += (String.Format("\nНе удалось выполнить Сторно документа.\nТекст ошибки: {0}", f.Message));
            }

            return iRet;
        }

        #endregion

        #region Возврат средств клиенту по форме 1
        /// <summary>
        /// Возврат средств клиенту по форме 1
        /// </summary>
        /// <param name="objProfile">профайл</param>
        /// <param name="cmdSQL">SQL-команда</param>
        /// <param name="Earning_Guid">УИ платежа</param>
        /// <param name="OPERATION_MONEY">сумма к возврату</param>
        /// <param name="OPERATION_DATE">дата операции</param>
        /// <param name="WRITEOFF_MONEY">фактически возвращённая клиенту сумма</param>
        /// <param name="ERROR_NUM">№ ошибки</param>
        /// <param name="strErr">сообщение об ошибке</param>
        /// <returns>0 - удачное завершение операции</returns>
        public static System.Int32 WriteOffReturnMoneyToCustomerForm1(UniXP.Common.CProfile objProfile, System.Data.SqlClient.SqlCommand cmdSQL,
            System.Guid Earning_Guid, System.Decimal OPERATION_MONEY, System.DateTime OPERATION_DATE,
            ref System.Decimal WRITEOFF_MONEY, ref System.Int32 ERROR_NUM, ref System.String strErr)
        {
            System.Int32 iRet = -1;

            System.Data.SqlClient.SqlConnection DBConnection = null;
            System.Data.SqlClient.SqlCommand cmd = null;
            try
            {
                if (cmdSQL == null)
                {
                    DBConnection = objProfile.GetDBSource();
                    if (DBConnection == null)
                    {
                        strErr += ("Не удалось получить соединение с базой данных.");
                        return iRet;
                    }
                    cmd = new System.Data.SqlClient.SqlCommand();
                    cmd.Connection = DBConnection;
                    cmd.CommandType = System.Data.CommandType.StoredProcedure;
                }
                else
                {
                    cmd = cmdSQL;
                    cmd.Parameters.Clear();
                }

                cmd.CommandText = System.String.Format("[{0}].[dbo].[usp_WriteOffReturnMoneyToCustomerForm1ToSQLandIB]", objProfile.GetOptionsDllDBName());
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@RETURN_VALUE", System.Data.SqlDbType.Int, 4, System.Data.ParameterDirection.ReturnValue, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Earning_Guid", System.Data.SqlDbType.UniqueIdentifier));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@OPERATION_MONEY", System.Data.SqlDbType.Money));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@OPERATION_DATE", System.Data.SqlDbType.Date));

                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_NUM", System.Data.SqlDbType.Int, 8, System.Data.ParameterDirection.Output, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_MES", System.Data.SqlDbType.NVarChar, 4000) { Direction = System.Data.ParameterDirection.Output });

                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@WRITEOFF_MONEY", System.Data.SqlDbType.Money) { Direction = System.Data.ParameterDirection.Output });

                cmd.Parameters["@Earning_Guid"].Value = Earning_Guid;
                cmd.Parameters["@OPERATION_MONEY"].Value = OPERATION_MONEY;
                cmd.Parameters["@OPERATION_DATE"].Value = OPERATION_DATE;

                iRet = cmd.ExecuteNonQuery();

                iRet = System.Convert.ToInt32(cmd.Parameters["@ERROR_NUM"].Value);

                if (cmd.Parameters["@ERROR_NUM"].Value != System.DBNull.Value) { ERROR_NUM = (System.Convert.ToInt32(cmd.Parameters["@ERROR_NUM"].Value)); }
                if (cmd.Parameters["@ERROR_MES"].Value != System.DBNull.Value) { strErr += (System.Convert.ToString(cmd.Parameters["@ERROR_MES"].Value)); }
                if (cmd.Parameters["@WRITEOFF_MONEY"].Value != System.DBNull.Value) { WRITEOFF_MONEY = (System.Convert.ToDecimal(cmd.Parameters["@WRITEOFF_MONEY"].Value)); }

                if (cmdSQL == null)
                {
                    cmd.Dispose();
                    DBConnection.Close();
                }
            }
            catch (System.Exception f)
            {
                strErr += (String.Format("\nНе удалось выполнить возврат средств клиенту.\nТекст ошибки: {0}", f.Message));
            }

            return iRet;
        }
        #endregion

        #region Отчёт "Архив платежей"
        /// <summary>
        /// Отчёт "Архив платежей"
        /// </summary>
        /// <param name="objProfile">профайл</param>
        /// <param name="cmdSQL">SQL-команда</param>
        /// <param name="dtBeginDate">начало периода</param>
        /// <param name="dtEndDate">конец периода</param>
        /// <param name="uuidCompanyId">УИ компании</param>
        /// <param name="strErr">сообщение об ошибке</param>
        /// <param name="bBlockViewTransitEarnings">признак "удалить транзитные проводки из выборки"</param>
        /// <returns>список объектов "Платёж"</returns>
        public static List<ERP_Mercury.Common.CEarning> GetReportEarningArj(UniXP.Common.CProfile objProfile,
            System.Data.SqlClient.SqlCommand cmdSQL, System.DateTime dtBeginDate, System.DateTime dtEndDate,
            System.Guid uuidCompanyId, ref System.String strErr, System.Boolean bBlockViewTransitEarnings = false )
        {
            List<ERP_Mercury.Common.CEarning> objList = new List<ERP_Mercury.Common.CEarning>();

            if( uuidCompanyId.CompareTo(System.Guid.Empty) == 0 )
            {
                return objList;
            }

            System.Data.SqlClient.SqlConnection DBConnection = null;
            System.Data.SqlClient.SqlCommand cmd = null;
            try
            {
                if (cmdSQL == null)
                {
                    DBConnection = objProfile.GetDBSource();
                    if (DBConnection == null)
                    {
                        strErr += ("Не удалось получить соединение с базой данных.");
                        return objList;
                    }
                    cmd = new System.Data.SqlClient.SqlCommand();
                    cmd.Connection = DBConnection;
                    cmd.CommandType = System.Data.CommandType.StoredProcedure;
                }
                else
                {
                    cmd = cmdSQL;
                    cmd.Parameters.Clear();
                }

                cmd.CommandTimeout = 600;
                cmd.CommandText = System.String.Format("[{0}].[dbo].[usp_GetEarningArjFromIB]", objProfile.GetOptionsDllDBName());
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@RETURN_VALUE", System.Data.SqlDbType.Int, 4, System.Data.ParameterDirection.ReturnValue, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_NUM", System.Data.SqlDbType.Int, 8, System.Data.ParameterDirection.Output, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_MES", System.Data.SqlDbType.NVarChar, 4000) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Company_Guid", System.Data.DbType.Guid));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@BeginDate", System.Data.SqlDbType.DateTime));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@EndDate", System.Data.SqlDbType.DateTime));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@bBlockViewTransitEarnings", System.Data.SqlDbType.Bit));
                cmd.Parameters["@ERROR_MES"].Direction = System.Data.ParameterDirection.Output;
                cmd.Parameters["@Company_Guid"].Value = uuidCompanyId;
                cmd.Parameters["@BeginDate"].Value = dtBeginDate;
                cmd.Parameters["@EndDate"].Value = dtEndDate;
                cmd.Parameters["@bBlockViewTransitEarnings"].Value = bBlockViewTransitEarnings;

                System.Data.SqlClient.SqlDataReader rs = cmd.ExecuteReader();
                System.Int32 iRecordCount = 0;
                if (rs.HasRows)
                {
                    ERP_Mercury.Common.CEarning objEarning = null;
                    while (rs.Read())
                    {
                        iRecordCount++;

                        objEarning = new ERP_Mercury.Common.CEarning();
                        objEarning.Date = ((rs["EARNING_DATE"] == System.DBNull.Value) ? System.DateTime.MinValue : (System.DateTime)rs["EARNING_DATE"]);
                        objEarning.Value = ((rs["EARNING_VALUE"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["EARNING_VALUE"]));
                        objEarning.Expense = ((rs["EARNING_EXPENSE"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["EARNING_EXPENSE"]));
                        objEarning.Saldo = ((rs["EARNING_SALDO"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["EARNING_SALDO"]));
                        objEarning.DetailsPayment = ((rs["EARNING_DESCRIPTION"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["EARNING_DESCRIPTION"]);
                        objEarning.Company = new ERP_Mercury.Common.CCompany()
                        {
                            InterBaseID = ((rs["COMPANY_ID"] == System.DBNull.Value) ? 0 : (System.Int32)rs["COMPANY_ID"]),
                            Abbr = ((rs["COMPANY_ACRONYM"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["COMPANY_ACRONYM"])
                        };
                        objEarning.Customer = new ERP_Mercury.Common.CCustomer()
                        {
                            InterBaseID = ((rs["CUSTOMER_ID"] == System.DBNull.Value) ? 0 : (System.Int32)rs["CUSTOMER_ID"]),
                            FullName = ((rs["CUSTOMER_NAME"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["CUSTOMER_NAME"])
                        };

                        if (objEarning != null) { objList.Add(objEarning); }
                    }
                }
                rs.Dispose();
                if (cmdSQL == null)
                {
                    cmd.Dispose();
                    DBConnection.Close();
                }
            }
            catch (System.Exception f)
            {
                strErr += (String.Format("\nНе удалось выполнить отчёт \"Архив платежей\".\nТекст ошибки: {0}", f.Message));
            }
            return objList;
        }

        /// <summary>
        /// Отчёт "Архив платежей"
        /// </summary>
        /// <param name="objProfile">профайл</param>
        /// <param name="cmdSQL">SQL-команда</param>
        /// <param name="dtBeginDate">начало периода</param>
        /// <param name="dtEndDate">конец периода</param>
        /// <param name="CustomerChild_Guid">УИ дочернего клиента</param>
        /// <param name="strErr">сообщение об ошибке</param>
        /// <returns>список объектов "Платёж"</returns>
        public static List<ERP_Mercury.Common.CEarning> GetReportCEarningArj(UniXP.Common.CProfile objProfile,
            System.Data.SqlClient.SqlCommand cmdSQL, System.DateTime dtBeginDate, System.DateTime dtEndDate,
            System.Guid CustomerChild_Guid, ref System.String strErr)
        {
            List<ERP_Mercury.Common.CEarning> objList = new List<ERP_Mercury.Common.CEarning>();

            System.Data.SqlClient.SqlConnection DBConnection = null;
            System.Data.SqlClient.SqlCommand cmd = null;
            try
            {
                if (cmdSQL == null)
                {
                    DBConnection = objProfile.GetDBSource();
                    if (DBConnection == null)
                    {
                        strErr += ("Не удалось получить соединение с базой данных.");
                        return objList;
                    }
                    cmd = new System.Data.SqlClient.SqlCommand();
                    cmd.Connection = DBConnection;
                    cmd.CommandType = System.Data.CommandType.StoredProcedure;
                }
                else
                {
                    cmd = cmdSQL;
                    cmd.Parameters.Clear();
                }

                cmd.CommandText = System.String.Format("[{0}].[dbo].[usp_GetCEarningArjFromIB]", objProfile.GetOptionsDllDBName());
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@RETURN_VALUE", System.Data.SqlDbType.Int, 4, System.Data.ParameterDirection.ReturnValue, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_NUM", System.Data.SqlDbType.Int, 8, System.Data.ParameterDirection.Output, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_MES", System.Data.SqlDbType.NVarChar, 4000) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@BeginDate", System.Data.SqlDbType.DateTime));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@EndDate", System.Data.SqlDbType.DateTime));
                cmd.Parameters["@ERROR_MES"].Direction = System.Data.ParameterDirection.Output;

                if (CustomerChild_Guid.CompareTo(System.Guid.Empty) != 0)
                {
                    cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ChildDepart_Guid", System.Data.DbType.Guid));
                    cmd.Parameters["@ChildDepart_Guid"].Value = CustomerChild_Guid;
                }

                cmd.Parameters["@BeginDate"].Value = dtBeginDate;
                cmd.Parameters["@EndDate"].Value = dtEndDate;

                System.Data.SqlClient.SqlDataReader rs = cmd.ExecuteReader();
                System.Int32 iRecordCount = 0;
                if (rs.HasRows)
                {
                    ERP_Mercury.Common.CEarning objEarning = null;
                    while (rs.Read())
                    {
                        iRecordCount++;

                        objEarning = new ERP_Mercury.Common.CEarning();
                        objEarning.Date = ((rs["EARNING_DATE"] == System.DBNull.Value) ? System.DateTime.MinValue : (System.DateTime)rs["EARNING_DATE"]);
                        objEarning.Value = ((rs["EARNING_VALUE"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["EARNING_VALUE"]));
                        objEarning.Expense = ((rs["EARNING_EXPENSE"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["EARNING_EXPENSE"]));
                        objEarning.Saldo = ((rs["EARNING_SALDO"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["EARNING_SALDO"]));
                        objEarning.DetailsPayment = ((rs["EARNING_DESCRIPTION"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["EARNING_DESCRIPTION"]);
                        objEarning.Company = new ERP_Mercury.Common.CCompany()
                        {
                            InterBaseID = ((rs["COMPANY_ID"] == System.DBNull.Value) ? 0 : (System.Int32)rs["COMPANY_ID"]),
                            Abbr = ((rs["COMPANY_ACRONYM"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["COMPANY_ACRONYM"])
                        };
                        objEarning.Customer = new ERP_Mercury.Common.CCustomer()
                        {
                            InterBaseID = ((rs["CUSTOMER_ID"] == System.DBNull.Value) ? 0 : (System.Int32)rs["CUSTOMER_ID"]),
                            FullName = ((rs["CUSTOMER_NAME"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["CUSTOMER_NAME"])
                        };
                        objEarning.Currency = new ERP_Mercury.Common.CCurrency()
                        {
                            CurrencyAbbr = ((rs["CURRENCY_CODE"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["CURRENCY_CODE"])
                        };
                        objEarning.ChildDepart = new ERP_Mercury.Common.CChildDepart()
                        {
                            Code = ((rs["CHILDCUST_CODE"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["CHILDCUST_CODE"])
                        };
                        objEarning.CurRate = ((rs["EARNING_CURRENCYRATE"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["EARNING_CURRENCYRATE"]));
                        objEarning.IsBonusEarning = ((rs["EARNING_BONUS"] == System.DBNull.Value) ? false : System.Convert.ToBoolean(rs["EARNING_BONUS"])); 

                        if (objEarning != null) { objList.Add(objEarning); }
                    }
                }
                rs.Dispose();
                if (cmdSQL == null)
                {
                    cmd.Dispose();
                    DBConnection.Close();
                }
            }
            catch (System.Exception f)
            {
                strErr += (String.Format("\nНе удалось выполнить отчёт \"Архив платежей\".\nТекст ошибки: {0}", f.Message));
            }
            return objList;
        }

        #endregion

        #region Отчёт "Должники"
        /// <summary>
        /// Отчёт "Должники форма 1"
        /// </summary>
        /// <param name="objProfile">профайл</param>
        /// <param name="cmdSQL">SQL-команда</param>
        /// <param name="uuidCompanyId">идентификатор компании</param>
        /// <param name="uuidCustomerId">идентификатор клиента</param>
        /// <param name="strErr"соообщение об ошибке></param>
        /// <returns>список документов с задолженностью</returns>
        public static List<CDebitDocument> GetReportDebtor(UniXP.Common.CProfile objProfile,
            System.Data.SqlClient.SqlCommand cmdSQL,
            System.Guid uuidCompanyId, System.Guid uuidCustomerId,
            ref System.String strErr)
        {
            List<CDebitDocument> objList = new List<CDebitDocument>();

            if(uuidCompanyId.CompareTo(System.Guid.Empty) == 0)
            {
                return objList;
            }

            System.Data.SqlClient.SqlConnection DBConnection = null;
            System.Data.SqlClient.SqlCommand cmd = null;
            try
            {
                if (cmdSQL == null)
                {
                    DBConnection = objProfile.GetDBSource();
                    if (DBConnection == null)
                    {
                        strErr += ("Не удалось получить соединение с базой данных.");
                        return objList;
                    }
                    cmd = new System.Data.SqlClient.SqlCommand();
                    cmd.Connection = DBConnection;
                    cmd.CommandType = System.Data.CommandType.StoredProcedure;
                }
                else
                {
                    cmd = cmdSQL;
                    cmd.Parameters.Clear();
                }

                cmd.CommandTimeout = 600;
                cmd.CommandText = System.String.Format("[{0}].[dbo].[usp_GetDebtorListPayForm1FromIB]", objProfile.GetOptionsDllDBName());
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@RETURN_VALUE", System.Data.SqlDbType.Int, 4, System.Data.ParameterDirection.ReturnValue, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_NUM", System.Data.SqlDbType.Int, 8, System.Data.ParameterDirection.Output, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_MES", System.Data.SqlDbType.NVarChar, 4000) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Company_Guid", System.Data.DbType.Guid));
                cmd.Parameters["@ERROR_MES"].Direction = System.Data.ParameterDirection.Output;

                cmd.Parameters["@Company_Guid"].Value = uuidCompanyId;

                if (uuidCustomerId.CompareTo(System.Guid.Empty) != 0)
                {
                    cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Customer_Guid", System.Data.DbType.Guid));
                    cmd.Parameters["@Customer_Guid"].Value = uuidCustomerId;
                }

                System.Data.SqlClient.SqlDataReader rs = cmd.ExecuteReader();
                System.Int32 iRecordCount = 0;
                if (rs.HasRows)
                {
                    CDebitDocument objDebitDocument = null;
                    while (rs.Read())
                    {
                        iRecordCount++;

                        objDebitDocument = new CDebitDocument();

                        objDebitDocument.Waybill_Id = ((rs["WAYBILL_ID"] == System.DBNull.Value) ? 0 : (System.Int32)rs["WAYBILL_ID"]);
                        objDebitDocument.Waybill_Num = ((rs["WAYBILL_NUM"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["WAYBILL_NUM"]);
                        objDebitDocument.Waybill_ShipDate = ((rs["WAYBILL_SHIPDATE"] == System.DBNull.Value) ? System.DateTime.MinValue : (System.DateTime)rs["WAYBILL_SHIPDATE"]);
                        objDebitDocument.Customer_Name = ((rs["CUSTOMER_NAME"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["CUSTOMER_NAME"]);
                        objDebitDocument.Depart_Code = ((rs["DEPART_CODE"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["DEPART_CODE"]);
                        objDebitDocument.Debt_Type = ((rs["DEBT_TYPE"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["DEBT_TYPE"]);
                        objDebitDocument.Waybill_TotalPrice = ((rs["WAYBILL_TOTALPRICE"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_TOTALPRICE"]));
                        objDebitDocument.Waybill_EndDate = ((rs["WAYBILL_ENDDATE"] == System.DBNull.Value) ? System.DateTime.MinValue : (System.DateTime)rs["WAYBILL_ENDDATE"]);
                        objDebitDocument.Waybill_AmountPaid = ((rs["WAYBILL_AMOUNTPAID"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_AMOUNTPAID"]));
                        objDebitDocument.Waybill_Saldo = ((rs["WAYBILL_SALDO"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_SALDO"]));
                        objDebitDocument.Stock_Name = ((rs["STOCK_NAME"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["STOCK_NAME"]);
                        objDebitDocument.Waybill_ShipMode = ((rs["WAYBILL_SHIPMODE"] == System.DBNull.Value) ? 0 : (System.Int32)rs["WAYBILL_SHIPMODE"]);
                        objDebitDocument.Waybill_ShipModeName = ((rs["WAYBILL_SHIPMODE_NAME"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["WAYBILL_SHIPMODE_NAME"]);
                        objDebitDocument.Waybill_ExpDays = ((rs["WAYBILL_EXPDAYS"] == System.DBNull.Value) ? 0 : (System.Int32)rs["WAYBILL_EXPDAYS"]);
                        objDebitDocument.CustomerLimit_ApprovedDays = ((rs["CUSTOMER_MAXDELAY"] == System.DBNull.Value) ? 0 : (System.Int32)rs["CUSTOMER_MAXDELAY"]);
                        objDebitDocument.CustomerLimit_ApprovedSumma = ((rs["CUSTOMER_MAXDEBT"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["CUSTOMER_MAXDEBT"]));

                        if (objDebitDocument != null) { objList.Add(objDebitDocument); }
                    }
                }
                rs.Dispose();
                if (cmdSQL == null)
                {
                    cmd.Dispose();
                    DBConnection.Close();
                }
            }
            catch (System.Exception f)
            {
                strErr += (String.Format("\nНе удалось сформировать отчёт \"Должники\".\nТекст ошибки: {0}", f.Message));
            }
            return objList;
        }

        /// <summary>
        /// Отчёт "Должники форма 2"
        /// </summary>
        /// <param name="objProfile">профайл</param>
        /// <param name="cmdSQL">SQL-команда</param>
        /// <param name="CustomerChild_Guid">УИ дочернего клиента</param>
        /// <param name="EndDate">Дата отчёта</param>
        /// <param name="strErr">сообщение об ошибке</param>
        /// <returns>список документов с задолженностью</returns>
        public static List<CDebitDocument> GetReportCDebtor(UniXP.Common.CProfile objProfile,
            System.Data.SqlClient.SqlCommand cmdSQL,
            System.Guid CustomerChild_Guid, System.DateTime EndDate,
            ref System.String strErr)
        {
            List<CDebitDocument> objList = new List<CDebitDocument>();

            System.Data.SqlClient.SqlConnection DBConnection = null;
            System.Data.SqlClient.SqlCommand cmd = null;
            try
            {
                if (cmdSQL == null)
                {
                    DBConnection = objProfile.GetDBSource();
                    if (DBConnection == null)
                    {
                        strErr += ("Не удалось получить соединение с базой данных.");
                        return objList;
                    }
                    cmd = new System.Data.SqlClient.SqlCommand();
                    cmd.Connection = DBConnection;
                    cmd.CommandType = System.Data.CommandType.StoredProcedure;
                }
                else
                {
                    cmd = cmdSQL;
                    cmd.Parameters.Clear();
                }
                cmd.CommandTimeout = INT_cmdCommandTimeout;
                cmd.CommandText = System.String.Format("[{0}].[dbo].[usp_GetDebtorListPayForm2FromIB]", objProfile.GetOptionsDllDBName());
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@RETURN_VALUE", System.Data.SqlDbType.Int, 4, System.Data.ParameterDirection.ReturnValue, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_NUM", System.Data.SqlDbType.Int, 8, System.Data.ParameterDirection.Output, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_MES", System.Data.SqlDbType.NVarChar, 4000) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@EndDate", System.Data.DbType.DateTime));
                cmd.Parameters["@ERROR_MES"].Direction = System.Data.ParameterDirection.Output;

                cmd.Parameters["@EndDate"].Value = EndDate;

                if (CustomerChild_Guid.CompareTo(System.Guid.Empty) != 0)
                {
                    cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ChildDepart_Guid", System.Data.DbType.Guid));
                    cmd.Parameters["@ChildDepart_Guid"].Value = CustomerChild_Guid;
                }

                System.Data.SqlClient.SqlDataReader rs = cmd.ExecuteReader();
                System.Int32 iRecordCount = 0;
                if (rs.HasRows)
                {
                    CDebitDocument objDebitDocument = null;
                    while (rs.Read())
                    {
                        iRecordCount++;

                        objDebitDocument = new CDebitDocument();

                        objDebitDocument.Waybill_Id = ((rs["WAYBILL_ID"] == System.DBNull.Value) ? 0 : (System.Int32)rs["WAYBILL_ID"]);
                        objDebitDocument.Waybill_Num = ((rs["WAYBILL_NUM"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["WAYBILL_NUM"]);
                        objDebitDocument.Waybill_ShipDate = ((rs["WAYBILL_SHIPDATE"] == System.DBNull.Value) ? System.DateTime.MinValue : (System.DateTime)rs["WAYBILL_SHIPDATE"]);
                        objDebitDocument.Customer_Name = ((rs["CUSTOMER_NAME"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["CUSTOMER_NAME"]);
                        objDebitDocument.Depart_Code = ((rs["DEPART_CODE"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["DEPART_CODE"]);
                        objDebitDocument.Debt_Type = ((rs["DEBT_TYPE"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["DEBT_TYPE"]);
                        objDebitDocument.Waybill_TotalPrice = ((rs["WAYBILL_TOTALPRICE"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_TOTALPRICE"]));
                        objDebitDocument.Waybill_EndDate = ((rs["WAYBILL_ENDDATE"] == System.DBNull.Value) ? System.DateTime.MinValue : (System.DateTime)rs["WAYBILL_ENDDATE"]);
                        objDebitDocument.Waybill_AmountPaid = ((rs["WAYBILL_AMOUNTPAID"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_AMOUNTPAID"]));
                        objDebitDocument.Waybill_Saldo = ((rs["WAYBILL_SALDO"] == System.DBNull.Value) ? 0 : System.Convert.ToDecimal(rs["WAYBILL_SALDO"]));
                        objDebitDocument.ChildCust_Code = ((rs["CHILDCUST_CODE"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["CHILDCUST_CODE"]);
                        objDebitDocument.ChildCust_Name = ((rs["childcust_name"] == System.DBNull.Value) ? System.String.Empty : (System.String)rs["childcust_name"]);
                        objDebitDocument.Waybill_ExpDays = ((rs["WAYBILL_EXPDAYS"] == System.DBNull.Value) ? 0 : System.Convert.ToInt32( rs["WAYBILL_EXPDAYS"] ) );

                        if (objDebitDocument != null) { objList.Add(objDebitDocument); }
                    }
                }
                rs.Dispose();
                if (cmdSQL == null)
                {
                    cmd.Dispose();
                    DBConnection.Close();
                }
            }
            catch (System.Exception f)
            {
                strErr += (String.Format("\nНе удалось сформировать отчёт \"Должники\".\nТекст ошибки: {0}", f.Message));
            }
            return objList;
        }


        #endregion
    }
}
