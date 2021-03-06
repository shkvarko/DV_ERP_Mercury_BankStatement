USE [ERP_Mercury]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- Возвращает список документов по ф1 для оплаты
--
-- Входные параметры
--
--		@Customer_Guid			- УИ клиента-плательщика
--		@Company_Guid				- УИ компании-получателя платежа
--		@IBLINKEDSERVERNAME	- имя LinkedServer
--
-- Выходные параметры
--
--		@ERROR_NUM					- код ошбики
--		@ERROR_MES					- сообщение об ошибке
--
CREATE PROCEDURE [dbo].[usp_GetDocForm1ForPaymentFromIB] 
	@Customer_Guid			D_GUID,
	@Company_Guid				D_GUID,
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

    DECLARE @CUSTOMER_ID int;
    DECLARE @COMPANY_ID int;
    DECLARE @CURRENCY_CODE nvarchar(3);
    DECLARE @ONLY_WAYBILL_SHIPMODE0 int;

		SET @CURRENCY_CODE = 'BYB';
		SET @ONLY_WAYBILL_SHIPMODE0 = 1;
		SELECT @CUSTOMER_ID = Customer_Id FROM T_Customer WHERE Customer_Guid = @Customer_Guid;
		SELECT @COMPANY_ID = Company_Id FROM T_Company WHERE Company_Guid = @Company_Guid;

		if( @CUSTOMER_ID IS NULL )
			BEGIN
				SET @ERROR_NUM = 1;
				SET @ERROR_MES = 'В базе данных не найден клиент с указанным идентификатором: ' + CAST( @Customer_Guid as nvarchar(36) );
			END

		if( @COMPANY_ID IS NULL )
			BEGIN
				SET @ERROR_NUM = 2;
				SET @ERROR_MES = 'В базе данных не найдена компания с указанным идентификатором: ' + CAST( @Company_Guid as nvarchar(36) );
			END

		if( @CURRENCY_CODE IS NULL )
			BEGIN
				SET @ERROR_NUM = 3;
				SET @ERROR_MES = 'В базе данных не найдена идентификатор валюты.';
			END

		CREATE TABLE #DocForm1ForPayment( SRC int, WAYBILL_ID int,  WAYBILL_NUM nvarchar(16),
			WAYBILL_BEGINDATE date,  CUSTOMER_NAME nvarchar(100), WAYBILL_TOTALPRICE float,
			WAYBILL_ENDDATE date,  WAYBILL_AMOUNTPAID float, WAYBILL_DATELASTPAID date,
			WAYBILL_SALDO float,  STOCK_NAME nvarchar(32),  WAYBILL_SHIPMODE int,
			WAYBILL_SHIPMODE_NAME nvarchar(100) );
	    
		SELECT @sql_text = dbo.GetTextQueryForSelectFromInterbase( null, null, 
			' SELECT SRC, WAYBILL_ID,  WAYBILL_NUM,  WAYBILL_BEGINDATE,
				CUSTOMER_NAME, WAYBILL_TOTALPRICE, WAYBILL_ENDDATE,
				WAYBILL_AMOUNTPAID, WAYBILL_DATELASTPAID, WAYBILL_SALDO,
				STOCK_NAME,  WAYBILL_SHIPMODE, WAYBILL_SHIPMODE_NAME 
			FROM SP_GETDOCFORPAYMENT( ' + cast( @CUSTOMER_ID as nvarchar(10) ) + ', ' + 
			  cast( @COMPANY_ID as nvarchar(10) ) + ', ''''' + cast( @CURRENCY_CODE as nvarchar(3) ) + 
				'''''' + ', ' + cast( @ONLY_WAYBILL_SHIPMODE0 as nvarchar(3) ) +  ' )');
			SET @sql_text = ' INSERT INTO #DocForm1ForPayment( SRC, WAYBILL_ID,  WAYBILL_NUM,  WAYBILL_BEGINDATE,
				CUSTOMER_NAME, WAYBILL_TOTALPRICE, WAYBILL_ENDDATE,
				WAYBILL_AMOUNTPAID, WAYBILL_DATELASTPAID, WAYBILL_SALDO,
				STOCK_NAME,  WAYBILL_SHIPMODE, WAYBILL_SHIPMODE_NAME ) ' + @sql_text;  
	    
		PRINT @sql_text;

		execute sp_executesql @sql_text;
		
		SELECT SRC, WAYBILL_ID,  WAYBILL_NUM,  WAYBILL_BEGINDATE,
				CUSTOMER_NAME, WAYBILL_TOTALPRICE, WAYBILL_ENDDATE,
				WAYBILL_AMOUNTPAID, WAYBILL_DATELASTPAID, WAYBILL_SALDO,
				STOCK_NAME,  WAYBILL_SHIPMODE, WAYBILL_SHIPMODE_NAME
		FROM #DocForm1ForPayment
		ORDER BY WAYBILL_BEGINDATE;
		
		DROP TABLE #DocForm1ForPayment;
		
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
GRANT EXECUTE ON [dbo].[usp_GetDocForm1ForPaymentFromIB] TO [public]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- Creation date:	
-- Author:			

CREATE FUNCTION [dbo].[GetNationalCurrencyAbbr] ()
RETURNS D_CURRENCYCODE
WITH EXECUTE AS caller
AS
BEGIN
  
	DECLARE @Currency_Abbr D_CURRENCYCODE = 'BYB';

	RETURN @Currency_Abbr;

end

GO
GRANT EXECUTE ON [dbo].[GetNationalCurrencyAbbr] TO [public]
GO



SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Регистрирует оплату задолженности в InterBase

-- Входные параметры
-- 
--		@Earning_Guid					- УИ платежа
--		@Waybill_Id						- УИ документа, подлежащего оплате
--		@IBLINKEDSERVERNAME		- имя LINKEDSERVER для подключения к InterBase
--
-- Выходные параметры
--
--		@FINDED_MONEY					- сумма разноски
--		@DOC_NUM							- номер оплаченного документа
--		@DOC_DATE							- дата оплаченного документа
--		@DOC_SALDO						- сальдо оплаченного документа
--		@ERROR_NUM						- номер ошибки
--		@ERROR_MES						- сообщение об ошибке

CREATE PROCEDURE [dbo].[usp_PayDebitDocumentForm1InIB]
	@Earning_Guid					D_GUID,
	@Waybill_Id						D_ID,
	@IBLINKEDSERVERNAME		D_NAME = NULL,

  @FINDED_MONEY					D_MONEY output,
  @DOC_NUM							D_NAME output,
  @DOC_DATE							D_DATE output,
	@DOC_SALDO						D_MONEY output,
	@ERROR_NUM						int output,
	@ERROR_MES						nvarchar(4000) output
AS

BEGIN
  BEGIN TRY
    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';
		SET @FINDED_MONEY = 0;
		SET @DOC_SALDO = 0;
		SET @DOC_NUM = '';
		SET @DOC_DATE = NULL;

		IF NOT EXISTS ( SELECT Earning_Guid FROM dbo.[T_Earning] WHERE Earning_Guid = @Earning_Guid )
			BEGIN
				SET @ERROR_NUM = 1;
				SET @ERROR_MES = 'В базе данных не найден платёж с указанным идентификатором: ' + CAST( @Earning_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END       
		
		DECLARE @EARNING_ID D_ID;
		DECLARE @DOC_CODE		D_ID;
		DECLARE @DOC_ID			D_ID;
		DECLARE @SETTLE_VALUE	D_MONEY;
		DECLARE @CURRENCY_CODE	D_CURRENCYCODE;

		SELECT @EARNING_ID = [Earning_Id], @SETTLE_VALUE = [Earning_Saldo] 
		FROM dbo.[T_Earning] WHERE Earning_Guid = @Earning_Guid;
		SET @DOC_CODE = 2;
		SET @DOC_ID = @Waybill_Id;
		SET @CURRENCY_CODE = ( SELECT dbo.GetNationalCurrencyAbbr() );

    DECLARE @EventID D_ID = NULL;
    DECLARE @ParentEventID D_ID = NULL;
    DECLARE @strMessage D_EVENTMSG = '';
    DECLARE @EventSrc D_NAME = 'Оплата задолженности в IB';

	  IF( @IBLINKEDSERVERNAME IS NULL ) SELECT @IBLINKEDSERVERNAME = dbo.GetIBLinkedServerName();
	  
    DECLARE @SQLString nvarchar( 2048 );
    DECLARE @ParmDefinition nvarchar( 500 );

    SET @ParmDefinition = N' @FINDED_MONEY_Ib money output, @DOCUMENT_NUM_Ib varchar(128) output, 
			@DOCUMENT_DATE_Ib date output, @DOCUMENT_SALDO_Ib money output,  @ErrorNum_Ib int output, @ErrorText_Ib varchar(480) output'; 				

		SET @SQLString = 'SELECT @FINDED_MONEY_Ib = FINDED_MONEY, @DOCUMENT_NUM_Ib = DOCUMENT_NUM, 
		 @DOCUMENT_DATE_Ib = DOCUMENT_DATE, @DOCUMENT_SALDO_Ib = DOCUMENT_SALDO, @ErrorNum_Ib = ERROR_NUMBER, @ErrorText_Ib = ERROR_TEXT FROM OPENQUERY( ' + 
			@IBLINKEDSERVERNAME + ', ''SELECT FINDED_MONEY, DOCUMENT_NUM, DOCUMENT_DATE, DOCUMENT_SALDO, ERROR_NUMBER, ERROR_TEXT FROM USP_NEWSETTLEDOC_FROMSQL( ' + cast( @DOC_CODE as nvarchar( 8 )) + ', ' + +
					cast( @DOC_ID as nvarchar(20)) +  ', ' +
					cast( @EARNING_ID as nvarchar(20)) +  ', ' +
					cast( @SETTLE_VALUE as nvarchar(20)) +  ', ' +
					'''''' + cast( @CURRENCY_CODE as nvarchar(3)) + ''''' )'' )'; 

		PRINT @ParmDefinition;

		PRINT @SQLString;
					
		PRINT Len(@SQLString);

    EXECUTE sp_executesql @SQLString, @ParmDefinition, @FINDED_MONEY_Ib = @FINDED_MONEY output, @DOCUMENT_NUM_Ib = @DOC_NUM output, 
			@DOCUMENT_DATE_Ib = @DOC_DATE output, @DOCUMENT_SALDO_Ib = @DOC_SALDO output,
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
		SET @ERROR_MES = 'Успешное завершение операции.';

	RETURN @ERROR_NUM;

END

GO
GRANT EXECUTE ON [dbo].[usp_PayDebitDocumentForm1InIB] TO [public]
GO



SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Регистрирует оплату задолженности в InterBase

-- Входные параметры
-- 
--		@Earning_Guid					- УИ платежа
--		@Waybill_Id						- УИ документа, подлежащего оплате
--
-- Выходные параметры
--
--		@FINDED_MONEY					- сумма разноски
--		@DOC_NUM							- номер оплаченного документа
--		@DOC_DATE							- дата оплаченного документа
--		@DOC_SALDO						- сальдо оплаченного документа
--		@ERROR_NUM						- номер ошибки
--		@ERROR_MES						- сообщение об ошибке

CREATE PROCEDURE [dbo].[usp_PayDebitDocumentForm1ToSQLandIB] 
	@Earning_Guid					D_GUID,
	@Waybill_Id						D_ID,

  @FINDED_MONEY					D_MONEY output,
  @DOC_NUM							D_NAME output,
  @DOC_DATE							D_DATE output,
	@DOC_SALDO						D_MONEY output,
	@ERROR_NUM						int output,
	@ERROR_MES						nvarchar(4000) output

AS

BEGIN

	BEGIN TRY

    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';
		SET @FINDED_MONEY = 0;
		SET @DOC_SALDO = 0;
		SET @DOC_NUM = '';
		SET @DOC_DATE = NULL;

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

	    EXEC dbo.usp_PayDebitDocumentForm1InIB @Earning_Guid = @Earning_Guid, @Waybill_Id = @Waybill_Id,  @IBLINKEDSERVERNAME = NULL, 
				@FINDED_MONEY = @FINDED_MONEY output, @DOC_NUM = @DOC_NUM output, @DOC_DATE = @DOC_DATE output, @DOC_SALDO = @DOC_SALDO output,
			@ERROR_NUM = @ERROR_NUM output, @ERROR_MES = @ERROR_MES output;

		IF( @ERROR_NUM = 0 )
			BEGIN
				SET @strMessage = 'Проверена оплата задолженности. УИ платежа: ' + CONVERT( nvarchar(36), @Earning_Guid );
				COMMIT TRANSACTION UpdateData
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

	IF( @ERROR_NUM = 0 )
		SET @ERROR_MES = 'Успешное завершение операции.';

	RETURN @ERROR_NUM;
END

GO
GRANT EXECUTE ON [dbo].[usp_PayDebitDocumentForm1ToSQLandIB] TO [public]
GO

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
CREATE PROCEDURE [dbo].[usp_GetEarningHistoryFromIB] 
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
			COMPANY_NAME nvarchar(32), PAYMENTS_OPERDATE date, BANKDATE date );

		SELECT @sql_text = dbo.GetTextQueryForSelectFromInterbase( null, null, 
			' SELECT WAYBILL_ID, WAYBILL_NUM, WAYBILL_SHIPDATE, WAYBILL_TOTALPRICE, WAYBILL_SALDO,
					PAYMENTS_VALUE,  WAYBILL_BONUS, WAYBILL_SHIPPED,  CUSTOMER_ID, COMPANY_ID,
					CHILDCUST_ID, CURRENCY_CODE, CUSTOMER_NAME, COMPANY_ACRONYM, COMPANY_NAME, 
					PAYMENTS_OPERDATE, BANKDATE
			FROM SP_EARNINGHISTORY( ' + cast( @EARNING_ID as nvarchar(10) ) + ' )');
			SET @sql_text = ' INSERT INTO #EarningHistory(  WAYBILL_ID, WAYBILL_NUM, WAYBILL_SHIPDATE, WAYBILL_TOTALPRICE, WAYBILL_SALDO,
					PAYMENTS_VALUE,  WAYBILL_BONUS, WAYBILL_SHIPPED,  CUSTOMER_ID, COMPANY_ID,
					CHILDCUST_ID, CURRENCY_CODE, CUSTOMER_NAME, COMPANY_ACRONYM, COMPANY_NAME, 
					PAYMENTS_OPERDATE, BANKDATE ) ' + @sql_text;  
	    
		PRINT @sql_text;

		execute sp_executesql @sql_text;
		
		SELECT  WAYBILL_ID, WAYBILL_NUM, WAYBILL_SHIPDATE, WAYBILL_TOTALPRICE, WAYBILL_SALDO,
					PAYMENTS_VALUE,  WAYBILL_BONUS, WAYBILL_SHIPPED,  CUSTOMER_ID, COMPANY_ID,
					CHILDCUST_ID, CURRENCY_CODE, CUSTOMER_NAME, COMPANY_ACRONYM, COMPANY_NAME, 
					PAYMENTS_OPERDATE, BANKDATE
		FROM #EarningHistory
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
GRANT EXECUTE ON [dbo].[usp_GetEarningHistoryFromIB] TO [public]
GO

/****** Object:  StoredProcedure [dbo].[usp_PayDebitDocumentForm1InIB]    Script Date: 24.04.2013 17:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Регистрирует оплату задолженности в InterBase

-- Входные параметры
-- 
--		@Earning_Guid					- УИ платежа
--		@Waybill_Id						- УИ документа, подлежащего оплате
--		@IBLINKEDSERVERNAME		- имя LINKEDSERVER для подключения к InterBase
--
-- Выходные параметры
--
--		@FINDED_MONEY					- сумма разноски
--		@DOC_NUM							- номер оплаченного документа
--		@DOC_DATE							- дата оплаченного документа
--		@DOC_SALDO						- сальдо оплаченного документа
--		@ERROR_NUM						- номер ошибки
--		@ERROR_MES						- сообщение об ошибке

ALTER PROCEDURE [dbo].[usp_PayDebitDocumentForm1InIB]
	@Earning_Guid					D_GUID,
	@Waybill_Id						D_ID,
	@IBLINKEDSERVERNAME		D_NAME = NULL,

  @FINDED_MONEY					D_MONEY output,
  @DOC_NUM							D_NAME output,
  @DOC_DATE							D_DATE output,
	@DOC_SALDO						D_MONEY output,
	@EARNING_SALDO				D_MONEY output,
	@EARNING_EXPENSE			D_MONEY output,
	@ERROR_NUM						int output,
	@ERROR_MES						nvarchar(4000) output
AS

BEGIN
  BEGIN TRY
    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';
		SET @FINDED_MONEY = 0;
		SET @DOC_SALDO = 0;
		SET @EARNING_EXPENSE = 0;
		SET @EARNING_SALDO = 0;
		SET @DOC_NUM = '';
		SET @DOC_DATE = NULL;

		IF NOT EXISTS ( SELECT Earning_Guid FROM dbo.[T_Earning] WHERE Earning_Guid = @Earning_Guid )
			BEGIN
				SET @ERROR_NUM = 1;
				SET @ERROR_MES = 'В базе данных не найден платёж с указанным идентификатором: ' + CAST( @Earning_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END       
		
		DECLARE @EARNING_ID D_ID;
		DECLARE @DOC_CODE		D_ID;
		DECLARE @DOC_ID			D_ID;
		DECLARE @SETTLE_VALUE	D_MONEY;
		DECLARE @CURRENCY_CODE	D_CURRENCYCODE;

		SELECT @EARNING_ID = [Earning_Id], @SETTLE_VALUE = [Earning_Saldo], @EARNING_EXPENSE = [Earning_Expense], @EARNING_SALDO = [Earning_Saldo]
		FROM dbo.[T_Earning] WHERE Earning_Guid = @Earning_Guid;
		SET @DOC_CODE = 2;
		SET @DOC_ID = @Waybill_Id;
		SET @CURRENCY_CODE = ( SELECT dbo.GetNationalCurrencyAbbr() );

    DECLARE @EventID D_ID = NULL;
    DECLARE @ParentEventID D_ID = NULL;
    DECLARE @strMessage D_EVENTMSG = '';
    DECLARE @EventSrc D_NAME = 'Оплата задолженности в IB';

	  IF( @IBLINKEDSERVERNAME IS NULL ) SELECT @IBLINKEDSERVERNAME = dbo.GetIBLinkedServerName();
	  
    DECLARE @SQLString nvarchar( 2048 );
    DECLARE @ParmDefinition nvarchar( 500 );

    SET @ParmDefinition = N' @FINDED_MONEY_Ib money output, @DOCUMENT_NUM_Ib varchar(128) output, 
			@DOCUMENT_DATE_Ib date output, @DOCUMENT_SALDO_Ib money output, @EARNING_SALDO_Ib money output, @EARNING_EXPENSE_Ib money output, 
			@ErrorNum_Ib int output, @ErrorText_Ib varchar(480) output'; 				

		SET @SQLString = 'SELECT @FINDED_MONEY_Ib = FINDED_MONEY, @DOCUMENT_NUM_Ib = DOCUMENT_NUM, 
		 @DOCUMENT_DATE_Ib = DOCUMENT_DATE, @DOCUMENT_SALDO_Ib = DOCUMENT_SALDO, @EARNING_SALDO_Ib = EARNING_SALDO, @EARNING_EXPENSE_Ib = EARNING_EXPENSE, 
		 @ErrorNum_Ib = ERROR_NUMBER, @ErrorText_Ib = ERROR_TEXT FROM OPENQUERY( ' + 
			@IBLINKEDSERVERNAME + ', ''SELECT FINDED_MONEY, DOCUMENT_NUM, DOCUMENT_DATE, DOCUMENT_SALDO, EARNING_SALDO, EARNING_EXPENSE, ERROR_NUMBER, ERROR_TEXT FROM USP_NEWSETTLEDOC_FROMSQL( ' + cast( @DOC_CODE as nvarchar( 8 )) + ', ' + +
					cast( @DOC_ID as nvarchar(20)) +  ', ' +
					cast( @EARNING_ID as nvarchar(20)) +  ', ' +
					cast( @SETTLE_VALUE as nvarchar(20)) +  ', ' +
					'''''' + cast( @CURRENCY_CODE as nvarchar(3)) + ''''' )'' )'; 

		PRINT @ParmDefinition;

		PRINT @SQLString;
					
		PRINT Len(@SQLString);

    EXECUTE sp_executesql @SQLString, @ParmDefinition, @FINDED_MONEY_Ib = @FINDED_MONEY output, @DOCUMENT_NUM_Ib = @DOC_NUM output, 
			@DOCUMENT_DATE_Ib = @DOC_DATE output, @DOCUMENT_SALDO_Ib = @DOC_SALDO output, @EARNING_SALDO_Ib = @EARNING_SALDO output, @EARNING_EXPENSE_Ib = @EARNING_EXPENSE,
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
		SET @ERROR_MES = 'Успешное завершение операции.';

	RETURN @ERROR_NUM;

END

GO

/****** Object:  StoredProcedure [dbo].[usp_PayDebitDocumentForm1ToSQLandIB]    Script Date: 24.04.2013 17:11:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Регистрирует оплату задолженности в InterBase

-- Входные параметры
-- 
--		@Earning_Guid					- УИ платежа
--		@Waybill_Id						- УИ документа, подлежащего оплате
--
-- Выходные параметры
--
--		@FINDED_MONEY					- сумма разноски
--		@DOC_NUM							- номер оплаченного документа
--		@DOC_DATE							- дата оплаченного документа
--		@DOC_SALDO						- сальдо оплаченного документа
--		@ERROR_NUM						- номер ошибки
--		@ERROR_MES						- сообщение об ошибке

ALTER PROCEDURE [dbo].[usp_PayDebitDocumentForm1ToSQLandIB] 
	@Earning_Guid					D_GUID,
	@Waybill_Id						D_ID,

  @FINDED_MONEY					D_MONEY output,
  @DOC_NUM							D_NAME output,
  @DOC_DATE							D_DATE output,
	@DOC_SALDO						D_MONEY output,
	@EARNING_SALDO				D_MONEY output,
	@EARNING_EXPENSE			D_MONEY output,
	@ERROR_NUM						int output,
	@ERROR_MES						nvarchar(4000) output

AS

BEGIN

	BEGIN TRY

    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';
		SET @FINDED_MONEY = 0;
		SET @DOC_SALDO = 0;
		SET @EARNING_SALDO = 0;
		SET @EARNING_EXPENSE = 0;
		SET @DOC_NUM = '';
		SET @DOC_DATE = NULL;

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

	    EXEC dbo.usp_PayDebitDocumentForm1InIB @Earning_Guid = @Earning_Guid, @Waybill_Id = @Waybill_Id,  @IBLINKEDSERVERNAME = NULL, 
				@FINDED_MONEY = @FINDED_MONEY output, @DOC_NUM = @DOC_NUM output, @DOC_DATE = @DOC_DATE output, @DOC_SALDO = @DOC_SALDO output,
				@EARNING_SALDO = @EARNING_SALDO output, @EARNING_EXPENSE = @EARNING_EXPENSE output,
			@ERROR_NUM = @ERROR_NUM output, @ERROR_MES = @ERROR_MES output;

		IF( @ERROR_NUM = 0 )
			BEGIN
				UPDATE [dbo].[T_Earning] SET [Earning_Expense] = @EARNING_EXPENSE WHERE Earning_Guid = @Earning_Guid;

				SET @strMessage = 'Проверена оплата задолженности. УИ платежа: ' + CONVERT( nvarchar(36), @Earning_Guid );
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

	IF( @ERROR_NUM = 0 )
		SET @ERROR_MES = 'Успешное завершение операции.';

	RETURN @ERROR_NUM;
END

GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Производит операцию Сторно по накладной в InterBase

-- Входные параметры
-- 
--		@Earning_Guid					- УИ платежа
--		@Waybill_Id						- УИ документа, подлежащего Сторно
--		@AMOUNT								- Сумма к сторнирования
--		@DATELASTPAID					- дата операции
--		@IBLINKEDSERVERNAME		- имя LINKEDSERVER для подключения к InterBase
--
-- Выходные параметры
--
--		@DEC_AMOUNT						- фактически проведённая сумма Сторно
--		@WAYBILL_AMOUNTPAID		- итоговая сумма оплаты накладной
--		@WAYBILL_SALDO				- сальдо накладной
--		@ERROR_NUM						- номер ошибки
--		@ERROR_MES						- сообщение об ошибке

CREATE PROCEDURE [dbo].[usp_DecPayDocumentForm1InIB]
	@Earning_Guid					D_GUID = NULL,
	@Waybill_Id						D_ID,
	@AMOUNT								D_MONEY,
	@DATELASTPAID					D_DATE,
	@IBLINKEDSERVERNAME		D_NAME = NULL,

  @DEC_AMOUNT						D_MONEY output,
  @WAYBILL_AMOUNTPAID		D_MONEY output,
  @WAYBILL_SALDO				D_MONEY output,
	@ERROR_NUM						int output,
	@ERROR_MES						nvarchar(4000) output
AS

BEGIN
  BEGIN TRY
    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';
		SET @DEC_AMOUNT = 0;
		SET @WAYBILL_AMOUNTPAID = 0;
		SET @WAYBILL_SALDO = 0;

		DECLARE @strBEGIN_DATE varchar(10);
		SET @strBEGIN_DATE = CONVERT (varchar(10), @DATELASTPAID, 104 );

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

    SET @ParmDefinition = N' @DEC_AMOUNT_Ib money output, @WAYBILL_AMOUNTPAID_Ib money output, @WAYBILL_SALDO_Ib money output, 
			@ErrorNum_Ib int output, @ErrorText_Ib varchar(480) output'; 				

		SET @SQLString = 'SELECT @DEC_AMOUNT_Ib = DEC_AMOUNT, 
			@WAYBILL_AMOUNTPAID_Ib = WAYBILL_AMOUNTPAID, @WAYBILL_SALDO_Ib = WAYBILL_SALDO, 
			@ErrorNum_Ib = ERROR_NUMBER, @ErrorText_Ib = ERROR_TEXT FROM OPENQUERY( ' + 
			@IBLINKEDSERVERNAME + ', ''SELECT DEC_AMOUNT, WAYBILL_AMOUNTPAID, WAYBILL_SALDO, ERROR_NUMBER, ERROR_TEXT FROM  USP_DECWAYBILLPAID_FROMSQL( ' + 
					cast( @Waybill_Id as nvarchar(20)) +  ', ' +
					cast( @AMOUNT as nvarchar(20)) +  ', ' +
					'''''' + cast( @strBEGIN_DATE as nvarchar(20)) + '''''' + ' )'' )'; 

		PRINT @SQLString;

    EXECUTE sp_executesql @SQLString, @ParmDefinition, @DEC_AMOUNT_Ib = @DEC_AMOUNT output, 
			@WAYBILL_AMOUNTPAID_Ib = @WAYBILL_AMOUNTPAID output, 
			@WAYBILL_SALDO_Ib = @WAYBILL_SALDO output, 
			@ErrorNum_Ib = @ERROR_NUM output, @ErrorText_Ib = @ERROR_MES output;  
		
	END TRY
	
	BEGIN CATCH
    SET @ERROR_NUM = ERROR_NUMBER();
    SET @ERROR_MES = @ERROR_MES + ' ' + ERROR_MESSAGE();
    
		RETURN @ERROR_NUM;
	END CATCH;

	IF( @ERROR_NUM = 0 )
		SET @ERROR_MES = 'Успешное завершение операции.';

	RETURN @ERROR_NUM;

END

GO
GRANT EXECUTE ON [dbo].[usp_DecPayDocumentForm1InIB] TO [public]
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Производит операцию Сторно по накладной

-- Входные параметры
-- 
--		@Earning_Guid					- УИ платежа
--		@Waybill_Id						- УИ документа, подлежащего Сторно
--		@AMOUNT								- Сумма к сторнирования
--		@DATELASTPAID					- дата операции
--		@IBLINKEDSERVERNAME		- имя LINKEDSERVER для подключения к InterBase
--
-- Выходные параметры
--
--		@DEC_AMOUNT						- фактически проведённая сумма Сторно
--		@WAYBILL_AMOUNTPAID		- итоговая сумма оплаты накладной
--		@WAYBILL_SALDO				- сальдо накладной
--		@ERROR_NUM						- номер ошибки
--		@ERROR_MES						- сообщение об ошибке

CREATE PROCEDURE [dbo].[usp_DecPayDocumentForm1ToSQLandIB] 
	@Earning_Guid					D_GUID = NULL,
	@Waybill_Id						D_ID,
	@AMOUNT								D_MONEY,
	@DATELASTPAID					D_DATE,
	@IBLINKEDSERVERNAME		D_NAME = NULL,

  @DEC_AMOUNT						D_MONEY output,
  @WAYBILL_AMOUNTPAID		D_MONEY output,
  @WAYBILL_SALDO				D_MONEY output,
	@ERROR_NUM						int output,
	@ERROR_MES						nvarchar(4000) output

AS

BEGIN

	BEGIN TRY
    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';
		SET @DEC_AMOUNT = 0;
		SET @WAYBILL_AMOUNTPAID = 0;
		SET @WAYBILL_SALDO = 0;

		IF( @Earning_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT Earning_Guid FROM dbo.[T_Earning] WHERE Earning_Guid = @Earning_Guid )
				BEGIN
					SET @ERROR_NUM = 1;
					SET @ERROR_MES = 'В базе данных не найден платёж с указанным идентификатором: ' + CAST( @Earning_Guid as nvarchar(36) );

					RETURN @ERROR_NUM;
				END       
    
    BEGIN TRANSACTION UpdateData;

	    EXEC dbo.usp_DecPayDocumentForm1InIB @Earning_Guid = @Earning_Guid, @Waybill_Id = @Waybill_Id, 
				@AMOUNT = @AMOUNT, @DATELASTPAID = @DATELASTPAID, @IBLINKEDSERVERNAME = NULL, 
				@DEC_AMOUNT = @DEC_AMOUNT output, @WAYBILL_AMOUNTPAID = @WAYBILL_AMOUNTPAID output, 
				@WAYBILL_SALDO = @WAYBILL_SALDO output, 
				@ERROR_NUM = @ERROR_NUM output, @ERROR_MES = @ERROR_MES output;

		IF( @ERROR_NUM = 0 )
			BEGIN
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

		RETURN @ERROR_NUM;
	END CATCH;

	IF( @ERROR_NUM = 0 )
		SET @ERROR_MES = 'Успешное завершение операции.';

	RETURN @ERROR_NUM;
END

GO
GRANT EXECUTE ON [dbo].[usp_DecPayDocumentForm1ToSQLandIB] TO [public]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- Возвращает список документов по ф1
--
-- Входные параметры
--
--		@Customer_Guid			- УИ клиента-плательщика
--		@Company_Guid				- УИ компании-получателя платежа
--		@Begin_Date					- начало периода для поиска
--		@End_Date						- конец периода для поиска
--		@Waybill_Num				- номер накладной
--		@IBLINKEDSERVERNAME	- имя LinkedServer
--
-- Выходные параметры
--
--		@ERROR_NUM					- код ошбики
--		@ERROR_MES					- сообщение об ошибке
--
CREATE PROCEDURE [dbo].[usp_GetDocForm1ForDecPaymentFromIB] 
	@Customer_Guid			D_GUID = NULL,
	@Company_Guid				D_GUID,
  @Begin_Date					D_DATE,
	@End_Date						D_DATE,
	@Waybill_Num				D_NAME = '',
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

    DECLARE @CUSTOMER_ID int;
    DECLARE @COMPANY_ID int;
    DECLARE @CURRENCY_CODE nvarchar(3);
    DECLARE @ONLY_WAYBILL_SHIPMODE0 int;
		DECLARE @PAYMENTFORM_ID int;

		DECLARE @strBEGIN_DATE varchar(10);
		SET @strBEGIN_DATE = CONVERT (varchar(10), @Begin_Date, 104 );
		DECLARE @strEND_DATE varchar(10);
		SET @strEND_DATE = CONVERT (varchar(10), @End_Date, 104 );

		SET @CURRENCY_CODE = 'BYB';
		SET @ONLY_WAYBILL_SHIPMODE0 = 1;
		SET @PAYMENTFORM_ID = 1;
		SELECT @COMPANY_ID = Company_Id FROM T_Company WHERE Company_Guid = @Company_Guid;

		IF( @Customer_Guid IS NOT NULL )
			BEGIN
				SELECT @CUSTOMER_ID = Customer_Id FROM T_Customer WHERE Customer_Guid = @Customer_Guid;
				IF( @CUSTOMER_ID IS NULL )
					BEGIN
						SET @ERROR_NUM = 1;
						SET @ERROR_MES = 'В базе данных не найден клиент с указанным идентификатором: ' + CAST( @Customer_Guid as nvarchar(36) );
					END
			END
		ELSE
			SET @CUSTOMER_ID = 0;

		if( @COMPANY_ID IS NULL )
			BEGIN
				SET @ERROR_NUM = 2;
				SET @ERROR_MES = 'В базе данных не найдена компания с указанным идентификатором: ' + CAST( @Company_Guid as nvarchar(36) );
			END

		if( @CURRENCY_CODE IS NULL )
			BEGIN
				SET @ERROR_NUM = 3;
				SET @ERROR_MES = 'В базе данных не найдена идентификатор валюты.';
			END

		CREATE TABLE #DocForm1( CURRENCY_CODE NVARCHAR(3),  WAYBILL_ID INT,  WAYBILL_SHIPPED INT,  WAYBILL_NUM NVARCHAR(16),
			CUSTOMER_ID INT,  DEPART_CODE NVARCHAR(8), CUSTOMER_NAME NVARCHAR(100),  WAYBILL_BEGINDATE DATE,   WAYBILL_SHIPDATE DATE,
			WAYBILL_ALLPRICE FLOAT,  WAYBILL_TOTALPRICE FLOAT,  WAYBILL_RETALLPRICE FLOAT,  WAYBILL_AMOUNTPAID FLOAT,  WAYBILL_DATELASTPAID DATE,
			WAYBILL_SALDO FLOAT,  WAYBILL_CURRENCYALLPRICE FLOAT,  WAYBILL_CURRENCYTOTALPRICE FLOAT,  WAYBILL_CURRENCYAMOUNTPAID FLOAT,
			WAYBILL_CURRENCYSALDO FLOAT, STOCK_ID INT,  CHILDCUST_ID INT,  QUANTITY INT,  COMPANY_ID INT,  PAYMENTFORM_ID INT,
			WAYBILL_EXPORTMODE INT,  WAYBILL_RETURN INT,  WAYBILL_USDRATE FLOAT,  WAYBILL_MONEYBONUS INT, WAYBILL_SHIPMODE INT,
			WAYBILL_SHIPMODE_NAME NVARCHAR(100),  STOCK_NAME NVARCHAR(32), COMPANY_ACRONYM NVARCHAR(3) );

		SELECT @sql_text = dbo.GetTextQueryForSelectFromInterbase( null, null, 
			' SELECT  CURRENCY_CODE, WAYBILL_ID, WAYBILL_SHIPPED, WAYBILL_NUM, CUSTOMER_ID,
				DEPART_CODE, CUSTOMER_NAME, WAYBILL_BEGINDATE, WAYBILL_SHIPDATE, WAYBILL_ALLPRICE,
				WAYBILL_TOTALPRICE, WAYBILL_RETALLPRICE, WAYBILL_AMOUNTPAID, WAYBILL_DATELASTPAID,
				WAYBILL_SALDO, WAYBILL_CURRENCYALLPRICE, WAYBILL_CURRENCYTOTALPRICE,
				WAYBILL_CURRENCYAMOUNTPAID, WAYBILL_CURRENCYSALDO, STOCK_ID, CHILDCUST_ID,
				QUANTITY, COMPANY_ID, PAYMENTFORM_ID, WAYBILL_EXPORTMODE, WAYBILL_RETURN,
				WAYBILL_USDRATE, WAYBILL_MONEYBONUS, WAYBILL_SHIPMODE, WAYBILL_SHIPMODE_NAME,
				STOCK_NAME, COMPANY_ACRONYM 
			FROM SP_GETWAYBILL( ' + '''''' + cast( @strBEGIN_DATE as nvarchar(20)) + '''''' + ', ' +
			'''''' + cast( @strEND_DATE as nvarchar(20)) + '''''' + ', ' +
			cast( @COMPANY_ID as nvarchar(10) ) + ', ' + 
			cast( @CUSTOMER_ID as nvarchar(10) ) + ', ' + 
			'''''' + cast( @Waybill_Num as nvarchar(20)) + '''''' + ', ' +
			cast( @PAYMENTFORM_ID as nvarchar(10) ) +  ' )');
			SET @sql_text = ' INSERT INTO #DocForm1( CURRENCY_CODE, WAYBILL_ID, WAYBILL_SHIPPED, WAYBILL_NUM, CUSTOMER_ID,
    DEPART_CODE, CUSTOMER_NAME, WAYBILL_BEGINDATE, WAYBILL_SHIPDATE, WAYBILL_ALLPRICE,
    WAYBILL_TOTALPRICE, WAYBILL_RETALLPRICE, WAYBILL_AMOUNTPAID, WAYBILL_DATELASTPAID,
    WAYBILL_SALDO, WAYBILL_CURRENCYALLPRICE, WAYBILL_CURRENCYTOTALPRICE,
    WAYBILL_CURRENCYAMOUNTPAID, WAYBILL_CURRENCYSALDO, STOCK_ID, CHILDCUST_ID,
    QUANTITY, COMPANY_ID, PAYMENTFORM_ID, WAYBILL_EXPORTMODE, WAYBILL_RETURN,
    WAYBILL_USDRATE, WAYBILL_MONEYBONUS, WAYBILL_SHIPMODE, WAYBILL_SHIPMODE_NAME,
    STOCK_NAME, COMPANY_ACRONYM ) ' + @sql_text;  

		PRINT @sql_text;

		execute sp_executesql @sql_text;
		
		SELECT CURRENCY_CODE, WAYBILL_ID, WAYBILL_SHIPPED, WAYBILL_NUM, CUSTOMER_ID,
				DEPART_CODE, CUSTOMER_NAME, WAYBILL_BEGINDATE, WAYBILL_SHIPDATE, WAYBILL_ALLPRICE,
				WAYBILL_TOTALPRICE, WAYBILL_RETALLPRICE, WAYBILL_AMOUNTPAID, WAYBILL_DATELASTPAID,
				WAYBILL_SALDO, WAYBILL_CURRENCYALLPRICE, WAYBILL_CURRENCYTOTALPRICE,
				WAYBILL_CURRENCYAMOUNTPAID, WAYBILL_CURRENCYSALDO, STOCK_ID, CHILDCUST_ID,
				QUANTITY, COMPANY_ID, PAYMENTFORM_ID, WAYBILL_EXPORTMODE, WAYBILL_RETURN,
				WAYBILL_USDRATE, WAYBILL_MONEYBONUS, WAYBILL_SHIPMODE, WAYBILL_SHIPMODE_NAME,
				STOCK_NAME, COMPANY_ACRONYM
		FROM #DocForm1
		WHERE WAYBILL_AMOUNTPAID > 0
		--WHERE Abs( WAYBILL_SALDO ) <> ( WAYBILL_TOTALPRICE - WAYBILL_RETALLPRICE )
		ORDER BY WAYBILL_BEGINDATE;
		
		DROP TABLE #DocForm1;
		
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
GRANT EXECUTE ON [dbo].[usp_GetDocForm1ForDecPaymentFromIB] TO [public]
GO
