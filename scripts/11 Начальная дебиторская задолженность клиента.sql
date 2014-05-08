USE [ERP_Mercury]
GO

INSERT INTO [dbo].[TS_GENERATOR]( GENERATOR_ID, TABLE_NAME )
VALUES( 0, 'T_CustomerInitalDebt' );

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[T_CustomerInitalDebt](
	[CustomerInitalDebt_Guid] [dbo].[D_GUID] NOT NULL,
	[CustomerInitalDebt_Id] [dbo].[D_ID] NOT NULL,
	[Customer_Guid] [dbo].[D_GUID] NULL,
	[Currency_Guid] [dbo].[D_GUID] NOT NULL,
	[CustomerInitalDebt_Date] [dbo].[D_DATE] NOT NULL,
	[CustomerInitalDebt_DocNum] [dbo].[D_NAME] NOT NULL,
	[CustomerInitalDebt_Value] [dbo].[D_MONEY] NOT NULL,
	[CustomerInitalDebt_AmountPaid] [dbo].[D_MONEY] NOT NULL,
	[CustomerInitalDebt_DateLastPaid] [dbo].[D_DATE] NULL,
	[CustomerInitalDebt_Saldo]  AS ([CustomerInitalDebt_AmountPaid]-[CustomerInitalDebt_Value]),
	[Company_Guid] [dbo].[D_GUID_NULL] NULL,
	[CustomerChild_Guid] [dbo].[D_GUID_NULL] NULL,
	[PaymentType_Guid] [dbo].[D_GUID_NULL] NOT NULL,
	[Record_Updated] [dbo].[D_DATETIME] NOT NULL,
	[Record_UserUpdated] [dbo].[D_NAMESHORT] NOT NULL,
 CONSTRAINT [PK_T_CustomerInitalDebt] PRIMARY KEY CLUSTERED 
(
	[CustomerInitalDebt_Guid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] 

GO

ALTER TABLE [dbo].[T_CustomerInitalDebt] ADD  CONSTRAINT [DF_T_CustomerInitalDebt_AmountPaid]  DEFAULT ((0)) FOR [CustomerInitalDebt_AmountPaid]
GO

ALTER TABLE [dbo].[T_CustomerInitalDebt]  WITH CHECK ADD  CONSTRAINT [FK_T_CustomerInitalDebt_T_Company] FOREIGN KEY([Company_Guid])
REFERENCES [dbo].[T_Company] ([Company_Guid])
GO

ALTER TABLE [dbo].[T_CustomerInitalDebt] CHECK CONSTRAINT [FK_T_CustomerInitalDebt_T_Company]
GO

ALTER TABLE [dbo].[T_CustomerInitalDebt]  WITH CHECK ADD  CONSTRAINT [FK_T_CustomerInitalDebt_T_Currency] FOREIGN KEY([Currency_Guid])
REFERENCES [dbo].[T_Currency] ([Currency_Guid])
GO

ALTER TABLE [dbo].[T_CustomerInitalDebt] CHECK CONSTRAINT [FK_T_CustomerInitalDebt_T_Currency]
GO

ALTER TABLE [dbo].[T_CustomerInitalDebt]  WITH CHECK ADD  CONSTRAINT [FK_T_CustomerInitalDebt_T_Customer] FOREIGN KEY([Customer_Guid])
REFERENCES [dbo].[T_Customer] ([Customer_Guid])
GO

ALTER TABLE [dbo].[T_CustomerInitalDebt] CHECK CONSTRAINT [FK_T_CustomerInitalDebt_T_Customer]
GO

ALTER TABLE [dbo].[T_CustomerInitalDebt]  WITH CHECK ADD  CONSTRAINT [FK_T_CustomerInitalDebt_T_CustomerChild] FOREIGN KEY([CustomerChild_Guid])
REFERENCES [dbo].[T_CustomerChild] ([CustomerChild_Guid])
GO

ALTER TABLE [dbo].[T_CustomerInitalDebt] CHECK CONSTRAINT [FK_T_CustomerInitalDebt_T_CustomerChild]
GO

ALTER TABLE [dbo].[T_CustomerInitalDebt]  WITH CHECK ADD  CONSTRAINT [FK_T_CustomerInitalDebt_T_PaymentType] FOREIGN KEY([PaymentType_Guid])
REFERENCES [dbo].[T_PaymentType] ([PaymentType_Guid])
GO

ALTER TABLE [dbo].[T_CustomerInitalDebt] CHECK CONSTRAINT [FK_T_CustomerInitalDebt_T_PaymentType]
GO

CREATE NONCLUSTERED INDEX [INDX_T_CustomerInitalDebt_Date] ON [dbo].[T_CustomerInitalDebt]
(
	[CustomerInitalDebt_Date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [INDEX]

GO

CREATE NONCLUSTERED INDEX [INDX_T_CustomerInitalDebt_DocNum] ON [dbo].[T_CustomerInitalDebt]
(
	[CustomerInitalDebt_DocNum] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [INDEX]

GO


CREATE UNIQUE NONCLUSTERED INDEX [INDX_T_CustomerInitalDebt_Id] ON [dbo].[T_CustomerInitalDebt]
(
	[CustomerInitalDebt_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [INDEX]

GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[T_CustomerInitalDebt_Archive](
	[CustomerInitalDebt_Guid] [dbo].[D_GUID] NOT NULL,
	[CustomerInitalDebt_Id] [dbo].[D_ID] NOT NULL,
	[Customer_Guid] [dbo].[D_GUID] NULL,
	[Currency_Guid] [dbo].[D_GUID] NOT NULL,
	[CustomerInitalDebt_Date] [dbo].[D_DATE] NOT NULL,
	[CustomerInitalDebt_DocNum] [dbo].[D_NAME] NOT NULL,
	[CustomerInitalDebt_Value] [dbo].[D_MONEY] NOT NULL,
	[CustomerInitalDebt_AmountPaid] [dbo].[D_MONEY] NOT NULL,
	[CustomerInitalDebt_DateLastPaid] [dbo].[D_DATE] NULL,
	[CustomerInitalDebt_Saldo]  AS ([CustomerInitalDebt_AmountPaid]-[CustomerInitalDebt_Value]),
	[Company_Guid] [dbo].[D_GUID_NULL] NULL,
	[CustomerChild_Guid] [dbo].[D_GUID_NULL] NULL,
	[PaymentType_Guid] [dbo].[D_GUID_NULL] NOT NULL,
	[Record_Updated] [dbo].[D_DATETIME] NOT NULL,
	[Record_UserUpdated] [dbo].[D_NAMESHORT] NOT NULL,
	[Action_TypeId] [dbo].[D_ID] NOT NULL,
) ON [PRIMARY]

GO

CREATE NONCLUSTERED INDEX [INDX_T_CustomerInitalDebt_Archive_Date] ON [dbo].[T_CustomerInitalDebt_Archive]
(
	[CustomerInitalDebt_Date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [INDEX]

GO

CREATE NONCLUSTERED INDEX [INDX_T_CustomerInitalDebt_Archive_Record_Updated] ON [dbo].[T_CustomerInitalDebt_Archive]
(
	[Record_Updated] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [INDEX]

GO

CREATE NONCLUSTERED INDEX [INDX_T_CustomerInitalDebt_Archive_Action_TypeId] ON [dbo].[T_CustomerInitalDebt_Archive]
(
	[Action_TypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [INDEX]

GO

CREATE NONCLUSTERED INDEX [INDX_T_CustomerInitalDebt_Archive_CustomerInitalDebt_Guid] ON [dbo].[T_CustomerInitalDebt_Archive]
(
	[CustomerInitalDebt_Guid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [INDEX]

GO

CREATE NONCLUSTERED INDEX [INDX_T_CustomerInitalDebt_Archive_CustomerInitalDebt_Id] ON [dbo].[T_CustomerInitalDebt_Archive]
(
	[CustomerInitalDebt_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [INDEX]

GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Триггер добавляет записи в случае их удаления в таблицу удаленных записей
-- =============================================
CREATE TRIGGER [dbo].[TG_CustomerInitalDebtAfterDelete] 
   ON [dbo].[T_CustomerInitalDebt] 
   AFTER DELETE
AS 
BEGIN
	SET NOCOUNT ON;

	INSERT INTO dbo.T_CustomerInitalDebt_Archive( CustomerInitalDebt_Guid, CustomerInitalDebt_Id, Customer_Guid, Currency_Guid, 
		CustomerInitalDebt_Date, CustomerInitalDebt_DocNum, CustomerInitalDebt_Value, CustomerInitalDebt_AmountPaid, 
		CustomerInitalDebt_DateLastPaid, Company_Guid, CustomerChild_Guid, PaymentType_Guid, 
		Record_Updated, Record_UserUpdated, Action_TypeId )
	SELECT CustomerInitalDebt_Guid, CustomerInitalDebt_Id, Customer_Guid, Currency_Guid, 
		CustomerInitalDebt_Date, CustomerInitalDebt_DocNum, CustomerInitalDebt_Value, CustomerInitalDebt_AmountPaid, 
		CustomerInitalDebt_DateLastPaid, Company_Guid, CustomerChild_Guid, PaymentType_Guid,
	  sysutcdatetime(), ( Host_Name() + ': ' + SUSER_SNAME() ), 2
	FROM deleted;
END
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Триггер обновляет время редактирования/вставки записи
-- =============================================
CREATE TRIGGER [dbo].[TG_CustomerInitalDebtAfterUpdate]
   ON  [dbo].[T_CustomerInitalDebt]
   AFTER INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;
	
	INSERT INTO dbo.T_CustomerInitalDebt_Archive( CustomerInitalDebt_Guid, CustomerInitalDebt_Id, Customer_Guid, Currency_Guid, 
		CustomerInitalDebt_Date, CustomerInitalDebt_DocNum, CustomerInitalDebt_Value, CustomerInitalDebt_AmountPaid, 
		CustomerInitalDebt_DateLastPaid, Company_Guid, CustomerChild_Guid, PaymentType_Guid, 
		Record_Updated, Record_UserUpdated, Action_TypeId )
	SELECT CustomerInitalDebt_Guid, CustomerInitalDebt_Id, Customer_Guid, Currency_Guid, 
		CustomerInitalDebt_Date, CustomerInitalDebt_DocNum, CustomerInitalDebt_Value, CustomerInitalDebt_AmountPaid, 
		CustomerInitalDebt_DateLastPaid, Company_Guid, CustomerChild_Guid, PaymentType_Guid,
	  sysutcdatetime(), ( Host_Name() + ': ' + SUSER_SNAME() ), 0
	FROM inserted;

	UPDATE dbo.[T_CustomerInitalDebt] SET Record_Updated = sysutcdatetime(), Record_UserUpdated = ( Host_Name() + ': ' + SUSER_SNAME() )
	WHERE CustomerInitalDebt_Guid IN ( SELECT CustomerInitalDebt_Guid FROM inserted );
END
GO


/****** Object:  View [dbo].[CustomerInitalDebtView]    Script Date: 26.08.2013 9:21:14 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[CustomerInitalDebtView]
AS
SELECT     dbo.T_CustomerInitalDebt.CustomerInitalDebt_Guid, dbo.T_CustomerInitalDebt.CustomerInitalDebt_Id, dbo.T_CustomerInitalDebt.Customer_Guid, 
                      dbo.T_CustomerInitalDebt.Currency_Guid, dbo.T_CustomerInitalDebt.CustomerInitalDebt_Date, dbo.T_CustomerInitalDebt.CustomerInitalDebt_DocNum, 
                      dbo.T_CustomerInitalDebt.CustomerInitalDebt_Value, dbo.T_CustomerInitalDebt.CustomerInitalDebt_AmountPaid, 
                      dbo.T_CustomerInitalDebt.CustomerInitalDebt_DateLastPaid, dbo.T_CustomerInitalDebt.CustomerInitalDebt_Saldo, dbo.T_CustomerInitalDebt.Company_Guid, 
                      dbo.T_CustomerInitalDebt.CustomerChild_Guid, dbo.T_CustomerInitalDebt.PaymentType_Guid, dbo.T_PaymentType.PaymentType_Name, 
                      dbo.T_PaymentType.PaymentType_Description, dbo.T_PaymentType.PaymentType_Id, dbo.T_ChildDepart.ChildDepart_Guid, dbo.T_ChildDepart.ChildDepart_Code, 
                      dbo.T_ChildDepart.ChildDepart_Main, dbo.T_ChildDepart.ChildDepart_NotActive, dbo.T_ChildDepart.ChildDepart_MaxDebt, dbo.T_ChildDepart.ChildDepart_MaxDelay, 
                      dbo.T_ChildDepart.ChildDepart_Email, dbo.T_ChildDepart.ChildDepart_Name, dbo.T_Company.Company_Id, dbo.T_Company.CompanyType_Guid, 
                      dbo.T_Company.Company_Acronym, dbo.T_Company.Company_Name, dbo.T_Company.Company_IsActive, dbo.T_Currency.Currency_Abbr, 
                      dbo.T_Currency.Currency_Code, dbo.T_Currency.Currency_ShortName, dbo.T_Currency.Currency_Name, dbo.T_Customer.Customer_Id, 
                      dbo.T_Customer.Customer_Code, dbo.T_Customer.Customer_Name, dbo.T_Customer.CustomerStateType_Guid, dbo.T_Customer.CustomerActiveType_Guid, 
                      dbo.T_Customer.Customer_UNP, dbo.T_Customer.Customer_OKPO, dbo.T_Customer.Customer_OKULP, dbo.T_CustomerStateType.CustomerStateType_ShortName, 
                      dbo.T_CustomerStateType.CustomerStateType_Name, dbo.T_CustomerChild.CustomerChild_Id
FROM         dbo.T_CustomerInitalDebt INNER JOIN
                      dbo.T_Customer ON dbo.T_CustomerInitalDebt.Customer_Guid = dbo.T_Customer.Customer_Guid INNER JOIN
                      dbo.T_Currency ON dbo.T_CustomerInitalDebt.Currency_Guid = dbo.T_Currency.Currency_Guid INNER JOIN
                      dbo.T_Company ON dbo.T_CustomerInitalDebt.Company_Guid = dbo.T_Company.Company_Guid INNER JOIN
                      dbo.T_PaymentType ON dbo.T_CustomerInitalDebt.PaymentType_Guid = dbo.T_PaymentType.PaymentType_Guid INNER JOIN
                      dbo.T_CustomerStateType ON dbo.T_Customer.CustomerStateType_Guid = dbo.T_CustomerStateType.CustomerStateType_Guid AND 
                      dbo.T_Company.CustomerStateType_Guid = dbo.T_CustomerStateType.CustomerStateType_Guid LEFT OUTER JOIN
                      dbo.T_CustomerChild ON dbo.T_CustomerInitalDebt.CustomerChild_Guid = dbo.T_CustomerChild.CustomerChild_Guid LEFT OUTER JOIN
                      dbo.T_ChildDepart ON dbo.T_CustomerChild.ChildDepart_Guid = dbo.T_ChildDepart.ChildDepart_Guid
GO

GO
GRANT SELECT ON [dbo].[CustomerInitalDebtView] TO [public]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- Возвращает информацию о начальной дебиторской задолженности
--
-- Входные параметры:
--		@DateBegin				- начало периода
--		@DateEnd					- окончание периода
--		@PaymentType_Guid	- УИ формы платежа
--		@Company_Guid			- УИ компании
--		@Customer_Guid		- УИ клиента
--		@ChildDepart_Guid	- УИ дочернего клиента
--
-- Выходные параметры:
--		@ERROR_NUM				- код ошибки
--		@ERROR_MES				- сообщение об ошибке
--
-- Результат:
--    0 - успешное завершение
--    <>0 - ошибка запроса информации из базы данных

CREATE PROCEDURE [dbo].[usp_GetCustomerInitalDebtList] 
  @DateBegin				D_DATE,
  @DateEnd					D_DATE,
  @PaymentType_Guid	D_GUID,
	@Company_Guid			D_GUID = NULL,
	@Customer_Guid		D_GUID = NULL,
	@ChildDepart_Guid	D_GUID = NULL,
	
  @ERROR_NUM				int output,
  @ERROR_MES				nvarchar(4000) output
AS

BEGIN

  SET @ERROR_NUM = 0;
  SET @ERROR_MES = '';

  BEGIN TRY
  
		DECLARE @PaymentType_1_Guid	D_GUID;
		DECLARE @PaymentType_2_Guid	D_GUID;

		SET @PaymentType_1_Guid = ( SELECT [dbo].[GetPaymentType_1_Guid]() );
		SET @PaymentType_2_Guid = ( SELECT [dbo].[GetPaymentType_2_Guid]() );

		IF( @PaymentType_Guid = @PaymentType_1_Guid  )
			BEGIN
				SELECT CustomerInitalDebt_Guid, CustomerInitalDebt_Id, Customer_Guid, Currency_Guid, 
					CustomerInitalDebt_Date, CustomerInitalDebt_DocNum, CustomerInitalDebt_Value, 
					CustomerInitalDebt_AmountPaid, CustomerInitalDebt_DateLastPaid, CustomerInitalDebt_Saldo, 
					Company_Guid, CustomerChild_Guid, PaymentType_Guid, PaymentType_Name, PaymentType_Description, 
					PaymentType_Id, ChildDepart_Guid, ChildDepart_Code, ChildDepart_Main, ChildDepart_NotActive, 
					ChildDepart_MaxDebt, ChildDepart_MaxDelay, ChildDepart_Email, ChildDepart_Name, Company_Id, 
					CompanyType_Guid, Company_Acronym, Company_Name, Company_IsActive, 
					Currency_Abbr, Currency_Code, Currency_ShortName, Currency_Name, Customer_Id, Customer_Code, 
					Customer_Name, CustomerStateType_Guid, CustomerActiveType_Guid, Customer_UNP, Customer_OKPO, 
					Customer_OKULP, CustomerStateType_ShortName, CustomerStateType_Name
				FROM [dbo].[CustomerInitalDebtView]
				WHERE	[CustomerInitalDebt_Date]	BETWEEN @DateBegin AND @DateEnd
					AND	[PaymentType_Guid] = @PaymentType_Guid
					AND [Company_Guid] = @Company_Guid
				ORDER BY Customer_Name;
			END
		ELSE	IF( @PaymentType_Guid = @PaymentType_2_Guid )
			BEGIN
				SELECT CustomerInitalDebt_Guid, CustomerInitalDebt_Id, Customer_Guid, Currency_Guid, 
					CustomerInitalDebt_Date, CustomerInitalDebt_DocNum, CustomerInitalDebt_Value, 
					CustomerInitalDebt_AmountPaid, CustomerInitalDebt_DateLastPaid, CustomerInitalDebt_Saldo, 
					Company_Guid, CustomerChild_Guid, PaymentType_Guid, PaymentType_Name, PaymentType_Description, 
					PaymentType_Id, ChildDepart_Guid, ChildDepart_Code, ChildDepart_Main, ChildDepart_NotActive, 
					ChildDepart_MaxDebt, ChildDepart_MaxDelay, ChildDepart_Email, ChildDepart_Name, Company_Id, 
					CompanyType_Guid, Company_Acronym, Company_Name, Company_IsActive, 
					Currency_Abbr, Currency_Code, Currency_ShortName, Currency_Name, Customer_Id, Customer_Code, 
					Customer_Name, CustomerStateType_Guid, CustomerActiveType_Guid, Customer_UNP, Customer_OKPO, 
					Customer_OKULP, CustomerStateType_ShortName, CustomerStateType_Name
				FROM [dbo].[CustomerInitalDebtView]
				WHERE	[CustomerInitalDebt_Date]	BETWEEN @DateBegin AND @DateEnd
					AND	[PaymentType_Guid] = @PaymentType_Guid
				ORDER BY ChildDepart_Code, Customer_Name;
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
GRANT EXECUTE ON [dbo].[usp_GetCustomerInitalDebtList] TO [public]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Добавляет в InterBase информацию о начальной задолженности клиента

-- Входные параметры
-- 
-- @CustomerInitalDebt_Guid	- УИ задолженности клиента
-- @IBLINKEDSERVERNAME				- имя LINKEDSERVER для подключения к InterBase
--
-- Выходные параметры
--
-- @CustomerInitalDebt_Id		- УИ начальной задолженности клиента в InterBase
-- @ERROR_NUM								- номер ошибки
-- @ERROR_MES								- сообщение об ошибке

CREATE PROCEDURE [dbo].[usp_AddCustomerInitalDebtToIB]
	@CustomerInitalDebt_Guid					D_GUID,
	@IBLINKEDSERVERNAME		D_NAME = NULL,

	@CustomerInitalDebt_Id						int output, 
	@ERROR_NUM						int output,
	@ERROR_MES						nvarchar(4000) output
AS

BEGIN
  BEGIN TRY
    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';
		SET @CustomerInitalDebt_Id = NULL;

		IF NOT EXISTS ( SELECT CustomerInitalDebt_Guid FROM [dbo].[T_CustomerInitalDebt] WHERE CustomerInitalDebt_Guid = @CustomerInitalDebt_Guid )
			BEGIN
				SET @ERROR_NUM = 1;
				SET @ERROR_MES = 'В базе данных не найдена задолженность с указанным идентификатором: ' + CAST( @CustomerInitalDebt_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END       

	  IF( @IBLINKEDSERVERNAME IS NULL ) SELECT @IBLINKEDSERVERNAME = dbo.GetIBLinkedServerName();
	  
    
    DECLARE @CUSTOMER_ID							int;
    DECLARE @COMPANY_ID								int;
    DECLARE @CURRENCY_CODE						D_CURRENCYCODE;
    DECLARE @CHILDCUST_ID							int;
    DECLARE @CUSTOMERDEBT_SRCDOC			NVARCHAR(16);
    DECLARE @CUSTOMERDEBT_BEGINDATE		D_DATE;
    DECLARE @CUSTOMERDEBT_INITIALDEBT	float;
    DECLARE @PAYMENTTYPE_ID						int;

    SELECT @CUSTOMER_ID = [Customer_Id], @COMPANY_ID = [Company_Id], @CURRENCY_CODE = [Currency_Abbr], 
			@CHILDCUST_ID = [CustomerChild_Id], @CUSTOMERDEBT_SRCDOC = [CustomerInitalDebt_DocNum], 
			@CUSTOMERDEBT_BEGINDATE = [CustomerInitalDebt_Date], @CUSTOMERDEBT_INITIALDEBT = [CustomerInitalDebt_Value],
			@PAYMENTTYPE_ID = [PaymentType_Id]
		FROM [dbo].[CustomerInitalDebtView] WHERE [CustomerInitalDebt_Guid] = @CustomerInitalDebt_Guid;
      
    IF( @CHILDCUST_ID IS NULL ) SET @CHILDCUST_ID = 0;
		IF( @CUSTOMERDEBT_SRCDOC IS NULL ) SET @CUSTOMERDEBT_SRCDOC = '';
		IF( @COMPANY_ID IS NULL )
      BEGIN
        SET @ERROR_NUM = 2;
        SET @ERROR_MES = 'Не найдена компания, указанная в задолженности. УИ суммы: ' + CAST( @CustomerInitalDebt_Guid as nvarchar(36) );

        RETURN @ERROR_NUM;
      END 

    DECLARE @SQLString nvarchar( 2048 );
    DECLARE @ParmDefinition nvarchar( 500 );
    DECLARE @RETURNVALUE int;


		DECLARE @NewCUSTOMERDEBT_ID int;
		SET @NewCUSTOMERDEBT_ID = NULL;
    SET @ParmDefinition = N'@CUSTOMERDEBT_ID_Ib int output, @ErrorNum_Ib int output, @ErrorText_Ib varchar(480) output'; 				
					
		SET @SQLString = 'SELECT @CUSTOMERDEBT_ID_Ib = CUSTOMERDEBT_ID, @ErrorNum_Ib = ERROR_NUMBER, @ErrorText_Ib = ERROR_TEXT FROM OPENQUERY( ' + 
			@IBLINKEDSERVERNAME + ', ''SELECT CUSTOMERDEBT_ID, ERROR_NUMBER, ERROR_TEXT FROM USP_ADD_CUSTOMERDEBT_FROMSQL( ' +
					cast( @CUSTOMER_ID as nvarchar(10))  + ', ' +
					cast( @COMPANY_ID as nvarchar(10))  + ', ' +
					'''''' + cast( @CURRENCY_CODE as nvarchar(3)) + '''''' + ', ' +
					cast( @CHILDCUST_ID as nvarchar(10))  + ', ' +
					'''''' + cast( @CUSTOMERDEBT_SRCDOC as nvarchar(16)) + '''''' + ', ' +
					'''''' + cast( @CUSTOMERDEBT_BEGINDATE as nvarchar(10)) + '''''' + ', ' +
					'''''' + convert( varchar(50),cast( @CUSTOMERDEBT_INITIALDEBT as money ) ) + '''''' + ', ' +
					cast( @PAYMENTTYPE_ID as nvarchar(10))  + ', ' + ' )'' )';

		PRINT @SQLString;

    EXECUTE sp_executesql @SQLString, @ParmDefinition, @CUSTOMERDEBT_ID_Ib = @CustomerInitalDebt_Id output, 
			@ErrorNum_Ib = @ERROR_NUM output, @ErrorText_Ib = @ERROR_MES output;  
		
		IF( @ERROR_NUM = 0 )
			BEGIN
				UPDATE dbo.T_CustomerInitalDebt	SET CustomerInitalDebt_Id = @CustomerInitalDebt_Id
				WHERE CustomerInitalDebt_Guid = @CustomerInitalDebt_Guid;
			
				UPDATE dbo.TS_GENERATOR SET GENERATOR_ID = @CustomerInitalDebt_Id 
				WHERE TABLE_NAME = 'T_CustomerInitalDebt';
			END

	END TRY
	
	BEGIN CATCH
    SET @ERROR_NUM = ERROR_NUMBER();
    SET @ERROR_MES = @ERROR_MES + ' ' + ERROR_MESSAGE();

		RETURN @ERROR_NUM;
	END CATCH;

	IF( @ERROR_NUM = 0 )
		SET @ERROR_MES = 'Успешное завершение операции. Код задолженности в IB: ' + CAST( @CustomerInitalDebt_Id as nvarchar( 56 ) );

	RETURN @ERROR_NUM;

END

GO
GRANT EXECUTE ON [dbo].[usp_AddCustomerInitalDebtToIB] TO [public]
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Добавляет новую запись в таблицу T_CustomerInitalDebt
--
-- Входные параметры:
--
--		@Customer_Guid							- УИ клиента
--		@Currency_Guid							- УИ валюты
--		@CustomerInitalDebt_Date		- Дата
--		@CustomerInitalDebt_DocNum	- № документа
--		@CustomerInitalDebt_Value		- сумма задолженности
--		@Company_Guid								- УИ компании
--		@ChildDepart_Guid						- УИ дочернего клиента
--		@PaymentType_Guid						- УИ формы платежа

-- Выходные параметры:
--
--		@CustomerInitalDebt_Guid		- уи записи
--		@CustomerInitalDebt_Id			- уи записи в InterBase
--  @ERROR_NUM										- номер ошибки
--  @ERROR_MES										- текст ошибки
--
-- Результат:
--    0 - Успешное завершение
--    <>0 - ошибка

CREATE PROCEDURE [dbo].[usp_AddCustomerInitalDebtToSQLandIB] 
@CustomerInitalDebt_Guid					D_GUID,
	@IBLINKEDSERVERNAME		D_NAME = NULL,

	@CustomerInitalDebt_Id						int output, 
	@ERROR_NUM						int output,
	@ERROR_MES						nvarchar(4000) output
AS

BEGIN
  BEGIN TRY
    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';
		SET @CustomerInitalDebt_Id = NULL;

		IF NOT EXISTS ( SELECT CustomerInitalDebt_Guid FROM [dbo].[T_CustomerInitalDebt] WHERE CustomerInitalDebt_Guid = @CustomerInitalDebt_Guid )
			BEGIN
				SET @ERROR_NUM = 1;
				SET @ERROR_MES = 'В базе данных не найдена задолженность с указанным идентификатором: ' + CAST( @CustomerInitalDebt_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END       

	  IF( @IBLINKEDSERVERNAME IS NULL ) SELECT @IBLINKEDSERVERNAME = dbo.GetIBLinkedServerName();
	  
    
    DECLARE @CUSTOMER_ID							int;
    DECLARE @COMPANY_ID								int;
    DECLARE @CURRENCY_CODE						D_CURRENCYCODE;
    DECLARE @CHILDCUST_ID							int;
    DECLARE @CUSTOMERDEBT_SRCDOC			NVARCHAR(16);
    DECLARE @CUSTOMERDEBT_BEGINDATE		D_DATE;
    DECLARE @CUSTOMERDEBT_INITIALDEBT	float;
    DECLARE @PAYMENTTYPE_ID						int;

    SELECT @CUSTOMER_ID = [Customer_Id], @COMPANY_ID = [Company_Id], @CURRENCY_CODE = [Currency_Abbr], 
			@CHILDCUST_ID = [CustomerChild_Id], @CUSTOMERDEBT_SRCDOC = [CustomerInitalDebt_DocNum], 
			@CUSTOMERDEBT_BEGINDATE = [CustomerInitalDebt_Date], @CUSTOMERDEBT_INITIALDEBT = [CustomerInitalDebt_Value],
			@PAYMENTTYPE_ID = [PaymentType_Id]
		FROM [dbo].[CustomerInitalDebtView] WHERE [CustomerInitalDebt_Guid] = @CustomerInitalDebt_Guid;
      
    IF( @CHILDCUST_ID IS NULL ) SET @CHILDCUST_ID = 0;
		IF( @CUSTOMERDEBT_SRCDOC IS NULL ) SET @CUSTOMERDEBT_SRCDOC = '';
		IF( @COMPANY_ID IS NULL )
      BEGIN
        SET @ERROR_NUM = 2;
        SET @ERROR_MES = 'Не найдена компания, указанная в задолженности. УИ суммы: ' + CAST( @CustomerInitalDebt_Guid as nvarchar(36) );

        RETURN @ERROR_NUM;
      END 

    DECLARE @SQLString nvarchar( 2048 );
    DECLARE @ParmDefinition nvarchar( 500 );
    DECLARE @RETURNVALUE int;

		DECLARE @strCUSTOMERDEBT_BEGINDATE varchar( 24 );
		IF( @CUSTOMERDEBT_BEGINDATE IS NULL ) SET @strCUSTOMERDEBT_BEGINDATE = 'NULL'
		ELSE 
			BEGIN
				SET @strCUSTOMERDEBT_BEGINDATE = convert( varchar( 10), @CUSTOMERDEBT_BEGINDATE, 104);
				SET @strCUSTOMERDEBT_BEGINDATE = '''''' + @strCUSTOMERDEBT_BEGINDATE + '''''';
			END	

		DECLARE @NewCUSTOMERDEBT_ID int;
		SET @NewCUSTOMERDEBT_ID = NULL;
    SET @ParmDefinition = N'@CUSTOMERDEBT_ID_Ib int output, @ErrorNum_Ib int output, @ErrorText_Ib varchar(480) output'; 				
					
		SET @SQLString = 'SELECT @CUSTOMERDEBT_ID_Ib = CUSTOMERDEBT_ID, @ErrorNum_Ib = ERROR_NUMBER, @ErrorText_Ib = ERROR_TEXT FROM OPENQUERY( ' + 
			@IBLINKEDSERVERNAME + ', ''SELECT CUSTOMERDEBT_ID, ERROR_NUMBER, ERROR_TEXT FROM USP_ADD_CUSTOMERDEBT_FROMSQL( ' +
					cast( @CUSTOMER_ID as nvarchar(10))  + ', ' +
					'''''' + cast( @CURRENCY_CODE as nvarchar(3)) + '''''' + ', ' +
					cast( @COMPANY_ID as nvarchar(10))  + ', ' +
					cast( @CHILDCUST_ID as nvarchar(10))  + ', ' +
					'''''' + cast( @CUSTOMERDEBT_SRCDOC as nvarchar(16)) + '''''' + ', ' +
					@strCUSTOMERDEBT_BEGINDATE + ', ' +
  				 convert( varchar(50),cast( @CUSTOMERDEBT_INITIALDEBT as money ) ) + ', ' +
					cast( @PAYMENTTYPE_ID as nvarchar(10))  + ' )'' )';

		PRINT @SQLString;

    EXECUTE sp_executesql @SQLString, @ParmDefinition, @CUSTOMERDEBT_ID_Ib = @CustomerInitalDebt_Id output, 
			@ErrorNum_Ib = @ERROR_NUM output, @ErrorText_Ib = @ERROR_MES output;  
		
		IF( @ERROR_NUM = 0 )
			BEGIN
				UPDATE dbo.T_CustomerInitalDebt	SET CustomerInitalDebt_Id = @CustomerInitalDebt_Id
				WHERE CustomerInitalDebt_Guid = @CustomerInitalDebt_Guid;
			
				UPDATE dbo.TS_GENERATOR SET GENERATOR_ID = @CustomerInitalDebt_Id 
				WHERE TABLE_NAME = 'T_CustomerInitalDebt';
			END

	END TRY
	
	BEGIN CATCH
    SET @ERROR_NUM = ERROR_NUMBER();
    SET @ERROR_MES = @ERROR_MES + ' ' + ERROR_MESSAGE();

		RETURN @ERROR_NUM;
	END CATCH;

	IF( @ERROR_NUM = 0 )
		SET @ERROR_MES = 'Успешное завершение операции. Код задолженности в IB: ' + CAST( @CustomerInitalDebt_Id as nvarchar( 56 ) );

	RETURN @ERROR_NUM;

END


GO
GRANT EXECUTE ON [dbo].[usp_AddCustomerInitalDebtToSQLandIB] TO [public]
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Редактирует в InterBase информацию о начальной задолженности клиента

-- Входные параметры
-- 
-- @CustomerInitalDebt_Guid	- УИ задолженности клиента
-- @IBLINKEDSERVERNAME				- имя LINKEDSERVER для подключения к InterBase
--
-- Выходные параметры
--
-- @ERROR_NUM								- номер ошибки
-- @ERROR_MES								- сообщение об ошибке

CREATE PROCEDURE [dbo].[usp_EditCustomerInitalDebtToIB]
@CustomerInitalDebt_Guid	D_GUID,
	@IBLINKEDSERVERNAME				D_NAME = NULL,

	@ERROR_NUM								int output,
	@ERROR_MES								nvarchar(4000) output
AS

BEGIN
  BEGIN TRY
    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';

		IF NOT EXISTS ( SELECT CustomerInitalDebt_Guid FROM [dbo].[T_CustomerInitalDebt] WHERE CustomerInitalDebt_Guid = @CustomerInitalDebt_Guid )
			BEGIN
				SET @ERROR_NUM = 1;
				SET @ERROR_MES = 'В базе данных не найдена задолженность с указанным идентификатором: ' + CAST( @CustomerInitalDebt_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END       

	  IF( @IBLINKEDSERVERNAME IS NULL ) SELECT @IBLINKEDSERVERNAME = dbo.GetIBLinkedServerName();
	  
    
    DECLARE @CUSTOMERDEBT_ID					int;
    DECLARE @CUSTOMER_ID							int;
    DECLARE @COMPANY_ID								int;
    DECLARE @CURRENCY_CODE						D_CURRENCYCODE;
    DECLARE @CHILDCUST_ID							int;
    DECLARE @CUSTOMERDEBT_SRCDOC			NVARCHAR(16);
    DECLARE @CUSTOMERDEBT_BEGINDATE		D_DATE;
    DECLARE @CUSTOMERDEBT_INITIALDEBT	float;
    DECLARE @PAYMENTTYPE_ID						int;

    SELECT @CUSTOMERDEBT_ID = [CustomerInitalDebt_Id], @CUSTOMER_ID = [Customer_Id], @COMPANY_ID = [Company_Id], @CURRENCY_CODE = [Currency_Abbr], 
			@CHILDCUST_ID = [CustomerChild_Id], @CUSTOMERDEBT_SRCDOC = [CustomerInitalDebt_DocNum], 
			@CUSTOMERDEBT_BEGINDATE = [CustomerInitalDebt_Date], @CUSTOMERDEBT_INITIALDEBT = [CustomerInitalDebt_Value],
			@PAYMENTTYPE_ID = [PaymentType_Id]
		FROM [dbo].[CustomerInitalDebtView] WHERE [CustomerInitalDebt_Guid] = @CustomerInitalDebt_Guid;
      
    IF( @CHILDCUST_ID IS NULL ) SET @CHILDCUST_ID = 0;
		IF( @CUSTOMERDEBT_SRCDOC IS NULL ) SET @CUSTOMERDEBT_SRCDOC = '';
		IF( @COMPANY_ID IS NULL )
      BEGIN
        SET @ERROR_NUM = 2;
        SET @ERROR_MES = 'Не найдена компания, указанная в задолженности. УИ суммы: ' + CAST( @CustomerInitalDebt_Guid as nvarchar(36) );

        RETURN @ERROR_NUM;
      END 

    DECLARE @SQLString nvarchar( 2048 );
    DECLARE @ParmDefinition nvarchar( 500 );
    DECLARE @RETURNVALUE int;

		DECLARE @strCUSTOMERDEBT_BEGINDATE varchar( 24 );
		IF( @CUSTOMERDEBT_BEGINDATE IS NULL ) SET @strCUSTOMERDEBT_BEGINDATE = 'NULL'
		ELSE 
			BEGIN
				SET @strCUSTOMERDEBT_BEGINDATE = convert( varchar( 10), @CUSTOMERDEBT_BEGINDATE, 104);
				SET @strCUSTOMERDEBT_BEGINDATE = '''''' + @strCUSTOMERDEBT_BEGINDATE + '''''';
			END	

    SET @ParmDefinition = N'@ErrorNum_Ib int output, @ErrorText_Ib varchar(480) output'; 				

		SET @SQLString = 'SELECT @ErrorNum_Ib = ERROR_NUMBER, @ErrorText_Ib = ERROR_TEXT FROM OPENQUERY( ' + 
			@IBLINKEDSERVERNAME + ', ''SELECT ERROR_NUMBER, ERROR_TEXT FROM USP_EDIT_CUSTOMERDEBT_FROMSQL( ' +
					cast( @CUSTOMERDEBT_ID as nvarchar(10))  + ', ' +
					cast( @CUSTOMER_ID as nvarchar(10))  + ', ' +
					'''''' + cast( @CURRENCY_CODE as nvarchar(3)) + '''''' + ', ' +
					cast( @COMPANY_ID as nvarchar(10))  + ', ' +
					cast( @CHILDCUST_ID as nvarchar(10))  + ', ' +
					'''''' + cast( @CUSTOMERDEBT_SRCDOC as nvarchar(16)) + '''''' + ', ' +
					@strCUSTOMERDEBT_BEGINDATE + ', ' +
					 convert( varchar(50),cast( @CUSTOMERDEBT_INITIALDEBT as money ) ) + ', ' +
					cast( @PAYMENTTYPE_ID as nvarchar(10))  + ' )'' )';

		PRINT @SQLString;

    EXECUTE sp_executesql @SQLString, @ParmDefinition, @ErrorNum_Ib = @ERROR_NUM output, @ErrorText_Ib = @ERROR_MES output;  
		
	END TRY
	
	BEGIN CATCH
    SET @ERROR_NUM = ERROR_NUMBER();
    SET @ERROR_MES = @ERROR_MES + ' ' + ERROR_MESSAGE();

		RETURN @ERROR_NUM;
	END CATCH;

	IF( @ERROR_NUM = 0 )
		SET @ERROR_MES = 'Успешное завершение операции. Код задолженности в IB: ' + CAST( @CUSTOMERDEBT_ID as nvarchar( 56 ) );

	RETURN @ERROR_NUM;

END

GO
GRANT EXECUTE ON [dbo].[usp_EditCustomerInitalDebtToIB] TO [public]
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Редактирует запись в таблицt T_CustomerInitalDebt
--
-- Входные параметры:
--
--		@CustomerInitalDebt_Guid		- УИ записи
--		@Customer_Guid							- УИ клиента
--		@Currency_Guid							- УИ валюты
--		@CustomerInitalDebt_Date		- Дата
--		@CustomerInitalDebt_DocNum	- № документа
--		@CustomerInitalDebt_Value		- сумма задолженности
--		@Company_Guid								- УИ компании
--		@ChildDepart_Guid						- УИ дочернего клиента
--		@PaymentType_Guid						- УИ формы платежа

-- Выходные параметры:
--
--  @ERROR_NUM										- номер ошибки
--  @ERROR_MES										- текст ошибки
--
-- Результат:
--    0 - Успешное завершение
--    <>0 - ошибка

CREATE PROCEDURE [dbo].[usp_EditCustomerInitalDebtToSQLandIB] 
  @CustomerInitalDebt_Guid		D_GUID,
	@Customer_Guid							D_GUID,
	@Currency_Guid							D_GUID,
	@CustomerInitalDebt_Date		D_Date,
	@CustomerInitalDebt_DocNum	D_Name,
	@CustomerInitalDebt_Value		D_Money,
	@Company_Guid								D_GUID,
	@ChildDepart_Guid						D_GUID_NULL = NULL,
	@PaymentType_Guid						D_GUID_NULL,

  @ERROR_NUM									int output,
  @ERROR_MES									nvarchar(4000) output

AS

BEGIN

	BEGIN TRY

    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';
    
		-- проверка наличия задолженности
			IF NOT EXISTS ( SELECT [CustomerInitalDebt_Guid] FROM [dbo].[T_CustomerInitalDebt]	WHERE [CustomerInitalDebt_Guid] = @CustomerInitalDebt_Guid )
			BEGIN
				SET @ERROR_NUM = 1;
				SET @ERROR_MES = 'В базе данных не найдена задолженность с указанным идентификатором: ' + CAST( @CustomerInitalDebt_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- компания
		IF( @Company_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [Company_Guid] FROM [dbo].[T_Company]	WHERE [Company_Guid] = @Company_Guid )
			BEGIN
				SET @ERROR_NUM = 1;
				SET @ERROR_MES = 'В базе данных не найдена компания с указанным идентификатором: ' + CAST( @Company_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

     -- клиент
     IF( @Customer_Guid IS NOT NULL)
       IF NOT EXISTS ( SELECT Customer_Guid FROM dbo.T_Customer WHERE Customer_Guid = @Customer_Guid )
        BEGIN
         SET @ERROR_NUM = 2;
         SET @ERROR_MES = 'В базе данных не найден клиент с указанным идентификатором: ' + CAST( @Customer_Guid as nvarchar(36) );

         RETURN @ERROR_NUM;
        END    

    -- дочерний клиент
		DECLARE	@CustomerChild_Guid	D_GUID_NULL = NULL;
		IF( @ChildDepart_Guid IS NOT NULL )
			BEGIN
				SELECT @CustomerChild_Guid = [CustomerChild_Guid] FROM [dbo].[T_CustomerChild]
				WHERE ( [ChildDepart_Guid] = @ChildDepart_Guid ) AND ( [Customer_Guid] = @Customer_Guid );

				IF( @CustomerChild_Guid IS NULL )
					BEGIN
						SET @ERROR_NUM = 3;
						SET @ERROR_MES = 'В базе данных не найден дочерний клиент с указанным идентификатором: ' + CAST( @ChildDepart_Guid as nvarchar(36) );

						RETURN @ERROR_NUM;
					END	
			END

    -- форма оплаты
		IF( @PaymentType_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [PaymentType_Guid]  FROM [dbo].[T_PaymentType]
				WHERE [PaymentType_Guid] = @PaymentType_Guid )
			BEGIN
				SET @ERROR_NUM = 4;
				SET @ERROR_MES = 'В базе данных не найдена форма оплаты с указанным идентификатором: ' + CAST( @PaymentType_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

     -- валюта
		 IF NOT EXISTS ( SELECT Currency_Guid FROM dbo.T_Currency WHERE Currency_Guid = @Currency_Guid )
      BEGIN
        SET @ERROR_NUM = 5;
        SET @ERROR_MES = 'В базе данных не найдена валюта с указанным идентификатором: ' + CAST( @Currency_Guid as nvarchar(36) );

        RETURN @ERROR_NUM;
      END    

    DECLARE @NewID D_GUID;
    SET @NewID = NEWID ( );	
                
    BEGIN TRANSACTION UpdateData;

    UPDATE [dbo].[T_CustomerInitalDebt]	SET [Customer_Guid] = @Customer_Guid, [Currency_Guid] = @Currency_Guid, 
			[CustomerInitalDebt_Date] = @CustomerInitalDebt_Date, [CustomerInitalDebt_DocNum] = @CustomerInitalDebt_DocNum,
			[CustomerInitalDebt_Value] = @CustomerInitalDebt_Value, [Company_Guid] = @Company_Guid, 
			[CustomerChild_Guid] = @CustomerChild_Guid, [PaymentType_Guid] = @PaymentType_Guid
		WHERE [CustomerInitalDebt_Guid] = @CustomerInitalDebt_Guid;

    EXEC dbo.usp_EditCustomerInitalDebtToIB @CustomerInitalDebt_Guid = @CustomerInitalDebt_Guid, @IBLINKEDSERVERNAME = NULL,
			@ERROR_NUM = @ERROR_NUM output, @ERROR_MES = @ERROR_MES output;

		IF( @ERROR_NUM = 0 )
			BEGIN
				COMMIT TRANSACTION UpdateData
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
		SET @ERROR_MES = 'Успешное завершение операции. ' + @ERROR_MES;

	RETURN @ERROR_NUM;
END

GO
GRANT EXECUTE ON [dbo].[usp_EditCustomerInitalDebtToSQLandIB] TO [public]
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Удаляет в InterBase информацию о задолженности клиента

-- Входные параметры
-- @CustomerInitalDebt_Guid	- УИ задолженности
-- @IBLINKEDSERVERNAME				- имя LINKEDSERVER

-- Выходные параметры
-- @ERROR_NUM								- код ошибки
-- @ERROR_MES								- тест ошибки

CREATE PROCEDURE [dbo].[usp_DeleteCustomerInitalDebtFromIB]
  @CustomerInitalDebt_Guid	D_GUID,
  @IBLINKEDSERVERNAME				D_NAME = NULL,

  @ERROR_NUM								int output,
  @ERROR_MES								nvarchar(4000) output
AS

BEGIN
  BEGIN TRY
    SET @ERROR_NUM = -1;
    SET @ERROR_MES = '';

 	  IF( @IBLINKEDSERVERNAME IS NULL ) SELECT @IBLINKEDSERVERNAME = dbo.GetIBLinkedServerName();

    DECLARE @strIBSQLText nvarchar( 250 );
    DECLARE	@CUSTOMERDEBT_ID int; 

		-- проверка наличия задолженности
			IF NOT EXISTS ( SELECT [CustomerInitalDebt_Guid] FROM [dbo].[T_CustomerInitalDebt]	WHERE [CustomerInitalDebt_Guid] = @CustomerInitalDebt_Guid )
			BEGIN
				SET @ERROR_NUM = 1;
				SET @ERROR_MES = 'В базе данных не найдена задолженность с указанным идентификатором: ' + CAST( @CustomerInitalDebt_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	
      
		SELECT @CUSTOMERDEBT_ID = [CustomerInitalDebt_Id]
		FROM [dbo].[T_CustomerInitalDebt] WHERE [CustomerInitalDebt_Guid] = @CustomerInitalDebt_Guid;
		
    DECLARE @SQLString nvarchar( 2048 );
    DECLARE @ParmDefinition nvarchar( 500 );
    DECLARE @RETURNVALUE int;


    SET @ParmDefinition = N'@ErrorNum_Ib int output, @ErrorText_Ib varchar(480) output'; 

    
    SET @SQLString = 'SELECT @ErrorNum_Ib = ERROR_NUMBER, @ErrorText_Ib = ERROR_TEXT FROM OPENQUERY( ' + 
			@IBLINKEDSERVERNAME + ', ''SELECT ERROR_NUMBER, ERROR_TEXT FROM USP_DELETE_CUSTOMERDEBT_FROMSQL( ' +
			'''''' + cast( @CUSTOMERDEBT_ID as nvarchar(50)) + ''''' )'' )'; 

    EXECUTE sp_executesql @SQLString, @ParmDefinition, @ErrorNum_Ib = @ERROR_NUM output, @ErrorText_Ib = @ERROR_MES output;

 	END TRY
	BEGIN CATCH
    SET @ERROR_NUM = ERROR_NUMBER();
    SET @ERROR_MES = ERROR_MESSAGE();

		RETURN @ERROR_NUM;
	END CATCH;

	RETURN @ERROR_NUM;

END

GO
GRANT EXECUTE ON [dbo].[usp_EditCustomerInitalDebtToSQLandIB] TO [public]
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Удаление элемента из таблицы dbo.T_CustomerInitalDebt
--
-- Входные параметры
-- @CustomerInitalDebt_Guid	- УИ задолженности

-- Выходные параметры
-- @ERROR_NUM								- код ошибки
-- @ERROR_MES								- тест ошибки

-- Результат:
--    0 - успешное завершение
--    <>0 - ошибка

CREATE PROCEDURE [dbo].[usp_DeleteCustomerInitalDebt] 
	@CustomerInitalDebt_Guid	D_GUID,

  @ERROR_NUM								int output,
  @ERROR_MES								nvarchar(4000) output

AS

BEGIN

  SET @ERROR_NUM = 0;
  SET @ERROR_MES = '';

	BEGIN TRY

		-- проверка наличия задолженности
			IF NOT EXISTS ( SELECT [CustomerInitalDebt_Guid] FROM [dbo].[T_CustomerInitalDebt]	WHERE [CustomerInitalDebt_Guid] = @CustomerInitalDebt_Guid )
			BEGIN
				SET @ERROR_NUM = 1;
				SET @ERROR_MES = 'В базе данных не найдена задолженность с указанным идентификатором: ' + CAST( @CustomerInitalDebt_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

		BEGIN TRANSACTION UpdateData;	
	
		EXEC dbo.usp_DeleteCustomerInitalDebtFromIB @CustomerInitalDebt_Guid = @CustomerInitalDebt_Guid, @IBLINKEDSERVERNAME = NULL, 
			@ERROR_NUM = @ERROR_NUM output, @ERROR_MES = @ERROR_MES output;

		IF( @ERROR_NUM = 0 ) 
			BEGIN
				DELETE FROM dbo.[T_CustomerInitalDebt] WHERE [CustomerInitalDebt_Guid] = @CustomerInitalDebt_Guid;
				
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
		SET @ERROR_MES = @ERROR_MES + ' Задолженность удалена. УИ записи: ' + CAST( @CustomerInitalDebt_Guid as nvarchar(36) );
	
	RETURN @ERROR_NUM;
END

GO
GRANT EXECUTE ON [dbo].[usp_DeleteCustomerInitalDebt] TO [public]
GO



SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Производит операцию Сторно по задолженности (форма оплаты №1) в InterBase

-- Входные параметры
-- 
--		@CustomerInitalDebt_Guid				- УИ задолженности
--		@IBLINKEDSERVERNAME							- имя LINKEDSERVER для подключения к InterBase
--
-- Выходные параметры
--
--		@DEC_AMOUNT											- фактически проведённая сумма Сторно
--		@CustomerInitalDebt_AmountPaid	- итоговая сумма оплаты задолженности
--		@CustomerInitalDebt_Saldo				- сальдо задолженности
--		@ERROR_NUM											- номер ошибки
--		@ERROR_MES											- сообщение об ошибке

CREATE PROCEDURE [dbo].[usp_DecPayCustomerInitialDebtForm1InIB]
	@CustomerInitalDebt_Guid				D_GUID,
	@IBLINKEDSERVERNAME							D_NAME = NULL,

  @DEC_AMOUNT											D_MONEY output,
  @CustomerInitalDebt_AmountPaid	D_MONEY output,
  @CustomerInitalDebt_Saldo				D_MONEY output,
	@ERROR_NUM											int output,
	@ERROR_MES											nvarchar(4000) output
AS

BEGIN
  BEGIN TRY
    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';
		SET @DEC_AMOUNT = 0;
		SET @CustomerInitalDebt_AmountPaid = 0;
		SET @CustomerInitalDebt_Saldo = 0;

		IF NOT EXISTS ( SELECT CustomerInitalDebt_Guid FROM dbo.[T_CustomerInitalDebt] WHERE CustomerInitalDebt_Guid = @CustomerInitalDebt_Guid )
			BEGIN
				SET @ERROR_NUM = 1;
				SET @ERROR_MES = 'В базе данных не найдена задолженность с указанным идентификатором: ' + CAST( @CustomerInitalDebt_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END       
		
		DECLARE @INITIALDEBT_ID D_ID;

		SELECT @INITIALDEBT_ID = [CustomerInitalDebt_Id]
		FROM dbo.[T_CustomerInitalDebt] WHERE CustomerInitalDebt_Guid = @CustomerInitalDebt_Guid;
		IF( ( @INITIALDEBT_ID IS NULL ) OR ( @INITIALDEBT_ID = 0 ) )
			BEGIN
				SET @ERROR_NUM = 2;
				SET @ERROR_MES = 'В базе данных не найден идентификатор задолженности для УИ: ' + CAST( @CustomerInitalDebt_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END

	  IF( @IBLINKEDSERVERNAME IS NULL ) SELECT @IBLINKEDSERVERNAME = dbo.GetIBLinkedServerName();
	  
    DECLARE @SQLString nvarchar( 2048 );
    DECLARE @ParmDefinition nvarchar( 500 );

    SET @ParmDefinition = N' @DEC_AMOUNT_Ib money output, @CUSTOMERINITALDEBT_AMOUNTPAID_Ib money output, @CUSTOMERINITALDEBT_SALDO_Ib money output, 
			@ErrorNum_Ib int output, @ErrorText_Ib varchar(480) output'; 				

		SET @SQLString = 'SELECT @DEC_AMOUNT_Ib = FINDED_MONEY, 
			@CUSTOMERINITALDEBT_AMOUNTPAID_Ib = CUSTOMERINITALDEBT_AMOUNTPAID, @CUSTOMERINITALDEBT_SALDO_Ib = CUSTOMERINITALDEBT_SALDO, 
			@ErrorNum_Ib = ERROR_NUMBER, @ErrorText_Ib = ERROR_TEXT  FROM OPENQUERY( ' + 
			@IBLINKEDSERVERNAME + ', ''SELECT FINDED_MONEY, CUSTOMERINITALDEBT_AMOUNTPAID, CUSTOMERINITALDEBT_SALDO, ERROR_NUMBER, ERROR_TEXT  FROM USP_UNSETTLEINITIALDEBT_FROMSQL( ' + 
					cast( @INITIALDEBT_ID as nvarchar(20)) + ' )'' )'; 

		PRINT @SQLString;

    EXECUTE sp_executesql @SQLString, @ParmDefinition, @DEC_AMOUNT_Ib = @DEC_AMOUNT output, 
			@CUSTOMERINITALDEBT_AMOUNTPAID_Ib = @CustomerInitalDebt_AmountPaid output, 
			@CUSTOMERINITALDEBT_SALDO_Ib = @CustomerInitalDebt_Saldo output, 
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
GRANT EXECUTE ON [dbo].[usp_DecPayCustomerInitialDebtForm1InIB] TO [public]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Производит операцию Сторно по задолженности

-- Входные параметры
-- 
--		@CustomerInitalDebt_Guid				- УИ задолженности
--
-- Выходные параметры
--
--		@DEC_AMOUNT											- фактически проведённая сумма Сторно
--		@CustomerInitalDebt_AmountPaid	- итоговая сумма оплаты задолженности
--		@CustomerInitalDebt_Saldo				- сальдо задолженности
--		@ERROR_NUM											- номер ошибки
--		@ERROR_MES											- сообщение об ошибке

CREATE PROCEDURE [dbo].[usp_DecPayCustomerInitialDebtForm1ToSQLandIB] 
	@CustomerInitalDebt_Guid				D_GUID,

  @DEC_AMOUNT											D_MONEY output,
  @CustomerInitalDebt_AmountPaid	D_MONEY output,
  @CustomerInitalDebt_Saldo				D_MONEY output,
	@ERROR_NUM											int output,
	@ERROR_MES											nvarchar(4000) output

AS

BEGIN

	BEGIN TRY
    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';
		SET @DEC_AMOUNT = 0;
		SET @CustomerInitalDebt_AmountPaid = 0;
		SET @CustomerInitalDebt_Saldo = 0;

		IF NOT EXISTS ( SELECT CustomerInitalDebt_Guid FROM dbo.[T_CustomerInitalDebt] WHERE CustomerInitalDebt_Guid = @CustomerInitalDebt_Guid )
			BEGIN
				SET @ERROR_NUM = 1;
				SET @ERROR_MES = 'В базе данных не найдена задолженность с указанным идентификатором: ' + CAST( @CustomerInitalDebt_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END       
    
    BEGIN TRANSACTION UpdateData;

	    EXEC dbo.usp_DecPayCustomerInitialDebtForm1InIB @CustomerInitalDebt_Guid = @CustomerInitalDebt_Guid, 
				@IBLINKEDSERVERNAME = NULL, 
				@DEC_AMOUNT = @DEC_AMOUNT output, @CustomerInitalDebt_AmountPaid = @CustomerInitalDebt_AmountPaid output, 
				@CustomerInitalDebt_Saldo = @CustomerInitalDebt_Saldo output, 
				@ERROR_NUM = @ERROR_NUM output, @ERROR_MES = @ERROR_MES output;

		IF( @ERROR_NUM = 0 )
			BEGIN
				IF( @DEC_AMOUNT > 0 ) 
					UPDATE [dbo].[T_CustomerInitalDebt] SET [CustomerInitalDebt_AmountPaid] = @CustomerInitalDebt_AmountPaid
					WHERE CustomerInitalDebt_Guid = @CustomerInitalDebt_Guid;

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
GRANT EXECUTE ON [dbo].[usp_DecPayCustomerInitialDebtForm1ToSQLandIB] TO [public]
GO
