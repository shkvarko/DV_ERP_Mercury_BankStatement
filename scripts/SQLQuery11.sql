USE [ERP_Mercury]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Регистрирует оплату задолженности в InterBase

-- Входные параметры
-- 
-- @Earning_Guid - УИ платежа
-- @IBLINKEDSERVERNAME		- имя LINKEDSERVER для подключения к InterBase
--
-- Выходные параметры
--
-- @ERROR_NUM						- номер ошибки
-- @ERROR_MES						- сообщение об ошибке

CREATE PROCEDURE [dbo].[usp_PayDebitDocumentForm1InIB]
	@Earning_Guid					D_GUID,
	@Waybill_Id						D_ID,
	@IBLINKEDSERVERNAME		D_NAME = NULL,

  @FINDED_MONEY					D_MONEY output,
  @DOC_NUM							D_NAME output,
  @DOC_DATE							D_DATE output,
	@ERROR_NUM						int output,
	@ERROR_MES						nvarchar(4000) output
AS

BEGIN
  BEGIN TRY
    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';
		SET @FINDED_MONEY = 0;
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
		DECLARE @CURRENCY_CODE	D_MONEY;

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
    DECLARE @RETURNVALUE int;

    SET @ParmDefinition = N'@FINDED_MONEY_Ib money ouput, @DOCUMENT_NUM_Ib nvarchar(16) output, 
			@DOCUMENT_DATE_Ib date output, @DOCUMENT_SALDO_Ib money output,  @ErrorNum_Ib int output, @ErrorText_Ib varchar(480) output'; 				

		SET @SQLString = 'SELECT @FINDED_MONEY_Ib = FINDED_MONEY, @DOCUMENT_NUM_Ib = DOCUMENT_NUM, 
		 @DOCUMENT_DATE_Ib = DOCUMENT_DATE, @DOCUMENT_SALDO_Ib = DOCUMENT_SALDO, @ErrorNum_Ib = ERROR_NUMBER, @ErrorText_Ib = ERROR_TEXT FROM OPENQUERY( ' + 
			@IBLINKEDSERVERNAME + ', ''SELECT FINDED_MONEY, DOCUMENT_NUM, DOCUMENT_DATE, DOCUMENT_SALDO, ERROR_NUMBER, ERROR_TEXT FROM USP_NEWSETTLEDOC_FROMSQL( ' + cast( @DOC_CODE as nvarchar( 8 )) + ', ' + +
					cast( @DOC_ID as nvarchar(10)) +  ', ' +
					cast( @EARNING_ID as nvarchar(10)) +  ', ' +
					cast( @SETTLE_VALUE as nvarchar(20)) +  ', ' +
					'''''' + cast( @CURRENCY_CODE as nvarchar(3)) + '''''' + ', ' +
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


