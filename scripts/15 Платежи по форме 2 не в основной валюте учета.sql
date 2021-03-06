USE [ERP_Mercury]
GO
/****** Object:  StoredProcedure [dbo].[usp_CorrectCEarningInfo]    Script Date: 13.02.2014 10:57:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--
-- Входные параметры
--
--		@IBLINKEDSERVERNAME	- имя LinkedServer
--
-- Выходные параметры
--
--		@ERROR_NUM					- код ошбики
--		@ERROR_MES					- сообщение об ошибке
--
ALTER PROCEDURE [dbo].[usp_CorrectCEarningInfo] 
  @Begin_Date					D_DATE,
	@End_Date						D_DATE,
  @IBLINKEDSERVERNAME	D_NAME = NULL,
	  
  @ERROR_NUM					int output,
  @ERROR_MES					nvarchar(4000) output
  
AS
-- процедура предназначена для выборки данных из справочника цен в InterBase
BEGIN
	SET NOCOUNT ON;
	
  SET @ERROR_NUM = 0;
  SET @ERROR_MES = '';

  IF( @IBLINKEDSERVERNAME IS NULL ) SELECT @IBLINKEDSERVERNAME = dbo.GetIBLinkedServerName();
  
	declare @sql_text nvarchar( 2048);
	
	BEGIN TRY

		DECLARE @strBEGIN_DATE varchar(10);
		SET @strBEGIN_DATE = CONVERT (varchar(10), @Begin_Date, 104 );
		DECLARE @strEND_DATE varchar(10);
		SET @strEND_DATE = CONVERT (varchar(10), @End_Date, 104 );

		DECLARE @Earning_Guid D_GUID;
		DECLARE @CustomerChild_Guid D_GUID;
		DECLARE @Customer_Guid D_GUID;
		DECLARE @Currency_Guid D_GUID;

		DECLARE @CEARNING_ID_OUT int;
		DECLARE @CEARNING_CODE int;
		DECLARE @CUSTOMER_ID int;
		DECLARE @CURRENCY_CODE nvarchar(3);
		DECLARE @CEARNING_DATE date;
		DECLARE @CEARNING_VALUE money;
		DECLARE @CEARNING_EXPENSE money;
		DECLARE @CEARNING_SALDO money;
		DECLARE @CHILDCUST_ID int;
		DECLARE @CEARNING_USDVALUE money;
		DECLARE @CEARNING_MODE int;
		DECLARE @CEARNING_CURRENCYVALUE money;
		DECLARE @COMPANY_ID int;
		DECLARE @CEARNING_CURRENCYRATE money;
		DECLARE @CEARNING_COMISPERCENT money;
		DECLARE @PaymentType_Guid D_GUID;
    DECLARE @NewID D_GUID;
		DECLARE @Account_Guid D_GUID;
		DECLARE @Bank_Guid D_GUID;
		DECLARE @CurrencyMain_Guid uniqueidentifier;

		DECLARE @Earning_CurrencyRate money;
		DECLARE @Earning_CurrencyValue money;
		DECLARE @Earning_Expense money;
		DECLARE @Earning_Value money;
		DECLARE @EarningCurrency_Guid uniqueidentifier;

		SELECT Top 1 @PaymentType_Guid = [PaymentType_Guid] FROM [dbo].[T_PaymentType] WHERE [PaymentType_Id] = 2;
		SELECT TOP 1 @Account_Guid = Account_Guid, @Bank_Guid = Bank_Guid FROM T_Account; 

		CREATE TABLE #CEarningList( CEARNING_ID_OUT int, CEARNING_CODE int, CUSTOMER_ID int, CURRENCY_CODE nvarchar(3),
			CEARNING_DATE date, CEARNING_VALUE money, CEARNING_EXPENSE money, CHILDCUST_ID int,
			CEARNING_USDVALUE money, CEARNING_MODE int, CEARNING_CURRENCYVALUE money, COMPANY_ID int,
			CEARNING_CURRENCYRATE money, CEARNING_COMISPERCENT money );

		SELECT @sql_text = dbo.GetTextQueryForSelectFromInterbase( null, null, 
			' SELECT  CEARNING_ID_OUT, CEARNING_CODE, CUSTOMER_ID, CURRENCY_CODE, CEARNING_DATE, CEARNING_VALUE, 
				CEARNING_EXPENSE, CHILDCUST_ID, CEARNING_USDVALUE, CEARNING_MODE, CEARNING_CURRENCYVALUE, COMPANY_ID, CEARNING_CURRENCYRATE, CEARNING_COMISPERCENT 
			FROM USP_GETCEARNINGINFO_FROMSQL_2( ' + '''''' + cast( @strBEGIN_DATE as nvarchar(20)) + '''''' + ', ' +
			'''''' + cast( @strEND_DATE as nvarchar(20)) + '''''' + ' )');
			SET @sql_text = ' INSERT INTO #CEarningList( CEARNING_ID_OUT, CEARNING_CODE, CUSTOMER_ID, CURRENCY_CODE, CEARNING_DATE, CEARNING_VALUE, 
				CEARNING_EXPENSE, CHILDCUST_ID, CEARNING_USDVALUE, CEARNING_MODE, CEARNING_CURRENCYVALUE, COMPANY_ID, CEARNING_CURRENCYRATE, CEARNING_COMISPERCENT ) ' + @sql_text;  

		PRINT @sql_text;

		execute sp_executesql @sql_text;
		
		DECLARE crSynch CURSOR FOR SELECT  CEARNING_ID_OUT, CEARNING_CODE, CUSTOMER_ID, CURRENCY_CODE, CEARNING_DATE, CEARNING_VALUE, 
			CEARNING_EXPENSE, CHILDCUST_ID, CEARNING_USDVALUE, CEARNING_MODE, CEARNING_CURRENCYVALUE, COMPANY_ID, CEARNING_CURRENCYRATE, CEARNING_COMISPERCENT
		FROM #CEarningList
		OPEN crSynch;
		FETCH next FROM crSynch INTO @CEARNING_ID_OUT, @CEARNING_CODE, @CUSTOMER_ID, @CURRENCY_CODE, @CEARNING_DATE, @CEARNING_VALUE, 
					@CEARNING_EXPENSE, @CHILDCUST_ID, @CEARNING_USDVALUE, @CEARNING_MODE, @CEARNING_CURRENCYVALUE, @COMPANY_ID, @CEARNING_CURRENCYRATE, @CEARNING_COMISPERCENT;
		WHILE @@fetch_status = 0
			BEGIN
				SET @Earning_Guid = NULL;
				
				SET @Earning_CurrencyRate = 0;
				SET @Earning_CurrencyValue = 0;
				SET @Earning_Expense = 0;
				SET @Earning_Value = 0;
				
				SELECT Top 1 @Earning_Guid = [Earning_Guid], @Earning_Value = Earning_Value,  @Earning_CurrencyRate = Earning_CurrencyRate,  
					@Earning_CurrencyValue = Earning_CurrencyValue, @Earning_Expense = Earning_Expense, @EarningCurrency_Guid = Currency_Guid
				FROM [dbo].[T_Earning] 
				WHERE [Earning_Id] = @CEARNING_ID_OUT AND [PaymentType_Guid] = @PaymentType_Guid;

				SET @CustomerChild_Guid  = NULL;
				SET @Customer_Guid  = NULL;
				SET @Currency_Guid = NULL;

				SELECT Top 1 @CustomerChild_Guid = CustomerChild_Guid FROM [dbo].[T_CustomerChild] WHERE [CustomerChild_Id] = @CHILDCUST_ID;
				SELECT @Customer_Guid = Customer_Guid FROM T_Customer WHERE Customer_Id = @CUSTOMER_ID;
				SELECT @Currency_Guid = Currency_Guid FROM T_Currency WHERE Currency_Abbr = @CURRENCY_CODE;

				IF( @CEARNING_VALUE = 25 )
					BEGIN
						PRINT @CEARNING_DATE;
						PRINT @CEARNING_VALUE;
						PRINT @CEARNING_CURRENCYVALUE;
						PRINT @CEARNING_EXPENSE;
--						PRINT @CEARNING_USDVALUE
						PRINT @CEARNING_CURRENCYRATE;
					END

				IF( @Earning_Guid IS NULL )
					BEGIN
						SET @NewID = NEWID();	

						INSERT INTO dbo.T_Earning ( Earning_Guid, Earning_Id, Customer_Guid, Currency_Guid,	Earning_Date, 
							Earning_DocNum, Bank_Guid, Account_Guid, Earning_Value, Earning_Expense,  
							Earning_CurrencyRate, Earning_CurrencyValue,   
							Earning_iKey, CustomerChild_Guid,	PaymentType_Guid,	Earning_IsBonus )
						VALUES( @NewID, @CEARNING_ID_OUT, @Customer_Guid, @Currency_Guid, @CEARNING_DATE, 
							'', @Bank_Guid,  @Account_Guid, @CEARNING_VALUE, @CEARNING_EXPENSE,  
							@CEARNING_CURRENCYRATE, @CEARNING_CURRENCYVALUE,   
							0, 	@CustomerChild_Guid,	@PaymentType_Guid,	@CEARNING_MODE );
        
						SET @Earning_Guid = @NewID;
					END
				
				IF( @Earning_Guid IS NOT NULL )
					BEGIN
						SET @CurrencyMain_Guid = ( SELECT dbo.GetCurrencyMain( @CEARNING_DATE ) );

						-- 2014.02.13 
						-- проверка на платежи по форме 2 не в валюте учета
						IF( @EarningCurrency_Guid <> @CurrencyMain_Guid )
							BEGIN
								-- в InterBase платеж по форме 2 регистрируется только в валюте учета
								-- при сохранении платежа в валюте, отличной от валюты учета, в Interbase происходит пересчет суммы платежа по курсу валюты учета
								-- при синхронизации расхода суммы необходимо сумму расхода из InterBase пересчитать по курсу
								IF( @Earning_CurrencyRate <> 0 )
									BEGIN
										UPDATE [dbo].[T_Earning] SET [Earning_Expense] = ( @CEARNING_EXPENSE * @Earning_CurrencyRate ) 
										WHERE [Earning_Guid] = @Earning_Guid;

										UPDATE [dbo].[T_Earning] SET [Earning_Expense] = [Earning_Value] 
										WHERE [Earning_Guid] = @Earning_Guid
											AND [Earning_Expense] > [Earning_Value];

									END

							END
						ELSE
							BEGIN
								UPDATE [dbo].[T_Earning] SET [Earning_Expense] = @CEARNING_EXPENSE WHERE [Earning_Guid] = @Earning_Guid;
							END

					END

				PRINT @Earning_Guid;

				FETCH next FROM crSynch INTO @CEARNING_ID_OUT, @CEARNING_CODE, @CUSTOMER_ID, @CURRENCY_CODE, @CEARNING_DATE, @CEARNING_VALUE, 
					@CEARNING_EXPENSE, @CHILDCUST_ID, @CEARNING_USDVALUE, @CEARNING_MODE, @CEARNING_CURRENCYVALUE, @COMPANY_ID, @CEARNING_CURRENCYRATE, @CEARNING_COMISPERCENT;
			END
		CLOSE crSynch;
		DEALLOCATE crSynch;
		
		DROP TABLE #CEarningList;
		
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

-- Регистрирует оплату задолженности по форме оплаты 2
-- Платёж разносится на указанный документ

-- Входные параметры
-- 
--		@Earning_Guid					- УИ платежа
--		@Waybill_Id						- УИ документа, подлежащего оплате
--
-- Выходные параметры
--
--		@EARNING_SALDO				- сальдо платежа
--		@EARNING_EXPENSE			- сумма расхода платежа
--		@DOCUMENT_NUM									- номер оплаченного документа
--		@DOCUMENT_DATE								- дата оплаченного документа
--		@DOCUMENT_CURRENCYSALDO				- сальдо оплаченного документа
--		@DOCUMENT_CURRENCYAMOUNTPAID	- итого оплачено по документу
--		@ERROR_NUM						- номер ошибки
--		@ERROR_MES						- сообщение об ошибке

ALTER PROCEDURE [dbo].[usp_PayDebitDocumentForm2ByEarningToSQLandIB] 
	@Earning_Guid					D_GUID,
	@Waybill_Id						D_ID,

  @EARNING_SALDO								D_MONEY output,
  @EARNING_EXPENSE							D_MONEY output,
  @DOCUMENT_NUM									D_NAME output,
  @DOCUMENT_DATE								D_DATE output,
  @DOCUMENT_CURRENCYSALDO				D_MONEY output,
  @DOCUMENT_CURRENCYAMOUNTPAID	D_MONEY output,

	@ERROR_NUM						int output,
	@ERROR_MES						nvarchar(4000) output

AS

BEGIN

	BEGIN TRY

    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';
		SET @EARNING_EXPENSE = 0;
		SET @EARNING_SALDO = 0;
		SET @DOCUMENT_CURRENCYSALDO = 0;
		SET @DOCUMENT_CURRENCYAMOUNTPAID = 0;
		SET @DOCUMENT_NUM = '';
		SET @DOCUMENT_DATE = NULL;

		IF NOT EXISTS ( SELECT Earning_Guid FROM dbo.[T_Earning] WHERE Earning_Guid = @Earning_Guid )
			BEGIN
				SET @ERROR_NUM = 1;
				SET @ERROR_MES = 'В базе данных не найден платёж с указанным идентификатором: ' + CAST( @Earning_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END       
    
    DECLARE @EventID D_ID;
    SET @EventID = NULL;
    DECLARE @ParentEventID D_ID;
    SET @ParentEventID = NULL;
    DECLARE @strMessage D_EVENTMSG;
    DECLARE @EventSrc D_NAME;
		DECLARE @Bank_Guid D_GUID;

    SET @EventSrc = 'Оплата задолженности в IB';
    
    
    BEGIN TRANSACTION UpdateData;

			SET @ERROR_MES = ( @ERROR_MES + ' 1. ');

	    EXEC dbo.usp_PayDebitDocumentForm2ByEarningInIB @Earning_Guid = @Earning_Guid,  @Waybill_Id = @Waybill_Id, @IBLINKEDSERVERNAME = NULL, 
				@EARNING_SALDO = @EARNING_SALDO output, @EARNING_EXPENSE = @EARNING_EXPENSE output,
				@DOCUMENT_NUM = @DOCUMENT_NUM output, @DOCUMENT_DATE = @DOCUMENT_DATE output, 
				@DOCUMENT_CURRENCYSALDO = @DOCUMENT_CURRENCYSALDO output, @DOCUMENT_CURRENCYAMOUNTPAID = @DOCUMENT_CURRENCYAMOUNTPAID output,
				@ERROR_NUM = @ERROR_NUM output, @ERROR_MES = @ERROR_MES output;

		IF( @ERROR_NUM = 0 )
			BEGIN
				DECLARE @CurrencyMain_Guid uniqueidentifier;
				DECLARE @Earning_CurrencyRate money;
				DECLARE @EarningCurrency_Guid uniqueidentifier;
				DECLARE @Earning_Date	date;

				SELECT @Earning_CurrencyRate = [Earning_CurrencyRate], @EarningCurrency_Guid = [Currency_Guid], @Earning_Date = [Earning_Date]
				FROM [dbo].[T_Earning] WHERE [Earning_Guid] = @Earning_Guid;

				SET @CurrencyMain_Guid = ( SELECT dbo.GetCurrencyMain( @Earning_Date ) );

				-- 2014.02.13 
				-- проверка на платежи по форме 2 не в валюте учета
				IF( @EarningCurrency_Guid <> @CurrencyMain_Guid )
					BEGIN
						-- в InterBase платеж по форме 2 регистрируется только в валюте учета
						-- при сохранении платежа в валюте, отличной от валюты учета, в Interbase происходит пересчет суммы платежа по курсу валюты учета
						-- при синхронизации расхода суммы необходимо сумму расхода из InterBase пересчитать по курсу
						IF( @Earning_CurrencyRate <> 0 )
							BEGIN
								UPDATE [dbo].[T_Earning] SET [Earning_Expense] = ( @EARNING_EXPENSE * @Earning_CurrencyRate ) 
								WHERE [Earning_Guid] = @Earning_Guid;

								UPDATE [dbo].[T_Earning] SET [Earning_Expense] = [Earning_Value] 
								WHERE [Earning_Guid] = @Earning_Guid
									AND [Earning_Expense] > [Earning_Value];

							END

					END
				ELSE
					BEGIN
						UPDATE [dbo].[T_Earning] SET [Earning_Expense] = @EARNING_EXPENSE WHERE Earning_Guid = @Earning_Guid;
					END


				SET @ERROR_MES = ( @ERROR_MES + ' Проведена оплата задолженности. УИ платежа: ' );
				COMMIT TRANSACTION UpdateData;
			END
		ELSE 
			BEGIN
				SET @ERROR_MES = 'Ошибка регистрации оплаты задолженности. ' + @ERROR_MES;
				ROLLBACK TRANSACTION UpdateData;
			END

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION UpdateData;

    SET @ERROR_NUM = ERROR_NUMBER();
    SET @ERROR_MES = ( @ERROR_MES + ' ' + ERROR_MESSAGE() );

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

-- Регистрирует оплату задолженности по форме оплаты 2
-- Платёж разносится на документы по дате их отгрузки, начиная с сомого раннего

-- Входные параметры
-- 
--		@Earning_Guid					- УИ платежа
--
-- Выходные параметры
--
--		@EARNING_SALDO				- сальдо платежа
--		@EARNING_EXPENSE			- сумма расхода платежа
--		@ERROR_NUM						- номер ошибки
--		@ERROR_MES						- сообщение об ошибке

ALTER PROCEDURE [dbo].[usp_PayDebitDocumentsForm2ToSQLandIB] 
	@Earning_Guid					D_GUID,

  @ID_START							int output,
  @ID_END								int output,
  @EARNING_SALDO				D_MONEY output,
  @EARNING_EXPENSE			D_MONEY output,

	@ERROR_NUM						int output,
	@ERROR_MES						nvarchar(4000) output

AS

BEGIN

	BEGIN TRY

    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';
		SET @ID_START = 0;
		SET @ID_END = 0;
		SET @EARNING_EXPENSE = 0;
		SET @EARNING_SALDO = 0;

		IF NOT EXISTS ( SELECT Earning_Guid FROM dbo.[T_Earning] WHERE Earning_Guid = @Earning_Guid )
			BEGIN
				SET @ERROR_NUM = 1;
				SET @ERROR_MES = 'В базе данных не найден платёж с указанным идентификатором: ' + CAST( @Earning_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END       
    
    DECLARE @EventID D_ID;
    SET @EventID = NULL;
    DECLARE @ParentEventID D_ID;
    SET @ParentEventID = NULL;
    DECLARE @strMessage D_EVENTMSG;
    DECLARE @EventSrc D_NAME;
		DECLARE @Bank_Guid D_GUID;

    SET @EventSrc = 'Оплата задолженности в IB';
    
    
    BEGIN TRANSACTION UpdateData;

	    EXEC dbo.usp_PayDebitDocumentsForm2InIB @Earning_Guid = @Earning_Guid,  @IBLINKEDSERVERNAME = NULL, 
				@ID_START = @ID_START output, @ID_END = @ID_END output, 
				@EARNING_SALDO = @EARNING_SALDO output, @EARNING_EXPENSE = @EARNING_EXPENSE output,
				@ERROR_NUM = @ERROR_NUM output, @ERROR_MES = @ERROR_MES output;

		IF( @ERROR_NUM = 0 )
			BEGIN
				DECLARE @CurrencyMain_Guid uniqueidentifier;
				DECLARE @Earning_CurrencyRate money;
				DECLARE @EarningCurrency_Guid uniqueidentifier;
				DECLARE @Earning_Date	date;

				SELECT @Earning_CurrencyRate = [Earning_CurrencyRate], @EarningCurrency_Guid = [Currency_Guid], @Earning_Date = [Earning_Date]
				FROM [dbo].[T_Earning] WHERE [Earning_Guid] = @Earning_Guid;

				SET @CurrencyMain_Guid = ( SELECT dbo.GetCurrencyMain( @Earning_Date ) );

				-- 2014.02.13 
				-- проверка на платежи по форме 2 не в валюте учета
				IF( @EarningCurrency_Guid <> @CurrencyMain_Guid )
					BEGIN
						-- в InterBase платеж по форме 2 регистрируется только в валюте учета
						-- при сохранении платежа в валюте, отличной от валюты учета, в Interbase происходит пересчет суммы платежа по курсу валюты учета
						-- при синхронизации расхода суммы необходимо сумму расхода из InterBase пересчитать по курсу
						IF( @Earning_CurrencyRate <> 0 )
							BEGIN
								UPDATE [dbo].[T_Earning] SET [Earning_Expense] = ( @EARNING_EXPENSE * @Earning_CurrencyRate ) 
								WHERE [Earning_Guid] = @Earning_Guid;

								UPDATE [dbo].[T_Earning] SET [Earning_Expense] = [Earning_Value] 
								WHERE [Earning_Guid] = @Earning_Guid
									AND [Earning_Expense] > [Earning_Value];
							END

					END
				ELSE
					BEGIN
						UPDATE [dbo].[T_Earning] SET [Earning_Expense] = @EARNING_EXPENSE WHERE Earning_Guid = @Earning_Guid;
					END

				SET @strMessage = 'Проведена оплата задолженности. УИ платежа: ' + CONVERT( nvarchar(36), @Earning_Guid );
				COMMIT TRANSACTION UpdateData;
			END
		ELSE 
			BEGIN
				SET @strMessage = 'Ошибка регистрации оплаты задолженности. ' + @ERROR_MES;
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

	--IF( @ERROR_NUM = 0 )
	--	SET @ERROR_MES = 'Успешное завершение операции.';

	RETURN @ERROR_NUM;
END

GO

