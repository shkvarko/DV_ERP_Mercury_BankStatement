using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using ERP_Mercury.Common;

namespace ERPMercuryBankStatement
{
    public class CCustomerInitialDebt
    {
        #region Свойства
        /// <summary>
        /// Уникальный идентификатор
        /// </summary>
        public System.Guid ID { get; set; }
        /// <summary>
        /// Уникальный идентификатор в InterBase
        /// </summary>
        public System.Int32 InterbaseID { get; set; }
        /// <summary>
        /// Дата
        /// </summary>
        public System.DateTime Date { get; set; }
        /// <summary>
        /// Клиент
        /// </summary>
        public CCustomer Customer { get; set; }
        /// <summary>
        /// Название клиента
        /// </summary>
        public System.String CustomerName { get { return (Customer == null ? "" : Customer.FullName); } }
        /// <summary>
        /// Дочерний клиент
        /// </summary>
        public CChildDepart ChildDepart { get; set; }
        /// <summary>
        /// Компания
        /// </summary>
        public CCompany Company { get; set; }
        /// <summary>
        /// Форма оплаты
        /// </summary>
        public CPaymentType PaymentType { get; set; }
        /// <summary>
        /// Валюта
        /// </summary>
        public CCurrency Currency { get; set; }
        /// <summary>
        /// Начальная задолженность клиента
        /// </summary>
        public System.Decimal InitialDebt { get; set; }
        /// <summary>
        /// Оплачено
        /// </summary>
        public System.Decimal AmountPaid { get; set; }
        /// <summary>
        /// Дата последней оплаты
        /// </summary>
        public System.DateTime DateLastPaid { get; set; }
        /// <summary>
        /// Сальдо задолженности
        /// </summary>
        public System.Decimal Saldo
        {
            get
            {
                return (AmountPaid - InitialDebt);
            }
        }
        /// <summary>
        /// Документ №
        /// </summary>
        public System.String DocNum { get; set; }
        /// <summary>
        /// Код дочернего клиента
        /// </summary>
        public System.String ChildDepartCode
        {
            get { return ((this.ChildDepart == null) ? "" : this.ChildDepart.Code); }
        }
        /// <summary>
        /// Наименование дочернего клиента
        /// </summary>
        public System.String ChildDepartName
        {
            get { return ((this.ChildDepart == null) ? "" : this.ChildDepart.Name); }
        }
        /// <summary>
        /// Код компании
        /// </summary>
        public System.String CompanyCode
        {
            get { return ((this.Company == null) ? "" : this.Company.Abbr); }
        }
        /// <summary>
        /// Код валюты
        /// </summary>
        public System.String CurrencyCode
        {
            get { return ((this.Currency == null) ? "" : this.Currency.CurrencyAbbr); }
        }

        #endregion

        #region Конструктор
        public CCustomerInitialDebt()
        {
            ID = System.Guid.Empty;
            InterbaseID = 0;
            Currency = null;
            Customer = null;
            ChildDepart = null;
            Company = null;
            PaymentType = null;
            InitialDebt = 0;
            AmountPaid = 0;
            Date = System.DateTime.MinValue;
            DateLastPaid = System.DateTime.MinValue;
            DocNum = System.String.Empty;
        }
        #endregion
    }

    public static class CCustomerInitialDebtDataBaseModel
    {
        #region Добавить объект в базу данных
        /// <summary>
        /// Проверка значений полей объекта перед сохранением в базе данных
        /// </summary>
        /// <param name="Customer_Guid">УИ клиента</param>
        /// <param name="Currency_Guid">УИ валюты</param>
        /// <param name="CustomerInitalDebt_Date">Дата</param>
        /// <param name="CustomerInitalDebt_DocNum">Документ №</param>
        /// <param name="CustomerInitalDebt_Value">Сумма</param>
        /// <param name="Company_Guid">УИ компании</param>
        /// <param name="ChildDepart_Guid">УИ дочернего клиента</param>
        /// <param name="PaymentType_Guid">УИ формы оплаты</param>
        /// <param name="strErr">сообщение об ошибке</param>
        /// <returns>true - проверка пройдена; false - проверка НЕ пройдена</returns>
        public static System.Boolean IsAllParametersValidPaymentType_1(System.Guid Customer_Guid, System.Guid Currency_Guid,
            System.DateTime CustomerInitalDebt_Date, System.String CustomerInitalDebt_DocNum,
            System.Decimal CustomerInitalDebt_Value, System.Guid Company_Guid,
            System.Guid ChildDepart_Guid, System.Guid PaymentType_Guid, ref System.String strErr)
        {

            System.Boolean bRet = false;
            System.Int32 iWarningCount = 0;
            try
            {
                if (Currency_Guid.Equals(System.Guid.Empty) == true)
                {
                    strErr += ("\nНеобходимо указать валюту задолженности!");
                    iWarningCount++;
                }
                if (CustomerInitalDebt_Date.CompareTo(System.DateTime.MinValue) == 0)
                {
                    strErr += ("\nНеобходимо указать дату задолженности!");
                    iWarningCount++;
                }
                if (CustomerInitalDebt_Value <= 0)
                {
                    strErr += ("\nСумма задолженности должна быть больше нуля!");
                    iWarningCount++;
                }
                if (Customer_Guid.Equals(System.Guid.Empty) == true)
                {
                    strErr += ("\nНеобходимо указать клиента!");
                    iWarningCount++;
                }
                if (Company_Guid.Equals(System.Guid.Empty) == true)
                {
                    strErr += ("\nНеобходимо указать компанию!");
                    iWarningCount++;
                }
                if (PaymentType_Guid.Equals(System.Guid.Empty) == true)
                {
                    strErr += ("\nНеобходимо указать форму оплаты!");
                    iWarningCount++;
                }

                bRet = (iWarningCount == 0);
            }
            catch (System.Exception f)
            {
                strErr += (String.Format("Ошибка проверки свойств объекта 'начальная задолженность клиента'. Текст ошибки: {0}", f.Message));
            }
            return bRet;
        }
        /// <summary>
        /// Проверка значений полей объекта перед сохранением в базе данных
        /// </summary>
        /// <param name="Customer_Guid">УИ клиента</param>
        /// <param name="Currency_Guid">УИ валюты</param>
        /// <param name="CustomerInitalDebt_Date">Дата</param>
        /// <param name="CustomerInitalDebt_DocNum">Документ №</param>
        /// <param name="CustomerInitalDebt_Value">Сумма</param>
        /// <param name="Company_Guid">УИ компании</param>
        /// <param name="ChildDepart_Guid">УИ дочернего клиента</param>
        /// <param name="PaymentType_Guid">УИ формы оплаты</param>
        /// <param name="strErr">сообщение об ошибке</param>
        /// <returns>true - проверка пройдена; false - проверка НЕ пройдена</returns>
        public static System.Boolean IsAllParametersValidPaymentType_2(System.Guid Customer_Guid, System.Guid Currency_Guid,
            System.DateTime CustomerInitalDebt_Date, System.String CustomerInitalDebt_DocNum,
            System.Decimal CustomerInitalDebt_Value, System.Guid Company_Guid,
            System.Guid ChildDepart_Guid, System.Guid PaymentType_Guid, ref System.String strErr)
        {

            System.Boolean bRet = false;
            System.Int32 iWarningCount = 0;
            try
            {
                if (Currency_Guid.Equals(System.Guid.Empty) == true)
                {
                    strErr += ("\nНеобходимо указать валюту задолженности!");
                    iWarningCount++;
                }
                if (CustomerInitalDebt_Date.CompareTo(System.DateTime.MinValue) == 0)
                {
                    strErr += ("\nНеобходимо указать дату задолженности!");
                    iWarningCount++;
                }
                if (CustomerInitalDebt_Value <= 0)
                {
                    strErr += ("\nСумма задолженности должна быть больше нуля!");
                    iWarningCount++;
                }
                if (Customer_Guid.Equals(System.Guid.Empty) == true)
                {
                    strErr += ("\nНеобходимо указать клиента!");
                    iWarningCount++;
                }
                if (ChildDepart_Guid.Equals(System.Guid.Empty) == true)
                {
                    strErr += ("\nНеобходимо указать дочернего клиента!");
                    iWarningCount++;
                }
                if (Company_Guid.Equals(System.Guid.Empty) == true)
                {
                    strErr += ("\nНеобходимо указать компанию!");
                    iWarningCount++;
                }
                if (PaymentType_Guid.Equals(System.Guid.Empty) == true)
                {
                    strErr += ("\nНеобходимо указать форму оплаты!");
                    iWarningCount++;
                }

                bRet = (iWarningCount == 0);
            }
            catch (System.Exception f)
            {
                strErr += (String.Format("Ошибка проверки свойств объекта 'начальная задолженность клиента'. Текст ошибки: {0}", f.Message));
            }
            return bRet;
        }
        /// <summary>
        /// Добавляет запись в базу данных
        /// </summary>
        /// <param name="Customer_Guid">УИ клиента</param>
        /// <param name="Currency_Guid">УИ валюты</param>
        /// <param name="CustomerInitalDebt_Date">Дата</param>
        /// <param name="CustomerInitalDebt_DocNum">Документ №</param>
        /// <param name="CustomerInitalDebt_Value">Сумма</param>
        /// <param name="Company_Guid">УИ компании</param>
        /// <param name="ChildDepart_Guid">УИ дочернего клиента</param>
        /// <param name="PaymentType_Guid">УИ формы оплаты</param>
        /// <param name="CustomerInitalDebt_Guid">УИ начальной задолженности</param>
        /// <param name="CustomerInitalDebt_Id">УИ начальной задолженности в InterBase</param>
        /// <param name="objProfile">профайл</param>
        /// <param name="strErr">сообщение об ошибке</param>
        /// <returns>true - удачное завершение операции; false - ошибка</returns>
        public static System.Boolean AddNewObjectToDataBase(System.Guid Customer_Guid, System.Guid Currency_Guid,
            System.DateTime CustomerInitalDebt_Date, System.String CustomerInitalDebt_DocNum,
            System.Decimal CustomerInitalDebt_Value, System.Guid Company_Guid,
            System.Guid ChildDepart_Guid, System.Guid PaymentType_Guid,
            ref System.Guid CustomerInitalDebt_Guid, ref System.Int32 CustomerInitalDebt_Id,
            UniXP.Common.CProfile objProfile, ref System.String strErr)
        {
            System.Boolean bRet = false;

            
            if (IsAllParametersValidPaymentType_1(Customer_Guid, Currency_Guid, CustomerInitalDebt_Date, CustomerInitalDebt_DocNum,
                CustomerInitalDebt_Value, Company_Guid, ChildDepart_Guid, PaymentType_Guid,
                ref strErr) == false )
            { return bRet; }

            System.Data.SqlClient.SqlConnection DBConnection = null;
            System.Data.SqlClient.SqlCommand cmd = null;

            try
            {
                DBConnection = objProfile.GetDBSource();
                if (DBConnection == null)
                {
                    strErr += ("Не удалось получить соединение с базой данных.");
                    return bRet;
                }
                cmd = new System.Data.SqlClient.SqlCommand();
                cmd.Connection = DBConnection;
                cmd.CommandType = System.Data.CommandType.StoredProcedure;
                cmd.CommandText = System.String.Format("[{0}].[dbo].[usp_AddCustomerInitalDebtToSQLandIB]", objProfile.GetOptionsDllDBName());
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@RETURN_VALUE", System.Data.SqlDbType.Int, 4, System.Data.ParameterDirection.ReturnValue, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@CustomerInitalDebt_Guid", System.Data.SqlDbType.UniqueIdentifier) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@CustomerInitalDebt_Id", System.Data.SqlDbType.Int) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Customer_Guid", System.Data.SqlDbType.UniqueIdentifier));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Currency_Guid", System.Data.SqlDbType.UniqueIdentifier));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@CustomerInitalDebt_Date", System.Data.SqlDbType.Date));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@CustomerInitalDebt_DocNum", System.Data.DbType.String));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@CustomerInitalDebt_Value", System.Data.SqlDbType.Money));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Company_Guid", System.Data.SqlDbType.UniqueIdentifier));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ChildDepart_Guid", System.Data.SqlDbType.UniqueIdentifier));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@PaymentType_Guid", System.Data.SqlDbType.UniqueIdentifier));

                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_NUM", System.Data.SqlDbType.Int) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_MES", System.Data.SqlDbType.NVarChar, 4000) { Direction = System.Data.ParameterDirection.Output });

                if (ChildDepart_Guid.Equals(System.Guid.Empty) == true)
                {
                    cmd.Parameters["@ChildDepart_Guid"].IsNullable = true;
                    cmd.Parameters["@ChildDepart_Guid"].Value = DBNull.Value;
                }
                else
                {
                    cmd.Parameters["@ChildDepart_Guid"].IsNullable = false;
                    cmd.Parameters["@ChildDepart_Guid"].Value = ChildDepart_Guid;
                }

                cmd.Parameters["@Customer_Guid"].Value = Customer_Guid;
                cmd.Parameters["@Currency_Guid"].Value = Currency_Guid;
                cmd.Parameters["@CustomerInitalDebt_Date"].Value = CustomerInitalDebt_Date;
                cmd.Parameters["@CustomerInitalDebt_DocNum"].Value = CustomerInitalDebt_DocNum;
                cmd.Parameters["@CustomerInitalDebt_Value"].Value = CustomerInitalDebt_Value;
                cmd.Parameters["@Company_Guid"].Value = Company_Guid;
                cmd.Parameters["@PaymentType_Guid"].Value = PaymentType_Guid;

                cmd.ExecuteNonQuery();
                System.Int32 iRes = (System.Int32)cmd.Parameters["@RETURN_VALUE"].Value;
                if (iRes == 0)
                {
                    CustomerInitalDebt_Guid = (System.Guid)cmd.Parameters["@CustomerInitalDebt_Guid"].Value;
                    CustomerInitalDebt_Id = (System.Int32)cmd.Parameters["@CustomerInitalDebt_Id"].Value;
                }
                else
                {
                    strErr += ((cmd.Parameters["@ERROR_MES"].Value == System.DBNull.Value) ? "" : (System.String)cmd.Parameters["@ERROR_MES"].Value);
                }

                cmd.Dispose();
                bRet = (iRes == 0);
            }
            catch (System.Exception f)
            {
                strErr += ("Не удалось создать объект 'начальная задолженность'. Текст ошибки: " + f.Message);
            }
            finally
            {
                DBConnection.Close();
            }
            return bRet;
        }

        #endregion

        #region Редактировать объект в базе данных
        /// <summary>
        /// Редактирует запись в базе данных
        /// </summary>
        /// <param name="CustomerInitalDebt_Guid">УИ начальной задолженности</param>
        /// <param name="Customer_Guid">УИ клиента</param>
        /// <param name="Currency_Guid">УИ валюты</param>
        /// <param name="CustomerInitalDebt_Date">Дата</param>
        /// <param name="CustomerInitalDebt_DocNum">Документ №</param>
        /// <param name="CustomerInitalDebt_Value">Сумма</param>
        /// <param name="Company_Guid">УИ компании</param>
        /// <param name="ChildDepart_Guid">УИ дочернего клиента</param>
        /// <param name="PaymentType_Guid">УИ формы оплаты</param>
        /// <param name="objProfile">профайл</param>
        /// <param name="strErr">сообщение об ошибке</param>
        /// <returns>true - удачное завершение операции; false - ошибка</returns>
        public static System.Boolean EditObjectInDataBase(System.Guid CustomerInitalDebt_Guid, System.Guid Customer_Guid, System.Guid Currency_Guid,
            System.DateTime CustomerInitalDebt_Date, System.String CustomerInitalDebt_DocNum,
            System.Decimal CustomerInitalDebt_Value, System.Guid Company_Guid,
            System.Guid ChildDepart_Guid, System.Guid PaymentType_Guid,
            UniXP.Common.CProfile objProfile, ref System.String strErr)
        {
            System.Boolean bRet = false;

            if (IsAllParametersValidPaymentType_1(Customer_Guid, Currency_Guid, CustomerInitalDebt_Date, CustomerInitalDebt_DocNum,
                CustomerInitalDebt_Value, Company_Guid, ChildDepart_Guid, PaymentType_Guid,
                ref strErr) == false)
            { return bRet; }

            System.Data.SqlClient.SqlConnection DBConnection = null;
            System.Data.SqlClient.SqlCommand cmd = null;

            try
            {
                DBConnection = objProfile.GetDBSource();
                if (DBConnection == null)
                {
                    strErr += ("Не удалось получить соединение с базой данных.");
                    return bRet;
                }
                cmd = new System.Data.SqlClient.SqlCommand();
                cmd.Connection = DBConnection;
                cmd.CommandType = System.Data.CommandType.StoredProcedure;
                cmd.CommandText = System.String.Format("[{0}].[dbo].[usp_EditCustomerInitalDebtToSQLandIB]", objProfile.GetOptionsDllDBName());
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@RETURN_VALUE", System.Data.SqlDbType.Int, 4, System.Data.ParameterDirection.ReturnValue, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@CustomerInitalDebt_Guid", System.Data.SqlDbType.UniqueIdentifier));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Customer_Guid", System.Data.SqlDbType.UniqueIdentifier));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Currency_Guid", System.Data.SqlDbType.UniqueIdentifier));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@CustomerInitalDebt_Date", System.Data.SqlDbType.Date));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@CustomerInitalDebt_DocNum", System.Data.DbType.String));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@CustomerInitalDebt_Value", System.Data.SqlDbType.Money));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Company_Guid", System.Data.SqlDbType.UniqueIdentifier));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ChildDepart_Guid", System.Data.SqlDbType.UniqueIdentifier));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@PaymentType_Guid", System.Data.SqlDbType.UniqueIdentifier));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_NUM", System.Data.SqlDbType.Int) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_MES", System.Data.SqlDbType.NVarChar, 4000) { Direction = System.Data.ParameterDirection.Output });

                cmd.Parameters["@CustomerInitalDebt_Guid"].Value = CustomerInitalDebt_Guid;
                if (ChildDepart_Guid.Equals(System.Guid.Empty) == true)
                {
                    cmd.Parameters["@ChildDepart_Guid"].IsNullable = true;
                    cmd.Parameters["@ChildDepart_Guid"].Value = DBNull.Value;
                }
                else
                {
                    cmd.Parameters["@ChildDepart_Guid"].IsNullable = false;
                    cmd.Parameters["@ChildDepart_Guid"].Value = ChildDepart_Guid;
                }

                cmd.Parameters["@Customer_Guid"].Value = Customer_Guid;
                cmd.Parameters["@Currency_Guid"].Value = Currency_Guid;
                cmd.Parameters["@CustomerInitalDebt_Date"].Value = CustomerInitalDebt_Date;
                cmd.Parameters["@CustomerInitalDebt_DocNum"].Value = CustomerInitalDebt_DocNum;
                cmd.Parameters["@CustomerInitalDebt_Value"].Value = CustomerInitalDebt_Value;
                cmd.Parameters["@Company_Guid"].Value = Company_Guid;
                cmd.Parameters["@PaymentType_Guid"].Value = PaymentType_Guid;

                cmd.ExecuteNonQuery();
                System.Int32 iRes = (System.Int32)cmd.Parameters["@RETURN_VALUE"].Value;
                if (iRes != 0)
                {
                    strErr += ((cmd.Parameters["@ERROR_MES"].Value == System.DBNull.Value) ? "" : (System.String)cmd.Parameters["@ERROR_MES"].Value);
                }

                cmd.Dispose();
                bRet = (iRes == 0);
            }
            catch (System.Exception f)
            {
                strErr += ("Не удалось внести изменения в объект 'начальная задолженность'. Текст ошибки: " + f.Message);
            }
            finally
            {
                DBConnection.Close();
            }
            return bRet;
        }

        #endregion

        #region Удалить объект из базы данных
        /// <summary>
        /// Удаляет запись из БД
        /// </summary>
        /// <param name="CustomerInitalDebt_Guid">УИ начальной задолженности</param>
        /// <param name="objProfile">профайл</param>
        /// <param name="strErr">сообщение об ошибке</param>
        /// <returns>true - удачное завершение операции; false - ошибка</returns>
        public static System.Boolean RemoveObjectFromDataBase(System.Guid CustomerInitalDebt_Guid,
           UniXP.Common.CProfile objProfile, ref System.String strErr)
        {
            System.Boolean bRet = false;

            System.Data.SqlClient.SqlConnection DBConnection = null;
            System.Data.SqlClient.SqlCommand cmd = null;

            try
            {
                DBConnection = objProfile.GetDBSource();
                if (DBConnection == null)
                {
                    strErr += ("Не удалось получить соединение с базой данных.");
                    return bRet;
                }
                cmd = new System.Data.SqlClient.SqlCommand();
                cmd.Connection = DBConnection;
                cmd.CommandType = System.Data.CommandType.StoredProcedure;
                cmd.CommandText = System.String.Format("[{0}].[dbo].[usp_DeleteCustomerInitalDebt]", objProfile.GetOptionsDllDBName());
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@RETURN_VALUE", System.Data.SqlDbType.Int, 4, System.Data.ParameterDirection.ReturnValue, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@CustomerInitalDebt_Guid", System.Data.SqlDbType.UniqueIdentifier));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_NUM", System.Data.SqlDbType.Int, 8, System.Data.ParameterDirection.Output, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_MES", System.Data.SqlDbType.NVarChar, 4000));
                cmd.Parameters["@ERROR_MES"].Direction = System.Data.ParameterDirection.Output;
                cmd.Parameters["@CustomerInitalDebt_Guid"].Value = CustomerInitalDebt_Guid;
                cmd.ExecuteNonQuery();
                System.Int32 iRes = (System.Int32)cmd.Parameters["@RETURN_VALUE"].Value;
                if (iRes != 0)
                {
                    strErr += ((cmd.Parameters["@ERROR_MES"].Value == System.DBNull.Value) ? "" : (System.String)cmd.Parameters["@ERROR_MES"].Value);
                }

                cmd.Dispose();
                bRet = (iRes == 0);
            }
            catch (System.Exception f)
            {
                strErr += ("Не удалось удалить объект 'начальная задолженность клиента'. Текст ошибки: " + f.Message);
            }
            finally
            {
                DBConnection.Close();
            }
            return bRet;
        }

        #endregion

        #region Список начальных задолженностей клиентов
        /// <summary>
        /// Возвращает список начальных задолженностей
        /// </summary>
        /// <param name="objProfile">профайл</param>
        /// <param name="cmdSQL">SQL-команда</param>
        /// <param name="DateBegin">начало периода</param>
        /// <param name="DateEnd">окончание периода</param>
        /// <param name="PaymentType_Guid">УИ формы оплаты</param>
        /// <param name="Company_Guid">УИ компании</param>
        /// <param name="Customer_Guid">УИ клиента</param>
        /// <param name="ChildDepart_Guid">УИ дочернего клиента</param>
        /// <param name="strErr">сообщение об ошибке</param>
        /// <returns>список начальных задолженностей</returns>
        public static List<CCustomerInitialDebt> GetCustomerInitialDebtList(UniXP.Common.CProfile objProfile, System.Data.SqlClient.SqlCommand cmdSQL,
            System.DateTime DateBegin, System.DateTime DateEnd, System.Guid PaymentType_Guid, 
            System.Guid Company_Guid, System.Guid Customer_Guid, System.Guid ChildDepart_Guid,
            ref System.String strErr)
        {
            List<CCustomerInitialDebt> objList = new List<CCustomerInitialDebt>();
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

                cmd.CommandText = System.String.Format("[{0}].[dbo].[usp_GetCustomerInitalDebtList]", objProfile.GetOptionsDllDBName());
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@RETURN_VALUE", System.Data.SqlDbType.Int, 4, System.Data.ParameterDirection.ReturnValue, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_NUM", System.Data.SqlDbType.Int, 8, System.Data.ParameterDirection.Output, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_MES", System.Data.SqlDbType.NVarChar, 4000));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@DateBegin", System.Data.DbType.Date));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@DateEnd", System.Data.DbType.Date));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@PaymentType_Guid", System.Data.DbType.Guid));

                cmd.Parameters["@ERROR_MES"].Direction = System.Data.ParameterDirection.Output;

                cmd.Parameters["@DateBegin"].Value = DateBegin;
                cmd.Parameters["@DateEnd"].Value = DateEnd;
                cmd.Parameters["@PaymentType_Guid"].Value = PaymentType_Guid;

                if (Company_Guid.Equals(System.Guid.Empty) == false)
                {
                    cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Company_Guid", System.Data.DbType.Guid));
                    cmd.Parameters["@Company_Guid"].Value = Company_Guid;
                }
                if (Customer_Guid.Equals(System.Guid.Empty) == false)
                {
                    cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@Customer_Guid", System.Data.DbType.Guid));
                    cmd.Parameters["@Customer_Guid"].Value = Company_Guid;
                }
                if (ChildDepart_Guid.Equals(System.Guid.Empty) == false)
                {
                    cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ChildDepart_Guid", System.Data.DbType.Guid));
                    cmd.Parameters["@ChildDepart_Guid"].Value = ChildDepart_Guid;
                }

                System.Data.SqlClient.SqlDataReader rs = cmd.ExecuteReader();
                System.Int32 iRecordCount = 0;
                if (rs.HasRows)
                {
                    CCustomerInitialDebt objCustomerInitialDebt = null;
                    while (rs.Read())
                    {
                        iRecordCount++;

                        objCustomerInitialDebt = new CCustomerInitialDebt();

                        objCustomerInitialDebt.ID = (System.Guid)rs["CustomerInitalDebt_Guid"];
                        objCustomerInitialDebt.InterbaseID = ((rs["CustomerInitalDebt_Id"] == System.DBNull.Value) ? 0 : (System.Int32)rs["CustomerInitalDebt_Id"]);
                        objCustomerInitialDebt.Customer = ((rs["Customer_Guid"] != System.DBNull.Value) ? new CCustomer()
                        {
                            ID = (System.Guid)rs["Customer_Guid"],
                            InterBaseID = System.Convert.ToInt32(rs["Customer_Id"]),
                            Code = System.Convert.ToString(rs["Customer_Code"]),
                            ShortName = System.Convert.ToString(rs["Customer_Name"]),
                            FullName = System.Convert.ToString(rs["Customer_Name"]),
                            UNP = System.Convert.ToString(rs["Customer_UNP"]),
                            OKPO = System.Convert.ToString(rs["Customer_OKPO"]),
                            OKULP = ((rs["Customer_OKULP"] == System.DBNull.Value) ? "" : (System.String)rs["Customer_OKULP"]),
                            StateType = ((rs["CustomerStateType_Guid"] != System.DBNull.Value) ? new CStateType()
                            {
                                ID = (System.Guid)rs["CustomerStateType_Guid"],
                                Name = System.Convert.ToString(rs["CustomerStateType_Name"]),
                                ShortName = System.Convert.ToString(rs["CustomerStateType_ShortName"])
                            } : null)
                        } : null);
                        objCustomerInitialDebt.Currency = ((rs["Currency_Guid"] != System.DBNull.Value) ? new CCurrency()
                        {
                            ID = (System.Guid)rs["Currency_Guid"],
                            CurrencyAbbr = System.Convert.ToString(rs["Currency_Abbr"]),
                            CurrencyCode = System.Convert.ToString(rs["Currency_Code"]),
                            Name = System.Convert.ToString(rs["Currency_Name"])
                        } : null);
                        objCustomerInitialDebt.Date = System.Convert.ToDateTime(rs["CustomerInitalDebt_Date"]);
                        objCustomerInitialDebt.DateLastPaid = ( (rs["CustomerInitalDebt_DateLastPaid"] != System.DBNull.Value) ? System.Convert.ToDateTime(rs["CustomerInitalDebt_DateLastPaid"]) : System.DateTime.MinValue ) ;
                        objCustomerInitialDebt.DocNum = ((rs["CustomerInitalDebt_DocNum"] != System.DBNull.Value) ? System.Convert.ToString(rs["CustomerInitalDebt_DocNum"]) : "");
                        objCustomerInitialDebt.InitialDebt = System.Convert.ToDecimal(rs["CustomerInitalDebt_Value"]);
                        objCustomerInitialDebt.AmountPaid = ((rs["CustomerInitalDebt_AmountPaid"] != System.DBNull.Value) ? System.Convert.ToDecimal(rs["CustomerInitalDebt_AmountPaid"]) : 0);
                        objCustomerInitialDebt.Company = ((rs["Company_Guid"] != System.DBNull.Value) ? new CCompany()
                        {
                            ID = (System.Guid)rs["Company_Guid"],
                            Name = System.Convert.ToString(rs["Company_Name"]),
                            Abbr = System.Convert.ToString(rs["Company_Acronym"]),
                            InterBaseID = System.Convert.ToInt32(rs["Company_Id"])
                        } : null);

                        objCustomerInitialDebt.PaymentType = ((rs["PaymentType_Guid"] != System.DBNull.Value) ? new CPaymentType((System.Guid)rs["PaymentType_Guid"], System.Convert.ToString(rs["PaymentType_Name"])) { Payment_Id = System.Convert.ToInt32(rs["PaymentType_Id"]) }
                        : null);
                        objCustomerInitialDebt.ChildDepart = ((rs["CustomerChild_Guid"] != System.DBNull.Value) ? new CChildDepart()
                        {
                            ID = (System.Guid)rs["ChildDepart_Guid"],
                            Code = System.Convert.ToString(rs["ChildDepart_Code"]),
                            Name = System.Convert.ToString(rs["ChildDepart_Name"]),
                            IsMain = System.Convert.ToBoolean(rs["ChildDepart_Main"]),
                            IsBlock = System.Convert.ToBoolean(rs["ChildDepart_NotActive"]),
                            MaxDebt = System.Convert.ToDecimal(rs["ChildDepart_MaxDebt"]),
                            MaxDelay = System.Convert.ToDecimal(rs["ChildDepart_MaxDelay"])
                        } : null);

                        if (objCustomerInitialDebt != null) { objList.Add(objCustomerInitialDebt); }
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
                strErr += (String.Format("\nНе удалось получить список начальных задолженностей.\nТекст ошибки: {0}", f.Message));
            }
            return objList;
        }

        #endregion

        #region Сторно оплаты (форма 1)
        /// <summary>
        /// Операция Сторно оплаты задолженности
        /// </summary>
        /// <param name="objProfile">профайл</param>
        /// <param name="cmdSQL">SQL-команда</param>
        /// <param name="CustomerInitialDebt_Guid">УИ задолженности</param>
        /// <param name="DEC_AMOUNT">фактически проведённая сумма Сторно</param>
        /// <param name="CustomerInitalDebt_AmountPaid"> итоговая сумма оплаты задолженности</param>
        /// <param name="CustomerInitalDebt_Saldo">сальдо задолженности</param>
        /// <param name="ERROR_NUM">код ошибки</param>
        /// <param name="strErr">сообщение об ошибке</param>
        /// <returns>код ошибки выполнения хранимой процедуры</returns>
        public static System.Int32 DePayCustomerInitialDebtForm1(UniXP.Common.CProfile objProfile, System.Data.SqlClient.SqlCommand cmdSQL,
            System.Guid CustomerInitialDebt_Guid,
            ref System.Decimal DEC_AMOUNT, ref System.Decimal CustomerInitalDebt_AmountPaid, 
            ref System.Decimal CustomerInitalDebt_Saldo,
            ref System.Int32 ERROR_NUM, ref System.String strErr)
        {
            System.Int32 iRet = -1;

            if (CustomerInitialDebt_Guid.CompareTo(System.Guid.Empty) == 0)
            {
                strErr += ("Не указан идентификатор оплаченной задолженности.");
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

                cmd.CommandText = System.String.Format("[{0}].[dbo].[usp_DecPayCustomerInitialDebtForm1ToSQLandIB]", objProfile.GetOptionsDllDBName());
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@RETURN_VALUE", System.Data.SqlDbType.Int, 4, System.Data.ParameterDirection.ReturnValue, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));

                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@CustomerInitalDebt_Guid", System.Data.SqlDbType.UniqueIdentifier));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_NUM", System.Data.SqlDbType.Int, 8, System.Data.ParameterDirection.Output, false, ((System.Byte)(0)), ((System.Byte)(0)), "", System.Data.DataRowVersion.Current, null));
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@ERROR_MES", System.Data.SqlDbType.NVarChar, 4000) { Direction = System.Data.ParameterDirection.Output });

                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@DEC_AMOUNT", System.Data.SqlDbType.Money) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@CustomerInitalDebt_AmountPaid", System.Data.SqlDbType.Money) { Direction = System.Data.ParameterDirection.Output });
                cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@CustomerInitalDebt_Saldo", System.Data.SqlDbType.Money) { Direction = System.Data.ParameterDirection.Output });

                cmd.Parameters["@CustomerInitalDebt_Guid"].Value = CustomerInitialDebt_Guid;

                iRet = cmd.ExecuteNonQuery();

                iRet = System.Convert.ToInt32(cmd.Parameters["@ERROR_NUM"].Value);

                if (cmd.Parameters["@ERROR_NUM"].Value != System.DBNull.Value) { ERROR_NUM = (System.Convert.ToInt32(cmd.Parameters["@ERROR_NUM"].Value)); }
                if (cmd.Parameters["@ERROR_MES"].Value != System.DBNull.Value) { strErr += (System.Convert.ToString(cmd.Parameters["@ERROR_MES"].Value)); }
                if (cmd.Parameters["@DEC_AMOUNT"].Value != System.DBNull.Value) { DEC_AMOUNT = (System.Convert.ToDecimal(cmd.Parameters["@DEC_AMOUNT"].Value)); }
                if (cmd.Parameters["@CustomerInitalDebt_AmountPaid"].Value != System.DBNull.Value) { CustomerInitalDebt_AmountPaid = (System.Convert.ToDecimal(cmd.Parameters["@CustomerInitalDebt_AmountPaid"].Value)); }
                if (cmd.Parameters["@CustomerInitalDebt_Saldo"].Value != System.DBNull.Value) { CustomerInitalDebt_Saldo = (System.Convert.ToDecimal(cmd.Parameters["@CustomerInitalDebt_Saldo"].Value)); }

                if (cmdSQL == null)
                {
                    cmd.Dispose();
                    DBConnection.Close();
                }
            }
            catch (System.Exception f)
            {
                strErr += (String.Format("\nНе удалось выполнить Сторно оплаты задолженности.\nТекст ошибки: {0}", f.Message));
            }

            return iRet;
        }
        #endregion
    }
}
