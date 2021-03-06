USE [ERP_Mercury]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- Возвращает список записей из ( dbo.T_Earning ) для платежей по форме №2
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

CREATE PROCEDURE [dbo].[usp_GetCEarningList] 
  @Earning_DateBegin		D_DATE,
  @Earning_DateEnd			D_DATE,
  @Earning_guidCompany	D_GUID = NULL,
	
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
		WHERE	[Earning_Date] BETWEEN @Earning_DateBegin AND @Earning_DateEnd
			AND (  ( PaymentType_Id IS NOT NULL ) AND ( PaymentType_Id = 2 ) )
	ORDER BY [Earning_Date];
	
  
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
GRANT EXECUTE ON [dbo].[usp_GetCEarningList] TO [public]
GO


/****** Object:  StoredProcedure [dbo].[sp_GetCustomerList]    Script Date: 17.04.2013 16:23:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- Возвращает список записей из ( dbo.T_CUSTOMER )
--
-- Входящие параметры:
--		@ChildDepart_Guid - уи дочернего клиента
--
-- Выходные параметры:
--
-- Результат:
--    0 - успешное завершение
--    <>0 - ошибка запроса информации из базы данных

ALTER PROCEDURE [dbo].[sp_GetCustomerList] 
	@ChildDepart_Guid			D_GUID = NULL,
  @ERROR_NUM						int output,
  @ERROR_MES						nvarchar(4000) output
AS

BEGIN

  SET @ERROR_NUM = 0;
  SET @ERROR_MES = '';

  BEGIN TRY

		IF( @ChildDepart_Guid IS NULL )
			SELECT Customer.Customer_Guid, Customer.CUSTOMER_ID, Customer.Customer_Code, Customer.CUSTOMER_NAME,
				Customer.Customer_UNP, Customer.Customer_OKPO, Customer.Customer_OKULP, 
				Customer.CustomerStateType_Guid, CustomerStateType.CustomerStateType_Name, CustomerStateType.CustomerStateType_ShortName, CustomerStateType.CustomerStateType_IsActive,
				Customer.CustomerActiveType_Guid, CustomerActiveType.CustomerActiveType_Name, 
				dbo.GetChildDepartCodeForCustomer( Customer.Customer_Guid ) AS ChildDepart_Code
			FROM dbo.T_CUSTOMER as Customer, dbo.T_CustomerActiveType as CustomerActiveType, dbo.T_CustomerStateType as CustomerStateType
			WHERE  Customer.CustomerStateType_Guid = CustomerStateType.CustomerStateType_Guid
				AND Customer.CustomerActiveType_Guid = CustomerActiveType.CustomerActiveType_Guid
			ORDER BY 	Customer.Customer_Name;
		ELSE
			SELECT Customer.Customer_Guid, Customer.CUSTOMER_ID, Customer.Customer_Code, Customer.CUSTOMER_NAME,
				Customer.Customer_UNP, Customer.Customer_OKPO, Customer.Customer_OKULP, 
				Customer.CustomerStateType_Guid, CustomerStateType.CustomerStateType_Name, CustomerStateType.CustomerStateType_ShortName, CustomerStateType.CustomerStateType_IsActive,
				Customer.CustomerActiveType_Guid, CustomerActiveType.CustomerActiveType_Name, 
				cast( '' as nvarchar(56) ) AS ChildDepart_Code
			FROM dbo.T_CUSTOMER as Customer, dbo.T_CustomerActiveType as CustomerActiveType, 
				dbo.T_CustomerStateType as CustomerStateType, [dbo].[T_CustomerChild] as CustomerChild
			WHERE Customer.CustomerStateType_Guid = CustomerStateType.CustomerStateType_Guid
				AND Customer.CustomerActiveType_Guid = CustomerActiveType.CustomerActiveType_Guid
				AND Customer.Customer_Guid = CustomerChild.Customer_Guid
				AND CustomerChild.ChildDepart_Guid = @ChildDepart_Guid
			ORDER BY 	Customer.Customer_Name;

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


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- Возвращает курс пересчёта
--
-- Входящие параметры:
--		@CurrencyIn		- уи валюты (из какой)
--		@CurrencyOut	- уи валюты (в какую)
--		@BEGINDATE		- на дату
--
-- Выходные параметры:
--		@Rate_Value		- курс пересчёта
--		@ERROR_NUM		- номер ошибки
--		@ERROR_MES		- сообщение об ошибке
--
-- Результат:
--    0 - успешное завершение
--    <>0 - ошибка запроса информации из базы данных

CREATE PROCEDURE [dbo].[usp_GetCurrencyRate] 
	@CurrencyIn		D_GUID, 
	@CurrencyOut	D_GUID,  
	@BEGINDATE		D_DATE,

  @Rate_Value		money output,
  @ERROR_NUM		int output,
  @ERROR_MES		nvarchar(4000) output
AS

BEGIN

  SET @ERROR_NUM = 0;
  SET @ERROR_MES = '';
	SET @Rate_Value = 0;

  BEGIN TRY

	  SET @Rate_Value = ( SELECT [dbo].[GetCurrencyRateInOut]( @CurrencyIn, @CurrencyOut, @BEGINDATE ) );

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
GRANT EXECUTE ON [dbo].[usp_GetCurrencyRate] TO [public]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Добавляет в InterBase информацию о новом платеже по ф2

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

CREATE PROCEDURE [dbo].[usp_AddCEarningToIB]
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
    DECLARE @Account_Guid						D_GUID_NULL;
    DECLARE @Bank_Guid							D_GUID_NULL;
		DECLARE @Customer_Guid					D_GUID;
		DECLARE @CustomerChild_Guid			D_GUID_NULL;
		DECLARE @CustomerChild_Id				int;
    DECLARE @CEarning_Mode					int;
    DECLARE @CEARNING_COMISPERCENT	float;
  
    SELECT @Customer_Guid = Customer_Guid, @Earning_CustomerId = [Customer_Id], @Earning_CurrencyCode =  [Currency_Abbr], 
			@Earning_Date = [Earning_Date], @Earning_DocNum = [Earning_DocNum], 
			@Account_Guid = [Account_Guid], @Bank_Guid = [Bank_Guid], @Earning_Value = [Earning_Value],
			@Earning_Expense = [Earning_Expense], @Earning_Saldo = [Earning_Saldo],
			@Earning_CompanyId = [Company_Id], @Earning_CurrencyRate = [Earning_CurrencyRate],
			@Earning_CurrencyValue = [Earning_CurrencyValue], @Earning_iKey = [Earning_iKey], 
			@Earning_BankAccount = [AccountViewAccount_Number], @Earning_BankCode = [Bank_Code], @CustomerChild_Id = [CustomerChild_Id]
		FROM [dbo].[EarningView] WHERE Earning_Guid = @Earning_Guid;
      
		IF( @Earning_CustomerId IS NULL )
    BEGIN
      SET @ERROR_NUM = 1;
      SET @ERROR_MES = 'В базе данных не найден клиент для указанного платежа. УИ платежа: ' + CAST( @Earning_Guid as nvarchar(36) );

      RETURN @ERROR_NUM;
    END    

		IF( @CustomerChild_Id IS NULL )
    BEGIN
      SET @ERROR_NUM = 2;
      SET @ERROR_MES = 'В базе данных не найден дочерний клиент для указанного платежа. УИ платежа: ' + CAST( @Earning_Guid as nvarchar(36) );

      RETURN @ERROR_NUM;
    END    

    SET @Earning_UsdValue = 0;	
    SET @Earning_Code = 0;
		SET @CEarning_Mode = 0;
		SET @CEARNING_COMISPERCENT = 0;
		DECLARE @strCompany_Id varchar( 24 );
		SET @strCompany_Id = 'NULL';
				   
    DECLARE @SQLString nvarchar( 2048 );
    DECLARE @ParmDefinition nvarchar( 500 );
    DECLARE @RETURNVALUE int;


		DECLARE @NewEarningId int;
		SET @NewEarningId = NULL;
    SET @ParmDefinition = N'@EarningId_Ib int output, @ErrorNum_Ib int output, @ErrorText_Ib varchar(480) output'; 				
					
		SET @SQLString = 'SELECT @EarningId_Ib=CEARNING_ID, @ErrorNum_Ib = ERROR_NUMBER, @ErrorText_Ib = ERROR_TEXT FROM OPENQUERY( ' + 
			@IBLINKEDSERVERNAME + ', ''SELECT CEARNING_ID, ERROR_NUMBER, ERROR_TEXT FROM SP_ADD_CEARNING_FROMSQL( ' +
					cast( @Earning_Code as nvarchar(10)) +  ', ' +
					cast( @CustomerChild_Id as nvarchar(10)) +  ', ' +
					cast( @Earning_CustomerId as nvarchar(10)) +  ', ' +
					'''''' + cast( @Earning_CurrencyCode as nvarchar(4)) + '''''' + ', ' +
					'''''' + CONVERT (varchar(10), @Earning_Date, 104 ) + '''''' + ', ' +
					cast( @Earning_Value as nvarchar(25) ) +  ', ' +
					cast( @Earning_Expense as nvarchar(25)) +  ', ' +
					cast( @Earning_UsdValue as nvarchar( 10 )) +  ', ' +
					cast( @CEarning_Mode as nvarchar( 10 )) +  ', ' +
					cast( @Earning_CurrencyRate as nvarchar(15)) + ', ' +
					cast( @Earning_CurrencyValue as nvarchar(25)) +  ', ' +
					cast( @CEARNING_COMISPERCENT as nvarchar(8)) +  ', ' + 
					@strCompany_Id + ' )'' )'; 

			DELETE FROM [dbo].[T_Log];
			INSERT INTO [dbo].[T_Log]( [LOG_TEXT] ) VALUES( @SQLString );

    EXECUTE sp_executesql @SQLString, @ParmDefinition, @EarningId_Ib = @NewEarningId output, 
			@ErrorNum_Ib = @ERROR_NUM output, @ErrorText_Ib = @ERROR_MES output;  
		SELECT @NewEarningId;
		
		IF( @ERROR_NUM = 0 )
			BEGIN
				UPDATE dbo.T_Earning	SET Earning_Id = @NewEarningId
				WHERE Earning_Guid = @Earning_Guid;
			
				UPDATE dbo.TS_GENERATOR SET GENERATOR_ID = @NewEarningId 
				WHERE TABLE_NAME = 'T_CEarning';
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
GRANT EXECUTE ON [dbo].[usp_AddCEarningToIB] TO [public]
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Добавляет новую запись в таблицу dbo.T_Earning по форме оплаты 2
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

CREATE PROCEDURE [dbo].[usp_AddCEarningToSQLandIB] 
	@Earning_CustomerGuid				D_GUID,
	@Earning_CurrencyGuid				D_GUID,
	@Earning_Date								D_Date,
	@Earning_DocNum							D_Name,
	@Earning_AccountGuid				D_GUID_NULL = NULL,
	@Earning_Value							D_Money,
	@Earning_CompanyGuid				D_GUID_NULL = NULL,
	@Earning_CurrencyRate				D_Money,
	@Earning_CurrencyValue			D_Money,
	@Earning_CustomerText				D_Description = NULL,
	@Earning_DetailsPaymentText	nvarchar(max) = NULL,
	@Earning_iKey								int,
	@BudgetProjectSRC_Guid			D_GUID_NULL = NULL,
	@BudgetProjectDST_Guid			D_GUID_NULL = NULL,
	@CompanyPayer_Guid					D_GUID_NULL = NULL,
	@ChildDepart_Guid						D_GUID_NULL,
	@AccountPlan_Guid						D_GUID_NULL = NULL,
	@PaymentType_Guid						D_GUID_NULL,
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

    SET @EventSrc = 'Платёж ф2';
    
		-- определяем УИ счёта    
    DECLARE @Account_Guid D_GUID = NULL;
		DECLARE @Bank_Guid D_GUID = NULL;

    IF( @Earning_AccountGuid IS NOT NULL )
			SELECT TOP 1 @Account_Guid = Account_Guid, @Bank_Guid = Bank_Guid FROM T_Account 
			WHERE Account_Guid = @Earning_AccountGuid;
    ELSE
			SELECT TOP 1 @Account_Guid = Account_Guid, @Bank_Guid = Bank_Guid FROM T_Account; 

		IF NOT EXISTS ( SELECT [Account_Guid] FROM [dbo].[T_Account]	WHERE [Account_Guid] = @Account_Guid )
			BEGIN
				SET @ERROR_NUM = 3;
				SET @ERROR_MES = 'В базе данных не найден счёт с указанным идентификатором: ' + CAST( @Earning_AccountGuid as nvarchar(36) );

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
		SELECT @CustomerChild_Guid = [CustomerChild_Guid] FROM [dbo].[T_CustomerChild]
		WHERE ( [ChildDepart_Guid] = @ChildDepart_Guid ) AND ( [Customer_Guid] = @Earning_CustomerGuid );

		IF( @CustomerChild_Guid IS NULL )
		BEGIN
			SET @ERROR_NUM = 7;
			SET @ERROR_MES = 'В базе данных не найден дочерний клиент с указанным идентификатором: ' + CAST( @CustomerChild_Guid as nvarchar(36) );

			RETURN @ERROR_NUM;
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
		
		-- компания-получатель
    IF( @Earning_CompanyGuid IS NOT NULL  )
			IF NOT EXISTS ( SELECT Company_Guid FROM dbo.T_Company WHERE Company_Guid = @Earning_CompanyGuid )
				BEGIN
					SET @ERROR_NUM = 12;
					SET @ERROR_MES = 'В базе данных не найдена компания с указанным идентификатором: ' + CAST( @Earning_CompanyGuid as nvarchar(36) );

					RETURN @ERROR_NUM;
				END       

    DECLARE @NewID D_GUID;
    SET @NewID = NEWID ( );	
                
    DECLARE @Earning_Id D_ID;
    EXEC @Earning_Id = SP_GetGeneratorID @strTableName = 'T_CEarning';
       
    
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
	
    EXEC dbo.usp_AddCEarningToIB @Earning_Guid = @NewID, @IBLINKEDSERVERNAME = NULL, @Earning_Id = @Earning_Id output,
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
GRANT EXECUTE ON [dbo].[usp_AddCEarningToSQLandIB] TO [public]
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Редактирует в InterBase информацию о платеже ф2

-- Входные параметры
-- 
-- @Earning_Guid - УИ платежа
-- @IBLINKEDSERVERNAME		- имя LINKEDSERVER для подключения к InterBase
--
-- Выходные параметры
--
-- @ERROR_NUM						- номер ошибки
-- @ERROR_MES						- сообщение об ошибке

CREATE PROCEDURE [dbo].[usp_EditCEarningInIB]
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
    DECLARE @Account_Guid						D_GUID_NULL;
    DECLARE @Bank_Guid							D_GUID_NULL;
		DECLARE @Customer_Guid					D_GUID;
		DECLARE @CustomerChild_Guid			D_GUID;
		DECLARE @CustomerChild_Id				int;
    DECLARE @CEarning_Mode					int;
    DECLARE @CEARNING_COMISPERCENT	float;
  
    SELECT @Earning_Id = Earning_Id, @Customer_Guid = Customer_Guid, @Earning_CustomerId = [Customer_Id], @Earning_CurrencyCode =  [Currency_Abbr], 
			@Earning_Date = [Earning_Date], @Earning_DocNum = [Earning_DocNum], 
			@Account_Guid = [Account_Guid], @Bank_Guid = [Bank_Guid], @Earning_Value = [Earning_Value],
			@Earning_Expense = [Earning_Expense], @Earning_Saldo = [Earning_Saldo],
			@Earning_CompanyId = [Company_Id], @Earning_CurrencyRate = [Earning_CurrencyRate],
			@Earning_CurrencyValue = [Earning_CurrencyValue], @Earning_iKey = [Earning_iKey], 
			@Earning_BankAccount = [AccountViewAccount_Number], @Earning_BankCode = [Bank_Code], @CustomerChild_Id = [CustomerChild_Id]
		FROM [dbo].[EarningView] WHERE Earning_Guid = @Earning_Guid;
      
		IF( @Earning_CustomerId IS NULL )
    BEGIN
      SET @ERROR_NUM = 1;
      SET @ERROR_MES = 'В базе данных не найден клиент для указанного платежа. УИ платежа: ' + CAST( @Earning_Guid as nvarchar(36) );

      RETURN @ERROR_NUM;
    END    

		IF( @CustomerChild_Id IS NULL )
    BEGIN
      SET @ERROR_NUM = 2;
      SET @ERROR_MES = 'В базе данных не найден дочерний клиент для указанного платежа. УИ платежа: ' + CAST( @Earning_Guid as nvarchar(36) );

      RETURN @ERROR_NUM;
    END    

    SET @Earning_UsdValue = 0;	
    SET @Earning_Code = 0;
		SET @CEarning_Mode = 0;
		SET @CEARNING_COMISPERCENT = 0;
		DECLARE @strCompany_Id varchar( 24 );
		SET @strCompany_Id = 'NULL';
				   
    DECLARE @SQLString nvarchar( 2048 );
    DECLARE @ParmDefinition nvarchar( 500 );
    DECLARE @RETURNVALUE int;

    SET @ParmDefinition = N'@ErrorNum_Ib int output, @ErrorText_Ib varchar(480) output'; 				
					
		SET @SQLString = 'SELECT  @ErrorNum_Ib = ERROR_NUMBER, @ErrorText_Ib = ERROR_TEXT FROM OPENQUERY( ' + 
			@IBLINKEDSERVERNAME + ', ''SELECT ERROR_NUMBER, ERROR_TEXT FROM SP_EDIT_CEARNING_FROMSQL( ' + cast( @Earning_Id as nvarchar( 20)) + ', ' + +
					cast( @Earning_Code as nvarchar(10)) +  ', ' +
					cast( @CustomerChild_Id as nvarchar(10)) +  ', ' +
					cast( @Earning_CustomerId as nvarchar(10)) +  ', ' +
					'''''' + cast( @Earning_CurrencyCode as nvarchar(4)) + '''''' + ', ' +
					'''''' + CONVERT (varchar(10), @Earning_Date, 104 ) + '''''' + ', ' +
					cast( @Earning_Value as nvarchar(25) ) +  ', ' +
					cast( @Earning_Expense as nvarchar(25)) +  ', ' +
					cast( @Earning_UsdValue as nvarchar( 10 )) +  ', ' +
					cast( @CEarning_Mode as nvarchar( 10 )) +  ', ' +
					cast( @Earning_CurrencyRate as nvarchar(15)) + ', ' +
					cast( @Earning_CurrencyValue as nvarchar(25)) +  ', ' +
					cast( @CEARNING_COMISPERCENT as nvarchar(8)) +  ', ' + 
					@strCompany_Id + ' )'' )'; 
					
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
GRANT EXECUTE ON [dbo].[usp_EditCEarningInIB] TO [public]
GO

/****** Object:  StoredProcedure [dbo].[usp_EditEarningInSQLandIB]    Script Date: 18.04.2013 15:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Редактирует запись в таблице dbo.T_Earning платёж ф2
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

CREATE PROCEDURE [dbo].[usp_EditCEarningInSQLandIB] 
  @Earning_Guid								D_GUID,
	@Earning_CustomerGuid				D_GUID,
	@Earning_CurrencyGuid				D_GUID,
	@Earning_Date								D_Date,
	@Earning_DocNum							D_Name,
	@Earning_AccountGuid				D_GUID_NULL = NULL,
	@Earning_Value							D_Money,
	@Earning_CompanyGuid				D_GUID_NULL = NULL,
	@Earning_CurrencyRate				D_Money,
	@Earning_CurrencyValue			D_Money,
	@Earning_CustomerText				D_Description = NULL,
	@Earning_DetailsPaymentText	nvarchar(max) = NULL,
	@Earning_iKey								int,
	@BudgetProjectSRC_Guid			D_GUID_NULL = NULL,
	@BudgetProjectDST_Guid			D_GUID_NULL = NULL,
	@CompanyPayer_Guid					D_GUID_NULL = NULL,
	@ChildDepart_Guid						D_GUID_NULL,
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
    SET @EventSrc = 'Платёж ф2';
    
    -- проверка на наличие платежа с указанным идентификатором
		IF NOT EXISTS( SELECT [Earning_Guid] FROM [dbo].[T_Earning] WHERE [Earning_Guid] = @Earning_Guid )
			BEGIN
				SET @ERROR_NUM = 1;
				SET @ERROR_MES = 'В БД уже не найден платёж с указанным идентификатором: ' + CAST( @Earning_Guid AS nvarchar( 36 ) );

				RETURN @ERROR_NUM;
			END
		
		-- определяем УИ счёта    
    DECLARE @Account_Guid D_GUID = NULL;
		DECLARE @Bank_Guid D_GUID = NULL;

    IF( @Earning_AccountGuid IS NOT NULL )
			SELECT TOP 1 @Account_Guid = Account_Guid, @Bank_Guid = Bank_Guid FROM T_Account 
			WHERE Account_Guid = @Earning_AccountGuid;
    ELSE
			SELECT TOP 1 @Account_Guid = Account_Guid, @Bank_Guid = Bank_Guid FROM T_Account; 

		IF NOT EXISTS ( SELECT [Account_Guid] FROM [dbo].[T_Account]	WHERE [Account_Guid] = @Account_Guid )
			BEGIN
				SET @ERROR_NUM = 3;
				SET @ERROR_MES = 'В базе данных не найден счёт с указанным идентификатором: ' + CAST( @Earning_AccountGuid as nvarchar(36) );

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
		SELECT @CustomerChild_Guid = [CustomerChild_Guid] FROM [dbo].[T_CustomerChild]
		WHERE ( [ChildDepart_Guid] = @ChildDepart_Guid ) AND ( [Customer_Guid] = @Earning_CustomerGuid );

		IF( @CustomerChild_Guid IS NULL )
		BEGIN
			SET @ERROR_NUM = 7;
			SET @ERROR_MES = 'В базе данных не найден дочерний клиент с указанным идентификатором: ' + CAST( @CustomerChild_Guid as nvarchar(36) );

			RETURN @ERROR_NUM;
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
		 IF( @Earning_CompanyGuid IS NOT NULL ) 
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

    EXEC dbo.usp_EditCEarningInIB @Earning_Guid = @Earning_Guid, @IBLINKEDSERVERNAME = NULL, 
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
GRANT EXECUTE ON [dbo].[usp_EditCEarningInSQLandIB] TO [public]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Удаляет в InterBase информацию о платеже ф2

-- Входные параметры
-- @Earning_Guid					- УИ платежа
-- @IBLINKEDSERVERNAME		- имя LINKEDSERVER

-- Выходные параметры
-- @ERROR_NUM						- номер ошибки
-- @ERROR_MES						- сообщение об ошибке

CREATE PROCEDURE [dbo].[usp_DeleteCEarningFromIB]
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
        SET @ERROR_MES = '[usp_DeleteCEarningFromIB] Не найден платёж с указанным идентификатором: ' +  CONVERT( nvarchar(36), @Earning_Guid );
        RETURN @ERROR_NUM;
      END
      
		SELECT @Earning_Id = Earning_Id
		FROM dbo.T_Earning WHERE Earning_Guid = @Earning_Guid;
		
    DECLARE @SQLString nvarchar( 2048 );
    DECLARE @ParmDefinition nvarchar( 500 );
    DECLARE @RETURNVALUE int;


    SET @ParmDefinition = N'@ErrorNum_Ib int output, @ErrorText_Ib varchar(480) output'; 

    
    SET @SQLString = 'SELECT @ErrorNum_Ib = ERROR_NUMBER, @ErrorText_Ib = ERROR_TEXT FROM OPENQUERY( ' + 
			@IBLINKEDSERVERNAME + ', ''SELECT ERROR_NUMBER, ERROR_TEXT FROM  SP_DELETE_CEARNING_FROMSQL  ( ' +
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
GRANT EXECUTE ON [dbo].[usp_DeleteCEarningFromIB] TO [public]
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Удаление элемента из таблицы dbo.T_Earning платёж ф2
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

CREATE PROCEDURE [dbo].[usp_DeleteCEarning] 
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
	
		EXEC dbo.usp_DeleteCEarningFromIB @Earning_Guid = @Earning_Guid, @IBLINKEDSERVERNAME = NULL, 
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
GRANT EXECUTE ON [dbo].[usp_DeleteCEarning] TO [public]
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Возвращает курс валюты @CurrencyIn к валюте @CurrencyOut на указанную дату

CREATE FUNCTION [dbo].[GetCurrencyRatePricingInOut] ( @CurrencyIn D_GUID, @CurrencyOut D_GUID,  @BEGINDATE D_DATE )
returns money
with execute as caller
as
begin
  DECLARE @ReturnValue money;
  SET @ReturnValue = NULL;
  
	DECLARE @CURRENCYRATE money;
	SET @CURRENCYRATE = 0;
  
  IF( @CurrencyIn = @CurrencyOut )
		BEGIN
			SET @CURRENCYRATE = 1;
		END
  ELSE
		BEGIN
			IF( ( @CurrencyIn IS NOT NULL ) AND ( @CurrencyOut IS NOT NULL ) )
				BEGIN
					-- Находим дату курса, ближайшую к @END_DATE
					DECLARE @CURRENCYRATE_DATE D_DATE;
					SELECT @CURRENCYRATE_DATE = MAX( CurrencyRate_Date ) FROM dbo.T_CurrencyRate
					WHERE 
								( Currency_In_Guid = @CurrencyIn ) 
						AND ( Currency_Out_Guid = @CurrencyOut )
						AND ( CurrencyRate_Date <= @BEGINDATE )
						AND [CurrencyRate_Pricing] = 1;

					-- Если дата найдена, запрашиваем курс
					IF( @CURRENCYRATE_DATE IS NOT NULL )
						BEGIN
							SELECT @CURRENCYRATE = CurrencyRate_Value FROM dbo.T_CurrencyRate
							WHERE 
										( Currency_In_Guid = @CurrencyIn ) 
								AND ( Currency_Out_Guid = @CurrencyOut )
								AND ( CurrencyRate_Date = @CURRENCYRATE_DATE )
								AND [CurrencyRate_Pricing] = 1;
						END
					ELSE
						BEGIN --
							-- Попробуем найти обратный курс
							-- Находим дату курса, ближайшую к @END_DATE
							SELECT @CURRENCYRATE_DATE = MAX( CurrencyRate_Date ) FROM dbo.T_CurrencyRate
							WHERE 
										( Currency_In_Guid = @CurrencyOut ) 
								AND ( Currency_Out_Guid = @CurrencyIn )
								AND ( CurrencyRate_Date <= @BEGINDATE )
								AND [CurrencyRate_Pricing] = 1;

							-- Если дата найдена, запрашиваем курс
							IF( @CURRENCYRATE_DATE IS NOT NULL )
								BEGIN
									SELECT @CURRENCYRATE = CurrencyRate_Value FROM dbo.T_CurrencyRate
									WHERE 
											( Currency_In_Guid = @CurrencyOut ) 
										AND ( Currency_Out_Guid = @CurrencyIn )
										AND ( CurrencyRate_Date = @CURRENCYRATE_DATE )
										AND [CurrencyRate_Pricing] = 1;

									IF( ( @CURRENCYRATE IS NOT NULL ) AND ( @CURRENCYRATE <> 0 ) )
										BEGIN
											SET @CURRENCYRATE = cast( ( 1/@CURRENCYRATE ) as money );
										END
								END
						END --
				END
		END

	SET @ReturnValue = @CURRENCYRATE;
  RETURN @ReturnValue;

end

GO
GRANT EXECUTE ON [dbo].[GetCurrencyRatePricingInOut] TO [public]
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- Возвращает курс пересчёта (для ценообразования)
--
-- Входящие параметры:
--		@CurrencyIn		- уи валюты (из какой)
--		@CurrencyOut	- уи валюты (в какую)
--		@BEGINDATE		- на дату
--
-- Выходные параметры:
--		@Rate_Value		- курс пересчёта
--		@ERROR_NUM		- номер ошибки
--		@ERROR_MES		- сообщение об ошибке
--
-- Результат:
--    0 - успешное завершение
--    <>0 - ошибка запроса информации из базы данных

CREATE PROCEDURE [dbo].[usp_GetCurrencyRatePricing] 
	@CurrencyIn		D_GUID, 
	@CurrencyOut	D_GUID,  
	@BEGINDATE		D_DATE,

  @Rate_Value		money output,
  @ERROR_NUM		int output,
  @ERROR_MES		nvarchar(4000) output
AS

BEGIN

  SET @ERROR_NUM = 0;
  SET @ERROR_MES = '';
	SET @Rate_Value = 0;

  BEGIN TRY

	  SET @Rate_Value = ( SELECT [dbo].[GetCurrencyRatePricingInOut]( @CurrencyIn, @CurrencyOut, @BEGINDATE ) );

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
GRANT EXECUTE ON [dbo].[usp_GetCurrencyRatePricing] TO [public]
GO

/****** Object:  StoredProcedure [dbo].[usp_AddEarning]    Script Date: 18.04.2013 18:05:54 ******/
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

		DECLARE @CurrencyMainGuid D_GUID; 

		SELECT TOP 1 @CurrencyMainGuid = [Currency_Guid] FROM [dbo].[T_Currency]
		WHERE [Currency_IsMain] = 1;

		SELECT @Earning_CurrencyRate = [dbo].[GetCurrencyRatePricingInOut]( @CurrencyMainGuid, @Earning_CurrencyGuid, @Earning_Date );
                
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

