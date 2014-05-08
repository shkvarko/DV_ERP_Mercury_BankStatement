USE [ERP_Mercury]
GO

INSERT INTO [dbo].[TS_GENERATOR]( GENERATOR_ID, TABLE_NAME )
VALUES( 0, 'T_BUDGETPROJECT' )
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[T_BudgetProject](
	[BUDGETPROJECT_GUID] [dbo].[D_GUID] NOT NULL,
	[BUDGETPROJECT_NAME] [dbo].[D_NAME] NOT NULL,
	[BUDGETPROJECT_DESCRIPTION] [dbo].[D_DESCRIPTION] NULL,
	[BUDGETPROJECT_ACTIVE] [dbo].[D_YESNO] NOT NULL,
	[BUDGETPROJECT_1C_CODE] [dbo].[D_ID] NOT NULL,
	[Record_Updated] [dbo].[D_DATETIME] NULL,
	[Record_UserUpdated] [dbo].[D_NAME] NULL,
 CONSTRAINT [PK_T_BUDGETPROJECT] PRIMARY KEY CLUSTERED 
(
	[BUDGETPROJECT_GUID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


CREATE NONCLUSTERED INDEX [INDX_T_BUDGETPROJECT_1C_Code] ON [dbo].[T_BUDGETPROJECT]
(
	[BUDGETPROJECT_1C_CODE] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [INDEX]
GO

CREATE NONCLUSTERED INDEX [INDX_T_BUDGETPROJECT_Active] ON [dbo].[T_BUDGETPROJECT]
(
	[BUDGETPROJECT_ACTIVE] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [INDEX]
GO

CREATE UNIQUE NONCLUSTERED INDEX [INDX_T_BUDGETPROJECT_Name] ON [dbo].[T_BUDGETPROJECT]
(
	[BUDGETPROJECT_NAME] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [INDEX]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[BudgetProjectView]
AS
SELECT BUDGETPROJECT_GUID, BUDGETPROJECT_NAME, BUDGETPROJECT_DESCRIPTION, BUDGETPROJECT_ACTIVE, BUDGETPROJECT_1C_CODE, Record_Updated, Record_UserUpdated
FROM [dbo].[T_BUDGETPROJECT]

GO

GRANT SELECT ON [dbo].[BudgetProjectView] TO [public]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--	 Добавление записи в таблицу T_BUDGETPROJECT
--
-- Входящие параметры:
-- 	@BUDGETPROJECT_NAME										- наименование
--  @BUDGETPROJECT_ACTIVE									- признак "запись активна"				
-- 	@BUDGETPROJECT_DESCRIPTION						- примечание
--		@BUDGETPROJECT_1C_CODE								- УИ в справочнике 1С
--
-- Выходные параметры:
--		@BUDGETPROJECT_GUID										- уникальный идентификатор записи
--
-- Результат:
--    0 - успешное завершение
--    <>0 - ошибка

CREATE PROCEDURE [dbo].[usp_AddBudgetProject] 
	@BUDGETPROJECT_NAME					[dbo].[D_NAME],
	@BUDGETPROJECT_ACTIVE				[dbo].[D_YESNO] = 1,
	@BUDGETPROJECT_DESCRIPTION	[dbo].[D_DESCRIPTION] = NULL,
	@BUDGETPROJECT_1C_CODE			[dbo].[D_ID] = 0,

  @BUDGETPROJECT_GUID					[dbo].[D_GUID] output,
  @ERROR_NUM									int output,
  @ERROR_MES									nvarchar( 4000 ) output

AS

BEGIN

	BEGIN TRY

    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';
		SET @BUDGETPROJECT_GUID = NULL;

    SET @BUDGETPROJECT_NAME = dbo.TrimSpace( @BUDGETPROJECT_NAME );

   IF EXISTS ( SELECT [BUDGETPROJECT_GUID] FROM [dbo].[T_BUDGETPROJECT] WHERE [BUDGETPROJECT_NAME] = @BUDGETPROJECT_NAME )
     BEGIN
       SET @ERROR_NUM = 1;
       SET @ERROR_MES = 'В базе данных зарегистрирован проект с указанным наименованием: ' + @BUDGETPROJECT_NAME;
       
			 RETURN @ERROR_NUM;
     END

    IF( @BUDGETPROJECT_1C_CODE = 0 )
			EXEC @BUDGETPROJECT_1C_CODE = SP_GetGeneratorID @strTableName = 'T_BUDGETPROJECT';

    DECLARE @NewID D_GUID;
    SET @NewID = NEWID ();	
    
		INSERT INTO [dbo].[T_BUDGETPROJECT]( BUDGETPROJECT_GUID, BUDGETPROJECT_NAME, BUDGETPROJECT_DESCRIPTION, BUDGETPROJECT_ACTIVE, BUDGETPROJECT_1C_CODE, 
			Record_Updated, Record_UserUpdated )
		VALUES( @NewID, @BUDGETPROJECT_NAME, @BUDGETPROJECT_DESCRIPTION, @BUDGETPROJECT_ACTIVE, @BUDGETPROJECT_1C_CODE,
			sysutcdatetime(), ( Host_Name() + ': ' + SUSER_SNAME() ));

		SET @BUDGETPROJECT_GUID = @NewID;

	END TRY
	BEGIN CATCH
    SET @ERROR_NUM = ERROR_NUMBER();
    SET @ERROR_MES = ERROR_MESSAGE();

		RETURN @ERROR_NUM;
	END CATCH;

	IF( @ERROR_NUM = 0 )
		SET @ERROR_MES = 'Успешное завершение операции. В БД добавлена информация о новом проекте. УИ: ' + CONVERT( nvarchar(36), @BUDGETPROJECT_GUID );

	RETURN @ERROR_NUM;
END


GO

GRANT EXECUTE ON [dbo].[usp_AddBudgetProject] TO [public]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--	 Редактирование записи в таблице T_BUDGETPROJECT
--
-- Входящие параметры:
--		@BUDGETPROJECT_GUID										- уникальный идентификатор записи
-- 	@BUDGETPROJECT_NAME										- наименование
--  @BUDGETPROJECT_ACTIVE									- признак "запись активна"				
-- 	@BUDGETPROJECT_DESCRIPTION						- примечание
--		@BUDGETPROJECT_1C_CODE								- УИ в справочнике 1С
--
-- Выходные параметры:
--
-- Результат:
--    0 - успешное завершение
--    <>0 - ошибка

CREATE PROCEDURE [dbo].[usp_EditBudgetProject] 
  @BUDGETPROJECT_GUID					[dbo].[D_GUID],
	@BUDGETPROJECT_NAME					[dbo].[D_NAME],
	@BUDGETPROJECT_ACTIVE				[dbo].[D_YESNO] = 1,
	@BUDGETPROJECT_DESCRIPTION	[dbo].[D_DESCRIPTION] = NULL,
	--@BUDGETPROJECT_1C_CODE			[dbo].[D_ID] = 0,

  @ERROR_NUM									int output,
  @ERROR_MES									nvarchar( 4000 ) output

AS

BEGIN

	BEGIN TRY

    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';

    SET @BUDGETPROJECT_NAME = dbo.TrimSpace( @BUDGETPROJECT_NAME );

   IF NOT EXISTS ( SELECT [BUDGETPROJECT_GUID] FROM [dbo].[T_BUDGETPROJECT] WHERE [BUDGETPROJECT_GUID] = @BUDGETPROJECT_GUID )
     BEGIN
       SET @ERROR_NUM = 1;
       SET @ERROR_MES = 'В базе данных не найден проект с указанным идентификатором: ' + CONVERT( nvarchar(36), @BUDGETPROJECT_GUID );
       
			 RETURN @ERROR_NUM;
     END

   IF EXISTS ( SELECT [BUDGETPROJECT_GUID] FROM [dbo].[T_BUDGETPROJECT] WHERE [BUDGETPROJECT_NAME] = @BUDGETPROJECT_NAME AND [BUDGETPROJECT_GUID] <> @BUDGETPROJECT_GUID )
     BEGIN
       SET @ERROR_NUM = 2;
       SET @ERROR_MES = 'В базе данных зарегистрирован проект с указанным наименованием: ' + @BUDGETPROJECT_NAME;
       
			 RETURN @ERROR_NUM;
     END

		UPDATE [dbo].[T_BUDGETPROJECT] SET [BUDGETPROJECT_NAME] = @BUDGETPROJECT_NAME, [BUDGETPROJECT_DESCRIPTION] = @BUDGETPROJECT_DESCRIPTION, 
			[BUDGETPROJECT_ACTIVE] = @BUDGETPROJECT_ACTIVE, [Record_Updated] = sysutcdatetime(), [Record_UserUpdated] = ( Host_Name() + ': ' + SUSER_SNAME() )
		WHERE [BUDGETPROJECT_GUID] = @BUDGETPROJECT_GUID;
    
	END TRY
	BEGIN CATCH
    SET @ERROR_NUM = ERROR_NUMBER();
    SET @ERROR_MES = ERROR_MESSAGE();

		RETURN @ERROR_NUM;
	END CATCH;

	IF( @ERROR_NUM = 0 )
		SET @ERROR_MES = 'Успешное завершение операции. В БД внесены изменения в информацию о проекте. УИ: ' + CONVERT( nvarchar(36), @BUDGETPROJECT_GUID );

	RETURN @ERROR_NUM;
END


GO

GRANT EXECUTE ON [dbo].[usp_EditBudgetProject] TO [public]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--	 Удаление записи в таблице T_BUDGETPROJECT
--
-- Входящие параметры:
--		@BUDGETPROJECT_GUID					- уникальный идентификатор записи
--
-- Выходные параметры:
--
-- Результат:
--    0 - успешное завершение
--    <>0 - ошибка

CREATE PROCEDURE [dbo].[usp_DeleteBudgetProject] 
  @BUDGETPROJECT_GUID					[dbo].[D_GUID],
	
  @ERROR_NUM				int output,
  @ERROR_MES				nvarchar( 4000 ) output

AS

BEGIN

	BEGIN TRY

    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';

    IF NOT EXISTS ( SELECT BUDGETPROJECT_GUID FROM [dbo].[T_BUDGETPROJECT] 
									  WHERE	[BUDGETPROJECT_GUID] = @BUDGETPROJECT_GUID )
     BEGIN
       SET @ERROR_NUM = 1;
       SET @ERROR_MES = 'В базе данных не найден проект с указанным идентификатором: ' +  CONVERT( nvarchar(36), @BUDGETPROJECT_GUID );
       
			 RETURN @ERROR_NUM;
     END

   DELETE FROM [dbo].[T_BUDGETPROJECT] WHERE [BUDGETPROJECT_GUID] = @BUDGETPROJECT_GUID;
	 

	END TRY
	BEGIN CATCH
    SET @ERROR_NUM = ERROR_NUMBER();
    SET @ERROR_MES = ERROR_MESSAGE();

		RETURN @ERROR_NUM;
	END CATCH;

	IF( @ERROR_NUM = 0 )
		SET @ERROR_MES = 'Успешное завершение операции. В БД удалена запись с описанием типа бюджетного документа. УИ: ' + CONVERT( nvarchar(36), @BUDGETPROJECT_GUID );

	RETURN @ERROR_NUM;
END

GO

GRANT EXECUTE ON [dbo].[usp_DeleteBudgetProject] TO [public]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--	 Возвращает записи в таблице T_BUDGETPROJECT
--
-- Входящие параметры:
--
-- Выходные параметры:
--		@BUDGETPROJECT_GUID		- уи записи
--
-- Результат:
--    0 - успешное завершение
--    <>0 - ошибка

CREATE PROCEDURE [dbo].[usp_GetBudgetProject] 
	@BUDGETPROJECT_GUID												D_GUID = NULL,

  @ERROR_NUM											int output,
  @ERROR_MES											nvarchar( 4000 ) output

AS

BEGIN

	BEGIN TRY

    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';

		IF( @BUDGETPROJECT_GUID IS NULL )
			SELECT BUDGETPROJECT_GUID, BUDGETPROJECT_NAME, BUDGETPROJECT_DESCRIPTION, BUDGETPROJECT_ACTIVE, BUDGETPROJECT_1C_CODE, Record_Updated, Record_UserUpdated
			FROM [dbo].[BudgetProjectView]
			ORDER BY  BUDGETPROJECT_NAME;		 
		ELSE
			SELECT BUDGETPROJECT_GUID, BUDGETPROJECT_NAME, BUDGETPROJECT_DESCRIPTION, BUDGETPROJECT_ACTIVE, BUDGETPROJECT_1C_CODE, Record_Updated, Record_UserUpdated
			FROM [dbo].[BudgetProjectView]
			WHERE BUDGETPROJECT_GUID = @BUDGETPROJECT_GUID;

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

GRANT EXECUTE ON [dbo].[usp_GetBudgetProject] TO [public]
GO

