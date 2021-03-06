USE [ERP_Mercury]
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
CREATE PROCEDURE [dbo].[usp_GetCEarningHistoryFromIB] 
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
			WAYBILL_SHIPDATE date,  CUSTOMER_ID int, CUSTOMER_NAME nvarchar(100), WAYBILL_CURRENCYTOTALPRICE float,
			WAYBILL_CURRENCYSALDO float, PAYMENTS_VALUE float, WAYBILL_BONUS int,  WAYBILL_SHIPPED int, 
			COMPANY_ID int, COMPANY_NAME nvarchar(32), COMPANY_ACRONYM  nvarchar(3),
			CHILDCUST_ID int,  CHILDCUST_CODE varchar(8), CHILDCUST_NAME varchar(32), 
			CURRENCY_CODE nvarchar(3), PAYMENTS_OPERDATE date, BANKDATE date );

		SELECT @sql_text = dbo.GetTextQueryForSelectFromInterbase( null, null, 
			' SELECT WAYBILL_ID,  WAYBILL_NUM, WAYBILL_SHIPDATE,  CUSTOMER_ID, CUSTOMER_NAME, WAYBILL_CURRENCYTOTALPRICE,
				WAYBILL_CURRENCYSALDO, PAYMENTS_VALUE, WAYBILL_BONUS,  WAYBILL_SHIPPED, 
				COMPANY_ID, COMPANY_NAME, COMPANY_ACRONYM, CHILDCUST_ID,  CHILDCUST_CODE, CHILDCUST_NAME, 
				CURRENCY_CODE, PAYMENTS_OPERDATE, BANKDATE
			FROM SP_CEARNINGHISTORY( ' + cast( @EARNING_ID as nvarchar(10) ) + ' )');
			SET @sql_text = ' INSERT INTO #EarningHistory(  WAYBILL_ID,  WAYBILL_NUM, WAYBILL_SHIPDATE,  CUSTOMER_ID, CUSTOMER_NAME, WAYBILL_CURRENCYTOTALPRICE,
				WAYBILL_CURRENCYSALDO, PAYMENTS_VALUE, WAYBILL_BONUS,  WAYBILL_SHIPPED, 
				COMPANY_ID, COMPANY_NAME, COMPANY_ACRONYM, CHILDCUST_ID,  CHILDCUST_CODE, CHILDCUST_NAME, 
				CURRENCY_CODE, PAYMENTS_OPERDATE, BANKDATE ) ' + @sql_text;  
	    
		PRINT @sql_text;

		execute sp_executesql @sql_text;
		
		SELECT  WAYBILL_ID,  WAYBILL_NUM, WAYBILL_SHIPDATE,  CUSTOMER_ID, CUSTOMER_NAME, WAYBILL_CURRENCYTOTALPRICE,
				WAYBILL_CURRENCYSALDO, PAYMENTS_VALUE, WAYBILL_BONUS,  WAYBILL_SHIPPED, 
				COMPANY_ID, COMPANY_NAME, COMPANY_ACRONYM, CHILDCUST_ID,  CHILDCUST_CODE, CHILDCUST_NAME, 
				CURRENCY_CODE, PAYMENTS_OPERDATE, BANKDATE
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
GRANT EXECUTE ON [dbo].[usp_GetCEarningHistoryFromIB] TO [public]
GO

/****** Object:  StoredProcedure [dbo].[usp_DecPayDocumentForm1InIB]    Script Date: 29.04.2013 18:10:01 ******/
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
--		@WAYBILL_CURRENCYAMOUNTPAID		- итоговая сумма оплаты накладной
--		@WAYBILL_CURRENCYSALDO				- сальдо накладной
--		@ERROR_NUM						- номер ошибки
--		@ERROR_MES						- сообщение об ошибке

CREATE PROCEDURE [dbo].[usp_DecPayDocumentForm2InIB]
	@Earning_Guid									D_GUID = NULL,
	@Waybill_Id										D_ID,
	@AMOUNT												D_MONEY,
	@DATELASTPAID									D_DATE,
	@IBLINKEDSERVERNAME						D_NAME = NULL,

  @DEC_AMOUNT										D_MONEY output,
  @WAYBILL_CURRENCYAMOUNTPAID		D_MONEY output,
  @WAYBILL_CURRENCYSALDO				D_MONEY output,
	@ERROR_NUM										int output,
	@ERROR_MES										nvarchar(4000) output
AS

BEGIN
  BEGIN TRY
    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';
		SET @DEC_AMOUNT = 0;
		SET @WAYBILL_CURRENCYAMOUNTPAID = 0;
		SET @WAYBILL_CURRENCYSALDO = 0;

		IF( @Earning_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT Earning_Guid FROM dbo.[T_Earning] WHERE Earning_Guid = @Earning_Guid )
				BEGIN
					SET @ERROR_NUM = 1;
					SET @ERROR_MES = 'В базе данных не найден платёж с указанным идентификатором: ' + CAST( @Earning_Guid as nvarchar(36) );

					RETURN @ERROR_NUM;
				END       
		
		DECLARE @EARNING_ID			D_ID;
		DECLARE	@CURRENCY_CODE	D_CURRENCYCODE;

		SELECT @EARNING_ID = Earning.Earning_Id
		FROM dbo.[T_Earning] AS Earning
		WHERE Earning.Earning_Guid = @Earning_Guid;

	  IF( @IBLINKEDSERVERNAME IS NULL ) SELECT @IBLINKEDSERVERNAME = dbo.GetIBLinkedServerName();
	  
    DECLARE @SQLString nvarchar( 2048 );
    DECLARE @ParmDefinition nvarchar( 500 );

    SET @ParmDefinition = N' @DEC_AMOUNT_Ib money output, @WAYBILL_CURRENCYAMOUNTPAID_Ib money output, @WAYBILL_CURRENCYSALDO_Ib money output, 
			@ErrorNum_Ib int output, @ErrorText_Ib varchar(480) output'; 				

		SET @SQLString = 'SELECT @DEC_AMOUNT_Ib = DEC_AMOUNT, 
			@WAYBILL_CURRENCYAMOUNTPAID_Ib = WAYBILL_CURRENCYAMOUNTPAID, @WAYBILL_CURRENCYSALDO_Ib = WAYBILL_CURRENCYSALDO, 
			@ErrorNum_Ib = ERROR_NUMBER, @ErrorText_Ib = ERROR_TEXT FROM OPENQUERY( ' + 
			@IBLINKEDSERVERNAME + ', ''SELECT DEC_AMOUNT, WAYBILL_CURRENCYAMOUNTPAID, WAYBILL_CURRENCYSALDO, ERROR_NUMBER, ERROR_TEXT FROM  USP_DECCWAYBILLPAID_FROMSQL( ' + 
					cast( @Waybill_Id as nvarchar(20)) +  ', ' +
					cast( @AMOUNT as nvarchar(20)) +  ', ' +
					'''''' + cast( @DATELASTPAID as nvarchar(10)) + '''''' + ' )'' )'; 

		PRINT @SQLString;

    EXECUTE sp_executesql @SQLString, @ParmDefinition, @DEC_AMOUNT_Ib = @DEC_AMOUNT output, 
			@WAYBILL_CURRENCYAMOUNTPAID_Ib = @WAYBILL_CURRENCYAMOUNTPAID output, 
			@WAYBILL_CURRENCYSALDO_Ib = @WAYBILL_CURRENCYSALDO output, 
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
GRANT EXECUTE ON [dbo].[usp_DecPayDocumentForm2InIB] TO [public]
GO

/****** Object:  StoredProcedure [dbo].[usp_DecPayDocumentForm1ToSQLandIB]    Script Date: 29.04.2013 18:38:35 ******/
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
--		@DEC_AMOUNT										- фактически проведённая сумма Сторно
--		@WAYBILL_CURRENCYAMOUNTPAID		- итоговая сумма оплаты накладной
--		@WAYBILL_CURRENCYSALDO				- сальдо накладной
--		@ERROR_NUM										- номер ошибки
--		@ERROR_MES										- сообщение об ошибке

CREATE PROCEDURE [dbo].[usp_DecPayDocumentForm2ToSQLandIB] 
	@Earning_Guid									D_GUID = NULL,
	@Waybill_Id										D_ID,
	@AMOUNT												D_MONEY,
	@DATELASTPAID									D_DATE,
	@IBLINKEDSERVERNAME						D_NAME = NULL,

  @DEC_AMOUNT										D_MONEY output,
  @WAYBILL_CURRENCYAMOUNTPAID		D_MONEY output,
  @WAYBILL_CURRENCYSALDO				D_MONEY output,
	@ERROR_NUM										int output,
	@ERROR_MES										nvarchar(4000) output

AS

BEGIN

	BEGIN TRY
    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';
		SET @DEC_AMOUNT = 0;
		SET @WAYBILL_CURRENCYAMOUNTPAID = 0;
		SET @WAYBILL_CURRENCYSALDO = 0;

		IF( @Earning_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT Earning_Guid FROM dbo.[T_Earning] WHERE Earning_Guid = @Earning_Guid )
				BEGIN
					SET @ERROR_NUM = 1;
					SET @ERROR_MES = 'В базе данных не найден платёж с указанным идентификатором: ' + CAST( @Earning_Guid as nvarchar(36) );

					RETURN @ERROR_NUM;
				END       
    
    BEGIN TRANSACTION UpdateData;

	    EXEC dbo.usp_DecPayDocumentForm2InIB @Earning_Guid = @Earning_Guid, @Waybill_Id = @Waybill_Id, 
				@AMOUNT = @AMOUNT, @DATELASTPAID = @DATELASTPAID, @IBLINKEDSERVERNAME = NULL, 
				@DEC_AMOUNT = @DEC_AMOUNT output, @WAYBILL_CURRENCYAMOUNTPAID = @WAYBILL_CURRENCYAMOUNTPAID output, 
				@WAYBILL_CURRENCYSALDO = @WAYBILL_CURRENCYSALDO output, 
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
GRANT EXECUTE ON [dbo].[usp_DecPayDocumentForm2ToSQLandIB] TO [public]
GO

/****** Object:  StoredProcedure [dbo].[usp_GetDocForm1ForDecPaymentFromIB]    Script Date: 30.04.2013 10:55:17 ******/
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
ALTER PROCEDURE [dbo].[usp_GetDocForm1ForDecPaymentFromIB] 
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
			'''''' + '''''' + ', ' +
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
--		WHERE Abs( WAYBILL_SALDO ) <> ( WAYBILL_TOTALPRICE - WAYBILL_RETALLPRICE )
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

/****** Object:  StoredProcedure [dbo].[usp_GetDocForm1ForDecPaymentFromIB]    Script Date: 30.04.2013 10:55:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- Возвращает список оплаченных документов по ф2
--
-- Входные параметры
--
--		@Customer_Guid			- УИ клиента-плательщика
--		@ChildDepart_Guid		- УИ дочернего клиента
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
CREATE PROCEDURE [dbo].[usp_GetDocForm2ForDecPaymentFromIB] 
	@Customer_Guid			D_GUID = NULL,
	@ChildDepart_Guid		D_GUID = NULL,
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
    DECLARE @CHILDCUST_CODE nvarchar(8) = '';
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
		SET @PAYMENTFORM_ID = 2;
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

		IF( @ChildDepart_Guid IS NOT NULL )
			BEGIN
				SELECT @CHILDCUST_CODE = [ChildDepart_Code] FROM [dbo].[T_ChildDepart] WHERE [ChildDepart_Guid] = @ChildDepart_Guid;
				IF( @CHILDCUST_CODE IS NULL )
					BEGIN
						SET @ERROR_NUM = 1;
						SET @ERROR_MES = 'В базе данных не найден дочерний клиент с указанным идентификатором: ' + CAST( @ChildDepart_Guid as nvarchar(36) );
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
			WAYBILL_SHIPMODE_NAME NVARCHAR(100),  STOCK_NAME NVARCHAR(32), COMPANY_ACRONYM NVARCHAR(3), CHILDCUST_NAME NVARCHAR(32) );

		SELECT @sql_text = dbo.GetTextQueryForSelectFromInterbase( null, null, 
			' SELECT  CURRENCY_CODE, WAYBILL_ID, WAYBILL_SHIPPED, WAYBILL_NUM, CUSTOMER_ID,
				DEPART_CODE, CUSTOMER_NAME, WAYBILL_BEGINDATE, WAYBILL_SHIPDATE, WAYBILL_ALLPRICE,
				WAYBILL_TOTALPRICE, WAYBILL_RETALLPRICE, WAYBILL_AMOUNTPAID, WAYBILL_DATELASTPAID,
				WAYBILL_SALDO, WAYBILL_CURRENCYALLPRICE, WAYBILL_CURRENCYTOTALPRICE,
				WAYBILL_CURRENCYAMOUNTPAID, WAYBILL_CURRENCYSALDO, STOCK_ID, CHILDCUST_ID,
				QUANTITY, COMPANY_ID, PAYMENTFORM_ID, WAYBILL_EXPORTMODE, WAYBILL_RETURN,
				WAYBILL_USDRATE, WAYBILL_MONEYBONUS, WAYBILL_SHIPMODE, WAYBILL_SHIPMODE_NAME,
				STOCK_NAME, COMPANY_ACRONYM, CHILDCUST_NAME 
			FROM SP_GETWAYBILL( ' + '''''' + cast( @strBEGIN_DATE as nvarchar(20)) + '''''' + ', ' +
			'''''' + cast( @strEND_DATE as nvarchar(20)) + '''''' + ', ' +
			cast( @COMPANY_ID as nvarchar(10) ) + ', ' + 
			cast( @CUSTOMER_ID as nvarchar(10) ) + ', ' + 
			'''''' + cast( @CHILDCUST_CODE as nvarchar(8)) + '''''' + ', ' +
			'''''' + cast( @Waybill_Num as nvarchar(20)) + '''''' + ', ' +
			cast( @PAYMENTFORM_ID as nvarchar(10) ) +  ' )');
			SET @sql_text = ' INSERT INTO #DocForm1( CURRENCY_CODE, WAYBILL_ID, WAYBILL_SHIPPED, WAYBILL_NUM, CUSTOMER_ID,
    DEPART_CODE, CUSTOMER_NAME, WAYBILL_BEGINDATE, WAYBILL_SHIPDATE, WAYBILL_ALLPRICE,
    WAYBILL_TOTALPRICE, WAYBILL_RETALLPRICE, WAYBILL_AMOUNTPAID, WAYBILL_DATELASTPAID,
    WAYBILL_SALDO, WAYBILL_CURRENCYALLPRICE, WAYBILL_CURRENCYTOTALPRICE,
    WAYBILL_CURRENCYAMOUNTPAID, WAYBILL_CURRENCYSALDO, STOCK_ID, CHILDCUST_ID,
    QUANTITY, COMPANY_ID, PAYMENTFORM_ID, WAYBILL_EXPORTMODE, WAYBILL_RETURN,
    WAYBILL_USDRATE, WAYBILL_MONEYBONUS, WAYBILL_SHIPMODE, WAYBILL_SHIPMODE_NAME,
    STOCK_NAME, COMPANY_ACRONYM, CHILDCUST_NAME ) ' + @sql_text;  

		PRINT @sql_text;

		execute sp_executesql @sql_text;
		
		SELECT CURRENCY_CODE, WAYBILL_ID, WAYBILL_SHIPPED, WAYBILL_NUM, CUSTOMER_ID,
				DEPART_CODE, CUSTOMER_NAME, WAYBILL_BEGINDATE, WAYBILL_SHIPDATE, WAYBILL_ALLPRICE,
				WAYBILL_TOTALPRICE, WAYBILL_RETALLPRICE, WAYBILL_AMOUNTPAID, WAYBILL_DATELASTPAID,
				WAYBILL_SALDO, WAYBILL_CURRENCYALLPRICE, WAYBILL_CURRENCYTOTALPRICE,
				WAYBILL_CURRENCYAMOUNTPAID, WAYBILL_CURRENCYSALDO, STOCK_ID, CHILDCUST_ID,
				QUANTITY, COMPANY_ID, PAYMENTFORM_ID, WAYBILL_EXPORTMODE, WAYBILL_RETURN,
				WAYBILL_USDRATE, WAYBILL_MONEYBONUS, WAYBILL_SHIPMODE, WAYBILL_SHIPMODE_NAME,
				STOCK_NAME, COMPANY_ACRONYM, CHILDCUST_NAME
		FROM #DocForm1
		WHERE WAYBILL_CURRENCYAMOUNTPAID > 0
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
GRANT EXECUTE ON [dbo].[usp_GetDocForm2ForDecPaymentFromIB] TO [public]
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- Возвращает список документов по ф2 для оплаты в ручном режиме
--
-- Входные параметры
--
--		@Customer_Guid			- УИ клиента-плательщика
--		@ChildDepart_Guid		- УИ дочернего клиента
--		@Company_Guid				- УИ компании-получателя платежа
--		@IBLINKEDSERVERNAME	- имя LinkedServer
--
-- Выходные параметры
--
--		@ERROR_NUM					- код ошбики
--		@ERROR_MES					- сообщение об ошибке
--
CREATE PROCEDURE [dbo].[usp_GetDocForm2ForPaymentFromIB] 
	@Customer_Guid			D_GUID,
	@ChildDepart_Guid		D_GUID,
	@Company_Guid				D_GUID,
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
  
	declare @sql_text nvarchar( 1000);
	
	BEGIN TRY

    DECLARE @CUSTOMER_ID int;
		DECLARE @CHILDCUST_CODE nvarchar(8) = '';
    DECLARE @COMPANY_ID int;
    DECLARE @CURRENCY_CODE nvarchar(3);
    DECLARE @ONLY_WAYBILL_SHIPMODE0 int;

		DECLARE @strBEGIN_DATE varchar(10);
		SET @strBEGIN_DATE = CONVERT (varchar(10), @Begin_Date, 104 );
		DECLARE @strEND_DATE varchar(10);
		SET @strEND_DATE = CONVERT (varchar(10), @End_Date, 104 );

		SELECT @CUSTOMER_ID = Customer_Id FROM T_Customer WHERE Customer_Guid = @Customer_Guid;
		SELECT @COMPANY_ID = Company_Id FROM T_Company WHERE Company_Guid = @Company_Guid;
		SELECT @CHILDCUST_CODE = [ChildDepart_Code] FROM [dbo].[T_ChildDepart] WHERE [ChildDepart_Guid] = @ChildDepart_Guid;

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

		if( @CHILDCUST_CODE IS NULL )
			BEGIN
				SET @ERROR_NUM = 3;
				SET @ERROR_MES = 'В базе данных не найден дочерний клиент с указанным идентификатором: ' + CAST( @ChildDepart_Guid as nvarchar(36) );
			END


		CREATE TABLE #DocForm2ForPayment( SRC int, WAYBILL_ID int,  WAYBILL_NUM nvarchar(16),
			WAYBILL_BEGINDATE date, WAYBILL_SHIPDATE date, CUSTOMER_NAME nvarchar(100), WAYBILL_TOTALPRICE float,
			WAYBILL_ENDDATE date,  WAYBILL_AMOUNTPAID float, WAYBILL_DATELASTPAID date,
			WAYBILL_SALDO float,  STOCK_NAME nvarchar(32),  WAYBILL_SHIPMODE int,
			WAYBILL_SHIPMODE_NAME nvarchar(100), WAYBILL_MONEYBONUS int, CHILDCUST_ID int, 
			CHILDCUST_CODE nvarchar(8), CHILDCUST_NAME nvarchar(32), WAYBILL_QUANTITY float  );

		SELECT @sql_text = dbo.GetTextQueryForSelectFromInterbase( null, null, 
			' SELECT SRC, WAYBILL_ID,  WAYBILL_NUM,  WAYBILL_BEGINDATE,
				CUSTOMER_NAME, WAYBILL_TOTALPRICE, WAYBILL_ENDDATE, WAYBILL_SHIPDATE,
				WAYBILL_AMOUNTPAID, WAYBILL_DATELASTPAID, WAYBILL_SALDO,
				STOCK_NAME,  WAYBILL_SHIPMODE, WAYBILL_SHIPMODE_NAME, 
				WAYBILL_MONEYBONUS, CHILDCUST_ID, CHILDCUST_CODE,  CHILDCUST_NAME, WAYBILL_QUANTITY
			FROM SP_GETDOCFORPAYMENT2( ' + cast( @CUSTOMER_ID as nvarchar(10) ) + ', ' + 
				'''''' + cast( @CHILDCUST_CODE as nvarchar(8)) + '''''' + ', ' +
			  cast( @COMPANY_ID as nvarchar(10) ) + ', ' +
				'''''' + cast( @strBEGIN_DATE as nvarchar(20)) + '''''' + ', ' +
				'''''' + cast( @strEND_DATE as nvarchar(20)) + '''''' +  ' )');
			SET @sql_text = ' INSERT INTO #DocForm2ForPayment( SRC, WAYBILL_ID,  WAYBILL_NUM,  WAYBILL_BEGINDATE, WAYBILL_SHIPDATE,
				CUSTOMER_NAME, WAYBILL_TOTALPRICE, WAYBILL_ENDDATE,
				WAYBILL_AMOUNTPAID, WAYBILL_DATELASTPAID, WAYBILL_SALDO,
				STOCK_NAME,  WAYBILL_SHIPMODE, WAYBILL_SHIPMODE_NAME, 
				WAYBILL_MONEYBONUS, CHILDCUST_ID, CHILDCUST_CODE,  CHILDCUST_NAME, WAYBILL_QUANTITY ) ' + @sql_text;  
	    
		PRINT @sql_text;

		execute sp_executesql @sql_text;
		
		SELECT SRC, WAYBILL_ID,  WAYBILL_NUM,  WAYBILL_BEGINDATE, WAYBILL_SHIPDATE,
				CUSTOMER_NAME, WAYBILL_TOTALPRICE, WAYBILL_ENDDATE,
				WAYBILL_AMOUNTPAID, WAYBILL_DATELASTPAID, WAYBILL_SALDO,
				STOCK_NAME,  WAYBILL_SHIPMODE, WAYBILL_SHIPMODE_NAME, 
				WAYBILL_MONEYBONUS, CHILDCUST_ID, CHILDCUST_CODE,  CHILDCUST_NAME, WAYBILL_QUANTITY
		FROM #DocForm2ForPayment
		ORDER BY WAYBILL_SHIPDATE;
		
		DROP TABLE #DocForm2ForPayment;
		
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
GRANT EXECUTE ON [dbo].[usp_GetDocForm2ForPaymentFromIB] TO [public]
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Регистрирует оплату задолженности в InterBase по форме оплаты 2
-- Платёж разносится на документы по дате их отгрузки, начиная с сомого раннего

-- Входные параметры
-- 
--		@Earning_Guid					- УИ платежа
--		@IBLINKEDSERVERNAME		- имя LINKEDSERVER для подключения к InterBase
--
-- Выходные параметры
--
--		@EARNING_SALDO				- сальдо платежа
--		@EARNING_EXPENSE			- сумма расхода платежа
--		@ERROR_NUM						- номер ошибки
--		@ERROR_MES						- сообщение об ошибке

CREATE PROCEDURE [dbo].[usp_PayDebitDocumentsForm2InIB]
	@Earning_Guid					D_GUID,
	@IBLINKEDSERVERNAME		D_NAME = NULL,

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
		
		DECLARE @CEARNING_ID D_ID;

		SELECT @CEARNING_ID = [Earning_Id], @EARNING_EXPENSE = [Earning_Expense], @EARNING_SALDO = [Earning_Saldo]
		FROM dbo.[T_Earning] WHERE Earning_Guid = @Earning_Guid;

    DECLARE @EventID D_ID = NULL;
    DECLARE @ParentEventID D_ID = NULL;
    DECLARE @strMessage D_EVENTMSG = '';
    DECLARE @EventSrc D_NAME = 'Оплата задолженности в IB';

	  IF( @IBLINKEDSERVERNAME IS NULL ) SELECT @IBLINKEDSERVERNAME = dbo.GetIBLinkedServerName();
	  
    DECLARE @SQLString nvarchar( 2048 );
    DECLARE @ParmDefinition nvarchar( 500 );

    SET @ParmDefinition = N' @ID_START_Ib int output, @ID_END_Ib int output, 
			@EARNING_SALDO_Ib money output, @EARNING_EXPENSE_Ib money output, 
			@ErrorNum_Ib int output, @ErrorText_Ib varchar(480) output'; 				

		SET @SQLString = 'SELECT @ID_START_Ib = ID_START, @ID_END_Ib = ID_END, 
		 @EARNING_SALDO_Ib = EARNING_SALDO, @EARNING_EXPENSE_Ib = EARNING_EXPENSE, 
		 @ErrorNum_Ib = ERROR_NUMBER, @ErrorText_Ib = ERROR_TEXT FROM OPENQUERY( ' + 
			@IBLINKEDSERVERNAME + ', ''SELECT ID_START, ID_END, EARNING_SALDO, EARNING_EXPENSE, ERROR_NUMBER, ERROR_TEXT FROM USP_SETTLECUSTOMERCWAYBILLS_FROMSQL( ' + 
					cast( @CEARNING_ID as nvarchar(20)) +  ' )'' )'; 

		PRINT @ParmDefinition;

		PRINT @SQLString;
					
		PRINT Len(@SQLString);

    EXECUTE sp_executesql @SQLString, @ParmDefinition, @ID_START_Ib = @ID_START output, @ID_END_Ib = @ID_END output, 
			@EARNING_SALDO_Ib = @EARNING_SALDO output, @EARNING_EXPENSE_Ib = @EARNING_EXPENSE,
			@ErrorNum_Ib = @ERROR_NUM output, @ErrorText_Ib = @ERROR_MES output;  
		
	END TRY
	
	BEGIN CATCH
    SET @ERROR_NUM = ERROR_NUMBER();
    SET @ERROR_MES = @ERROR_MES + ' ' + ERROR_MESSAGE();
    SET @strMessage = @ERROR_MES + ' ' + @CEARNING_ID;
    
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
GRANT EXECUTE ON [dbo].[usp_PayDebitDocumentsForm2InIB] TO [public]
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

CREATE PROCEDURE [dbo].[usp_PayDebitDocumentsForm2ToSQLandIB] 
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
				UPDATE [dbo].[T_Earning] SET [Earning_Expense] = @EARNING_EXPENSE WHERE Earning_Guid = @Earning_Guid;

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

	IF( @ERROR_NUM = 0 )
		SET @ERROR_MES = 'Успешное завершение операции.';

	RETURN @ERROR_NUM;
END

GO
GRANT EXECUTE ON [dbo].[usp_PayDebitDocumentsForm2ToSQLandIB] TO [public]
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Регистрирует оплату задолженности в InterBase по форме 2

-- Входные параметры
-- 
--		@Waybill_Id						- УИ документа, подлежащего оплате
--		@ChildDepart_Guid			- УИ дочернего клиента
--		@IBLINKEDSERVERNAME		- имя LINKEDSERVER для подключения к InterBase
--
-- Выходные параметры
--
--		@FINDED_MONEY									- сумма разноски
--		@DOCUMENT_NUM									- номер оплаченного документа
--		@DOCUMENT_DATE								- дата оплаченного документа
--		@DOCUMENT_CURRENCYSALDO				- сальдо оплаченного документа
--		@DOCUMENT_CURRENCYAMOUNTPAID	- итого оплачено по документу
--		@ERROR_NUM										- номер ошибки
--		@ERROR_MES										- сообщение об ошибке

CREATE PROCEDURE [dbo].[usp_PayDebitDocumentForm2InIB]
	@Waybill_Id						D_ID,
	@ChildDepart_Guid			D_GUID,
	@IBLINKEDSERVERNAME		D_NAME = NULL,

  @FINDED_MONEY									D_MONEY output,
  @DOCUMENT_NUM									D_NAME output,
  @DOCUMENT_DATE								D_DATE output,
  @DOCUMENT_CURRENCYSALDO				D_MONEY output,
  @DOCUMENT_CURRENCYAMOUNTPAID	D_MONEY output,
	@ERROR_NUM										int output,
	@ERROR_MES										nvarchar(4000) output
AS

BEGIN
  BEGIN TRY
    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';
		SET @FINDED_MONEY = 0;
		SET @DOCUMENT_CURRENCYSALDO = 0;
		SET @DOCUMENT_CURRENCYAMOUNTPAID = 0;
		SET @DOCUMENT_NUM = '';
		SET @DOCUMENT_DATE = NULL;

		DECLARE @CHILDCUST_CODE nvarchar(8) = '';
		SELECT @CHILDCUST_CODE = [ChildDepart_Code] FROM [dbo].[T_ChildDepart] WHERE [ChildDepart_Guid] = @ChildDepart_Guid;
		if( @CHILDCUST_CODE IS NULL )
			BEGIN
				SET @ERROR_NUM = 1;
				SET @ERROR_MES = 'В базе данных не найден дочерний клиент с указанным идентификатором: ' + CAST( @ChildDepart_Guid as nvarchar(36) );
			END

    DECLARE @EventID D_ID = NULL;
    DECLARE @ParentEventID D_ID = NULL;
    DECLARE @strMessage D_EVENTMSG = '';
    DECLARE @EventSrc D_NAME = 'Оплата задолженности в IB';

	  IF( @IBLINKEDSERVERNAME IS NULL ) SELECT @IBLINKEDSERVERNAME = dbo.GetIBLinkedServerName();
	  
    DECLARE @SQLString nvarchar( 2048 );
    DECLARE @ParmDefinition nvarchar( 500 );

    SET @ParmDefinition = N' @FINDED_MONEY_Ib money output, @DOCUMENT_NUM_Ib varchar(128) output, 
			@DOCUMENT_DATE_Ib date output, @DOCUMENT_CURRENCYSALDO_Ib money output, @DOCUMENT_CURRENCYAMOUNTPAID_Ib money output, 
			@ErrorNum_Ib int output, @ErrorText_Ib varchar(480) output'; 				

		SET @SQLString = 'SELECT @FINDED_MONEY_Ib = FINDED_MONEY, @DOCUMENT_NUM_Ib = DOCUMENT_NUM, 
		 @DOCUMENT_DATE_Ib = DOCUMENT_DATE, @DOCUMENT_CURRENCYSALDO_Ib = DOCUMENT_CURRENCYSALDO, @DOCUMENT_CURRENCYAMOUNTPAID_Ib = DOCUMENT_CURRENCYAMOUNTPAID, 
		 @ErrorNum_Ib = ERROR_NUMBER, @ErrorText_Ib = ERROR_TEXT FROM OPENQUERY( ' + 
			@IBLINKEDSERVERNAME + ', ''SELECT FINDED_MONEY, DOCUMENT_NUM, DOCUMENT_DATE, DOCUMENT_CURRENCYSALDO, DOCUMENT_CURRENCYAMOUNTPAID, ERROR_NUMBER, ERROR_TEXT FROM USP_SETTLECWAYBILL_FROMSQL( ' + 
					cast( @Waybill_Id as nvarchar(20)) + ', ' + 
					'''''' + cast( @CHILDCUST_CODE as nvarchar(8)) + '''''' + ' )'' )'; 

		PRINT @ParmDefinition;

		PRINT @SQLString;
					
    EXECUTE sp_executesql @SQLString, @ParmDefinition, @FINDED_MONEY_Ib = @FINDED_MONEY output, @DOCUMENT_NUM_Ib = @DOCUMENT_NUM output, 
			@DOCUMENT_DATE_Ib = @DOCUMENT_DATE output, @DOCUMENT_CURRENCYSALDO_Ib = @DOCUMENT_CURRENCYSALDO output, 
			@DOCUMENT_CURRENCYAMOUNTPAID_Ib = @DOCUMENT_CURRENCYAMOUNTPAID output, 
			@ErrorNum_Ib = @ERROR_NUM output, @ErrorText_Ib = @ERROR_MES output;  
		
	END TRY
	
	BEGIN CATCH
    SET @ERROR_NUM = ERROR_NUMBER();
    SET @ERROR_MES = @ERROR_MES + ' ' + ERROR_MESSAGE();
    SET @strMessage = @ERROR_MES + ' ' + @Waybill_Id;
    
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
GRANT EXECUTE ON [dbo].[usp_PayDebitDocumentForm2InIB] TO [public]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Регистрирует оплату задолженности по форме 2

-- Входные параметры
-- 
--		@Waybill_Id						- УИ документа, подлежащего оплате
--		@ChildDepart_Guid			- УИ дочернего клиента
--
-- Выходные параметры
--
--		@FINDED_MONEY									- сумма разноски
--		@DOCUMENT_NUM									- номер оплаченного документа
--		@DOCUMENT_DATE								- дата оплаченного документа
--		@DOCUMENT_CURRENCYSALDO				- сальдо оплаченного документа
--		@DOCUMENT_CURRENCYAMOUNTPAID	- итого оплачено по документу
--		@ERROR_NUM										- номер ошибки
--		@ERROR_MES										- сообщение об ошибке

CREATE PROCEDURE [dbo].[usp_PayDebitDocumentForm2ToSQLandIB] 
	@Waybill_Id						D_ID,
	@ChildDepart_Guid			D_GUID,

  @FINDED_MONEY									D_MONEY output,
  @DOCUMENT_NUM									D_NAME output,
  @DOCUMENT_DATE								D_DATE output,
  @DOCUMENT_CURRENCYSALDO				D_MONEY output,
  @DOCUMENT_CURRENCYAMOUNTPAID	D_MONEY output,
	@ERROR_NUM										int output,
	@ERROR_MES										nvarchar(4000) output

AS

BEGIN

	BEGIN TRY

    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';
		SET @FINDED_MONEY = 0;
		SET @DOCUMENT_CURRENCYSALDO = 0;
		SET @DOCUMENT_CURRENCYAMOUNTPAID = 0;
		SET @DOCUMENT_NUM = '';
		SET @DOCUMENT_DATE = NULL;

		IF NOT EXISTS ( SELECT [ChildDepart_Guid] FROM dbo.[T_ChildDepart] WHERE [ChildDepart_Guid] = @ChildDepart_Guid )
			BEGIN
				SET @ERROR_NUM = 1;
				SET @ERROR_MES = 'В базе данных не найден дочерний клиент с указанным идентификатором: ' + CAST( @ChildDepart_Guid as nvarchar(36) );

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

	    EXEC dbo.usp_PayDebitDocumentForm2InIB @Waybill_Id = @Waybill_Id,  @IBLINKEDSERVERNAME = NULL, 
				@FINDED_MONEY = @FINDED_MONEY output, @DOCUMENT_NUM = @DOCUMENT_NUM output, @DOCUMENT_DATE = @DOCUMENT_DATE output, 
				@DOCUMENT_CURRENCYSALDO = @DOCUMENT_CURRENCYSALDO output, @DOCUMENT_CURRENCYAMOUNTPAID = @DOCUMENT_CURRENCYAMOUNTPAID output,
			@ERROR_NUM = @ERROR_NUM output, @ERROR_MES = @ERROR_MES output;

		IF( @ERROR_NUM = 0 )
			BEGIN
				SET @strMessage = 'Проведена оплата задолженности по форме 2. УИ документа: ' + CONVERT( nvarchar(16), @Waybill_Id );
				COMMIT TRANSACTION UpdateData;
			END
		ELSE 
			BEGIN
				SET @strMessage = 'Ошибка регистрации оплаты задолженности по форме 2. ' + @ERROR_MES;
				ROLLBACK TRANSACTION UpdateData;
			END


		EXEC dbo.spAddEventToLog @EVENT_SOURCE = @EventSrc, @EVENT_SOURCEID = @Waybill_Id, @EVENT_CATEGORY = 'None', 
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
GRANT EXECUTE ON [dbo].[usp_PayDebitDocumentForm2ToSQLandIB] TO [public]
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Возвращает настройки по умолчанию для платежа
--
-- Входящие параметры:
--		@PaymentType_Guid - УИ формы оплаты
--
-- Выходные параметры:
--
--		@ACCOUNTPLAN_1C_CODE			код плана счетов в 1С
--		@ACCOUNTPLAN_GUID					УИ плана счетов
--		@BUDGETPROJECT_DST_NAME		наименование проекта
--		@BUDGETPROJECT_DST_GUID		УИ проекта
--		@ERROR_NUM								номер ошибки
--		@ERROR_MES								сообщение об ошибке

-- Результат:
--    0 - успешное завершение
--    <>0 - ошибка запроса информации из базы данных

CREATE PROCEDURE [dbo].[usp_GetEarningSettingsDefault] 
	@PaymentType_Guid			D_GUID,

  @ACCOUNTPLAN_1C_CODE	D_NAME output,
	@ACCOUNTPLAN_GUID			D_GUID output,
	@BUDGETPROJECT_DST_NAME		D_NAME output,
	@BUDGETPROJECT_DST_GUID		D_GUID output,

	@ERROR_NUM						int output,
  @ERROR_MES						nvarchar(4000) output
AS

BEGIN

  SET @ERROR_NUM = 0;
  SET @ERROR_MES = '';
  SET @ACCOUNTPLAN_1C_CODE = NULL;
	SET @ACCOUNTPLAN_GUID = NULL;
	SET @BUDGETPROJECT_DST_NAME = NULL;
	SET @BUDGETPROJECT_DST_GUID = NULL;

  BEGIN TRY

    DECLARE @PaymentTypeId D_ID;
		SELECT @PaymentTypeId = PaymentType_Id FROM T_PaymentType WHERE PaymentType_Guid = @PaymentType_Guid;
		DECLARE @strPaymentTypeId D_NAME;
		SET @strPaymentTypeId = CAST(@PaymentTypeId as nvarchar(128));


		DECLARE @Settings_Name D_NAME;
		SET @Settings_Name = 'Настройки для модуля Платежи';

		DECLARE @doc xml;
		SELECT Top 1 @doc = [Settings_XML] FROM [dbo].[T_Settings]
		WHERE [Settings_Name] = @Settings_Name;

		IF( @doc IS NOT NULL )
			BEGIN
				IF( @PaymentTypeId = 1 )
					BEGIN
						SELECT @ACCOUNTPLAN_1C_CODE = @doc.value( '(//SettingsForEarning/EarningAccountPlan/AccountPlan[@PaymentType_Id=1]/@ACCOUNTPLAN_1C_CODE)[1]', 'nvarchar(128)' ) ;
						SELECT @BUDGETPROJECT_DST_NAME = @doc.value( '(//SettingsForEarning/EarningBudgetProject/BudgetProjectDST[@PaymentType_Id=1]/@BUDGETPROJECT_NAME)[1]', 'nvarchar(128)' ) ;
					END

				IF( @PaymentTypeId = 2 )
					BEGIN
						SELECT @ACCOUNTPLAN_1C_CODE = @doc.value( '(//SettingsForEarning/EarningAccountPlan/AccountPlan[@PaymentType_Id=2]/@ACCOUNTPLAN_1C_CODE)[1]', 'nvarchar(128)' ) ;
						SELECT @BUDGETPROJECT_DST_NAME = @doc.value( '(//SettingsForEarning/EarningBudgetProject/BudgetProjectDST[@PaymentType_Id=2]/@BUDGETPROJECT_NAME)[1]', 'nvarchar(128)' ) ;
					END

				IF( @ACCOUNTPLAN_1C_CODE IS NOT NULL ) 
					SELECT Top 1 @ACCOUNTPLAN_GUID = [ACCOUNTPLAN_GUID] FROM [dbo].[T_AccountPlan]
					WHERE [ACCOUNTPLAN_1C_CODE] = @ACCOUNTPLAN_1C_CODE;

				IF( @BUDGETPROJECT_DST_NAME IS NOT NULL ) 
					SELECT Top 1 @BUDGETPROJECT_DST_GUID = [BUDGETPROJECT_GUID] FROM [dbo].[T_BudgetProject]
					WHERE [BUDGETPROJECT_NAME] = @BUDGETPROJECT_DST_NAME;
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
GRANT EXECUTE ON [dbo].[usp_GetEarningSettingsDefault] TO [public]
GO

/****** Object:  StoredProcedure [dbo].[usp_PayDebitDocumentForm2InIB]    Script Date: 07.05.2013 10:20:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Регистрирует оплату задолженности в InterBase по форме 2

-- Входные параметры
-- 
--		@Earning_Guid					- УИ платежа
--		@Waybill_Id						- УИ документа, подлежащего оплате
--		@IBLINKEDSERVERNAME		- имя LINKEDSERVER для подключения к InterBase
--
-- Выходные параметры
--
--		@EARNING_SALDO								- сальдо платежа
--		@EARNING_EXPENSE							- сумма расхода платежа
--		@DOCUMENT_NUM									- номер оплаченного документа
--		@DOCUMENT_DATE								- дата оплаченного документа
--		@DOCUMENT_CURRENCYSALDO				- сальдо оплаченного документа
--		@DOCUMENT_CURRENCYAMOUNTPAID	- итого оплачено по документу
--		@ERROR_NUM										- номер ошибки
--		@ERROR_MES										- сообщение об ошибке

CREATE PROCEDURE [dbo].[usp_PayDebitDocumentForm2ByEarningInIB]
	@Earning_Guid					D_GUID,
	@Waybill_Id						D_ID,
	@IBLINKEDSERVERNAME		D_NAME = NULL,

  @EARNING_SALDO								D_MONEY output,
  @EARNING_EXPENSE							D_MONEY output,
  @DOCUMENT_NUM									D_NAME output,
  @DOCUMENT_DATE								D_DATE output,
  @DOCUMENT_CURRENCYSALDO				D_MONEY output,
  @DOCUMENT_CURRENCYAMOUNTPAID	D_MONEY output,
	@ERROR_NUM										int output,
	@ERROR_MES										nvarchar(4000) output
AS

BEGIN
  BEGIN TRY
    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';
		SET @EARNING_SALDO = 0;
		SET @EARNING_EXPENSE = 0;
		SET @DOCUMENT_CURRENCYSALDO = 0;
		SET @DOCUMENT_CURRENCYAMOUNTPAID = 0;
		SET @DOCUMENT_NUM = '';
		SET @DOCUMENT_DATE = NULL;

    DECLARE @EventID D_ID = NULL;
    DECLARE @ParentEventID D_ID = NULL;
    DECLARE @strMessage D_EVENTMSG = '';
    DECLARE @EventSrc D_NAME = 'Оплата задолженности в IB';

		IF NOT EXISTS ( SELECT Earning_Guid FROM dbo.[T_Earning] WHERE Earning_Guid = @Earning_Guid )
			BEGIN
				SET @ERROR_NUM = 1;
				SET @ERROR_MES = 'В базе данных не найден платёж с указанным идентификатором: ' + CAST( @Earning_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END       
		
		DECLARE @CEARNING_ID D_ID;

		SELECT @CEARNING_ID = [Earning_Id], @EARNING_EXPENSE = [Earning_Expense], @EARNING_SALDO = [Earning_Saldo]
		FROM dbo.[T_Earning] WHERE Earning_Guid = @Earning_Guid;

	  IF( @IBLINKEDSERVERNAME IS NULL ) SELECT @IBLINKEDSERVERNAME = dbo.GetIBLinkedServerName();
	  
    DECLARE @SQLString nvarchar( 2048 );
    DECLARE @ParmDefinition nvarchar( 500 );

    SET @ParmDefinition = N' @EARNING_SALDO_Ib = EARNING_SALDO money output, @EARNING_EXPENSE_Ib = EARNING_EXPENSE money output, @DOCUMENT_NUM_Ib varchar(128) output, 
			@DOCUMENT_DATE_Ib date output, @DOCUMENT_CURRENCYSALDO_Ib money output, @DOCUMENT_CURRENCYAMOUNTPAID_Ib money output, 
			@ErrorNum_Ib int output, @ErrorText_Ib varchar(480) output'; 				

		SET @SQLString = 'SELECT @EARNING_SALDO_Ib = EARNING_SALDO, @EARNING_EXPENSE_Ib = EARNING_EXPENSE, @DOCUMENT_NUM_Ib = DOCUMENT_NUM, 
		 @DOCUMENT_DATE_Ib = DOCUMENT_DATE, @DOCUMENT_CURRENCYSALDO_Ib = DOCUMENT_CURRENCYSALDO, @DOCUMENT_CURRENCYAMOUNTPAID_Ib = DOCUMENT_CURRENCYAMOUNTPAID, 
		 @ErrorNum_Ib = ERROR_NUMBER, @ErrorText_Ib = ERROR_TEXT FROM OPENQUERY( ' + 
			@IBLINKEDSERVERNAME + ', ''SELECT EARNING_SALDO, EARNING_EXPENSE, DOCUMENT_NUM, DOCUMENT_DATE, DOCUMENT_CURRENCYSALDO, DOCUMENT_CURRENCYAMOUNTPAID, ERROR_NUMBER, ERROR_TEXT 
			FROM USP_SETTLECWAYBILL_FROMSQL( ' + 
					cast( @CEARNING_ID as nvarchar(20)) + ', ' + 
					cast( @Waybill_Id as nvarchar(20)) + ' )'' )'; 

		PRINT @ParmDefinition;

		PRINT @SQLString;
					
    EXECUTE sp_executesql @SQLString, @ParmDefinition, @EARNING_SALDO_Ib = @EARNING_SALDO output, @EARNING_EXPENSE_Ib = @EARNING_EXPENSE output, 
			@DOCUMENT_NUM_Ib = @DOCUMENT_NUM output, 
			@DOCUMENT_DATE_Ib = @DOCUMENT_DATE output, @DOCUMENT_CURRENCYSALDO_Ib = @DOCUMENT_CURRENCYSALDO output, 
			@DOCUMENT_CURRENCYAMOUNTPAID_Ib = @DOCUMENT_CURRENCYAMOUNTPAID output, 
			@ErrorNum_Ib = @ERROR_NUM output, @ErrorText_Ib = @ERROR_MES output;  
		
	END TRY
	
	BEGIN CATCH
    SET @ERROR_NUM = ERROR_NUMBER();
    SET @ERROR_MES = @ERROR_MES + ' ' + ERROR_MESSAGE();
    SET @strMessage = @ERROR_MES + ' ' + @Waybill_Id;
    
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
GRANT EXECUTE ON [dbo].[usp_PayDebitDocumentForm2ByEarningInIB] TO [public]
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

CREATE PROCEDURE [dbo].[usp_PayDebitDocumentForm2ByEarningToSQLandIB] 
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

	    EXEC dbo.usp_PayDebitDocumentForm2ByEarningInIB @Earning_Guid = @Earning_Guid,  @Waybill_Id = @Waybill_Id, @IBLINKEDSERVERNAME = NULL, 
				@EARNING_SALDO = @EARNING_SALDO output, @EARNING_EXPENSE = @EARNING_EXPENSE output,
				@DOCUMENT_NUM = @DOCUMENT_NUM output, @DOCUMENT_DATE = @DOCUMENT_DATE output, 
				@DOCUMENT_CURRENCYSALDO = @DOCUMENT_CURRENCYSALDO output, @DOCUMENT_CURRENCYAMOUNTPAID = @DOCUMENT_CURRENCYAMOUNTPAID output,
				@ERROR_NUM = @ERROR_NUM output, @ERROR_MES = @ERROR_MES output;

		IF( @ERROR_NUM = 0 )
			BEGIN
				UPDATE [dbo].[T_Earning] SET [Earning_Expense] = @EARNING_EXPENSE WHERE Earning_Guid = @Earning_Guid;

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

	IF( @ERROR_NUM = 0 )
		SET @ERROR_MES = 'Успешное завершение операции.';

	RETURN @ERROR_NUM;
END

GO
GRANT EXECUTE ON [dbo].[usp_PayDebitDocumentForm2ByEarningToSQLandIB] TO [public]
GO

