USE [ERP_Mercury]
GO

/****** Object:  StoredProcedure [dbo].[usp_DeleteEarning2FromIB]    Script Date: 17.01.2014 15:51:43 ******/
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

ALTER PROCEDURE [dbo].[usp_DeleteEarning2FromIB]
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
		
		IF( @Earning_Id = 0 )
			BEGIN
				SET @ERROR_NUM = 0;
				SET @ERROR_MES = 'Оплата не зарегистрирована в "Контракте"';

				RETURN @ERROR_NUM;
			END  

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

/****** Object:  StoredProcedure [dbo].[usp_DeleteEarning2]    Script Date: 17.01.2014 15:56:11 ******/
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

ALTER PROCEDURE [dbo].[usp_DeleteEarning2] 
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

/****** Object:  StoredProcedure [dbo].[usp_AddEarningToSQLandIB]    Script Date: 17.01.2014 10:57:06 ******/
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
--		@EarningType_Guid						- УИ вида оплаты
--
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
	@EarningType_Guid						D_GUID_NULL = NULL,

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

    -- вид оплаты
		IF( @EarningType_Guid IS NOT NULL )
			BEGIN
				IF NOT EXISTS ( SELECT [EarningType_Guid]  FROM [dbo].[T_EarningType]	WHERE [EarningType_Guid] = @EarningType_Guid )
					BEGIN
						SET @ERROR_NUM = 13;
						SET @ERROR_MES = 'В базе данных не найден вид оплаты с указанным идентификатором: ' + CAST( @EarningType_Guid as nvarchar(36) );
						RETURN @ERROR_NUM;
					END
			END	
		ELSE
			SELECT TOP 1 @EarningType_Guid = [EarningType_Guid] FROM [dbo].[T_EarningType] WHERE [EarningType_IsDefault] = 1;

		-- проверка на заполнение реквизитов транзитной проводки
		IF( ( @CompanyPayer_Guid IS NOT NULL ) OR ( @BudgetProjectSRC_Guid IS NOT NULL ) )
			BEGIN
				-- указан проект-источник либо компания-плательщик
				IF( ( ( @CompanyPayer_Guid IS NOT NULL ) AND ( @BudgetProjectSRC_Guid IS NULL ) ) OR
						( ( @CompanyPayer_Guid IS NULL ) AND ( @BudgetProjectSRC_Guid IS NOT NULL ) ) )
					BEGIN
						SET @ERROR_NUM = 14;
						SET @ERROR_MES = 'В том случае, если указана либо компания-плательщик, либо проект-источник, необходимо указать оба реквизита.';
						RETURN @ERROR_NUM;
					END
				ELSE IF ( ( @CompanyPayer_Guid IS NOT NULL ) AND ( @BudgetProjectSRC_Guid IS NOT NULL ) )
					BEGIN
						-- указаны оба реквизита, вид оплаты должен быть "транзитная проводка"
						IF( @EarningType_Guid IS NULL )
							BEGIN
								SET @ERROR_NUM = 14;
								SET @ERROR_MES = 'Укажите, пожалуйста, вид оплаты "транзитная проводка".';
								RETURN @ERROR_NUM;
							END
						ELSE
							BEGIN
								IF NOT EXISTS( SELECT [EarningType_Guid] FROM [dbo].[T_EarningType] WHERE [EarningType_Guid] = @EarningType_Guid AND EarningType_Id = 1 )
									BEGIN
										SET @ERROR_NUM = 14;
										SET @ERROR_MES = 'Необходимо указать вид оплаты "транзитная проводка"!';
										RETURN @ERROR_NUM;
									END
							END
					END
			END
		DECLARE @EarningType_Id D_ID;
		IF( @EarningType_Guid IS NOT NULL )
			BEGIN
				SELECT @EarningType_Id = EarningType_Id FROM [dbo].[T_EarningType] WHERE [EarningType_Guid] = @EarningType_Guid;
				IF( @EarningType_Id = 1 )
					BEGIN
						IF( @CompanyPayer_Guid IS NULL ) OR ( @BudgetProjectSRC_Guid IS NULL )
							BEGIN
								SET @ERROR_NUM = 14;
								SET @ERROR_MES = 'Для транзитной оплаты необходимо указать компанию-плательщика и проект-источник.';
								RETURN @ERROR_NUM;
							END
					END
			END

    DECLARE @NewID D_GUID;
    SET @NewID = NEWID ( );	
                
		DECLARE @CurrencyMainGuid D_GUID; 

		SELECT TOP 1 @CurrencyMainGuid = [Currency_Guid] FROM [dbo].[T_Currency]
		WHERE [Currency_IsMain] = 1;

		SELECT @Earning_CurrencyRate = [dbo].[GetCurrencyRatePricingInOut]( @CurrencyMainGuid, @Earning_CurrencyGuid, @Earning_Date );

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
		
		DECLARE @Earning_ValueByCurrencyRate money = 0;
		IF( @Earning_CurrencyRate <> 0 )
			SET @Earning_ValueByCurrencyRate = ( @Earning_Value/@Earning_CurrencyRate );

    INSERT INTO dbo.T_Earning ( Earning_Guid, Earning_Id, Customer_Guid, Currency_Guid,	Earning_Date, 
			Earning_DocNum, Bank_Guid, Account_Guid, Earning_Value, Earning_Expense, Company_Guid, 
			Earning_CurrencyRate, Earning_CurrencyValue, Earning_CustomerText, Earning_DetailsPaymentText, 
			Earning_iKey, BudgetProjectSRC_Guid, BudgetProjectDST_Guid,	CompanyPayer_Guid,
			CustomerChild_Guid,	AccountPlan_Guid,	PaymentType_Guid,	Earning_IsBonus, EarningType_Guid )
		VALUES( @NewID, @Earning_Id, @Earning_CustomerGuid, @Earning_CurrencyGuid, @Earning_Date, 
			@Earning_DocNum, @Bank_Guid,  @Account_Guid, @Earning_Value, 0, @Earning_CompanyGuid, 
			@Earning_CurrencyRate, @Earning_ValueByCurrencyRate, @Earning_CustomerText, @Earning_DetailsPaymentText, 
			@Earning_iKey, @BudgetProjectSRC_Guid, @BudgetProjectDST_Guid,	@CompanyPayer_Guid,
			@CustomerChild_Guid,	@AccountPlan_Guid,	@PaymentType_Guid,	@Earning_IsBonus, @EarningType_Guid );
        
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
		
		DECLARE @EarningType_Guid uniqueidentifier;
		DECLARE @NEED_SAVE_IN_IB bit = 0;	     
		
		SELECT @EarningType_Guid = EarningType_Guid FROM dbo.[T_Earning] WHERE Earning_Guid = @Earning_Guid;
		
		IF( @EarningType_Guid IS NULL ) 
			BEGIN
				SET @NEED_SAVE_IN_IB = 1;
			END
		ELSE
			BEGIN
				IF EXISTS( SELECT [EarningType_Guid] FROM [dbo].[T_EarningType] 
										WHERE [EarningType_Guid] = @EarningType_Guid 
											AND [EarningType_DublicateInIB] = 1 )
						SET @NEED_SAVE_IN_IB = 1;
			END
		
		IF( @NEED_SAVE_IN_IB = 0 )
			BEGIN
				SET @Earning_Id = 0;
				UPDATE dbo.T_Earning	SET Earning_Id = @Earning_Id	WHERE Earning_Guid = @Earning_Guid;

				SET @ERROR_NUM = 0;
				SET @ERROR_MES = 'Оплата не регистрируется в "Контракте"';

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
		DECLARE @EarningIsTransit				int;
		DECLARE @BudgetProjectSRC_Guid	D_GUID;
		DECLARE @CompanyPayer_Guid			D_GUID;
  
    SELECT @Customer_Guid = Customer_Guid, @Earning_CustomerId = [Customer_Id], @Earning_CurrencyCode =  [Currency_Abbr], 
			@Earning_Date = [Earning_Date], @Earning_DocNum = [Earning_DocNum], 
			@Account_Guid = [Account_Guid], @Bank_Guid = [Bank_Guid], @Earning_Value = [Earning_Value],
			@Earning_Expense = [Earning_Expense], @Earning_Saldo = [Earning_Saldo],
			@Earning_CompanyId = [Company_Id], @Earning_CurrencyRate = [Earning_CurrencyRate],
			@Earning_CurrencyValue = [Earning_CurrencyValue], @Earning_iKey = [Earning_iKey], 
			@Earning_BankAccount = [AccountViewAccount_Number], @Earning_BankCode = [Bank_Code], 
			@BudgetProjectSRC_Guid = BudgetProjectSRC_Guid, @CompanyPayer_Guid = CompanyPayer_Guid
		FROM [dbo].[EarningView] WHERE Earning_Guid = @Earning_Guid;
      
    IF( @Earning_CustomerId IS NULL ) SET @Earning_CustomerId = 0;
		IF( @Earning_CompanyId IS NULL )
      BEGIN
        SET @ERROR_NUM = 2;
        SET @ERROR_MES = 'Не найдена компания, указанная в платеже. УИ платежа: ' + CAST( @Earning_Guid as nvarchar(36) );

        RETURN @ERROR_NUM;
      END 
		
		IF( @NEED_SAVE_IN_IB = 1 ) SET @EarningIsTransit = 0;
		ELSE SET @EarningIsTransit = 1;

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
					'''''' + cast( @Earning_iKey as nvarchar( 50 )) + '''''' + ', ' +
					'''''' + cast( @EarningIsTransit as nvarchar( 8 )) + ''''' )'' )'; 
					
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

		DECLARE @EarningType_Guid uniqueidentifier;
		DECLARE @NEED_SAVE_IN_IB bit = 0;	     
		
		SELECT @EarningType_Guid = EarningType_Guid FROM dbo.[T_Earning] WHERE Earning_Guid = @Earning_Guid;
		
		IF( @EarningType_Guid IS NULL ) 
			BEGIN
				SET @NEED_SAVE_IN_IB = 1;
			END
		ELSE
			BEGIN
				IF EXISTS( SELECT [EarningType_Guid] FROM [dbo].[T_EarningType] 
										WHERE [EarningType_Guid] = @EarningType_Guid 
											AND [EarningType_DublicateInIB] = 1 )
						SET @NEED_SAVE_IN_IB = 1;
			END
		
		IF( @NEED_SAVE_IN_IB = 0 )
			BEGIN
				SET @ERROR_NUM = 0;
				SET @ERROR_MES = 'Оплата не регистрируется в "Контракте"';

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
 		DECLARE @EarningIsTransit				int;
		DECLARE @BudgetProjectSRC_Guid	D_GUID;
		DECLARE @CompanyPayer_Guid			D_GUID;

    SELECT @Earning_Id = Earning_Id, @Customer_Guid = Customer_Guid, @Earning_CustomerId = [Customer_Id], @Earning_CurrencyCode =  [Currency_Abbr], 
			@Earning_Date = [Earning_Date], @Earning_DocNum = [Earning_DocNum], 
			@Account_Guid = [Account_Guid], @Bank_Guid = [Bank_Guid], @Earning_Value = [Earning_Value],
			@Earning_Expense = [Earning_Expense], @Earning_Saldo = [Earning_Saldo],
			@Earning_CompanyId = [Company_Id], @Earning_CurrencyRate = [Earning_CurrencyRate],
			@Earning_CurrencyValue = [Earning_CurrencyValue], @Earning_iKey = [Earning_iKey], 
			@Earning_BankAccount = [AccountViewAccount_Number], @Earning_BankCode = [Bank_Code],
			@BudgetProjectSRC_Guid = BudgetProjectSRC_Guid, @CompanyPayer_Guid = CompanyPayer_Guid
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
				   
		--IF( ( @BudgetProjectSRC_Guid IS NOT NULL ) AND ( @CompanyPayer_Guid IS NOT NULL ) )
		--	SET @EarningIsTransit = 1;
		--ELSE
		--	SET @EarningIsTransit = 0;

		IF( @NEED_SAVE_IN_IB = 1 ) SET @EarningIsTransit = 0;
		ELSE SET @EarningIsTransit = 1;

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
					'''''' + cast( @Earning_iKey as nvarchar( 50 )) + '''''' + ', ' +
					'''''' + cast( @EarningIsTransit as nvarchar( 8 )) + ''''' )'' )'; 
					
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
--		@EarningType_Guid						- УИ вида оплаты
--
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
	@EarningType_Guid						D_GUID_NULL = NULL,

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

    -- вид оплаты
		IF( @EarningType_Guid IS NOT NULL )
			BEGIN
				IF NOT EXISTS ( SELECT [EarningType_Guid]  FROM [dbo].[T_EarningType]	WHERE [EarningType_Guid] = @EarningType_Guid )
					BEGIN
						SET @ERROR_NUM = 13;
						SET @ERROR_MES = 'В базе данных не найден вид оплаты с указанным идентификатором: ' + CAST( @EarningType_Guid as nvarchar(36) );
						
						RETURN @ERROR_NUM;
					END
			END	
		ELSE
			BEGIN
				SET @ERROR_NUM = 13;
				SET @ERROR_MES = 'Пожалуйста, укажите вид оплаты (оплата за товар, транзит и т.д.)';
				
				RETURN @ERROR_NUM;
			END

		-- курс ценообразования
		DECLARE @CurrencyMainGuid D_GUID; 

		SELECT TOP 1 @CurrencyMainGuid = [Currency_Guid] FROM [dbo].[T_Currency]
		WHERE [Currency_IsMain] = 1;
		SELECT @Earning_CurrencyRate = [dbo].[GetCurrencyRatePricingInOut]( @CurrencyMainGuid, @Earning_CurrencyGuid, @Earning_Date );

		DECLARE @Earning_ValueByCurrencyRate money = 0;
		IF( @Earning_CurrencyRate <> 0 )
			SET @Earning_ValueByCurrencyRate = ( @Earning_Value/@Earning_CurrencyRate );

		-- проверка на изменение вида оплаты
		--
		-- если "оплата за товар" --> "транзит" или "прочий приход", то необходимо проверить, участвовал ли платеж в оплате долгов
		-- если участвовал, то предварительно требуется сторнировать оплаты, а если НЕ участвовал, то в InterBase платеж удаляется
		-- 
		-- если "транзит" или "прочий приход" --> "оплата за товар", то платеж необходимо зарегистрировать в InterBase в том случае, если Earning_Id = 0
		-- для "транзита" и "прочего прихода" операция оплаты по долгам не предусмотрена, но в любом случае необходимо проверить, участвовал ли платеж в оплате долгов
		-- если сумма расхода платежа больше нуля, то необходимо сторнировать оплаты
		--

		DECLARE @PrevEarningType_Guid D_GUID;
		DECLARE @PrevEarningType_DublicateInIB bit;
		DECLARE @PrevEarningType_Id int;
		DECLARE @EarningType_DublicateInIB bit;
		DECLARE @EarningType_Id int;
		DECLARE @Earning_Id int;
		DECLARE @Earning_Expense	D_MONEY;

		SELECT @PrevEarningType_Guid = EarningType_Guid, @Earning_Id = Earning_Id, @Earning_Expense = Earning_Expense 
		FROM [dbo].[T_Earning] WHERE Earning_Guid = @Earning_Guid;
		IF( @PrevEarningType_Guid IS NULL )
			BEGIN
				SET @ERROR_NUM = 14;
				SET @ERROR_MES = 'Системе не удалось определить текущий вид оплаты. Операция отменена. Пожалуйста, обратитесь к разработчику.';
				
				RETURN @ERROR_NUM;
			END
		
		SELECT @PrevEarningType_DublicateInIB = [EarningType_DublicateInIB], 	@PrevEarningType_Id = [EarningType_Id]		
		FROM [dbo].[T_EarningType] 
		WHERE [EarningType_Guid] = @PrevEarningType_Guid;

		SELECT @EarningType_DublicateInIB = [EarningType_DublicateInIB], 	@EarningType_Id = [EarningType_Id]		
		FROM [dbo].[T_EarningType] 
		WHERE [EarningType_Guid] = @EarningType_Guid;

		IF( ( @PrevEarningType_DublicateInIB <> @EarningType_DublicateInIB ) AND ( @Earning_Expense > 0 )  )
			BEGIN
				SET @ERROR_NUM = 15;
				SET @ERROR_MES = 'Платеж разносился по долгам. Отсторнируйте, пожалуйста, оплаты, и повторите операцию.';
				
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
			Earning_CurrencyRate = @Earning_CurrencyRate, Earning_CurrencyValue = @Earning_ValueByCurrencyRate, 
			Earning_CustomerText = @Earning_CustomerText, Earning_DetailsPaymentText = @Earning_DetailsPaymentText, 
			Earning_iKey = @Earning_iKey, BudgetProjectSRC_Guid = @BudgetProjectSRC_Guid, 
			BudgetProjectDST_Guid = @BudgetProjectDST_Guid,	CompanyPayer_Guid = @CompanyPayer_Guid,
			CustomerChild_Guid = @CustomerChild_Guid,	AccountPlan_Guid = @AccountPlan_Guid,	
			PaymentType_Guid = @PaymentType_Guid,	Earning_IsBonus = @Earning_IsBonus, EarningType_Guid = @EarningType_Guid
		WHERE Earning_Guid = @Earning_Guid;

		IF( @PrevEarningType_DublicateInIB <> @EarningType_DublicateInIB )
			BEGIN
				-- в новом и текущем виде оплаты разные значения реквизита "платеж необходимо дублировать в InterBase"
				IF( ( @PrevEarningType_DublicateInIB = 0 ) AND ( @EarningType_DublicateInIB = 1 ) )
					BEGIN
						IF( @Earning_Id = 0 )
							BEGIN
								-- платеж не регистрировался в InterBase, его необходимо добавить
								EXEC dbo.usp_AddEarningToIB @Earning_Guid = @Earning_Guid, @IBLINKEDSERVERNAME = NULL, @Earning_Id = @Earning_Id output,
									@ERROR_NUM = @ERROR_NUM output, @ERROR_MES = @ERROR_MES output;
							END
						ELSE
							BEGIN
								EXEC dbo.usp_EditEarningInIB @Earning_Guid = @Earning_Guid, @IBLINKEDSERVERNAME = NULL, 
									@ERROR_NUM = @ERROR_NUM output, @ERROR_MES = @ERROR_MES output;
							END
					END
				ELSE IF( ( @PrevEarningType_DublicateInIB = 1 ) AND ( @EarningType_DublicateInIB = 0 ) )
					BEGIN
						IF( @Earning_Id <> 0 )
							BEGIN
								-- для выбранного вид платежа необходимо удалить запись из InterBase (T_EARNING ) 
								EXEC dbo.usp_DeleteEarning2FromIB @Earning_Guid = @Earning_Guid, @IBLINKEDSERVERNAME = NULL, 
									@ERROR_NUM = @ERROR_NUM output, @ERROR_MES = @ERROR_MES output;
								IF( @ERROR_NUM = 0 )
									UPDATE [dbo].[T_Earning] SET Earning_Id = 0 WHERE Earning_Guid = @Earning_Guid;
							END

					END
			END
		ELSE
			BEGIN
				-- вид оплаты не меняется
				EXEC dbo.usp_EditEarningInIB @Earning_Guid = @Earning_Guid, @IBLINKEDSERVERNAME = NULL, 
					@ERROR_NUM = @ERROR_NUM output, @ERROR_MES = @ERROR_MES output;
			END


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

/****** Object:  StoredProcedure [dbo].[usp_EditEarningInSQLandIB]    Script Date: 17.01.2014 16:43:24 ******/
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
--		@EarningType_Guid						- УИ вида оплаты
--
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
	@EarningType_Guid						D_GUID_NULL = NULL,

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

    -- вид оплаты
		IF( @EarningType_Guid IS NOT NULL )
			BEGIN
				IF NOT EXISTS ( SELECT [EarningType_Guid]  FROM [dbo].[T_EarningType]	WHERE [EarningType_Guid] = @EarningType_Guid )
					BEGIN
						SET @ERROR_NUM = 13;
						SET @ERROR_MES = 'В базе данных не найден вид оплаты с указанным идентификатором: ' + CAST( @EarningType_Guid as nvarchar(36) );
						
						RETURN @ERROR_NUM;
					END
			END	
		ELSE
			BEGIN
				SET @ERROR_NUM = 13;
				SET @ERROR_MES = 'Пожалуйста, укажите вид оплаты (оплата за товар, транзит и т.д.)';
				
				RETURN @ERROR_NUM;
			END

		-- проверка на заполнение реквизитов транзитной проводки
		IF( ( @CompanyPayer_Guid IS NOT NULL ) OR ( @BudgetProjectSRC_Guid IS NOT NULL ) )
			BEGIN
				-- указан проект-источник либо компания-плательщик
				IF( ( ( @CompanyPayer_Guid IS NOT NULL ) AND ( @BudgetProjectSRC_Guid IS NULL ) ) OR
						( ( @CompanyPayer_Guid IS NULL ) AND ( @BudgetProjectSRC_Guid IS NOT NULL ) ) )
					BEGIN
						SET @ERROR_NUM = 14;
						SET @ERROR_MES = 'В том случае, если указана либо компания-плательщик, либо проект-источник, необходимо указать оба реквизита.';
						RETURN @ERROR_NUM;
					END
				ELSE IF ( ( @CompanyPayer_Guid IS NOT NULL ) AND ( @BudgetProjectSRC_Guid IS NOT NULL ) )
					BEGIN
						-- указаны оба реквизита, вид оплаты должен быть "транзитная проводка"
						IF( @EarningType_Guid IS NULL )
							BEGIN
								SET @ERROR_NUM = 14;
								SET @ERROR_MES = 'Укажите, пожалуйста, тип оплаты "транзитная проводка".';
								RETURN @ERROR_NUM;
							END
						ELSE
							BEGIN
								IF NOT EXISTS( SELECT [EarningType_Guid] FROM [dbo].[T_EarningType] WHERE [EarningType_Guid] = @EarningType_Guid AND EarningType_Id = 1 )
									BEGIN
										SET @ERROR_NUM = 14;
										SET @ERROR_MES = 'Необходимо указать тип оплаты "транзитная проводка"!';
										RETURN @ERROR_NUM;
									END
							END
					END
			END

		DECLARE @EarningType_Id D_ID;
		IF( @EarningType_Guid IS NOT NULL )
			BEGIN
				SELECT @EarningType_Id = EarningType_Id FROM [dbo].[T_EarningType] WHERE [EarningType_Guid] = @EarningType_Guid;
				IF( @EarningType_Id = 1 )
					BEGIN
						IF( @CompanyPayer_Guid IS NULL ) OR ( @BudgetProjectSRC_Guid IS NULL )
							BEGIN
								SET @ERROR_NUM = 14;
								SET @ERROR_MES = 'Для транзитной оплаты необходимо указать компанию-плательщика и проект-источник.';
								RETURN @ERROR_NUM;
							END
					END
			END

		-- курс ценообразования
		DECLARE @CurrencyMainGuid D_GUID; 

		SELECT TOP 1 @CurrencyMainGuid = [Currency_Guid] FROM [dbo].[T_Currency]
		WHERE [Currency_IsMain] = 1;
		SELECT @Earning_CurrencyRate = [dbo].[GetCurrencyRatePricingInOut]( @CurrencyMainGuid, @Earning_CurrencyGuid, @Earning_Date );

		DECLARE @Earning_ValueByCurrencyRate money = 0;
		IF( @Earning_CurrencyRate <> 0 )
			SET @Earning_ValueByCurrencyRate = ( @Earning_Value/@Earning_CurrencyRate );

		-- проверка на изменение вида оплаты
		--
		-- если "оплата за товар" --> "транзит" или "прочий приход", то необходимо проверить, участвовал ли платеж в оплате долгов
		-- если участвовал, то предварительно требуется сторнировать оплаты, а если НЕ участвовал, то в InterBase платеж удаляется
		-- 
		-- если "транзит" или "прочий приход" --> "оплата за товар", то платеж необходимо зарегистрировать в InterBase в том случае, если Earning_Id = 0
		-- для "транзита" и "прочего прихода" операция оплаты по долгам не предусмотрена, но в любом случае необходимо проверить, участвовал ли платеж в оплате долгов
		-- если сумма расхода платежа больше нуля, то необходимо сторнировать оплаты
		--

		DECLARE @PrevEarningType_Guid D_GUID;
		DECLARE @PrevEarningType_DublicateInIB bit;
		DECLARE @PrevEarningType_Id int;
		DECLARE @EarningType_DublicateInIB bit;
		DECLARE @Earning_Id int;
		DECLARE @Earning_Expense	D_MONEY;

		SELECT @PrevEarningType_Guid = EarningType_Guid, @Earning_Id = Earning_Id, @Earning_Expense = Earning_Expense 
		FROM [dbo].[T_Earning] WHERE Earning_Guid = @Earning_Guid;
		IF( @PrevEarningType_Guid IS NULL )
			BEGIN
				SET @ERROR_NUM = 14;
				SET @ERROR_MES = 'Системе не удалось определить текущий вид оплаты. Операция отменена. Пожалуйста, обратитесь к разработчику.';
				
				RETURN @ERROR_NUM;
			END
		
		SELECT @PrevEarningType_DublicateInIB = [EarningType_DublicateInIB], 	@PrevEarningType_Id = [EarningType_Id]		
		FROM [dbo].[T_EarningType] 
		WHERE [EarningType_Guid] = @PrevEarningType_Guid;

		SELECT @EarningType_DublicateInIB = [EarningType_DublicateInIB], 	@EarningType_Id = [EarningType_Id]		
		FROM [dbo].[T_EarningType] 
		WHERE [EarningType_Guid] = @EarningType_Guid;

		IF( ( @PrevEarningType_DublicateInIB <> @EarningType_DublicateInIB ) AND ( @Earning_Expense > 0 )  )
			BEGIN
				SET @ERROR_NUM = 15;
				SET @ERROR_MES = 'Платеж разносился по долгам. Отсторнируйте, пожалуйста, оплаты, и повторите операцию.';
				
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
			Earning_CurrencyRate = @Earning_CurrencyRate, Earning_CurrencyValue = @Earning_ValueByCurrencyRate, 
			Earning_CustomerText = @Earning_CustomerText, Earning_DetailsPaymentText = @Earning_DetailsPaymentText, 
			Earning_iKey = @Earning_iKey, BudgetProjectSRC_Guid = @BudgetProjectSRC_Guid, 
			BudgetProjectDST_Guid = @BudgetProjectDST_Guid,	CompanyPayer_Guid = @CompanyPayer_Guid,
			CustomerChild_Guid = @CustomerChild_Guid,	AccountPlan_Guid = @AccountPlan_Guid,	
			PaymentType_Guid = @PaymentType_Guid,	Earning_IsBonus = @Earning_IsBonus, EarningType_Guid = @EarningType_Guid
		WHERE Earning_Guid = @Earning_Guid;

		IF( @PrevEarningType_DublicateInIB <> @EarningType_DublicateInIB )
			BEGIN
				-- в новом и текущем виде оплаты разные значения реквизита "платеж необходимо дублировать в InterBase"
				IF( ( @PrevEarningType_DublicateInIB = 0 ) AND ( @EarningType_DublicateInIB = 1 ) )
					BEGIN
						IF( @Earning_Id = 0 )
							BEGIN
								-- платеж не регистрировался в InterBase, его необходимо добавить
								EXEC dbo.usp_AddEarningToIB @Earning_Guid = @Earning_Guid, @IBLINKEDSERVERNAME = NULL, @Earning_Id = @Earning_Id output,
									@ERROR_NUM = @ERROR_NUM output, @ERROR_MES = @ERROR_MES output;
							END
						ELSE
							BEGIN
								EXEC dbo.usp_EditEarningInIB @Earning_Guid = @Earning_Guid, @IBLINKEDSERVERNAME = NULL, 
									@ERROR_NUM = @ERROR_NUM output, @ERROR_MES = @ERROR_MES output;
							END
					END
				ELSE IF( ( @PrevEarningType_DublicateInIB = 1 ) AND ( @EarningType_DublicateInIB = 0 ) )
					BEGIN
						IF( @Earning_Id <> 0 )
							BEGIN
								-- для выбранного вид платежа необходимо удалить запись из InterBase (T_EARNING ) 
								EXEC dbo.usp_DeleteEarning2FromIB @Earning_Guid = @Earning_Guid, @IBLINKEDSERVERNAME = NULL, 
									@ERROR_NUM = @ERROR_NUM output, @ERROR_MES = @ERROR_MES output;
								IF( @ERROR_NUM = 0 )
									UPDATE [dbo].[T_Earning] SET Earning_Id = 0 WHERE Earning_Guid = @Earning_Guid;
							END

					END
			END
		ELSE
			BEGIN
				-- вид оплаты не меняется
				EXEC dbo.usp_EditEarningInIB @Earning_Guid = @Earning_Guid, @IBLINKEDSERVERNAME = NULL, 
					@ERROR_NUM = @ERROR_NUM output, @ERROR_MES = @ERROR_MES output;
			END


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
