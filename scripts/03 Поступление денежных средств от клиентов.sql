USE [ERP_Mercury]
GO

UPDATE [dbo].[T_Earning] SET Earning_IsBonus = 0
GO

CREATE NONCLUSTERED INDEX [IX_T_Earning_Earning_IsBonus] ON [dbo].[T_Earning]
(
	[Earning_IsBonus] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [INDEX]

GO

ALTER TABLE [dbo].[T_Earning]  WITH CHECK ADD  CONSTRAINT [FK_T_Earning_T_BudgetProjectDst] FOREIGN KEY([BudgetProjectDST_Guid])
REFERENCES [dbo].[T_BudgetProject] ([BUDGETPROJECT_GUID])
GO

ALTER TABLE [dbo].[T_Earning] CHECK CONSTRAINT [FK_T_Earning_T_BudgetProjectDst]
GO


ALTER TABLE [dbo].[T_Earning]  WITH CHECK ADD  CONSTRAINT [FK_T_Earning_T_BudgetProjectSrc] FOREIGN KEY([BudgetProjectSRC_Guid])
REFERENCES [dbo].[T_BudgetProject] ([BUDGETPROJECT_GUID])
GO

ALTER TABLE [dbo].[T_Earning] CHECK CONSTRAINT [FK_T_Earning_T_BudgetProjectSrc]
GO

ALTER TABLE [dbo].[T_Earning]  WITH CHECK ADD  CONSTRAINT [FK_T_Earning_T_CompanyPayer] FOREIGN KEY([CompanyPayer_Guid])
REFERENCES [dbo].[T_Company] ([Company_Guid])
GO

ALTER TABLE [dbo].[T_Earning] CHECK CONSTRAINT [FK_T_Earning_T_CompanyPayer]
GO


ALTER TABLE [dbo].[T_Earning]  WITH CHECK ADD  CONSTRAINT [FK_T_Earning_T_CustomerChild] FOREIGN KEY([CustomerChild_Guid])
REFERENCES [dbo].[T_CustomerChild] ([CustomerChild_Guid])
GO

ALTER TABLE [dbo].[T_Earning] CHECK CONSTRAINT [FK_T_Earning_T_CustomerChild]
GO

ALTER TABLE [dbo].[T_Earning]  WITH CHECK ADD  CONSTRAINT [FK_T_Earning_T_PaymentType] FOREIGN KEY([PaymentType_Guid])
REFERENCES [dbo].[T_PaymentType] ([PaymentType_Guid])
GO

ALTER TABLE [dbo].[T_Earning] CHECK CONSTRAINT [FK_T_Earning_T_PaymentType]
GO


ALTER TABLE [dbo].[T_Earning]  WITH CHECK ADD  CONSTRAINT [FK_T_Earning_T_AccountPlan] FOREIGN KEY([AccountPlan_Guid])
REFERENCES [dbo].[T_AccountPlan] ([ACCOUNTPLAN_GUID])
GO

ALTER TABLE [dbo].[T_Earning] CHECK CONSTRAINT [FK_T_Earning_T_AccountPlan]
GO

/****** Object:  View [dbo].[CustomerChildView]    Script Date: 16.03.2013 13:55:03 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[CustomerChildView]
AS
SELECT     dbo.T_CustomerChild.CustomerChild_Guid, dbo.T_CustomerChild.CustomerChild_Id, dbo.T_CustomerChild.ChildDepart_Guid, dbo.T_CustomerChild.Customer_Guid, 
                      dbo.T_ChildDepart.ChildDepart_Code, dbo.T_ChildDepart.ChildDepart_Main, dbo.T_ChildDepart.ChildDepart_NotActive, dbo.T_ChildDepart.ChildDepart_MaxDebt, 
                      dbo.T_ChildDepart.ChildDepart_MaxDelay, dbo.T_ChildDepart.ChildDepart_Email, dbo.T_ChildDepart.ChildDepart_Name
FROM         dbo.T_ChildDepart INNER JOIN
                      dbo.T_CustomerChild ON dbo.T_ChildDepart.ChildDepart_Guid = dbo.T_CustomerChild.ChildDepart_Guid

GO
GRANT SELECT ON [dbo].[CustomerChildView] TO [public]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[AccountView]
AS
SELECT     Account.Account_Guid, Account.Account_Number, Account.Bank_Guid, Account.Currency_Giud, Account.Account_Ddescription, Currency.Currency_Abbr, 
                      Currency.Currency_Code, Bank.Bank_Code, Bank.Bank_IsActive, Bank.Bank_MFO, Bank.Bank_Name, Bank.Bank_ParentGuid, Bank.Bank_UNN, 
                      Account.AccountType_Guid, AcoountType.AccountType_Name, AcoountType.AccountType_IsActive, CAST(0 AS bit) AS CompanyAccount_IsMain
FROM         dbo.T_Account AS Account INNER JOIN
                      dbo.T_Bank AS Bank ON Account.Bank_Guid = Bank.Bank_Guid INNER JOIN
                      dbo.T_Currency AS Currency ON Account.Currency_Giud = Currency.Currency_Guid INNER JOIN
                      dbo.T_AccountType AS AcoountType ON Account.AccountType_Guid = AcoountType.AccountType_Guid

GO
GRANT SELECT ON [dbo].[AccountView] TO [public]
GO

/****** Object:  View [dbo].[EarningView]    Script Date: 16.03.2013 14:09:10 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[EarningView]
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
                      dbo.AccountView.Bank_MFO AS AccountViewBank_MFO
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
GRANT SELECT ON [dbo].[EarningView] TO [public]
GO

/****** Object:  StoredProcedure [dbo].[usp_GetEarningList]    Script Date: 16.03.2013 14:17:31 ******/
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
			CompanyPayerCompany_UNN, CompanyPayerCompany_IsActive, PaymentType_Name, PaymentType_Description, 
			ChildDepart_Guid, CustomerChildViewCustomer_Guid, CustomerChild_Id, ChildDepart_Code, 
			ChildDepart_Main, ChildDepart_NotActive, ChildDepart_MaxDebt, ChildDepart_MaxDelay, 
			ChildDepart_Email, ChildDepart_Name, ACCOUNTPLAN_1C_CODE, ACCOUNTPLAN_NAME, ACCOUNTPLAN_ACTIVE, 
			BudgetProjectDST_BUDGETPROJECT_1C_CODE, BudgetProjectDST_BUDGETPROJECT_ACTIVE, 
			BudgetProjectDST_BUDGETPROJECT_NAME, BudgetProjectSRC_BUDGETPROJECT_NAME, 
			BudgetProjectSRC_BUDGETPROJECT_ACTIVE, BudgetProjectSRC_BUDGETPROJECT_1C_CODE, 
			[AccountViewCurrency_Giud], [AccountViewBank_Guid], [AccountViewAccount_Ddescription], 
			[AccountViewCurrency_Abbr], [AccountViewCurrency_Code], [AccountViewBank_IsActive], [AccountViewCompanyAccount_IsMain],
			[AccountViewAccountType_IsActive], [AccountViewAccountType_Name], [AccountViewAccountType_Guid], [AccountViewBank_UNN], 
			[AccountViewBank_ParentGuid], [AccountViewBank_Code], [AccountViewBank_Name], [AccountViewBank_MFO]
		FROM [dbo].[EarningView]	
		WHERE	[Company_Guid] = @Earning_guidCompany
			AND [Earning_Date] BETWEEN @Earning_DateBegin AND @Earning_DateEnd
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


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[GetAccountTypeMainGuid] ( )
RETURNS D_GUID
WITH EXECUTE AS caller
AS
BEGIN
  
	DECLARE @AccountTypeMain_Guid D_GUID = NULL;

	SELECT @AccountTypeMain_Guid = AccountType_Guid FROM T_AccountType
	WHERE UPPER( AccountType_Name ) LIKE '%ОСНОВНОЙ%';

	RETURN @AccountTypeMain_Guid;

END

GO
GRANT EXECUTE ON [dbo].[GetAccountTypeMainGuid] TO [public]
GO

/****** Object:  StoredProcedure [dbo].[usp_AddEarning]    Script Date: 18.03.2013 10:16:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Добавляет новую запись в таблицу dbo.T_Earning
--
-- Входящие параметры:
--
--		@Earning_CustomerGuid				- УИ клиента
--		@Earning_CurrencyGuid				- УИ валюты
--		@Earning_Date								- дата платежа
--		@Earning_DocNum							- № документа
--		@Earning_BankCode						- код банка
--		@Earning_Account						- № р/с
--		@Earning_Value							- сумма платежа
--		@Earning_CompanyGuid				- уи компании-получателя платежа
--		@Earning_CurrencyRate				- курс !?
--		@Earning_CurrencyValue			- !?
--		@Earning_CustomerText				-	
--		@Earning_DetailsPaymentText	- 
--		@Earning_iKey								- 
--		@BudgetProjectSRC_Guid			- УИ проекта-источника
--		@BudgetProjectDST_Guid			- УИ проекта-получателя
--		@CompanyPayer_Guid					- УИ компании-плательщика
--		@ChildDepart_Guid						- УИ дочернего клиента
--		@AccountPlan_Guid						- УИ записи в плане счетов
--		@PaymentType_Guid						- УИ формы оплаты
--		@Earning_IsBonus						- признак "бонусный платёж"

-- Выходные параметры:
--
--  @Earning_Guid								- УИ записи
--  @ERROR_NUM										- номер ошибки
--  @ERROR_MES										- текст ошибки
--
-- Результат:
--    0 - Успешное завершение
--    <>0 - ошибка

ALTER PROCEDURE [dbo].[usp_AddEarning] 
	@Earning_CustomerGuid				D_GUID = NULL,
	@Earning_CurrencyGuid				D_GUID,
	@Earning_Date								D_Date,
	@Earning_DocNum							D_Name,
	@Earning_BankCode						D_BankCode,
	@Earning_Account						D_Account,
	@Earning_Value							D_Money,
	@Earning_CompanyGuid				D_GUID,
	@Earning_CurrencyRate				D_Money,
	@Earning_CurrencyValue			D_Money,
	@Earning_CustomerText				D_Description,
	@Earning_DetailsPaymentText	nvarchar(max),
	@Earning_iKey								int,
	@BudgetProjectSRC_Guid			D_GUID_NULL = NULL,
	@BudgetProjectDST_Guid			D_GUID_NULL = NULL,
	@CompanyPayer_Guid					D_GUID_NULL = NULL,
	@ChildDepart_Guid						D_GUID_NULL = NULL,
	@AccountPlan_Guid						D_GUID_NULL = NULL,
	@PaymentType_Guid						D_GUID_NULL = NULL,
	@Earning_IsBonus						D_YESNO = 0,
	@InAccount_Guid							D_GUID = NULL,

  @Earning_Guid								D_GUID output,
  @ERROR_NUM									int output,
  @ERROR_MES									nvarchar(4000) output

AS

BEGIN

	BEGIN TRY

    SET @ERROR_NUM = 0;
    SET @ERROR_MES = NULL;
    SET @Earning_Guid = NULL;
    
    DECLARE @EventID D_ID;
    SET @EventID = NULL;
    DECLARE @ParentEventID D_ID;
    SET @ParentEventID = NULL;
    DECLARE @strMessage D_EVENTMSG;
    DECLARE @EventSrc D_NAME;
    SET @EventSrc = 'Банковские выписки';
    
    -- определяем УИ банка
    DECLARE @Bank_Guid D_GUID = NULL;
    SELECT TOP 1 @Bank_Guid = Bank_Guid FROM T_Bank	WHERE Bank_Code = @Earning_BankCode;
	  IF( @Bank_Guid IS NULL )
			BEGIN
				SET @ERROR_NUM = 1;
				SET @ERROR_MES = 'В БД уже не найден банк с указанным кодом: ' + @Earning_BankCode;

				RETURN @ERROR_NUM;
			END	
    
		-- определяем УИ счёта    
    DECLARE @Account_Guid D_GUID = NULL;

		IF( @InAccount_Guid IS NULL )
			SELECT TOP 1 @Account_Guid = Account_Guid FROM T_Account 
			WHERE ( Account_Number = @Earning_Account ) AND	( Bank_Guid = @Bank_Guid );
    ELSE 
			SELECT TOP 1 @Account_Guid = Account_Guid FROM T_Account 
			WHERE Account_Guid = @InAccount_Guid;

    IF (@Account_Guid IS NULL)
			BEGIN
				DECLARE @AccountTypeMain_Guid D_GUID;	
				SELECT @AccountTypeMain_Guid= [dbo].[GetAccountTypeMainGuid]();

				IF( @AccountTypeMain_Guid IS NULL )
					BEGIN
						SET @ERROR_NUM = 2;
						SET @ERROR_MES = 'В базе данных не найден указанный счёт. Банк (код): ' + @Earning_BankCode + ' Счёт: "' + @Earning_Account + '". Не найден уи для типа счёта "основной".';

						RETURN @ERROR_NUM;
					END	

				DECLARE @NewAccount_Guid D_GUID;
				SET @NewAccount_Guid = NEWID();		
	  		  
				INSERT INTO T_Account (Account_Guid, Bank_Guid, Account_Number, Account_Ddescription,Currency_Giud, Record_Updated, AccountType_Guid)
				VALUES (@NewAccount_Guid, @Bank_Guid, @Earning_Account, null, @Earning_CurrencyGuid, GETDATE(), @AccountTypeMain_Guid)
				
				SET @Account_Guid = @NewAccount_Guid;
			END

		IF NOT EXISTS ( SELECT [Account_Guid] FROM [dbo].[T_Account]	WHERE [Account_Guid] = @Account_Guid )
			BEGIN
				SET @ERROR_NUM = 3;
				SET @ERROR_MES = 'В базе данных не найден счёт с указанным идентификатором: ' + CAST( @Account_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- проект-источник
		IF( @BudgetProjectSRC_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [BUDGETPROJECT_GUID] FROM [dbo].[T_BudgetProject] 
				WHERE [BUDGETPROJECT_GUID] = @BudgetProjectSRC_Guid )
			BEGIN
				SET @ERROR_NUM = 4;
				SET @ERROR_MES = 'В базе данных не найден проект-источник с указанным идентификатором: ' + CAST( @BudgetProjectSRC_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- проект-получатель
		IF( @BudgetProjectDST_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [BUDGETPROJECT_GUID] FROM [dbo].[T_BudgetProject] 
				WHERE [BUDGETPROJECT_GUID] = @BudgetProjectDST_Guid )
			BEGIN
				SET @ERROR_NUM = 5;
				SET @ERROR_MES = 'В базе данных не найден проект-получатель с указанным идентификатором: ' + CAST( @BudgetProjectDST_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- компания-плательщик
		IF( @CompanyPayer_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [Company_Guid] FROM [dbo].[T_Company]
				WHERE [Company_Guid] = @CompanyPayer_Guid )
			BEGIN
				SET @ERROR_NUM = 6;
				SET @ERROR_MES = 'В базе данных не найдена компания-плательщик с указанным идентификатором: ' + CAST( @CompanyPayer_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- дочерний клиент
		DECLARE	@CustomerChild_Guid	D_GUID_NULL = NULL;
		IF( @ChildDepart_Guid IS NOT NULL )
			BEGIN
				SELECT @CustomerChild_Guid = [CustomerChild_Guid] FROM [dbo].[T_CustomerChild]
				WHERE ( [ChildDepart_Guid] = @ChildDepart_Guid ) AND ( [Customer_Guid] = @Earning_CustomerGuid );

				IF( @CustomerChild_Guid IS NULL )
				BEGIN
					SET @ERROR_NUM = 7;
					SET @ERROR_MES = 'В базе данных не найден дочерний клиент с указанным идентификатором: ' + CAST( @CustomerChild_Guid as nvarchar(36) );

					RETURN @ERROR_NUM;
				END	
			END

    -- план счетов
		IF( @AccountPlan_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [ACCOUNTPLAN_GUID] FROM [dbo].[T_AccountPlan]
				WHERE [ACCOUNTPLAN_GUID] = @AccountPlan_Guid )
			BEGIN
				SET @ERROR_NUM = 8;
				SET @ERROR_MES = 'В базе данных не найдена запись в плане счетов с указанным идентификатором: ' + CAST( @AccountPlan_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- форма оплаты
		IF( @PaymentType_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [PaymentType_Guid]  FROM [dbo].[T_PaymentType]
				WHERE [PaymentType_Guid] = @PaymentType_Guid )
			BEGIN
				SET @ERROR_NUM = 9;
				SET @ERROR_MES = 'В базе данных не найдена форма оплаты с указанным идентификатором: ' + CAST( @PaymentType_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

     -- клиент
     IF( @Earning_CustomerGuid IS NOT NULL)
       IF NOT EXISTS ( SELECT Customer_Guid FROM dbo.T_Customer WHERE Customer_Guid = @Earning_CustomerGuid )
        BEGIN
         SET @ERROR_NUM = 10;
         SET @ERROR_MES = 'В базе данных не найден клиент с указанным идентификатором: ' + CAST( @Earning_CustomerGuid as nvarchar(36) );

         RETURN @ERROR_NUM;
        END    

     -- валюта
		 IF NOT EXISTS ( SELECT Currency_Guid FROM dbo.T_Currency WHERE Currency_Guid = @Earning_CurrencyGuid )
      BEGIN
        SET @ERROR_NUM = 11;
        SET @ERROR_MES = 'В базе данных не найдена валюта с указанным идентификатором: ' + CAST( @Earning_CurrencyGuid as nvarchar(36) );

        RETURN @ERROR_NUM;
      END    

     IF NOT EXISTS ( SELECT Company_Guid FROM dbo.T_Company WHERE Company_Guid = @Earning_CompanyGuid )
      BEGIN
        SET @ERROR_NUM = 12;
        SET @ERROR_MES = 'В базе данных не найдена компания с указанным идентификатором: ' + CAST( @Earning_CompanyGuid as nvarchar(36) );

        RETURN @ERROR_NUM;
      END       

    DECLARE @NewID D_GUID;
    SET @NewID = NEWID ( );	
                
    DECLARE @Earning_Id D_ID;
    EXEC @Earning_Id = SP_GetGeneratorID @strTableName = 'T_Earning';
       
    
    INSERT INTO dbo.T_Earning ( Earning_Guid, Earning_Id, Customer_Guid, Currency_Guid,	Earning_Date, 
			Earning_DocNum, Bank_Guid, Account_Guid, Earning_Value, Earning_Expense, Company_Guid, 
			Earning_CurrencyRate, Earning_CurrencyValue, Earning_CustomerText, Earning_DetailsPaymentText, 
			Earning_iKey, BudgetProjectSRC_Guid, BudgetProjectDST_Guid,	CompanyPayer_Guid,
			CustomerChild_Guid,	AccountPlan_Guid,	PaymentType_Guid,	Earning_IsBonus )
		VALUES( @NewID, @Earning_Id, @Earning_CustomerGuid, @Earning_CurrencyGuid, @Earning_Date, 
			@Earning_DocNum, @Bank_Guid,  @Account_Guid, @Earning_Value, 0, @Earning_CompanyGuid, 
			@Earning_CurrencyRate, @Earning_CurrencyValue, @Earning_CustomerText, @Earning_DetailsPaymentText, 
			@Earning_iKey, @BudgetProjectSRC_Guid, @BudgetProjectDST_Guid,	@CompanyPayer_Guid,
			@CustomerChild_Guid,	@AccountPlan_Guid,	@PaymentType_Guid,	@Earning_IsBonus );
        
		SET @Earning_Guid = @NewID;
	
		SET @strMessage = 'В БД добавлена информация о новом платеже. УИ записи: ' + CONVERT( nvarchar(36), @Earning_Guid );

		EXEC dbo.spAddEventToLog @EVENT_SOURCE = @EventSrc, @EVENT_SOURCEID = @Earning_Guid, @EVENT_CATEGORY = 'None', 
				@EVENT_COMPUTER = ' ', @EVENT_TYPE = 'Info', @EVENT_IS_COMPOSITE = 0, 
				@EVENT_DESCRIPTION = @strMessage, @EVENT_PARENTID = @ParentEventID, @EVENT_ID = @EventID output;

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

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Удаление элемента из таблицы dbo.T_Earning
--
-- Входящие параметры:
--
--		@Earning_Guid - уникальный идентификатор записи
--
-- Выходные параметры:
--
--		@ERROR_NUM		- номер ошибки
--		@ERROR_MES		- сообщение об ошибке

-- Результат:
--    0 - успешное завершение
--    <>0 - ошибка

CREATE PROCEDURE [dbo].[usp_DeleteEarning] 
	@Earning_Guid		D_GUID,

  @ERROR_NUM			int output,
  @ERROR_MES			nvarchar(4000) output

AS

BEGIN

  SET @ERROR_NUM = 0;
  SET @ERROR_MES = '';

	BEGIN TRY

		IF NOT EXISTS ( SELECT Earning_Guid FROM dbo.[T_Earning] WHERE Earning_Guid = @Earning_Guid )
		BEGIN
			SET @ERROR_NUM = 1;
			SET @ERROR_MES = 'В базе данных не найден платёж с указанным идентификатором: ' + CAST( @Earning_Guid as nvarchar(36) );

			RETURN @ERROR_NUM;
		END       

		DECLARE @Earning_iKey int;
		SELECT @Earning_iKey = [Earning_iKey] FROM [dbo].[T_Earning]
		WHERE [Earning_Guid] = @Earning_Guid;

		BEGIN TRANSACTION UpdateData;	
	
		EXEC dbo.usp_DeleteEarningFromIB @Earning_iKey = @Earning_iKey, @IBLINKEDSERVERNAME = NULL, 
			@ERROR_NUM = @ERROR_NUM output, @ERROR_MES = @ERROR_MES output;

		IF( @ERROR_NUM = 0 ) 
			BEGIN
				DELETE FROM dbo.[T_Earning] WHERE Earning_Guid = @Earning_Guid;
				
				COMMIT TRANSACTION UpdateData;
			END
		ELSE ROLLBACK TRANSACTION UpdateData;

    
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION UpdateData;
		
		SET @ERROR_NUM = ERROR_NUMBER();
		SET @ERROR_MES = ERROR_MESSAGE();
		
		RETURN @ERROR_NUM;
	END CATCH;

	IF( @ERROR_NUM = 0 )
		SET @ERROR_MES = 'Платёж успешно удалён. УИ платежа: ' + CAST( @Earning_Guid as nvarchar(36) );
	
	RETURN @ERROR_NUM;
END


GO
GRANT EXECUTE ON [dbo].[usp_DeleteEarning] TO [public]
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Добавляет в InterBase информацию о новой банковской выписке

-- Входные параметры
-- 
-- @Earning_Guid - УИ платежа
-- @IBLINKEDSERVERNAME		- имя LINKEDSERVER для подключения к InterBase
--
-- Выходные параметры
--
-- @Earning_Id						- УИ платежа в InterBase
-- @ERROR_NUM						- номер ошибки
-- @ERROR_MES						- сообщение об ошибке

ALTER PROCEDURE [dbo].[usp_AddEarningToIB]
	@Earning_Guid					D_GUID,
	@IBLINKEDSERVERNAME		D_NAME = NULL,

	@Earning_Id						int output, 
	@ERROR_NUM						int output,
	@ERROR_MES						nvarchar(4000) output
AS

BEGIN
  BEGIN TRY
    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';

		IF NOT EXISTS ( SELECT Earning_Guid FROM dbo.[T_Earning] WHERE Earning_Guid = @Earning_Guid )
			BEGIN
				SET @ERROR_NUM = 1;
				SET @ERROR_MES = 'В базе данных не найден платёж с указанным идентификатором: ' + CAST( @Earning_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END       

    DECLARE @EventID D_ID = NULL;
    DECLARE @ParentEventID D_ID = NULL;
    DECLARE @strMessage D_EVENTMSG = '';
    DECLARE @EventSrc D_NAME = 'Создание записи по банковской выписке в IB';

	  IF( @IBLINKEDSERVERNAME IS NULL ) SELECT @IBLINKEDSERVERNAME = dbo.GetIBLinkedServerName();
	  
    
    DECLARE @Earning_Code						int;
    DECLARE @Earning_CustomerId			int;
    DECLARE @Earning_CurrencyCode		D_CURRENCYCODE;
    DECLARE @Earning_Date						D_Date;
    DECLARE @Earning_DocNum					D_Name;
    DECLARE @Earning_BankCode				D_BankCode;
    DECLARE @Earning_BankAccount		D_Account;
    DECLARE @Earning_Value					float;
    DECLARE @Earning_Expense				float;
    DECLARE @Earning_Saldo					float;
    DECLARE @Earning_CompanyId			int;
    DECLARE @Earning_CurrencyRate		float;
    DECLARE @Earning_CurrencyValue	float;
    DECLARE @Earning_UsdValue				float;
    DECLARE @Earning_iKey						int;
    DECLARE @Account_Guid						D_GUID;
    DECLARE @Bank_Guid							D_Guid;
		DECLARE @Customer_Guid					D_GUID;
  
    SELECT @Customer_Guid = Customer_Guid, @Earning_CustomerId = [Customer_Id], @Earning_CurrencyCode =  [Currency_Abbr], 
			@Earning_Date = [Earning_Date], @Earning_DocNum = [Earning_DocNum], 
			@Account_Guid = [Account_Guid], @Bank_Guid = [Bank_Guid], @Earning_Value = [Earning_Value],
			@Earning_Expense = [Earning_Expense], @Earning_Saldo = [Earning_Saldo],
			@Earning_CompanyId = [Company_Id], @Earning_CurrencyRate = [Earning_CurrencyRate],
			@Earning_CurrencyValue = [Earning_CurrencyValue], @Earning_iKey = [Earning_iKey], 
			@Earning_BankAccount = [AccountViewAccount_Number], @Earning_BankCode = [Bank_Code]
		FROM [dbo].[EarningView] WHERE Earning_Guid = @Earning_Guid;
      
    IF( @Earning_CustomerId IS NULL ) SET @Earning_CustomerId = 0;
		IF( @Earning_CompanyId IS NULL )
      BEGIN
        SET @ERROR_NUM = 2;
        SET @ERROR_MES = 'Не найдена компания, указанная в платеже. УИ платежа: ' + CAST( @Earning_Guid as nvarchar(36) );

        RETURN @ERROR_NUM;
      END 

    SET @Earning_UsdValue=0	
    SET @Earning_Code=0
				   
    DECLARE @SQLString nvarchar( 2048 );
    DECLARE @ParmDefinition nvarchar( 500 );
    DECLARE @RETURNVALUE int;


		DECLARE @NewEarningId int;
		SET @NewEarningId = NULL;
    SET @ParmDefinition = N'@EarningId_Ib int output, @ErrorNum_Ib int output, @ErrorText_Ib varchar(480) output'; 				
					
		SET @SQLString = 'SELECT @EarningId_Ib=EARNING_ID, @ErrorNum_Ib = ERROR_NUMBER, @ErrorText_Ib = ERROR_TEXT FROM OPENQUERY( ' + 
			@IBLINKEDSERVERNAME + ', ''SELECT EARNING_ID, ERROR_NUMBER, ERROR_TEXT FROM SP_ADD_EARNING_FROMSQL( ' +
					'''''' + cast( @Earning_Code as nvarchar(10)) + '''''' + ', ' +
					'''''' + cast( @Earning_CustomerId as nvarchar(10)) + '''''' + ', ' +
					'''''' + cast( @Earning_CurrencyCode as nvarchar(4)) + '''''' + ', ' +
					'''''' + cast( @Earning_Date as nvarchar(10)) + '''''' + ', ' +
					'''''' + cast( @Earning_DocNum as nvarchar(10)) + '''''' + ', ' +
					'''''' + cast( @Earning_BankCode as nvarchar(4)) + '''''' + ', ' +	
					'''''' + cast( @Earning_BankAccount as nvarchar(13)) + '''''' + ', ' +
					'''''' + convert(varchar(50),cast(@Earning_Value as money)) + '''''' + ', ' +
					'''''' + cast( @Earning_Expense as nvarchar(25)) + '''''' + ', ' +
					'''''' + cast( @Earning_CompanyId as nvarchar(25)) + '''''' + ', ' +
					'''''' + cast( @Earning_CurrencyRate as nvarchar(15)) + '''''' + ', ' +
					'''''' + cast( @Earning_CurrencyValue as nvarchar(25)) + '''''' + ', ' +
					'''''' + cast( @Earning_UsdValue as nvarchar( 10 )) + '''''' + ', ' +
					'''''' + cast( @Earning_iKey as nvarchar( 50 )) + ''''' )'' )'; 
					
    EXECUTE sp_executesql @SQLString, @ParmDefinition, @EarningId_Ib = @NewEarningId output, 
			@ErrorNum_Ib = @ERROR_NUM output, @ErrorText_Ib = @ERROR_MES output;  
		SELECT @NewEarningId;
		
		IF( @ERROR_NUM = 0 )
			BEGIN
				UPDATE dbo.T_Earning	SET Earning_Id = @NewEarningId
				WHERE Earning_Guid = @Earning_Guid;
			
				UPDATE dbo.TS_GENERATOR SET GENERATOR_ID = @NewEarningId 
				WHERE TABLE_NAME = 'T_Earning';
			END
		

	END TRY
	
	BEGIN CATCH
    SET @ERROR_NUM = ERROR_NUMBER();
    SET @ERROR_MES = @ERROR_MES + ' ' + ERROR_MESSAGE();
    SET @strMessage = @ERROR_MES + ' ' + @Earning_Id;
    
		EXEC dbo.spAddEventToLog @EVENT_SOURCE = @EventSrc, @EVENT_CATEGORY = 'None', 
      @EVENT_COMPUTER = ' ', @EVENT_TYPE = 'Error', @EVENT_IS_COMPOSITE = 0, 
      @EVENT_DESCRIPTION = @strMessage, @EVENT_PARENTID = @ParentEventID, @EVENT_ID = @EventID output;

		RETURN @ERROR_NUM;
	END CATCH;

	IF( @ERROR_NUM = 0 )
		SET @ERROR_MES = 'Успешное завершение операции. Код платежа в IB: ' + CAST( @NewEarningId as nvarchar( 56 ) );

	RETURN @ERROR_NUM;

END
GO

/****** Object:  StoredProcedure [dbo].[usp_AddEarning]    Script Date: 03.04.2013 14:05:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Добавляет новую запись в таблицу dbo.T_Earning
--
-- Входящие параметры:
--
--		@Earning_CustomerGuid				- УИ клиента
--		@Earning_CurrencyGuid				- УИ валюты
--		@Earning_Date								- дата платежа
--		@Earning_DocNum							- № документа
--		@Earning_BankCode						- код банка
--		@Earning_Account						- № р/с
--		@Earning_Value							- сумма платежа
--		@Earning_CompanyGuid				- уи компании-получателя платежа
--		@Earning_CurrencyRate				- курс !?
--		@Earning_CurrencyValue			- !?
--		@Earning_CustomerText				-	
--		@Earning_DetailsPaymentText	- 
--		@Earning_iKey								- 
--		@BudgetProjectSRC_Guid			- УИ проекта-источника
--		@BudgetProjectDST_Guid			- УИ проекта-получателя
--		@CompanyPayer_Guid					- УИ компании-плательщика
--		@ChildDepart_Guid						- УИ дочернего клиента
--		@AccountPlan_Guid						- УИ записи в плане счетов
--		@PaymentType_Guid						- УИ формы оплаты
--		@Earning_IsBonus						- признак "бонусный платёж"

-- Выходные параметры:
--
--  @Earning_Guid								- УИ записи
--  @ERROR_NUM										- номер ошибки
--  @ERROR_MES										- текст ошибки
--
-- Результат:
--    0 - Успешное завершение
--    <>0 - ошибка

CREATE PROCEDURE [dbo].[usp_AddEarningToSQLandIB] 
	@Earning_CustomerGuid				D_GUID = NULL,
	@Earning_CurrencyGuid				D_GUID,
	@Earning_Date								D_Date,
	@Earning_DocNum							D_Name,
	@Earning_BankCode						D_BankCode,
	@Earning_Account						D_Account,
	@Earning_Value							D_Money,
	@Earning_CompanyGuid				D_GUID,
	@Earning_CurrencyRate				D_Money,
	@Earning_CurrencyValue			D_Money,
	@Earning_CustomerText				D_Description,
	@Earning_DetailsPaymentText	nvarchar(max),
	@Earning_iKey								int,
	@BudgetProjectSRC_Guid			D_GUID_NULL = NULL,
	@BudgetProjectDST_Guid			D_GUID_NULL = NULL,
	@CompanyPayer_Guid					D_GUID_NULL = NULL,
	@ChildDepart_Guid						D_GUID_NULL = NULL,
	@AccountPlan_Guid						D_GUID_NULL = NULL,
	@PaymentType_Guid						D_GUID_NULL = NULL,
	@Earning_IsBonus						D_YESNO = 0,

  @Earning_Guid								D_GUID output,
  @ERROR_NUM									int output,
  @ERROR_MES									nvarchar(4000) output

AS

BEGIN

	BEGIN TRY

    SET @ERROR_NUM = 0;
    SET @ERROR_MES = NULL;
    SET @Earning_Guid = NULL;
    
    DECLARE @EventID D_ID;
    SET @EventID = NULL;
    DECLARE @ParentEventID D_ID;
    SET @ParentEventID = NULL;
    DECLARE @strMessage D_EVENTMSG;
    DECLARE @EventSrc D_NAME;
    SET @EventSrc = 'Банковские выписки';
    
    -- определяем УИ банка
    DECLARE @Bank_Guid D_GUID = NULL;
    SELECT TOP 1 @Bank_Guid = Bank_Guid FROM T_Bank	WHERE Bank_Code = @Earning_BankCode;
	  IF( @Bank_Guid IS NULL )
			BEGIN
				SET @ERROR_NUM = 1;
				SET @ERROR_MES = 'В БД уже не найден банк с указанным кодом: ' + @Earning_BankCode;

				RETURN @ERROR_NUM;
			END	
    
		-- определяем УИ счёта    
    DECLARE @Account_Guid D_GUID = NULL;
    SELECT TOP 1 @Account_Guid = Account_Guid FROM T_Account 
		WHERE ( Account_Number = @Earning_Account ) AND	( Bank_Guid = @Bank_Guid );
    
    IF (@Account_Guid IS NULL)
			BEGIN
				DECLARE @AccountTypeMain_Guid D_GUID;	
				SELECT @AccountTypeMain_Guid= [dbo].[GetAccountTypeMainGuid]();

				IF( @AccountTypeMain_Guid IS NULL )
					BEGIN
						SET @ERROR_NUM = 2;
						SET @ERROR_MES = 'В базе данных не найден указанный счёт. Банк (код): ' + @Earning_BankCode + ' Счёт: "' + @Earning_Account + '". Не найден уи для типа счёта "основной".';

						RETURN @ERROR_NUM;
					END	

				DECLARE @NewAccount_Guid D_GUID;
				SET @NewAccount_Guid = NEWID();		
	  		  
				INSERT INTO T_Account (Account_Guid, Bank_Guid, Account_Number, Account_Ddescription,Currency_Giud, Record_Updated, AccountType_Guid)
				VALUES (@NewAccount_Guid, @Bank_Guid, @Earning_Account, null, @Earning_CurrencyGuid, GETDATE(), @AccountTypeMain_Guid)
				
				SET @Account_Guid = @NewAccount_Guid;
			END

		IF NOT EXISTS ( SELECT [Account_Guid] FROM [dbo].[T_Account]	WHERE [Account_Guid] = @Account_Guid )
			BEGIN
				SET @ERROR_NUM = 3;
				SET @ERROR_MES = 'В базе данных не найден счёт с указанным идентификатором: ' + CAST( @Account_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- проект-источник
		IF( @BudgetProjectSRC_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [BUDGETPROJECT_GUID] FROM [dbo].[T_BudgetProject] 
				WHERE [BUDGETPROJECT_GUID] = @BudgetProjectSRC_Guid )
			BEGIN
				SET @ERROR_NUM = 4;
				SET @ERROR_MES = 'В базе данных не найден проект-источник с указанным идентификатором: ' + CAST( @BudgetProjectSRC_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- проект-получатель
		IF( @BudgetProjectDST_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [BUDGETPROJECT_GUID] FROM [dbo].[T_BudgetProject] 
				WHERE [BUDGETPROJECT_GUID] = @BudgetProjectDST_Guid )
			BEGIN
				SET @ERROR_NUM = 5;
				SET @ERROR_MES = 'В базе данных не найден проект-получатель с указанным идентификатором: ' + CAST( @BudgetProjectDST_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- компания-плательщик
		IF( @CompanyPayer_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [Company_Guid] FROM [dbo].[T_Company]
				WHERE [Company_Guid] = @CompanyPayer_Guid )
			BEGIN
				SET @ERROR_NUM = 6;
				SET @ERROR_MES = 'В базе данных не найдена компания-плательщик с указанным идентификатором: ' + CAST( @CompanyPayer_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- дочерний клиент
		DECLARE	@CustomerChild_Guid	D_GUID_NULL = NULL;
		IF( @ChildDepart_Guid IS NOT NULL )
			BEGIN
				SELECT @CustomerChild_Guid = [CustomerChild_Guid] FROM [dbo].[T_CustomerChild]
				WHERE ( [ChildDepart_Guid] = @ChildDepart_Guid ) AND ( [Customer_Guid] = @Earning_CustomerGuid );

				IF( @CustomerChild_Guid IS NULL )
				BEGIN
					SET @ERROR_NUM = 7;
					SET @ERROR_MES = 'В базе данных не найден дочерний клиент с указанным идентификатором: ' + CAST( @CustomerChild_Guid as nvarchar(36) );

					RETURN @ERROR_NUM;
				END	
			END

    -- план счетов
		IF( @AccountPlan_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [ACCOUNTPLAN_GUID] FROM [dbo].[T_AccountPlan]
				WHERE [ACCOUNTPLAN_GUID] = @AccountPlan_Guid )
			BEGIN
				SET @ERROR_NUM = 8;
				SET @ERROR_MES = 'В базе данных не найдена запись в плане счетов с указанным идентификатором: ' + CAST( @AccountPlan_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- форма оплаты
		IF( @PaymentType_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [PaymentType_Guid]  FROM [dbo].[T_PaymentType]
				WHERE [PaymentType_Guid] = @PaymentType_Guid )
			BEGIN
				SET @ERROR_NUM = 9;
				SET @ERROR_MES = 'В базе данных не найдена форма оплаты с указанным идентификатором: ' + CAST( @PaymentType_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

     -- клиент
     IF( @Earning_CustomerGuid IS NOT NULL)
       IF NOT EXISTS ( SELECT Customer_Guid FROM dbo.T_Customer WHERE Customer_Guid = @Earning_CustomerGuid )
        BEGIN
         SET @ERROR_NUM = 10;
         SET @ERROR_MES = 'В базе данных не найден клиент с указанным идентификатором: ' + CAST( @Earning_CustomerGuid as nvarchar(36) );

         RETURN @ERROR_NUM;
        END    

     -- валюта
		 IF NOT EXISTS ( SELECT Currency_Guid FROM dbo.T_Currency WHERE Currency_Guid = @Earning_CurrencyGuid )
      BEGIN
        SET @ERROR_NUM = 11;
        SET @ERROR_MES = 'В базе данных не найдена валюта с указанным идентификатором: ' + CAST( @Earning_CurrencyGuid as nvarchar(36) );

        RETURN @ERROR_NUM;
      END    

     IF NOT EXISTS ( SELECT Company_Guid FROM dbo.T_Company WHERE Company_Guid = @Earning_CompanyGuid )
      BEGIN
        SET @ERROR_NUM = 12;
        SET @ERROR_MES = 'В базе данных не найдена компания с указанным идентификатором: ' + CAST( @Earning_CompanyGuid as nvarchar(36) );

        RETURN @ERROR_NUM;
      END       

    DECLARE @NewID D_GUID;
    SET @NewID = NEWID ( );	
                
    DECLARE @Earning_Id D_ID;
    EXEC @Earning_Id = SP_GetGeneratorID @strTableName = 'T_Earning';
       
    
    BEGIN TRANSACTION UpdateData;

    INSERT INTO dbo.T_Earning ( Earning_Guid, Earning_Id, Customer_Guid, Currency_Guid,	Earning_Date, 
			Earning_DocNum, Bank_Guid, Account_Guid, Earning_Value, Earning_Expense, Company_Guid, 
			Earning_CurrencyRate, Earning_CurrencyValue, Earning_CustomerText, Earning_DetailsPaymentText, 
			Earning_iKey, BudgetProjectSRC_Guid, BudgetProjectDST_Guid,	CompanyPayer_Guid,
			CustomerChild_Guid,	AccountPlan_Guid,	PaymentType_Guid,	Earning_IsBonus )
		VALUES( @NewID, @Earning_Id, @Earning_CustomerGuid, @Earning_CurrencyGuid, @Earning_Date, 
			@Earning_DocNum, @Bank_Guid,  @Account_Guid, @Earning_Value, 0, @Earning_CompanyGuid, 
			@Earning_CurrencyRate, @Earning_CurrencyValue, @Earning_CustomerText, @Earning_DetailsPaymentText, 
			@Earning_iKey, @BudgetProjectSRC_Guid, @BudgetProjectDST_Guid,	@CompanyPayer_Guid,
			@CustomerChild_Guid,	@AccountPlan_Guid,	@PaymentType_Guid,	@Earning_IsBonus );
        
		SET @Earning_Guid = @NewID;
	
    EXEC dbo.usp_AddEarningToIB @Earning_Guid = @NewID, @IBLINKEDSERVERNAME = NULL, @Earning_Id = @Earning_Id output,
			@ERROR_NUM = @ERROR_NUM output, @ERROR_MES = @ERROR_MES output;

		IF( @ERROR_NUM = 0 )
			BEGIN
				SET @strMessage = 'В БД добавлена информация о новом платеже. УИ записи: ' + CONVERT( nvarchar(36), @Earning_Guid );
				COMMIT TRANSACTION UpdateData
			END
		ELSE 
			BEGIN
				SET @strMessage = 'Ошибка регистрации платежа. ' + @ERROR_MES;
				ROLLBACK TRANSACTION UpdateData;
			END


		EXEC dbo.spAddEventToLog @EVENT_SOURCE = @EventSrc, @EVENT_SOURCEID = @Earning_Guid, @EVENT_CATEGORY = 'None', 
				@EVENT_COMPUTER = ' ', @EVENT_TYPE = 'Info', @EVENT_IS_COMPOSITE = 0, 
				@EVENT_DESCRIPTION = @strMessage, @EVENT_PARENTID = @ParentEventID, @EVENT_ID = @EventID output;

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION UpdateData;

    SET @ERROR_NUM = ERROR_NUMBER();
    SET @ERROR_MES = ERROR_MESSAGE();

		RETURN @ERROR_NUM;
	END CATCH;

	IF( @ERROR_NUM = 0 )
		SET @ERROR_MES = 'Успешное завершение операции.';

	RETURN @ERROR_NUM;
END

GO
GRANT EXECUTE ON [dbo].[usp_AddEarningToSQLandIB] TO [public]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Редактирует в InterBase информацию о платеже

-- Входные параметры
-- 
-- @Earning_Guid - УИ платежа
-- @IBLINKEDSERVERNAME		- имя LINKEDSERVER для подключения к InterBase
--
-- Выходные параметры
--
-- @ERROR_NUM						- номер ошибки
-- @ERROR_MES						- сообщение об ошибке

CREATE PROCEDURE [dbo].[usp_EditEarningInIB]
	@Earning_Guid					D_GUID,
	@IBLINKEDSERVERNAME		D_NAME = NULL,

	@ERROR_NUM						int output,
	@ERROR_MES						nvarchar(4000) output
AS

BEGIN
  BEGIN TRY
    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';

		IF NOT EXISTS ( SELECT Earning_Guid FROM dbo.[T_Earning] WHERE Earning_Guid = @Earning_Guid )
			BEGIN
				SET @ERROR_NUM = 1;
				SET @ERROR_MES = 'В базе данных не найден платёж с указанным идентификатором: ' + CAST( @Earning_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END       

    DECLARE @EventID D_ID = NULL;
    DECLARE @ParentEventID D_ID = NULL;
    DECLARE @strMessage D_EVENTMSG = '';
    DECLARE @EventSrc D_NAME = 'Создание записи по банковской выписке в IB';

	  IF( @IBLINKEDSERVERNAME IS NULL ) SELECT @IBLINKEDSERVERNAME = dbo.GetIBLinkedServerName();
	  
    
    DECLARE @Earning_Id							int;
    DECLARE @Earning_Code						int;
    DECLARE @Earning_CustomerId			int;
    DECLARE @Earning_CurrencyCode		D_CURRENCYCODE;
    DECLARE @Earning_Date						D_Date;
    DECLARE @Earning_DocNum					D_Name;
    DECLARE @Earning_BankCode				D_BankCode;
    DECLARE @Earning_BankAccount		D_Account;
    DECLARE @Earning_Value					float;
    DECLARE @Earning_Expense				float;
    DECLARE @Earning_Saldo					float;
    DECLARE @Earning_CompanyId			int;
    DECLARE @Earning_CurrencyRate		float;
    DECLARE @Earning_CurrencyValue	float;
    DECLARE @Earning_UsdValue				float;
    DECLARE @Earning_iKey						int;
    DECLARE @Account_Guid						D_GUID;
    DECLARE @Bank_Guid							D_Guid;
		DECLARE @Customer_Guid					D_GUID;
  
    SELECT @Earning_Id = Earning_Id, @Customer_Guid = Customer_Guid, @Earning_CustomerId = [Customer_Id], @Earning_CurrencyCode =  [Currency_Abbr], 
			@Earning_Date = [Earning_Date], @Earning_DocNum = [Earning_DocNum], 
			@Account_Guid = [Account_Guid], @Bank_Guid = [Bank_Guid], @Earning_Value = [Earning_Value],
			@Earning_Expense = [Earning_Expense], @Earning_Saldo = [Earning_Saldo],
			@Earning_CompanyId = [Company_Id], @Earning_CurrencyRate = [Earning_CurrencyRate],
			@Earning_CurrencyValue = [Earning_CurrencyValue], @Earning_iKey = [Earning_iKey], 
			@Earning_BankAccount = [Account_Number], @Earning_BankCode = [Bank_Code]
		FROM [dbo].[EarningView] WHERE Earning_Guid = @Earning_Guid;
      
    IF( @Earning_CustomerId IS NULL ) SET @Earning_CustomerId = 0;
		IF( @Earning_iKey IS NULL ) SET @Earning_iKey = 0;
		IF( @Earning_CompanyId IS NULL )
      BEGIN
        SET @ERROR_NUM = 2;
        SET @ERROR_MES = 'Не найдена компания, указанная в платеже. УИ платежа: ' + CAST( @Earning_Guid as nvarchar(36) );

        RETURN @ERROR_NUM;
      END 

    SET @Earning_UsdValue=0	
    SET @Earning_Code=0
				   
    DECLARE @SQLString nvarchar( 2048 );
    DECLARE @ParmDefinition nvarchar( 500 );
    DECLARE @RETURNVALUE int;

    SET @ParmDefinition = N'@ErrorNum_Ib int output, @ErrorText_Ib varchar(480) output'; 				
					
		SET @SQLString = 'SELECT  @ErrorNum_Ib = ERROR_NUMBER, @ErrorText_Ib = ERROR_TEXT FROM OPENQUERY( ' + 
			@IBLINKEDSERVERNAME + ', ''SELECT ERROR_NUMBER, ERROR_TEXT FROM SP_EDIT_EARNING_FROMSQL( ' + cast( @Earning_Id as nvarchar( 20)) + ', ' + +
					'''''' + cast( @Earning_Code as nvarchar(10)) + '''''' + ', ' +
					'''''' + cast( @Earning_CustomerId as nvarchar(10)) + '''''' + ', ' +
					'''''' + cast( @Earning_CurrencyCode as nvarchar(4)) + '''''' + ', ' +
					'''''' + cast( @Earning_Date as nvarchar(10)) + '''''' + ', ' +
					'''''' + cast( @Earning_DocNum as nvarchar(10)) + '''''' + ', ' +
					'''''' + cast( @Earning_BankCode as nvarchar(4)) + '''''' + ', ' +	
					'''''' + cast( @Earning_BankAccount as nvarchar(13)) + '''''' + ', ' +
					'''''' + convert(varchar(50),cast(@Earning_Value as money)) + '''''' + ', ' +
					'''''' + cast( @Earning_Expense as nvarchar(25)) + '''''' + ', ' +
					'''''' + cast( @Earning_CompanyId as nvarchar(25)) + '''''' + ', ' +
					'''''' + cast( @Earning_CurrencyRate as nvarchar(15)) + '''''' + ', ' +
					'''''' + cast( @Earning_CurrencyValue as nvarchar(25)) + '''''' + ', ' +
					'''''' + cast( @Earning_UsdValue as nvarchar( 10 )) + '''''' + ', ' +
					'''''' + cast( @Earning_iKey as nvarchar( 50 )) + ''''' )'' )'; 
					
    EXECUTE sp_executesql @SQLString, @ParmDefinition, 
			@ErrorNum_Ib = @ERROR_NUM output, @ErrorText_Ib = @ERROR_MES output;  
		
	END TRY
	
	BEGIN CATCH
    SET @ERROR_NUM = ERROR_NUMBER();
    SET @ERROR_MES = @ERROR_MES + ' ' + ERROR_MESSAGE();
    SET @strMessage = @ERROR_MES + ' ' + @Earning_Id;
    
		EXEC dbo.spAddEventToLog @EVENT_SOURCE = @EventSrc, @EVENT_CATEGORY = 'None', 
      @EVENT_COMPUTER = ' ', @EVENT_TYPE = 'Error', @EVENT_IS_COMPOSITE = 0, 
      @EVENT_DESCRIPTION = @strMessage, @EVENT_PARENTID = @ParentEventID, @EVENT_ID = @EventID output;

		RETURN @ERROR_NUM;
	END CATCH;

	IF( @ERROR_NUM = 0 )
		SET @ERROR_MES = 'Успешное завершение операции. Код платежа в IB: ' + CAST( @Earning_Id as nvarchar( 56 ) );

	RETURN @ERROR_NUM;

END


GO
GRANT EXECUTE ON [dbo].[usp_EditEarningInIB] TO [public]
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Редактирует запись в таблице dbo.T_Earning
--
-- Входящие параметры:
--
--  @Earning_Guid								- УИ записи
--		@Earning_CustomerGuid				- УИ клиента
--		@Earning_CurrencyGuid				- УИ валюты
--		@Earning_Date								- дата платежа
--		@Earning_DocNum							- № документа
--		@Earning_BankCode						- код банка
--		@Earning_Account						- № р/с
--		@Earning_Value							- сумма платежа
--		@Earning_CompanyGuid				- уи компании-получателя платежа
--		@Earning_CurrencyRate				- курс !?
--		@Earning_CurrencyValue			- !?
--		@Earning_CustomerText				-	
--		@Earning_DetailsPaymentText	- 
--		@Earning_iKey								- 
--		@BudgetProjectSRC_Guid			- УИ проекта-источника
--		@BudgetProjectDST_Guid			- УИ проекта-получателя
--		@CompanyPayer_Guid					- УИ компании-плательщика
--		@ChildDepart_Guid						- УИ дочернего клиента
--		@AccountPlan_Guid						- УИ записи в плане счетов
--		@PaymentType_Guid						- УИ формы оплаты
--		@Earning_IsBonus						- признак "бонусный платёж"

-- Выходные параметры:
--
--  @ERROR_NUM										- номер ошибки
--  @ERROR_MES										- текст ошибки
--
-- Результат:
--    0 - Успешное завершение
--    <>0 - ошибка

CREATE PROCEDURE [dbo].[usp_EditEarningInSQLandIB] 
  @Earning_Guid								D_GUID,
	@Earning_CustomerGuid				D_GUID = NULL,
	@Earning_CurrencyGuid				D_GUID,
	@Earning_Date								D_Date,
	@Earning_DocNum							D_Name,
	@Earning_BankCode						D_BankCode,
	@Earning_Account						D_Account,
	@Earning_Value							D_Money,
	@Earning_CompanyGuid				D_GUID,
	@Earning_CurrencyRate				D_Money,
	@Earning_CurrencyValue			D_Money,
	@Earning_CustomerText				D_Description,
	@Earning_DetailsPaymentText	nvarchar(max),
	@Earning_iKey								int,
	@BudgetProjectSRC_Guid			D_GUID_NULL = NULL,
	@BudgetProjectDST_Guid			D_GUID_NULL = NULL,
	@CompanyPayer_Guid					D_GUID_NULL = NULL,
	@ChildDepart_Guid						D_GUID_NULL = NULL,
	@AccountPlan_Guid						D_GUID_NULL = NULL,
	@PaymentType_Guid						D_GUID_NULL = NULL,
	@Earning_IsBonus						D_YESNO = 0,

  @ERROR_NUM									int output,
  @ERROR_MES									nvarchar(4000) output

AS

BEGIN

	BEGIN TRY

    SET @ERROR_NUM = 0;
    SET @ERROR_MES = NULL;
    
    DECLARE @EventID D_ID;
    SET @EventID = NULL;
    DECLARE @ParentEventID D_ID;
    SET @ParentEventID = NULL;
    DECLARE @strMessage D_EVENTMSG;
    DECLARE @EventSrc D_NAME;
    SET @EventSrc = 'Платёж';
    
    -- проверка на наличие платежа с указанным идентификатором
		IF NOT EXISTS( SELECT [Earning_Guid] FROM [dbo].[T_Earning] WHERE [Earning_Guid] = @Earning_Guid )
			BEGIN
				SET @ERROR_NUM = 1;
				SET @ERROR_MES = 'В БД уже не найден платёж с указанным идентификатором: ' + CAST( @Earning_Guid AS nvarchar( 36 ) );

				RETURN @ERROR_NUM;
			END
		
		-- определяем УИ банка
    DECLARE @Bank_Guid D_GUID = NULL;
    SELECT TOP 1 @Bank_Guid = Bank_Guid FROM T_Bank	WHERE Bank_Code = @Earning_BankCode;
	  IF( @Bank_Guid IS NULL )
			BEGIN
				SET @ERROR_NUM = 1;
				SET @ERROR_MES = 'В БД уже не найден банк с указанным кодом: ' + @Earning_BankCode;

				RETURN @ERROR_NUM;
			END	
    
		-- определяем УИ счёта    
    DECLARE @Account_Guid D_GUID = NULL;
    SELECT TOP 1 @Account_Guid = Account_Guid FROM T_Account 
		WHERE ( Account_Number = @Earning_Account ) AND	( Bank_Guid = @Bank_Guid );
    
    IF (@Account_Guid IS NULL)
			BEGIN
				DECLARE @AccountTypeMain_Guid D_GUID;	
				SELECT @AccountTypeMain_Guid= [dbo].[GetAccountTypeMainGuid]();

				IF( @AccountTypeMain_Guid IS NULL )
					BEGIN
						SET @ERROR_NUM = 2;
						SET @ERROR_MES = 'В базе данных не найден указанный счёт. Банк (код): ' + @Earning_BankCode + ' Счёт: "' + @Earning_Account + '". Не найден уи для типа счёта "основной".';

						RETURN @ERROR_NUM;
					END	

				DECLARE @NewAccount_Guid D_GUID;
				SET @NewAccount_Guid = NEWID();		
	  		  
				INSERT INTO T_Account (Account_Guid, Bank_Guid, Account_Number, Account_Ddescription,Currency_Giud, Record_Updated, AccountType_Guid)
				VALUES (@NewAccount_Guid, @Bank_Guid, @Earning_Account, null, @Earning_CurrencyGuid, GETDATE(), @AccountTypeMain_Guid)
				
				SET @Account_Guid = @NewAccount_Guid;
			END

		IF NOT EXISTS ( SELECT [Account_Guid] FROM [dbo].[T_Account]	WHERE [Account_Guid] = @Account_Guid )
			BEGIN
				SET @ERROR_NUM = 3;
				SET @ERROR_MES = 'В базе данных не найден счёт с указанным идентификатором: ' + CAST( @Account_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- проект-источник
		IF( @BudgetProjectSRC_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [BUDGETPROJECT_GUID] FROM [dbo].[T_BudgetProject] 
				WHERE [BUDGETPROJECT_GUID] = @BudgetProjectSRC_Guid )
			BEGIN
				SET @ERROR_NUM = 4;
				SET @ERROR_MES = 'В базе данных не найден проект-источник с указанным идентификатором: ' + CAST( @BudgetProjectSRC_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- проект-получатель
		IF( @BudgetProjectDST_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [BUDGETPROJECT_GUID] FROM [dbo].[T_BudgetProject] 
				WHERE [BUDGETPROJECT_GUID] = @BudgetProjectDST_Guid )
			BEGIN
				SET @ERROR_NUM = 5;
				SET @ERROR_MES = 'В базе данных не найден проект-получатель с указанным идентификатором: ' + CAST( @BudgetProjectDST_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- компания-плательщик
		IF( @CompanyPayer_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [Company_Guid] FROM [dbo].[T_Company]
				WHERE [Company_Guid] = @CompanyPayer_Guid )
			BEGIN
				SET @ERROR_NUM = 6;
				SET @ERROR_MES = 'В базе данных не найдена компания-плательщик с указанным идентификатором: ' + CAST( @CompanyPayer_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- дочерний клиент
		DECLARE	@CustomerChild_Guid	D_GUID_NULL = NULL;
		IF( @ChildDepart_Guid IS NOT NULL )
			BEGIN
				SELECT @CustomerChild_Guid = [CustomerChild_Guid] FROM [dbo].[T_CustomerChild]
				WHERE ( [ChildDepart_Guid] = @ChildDepart_Guid ) AND ( [Customer_Guid] = @Earning_CustomerGuid );

				IF( @CustomerChild_Guid IS NULL )
				BEGIN
					SET @ERROR_NUM = 7;
					SET @ERROR_MES = 'В базе данных не найден дочерний клиент с указанным идентификатором: ' + CAST( @CustomerChild_Guid as nvarchar(36) );

					RETURN @ERROR_NUM;
				END	
			END

    -- план счетов
		IF( @AccountPlan_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [ACCOUNTPLAN_GUID] FROM [dbo].[T_AccountPlan]
				WHERE [ACCOUNTPLAN_GUID] = @AccountPlan_Guid )
			BEGIN
				SET @ERROR_NUM = 8;
				SET @ERROR_MES = 'В базе данных не найдена запись в плане счетов с указанным идентификатором: ' + CAST( @AccountPlan_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- форма оплаты
		IF( @PaymentType_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [PaymentType_Guid]  FROM [dbo].[T_PaymentType]
				WHERE [PaymentType_Guid] = @PaymentType_Guid )
			BEGIN
				SET @ERROR_NUM = 9;
				SET @ERROR_MES = 'В базе данных не найдена форма оплаты с указанным идентификатором: ' + CAST( @PaymentType_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

     -- клиент
     IF( @Earning_CustomerGuid IS NOT NULL)
       IF NOT EXISTS ( SELECT Customer_Guid FROM dbo.T_Customer WHERE Customer_Guid = @Earning_CustomerGuid )
        BEGIN
         SET @ERROR_NUM = 10;
         SET @ERROR_MES = 'В базе данных не найден клиент с указанным идентификатором: ' + CAST( @Earning_CustomerGuid as nvarchar(36) );

         RETURN @ERROR_NUM;
        END    

     -- валюта
		 IF NOT EXISTS ( SELECT Currency_Guid FROM dbo.T_Currency WHERE Currency_Guid = @Earning_CurrencyGuid )
      BEGIN
        SET @ERROR_NUM = 11;
        SET @ERROR_MES = 'В базе данных не найдена валюта с указанным идентификатором: ' + CAST( @Earning_CurrencyGuid as nvarchar(36) );

        RETURN @ERROR_NUM;
      END    
			
		 -- компания
     IF NOT EXISTS ( SELECT Company_Guid FROM dbo.T_Company WHERE Company_Guid = @Earning_CompanyGuid )
      BEGIN
        SET @ERROR_NUM = 12;
        SET @ERROR_MES = 'В базе данных не найдена компания с указанным идентификатором: ' + CAST( @Earning_CompanyGuid as nvarchar(36) );

        RETURN @ERROR_NUM;
      END       

    BEGIN TRANSACTION UpdateData;

		UPDATE [dbo].[T_Earning] SET Customer_Guid = @Earning_CustomerGuid, Currency_Guid = @Earning_CurrencyGuid,	
			Earning_Date = @Earning_Date, Earning_DocNum = @Earning_DocNum, Bank_Guid= @Bank_Guid, 
			Account_Guid = @Account_Guid, Earning_Value = @Earning_Value, Company_Guid = @Earning_CompanyGuid, 
			Earning_CurrencyRate = @Earning_CurrencyRate, Earning_CurrencyValue = @Earning_CurrencyValue, 
			Earning_CustomerText = @Earning_CustomerText, Earning_DetailsPaymentText = @Earning_DetailsPaymentText, 
			Earning_iKey = @Earning_iKey, BudgetProjectSRC_Guid = @BudgetProjectSRC_Guid, 
			BudgetProjectDST_Guid = @BudgetProjectDST_Guid,	CompanyPayer_Guid = @CompanyPayer_Guid,
			CustomerChild_Guid = @CustomerChild_Guid,	AccountPlan_Guid = @AccountPlan_Guid,	
			PaymentType_Guid = @PaymentType_Guid,	Earning_IsBonus = @Earning_IsBonus
		WHERE Earning_Guid = @Earning_Guid;

    EXEC dbo.usp_EditEarningInIB @Earning_Guid = @Earning_Guid, @IBLINKEDSERVERNAME = NULL, 
			@ERROR_NUM = @ERROR_NUM output, @ERROR_MES = @ERROR_MES output;

		IF( @ERROR_NUM = 0 )
			BEGIN
				SET @strMessage = 'В БД внесены изменения в информацию о платеже. УИ записи: ' + CONVERT( nvarchar(36), @Earning_Guid );
				COMMIT TRANSACTION UpdateData
			END
		ELSE 
			BEGIN
				SET @strMessage = 'Ошибка изменения реквизитов платежа. ' + @ERROR_MES;
				ROLLBACK TRANSACTION UpdateData;
			END


		EXEC dbo.spAddEventToLog @EVENT_SOURCE = @EventSrc, @EVENT_SOURCEID = @Earning_Guid, @EVENT_CATEGORY = 'None', 
				@EVENT_COMPUTER = ' ', @EVENT_TYPE = 'Info', @EVENT_IS_COMPOSITE = 0, 
				@EVENT_DESCRIPTION = @strMessage, @EVENT_PARENTID = @ParentEventID, @EVENT_ID = @EventID output;

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION UpdateData;

    SET @ERROR_NUM = ERROR_NUMBER();
    SET @ERROR_MES = ERROR_MESSAGE();

		RETURN @ERROR_NUM;
	END CATCH;

	IF( @ERROR_NUM = 0 )
		SET @ERROR_MES = 'Успешное завершение операции.';

	RETURN @ERROR_NUM;
END

GO
GRANT EXECUTE ON [dbo].[usp_EditEarningInSQLandIB] TO [public]
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Удаляет в InterBase информацию о платеже

-- Входные параметры
-- @Earning_Guid					- УИ платежа
-- @IBLINKEDSERVERNAME		- имя LINKEDSERVER

-- Выходные параметры
-- @ERROR_NUM						- номер ошибки
-- @ERROR_MES						- сообщение об ошибке

CREATE PROCEDURE [dbo].[usp_DeleteEarning2FromIB]
  @Earning_Guid				dbo.D_GUID,
  @IBLINKEDSERVERNAME dbo.D_NAME = NULL,

  @ERROR_NUM					int output,
  @ERROR_MES					nvarchar(4000) output
AS

BEGIN
  BEGIN TRY
    SET @ERROR_NUM = -1;
    SET @ERROR_MES = '';

    DECLARE @EventID D_ID;
    SET @EventID = NULL;
    DECLARE @ParentEventID D_ID;
    SET @ParentEventID = NULL;
    DECLARE @strMessage D_EVENTMSG;
    SET @strMessage = '';
    DECLARE @EventSrc D_NAME;
	  SET @EventSrc = 'Удаление платежа в IB';

 	  IF( @IBLINKEDSERVERNAME IS NULL ) SELECT @IBLINKEDSERVERNAME = dbo.GetIBLinkedServerName();

    DECLARE @strIBSQLText nvarchar( 250 );
    DECLARE	@Earning_Id int; 

		-- Проверяем, есть ли проводка с указанным идентификатором 
    IF NOT EXISTS ( SELECT * FROM dbo.T_Earning WHERE Earning_Guid = @Earning_Guid )
      BEGIN
        SET @ERROR_NUM = 1;
        SET @ERROR_MES = '[usp_DeleteEarning2FromIB] Не найден платёж с указанным идентификатором: ' +  CONVERT( nvarchar(36), @Earning_Guid );
        RETURN @ERROR_NUM;
      END
      
		SELECT @Earning_Id = Earning_Id
		FROM dbo.T_Earning WHERE Earning_Guid = @Earning_Guid;
		
    DECLARE @SQLString nvarchar( 2048 );
    DECLARE @ParmDefinition nvarchar( 500 );
    DECLARE @RETURNVALUE int;


    SET @ParmDefinition = N'@ErrorNum_Ib int output, @ErrorText_Ib varchar(480) output'; 

    
    SET @SQLString = 'SELECT @ErrorNum_Ib = ERROR_NUMBER, @ErrorText_Ib = ERROR_TEXT FROM OPENQUERY( ' + 
			@IBLINKEDSERVERNAME + ', ''SELECT ERROR_NUMBER, ERROR_TEXT FROM  SP_DELETE_EARNING_2_FROMSQL  ( ' +
			'''''' + cast( @Earning_Id as nvarchar(50)) + ''''' )'' )'; 

    EXECUTE sp_executesql @SQLString, @ParmDefinition, @ErrorNum_Ib = @ERROR_NUM output, @ErrorText_Ib = @ERROR_MES output;

 	END TRY
	BEGIN CATCH
    SET @ERROR_NUM = ERROR_NUMBER();
    SET @ERROR_MES = ERROR_MESSAGE();
    SET @strMessage = @ERROR_MES;
    EXEC dbo.spAddEventToLog @EVENT_SOURCE = @EventSrc, @EVENT_CATEGORY = 'None', 
      @EVENT_COMPUTER = ' ', @EVENT_TYPE = 'Error', @EVENT_IS_COMPOSITE = 0, 
      @EVENT_DESCRIPTION = @strMessage, @EVENT_PARENTID = @ParentEventID, @EVENT_ID = @EventID output;

		RETURN @ERROR_NUM;
	END CATCH;

	RETURN @ERROR_NUM;

END

GO
GRANT EXECUTE ON [dbo].[usp_DeleteEarning2FromIB] TO [public]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Удаление элемента из таблицы dbo.T_Earning
--
-- Входящие параметры:
--
--		@Earning_Guid - уникальный идентификатор записи
--
-- Выходные параметры:
--
--		@ERROR_NUM		- номер ошибки
--		@ERROR_MES		- сообщение об ошибке

-- Результат:
--    0 - успешное завершение
--    <>0 - ошибка

CREATE PROCEDURE [dbo].[usp_DeleteEarning2] 
	@Earning_Guid		D_GUID,

  @ERROR_NUM			int output,
  @ERROR_MES			nvarchar(4000) output

AS

BEGIN

  SET @ERROR_NUM = 0;
  SET @ERROR_MES = '';

	BEGIN TRY

		IF NOT EXISTS ( SELECT Earning_Guid FROM dbo.[T_Earning] WHERE Earning_Guid = @Earning_Guid )
		BEGIN
			SET @ERROR_NUM = 1;
			SET @ERROR_MES = 'В базе данных не найден платёж с указанным идентификатором: ' + CAST( @Earning_Guid as nvarchar(36) );

			RETURN @ERROR_NUM;
		END       

		DECLARE @Earning_iKey int;
		SELECT @Earning_iKey = [Earning_iKey] FROM [dbo].[T_Earning]
		WHERE [Earning_Guid] = @Earning_Guid;

		BEGIN TRANSACTION UpdateData;	
	
		EXEC dbo.usp_DeleteEarning2FromIB @Earning_Guid = @Earning_Guid, @IBLINKEDSERVERNAME = NULL, 
			@ERROR_NUM = @ERROR_NUM output, @ERROR_MES = @ERROR_MES output;

		IF( @ERROR_NUM = 0 ) 
			BEGIN
				DELETE FROM dbo.[T_Earning] WHERE Earning_Guid = @Earning_Guid;
				
				COMMIT TRANSACTION UpdateData;
			END
		ELSE ROLLBACK TRANSACTION UpdateData;

    
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION UpdateData;
		
		SET @ERROR_NUM = ERROR_NUMBER();
		SET @ERROR_MES = ERROR_MESSAGE();
		
		RETURN @ERROR_NUM;
	END CATCH;

	IF( @ERROR_NUM = 0 )
		SET @ERROR_MES = 'Платёж успешно удалён. УИ платежа: ' + CAST( @Earning_Guid as nvarchar(36) );
	
	RETURN @ERROR_NUM;
END


GO
GRANT EXECUTE ON [dbo].[usp_DeleteEarning2] TO [public]
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Добавляет расчетный счет без привязки к владельцу
--
-- Входящие параметры:
--	 @Bank_Guid							- уникальный идентификатор банка
--	 @Currency_Guid					- уникальный идентификатор валюты
--	 @Account_Number				- номер расчетного счета
-- @Account_Ddescription		- примечание
-- @AccountType_Guid				- тип расчётного счёта

--
-- Выходные параметры:
--  @Account_Guid					- уникальный идентификатор расчетного счета
--  @ERROR_NUM							- номер ошибки
--  @ERROR_MES							- текст ошибки
--
-- Результат:
--    0 - Успешное завершение
--    <>0 - ошибка

CREATE PROCEDURE [dbo].[usp_AddAccount] 
	@Bank_Guid						D_GUID,
	@Currency_Guid				D_GUID,
	@Account_Number				D_ACCOUNT,
	@Account_Description	D_DESCRIPTION = NULL,
	@AccountType_Guid			D_GUID,

  @Account_Guid					D_GUID output,
  @ERROR_NUM						int output,
  @ERROR_MES						nvarchar(4000) output

AS

BEGIN

	BEGIN TRY

    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';
    SET @Account_Guid = NULL;

     IF NOT EXISTS ( SELECT * FROM dbo.T_Currency WHERE Currency_Guid = @Currency_Guid )
      BEGIN
        SET @ERROR_NUM = 2;
        SET @ERROR_MES = 'В базе данных не найдена валюта с указанным идентификатором.'  + nChar(13) + nChar(10) + CONVERT( nvarchar(36), @Currency_Guid ) ;
        RETURN @ERROR_NUM;
      END

		IF NOT EXISTS ( SELECT * FROM dbo.T_Bank WHERE Bank_Guid = @Bank_Guid )
		BEGIN
			SET @ERROR_NUM = 3;
			SET @ERROR_MES = 'В базе данных не найден банк с указанным идентификатором.'  + nChar(13) + nChar(10) + CONVERT( nvarchar(36), @Bank_Guid ) ;
			RETURN @ERROR_NUM;
		END

		IF NOT EXISTS ( SELECT * FROM dbo.T_AccountType WHERE AccountType_Guid = @AccountType_Guid )
		BEGIN
			SET @ERROR_NUM = 4;
			SET @ERROR_MES = 'В базе данных не найден тип расчетного счета с указанным идентификатором.'  + nChar(13) + nChar(10) + CONVERT( nvarchar(36), @AccountType_Guid ) ;
			RETURN @ERROR_NUM;
		END

		SELECT @Account_Guid = Account_Guid FROM dbo.T_Account WHERE Bank_Guid = @Bank_Guid  AND Account_Number = @Account_Number;
		

    IF( @Account_Guid IS NULL )  
			BEGIN
				DECLARE @NewID D_GUID;
				SET @NewID = NEWID ( );	

				INSERT INTO dbo.T_Account( Account_Guid, Bank_Guid, Account_Number, Account_Ddescription, Currency_Giud, AccountType_Guid )
				VALUES( @NewID, @Bank_Guid, @Account_Number, @Account_Description, @Currency_Guid, @AccountType_Guid );

				SET @Account_Guid = @NewID;
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
GRANT EXECUTE ON [dbo].[usp_AddAccount] TO [public]
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Редактирует расчетный счет без привязки к владельцу
--
-- Входящие параметры:
-- @Account_Guid						- уникальный идентификатор расчетного счета
--	 @Bank_Guid							- уникальный идентификатор банка
--	 @Currency_Guid					- уникальный идентификатор валюты
--	 @Account_Number				- номер расчетного счета
-- @Account_Ddescription		- примечание
-- @AccountType_Guid				- тип расчётного счёта

--
-- Выходные параметры:
--  @ERROR_NUM							- номер ошибки
--  @ERROR_MES							- текст ошибки
--
-- Результат:
--    0 - Успешное завершение
--    <>0 - ошибка

CREATE PROCEDURE [dbo].[usp_EditAccount] 
  @Account_Guid					D_GUID,
	@Bank_Guid						D_GUID,
	@Currency_Guid				D_GUID,
	@Account_Number				D_ACCOUNT,
	@Account_Description	D_DESCRIPTION = NULL,
	@AccountType_Guid			D_GUID,

  @ERROR_NUM						int output,
  @ERROR_MES						nvarchar(4000) output

AS

BEGIN

	BEGIN TRY

    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';

     IF NOT EXISTS ( SELECT Account_Guid FROM dbo.T_Account WHERE Account_Guid = @Account_Guid )
      BEGIN
        SET @ERROR_NUM = 1;
        SET @ERROR_MES = 'В базе данных не найден счёт с указанным идентификатором.'  + nChar(13) + nChar(10) + CONVERT( nvarchar(36), @Account_Guid ) ;
        RETURN @ERROR_NUM;
      END

     IF EXISTS ( SELECT Account_Guid FROM dbo.T_Account 
		 WHERE Bank_Guid = @Bank_Guid  
			AND Account_Number = @Account_Number
			AND Account_Guid <> @Account_Guid )
      BEGIN
        SET @ERROR_NUM = 1;
        SET @ERROR_MES = 'В базе данных уже зарегистрирован счёт с указанным номером и банком.';
        RETURN @ERROR_NUM;
      END

		SELECT @Account_Guid = Account_Guid FROM dbo.T_Account WHERE Bank_Guid = @Bank_Guid  AND Account_Number = @Account_Number;


     IF NOT EXISTS ( SELECT * FROM dbo.T_Currency WHERE Currency_Guid = @Currency_Guid )
      BEGIN
        SET @ERROR_NUM = 2;
        SET @ERROR_MES = 'В базе данных не найдена валюта с указанным идентификатором.'  + nChar(13) + nChar(10) + CONVERT( nvarchar(36), @Currency_Guid ) ;
        RETURN @ERROR_NUM;
      END

		IF NOT EXISTS ( SELECT * FROM dbo.T_Bank WHERE Bank_Guid = @Bank_Guid )
		BEGIN
			SET @ERROR_NUM = 3;
			SET @ERROR_MES = 'В базе данных не найден банк с указанным идентификатором.'  + nChar(13) + nChar(10) + CONVERT( nvarchar(36), @Bank_Guid ) ;
			RETURN @ERROR_NUM;
		END

		IF NOT EXISTS ( SELECT * FROM dbo.T_AccountType WHERE AccountType_Guid = @AccountType_Guid )
		BEGIN
			SET @ERROR_NUM = 4;
			SET @ERROR_MES = 'В базе данных не найден тип расчетного счета с указанным идентификатором.'  + nChar(13) + nChar(10) + CONVERT( nvarchar(36), @AccountType_Guid ) ;
			RETURN @ERROR_NUM;
		END

		UPDATE dbo.T_Account SET Bank_Guid = @Bank_Guid, Account_Number = @Account_Number, Account_Ddescription = @Account_Description, 
			Currency_Giud = @Currency_Guid, AccountType_Guid = @AccountType_Guid
		WHERE Account_Guid = @Account_Guid;

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
GRANT EXECUTE ON [dbo].[usp_EditAccount] TO [public]
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Удаляет расчётный счёт
--
-- Входящие параметры:
--  @Account_Guid - уникальный идентификатор расчетного счета
--
-- Выходные параметры:
--  @ERROR_NUM - номер ошибки
--  @ERROR_MES - текст ошибки
--
-- Результат:
--    0 - Успешное завершение
--    <>0 - ошибка

CREATE PROCEDURE [dbo].[usp_DeleteAccount] 
  @Account_Guid D_GUID,

  @ERROR_NUM int output,
  @ERROR_MES nvarchar(4000) output

AS

BEGIN

	BEGIN TRY

    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';

		DELETE FROM dbo.T_Account WHERE Account_Guid = @Account_Guid;

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
GRANT EXECUTE ON [dbo].[usp_DeleteAccount] TO [public]
GO



SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- Возвращает список расчетных счетов
--
-- Входящие параметры:
--		@Account_Number	- номер расчётного счёта
--		@Bank_Guid			- уи банка
--
-- Выходные параметры:
--		@ERROR_NUM			- номер ошибки 
--		@ERROR_MES			- текст ошибки 
--
-- Результат:
--    0 - успешное завершение
--    <>0 - ошибка запроса информации из базы данных

CREATE PROCEDURE [dbo].[usp_GetAccount] 
	@Account_Number				D_NAME = '',
	@Bank_Guid						D_GUID = NULL,

  @ERROR_NUM						int output,
  @ERROR_MES						nvarchar( 4000 ) output
AS

BEGIN

  SET @ERROR_NUM = 0;
  SET @ERROR_MES = '';
	
	DECLARE @FindAccountNumber D_NAME = '';
	SET @FindAccountNumber = ( '%' + @Account_Number + '%' );

  BEGIN TRY

    CREATE TABLE #Account( Account_Guid uniqueidentifier, Account_Number nvarchar(56), Bank_Guid uniqueidentifier, Currency_Giud uniqueidentifier, 
			Account_Ddescription nvarchar(512), Currency_Abbr nvarchar(3), Currency_Code nvarchar(3), 
			Bank_Code nvarchar(3), Bank_IsActive bit, Bank_MFO nvarchar(16), Bank_Name nvarchar(128), Bank_ParentGuid uniqueidentifier, Bank_UNN nvarchar(16), 
			AccountType_Guid uniqueidentifier, AccountType_Name nvarchar(128), AccountType_IsActive bit, 
			CompanyAccount_IsMain bit );

		INSERT INTO #Account( Account_Guid, Account_Number, Bank_Guid, Currency_Giud, 
			Account_Ddescription, Currency_Abbr, Currency_Code, 
			Bank_Code, Bank_IsActive, Bank_MFO, Bank_Name, Bank_ParentGuid, Bank_UNN, 
			AccountType_Guid, AccountType_Name, AccountType_IsActive, CompanyAccount_IsMain )
		SELECT Account.Account_Guid, Account.Account_Number, Account.Bank_Guid, Account.Currency_Giud, 
			Account.Account_Ddescription, Currency.Currency_Abbr, Currency.Currency_Code, 
			Bank.Bank_Code, Bank.Bank_IsActive, Bank.Bank_MFO, Bank.Bank_Name, Bank.Bank_ParentGuid, Bank.Bank_UNN,
			Account.AccountType_Guid, AcoountType.AccountType_Name, AcoountType.AccountType_IsActive, 
			CAST( 0 as bit ) AS CompanyAccount_IsMain
    FROM dbo.T_Account as Account, dbo.T_Bank as Bank, dbo.T_Currency as Currency, dbo.T_AccountType as AcoountType
    WHERE Account.Bank_Guid = Bank.Bank_Guid
			AND Account.Currency_Giud = Currency.Currency_Guid
			AND Account.AccountType_Guid = AcoountType.AccountType_Guid;

		IF( @Bank_Guid IS NOT NULL ) 
			DELETE FROM #Account WHERE Bank_Guid <> @Bank_Guid;

		IF( @Account_Number <> '' ) 
			DELETE FROM #Account WHERE Account_Number NOT LIKE @FindAccountNumber;

		SELECT Account_Guid, Account_Number, Bank_Guid, Currency_Giud, 
			Account_Ddescription, Currency_Abbr, Currency_Code, 
			Bank_Code, Bank_IsActive, Bank_MFO, Bank_Name, Bank_ParentGuid, Bank_UNN, 
			AccountType_Guid, AccountType_Name, AccountType_IsActive, CompanyAccount_IsMain
		FROM #Account
		ORDER BY Account_Number;

		DROP TABLE #Account;

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
GRANT EXECUTE ON [dbo].[usp_GetAccount] TO [public]
GO

/****** Object:  StoredProcedure [dbo].[usp_AddEarningToSQLandIB]    Script Date: 08.04.2013 15:57:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Добавляет новую запись в таблицу dbo.T_Earning
--
-- Входящие параметры:
--
--		@Earning_CustomerGuid				- УИ клиента
--		@Earning_CurrencyGuid				- УИ валюты
--		@Earning_Date								- дата платежа
--		@Earning_DocNum							- № документа
--		@Earning_BankCode						- код банка
--		@Earning_Account						- № р/с
--		@Earning_Value							- сумма платежа
--		@Earning_CompanyGuid				- уи компании-получателя платежа
--		@Earning_CurrencyRate				- курс !?
--		@Earning_CurrencyValue			- !?
--		@Earning_CustomerText				-	
--		@Earning_DetailsPaymentText	- 
--		@Earning_iKey								- 
--		@BudgetProjectSRC_Guid			- УИ проекта-источника
--		@BudgetProjectDST_Guid			- УИ проекта-получателя
--		@CompanyPayer_Guid					- УИ компании-плательщика
--		@ChildDepart_Guid						- УИ дочернего клиента
--		@AccountPlan_Guid						- УИ записи в плане счетов
--		@PaymentType_Guid						- УИ формы оплаты
--		@Earning_IsBonus						- признак "бонусный платёж"

-- Выходные параметры:
--
--  @Earning_Guid								- УИ записи
--  @ERROR_NUM										- номер ошибки
--  @ERROR_MES										- текст ошибки
--
-- Результат:
--    0 - Успешное завершение
--    <>0 - ошибка

ALTER PROCEDURE [dbo].[usp_AddEarningToSQLandIB] 
	@Earning_CustomerGuid				D_GUID = NULL,
	@Earning_CurrencyGuid				D_GUID,
	@Earning_Date								D_Date,
	@Earning_DocNum							D_Name,
	@Earning_AccountGuid				D_GUID,
	@Earning_Value							D_Money,
	@Earning_CompanyGuid				D_GUID,
	@Earning_CurrencyRate				D_Money,
	@Earning_CurrencyValue			D_Money,
	@Earning_CustomerText				D_Description,
	@Earning_DetailsPaymentText	nvarchar(max),
	@Earning_iKey								int,
	@BudgetProjectSRC_Guid			D_GUID_NULL = NULL,
	@BudgetProjectDST_Guid			D_GUID_NULL = NULL,
	@CompanyPayer_Guid					D_GUID_NULL = NULL,
	@ChildDepart_Guid						D_GUID_NULL = NULL,
	@AccountPlan_Guid						D_GUID_NULL = NULL,
	@PaymentType_Guid						D_GUID_NULL = NULL,
	@Earning_IsBonus						D_YESNO = 0,

  @Earning_Guid								D_GUID output,
  @ERROR_NUM									int output,
  @ERROR_MES									nvarchar(4000) output

AS

BEGIN

	BEGIN TRY

    SET @ERROR_NUM = 0;
    SET @ERROR_MES = NULL;
    SET @Earning_Guid = NULL;
    
    DECLARE @EventID D_ID;
    SET @EventID = NULL;
    DECLARE @ParentEventID D_ID;
    SET @ParentEventID = NULL;
    DECLARE @strMessage D_EVENTMSG;
    DECLARE @EventSrc D_NAME;
		DECLARE @Bank_Guid D_GUID;

    SET @EventSrc = 'Платёж';
    
		-- определяем УИ счёта    
    DECLARE @Account_Guid D_GUID = NULL;
    SELECT TOP 1 @Account_Guid = Account_Guid, @Bank_Guid = Bank_Guid FROM T_Account 
		WHERE Account_Guid = @Earning_AccountGuid;
    
		IF NOT EXISTS ( SELECT [Account_Guid] FROM [dbo].[T_Account]	WHERE [Account_Guid] = @Earning_AccountGuid )
			BEGIN
				SET @ERROR_NUM = 3;
				SET @ERROR_MES = 'В базе данных не найден счёт с указанным идентификатором: ' + CAST( @Earning_AccountGuid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	
		ELSE 
			SELECT TOP 1 @Account_Guid = Account_Guid, @Bank_Guid = Bank_Guid FROM T_Account 
			WHERE Account_Guid = @Earning_AccountGuid;			

    -- проект-источник
		IF( @BudgetProjectSRC_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [BUDGETPROJECT_GUID] FROM [dbo].[T_BudgetProject] 
				WHERE [BUDGETPROJECT_GUID] = @BudgetProjectSRC_Guid )
			BEGIN
				SET @ERROR_NUM = 4;
				SET @ERROR_MES = 'В базе данных не найден проект-источник с указанным идентификатором: ' + CAST( @BudgetProjectSRC_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- проект-получатель
		IF( @BudgetProjectDST_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [BUDGETPROJECT_GUID] FROM [dbo].[T_BudgetProject] 
				WHERE [BUDGETPROJECT_GUID] = @BudgetProjectDST_Guid )
			BEGIN
				SET @ERROR_NUM = 5;
				SET @ERROR_MES = 'В базе данных не найден проект-получатель с указанным идентификатором: ' + CAST( @BudgetProjectDST_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- компания-плательщик
		IF( @CompanyPayer_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [Company_Guid] FROM [dbo].[T_Company]
				WHERE [Company_Guid] = @CompanyPayer_Guid )
			BEGIN
				SET @ERROR_NUM = 6;
				SET @ERROR_MES = 'В базе данных не найдена компания-плательщик с указанным идентификатором: ' + CAST( @CompanyPayer_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- дочерний клиент
		DECLARE	@CustomerChild_Guid	D_GUID_NULL = NULL;
		IF( @ChildDepart_Guid IS NOT NULL )
			BEGIN
				SELECT @CustomerChild_Guid = [CustomerChild_Guid] FROM [dbo].[T_CustomerChild]
				WHERE ( [ChildDepart_Guid] = @ChildDepart_Guid ) AND ( [Customer_Guid] = @Earning_CustomerGuid );

				IF( @CustomerChild_Guid IS NULL )
				BEGIN
					SET @ERROR_NUM = 7;
					SET @ERROR_MES = 'В базе данных не найден дочерний клиент с указанным идентификатором: ' + CAST( @CustomerChild_Guid as nvarchar(36) );

					RETURN @ERROR_NUM;
				END	
			END

    -- план счетов
		IF( @AccountPlan_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [ACCOUNTPLAN_GUID] FROM [dbo].[T_AccountPlan]
				WHERE [ACCOUNTPLAN_GUID] = @AccountPlan_Guid )
			BEGIN
				SET @ERROR_NUM = 8;
				SET @ERROR_MES = 'В базе данных не найдена запись в плане счетов с указанным идентификатором: ' + CAST( @AccountPlan_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- форма оплаты
		IF( @PaymentType_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [PaymentType_Guid]  FROM [dbo].[T_PaymentType]
				WHERE [PaymentType_Guid] = @PaymentType_Guid )
			BEGIN
				SET @ERROR_NUM = 9;
				SET @ERROR_MES = 'В базе данных не найдена форма оплаты с указанным идентификатором: ' + CAST( @PaymentType_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

     -- клиент
     IF( @Earning_CustomerGuid IS NOT NULL)
       IF NOT EXISTS ( SELECT Customer_Guid FROM dbo.T_Customer WHERE Customer_Guid = @Earning_CustomerGuid )
        BEGIN
         SET @ERROR_NUM = 10;
         SET @ERROR_MES = 'В базе данных не найден клиент с указанным идентификатором: ' + CAST( @Earning_CustomerGuid as nvarchar(36) );

         RETURN @ERROR_NUM;
        END    

     -- валюта
		 IF NOT EXISTS ( SELECT Currency_Guid FROM dbo.T_Currency WHERE Currency_Guid = @Earning_CurrencyGuid )
      BEGIN
        SET @ERROR_NUM = 11;
        SET @ERROR_MES = 'В базе данных не найдена валюта с указанным идентификатором: ' + CAST( @Earning_CurrencyGuid as nvarchar(36) );

        RETURN @ERROR_NUM;
      END    

     IF NOT EXISTS ( SELECT Company_Guid FROM dbo.T_Company WHERE Company_Guid = @Earning_CompanyGuid )
      BEGIN
        SET @ERROR_NUM = 12;
        SET @ERROR_MES = 'В базе данных не найдена компания с указанным идентификатором: ' + CAST( @Earning_CompanyGuid as nvarchar(36) );

        RETURN @ERROR_NUM;
      END       

    DECLARE @NewID D_GUID;
    SET @NewID = NEWID ( );	
                
    DECLARE @Earning_Id D_ID;
    EXEC @Earning_Id = SP_GetGeneratorID @strTableName = 'T_Earning';
       
    
    BEGIN TRANSACTION UpdateData;

    INSERT INTO dbo.T_Earning ( Earning_Guid, Earning_Id, Customer_Guid, Currency_Guid,	Earning_Date, 
			Earning_DocNum, Bank_Guid, Account_Guid, Earning_Value, Earning_Expense, Company_Guid, 
			Earning_CurrencyRate, Earning_CurrencyValue, Earning_CustomerText, Earning_DetailsPaymentText, 
			Earning_iKey, BudgetProjectSRC_Guid, BudgetProjectDST_Guid,	CompanyPayer_Guid,
			CustomerChild_Guid,	AccountPlan_Guid,	PaymentType_Guid,	Earning_IsBonus )
		VALUES( @NewID, @Earning_Id, @Earning_CustomerGuid, @Earning_CurrencyGuid, @Earning_Date, 
			@Earning_DocNum, @Bank_Guid,  @Account_Guid, @Earning_Value, 0, @Earning_CompanyGuid, 
			@Earning_CurrencyRate, @Earning_CurrencyValue, @Earning_CustomerText, @Earning_DetailsPaymentText, 
			@Earning_iKey, @BudgetProjectSRC_Guid, @BudgetProjectDST_Guid,	@CompanyPayer_Guid,
			@CustomerChild_Guid,	@AccountPlan_Guid,	@PaymentType_Guid,	@Earning_IsBonus );
        
		SET @Earning_Guid = @NewID;
	
    EXEC dbo.usp_AddEarningToIB @Earning_Guid = @NewID, @IBLINKEDSERVERNAME = NULL, @Earning_Id = @Earning_Id output,
			@ERROR_NUM = @ERROR_NUM output, @ERROR_MES = @ERROR_MES output;

		IF( @ERROR_NUM = 0 )
			BEGIN
				SET @strMessage = 'В БД добавлена информация о новом платеже. УИ записи: ' + CONVERT( nvarchar(36), @Earning_Guid );
				COMMIT TRANSACTION UpdateData
			END
		ELSE 
			BEGIN
				SET @strMessage = 'Ошибка регистрации платежа. ' + @ERROR_MES;
				ROLLBACK TRANSACTION UpdateData;
			END


		EXEC dbo.spAddEventToLog @EVENT_SOURCE = @EventSrc, @EVENT_SOURCEID = @Earning_Guid, @EVENT_CATEGORY = 'None', 
				@EVENT_COMPUTER = ' ', @EVENT_TYPE = 'Info', @EVENT_IS_COMPOSITE = 0, 
				@EVENT_DESCRIPTION = @strMessage, @EVENT_PARENTID = @ParentEventID, @EVENT_ID = @EventID output;

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION UpdateData;

    SET @ERROR_NUM = ERROR_NUMBER();
    SET @ERROR_MES = ERROR_MESSAGE();

		RETURN @ERROR_NUM;
	END CATCH;

	IF( @ERROR_NUM = 0 )
		SET @ERROR_MES = 'Успешное завершение операции.';

	RETURN @ERROR_NUM;
END

GO

/****** Object:  StoredProcedure [dbo].[usp_EditEarningInIB]    Script Date: 08.04.2013 16:11:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Редактирует в InterBase информацию о платеже

-- Входные параметры
-- 
-- @Earning_Guid - УИ платежа
-- @IBLINKEDSERVERNAME		- имя LINKEDSERVER для подключения к InterBase
--
-- Выходные параметры
--
-- @ERROR_NUM						- номер ошибки
-- @ERROR_MES						- сообщение об ошибке

ALTER PROCEDURE [dbo].[usp_EditEarningInIB]
	@Earning_Guid					D_GUID,
	@IBLINKEDSERVERNAME		D_NAME = NULL,

	@ERROR_NUM						int output,
	@ERROR_MES						nvarchar(4000) output
AS

BEGIN
  BEGIN TRY
    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';

		IF NOT EXISTS ( SELECT Earning_Guid FROM dbo.[T_Earning] WHERE Earning_Guid = @Earning_Guid )
			BEGIN
				SET @ERROR_NUM = 1;
				SET @ERROR_MES = 'В базе данных не найден платёж с указанным идентификатором: ' + CAST( @Earning_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END       

    DECLARE @EventID D_ID = NULL;
    DECLARE @ParentEventID D_ID = NULL;
    DECLARE @strMessage D_EVENTMSG = '';
    DECLARE @EventSrc D_NAME = 'Создание записи по банковской выписке в IB';

	  IF( @IBLINKEDSERVERNAME IS NULL ) SELECT @IBLINKEDSERVERNAME = dbo.GetIBLinkedServerName();
	  
    
    DECLARE @Earning_Id							int;
    DECLARE @Earning_Code						int;
    DECLARE @Earning_CustomerId			int;
    DECLARE @Earning_CurrencyCode		D_CURRENCYCODE;
    DECLARE @Earning_Date						D_Date;
    DECLARE @Earning_DocNum					D_Name;
    DECLARE @Earning_BankCode				D_BankCode;
    DECLARE @Earning_BankAccount		D_Account;
    DECLARE @Earning_Value					float;
    DECLARE @Earning_Expense				float;
    DECLARE @Earning_Saldo					float;
    DECLARE @Earning_CompanyId			int;
    DECLARE @Earning_CurrencyRate		float;
    DECLARE @Earning_CurrencyValue	float;
    DECLARE @Earning_UsdValue				float;
    DECLARE @Earning_iKey						int;
    DECLARE @Account_Guid						D_GUID;
    DECLARE @Bank_Guid							D_Guid;
		DECLARE @Customer_Guid					D_GUID;
  
    SELECT @Earning_Id = Earning_Id, @Customer_Guid = Customer_Guid, @Earning_CustomerId = [Customer_Id], @Earning_CurrencyCode =  [Currency_Abbr], 
			@Earning_Date = [Earning_Date], @Earning_DocNum = [Earning_DocNum], 
			@Account_Guid = [Account_Guid], @Bank_Guid = [Bank_Guid], @Earning_Value = [Earning_Value],
			@Earning_Expense = [Earning_Expense], @Earning_Saldo = [Earning_Saldo],
			@Earning_CompanyId = [Company_Id], @Earning_CurrencyRate = [Earning_CurrencyRate],
			@Earning_CurrencyValue = [Earning_CurrencyValue], @Earning_iKey = [Earning_iKey], 
			@Earning_BankAccount = [AccountViewAccount_Number], @Earning_BankCode = [Bank_Code]
		FROM [dbo].[EarningView] WHERE Earning_Guid = @Earning_Guid;
      
    IF( @Earning_CustomerId IS NULL ) SET @Earning_CustomerId = 0;
		IF( @Earning_iKey IS NULL ) SET @Earning_iKey = 0;
		IF( @Earning_CompanyId IS NULL )
      BEGIN
        SET @ERROR_NUM = 2;
        SET @ERROR_MES = 'Не найдена компания, указанная в платеже. УИ платежа: ' + CAST( @Earning_Guid as nvarchar(36) );

        RETURN @ERROR_NUM;
      END 

    SET @Earning_UsdValue=0	
    SET @Earning_Code=0
				   
    DECLARE @SQLString nvarchar( 2048 );
    DECLARE @ParmDefinition nvarchar( 500 );
    DECLARE @RETURNVALUE int;

    SET @ParmDefinition = N'@ErrorNum_Ib int output, @ErrorText_Ib varchar(480) output'; 				
					
		SET @SQLString = 'SELECT  @ErrorNum_Ib = ERROR_NUMBER, @ErrorText_Ib = ERROR_TEXT FROM OPENQUERY( ' + 
			@IBLINKEDSERVERNAME + ', ''SELECT ERROR_NUMBER, ERROR_TEXT FROM SP_EDIT_EARNING_FROMSQL( ' + cast( @Earning_Id as nvarchar( 20)) + ', ' + +
					'''''' + cast( @Earning_Code as nvarchar(10)) + '''''' + ', ' +
					'''''' + cast( @Earning_CustomerId as nvarchar(10)) + '''''' + ', ' +
					'''''' + cast( @Earning_CurrencyCode as nvarchar(4)) + '''''' + ', ' +
					'''''' + cast( @Earning_Date as nvarchar(10)) + '''''' + ', ' +
					'''''' + cast( @Earning_DocNum as nvarchar(10)) + '''''' + ', ' +
					'''''' + cast( @Earning_BankCode as nvarchar(4)) + '''''' + ', ' +	
					'''''' + cast( @Earning_BankAccount as nvarchar(13)) + '''''' + ', ' +
					'''''' + convert(varchar(50),cast(@Earning_Value as money)) + '''''' + ', ' +
					'''''' + cast( @Earning_Expense as nvarchar(25)) + '''''' + ', ' +
					'''''' + cast( @Earning_CompanyId as nvarchar(25)) + '''''' + ', ' +
					'''''' + cast( @Earning_CurrencyRate as nvarchar(15)) + '''''' + ', ' +
					'''''' + cast( @Earning_CurrencyValue as nvarchar(25)) + '''''' + ', ' +
					'''''' + cast( @Earning_UsdValue as nvarchar( 10 )) + '''''' + ', ' +
					'''''' + cast( @Earning_iKey as nvarchar( 50 )) + ''''' )'' )'; 
					
    EXECUTE sp_executesql @SQLString, @ParmDefinition, 
			@ErrorNum_Ib = @ERROR_NUM output, @ErrorText_Ib = @ERROR_MES output;  
		
	END TRY
	
	BEGIN CATCH
    SET @ERROR_NUM = ERROR_NUMBER();
    SET @ERROR_MES = @ERROR_MES + ' ' + ERROR_MESSAGE();
    SET @strMessage = @ERROR_MES + ' ' + @Earning_Id;
    
		EXEC dbo.spAddEventToLog @EVENT_SOURCE = @EventSrc, @EVENT_CATEGORY = 'None', 
      @EVENT_COMPUTER = ' ', @EVENT_TYPE = 'Error', @EVENT_IS_COMPOSITE = 0, 
      @EVENT_DESCRIPTION = @strMessage, @EVENT_PARENTID = @ParentEventID, @EVENT_ID = @EventID output;

		RETURN @ERROR_NUM;
	END CATCH;

	IF( @ERROR_NUM = 0 )
		SET @ERROR_MES = 'Успешное завершение операции. Код платежа в IB: ' + CAST( @Earning_Id as nvarchar( 56 ) );

	RETURN @ERROR_NUM;

END

GO

/****** Object:  StoredProcedure [dbo].[usp_EditEarningInSQLandIB]    Script Date: 08.04.2013 16:09:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Редактирует запись в таблице dbo.T_Earning
--
-- Входящие параметры:
--
--  @Earning_Guid								- УИ записи
--		@Earning_CustomerGuid				- УИ клиента
--		@Earning_CurrencyGuid				- УИ валюты
--		@Earning_Date								- дата платежа
--		@Earning_DocNum							- № документа
--		@Earning_AccountGuid				- УИ р/с
--		@Earning_Value							- сумма платежа
--		@Earning_CompanyGuid				- уи компании-получателя платежа
--		@Earning_CurrencyRate				- курс !?
--		@Earning_CurrencyValue			- !?
--		@Earning_CustomerText				-	
--		@Earning_DetailsPaymentText	- 
--		@Earning_iKey								- 
--		@BudgetProjectSRC_Guid			- УИ проекта-источника
--		@BudgetProjectDST_Guid			- УИ проекта-получателя
--		@CompanyPayer_Guid					- УИ компании-плательщика
--		@ChildDepart_Guid						- УИ дочернего клиента
--		@AccountPlan_Guid						- УИ записи в плане счетов
--		@PaymentType_Guid						- УИ формы оплаты
--		@Earning_IsBonus						- признак "бонусный платёж"

-- Выходные параметры:
--
--  @ERROR_NUM										- номер ошибки
--  @ERROR_MES										- текст ошибки
--
-- Результат:
--    0 - Успешное завершение
--    <>0 - ошибка

ALTER PROCEDURE [dbo].[usp_EditEarningInSQLandIB] 
  @Earning_Guid								D_GUID,
	@Earning_CustomerGuid				D_GUID = NULL,
	@Earning_CurrencyGuid				D_GUID,
	@Earning_Date								D_Date,
	@Earning_DocNum							D_Name,
	@Earning_AccountGuid				D_GUID,
	@Earning_Value							D_Money,
	@Earning_CompanyGuid				D_GUID,
	@Earning_CurrencyRate				D_Money,
	@Earning_CurrencyValue			D_Money,
	@Earning_CustomerText				D_Description,
	@Earning_DetailsPaymentText	nvarchar(max),
	@Earning_iKey								int,
	@BudgetProjectSRC_Guid			D_GUID_NULL = NULL,
	@BudgetProjectDST_Guid			D_GUID_NULL = NULL,
	@CompanyPayer_Guid					D_GUID_NULL = NULL,
	@ChildDepart_Guid						D_GUID_NULL = NULL,
	@AccountPlan_Guid						D_GUID_NULL = NULL,
	@PaymentType_Guid						D_GUID_NULL = NULL,
	@Earning_IsBonus						D_YESNO = 0,

  @ERROR_NUM									int output,
  @ERROR_MES									nvarchar(4000) output

AS

BEGIN

	BEGIN TRY

    SET @ERROR_NUM = 0;
    SET @ERROR_MES = NULL;
    
    DECLARE @EventID D_ID;
    SET @EventID = NULL;
    DECLARE @ParentEventID D_ID;
    SET @ParentEventID = NULL;
    DECLARE @strMessage D_EVENTMSG;
    DECLARE @EventSrc D_NAME;
		DECLARE @Bank_Guid D_GUID;
    SET @EventSrc = 'Платёж';
    
    -- проверка на наличие платежа с указанным идентификатором
		IF NOT EXISTS( SELECT [Earning_Guid] FROM [dbo].[T_Earning] WHERE [Earning_Guid] = @Earning_Guid )
			BEGIN
				SET @ERROR_NUM = 1;
				SET @ERROR_MES = 'В БД уже не найден платёж с указанным идентификатором: ' + CAST( @Earning_Guid AS nvarchar( 36 ) );

				RETURN @ERROR_NUM;
			END
		
		-- определяем УИ счёта    
    DECLARE @Account_Guid D_GUID = NULL;
    SELECT TOP 1 @Account_Guid = Account_Guid, @Bank_Guid = Bank_Guid FROM T_Account 
		WHERE Account_Guid = @Earning_AccountGuid;
    
		IF NOT EXISTS ( SELECT [Account_Guid] FROM [dbo].[T_Account]	WHERE [Account_Guid] = @Earning_AccountGuid )
			BEGIN
				SET @ERROR_NUM = 3;
				SET @ERROR_MES = 'В базе данных не найден счёт с указанным идентификатором: ' + CAST( @Earning_AccountGuid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	
		ELSE 
			SELECT TOP 1 @Account_Guid = Account_Guid, @Bank_Guid = Bank_Guid FROM T_Account 
			WHERE Account_Guid = @Earning_AccountGuid;			

    -- проект-источник
		IF( @BudgetProjectSRC_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [BUDGETPROJECT_GUID] FROM [dbo].[T_BudgetProject] 
				WHERE [BUDGETPROJECT_GUID] = @BudgetProjectSRC_Guid )
			BEGIN
				SET @ERROR_NUM = 4;
				SET @ERROR_MES = 'В базе данных не найден проект-источник с указанным идентификатором: ' + CAST( @BudgetProjectSRC_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- проект-получатель
		IF( @BudgetProjectDST_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [BUDGETPROJECT_GUID] FROM [dbo].[T_BudgetProject] 
				WHERE [BUDGETPROJECT_GUID] = @BudgetProjectDST_Guid )
			BEGIN
				SET @ERROR_NUM = 5;
				SET @ERROR_MES = 'В базе данных не найден проект-получатель с указанным идентификатором: ' + CAST( @BudgetProjectDST_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- компания-плательщик
		IF( @CompanyPayer_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [Company_Guid] FROM [dbo].[T_Company]
				WHERE [Company_Guid] = @CompanyPayer_Guid )
			BEGIN
				SET @ERROR_NUM = 6;
				SET @ERROR_MES = 'В базе данных не найдена компания-плательщик с указанным идентификатором: ' + CAST( @CompanyPayer_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- дочерний клиент
		DECLARE	@CustomerChild_Guid	D_GUID_NULL = NULL;
		IF( @ChildDepart_Guid IS NOT NULL )
			BEGIN
				SELECT @CustomerChild_Guid = [CustomerChild_Guid] FROM [dbo].[T_CustomerChild]
				WHERE ( [ChildDepart_Guid] = @ChildDepart_Guid ) AND ( [Customer_Guid] = @Earning_CustomerGuid );

				IF( @CustomerChild_Guid IS NULL )
				BEGIN
					SET @ERROR_NUM = 7;
					SET @ERROR_MES = 'В базе данных не найден дочерний клиент с указанным идентификатором: ' + CAST( @CustomerChild_Guid as nvarchar(36) );

					RETURN @ERROR_NUM;
				END	
			END

    -- план счетов
		IF( @AccountPlan_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [ACCOUNTPLAN_GUID] FROM [dbo].[T_AccountPlan]
				WHERE [ACCOUNTPLAN_GUID] = @AccountPlan_Guid )
			BEGIN
				SET @ERROR_NUM = 8;
				SET @ERROR_MES = 'В базе данных не найдена запись в плане счетов с указанным идентификатором: ' + CAST( @AccountPlan_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- форма оплаты
		IF( @PaymentType_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [PaymentType_Guid]  FROM [dbo].[T_PaymentType]
				WHERE [PaymentType_Guid] = @PaymentType_Guid )
			BEGIN
				SET @ERROR_NUM = 9;
				SET @ERROR_MES = 'В базе данных не найдена форма оплаты с указанным идентификатором: ' + CAST( @PaymentType_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

     -- клиент
     IF( @Earning_CustomerGuid IS NOT NULL)
       IF NOT EXISTS ( SELECT Customer_Guid FROM dbo.T_Customer WHERE Customer_Guid = @Earning_CustomerGuid )
        BEGIN
         SET @ERROR_NUM = 10;
         SET @ERROR_MES = 'В базе данных не найден клиент с указанным идентификатором: ' + CAST( @Earning_CustomerGuid as nvarchar(36) );

         RETURN @ERROR_NUM;
        END    

     -- валюта
		 IF NOT EXISTS ( SELECT Currency_Guid FROM dbo.T_Currency WHERE Currency_Guid = @Earning_CurrencyGuid )
      BEGIN
        SET @ERROR_NUM = 11;
        SET @ERROR_MES = 'В базе данных не найдена валюта с указанным идентификатором: ' + CAST( @Earning_CurrencyGuid as nvarchar(36) );

        RETURN @ERROR_NUM;
      END    
			
		 -- компания
     IF NOT EXISTS ( SELECT Company_Guid FROM dbo.T_Company WHERE Company_Guid = @Earning_CompanyGuid )
      BEGIN
        SET @ERROR_NUM = 12;
        SET @ERROR_MES = 'В базе данных не найдена компания с указанным идентификатором: ' + CAST( @Earning_CompanyGuid as nvarchar(36) );

        RETURN @ERROR_NUM;
      END       

    BEGIN TRANSACTION UpdateData;

		UPDATE [dbo].[T_Earning] SET Customer_Guid = @Earning_CustomerGuid, Currency_Guid = @Earning_CurrencyGuid,	
			Earning_Date = @Earning_Date, Earning_DocNum = @Earning_DocNum, Bank_Guid= @Bank_Guid, 
			Account_Guid = @Account_Guid, Earning_Value = @Earning_Value, Company_Guid = @Earning_CompanyGuid, 
			Earning_CurrencyRate = @Earning_CurrencyRate, Earning_CurrencyValue = @Earning_CurrencyValue, 
			Earning_CustomerText = @Earning_CustomerText, Earning_DetailsPaymentText = @Earning_DetailsPaymentText, 
			Earning_iKey = @Earning_iKey, BudgetProjectSRC_Guid = @BudgetProjectSRC_Guid, 
			BudgetProjectDST_Guid = @BudgetProjectDST_Guid,	CompanyPayer_Guid = @CompanyPayer_Guid,
			CustomerChild_Guid = @CustomerChild_Guid,	AccountPlan_Guid = @AccountPlan_Guid,	
			PaymentType_Guid = @PaymentType_Guid,	Earning_IsBonus = @Earning_IsBonus
		WHERE Earning_Guid = @Earning_Guid;

    EXEC dbo.usp_EditEarningInIB @Earning_Guid = @Earning_Guid, @IBLINKEDSERVERNAME = NULL, 
			@ERROR_NUM = @ERROR_NUM output, @ERROR_MES = @ERROR_MES output;

		IF( @ERROR_NUM = 0 )
			BEGIN
				SET @strMessage = 'В БД внесены изменения в информацию о платеже. УИ записи: ' + CONVERT( nvarchar(36), @Earning_Guid );
				COMMIT TRANSACTION UpdateData
			END
		ELSE 
			BEGIN
				SET @strMessage = 'Ошибка изменения реквизитов платежа. ' + @ERROR_MES;
				ROLLBACK TRANSACTION UpdateData;
			END


		EXEC dbo.spAddEventToLog @EVENT_SOURCE = @EventSrc, @EVENT_SOURCEID = @Earning_Guid, @EVENT_CATEGORY = 'None', 
				@EVENT_COMPUTER = ' ', @EVENT_TYPE = 'Info', @EVENT_IS_COMPOSITE = 0, 
				@EVENT_DESCRIPTION = @strMessage, @EVENT_PARENTID = @ParentEventID, @EVENT_ID = @EventID output;

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION UpdateData;

    SET @ERROR_NUM = ERROR_NUMBER();
    SET @ERROR_MES = ERROR_MESSAGE();

		RETURN @ERROR_NUM;
	END CATCH;

	IF( @ERROR_NUM = 0 )
		SET @ERROR_MES = 'Успешное завершение операции.';

	RETURN @ERROR_NUM;
END

GO

/****** Object:  StoredProcedure [dbo].[usp_AddEarningToSQLandIB]    Script Date: 11.04.2013 10:58:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Добавляет новую запись в таблицу dbo.T_Earning
--
-- Входящие параметры:
--
--		@Earning_CustomerGuid				- УИ клиента
--		@Earning_CurrencyGuid				- УИ валюты
--		@Earning_Date								- дата платежа
--		@Earning_DocNum							- № документа
--		@Earning_BankCode						- код банка
--		@Earning_Account						- № р/с
--		@Earning_Value							- сумма платежа
--		@Earning_CompanyGuid				- уи компании-получателя платежа
--		@Earning_CurrencyRate				- курс !?
--		@Earning_CurrencyValue			- !?
--		@Earning_CustomerText				-	
--		@Earning_DetailsPaymentText	- 
--		@Earning_iKey								- 
--		@BudgetProjectSRC_Guid			- УИ проекта-источника
--		@BudgetProjectDST_Guid			- УИ проекта-получателя
--		@CompanyPayer_Guid					- УИ компании-плательщика
--		@ChildDepart_Guid						- УИ дочернего клиента
--		@AccountPlan_Guid						- УИ записи в плане счетов
--		@PaymentType_Guid						- УИ формы оплаты
--		@Earning_IsBonus						- признак "бонусный платёж"

-- Выходные параметры:
--
--  @Earning_Guid								- УИ записи
--  @ERROR_NUM										- номер ошибки
--  @ERROR_MES										- текст ошибки
--
-- Результат:
--    0 - Успешное завершение
--    <>0 - ошибка

ALTER PROCEDURE [dbo].[usp_AddEarningToSQLandIB] 
	@Earning_CustomerGuid				D_GUID = NULL,
	@Earning_CurrencyGuid				D_GUID,
	@Earning_Date								D_Date,
	@Earning_DocNum							D_Name,
	@Earning_AccountGuid				D_GUID,
	@Earning_Value							D_Money,
	@Earning_CompanyGuid				D_GUID,
	@Earning_CurrencyRate				D_Money,
	@Earning_CurrencyValue			D_Money,
	@Earning_CustomerText				D_Description,
	@Earning_DetailsPaymentText	nvarchar(max),
	@Earning_iKey								int,
	@BudgetProjectSRC_Guid			D_GUID_NULL = NULL,
	@BudgetProjectDST_Guid			D_GUID_NULL = NULL,
	@CompanyPayer_Guid					D_GUID_NULL = NULL,
	@ChildDepart_Guid						D_GUID_NULL = NULL,
	@AccountPlan_Guid						D_GUID_NULL = NULL,
	@PaymentType_Guid						D_GUID_NULL = NULL,
	@Earning_IsBonus						D_YESNO = 0,

  @Earning_Guid								D_GUID output,
  @ERROR_NUM									int output,
  @ERROR_MES									nvarchar(4000) output

AS

BEGIN

	BEGIN TRY

    SET @ERROR_NUM = 0;
    SET @ERROR_MES = NULL;
    SET @Earning_Guid = NULL;
    
    DECLARE @EventID D_ID;
    SET @EventID = NULL;
    DECLARE @ParentEventID D_ID;
    SET @ParentEventID = NULL;
    DECLARE @strMessage D_EVENTMSG;
    DECLARE @EventSrc D_NAME;
		DECLARE @Bank_Guid D_GUID;

    SET @EventSrc = 'Банковские выписки';
    
		-- определяем УИ счёта    
    DECLARE @Account_Guid D_GUID = NULL;
    SELECT TOP 1 @Account_Guid = Account_Guid, @Bank_Guid = Bank_Guid FROM T_Account 
		WHERE Account_Guid = @Earning_AccountGuid;
    
		IF NOT EXISTS ( SELECT [Account_Guid] FROM [dbo].[T_Account]	WHERE [Account_Guid] = @Earning_AccountGuid )
			BEGIN
				SET @ERROR_NUM = 3;
				SET @ERROR_MES = 'В базе данных не найден счёт с указанным идентификатором: ' + CAST( @Earning_AccountGuid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	
		ELSE 
			SELECT TOP 1 @Account_Guid = Account_Guid, @Bank_Guid = Bank_Guid FROM T_Account 
			WHERE Account_Guid = @Earning_AccountGuid;			

    -- проект-источник
		IF( @BudgetProjectSRC_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [BUDGETPROJECT_GUID] FROM [dbo].[T_BudgetProject] 
				WHERE [BUDGETPROJECT_GUID] = @BudgetProjectSRC_Guid )
			BEGIN
				SET @ERROR_NUM = 4;
				SET @ERROR_MES = 'В базе данных не найден проект-источник с указанным идентификатором: ' + CAST( @BudgetProjectSRC_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- проект-получатель
		IF( @BudgetProjectDST_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [BUDGETPROJECT_GUID] FROM [dbo].[T_BudgetProject] 
				WHERE [BUDGETPROJECT_GUID] = @BudgetProjectDST_Guid )
			BEGIN
				SET @ERROR_NUM = 5;
				SET @ERROR_MES = 'В базе данных не найден проект-получатель с указанным идентификатором: ' + CAST( @BudgetProjectDST_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- компания-плательщик
		IF( @CompanyPayer_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [Company_Guid] FROM [dbo].[T_Company]
				WHERE [Company_Guid] = @CompanyPayer_Guid )
			BEGIN
				SET @ERROR_NUM = 6;
				SET @ERROR_MES = 'В базе данных не найдена компания-плательщик с указанным идентификатором: ' + CAST( @CompanyPayer_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- дочерний клиент
		DECLARE	@CustomerChild_Guid	D_GUID_NULL = NULL;
		IF( @ChildDepart_Guid IS NOT NULL )
			BEGIN
				SELECT @CustomerChild_Guid = [CustomerChild_Guid] FROM [dbo].[T_CustomerChild]
				WHERE ( [ChildDepart_Guid] = @ChildDepart_Guid ) AND ( [Customer_Guid] = @Earning_CustomerGuid );

				IF( @CustomerChild_Guid IS NULL )
				BEGIN
					SET @ERROR_NUM = 7;
					SET @ERROR_MES = 'В базе данных не найден дочерний клиент с указанным идентификатором: ' + CAST( @CustomerChild_Guid as nvarchar(36) );

					RETURN @ERROR_NUM;
				END	
			END

    -- план счетов
		IF( @AccountPlan_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [ACCOUNTPLAN_GUID] FROM [dbo].[T_AccountPlan]
				WHERE [ACCOUNTPLAN_GUID] = @AccountPlan_Guid )
			BEGIN
				SET @ERROR_NUM = 8;
				SET @ERROR_MES = 'В базе данных не найдена запись в плане счетов с указанным идентификатором: ' + CAST( @AccountPlan_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- форма оплаты
		IF( @PaymentType_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [PaymentType_Guid]  FROM [dbo].[T_PaymentType]
				WHERE [PaymentType_Guid] = @PaymentType_Guid )
			BEGIN
				SET @ERROR_NUM = 9;
				SET @ERROR_MES = 'В базе данных не найдена форма оплаты с указанным идентификатором: ' + CAST( @PaymentType_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

     -- клиент
     IF( @Earning_CustomerGuid IS NOT NULL)
       IF NOT EXISTS ( SELECT Customer_Guid FROM dbo.T_Customer WHERE Customer_Guid = @Earning_CustomerGuid )
        BEGIN
         SET @ERROR_NUM = 10;
         SET @ERROR_MES = 'В базе данных не найден клиент с указанным идентификатором: ' + CAST( @Earning_CustomerGuid as nvarchar(36) );

         RETURN @ERROR_NUM;
        END    

     -- валюта
		 IF NOT EXISTS ( SELECT Currency_Guid FROM dbo.T_Currency WHERE Currency_Guid = @Earning_CurrencyGuid )
      BEGIN
        SET @ERROR_NUM = 11;
        SET @ERROR_MES = 'В базе данных не найдена валюта с указанным идентификатором: ' + CAST( @Earning_CurrencyGuid as nvarchar(36) );

        RETURN @ERROR_NUM;
      END    

     IF NOT EXISTS ( SELECT Company_Guid FROM dbo.T_Company WHERE Company_Guid = @Earning_CompanyGuid )
      BEGIN
        SET @ERROR_NUM = 12;
        SET @ERROR_MES = 'В базе данных не найдена компания с указанным идентификатором: ' + CAST( @Earning_CompanyGuid as nvarchar(36) );

        RETURN @ERROR_NUM;
      END       

    DECLARE @NewID D_GUID;
    SET @NewID = NEWID ( );	
                
    DECLARE @Earning_Id D_ID;
    EXEC @Earning_Id = SP_GetGeneratorID @strTableName = 'T_Earning';
       
    
    BEGIN TRANSACTION UpdateData;

		-- в том случае, если указан клиент и расчётный счёт, необходимо проверить, назначен ли этот счёт клиенту
		-- если счёт НЕ назначен, то добавляем счёт в список счетов клиента
		IF( ( @Earning_CustomerGuid IS NOT NULL ) AND ( @Account_Guid IS NOT NULL ) )
			BEGIN
				IF NOT EXISTS( SELECT [CustomerAccount_Guid] FROM [dbo].[T_CustomerAccount]
												WHERE [Customer_Guid] = @Earning_CustomerGuid AND [Account_Guid] = @Account_Guid )
					INSERT INTO [dbo].[T_CustomerAccount]( CustomerAccount_Guid, Customer_Guid, Account_Guid, Record_Updated )
					VALUES( NEWID(), @Earning_CustomerGuid, @Account_Guid, GETUTCDATE() );
			END

    INSERT INTO dbo.T_Earning ( Earning_Guid, Earning_Id, Customer_Guid, Currency_Guid,	Earning_Date, 
			Earning_DocNum, Bank_Guid, Account_Guid, Earning_Value, Earning_Expense, Company_Guid, 
			Earning_CurrencyRate, Earning_CurrencyValue, Earning_CustomerText, Earning_DetailsPaymentText, 
			Earning_iKey, BudgetProjectSRC_Guid, BudgetProjectDST_Guid,	CompanyPayer_Guid,
			CustomerChild_Guid,	AccountPlan_Guid,	PaymentType_Guid,	Earning_IsBonus )
		VALUES( @NewID, @Earning_Id, @Earning_CustomerGuid, @Earning_CurrencyGuid, @Earning_Date, 
			@Earning_DocNum, @Bank_Guid,  @Account_Guid, @Earning_Value, 0, @Earning_CompanyGuid, 
			@Earning_CurrencyRate, @Earning_CurrencyValue, @Earning_CustomerText, @Earning_DetailsPaymentText, 
			@Earning_iKey, @BudgetProjectSRC_Guid, @BudgetProjectDST_Guid,	@CompanyPayer_Guid,
			@CustomerChild_Guid,	@AccountPlan_Guid,	@PaymentType_Guid,	@Earning_IsBonus );
        
		SET @Earning_Guid = @NewID;
	
    EXEC dbo.usp_AddEarningToIB @Earning_Guid = @NewID, @IBLINKEDSERVERNAME = NULL, @Earning_Id = @Earning_Id output,
			@ERROR_NUM = @ERROR_NUM output, @ERROR_MES = @ERROR_MES output;

		IF( @ERROR_NUM = 0 )
			BEGIN
				SET @strMessage = 'В БД добавлена информация о новом платеже. УИ записи: ' + CONVERT( nvarchar(36), @Earning_Guid );
				COMMIT TRANSACTION UpdateData
			END
		ELSE 
			BEGIN
				SET @strMessage = 'Ошибка регистрации платежа. ' + @ERROR_MES;
				ROLLBACK TRANSACTION UpdateData;
			END


		EXEC dbo.spAddEventToLog @EVENT_SOURCE = @EventSrc, @EVENT_SOURCEID = @Earning_Guid, @EVENT_CATEGORY = 'None', 
				@EVENT_COMPUTER = ' ', @EVENT_TYPE = 'Info', @EVENT_IS_COMPOSITE = 0, 
				@EVENT_DESCRIPTION = @strMessage, @EVENT_PARENTID = @ParentEventID, @EVENT_ID = @EventID output;

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION UpdateData;

    SET @ERROR_NUM = ERROR_NUMBER();
    SET @ERROR_MES = ERROR_MESSAGE();

		RETURN @ERROR_NUM;
	END CATCH;

	IF( @ERROR_NUM = 0 )
		SET @ERROR_MES = 'Успешное завершение операции.';

	RETURN @ERROR_NUM;
END

GO

USE [ERP_Mercury]
GO
/****** Object:  StoredProcedure [dbo].[usp_EditEarningInSQLandIB]    Script Date: 11.04.2013 10:58:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Редактирует запись в таблице dbo.T_Earning
--
-- Входящие параметры:
--
--  @Earning_Guid								- УИ записи
--		@Earning_CustomerGuid				- УИ клиента
--		@Earning_CurrencyGuid				- УИ валюты
--		@Earning_Date								- дата платежа
--		@Earning_DocNum							- № документа
--		@Earning_BankCode						- код банка
--		@Earning_Account						- № р/с
--		@Earning_Value							- сумма платежа
--		@Earning_CompanyGuid				- уи компании-получателя платежа
--		@Earning_CurrencyRate				- курс !?
--		@Earning_CurrencyValue			- !?
--		@Earning_CustomerText				-	
--		@Earning_DetailsPaymentText	- 
--		@Earning_iKey								- 
--		@BudgetProjectSRC_Guid			- УИ проекта-источника
--		@BudgetProjectDST_Guid			- УИ проекта-получателя
--		@CompanyPayer_Guid					- УИ компании-плательщика
--		@ChildDepart_Guid						- УИ дочернего клиента
--		@AccountPlan_Guid						- УИ записи в плане счетов
--		@PaymentType_Guid						- УИ формы оплаты
--		@Earning_IsBonus						- признак "бонусный платёж"

-- Выходные параметры:
--
--  @ERROR_NUM										- номер ошибки
--  @ERROR_MES										- текст ошибки
--
-- Результат:
--    0 - Успешное завершение
--    <>0 - ошибка

ALTER PROCEDURE [dbo].[usp_EditEarningInSQLandIB] 
  @Earning_Guid								D_GUID,
	@Earning_CustomerGuid				D_GUID = NULL,
	@Earning_CurrencyGuid				D_GUID,
	@Earning_Date								D_Date,
	@Earning_DocNum							D_Name,
	@Earning_AccountGuid				D_GUID,
	@Earning_Value							D_Money,
	@Earning_CompanyGuid				D_GUID,
	@Earning_CurrencyRate				D_Money,
	@Earning_CurrencyValue			D_Money,
	@Earning_CustomerText				D_Description,
	@Earning_DetailsPaymentText	nvarchar(max),
	@Earning_iKey								int,
	@BudgetProjectSRC_Guid			D_GUID_NULL = NULL,
	@BudgetProjectDST_Guid			D_GUID_NULL = NULL,
	@CompanyPayer_Guid					D_GUID_NULL = NULL,
	@ChildDepart_Guid						D_GUID_NULL = NULL,
	@AccountPlan_Guid						D_GUID_NULL = NULL,
	@PaymentType_Guid						D_GUID_NULL = NULL,
	@Earning_IsBonus						D_YESNO = 0,

  @ERROR_NUM									int output,
  @ERROR_MES									nvarchar(4000) output

AS

BEGIN

	BEGIN TRY

    SET @ERROR_NUM = 0;
    SET @ERROR_MES = NULL;
    
    DECLARE @EventID D_ID;
    SET @EventID = NULL;
    DECLARE @ParentEventID D_ID;
    SET @ParentEventID = NULL;
    DECLARE @strMessage D_EVENTMSG;
    DECLARE @EventSrc D_NAME;
		DECLARE @Bank_Guid D_GUID;
    SET @EventSrc = 'Платёж';
    
    -- проверка на наличие платежа с указанным идентификатором
		IF NOT EXISTS( SELECT [Earning_Guid] FROM [dbo].[T_Earning] WHERE [Earning_Guid] = @Earning_Guid )
			BEGIN
				SET @ERROR_NUM = 1;
				SET @ERROR_MES = 'В БД уже не найден платёж с указанным идентификатором: ' + CAST( @Earning_Guid AS nvarchar( 36 ) );

				RETURN @ERROR_NUM;
			END
		
		-- определяем УИ счёта    
    DECLARE @Account_Guid D_GUID = NULL;
    SELECT TOP 1 @Account_Guid = Account_Guid, @Bank_Guid = Bank_Guid FROM T_Account 
		WHERE Account_Guid = @Earning_AccountGuid;
    
		IF NOT EXISTS ( SELECT [Account_Guid] FROM [dbo].[T_Account]	WHERE [Account_Guid] = @Earning_AccountGuid )
			BEGIN
				SET @ERROR_NUM = 3;
				SET @ERROR_MES = 'В базе данных не найден счёт с указанным идентификатором: ' + CAST( @Earning_AccountGuid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	
		ELSE 
			SELECT TOP 1 @Account_Guid = Account_Guid, @Bank_Guid = Bank_Guid FROM T_Account 
			WHERE Account_Guid = @Earning_AccountGuid;			

    -- проект-источник
		IF( @BudgetProjectSRC_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [BUDGETPROJECT_GUID] FROM [dbo].[T_BudgetProject] 
				WHERE [BUDGETPROJECT_GUID] = @BudgetProjectSRC_Guid )
			BEGIN
				SET @ERROR_NUM = 4;
				SET @ERROR_MES = 'В базе данных не найден проект-источник с указанным идентификатором: ' + CAST( @BudgetProjectSRC_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- проект-получатель
		IF( @BudgetProjectDST_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [BUDGETPROJECT_GUID] FROM [dbo].[T_BudgetProject] 
				WHERE [BUDGETPROJECT_GUID] = @BudgetProjectDST_Guid )
			BEGIN
				SET @ERROR_NUM = 5;
				SET @ERROR_MES = 'В базе данных не найден проект-получатель с указанным идентификатором: ' + CAST( @BudgetProjectDST_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- компания-плательщик
		IF( @CompanyPayer_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [Company_Guid] FROM [dbo].[T_Company]
				WHERE [Company_Guid] = @CompanyPayer_Guid )
			BEGIN
				SET @ERROR_NUM = 6;
				SET @ERROR_MES = 'В базе данных не найдена компания-плательщик с указанным идентификатором: ' + CAST( @CompanyPayer_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- дочерний клиент
		DECLARE	@CustomerChild_Guid	D_GUID_NULL = NULL;
		IF( @ChildDepart_Guid IS NOT NULL )
			BEGIN
				SELECT @CustomerChild_Guid = [CustomerChild_Guid] FROM [dbo].[T_CustomerChild]
				WHERE ( [ChildDepart_Guid] = @ChildDepart_Guid ) AND ( [Customer_Guid] = @Earning_CustomerGuid );

				IF( @CustomerChild_Guid IS NULL )
				BEGIN
					SET @ERROR_NUM = 7;
					SET @ERROR_MES = 'В базе данных не найден дочерний клиент с указанным идентификатором: ' + CAST( @CustomerChild_Guid as nvarchar(36) );

					RETURN @ERROR_NUM;
				END	
			END

    -- план счетов
		IF( @AccountPlan_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [ACCOUNTPLAN_GUID] FROM [dbo].[T_AccountPlan]
				WHERE [ACCOUNTPLAN_GUID] = @AccountPlan_Guid )
			BEGIN
				SET @ERROR_NUM = 8;
				SET @ERROR_MES = 'В базе данных не найдена запись в плане счетов с указанным идентификатором: ' + CAST( @AccountPlan_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- форма оплаты
		IF( @PaymentType_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [PaymentType_Guid]  FROM [dbo].[T_PaymentType]
				WHERE [PaymentType_Guid] = @PaymentType_Guid )
			BEGIN
				SET @ERROR_NUM = 9;
				SET @ERROR_MES = 'В базе данных не найдена форма оплаты с указанным идентификатором: ' + CAST( @PaymentType_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

     -- клиент
     IF( @Earning_CustomerGuid IS NOT NULL)
       IF NOT EXISTS ( SELECT Customer_Guid FROM dbo.T_Customer WHERE Customer_Guid = @Earning_CustomerGuid )
        BEGIN
         SET @ERROR_NUM = 10;
         SET @ERROR_MES = 'В базе данных не найден клиент с указанным идентификатором: ' + CAST( @Earning_CustomerGuid as nvarchar(36) );

         RETURN @ERROR_NUM;
        END    

     -- валюта
		 IF NOT EXISTS ( SELECT Currency_Guid FROM dbo.T_Currency WHERE Currency_Guid = @Earning_CurrencyGuid )
      BEGIN
        SET @ERROR_NUM = 11;
        SET @ERROR_MES = 'В базе данных не найдена валюта с указанным идентификатором: ' + CAST( @Earning_CurrencyGuid as nvarchar(36) );

        RETURN @ERROR_NUM;
      END    
			
		 -- компания
     IF NOT EXISTS ( SELECT Company_Guid FROM dbo.T_Company WHERE Company_Guid = @Earning_CompanyGuid )
      BEGIN
        SET @ERROR_NUM = 12;
        SET @ERROR_MES = 'В базе данных не найдена компания с указанным идентификатором: ' + CAST( @Earning_CompanyGuid as nvarchar(36) );

        RETURN @ERROR_NUM;
      END       

    BEGIN TRANSACTION UpdateData;

		-- в том случае, если указан клиент и расчётный счёт, необходимо проверить, назначен ли этот счёт клиенту
		-- если счёт НЕ назначен, то добавляем счёт в список счетов клиента
		IF( ( @Earning_CustomerGuid IS NOT NULL ) AND ( @Account_Guid IS NOT NULL ) )
			BEGIN
				IF NOT EXISTS( SELECT [CustomerAccount_Guid] FROM [dbo].[T_CustomerAccount]
												WHERE [Customer_Guid] = @Earning_CustomerGuid AND [Account_Guid] = @Account_Guid )
					INSERT INTO [dbo].[T_CustomerAccount]( CustomerAccount_Guid, Customer_Guid, Account_Guid, Record_Updated )
					VALUES( NEWID(), @Earning_CustomerGuid, @Account_Guid, GETUTCDATE() );
			END

		UPDATE [dbo].[T_Earning] SET Customer_Guid = @Earning_CustomerGuid, Currency_Guid = @Earning_CurrencyGuid,	
			Earning_Date = @Earning_Date, Earning_DocNum = @Earning_DocNum, Bank_Guid= @Bank_Guid, 
			Account_Guid = @Account_Guid, Earning_Value = @Earning_Value, Company_Guid = @Earning_CompanyGuid, 
			Earning_CurrencyRate = @Earning_CurrencyRate, Earning_CurrencyValue = @Earning_CurrencyValue, 
			Earning_CustomerText = @Earning_CustomerText, Earning_DetailsPaymentText = @Earning_DetailsPaymentText, 
			Earning_iKey = @Earning_iKey, BudgetProjectSRC_Guid = @BudgetProjectSRC_Guid, 
			BudgetProjectDST_Guid = @BudgetProjectDST_Guid,	CompanyPayer_Guid = @CompanyPayer_Guid,
			CustomerChild_Guid = @CustomerChild_Guid,	AccountPlan_Guid = @AccountPlan_Guid,	
			PaymentType_Guid = @PaymentType_Guid,	Earning_IsBonus = @Earning_IsBonus
		WHERE Earning_Guid = @Earning_Guid;

    EXEC dbo.usp_EditEarningInIB @Earning_Guid = @Earning_Guid, @IBLINKEDSERVERNAME = NULL, 
			@ERROR_NUM = @ERROR_NUM output, @ERROR_MES = @ERROR_MES output;

		IF( @ERROR_NUM = 0 )
			BEGIN
				SET @strMessage = 'В БД внесены изменения в информацию о платеже. УИ записи: ' + CONVERT( nvarchar(36), @Earning_Guid );
				COMMIT TRANSACTION UpdateData
			END
		ELSE 
			BEGIN
				SET @strMessage = 'Ошибка изменения реквизитов платежа. ' + @ERROR_MES;
				ROLLBACK TRANSACTION UpdateData;
			END


		EXEC dbo.spAddEventToLog @EVENT_SOURCE = @EventSrc, @EVENT_SOURCEID = @Earning_Guid, @EVENT_CATEGORY = 'None', 
				@EVENT_COMPUTER = ' ', @EVENT_TYPE = 'Info', @EVENT_IS_COMPOSITE = 0, 
				@EVENT_DESCRIPTION = @strMessage, @EVENT_PARENTID = @ParentEventID, @EVENT_ID = @EventID output;

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION UpdateData;

    SET @ERROR_NUM = ERROR_NUMBER();
    SET @ERROR_MES = ERROR_MESSAGE();

		RETURN @ERROR_NUM;
	END CATCH;

	IF( @ERROR_NUM = 0 )
		SET @ERROR_MES = 'Успешное завершение операции.';

	RETURN @ERROR_NUM;
END

GO

/****** Object:  View [dbo].[AccountView]    Script Date: 12.04.2013 12:04:32 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER VIEW [dbo].[AccountView]
AS
SELECT     Account.Account_Guid, Account.Account_Number, Account.Bank_Guid, Account.Currency_Giud, Account.Account_Ddescription, Currency.Currency_Abbr, 
                      Currency.Currency_Code, Bank.Bank_Code, Bank.Bank_IsActive, Bank.Bank_MFO, Bank.Bank_Name, Bank.Bank_ParentGuid, Bank.Bank_UNN, 
                      Account.AccountType_Guid, AcoountType.AccountType_Name, AcoountType.AccountType_IsActive, CAST(0 AS bit) AS CompanyAccount_IsMain
FROM         dbo.T_Account AS Account INNER JOIN
                      dbo.T_Bank AS Bank ON Account.Bank_Guid = Bank.Bank_Guid INNER JOIN
                      dbo.T_Currency AS Currency ON Account.Currency_Giud = Currency.Currency_Guid LEFT OUTER JOIN
                      dbo.T_AccountType AS AcoountType ON Account.AccountType_Guid = AcoountType.AccountType_Guid

GO


