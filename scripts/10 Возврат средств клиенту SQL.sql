USE [ERP_Mercury]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[T_PaymentOperationType](
	[PaymentOperationType_Guid] [dbo].[D_GUID] NOT NULL,
	[PaymentOperationType_Name] [dbo].[D_NAME] NOT NULL,
	[PaymentOperationType_Description] [dbo].[D_DESCRIPTION] NULL,
	[PaymentOperationType_Id] [dbo].[D_ID] NOT NULL,
 CONSTRAINT [PK_T_PaymentOperationType] PRIMARY KEY CLUSTERED 
(
	[PaymentOperationType_Guid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


/****** Object:  Index [INDX_T_PaymentOperationType_PaymentOperationType_Id]    Script Date: 13.06.2013 14:58:50 ******/
CREATE UNIQUE NONCLUSTERED INDEX [INDX_T_PaymentOperationType_PaymentOperationType_Id] ON [dbo].[T_PaymentOperationType]
(
	[PaymentOperationType_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [INDEX]
GO

INSERT INTO T_PaymentOperationType( PaymentOperationType_Guid, PaymentOperationType_Name, PaymentOperationType_Id )
VALUES( NEWID(), 'оплата долга', 2 )

INSERT INTO T_PaymentOperationType( PaymentOperationType_Guid, PaymentOperationType_Name, PaymentOperationType_Id )
VALUES( NEWID(), 'оплата начального долга', 5 )

INSERT INTO T_PaymentOperationType( PaymentOperationType_Guid, PaymentOperationType_Name, PaymentOperationType_Id )
VALUES( NEWID(), 'списание остатка платежа по ф. 2', 6 )

INSERT INTO T_PaymentOperationType( PaymentOperationType_Guid, PaymentOperationType_Name, PaymentOperationType_Id )
VALUES( NEWID(), 'списание остатка платежа по ф. 1', 7 )

INSERT INTO T_PaymentOperationType( PaymentOperationType_Guid, PaymentOperationType_Name, PaymentOperationType_Id )
VALUES( NEWID(), 'возврат средств клиенту ф. 1', 8 )

GO

/****** Object:  StoredProcedure [dbo].[usp_GetEarningHistoryFromIB]    Script Date: 13.06.2013 13:38:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- Возвращает историю разноски оплат для указанного платежа
--
-- Входные параметры
--
--		@Earning_Guid				- УИ платежа
--		@IBLINKEDSERVERNAME	- имя LinkedServer
--
-- Выходные параметры
--
--		@ERROR_NUM					- код ошбики
--		@ERROR_MES					- сообщение об ошибке
--
ALTER PROCEDURE [dbo].[usp_GetEarningHistoryFromIB] 
	@Earning_Guid				D_GUID,
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
  
	declare @sql_text nvarchar( 1000);
	
	BEGIN TRY

    DECLARE @EARNING_ID int;
		SELECT @EARNING_ID = Earning_Id FROM T_Earning WHERE Earning_Guid = @Earning_Guid;

		if( @EARNING_ID IS NULL )
			BEGIN
				SET @ERROR_NUM = 1;
				SET @ERROR_MES = 'В базе данных не найден платёж с указанным идентификатором: ' + CAST( @Earning_Guid as nvarchar(36) );
			END


		CREATE TABLE #EarningHistory( WAYBILL_ID int,  WAYBILL_NUM nvarchar(16),
			WAYBILL_SHIPDATE date,  CUSTOMER_NAME nvarchar(100), WAYBILL_TOTALPRICE float,
			WAYBILL_SALDO float, PAYMENTS_VALUE float, WAYBILL_BONUS int,  WAYBILL_SHIPPED int, 
			CUSTOMER_ID int, COMPANY_ID int, CHILDCUST_ID int, CURRENCY_CODE nvarchar(3), COMPANY_ACRONYM  nvarchar(3),
			COMPANY_NAME nvarchar(32), PAYMENTS_OPERDATE date, BANKDATE date, PAYMENTS_PAYMENTSCODE int );

		SELECT @sql_text = dbo.GetTextQueryForSelectFromInterbase( null, null, 
			' SELECT WAYBILL_ID, WAYBILL_NUM, WAYBILL_SHIPDATE, WAYBILL_TOTALPRICE, WAYBILL_SALDO,
					PAYMENTS_VALUE,  WAYBILL_BONUS, WAYBILL_SHIPPED,  CUSTOMER_ID, COMPANY_ID,
					CHILDCUST_ID, CURRENCY_CODE, CUSTOMER_NAME, COMPANY_ACRONYM, COMPANY_NAME, 
					PAYMENTS_OPERDATE, BANKDATE, PAYMENTS_PAYMENTSCODE
			FROM SP_EARNINGHISTORY( ' + cast( @EARNING_ID as nvarchar(10) ) + ' )');
			SET @sql_text = ' INSERT INTO #EarningHistory(  WAYBILL_ID, WAYBILL_NUM, WAYBILL_SHIPDATE, WAYBILL_TOTALPRICE, WAYBILL_SALDO,
					PAYMENTS_VALUE,  WAYBILL_BONUS, WAYBILL_SHIPPED,  CUSTOMER_ID, COMPANY_ID,
					CHILDCUST_ID, CURRENCY_CODE, CUSTOMER_NAME, COMPANY_ACRONYM, COMPANY_NAME, 
					PAYMENTS_OPERDATE, BANKDATE, PAYMENTS_PAYMENTSCODE ) ' + @sql_text;  
	    
		PRINT @sql_text;

		execute sp_executesql @sql_text;
		
		SELECT  WAYBILL_ID, WAYBILL_NUM, WAYBILL_SHIPDATE, WAYBILL_TOTALPRICE, WAYBILL_SALDO,
					PAYMENTS_VALUE,  WAYBILL_BONUS, WAYBILL_SHIPPED,  CUSTOMER_ID, COMPANY_ID,
					CHILDCUST_ID, CURRENCY_CODE, CUSTOMER_NAME, COMPANY_ACRONYM, COMPANY_NAME, 
					PAYMENTS_OPERDATE, BANKDATE, PAYMENTS_PAYMENTSCODE, T_PaymentOperationType.PaymentOperationType_Name
		FROM #EarningHistory INNER JOIN T_PaymentOperationType ON #EarningHistory.PAYMENTS_PAYMENTSCODE = T_PaymentOperationType.PaymentOperationType_Id
		ORDER BY PAYMENTS_OPERDATE;
		
		DROP TABLE #EarningHistory;
		
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

-- Производит операцию возврата средств клиенту по платежу в InterBase

-- Входные параметры
-- 
--		@Earning_Guid					- УИ платежа
--		@OPERATION_MONEY			- Сумма к возврату клиенту
--		@OPERATION_DATE				- дата операции
--		@IBLINKEDSERVERNAME		- имя LINKEDSERVER для подключения к InterBase
--
-- Выходные параметры
--
--		@WRITEOFF_MONEY				- фактически проведённая сумма возврата
--		@ERROR_NUM						- номер ошибки
--		@ERROR_MES						- сообщение об ошибке

CREATE PROCEDURE [dbo].[usp_WriteOffReturnMoneyToCustomerForm1InIB]
	@Earning_Guid					D_GUID = NULL,
	@OPERATION_MONEY			D_MONEY,
	@OPERATION_DATE				D_DATE,
	@IBLINKEDSERVERNAME		D_NAME = NULL,

  @WRITEOFF_MONEY				D_MONEY output,
	@ERROR_NUM						int output,
	@ERROR_MES						nvarchar(4000) output
AS

BEGIN
  BEGIN TRY
    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';
		SET @WRITEOFF_MONEY = 0;

		IF( @Earning_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT Earning_Guid FROM dbo.[T_Earning] WHERE Earning_Guid = @Earning_Guid )
				BEGIN
					SET @ERROR_NUM = 1;
					SET @ERROR_MES = 'В базе данных не найден платёж с указанным идентификатором: ' + CAST( @Earning_Guid as nvarchar(36) );

					RETURN @ERROR_NUM;
				END       
		
		DECLARE @EARNING_ID D_ID;

		SELECT @EARNING_ID = [Earning_Id]
		FROM dbo.[T_Earning] WHERE Earning_Guid = @Earning_Guid;

	  IF( @IBLINKEDSERVERNAME IS NULL ) SELECT @IBLINKEDSERVERNAME = dbo.GetIBLinkedServerName();
	  
    DECLARE @SQLString nvarchar( 2048 );
    DECLARE @ParmDefinition nvarchar( 500 );

    SET @ParmDefinition = N' @WRITEOFF_MONEY_Ib money output,	@ErrorNum_Ib int output, @ErrorText_Ib varchar(480) output'; 				

		SET @SQLString = 'SELECT @WRITEOFF_MONEY_Ib = WRITEOFF_MONEY, 
			@ErrorNum_Ib = ERROR_NUMBER, @ErrorText_Ib = ERROR_TEXT FROM OPENQUERY( ' + 
			@IBLINKEDSERVERNAME + ', ''SELECT WRITEOFF_MONEY,  ERROR_NUMBER, ERROR_TEXT FROM USP_WRITEOFFEARNING_RETURNMONEYCUSTOMER( ' + 
					cast( @EARNING_ID as nvarchar(20)) +  ', ' +
					cast( @OPERATION_MONEY as nvarchar(20)) +  ', ' +
					'''''' + cast( @OPERATION_DATE as nvarchar(10)) + '''''' + ' )'' )'; 

		PRINT @SQLString;

    EXECUTE sp_executesql @SQLString, @ParmDefinition, @WRITEOFF_MONEY_Ib = @WRITEOFF_MONEY output, 
			@ErrorNum_Ib = @ERROR_NUM output, @ErrorText_Ib = @ERROR_MES output;  
		
	END TRY
	
	BEGIN CATCH
    SET @ERROR_NUM = ERROR_NUMBER();
    SET @ERROR_MES = @ERROR_MES + ' ' + ERROR_MESSAGE();
    
	END CATCH;

	IF( @ERROR_NUM = 0 )
		SET @ERROR_MES = 'Успешное завершение операции.';

	RETURN @ERROR_NUM;

END

GO
GRANT EXECUTE ON [dbo].[usp_WriteOffReturnMoneyToCustomerForm1InIB] TO [public]
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Производит операцию возврата средств клиенту по платежу

-- Входные параметры
-- 
--		@Earning_Guid					- УИ платежа
--		@OPERATION_MONEY			- Сумма к возврату клиенту
--		@OPERATION_DATE				- дата операции
--		@IBLINKEDSERVERNAME		- имя LINKEDSERVER для подключения к InterBase
--
-- Выходные параметры
--
--		@WRITEOFF_MONEY				- фактически проведённая сумма возврата
--		@ERROR_NUM						- номер ошибки
--		@ERROR_MES						- сообщение об ошибке

CREATE PROCEDURE [dbo].[usp_WriteOffReturnMoneyToCustomerForm1ToSQLandIB] 
	@Earning_Guid					D_GUID,
	@OPERATION_MONEY			D_MONEY,
	@OPERATION_DATE				D_DATE,
	@IBLINKEDSERVERNAME		D_NAME = NULL,

  @WRITEOFF_MONEY				D_MONEY output,
	@ERROR_NUM						int output,
	@ERROR_MES						nvarchar(4000) output

AS

BEGIN

	BEGIN TRY
    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';
		SET @WRITEOFF_MONEY = 0;

		IF( @Earning_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT Earning_Guid FROM dbo.[T_Earning] WHERE Earning_Guid = @Earning_Guid )
				BEGIN
					SET @ERROR_NUM = 1;
					SET @ERROR_MES = 'В базе данных не найден платёж с указанным идентификатором: ' + CAST( @Earning_Guid as nvarchar(36) );

					RETURN @ERROR_NUM;
				END       
    
    BEGIN TRANSACTION UpdateData;

	    EXEC dbo.usp_WriteOffReturnMoneyToCustomerForm1InIB @Earning_Guid = @Earning_Guid, 
				@OPERATION_MONEY = @OPERATION_MONEY, 
				@OPERATION_DATE = @OPERATION_DATE,@IBLINKEDSERVERNAME = NULL, 
				@WRITEOFF_MONEY = @WRITEOFF_MONEY output, 
				@ERROR_NUM = @ERROR_NUM output, @ERROR_MES = @ERROR_MES output;

		IF( @ERROR_NUM = 0 )
			BEGIN
				UPDATE [dbo].[T_Earning] SET [Earning_Expense] = ( Earning_Expense + @WRITEOFF_MONEY ) WHERE Earning_Guid = @Earning_Guid;
				COMMIT TRANSACTION UpdateData;
			END
		ELSE 
			BEGIN
				ROLLBACK TRANSACTION UpdateData;
			END

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION UpdateData;

    SET @ERROR_NUM = ERROR_NUMBER();
    SET @ERROR_MES = ERROR_MESSAGE();

	END CATCH;

	IF( @ERROR_NUM = 0 )
		SET @ERROR_MES = 'Успешное завершение операции.';

	RETURN @ERROR_NUM;
END

GO
GRANT EXECUTE ON [dbo].[usp_WriteOffReturnMoneyToCustomerForm1ToSQLandIB] TO [public]
GO

