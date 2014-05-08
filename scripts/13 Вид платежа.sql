USE [ERP_Mercury]
GO

CREATE TYPE [dbo].[D_ERROR_MESSAGE] FROM [nvarchar](4000)
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[T_EarningType](
	[EarningType_Guid] [dbo].[D_GUID] NOT NULL,
	[EarningType_Name] [dbo].[D_NAME] NOT NULL,
	[EarningType_Description] [dbo].[D_DESCRIPTION] NULL,
	[EarningType_IsActive] [dbo].[D_ISACTIVE] NOT NULL,
	[EarningType_IsDefault] [dbo].[D_YESNO] NOT NULL,
	[EarningType_DublicateInIB] [dbo].[D_YESNO] NOT NULL,
	[EarningType_Id] [dbo].[D_ID] NOT NULL,
	[Record_Updated] [dbo].[D_DATETIME] NULL,
	[Record_UserUdpated] [dbo].[D_NAMESHORT] NULL,
 CONSTRAINT [PK_T_EarningType] PRIMARY KEY CLUSTERED 
(
	[EarningType_Guid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


SET ANSI_PADDING ON


GO

CREATE UNIQUE NONCLUSTERED INDEX [INDX_EarningType_EarningTypeName] ON [dbo].[T_EarningType]
(
	[EarningType_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [INDEX]

GO


CREATE UNIQUE NONCLUSTERED INDEX [INDX_EarningType_EarningTypeId] ON [dbo].[T_EarningType]
(
	[EarningType_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [INDEX]

GO


CREATE  NONCLUSTERED INDEX [INDX_EarningType_EarningTypeIsDefault] ON [dbo].[T_EarningType]
(
	[EarningType_IsDefault] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [INDEX]

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Добавляет новую запись в таблицу dbo.T_EarningType (вид оплаты)
--
-- Входные параметры:
--
--		@EarningType_Name					наименование вида оплаты
--		@EarningType_Description	примечание
--		@EarningType_IsActive			признак "запись используется в новых документах"
--		@EarningType_IsDefault		признак "использовать по умолчанию в документах"
--		@EarningType_Id						целочисленный код вида оплаты
--		@EarningType_DublicateInIB признак "дублировать запись в InterBase"
--
-- Выходные параметры:
--
--  @EarningType_Guid					уникальный идентификатор записи
--  @ERROR_NUM									код ошибки
--  @ERROR_MES									текст ошибки
--
-- Результат:
--    0 - Успешное завершение
--    <>0 - ошибка

CREATE PROCEDURE [dbo].[usp_AddEarningType] 
	@EarningType_Name					[dbo].[D_NAME],
	@EarningType_Description	[dbo].[D_DESCRIPTION] = NULL,
	@EarningType_IsActive			[dbo].[D_ISACTIVE] = 1,
	@EarningType_IsDefault		[dbo].[D_YESNO] = 0,
	@EarningType_Id						[dbo].[D_ID],
	@EarningType_DublicateInIB [dbo].[D_YESNO] = 0,

  @EarningType_Guid					D_GUID output,
  @ERROR_NUM								D_ID output,
  @ERROR_MES								D_ERROR_MESSAGE output

AS

BEGIN

	BEGIN TRY

    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';
    SET @EarningType_Guid = NULL;

    -- Проверяем наличие записи с заданным именем
    IF EXISTS ( SELECT * FROM dbo.T_EarningType	WHERE EarningType_Name = @EarningType_Name )
      BEGIN
        SET @ERROR_NUM = 1;
        SET @ERROR_MES = 'В базе данных уже зарегистрирован вид оплаты с указанным наименованием.' + Char(13) + 
          'Вид оплаты: ' + Char(9) + @EarningType_Name;
        RETURN @ERROR_NUM;
      END

    -- Проверяем наличие записи с заданным кодом
    IF EXISTS ( SELECT * FROM dbo.T_EarningType	WHERE EarningType_Id = @EarningType_Id )
      BEGIN
        SET @ERROR_NUM = 2;
        SET @ERROR_MES = 'В базе данных уже зарегистрирован вид оплаты с указанным кодом.' + Char(13) + 
          'Код оплаты: ' + Char(9) + CONVERT( nvarchar(16),  @EarningType_Id );
        RETURN @ERROR_NUM;
      END

    DECLARE @NewID D_GUID;
    SET @NewID = NEWID ( );	
    
    INSERT INTO [dbo].[T_EarningType]( EarningType_Guid, EarningType_Name, EarningType_Description, EarningType_IsActive, 
			EarningType_IsDefault, EarningType_Id, EarningType_DublicateInIB, Record_Updated, Record_UserUdpated )
    VALUES( @NewID, @EarningType_Name, @EarningType_Description, @EarningType_IsActive, 
			@EarningType_IsDefault, @EarningType_Id, @EarningType_DublicateInIB, sysutcdatetime(), ( Host_Name() + ': ' + SUSER_SNAME() ) );
    
    SET @EarningType_Guid = @NewID;

		IF( @EarningType_IsDefault = 1 )
			UPDATE [dbo].[T_EarningType] SET EarningType_IsDefault = 0 WHERE EarningType_Guid <> @EarningType_Guid;

	END TRY
	BEGIN CATCH
    SET @ERROR_NUM = ERROR_NUMBER();
    SET @ERROR_MES = ERROR_MESSAGE();
	END CATCH;

	IF( @ERROR_NUM = 0 )
		SET @ERROR_MES = 'Успешное завершение операции.';
		
	RETURN @ERROR_NUM;
END

GO
GRANT EXECUTE ON [dbo].[usp_AddEarningType] TO [public]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Редактирует запись в таблице dbo.T_EarningType
--
-- Входные параметры:
--
--  @EarningType_Guid					уникальный идентификатор записи
--		@EarningType_Name					наименование вида оплаты
--		@EarningType_Description	примечание
--		@EarningType_IsActive			признак "запись используется в новых документах"
--		@EarningType_IsDefault		признак "использовать по умолчанию в документах"
--		@EarningType_Id						целочисленный код вида оплаты
--		@EarningType_DublicateInIB признак "дублировать запись в InterBase"
--
-- Выходные параметры:
--
--  @ERROR_NUM									код ошибки
--  @ERROR_MES									текст ошибки
--
-- Результат:
--    0 - Успешное завершение
--    <>0 - ошибка

CREATE PROCEDURE [dbo].[usp_EditEarningType] 
  @EarningType_Guid					D_GUID,
	@EarningType_Name					[dbo].[D_NAME],
	@EarningType_Description	[dbo].[D_DESCRIPTION] = NULL,
	@EarningType_IsActive			[dbo].[D_ISACTIVE] = 1,
	@EarningType_IsDefault		[dbo].[D_YESNO] = 0,
	@EarningType_Id						[dbo].[D_ID],
	@EarningType_DublicateInIB [dbo].[D_YESNO] = 0,

  @ERROR_NUM								D_ID output,
  @ERROR_MES								D_ERROR_MESSAGE output

AS

BEGIN

	BEGIN TRY

    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';

    -- Проверяем наличие записи с заданным именем
    IF EXISTS ( SELECT * FROM dbo.T_EarningType	WHERE EarningType_Name = @EarningType_Name AND EarningType_Guid <> @EarningType_Guid )
      BEGIN
        SET @ERROR_NUM = 1;
        SET @ERROR_MES = 'В базе данных уже зарегистрирован вид оплаты с указанным наименованием.' + Char(13) + 
          'Вид оплаты: ' + Char(9) + @EarningType_Name;
        RETURN @ERROR_NUM;
      END

    -- Проверяем наличие записи с заданным кодом
    IF EXISTS ( SELECT * FROM dbo.T_EarningType	WHERE EarningType_Id = @EarningType_Id AND EarningType_Guid <> @EarningType_Guid )
      BEGIN
        SET @ERROR_NUM = 2;
        SET @ERROR_MES = 'В базе данных уже зарегистрирован вид оплаты с указанным кодом.' + Char(13) + 
          'Код оплаты: ' + Char(9) + CONVERT( nvarchar(16),  @EarningType_Id );
        RETURN @ERROR_NUM;
      END

    UPDATE [dbo].[T_EarningType]	SET EarningType_Name = @EarningType_Name, EarningType_Description = @EarningType_Description, 
			EarningType_IsActive = @EarningType_IsActive, EarningType_IsDefault = @EarningType_IsDefault, 
			EarningType_Id = @EarningType_Id, EarningType_DublicateInIB = @EarningType_DublicateInIB,
			Record_Updated = sysutcdatetime(), Record_UserUdpated = ( Host_Name() + ': ' + SUSER_SNAME() )
		WHERE EarningType_Guid = @EarningType_Guid;
    
		IF( @EarningType_IsDefault = 1 )
			UPDATE [dbo].[T_EarningType] SET EarningType_IsDefault = 0 WHERE EarningType_Guid <> @EarningType_Guid;

	END TRY
	BEGIN CATCH
    SET @ERROR_NUM = ERROR_NUMBER();
    SET @ERROR_MES = ERROR_MESSAGE();
	END CATCH;

	IF( @ERROR_NUM = 0 )
		SET @ERROR_MES = 'Успешное завершение операции.';
		
	RETURN @ERROR_NUM;
END

GO
GRANT EXECUTE ON [dbo].[usp_EditEarningType] TO [public]
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Возвращает список записей из таблицы T_EarningType
--
-- Входные параметры:
--
--		@EarningType_Guid					УИ записи
--
-- Выходные параметры:
--
--  @ERROR_NUM									код ошибки
--  @ERROR_MES									текст ошибки
--
-- Результат:
--		0 - Успешное завершение
--		<>0 - ошибка
--

CREATE PROCEDURE [dbo].[usp_GetEarningType] 
	@EarningType_Guid		D_GUID = NULL,
	
  @ERROR_NUM					D_ID output,
  @ERROR_MES					D_ERROR_MESSAGE output
AS

BEGIN

  SET @ERROR_NUM = 0;
  SET @ERROR_MES = '';

  BEGIN TRY

    IF( @EarningType_Guid IS NULL )
			BEGIN
				SELECT EarningType_Guid, EarningType_Name, EarningType_Description, EarningType_IsActive, 
					EarningType_IsDefault, EarningType_Id, EarningType_DublicateInIB, Record_Updated, Record_UserUdpated
				FROM [dbo].[T_EarningType]
				ORDER BY EarningType_Id;
			END
		ELSE	
			BEGIN
				SELECT EarningType_Guid, EarningType_Name, EarningType_Description, EarningType_IsActive, 
					EarningType_IsDefault, EarningType_Id, EarningType_DublicateInIB, Record_Updated, Record_UserUdpated
				FROM [dbo].[T_EarningType]
				WHERE EarningType_Guid = @EarningType_Guid;
			END
	END TRY
	BEGIN CATCH
		SET @ERROR_NUM = ERROR_NUMBER();
		SET @ERROR_MES = ERROR_MESSAGE();
	END CATCH;

  IF( @ERROR_NUM = 0 )
		SET @ERROR_MES = 'Успешное завершение операции.';
		
  RETURN @ERROR_NUM;
END

GO
GRANT EXECUTE ON [dbo].[usp_GetEarningType] TO [public]
GO

 DECLARE @EarningType_Guid	D_GUID;

 SET @EarningType_Guid = 'E46953E2-D7D7-4D79-96C4-E17260D9379F';
 INSERT INTO [dbo].[T_EarningType]( EarningType_Guid, EarningType_Name, EarningType_Description, 
	EarningType_IsActive, EarningType_IsDefault, EarningType_DublicateInIB, EarningType_Id, Record_Updated, Record_UserUdpated )
 VALUES( @EarningType_Guid, 'оплата за товар', 'клиент оплачивает за твоар', 
  1,  1, 1, 0, GetDate(), ( Host_Name() + ': ' + SUSER_SNAME() ) );	

 SET @EarningType_Guid = 'B5D55C25-FBAA-4CDB-A2F3-E9EE76F82413';
 INSERT INTO [dbo].[T_EarningType]( EarningType_Guid, EarningType_Name, EarningType_Description, 
	EarningType_IsActive, EarningType_IsDefault, EarningType_DublicateInIB, EarningType_Id, Record_Updated, Record_UserUdpated )
 VALUES( @EarningType_Guid, 'транзитная проводка', 'перечисление средств между компаниями', 
  1,  0, 0, 1, GetDate(), ( Host_Name() + ': ' + SUSER_SNAME() ) );	

 SET @EarningType_Guid = 'EC493E9D-BA1B-42EA-8B0D-A168E97C3C4A';
 INSERT INTO [dbo].[T_EarningType]( EarningType_Guid, EarningType_Name, EarningType_Description, 
	EarningType_IsActive, EarningType_IsDefault, EarningType_DublicateInIB, EarningType_Id, Record_Updated, Record_UserUdpated )
 VALUES( @EarningType_Guid, 'получение кредита', 'получение кредита', 
  1,  0, 0, 2, GetDate(), ( Host_Name() + ': ' + SUSER_SNAME() ) );	


ALTER TABLE [dbo].[T_Earning] ADD EarningType_Guid D_GUID NULL
GO

UPDATE [dbo].[T_Earning] SET EarningType_Guid = 'E46953E2-D7D7-4D79-96C4-E17260D9379F'
GO

UPDATE [dbo].[T_Earning] SET EarningType_Guid = 'B5D55C25-FBAA-4CDB-A2F3-E9EE76F82413'
WHERE ( [BudgetProjectSRC_Guid] IS NOT NULL ) AND ( [CompanyPayer_Guid] IS NOT NULL )
GO

UPDATE [dbo].[T_Earning] SET EarningType_Guid = 'EC493E9D-BA1B-42EA-8B0D-A168E97C3C4A'
WHERE Earning_Id IN ( 246839, 246837, 246838, 246899, 246945, 246946,
  246843, 246844, 246901, 246902, 246907 )
GO

ALTER TABLE [dbo].[T_Earning]  WITH CHECK ADD  CONSTRAINT [FK_T_Earning_T_EarningType] FOREIGN KEY([EarningType_Guid])
REFERENCES [dbo].[T_EarningType] ([EarningType_Guid])
GO

ALTER TABLE [dbo].[T_Earning] CHECK CONSTRAINT [FK_T_Earning_T_EarningType]
GO


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
--		@EarningType_Guid						- УИ вида оплаты

-- Выходные параметры:
--
--  @ERROR_NUM										- номер ошибки
--  @ERROR_MES										- текст ошибки
--
-- Результат:
--    0 - Успешное завершение
--    <>0 - ошибка

ALTER PROCEDURE [dbo].[usp_EditCEarningInSQLandIB] 
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

    BEGIN TRANSACTION UpdateData;

		UPDATE [dbo].[T_Earning] SET Customer_Guid = @Earning_CustomerGuid, Currency_Guid = @Earning_CurrencyGuid,	
			Earning_Date = @Earning_Date, Earning_DocNum = @Earning_DocNum, Bank_Guid= @Bank_Guid, 
			Account_Guid = @Account_Guid, Earning_Value = @Earning_Value, Company_Guid = @Earning_CompanyGuid, 
			Earning_CurrencyRate = @Earning_CurrencyRate, Earning_CurrencyValue = @Earning_CurrencyValue, 
			Earning_CustomerText = @Earning_CustomerText, Earning_DetailsPaymentText = @Earning_DetailsPaymentText, 
			Earning_iKey = @Earning_iKey, BudgetProjectSRC_Guid = @BudgetProjectSRC_Guid, 
			BudgetProjectDST_Guid = @BudgetProjectDST_Guid,	CompanyPayer_Guid = @CompanyPayer_Guid,
			CustomerChild_Guid = @CustomerChild_Guid,	AccountPlan_Guid = @AccountPlan_Guid,	
			PaymentType_Guid = @PaymentType_Guid,	Earning_IsBonus = @Earning_IsBonus, EarningType_Guid = @EarningType_Guid
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
			SELECT TOP 1 @EarningType_Guid = [EarningType_Guid] FROM [dbo].[T_EarningType] WHERE [EarningType_IsDefault] = 1;

    BEGIN TRANSACTION UpdateData;

		DECLARE @CurrencyMainGuid D_GUID; 

		SELECT TOP 1 @CurrencyMainGuid = [Currency_Guid] FROM [dbo].[T_Currency]
		WHERE [Currency_IsMain] = 1;
		SELECT @Earning_CurrencyRate = [dbo].[GetCurrencyRatePricingInOut]( @CurrencyMainGuid, @Earning_CurrencyGuid, @Earning_Date );

		DECLARE @Earning_ValueByCurrencyRate money = 0;
		IF( @Earning_CurrencyRate <> 0 )
			SET @Earning_ValueByCurrencyRate = ( @Earning_Value/@Earning_CurrencyRate );

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

ALTER PROCEDURE [dbo].[usp_AddCEarningToSQLandIB] 
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

    DECLARE @NewID D_GUID;
    SET @NewID = NEWID ( );	
                
    DECLARE @Earning_Id D_ID;
    EXEC @Earning_Id = SP_GetGeneratorID @strTableName = 'T_CEarning';
       
    
    BEGIN TRANSACTION UpdateData;

    INSERT INTO dbo.T_Earning ( Earning_Guid, Earning_Id, Customer_Guid, Currency_Guid,	Earning_Date, 
			Earning_DocNum, Bank_Guid, Account_Guid, Earning_Value, Earning_Expense, Company_Guid, 
			Earning_CurrencyRate, Earning_CurrencyValue, Earning_CustomerText, Earning_DetailsPaymentText, 
			Earning_iKey, BudgetProjectSRC_Guid, BudgetProjectDST_Guid,	CompanyPayer_Guid,
			CustomerChild_Guid,	AccountPlan_Guid,	PaymentType_Guid,	Earning_IsBonus, EarningType_Guid )
		VALUES( @NewID, @Earning_Id, @Earning_CustomerGuid, @Earning_CurrencyGuid, @Earning_Date, 
			@Earning_DocNum, @Bank_Guid,  @Account_Guid, @Earning_Value, 0, @Earning_CompanyGuid, 
			@Earning_CurrencyRate, @Earning_CurrencyValue, @Earning_CustomerText, @Earning_DetailsPaymentText, 
			@Earning_iKey, @BudgetProjectSRC_Guid, @BudgetProjectDST_Guid,	@CompanyPayer_Guid,
			@CustomerChild_Guid,	@AccountPlan_Guid,	@PaymentType_Guid,	@Earning_IsBonus, @EarningType_Guid );
        
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
			SELECT TOP 1 @EarningType_Guid = [EarningType_Guid] FROM [dbo].[T_EarningType] WHERE [EarningType_IsDefault] = 1;

    BEGIN TRANSACTION UpdateData;

		DECLARE @CurrencyMainGuid D_GUID; 

		SELECT TOP 1 @CurrencyMainGuid = [Currency_Guid] FROM [dbo].[T_Currency]
		WHERE [Currency_IsMain] = 1;
		SELECT @Earning_CurrencyRate = [dbo].[GetCurrencyRatePricingInOut]( @CurrencyMainGuid, @Earning_CurrencyGuid, @Earning_Date );

		DECLARE @Earning_ValueByCurrencyRate money = 0;
		IF( @Earning_CurrencyRate <> 0 )
			SET @Earning_ValueByCurrencyRate = ( @Earning_Value/@Earning_CurrencyRate );

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
		IF( @PaymentType_Guid IS NULL )
			SET @PaymentType_Guid = '58636EC5-F64A-462C-90B1-7686ADFE70F9'; -- форма оплаты №1
		
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

    DECLARE @NewID D_GUID;
    SET @NewID = NEWID ( );	

		DECLARE @CurrencyMainGuid D_GUID; 

		--SELECT TOP 1 @CurrencyMainGuid = [Currency_Guid] FROM [dbo].[T_Currency]
		--WHERE [Currency_IsMain] = 1;

		--SELECT @Earning_CurrencyRate = [dbo].[GetCurrencyRatePricingInOut]( @CurrencyMainGuid, @Earning_CurrencyGuid, @Earning_Date );
                
    DECLARE @Earning_Id D_ID;
    EXEC @Earning_Id = SP_GetGeneratorID @strTableName = 'T_Earning';
       
    
    INSERT INTO dbo.T_Earning ( Earning_Guid, Earning_Id, Customer_Guid, Currency_Guid,	Earning_Date, 
			Earning_DocNum, Bank_Guid, Account_Guid, Earning_Value, Earning_Expense, Company_Guid, 
			Earning_CurrencyRate, Earning_CurrencyValue, Earning_CustomerText, Earning_DetailsPaymentText, 
			Earning_iKey, BudgetProjectSRC_Guid, BudgetProjectDST_Guid,	CompanyPayer_Guid,
			CustomerChild_Guid,	AccountPlan_Guid,	PaymentType_Guid,	Earning_IsBonus, EarningType_Guid )
		VALUES( @NewID, @Earning_Id, @Earning_CustomerGuid, @Earning_CurrencyGuid, @Earning_Date, 
			@Earning_DocNum, @Bank_Guid,  @Account_Guid, @Earning_Value, 0, @Earning_CompanyGuid, 
			@Earning_CurrencyRate, @Earning_CurrencyValue, @Earning_CustomerText, @Earning_DetailsPaymentText, 
			@Earning_iKey, @BudgetProjectSRC_Guid, @BudgetProjectDST_Guid,	@CompanyPayer_Guid,
			@CustomerChild_Guid,	@AccountPlan_Guid,	@PaymentType_Guid,	@Earning_IsBonus, @EarningType_Guid );
        
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
		
		IF( @EarningType_Guid IS NULL ) SET @NEED_SAVE_IN_IB = 1;
		ELSE IF EXISTS( SELECT [EarningType_Guid] FROM [dbo].[T_EarningType] 
										WHERE [EarningType_Guid] = @EarningType_Guid 
											AND [EarningType_DublicateInIB] = 1 )
						SET @NEED_SAVE_IN_IB = 1;
		
		IF( @NEED_SAVE_IN_IB = 0 )
			BEGIN
				SET @Earning_Id = 0;
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
		
		IF( ( @BudgetProjectSRC_Guid IS NOT NULL ) AND ( @CompanyPayer_Guid IS NOT NULL ) )
			SET @EarningIsTransit = 1;
		ELSE
			SET @EarningIsTransit = 0;

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

ALTER PROCEDURE [dbo].[usp_AddCEarningToIB]
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
		
		IF( @EarningType_Guid IS NULL ) SET @NEED_SAVE_IN_IB = 1;
		ELSE IF EXISTS( SELECT [EarningType_Guid] FROM [dbo].[T_EarningType] 
										WHERE [EarningType_Guid] = @EarningType_Guid 
											AND [EarningType_DublicateInIB] = 1 )
						SET @NEED_SAVE_IN_IB = 1;
		
		IF( @NEED_SAVE_IN_IB = 0 )
			BEGIN
				SET @Earning_Id = 0;
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
			@Earning_BankAccount = [AccountViewAccount_Number], @Earning_BankCode = [Bank_Code], @CustomerChild_Id = [CustomerChild_Id], 
			@CEarning_Mode = [Earning_IsBonus]
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
		--SET @CEarning_Mode = 0;
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

			--DELETE FROM [dbo].[T_Log];
			--INSERT INTO [dbo].[T_Log]( [LOG_TEXT] ) VALUES( @SQLString );

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
		
		IF( @EarningType_Guid IS NULL ) SET @NEED_SAVE_IN_IB = 1;
		ELSE IF EXISTS( SELECT [EarningType_Guid] FROM [dbo].[T_EarningType] 
										WHERE [EarningType_Guid] = @EarningType_Guid 
											AND [EarningType_DublicateInIB] = 1 )
						SET @NEED_SAVE_IN_IB = 1;
		
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
				   
		IF( ( @BudgetProjectSRC_Guid IS NOT NULL ) AND ( @CompanyPayer_Guid IS NOT NULL ) )
			SET @EarningIsTransit = 1;
		ELSE
			SET @EarningIsTransit = 0;

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

ALTER PROCEDURE [dbo].[usp_EditCEarningInIB]
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
		
		IF( @EarningType_Guid IS NULL ) SET @NEED_SAVE_IN_IB = 1;
		ELSE IF EXISTS( SELECT [EarningType_Guid] FROM [dbo].[T_EarningType] 
										WHERE [EarningType_Guid] = @EarningType_Guid 
											AND [EarningType_DublicateInIB] = 1 )
						SET @NEED_SAVE_IN_IB = 1;
		
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
			@Earning_BankAccount = [AccountViewAccount_Number], @Earning_BankCode = [Bank_Code], @CustomerChild_Id = [CustomerChild_Id], 
			@CEarning_Mode = [Earning_IsBonus]
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
		--SET @CEarning_Mode = 0;
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
      
		DECLARE @EarningType_Guid uniqueidentifier;
		DECLARE @NEED_SAVE_IN_IB bit = 0;	     
		
		SELECT @EarningType_Guid = EarningType_Guid FROM dbo.[T_Earning] WHERE Earning_Guid = @Earning_Guid;
		
		IF( @EarningType_Guid IS NULL ) SET @NEED_SAVE_IN_IB = 1;
		ELSE IF EXISTS( SELECT [EarningType_Guid] FROM [dbo].[T_EarningType] 
										WHERE [EarningType_Guid] = @EarningType_Guid 
											AND [EarningType_DublicateInIB] = 1 )
						SET @NEED_SAVE_IN_IB = 1;
		
		IF( @NEED_SAVE_IN_IB = 0 )
			BEGIN
				SET @ERROR_NUM = 0;
				SET @ERROR_MES = 'Оплата не регистрируется в "Контракте"';

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

ALTER PROCEDURE [dbo].[usp_DeleteCEarningFromIB]
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
      
		DECLARE @EarningType_Guid uniqueidentifier;
		DECLARE @NEED_SAVE_IN_IB bit = 0;	     
		
		SELECT @EarningType_Guid = EarningType_Guid FROM dbo.[T_Earning] WHERE Earning_Guid = @Earning_Guid;
		
		IF( @EarningType_Guid IS NULL ) SET @NEED_SAVE_IN_IB = 1;
		ELSE IF EXISTS( SELECT [EarningType_Guid] FROM [dbo].[T_EarningType] 
										WHERE [EarningType_Guid] = @EarningType_Guid 
											AND [EarningType_DublicateInIB] = 1 )
						SET @NEED_SAVE_IN_IB = 1;
		
		IF( @NEED_SAVE_IN_IB = 0 )
			BEGIN
				SET @ERROR_NUM = 0;
				SET @ERROR_MES = 'Оплата не регистрируется в "Контракте"';

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
		PRINT @SQLString;
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


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Удаление элемента из таблицы dbo.T_EarningType
--
-- Входные параметры:
--
--		@EarningType_Guid					УИ записи
--
-- Выходные параметры:
--
--  @ERROR_NUM									код ошибки
--  @ERROR_MES									текст ошибки
--
-- Результат:
--		0 - Успешное завершение
--		<>0 - ошибка
--

CREATE PROCEDURE [dbo].[usp_DeleteEarningType] 
	@EarningType_Guid		D_GUID,

  @ERROR_NUM					D_ID output,
  @ERROR_MES					D_ERROR_MESSAGE output

AS

BEGIN

  SET @ERROR_NUM = 0;
  SET @ERROR_MES = NULL;

	BEGIN TRY

    -- Проверяем наличие записи с заданным именем
    IF EXISTS ( SELECT * FROM dbo.T_Earning	WHERE ( EarningType_Guid IS NOT NULL ) AND ( EarningType_Guid = @EarningType_Guid ) )
      BEGIN
        SET @ERROR_NUM = 1;
        SET @ERROR_MES = 'На указанный вид оплаты есть ссылка в журнале оплат. Операция удаления отменена.';
        
				RETURN @ERROR_NUM;
      END

   DELETE FROM dbo.T_EarningType WHERE EarningType_Guid = @EarningType_Guid;

	END TRY
	BEGIN CATCH
		SET @ERROR_NUM = ERROR_NUMBER();
		SET @ERROR_MES = ERROR_MESSAGE();
	END CATCH;

	IF( @ERROR_NUM = 0 )
		SET @ERROR_MES = 'Успешное завершение операции.';
		
	RETURN @ERROR_NUM;
END

GO
GRANT EXECUTE ON [dbo].[usp_DeleteEarningType] TO [public]
GO

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
                      dbo.AccountView.Bank_MFO AS AccountViewBank_MFO, dbo.T_PaymentType.PaymentType_Id, 
											dbo.T_Earning.EarningType_Guid, dbo.T_EarningType.EarningType_Name, dbo.T_EarningType.EarningType_Id, 
											dbo.T_EarningType.EarningType_IsActive, dbo.T_EarningType.EarningType_IsDefault, dbo.T_EarningType.EarningType_DublicateInIB
FROM         dbo.T_Earning LEFT OUTER JOIN
                      dbo.T_Customer ON dbo.T_Earning.Customer_Guid = dbo.T_Customer.Customer_Guid LEFT OUTER JOIN
                      dbo.T_CustomerStateType ON dbo.T_Customer.CustomerStateType_Guid = dbo.T_CustomerStateType.CustomerStateType_Guid LEFT OUTER JOIN
                      dbo.T_CustomerActiveType ON dbo.T_Customer.CustomerActiveType_Guid = dbo.T_CustomerActiveType.CustomerActiveType_Guid LEFT OUTER JOIN
                      dbo.T_Currency ON dbo.T_Earning.Currency_Guid = dbo.T_Currency.Currency_Guid LEFT OUTER JOIN
                      dbo.T_Company ON dbo.T_Earning.Company_Guid = dbo.T_Company.Company_Guid LEFT OUTER JOIN
                      dbo.T_BudgetProject AS BudgetProjectDST ON dbo.T_Earning.BudgetProjectDST_Guid = BudgetProjectDST.BUDGETPROJECT_GUID LEFT OUTER JOIN
                      dbo.T_BudgetProject AS BudgetProjectSRC ON dbo.T_Earning.BudgetProjectSRC_Guid = BudgetProjectSRC.BUDGETPROJECT_GUID LEFT OUTER JOIN
                      dbo.T_AccountPlan ON dbo.T_Earning.AccountPlan_Guid = dbo.T_AccountPlan.ACCOUNTPLAN_GUID LEFT OUTER JOIN
                      dbo.T_PaymentType ON dbo.T_Earning.PaymentType_Guid = dbo.T_PaymentType.PaymentType_Guid LEFT OUTER JOIN
                      dbo.T_Company AS CompanyPayer ON dbo.T_Earning.CompanyPayer_Guid = CompanyPayer.Company_Guid LEFT OUTER JOIN
                      dbo.T_Bank ON dbo.T_Earning.Bank_Guid = dbo.T_Bank.Bank_Guid LEFT OUTER JOIN
                      dbo.AccountView ON dbo.T_Earning.Account_Guid = dbo.AccountView.Account_Guid LEFT OUTER JOIN
                      dbo.CustomerChildView ON dbo.T_Earning.CustomerChild_Guid = dbo.CustomerChildView.CustomerChild_Guid LEFT OUTER JOIN
											dbo.T_EarningType ON dbo.T_Earning.EarningType_Guid = dbo.T_EarningType.EarningType_Guid

GO

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
			[AccountViewBank_Code] AS Earning_BankCode, 
			[EarningType_Guid], [EarningType_Name], [EarningType_Id], [EarningType_IsActive], [EarningType_IsDefault], [EarningType_DublicateInIB]
		FROM [dbo].[EarningView]	
		WHERE	[Company_Guid] = @Earning_guidCompany
			AND [Earning_Date] BETWEEN @Earning_DateBegin AND @Earning_DateEnd
			AND (  ( PaymentType_Id IS NULL ) OR ( PaymentType_Id = 1 ) )
	ORDER BY [Earning_Date];
	
  END TRY
	BEGIN CATCH
		SET @ERROR_NUM = ERROR_NUMBER();
		SET @ERROR_MES = ERROR_MESSAGE();
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

ALTER PROCEDURE [dbo].[usp_GetCEarningList] 
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
			[AccountViewBank_Code] AS Earning_BankCode,
			[EarningType_Guid], [EarningType_Name], [EarningType_Id], [EarningType_IsActive], [EarningType_IsDefault], [EarningType_DublicateInIB]
		FROM [dbo].[EarningView]	
		WHERE	[Earning_Date] BETWEEN @Earning_DateBegin AND @Earning_DateEnd
			AND (  ( PaymentType_Id IS NOT NULL ) AND ( PaymentType_Id = 2 ) )
	ORDER BY [Earning_Date];
	
  
  END TRY
	BEGIN CATCH
		SET @ERROR_NUM = ERROR_NUMBER();
		SET @ERROR_MES = ERROR_MESSAGE();
	END CATCH;

  IF( @ERROR_NUM = 0 )
		SET @ERROR_MES = 'Успешное завершение операции.';

  RETURN @ERROR_NUM;
END

GO
