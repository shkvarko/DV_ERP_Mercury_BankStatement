 USE [ERP_Mercury]
 GO

 ALTER TABLE [dbo].[T_PaymentType] ADD PaymentType_Id D_ID NULL
 GO

 UPDATE [dbo].[T_PaymentType] SET PaymentType_Id = 1 WHERE [PaymentType_Guid] = '58636EC5-F64A-462C-90B1-7686ADFE70F9'
 GO

 UPDATE [dbo].[T_PaymentType] SET PaymentType_Id = 2 WHERE [PaymentType_Guid] = 'E872B5E3-83FF-4B1A-925D-0F1B3C4D5C85'
 GO

 
CREATE UNIQUE NONCLUSTERED INDEX [INDX_T_PaymentType_Payment_Id] ON [dbo].[T_PaymentType]
(
	[PaymentType_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [INDEX]

GO

/****** Object:  StoredProcedure [dbo].[usp_GetPaymentType]    Script Date: 14.04.2013 18:56:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- Возвращает список записей из ( dbo.T_PaymentType )
--
-- Входящие параметры:
--
-- Выходные параметры:
--
-- Результат:
--    0 - успешное завершение
--    <>0 - ошибка запроса информации из базы данных

ALTER PROCEDURE [dbo].[usp_GetPaymentType] 
	@PaymentType_Guid D_GUID = NULL,
	
  @ERROR_NUM int output,
  @ERROR_MES nvarchar(4000) output
AS

BEGIN

  SET @ERROR_NUM = 0;
  SET @ERROR_MES = NULL;

  BEGIN TRY
		IF( @PaymentType_Guid IS NULL )
			BEGIN
				SELECT PaymentType_Guid, PaymentType_Name, PaymentType_Description, PaymentType_Id 
				FROM dbo.T_PaymentType
				ORDER BY PaymentType_Name;
			END
		ELSE	
			BEGIN
				SELECT PaymentType_Guid, PaymentType_Name, PaymentType_Description, PaymentType_Id 
				FROM dbo.T_PaymentType
				WHERE PaymentType_Guid = @PaymentType_Guid;
			END

	END TRY
	BEGIN CATCH
		SET @ERROR_NUM = ERROR_NUMBER();
		SET @ERROR_MES = ERROR_MESSAGE();
		RETURN @ERROR_NUM;
	END CATCH;

  IF( @ERROR_NUM = 0 )
		SET @ERROR_MES = 'Успешное завершение операции.';
		
  RETURN @ERROR_NUM;
END

GO


/****** Object:  View [dbo].[EarningView]    Script Date: 14.04.2013 18:57:56 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER VIEW [dbo].[EarningView]
AS
SELECT     dbo.T_Earning.Earning_Guid, dbo.T_Earning.Earning_Id, dbo.T_Earning.Customer_Guid, dbo.T_Earning.Currency_Guid, dbo.T_Earning.Earning_Date, 
                      dbo.T_Earning.Earning_DocNum, dbo.T_Earning.Bank_Guid, dbo.T_Earning.Account_Guid, dbo.T_Earning.Earning_Value, dbo.T_Earning.Earning_Expense, 
                      dbo.T_Earning.Earning_Saldo, dbo.T_Earning.Company_Guid, dbo.T_Earning.Earning_CurrencyRate, dbo.T_Earning.Earning_CurrencyValue, 
                      dbo.T_Earning.Earning_CustomerText, dbo.T_Earning.Earning_DetailsPaymentText, dbo.T_Earning.Earning_Key, dbo.T_Earning.Earning_iKey, 
                      dbo.T_Earning.BudgetProjectSRC_Guid, dbo.T_Earning.BudgetProjectDST_Guid, dbo.T_Earning.CompanyPayer_Guid, dbo.T_Earning.CustomerChild_Guid, 
                      dbo.T_Earning.AccountPlan_Guid, dbo.T_Earning.PaymentType_Guid, dbo.T_Earning.Earning_IsBonus, dbo.T_Customer.Customer_Id, 
                      dbo.T_Customer.Customer_Code, dbo.T_Customer.Customer_Name, dbo.T_Customer.Customer_UNP, dbo.T_Customer.Customer_OKPO, 
                      dbo.T_Customer.Customer_OKULP, dbo.T_Customer.CustomerStateType_Guid, dbo.T_Customer.CustomerActiveType_Guid, 
                      dbo.T_CustomerStateType.CustomerStateType_Name, dbo.T_CustomerStateType.CustomerStateType_ShortName, 
                      dbo.T_CustomerStateType.CustomerStateType_IsActive, dbo.T_CustomerActiveType.CustomerActiveType_Name, dbo.T_Currency.Currency_Abbr, 
                      dbo.T_Currency.Currency_ShortName, dbo.T_Currency.Currency_Code, dbo.T_Currency.Currency_Name, dbo.T_Bank.Bank_Name, dbo.T_Bank.Bank_Code, 
                      dbo.T_Bank.Bank_UNN, dbo.T_Bank.Bank_MFO, dbo.T_Bank.Bank_WWW, dbo.T_Bank.Bank_IsActive, dbo.T_Bank.Bank_ParentGuid, dbo.T_Company.Company_Id, 
                      dbo.T_Company.CompanyType_Guid, dbo.T_Company.Company_Acronym, dbo.T_Company.Company_Name, dbo.T_Company.Company_OKPO, 
                      dbo.T_Company.Company_OKULP, dbo.T_Company.Company_UNN, dbo.T_Company.Company_IsActive, 
                      dbo.T_Company.CustomerStateType_Guid AS CompanyStateType_Guid, CompanyPayer.Company_Id AS CompanyPayerCompany_Id, 
                      CompanyPayer.CompanyType_Guid AS CompanyPayerCompanyType_Guid, CompanyPayer.Company_Acronym AS CompanyPayerCompany_Acronym, 
                      CompanyPayer.Company_Name AS CompanyPayerCompany_Name, CompanyPayer.Company_OKPO AS CompanyPayerCompany_OKPO, 
                      CompanyPayer.Company_OKULP AS CompanyPayerCompany_OKULP, CompanyPayer.Company_UNN AS CompanyPayerCompany_UNN, 
                      CompanyPayer.Company_IsActive AS CompanyPayerCompany_IsActive, dbo.T_PaymentType.PaymentType_Name, dbo.T_PaymentType.PaymentType_Description, 
                      dbo.CustomerChildView.ChildDepart_Guid, dbo.CustomerChildView.Customer_Guid AS CustomerChildViewCustomer_Guid, dbo.CustomerChildView.CustomerChild_Id, 
                      dbo.CustomerChildView.ChildDepart_Code, dbo.CustomerChildView.ChildDepart_Main, dbo.CustomerChildView.ChildDepart_NotActive, 
                      dbo.CustomerChildView.ChildDepart_MaxDebt, dbo.CustomerChildView.ChildDepart_MaxDelay, dbo.CustomerChildView.ChildDepart_Email, 
                      dbo.CustomerChildView.ChildDepart_Name, dbo.T_AccountPlan.ACCOUNTPLAN_1C_CODE, dbo.T_AccountPlan.ACCOUNTPLAN_NAME, 
                      dbo.T_AccountPlan.ACCOUNTPLAN_ACTIVE, BudgetProjectDST.BUDGETPROJECT_1C_CODE AS BudgetProjectDST_BUDGETPROJECT_1C_CODE, 
                      BudgetProjectDST.BUDGETPROJECT_ACTIVE AS BudgetProjectDST_BUDGETPROJECT_ACTIVE, 
                      BudgetProjectDST.BUDGETPROJECT_NAME AS BudgetProjectDST_BUDGETPROJECT_NAME, 
                      BudgetProjectSRC.BUDGETPROJECT_NAME AS BudgetProjectSRC_BUDGETPROJECT_NAME, 
                      BudgetProjectSRC.BUDGETPROJECT_ACTIVE AS BudgetProjectSRC_BUDGETPROJECT_ACTIVE, 
                      BudgetProjectSRC.BUDGETPROJECT_1C_CODE AS BudgetProjectSRC_BUDGETPROJECT_1C_CODE, dbo.AccountView.Currency_Giud AS AccountViewCurrency_Giud, 
                      dbo.AccountView.Account_Number AS AccountViewAccount_Number, dbo.AccountView.Bank_Guid AS AccountViewBank_Guid, 
                      dbo.AccountView.Account_Ddescription AS AccountViewAccount_Ddescription, dbo.AccountView.Currency_Abbr AS AccountViewCurrency_Abbr, 
                      dbo.AccountView.Currency_Code AS AccountViewCurrency_Code, dbo.AccountView.Bank_Code AS AccountViewBank_Code, 
                      dbo.AccountView.Bank_IsActive AS AccountViewBank_IsActive, dbo.AccountView.CompanyAccount_IsMain AS AccountViewCompanyAccount_IsMain, 
                      dbo.AccountView.AccountType_IsActive AS AccountViewAccountType_IsActive, dbo.AccountView.AccountType_Name AS AccountViewAccountType_Name, 
                      dbo.AccountView.AccountType_Guid AS AccountViewAccountType_Guid, dbo.AccountView.Bank_UNN AS AccountViewBank_UNN, 
                      dbo.AccountView.Bank_ParentGuid AS AccountViewBank_ParentGuid, dbo.AccountView.Bank_Name AS AccountViewBank_Name, 
                      dbo.AccountView.Bank_MFO AS AccountViewBank_MFO, dbo.T_PaymentType.PaymentType_Id
FROM         dbo.T_Earning LEFT OUTER JOIN
                      dbo.T_Customer ON dbo.T_Earning.Customer_Guid = dbo.T_Customer.Customer_Guid LEFT OUTER JOIN
                      dbo.T_CustomerStateType ON dbo.T_Customer.CustomerStateType_Guid = dbo.T_CustomerStateType.CustomerStateType_Guid LEFT OUTER JOIN
                      dbo.T_CustomerActiveType ON dbo.T_Customer.CustomerActiveType_Guid = dbo.T_CustomerActiveType.CustomerActiveType_Guid LEFT OUTER JOIN
                      dbo.T_Currency ON dbo.T_Earning.Currency_Guid = dbo.T_Currency.Currency_Guid INNER JOIN
                      dbo.T_Company ON dbo.T_Earning.Company_Guid = dbo.T_Company.Company_Guid LEFT OUTER JOIN
                      dbo.T_BudgetProject AS BudgetProjectDST ON dbo.T_Earning.BudgetProjectDST_Guid = BudgetProjectDST.BUDGETPROJECT_GUID LEFT OUTER JOIN
                      dbo.T_BudgetProject AS BudgetProjectSRC ON dbo.T_Earning.BudgetProjectSRC_Guid = BudgetProjectSRC.BUDGETPROJECT_GUID LEFT OUTER JOIN
                      dbo.T_AccountPlan ON dbo.T_Earning.AccountPlan_Guid = dbo.T_AccountPlan.ACCOUNTPLAN_GUID LEFT OUTER JOIN
                      dbo.T_PaymentType ON dbo.T_Earning.PaymentType_Guid = dbo.T_PaymentType.PaymentType_Guid LEFT OUTER JOIN
                      dbo.T_Company AS CompanyPayer ON dbo.T_Earning.CompanyPayer_Guid = CompanyPayer.Company_Guid LEFT OUTER JOIN
                      dbo.T_Bank ON dbo.T_Earning.Bank_Guid = dbo.T_Bank.Bank_Guid LEFT OUTER JOIN
                      dbo.AccountView ON dbo.T_Earning.Account_Guid = dbo.AccountView.Account_Guid LEFT OUTER JOIN
                      dbo.CustomerChildView ON dbo.T_Earning.CustomerChild_Guid = dbo.CustomerChildView.CustomerChild_Guid

GO

/****** Object:  StoredProcedure [dbo].[usp_GetEarningList]    Script Date: 14.04.2013 19:00:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- Возвращает список записей из ( dbo.T_Earning )
--
-- Входящие параметры:
--		@Earning_DateBegin		- начало периода
--		@Earning_DateEnd			- окончание периода
--		@Earning_guidCompany	- уи компании-получателя средств
--
-- Выходные параметры:
--		@ERROR_NUM						- номер ошибки
--		@ERROR_MES						- сообщение об ошибке
--
-- Результат:
--    0 - успешное завершение
--    <>0 - ошибка запроса информации из базы данных

ALTER PROCEDURE [dbo].[usp_GetEarningList] 
  @Earning_DateBegin		D_DATE,
  @Earning_DateEnd			D_DATE,
  @Earning_guidCompany	D_GUID,
	
  @ERROR_NUM int output,
  @ERROR_MES nvarchar(4000) output
AS

BEGIN

  SET @ERROR_NUM = 0;
  SET @ERROR_MES = '';

  BEGIN TRY
  
		SELECT Earning_Guid, Earning_Id, Customer_Guid, Currency_Guid, Earning_Date, Earning_DocNum, 
			Bank_Guid, Account_Guid, Earning_Value, Earning_Expense, Earning_Saldo, Company_Guid, 
			Earning_CurrencyRate, Earning_CurrencyValue, Earning_CustomerText, Earning_DetailsPaymentText, 
			Earning_Key, Earning_iKey, BudgetProjectSRC_Guid, BudgetProjectDST_Guid, CompanyPayer_Guid, 
			CustomerChild_Guid, AccountPlan_Guid, PaymentType_Guid, Earning_IsBonus, Customer_Id, 
			Customer_Code, Customer_Name, Customer_UNP, Customer_OKPO, Customer_OKULP, CustomerStateType_Guid, 
			CustomerActiveType_Guid, CustomerStateType_Name, CustomerStateType_ShortName, CustomerStateType_IsActive, 
			CustomerActiveType_Name, Currency_Abbr, Currency_ShortName, Currency_Code, Currency_Name, 
			Bank_Name, Bank_Code, Bank_UNN, Bank_MFO, Bank_WWW, Bank_IsActive, Bank_ParentGuid, 
			AccountViewAccount_Number AS Account_Number, Company_Id, CompanyType_Guid, Company_Acronym, Company_Name, 
			Company_OKPO, Company_OKULP, Company_UNN, Company_IsActive, CompanyStateType_Guid, 
			CompanyPayerCompany_Id, CompanyPayerCompanyType_Guid, CompanyPayerCompany_Acronym, 
			CompanyPayerCompany_Name, CompanyPayerCompany_OKPO, CompanyPayerCompany_OKULP, 
			CompanyPayerCompany_UNN, CompanyPayerCompany_IsActive, PaymentType_Name, PaymentType_Description, PaymentType_Id,
			ChildDepart_Guid, CustomerChildViewCustomer_Guid, CustomerChild_Id, ChildDepart_Code, 
			ChildDepart_Main, ChildDepart_NotActive, ChildDepart_MaxDebt, ChildDepart_MaxDelay, 
			ChildDepart_Email, ChildDepart_Name, ACCOUNTPLAN_1C_CODE, ACCOUNTPLAN_NAME, ACCOUNTPLAN_ACTIVE, 
			BudgetProjectDST_BUDGETPROJECT_1C_CODE, BudgetProjectDST_BUDGETPROJECT_ACTIVE, 
			BudgetProjectDST_BUDGETPROJECT_NAME, BudgetProjectSRC_BUDGETPROJECT_NAME, 
			BudgetProjectSRC_BUDGETPROJECT_ACTIVE, BudgetProjectSRC_BUDGETPROJECT_1C_CODE, 
			[AccountViewCurrency_Giud], [AccountViewBank_Guid], [AccountViewAccount_Ddescription], 
			[AccountViewCurrency_Abbr], [AccountViewCurrency_Code], [AccountViewBank_IsActive], [AccountViewCompanyAccount_IsMain],
			[AccountViewAccountType_IsActive], [AccountViewAccountType_Name], [AccountViewAccountType_Guid], [AccountViewBank_UNN], 
			[AccountViewBank_ParentGuid], [AccountViewBank_Code], [AccountViewBank_Name], [AccountViewBank_MFO], 
			AccountViewAccount_Number AS Earning_Account, 
			[AccountViewBank_Code] AS Earning_BankCode
		FROM [dbo].[EarningView]	
		WHERE	[Company_Guid] = @Earning_guidCompany
			AND [Earning_Date] BETWEEN @Earning_DateBegin AND @Earning_DateEnd
			AND (  ( PaymentType_Id IS NULL ) OR ( PaymentType_Id = 1 ) )
	ORDER BY [Earning_Date];
	
	--	Select distinct ea.Earning_Guid, ea.Earning_Id,
	--   cu.Customer_Guid, cu.Customer_Name,
	--   cr.Currency_Guid, cr.Currency_Abbr,cr.Currency_Name,
	--   ea.Earning_Date, ea.Earning_DocNum, bnk.Bank_Code as Earning_BankCode,/* ea.Earning_BankCode,*/ ac.Account_Number as Earning_Account,/* ea.Earning_Account,*/ ea.Earning_Value, ea.Earning_Expense, ea.Earning_Saldo,
	--   com.Company_Guid, com.Company_Acronym, com.Company_Name,
	--   ea.Earning_CurrencyRate, ea.Earning_CurrencyValue, ea.Earning_CustomerText, ea.Earning_DetailsPaymentText 
	--From T_Earning as ea, T_Customer as cu, T_CustomerAccount as cuacc, T_Account as ac, T_Bank as bnk, T_Currency as cr, T_Company as com 
	--Where ea.Customer_Guid=cu.Customer_Guid 
	--and ea.Currency_Guid=cr.Currency_Guid
	--and ea.Company_Guid=com.Company_Guid
	--and cu.Customer_Guid = cuacc.Customer_Guid
	--and cuacc.Account_Guid=ac.Account_Guid
	--and ea.Account_Guid=ac.Account_Guid
	--and ac.Bank_Guid=bnk.Bank_Guid
	--and bnk.Bank_Guid=ea.Bank_Guid
	--and com.Company_Guid=@Earning_guidCompany
	--and ea.Earning_Date BETWEEN (CONVERT(datetime, convert(char(10),@Earning_DateBegin,102),102))  and (CONVERT(datetime, convert(char(10),@Earning_DateEnd,102),102))
	--order by ea.Earning_Date
  
  END TRY
	BEGIN CATCH
		SET @ERROR_NUM = ERROR_NUMBER();
		SET @ERROR_MES = ERROR_MESSAGE();
		RETURN @ERROR_NUM;
	END CATCH;

  IF( @ERROR_NUM = 0 )
		SET @ERROR_MES = 'Успешное завершение операции.';

  RETURN @ERROR_NUM;
END

GO

/****** Object:  StoredProcedure [dbo].[sp_GetCurrencyList]    Script Date: 14.04.2013 19:04:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- Возвращает список записей из ( dbo.T_Currency )
--
-- Входящие параметры:
--
-- Выходные параметры:
--
-- Результат:
--    0 - успешное завершение
--    <>0 - ошибка запроса информации из базы данных

ALTER PROCEDURE [dbo].[sp_GetCurrencyList] 
  @ERROR_NUM int output,
  @ERROR_MES nvarchar(4000) output
AS

BEGIN

  SET @ERROR_NUM = 0;
  SET @ERROR_MES = '';

  BEGIN TRY

	SELECT Currency_Guid, Currency_Abbr, Currency_Code, Currency_Name, Currency_EngName, Currency_Description, 
		Currency_ParentGuid, Currency_ParentRate, Currency_Divisible, Currency_IsMain, 
		IsNationalCurrency =
      CASE Currency_Abbr
         WHEN 'BYB' THEN 1
         ELSE 0
      END
	FROM dbo.T_Currency
	ORDER BY 	Currency_Abbr
	END TRY
	BEGIN CATCH
		SET @ERROR_NUM = ERROR_NUMBER();
		SET @ERROR_MES = ERROR_MESSAGE();
		RETURN @ERROR_NUM;
	END CATCH;

  SET @ERROR_NUM = 0;
  SET @ERROR_MES = 'Успешное завершение операции.';
  RETURN @ERROR_NUM;
END
GO
