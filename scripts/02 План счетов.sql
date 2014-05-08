USE [ERP_Mercury]
GO

INSERT INTO [dbo].[TS_GENERATOR]( GENERATOR_ID, TABLE_NAME )
VALUES( 0, 'T_ACCOUNTPLAN' )
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[T_AccountPlan](
	[ACCOUNTPLAN_GUID] [dbo].[D_GUID] NOT NULL,
	[ACCOUNTPLAN_1C_CODE] [dbo].[D_NAME] NOT NULL,
	[ACCOUNTPLAN_NAME] [dbo].[D_NAME] NOT NULL,
	[ACCOUNTPLAN_ACTIVE] [dbo].[D_YESNO] NOT NULL,
	[Record_Updated] [dbo].[D_DATETIME] NULL,
	[Record_UserUpdated] [dbo].[D_NAME] NULL,
 CONSTRAINT [PK_T_ACCOUNTPLAN] PRIMARY KEY CLUSTERED 
(
	[ACCOUNTPLAN_GUID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


CREATE NONCLUSTERED INDEX [INDX_T_ACCOUNTPLAN_1C_Code] ON [dbo].[T_ACCOUNTPLAN]
(
	[ACCOUNTPLAN_1C_CODE] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [INDEX]
GO

CREATE NONCLUSTERED INDEX [INDX_T_ACCOUNTPLAN_Active] ON [dbo].[T_ACCOUNTPLAN]
(
	[ACCOUNTPLAN_ACTIVE] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [INDEX]
GO

CREATE UNIQUE NONCLUSTERED INDEX [INDX_T_ACCOUNTPLAN_Name] ON [dbo].[T_ACCOUNTPLAN]
(
	[ACCOUNTPLAN_NAME] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [INDEX]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[AccountPlanView]
AS
SELECT ACCOUNTPLAN_GUID, ACCOUNTPLAN_1C_CODE, ACCOUNTPLAN_NAME, ACCOUNTPLAN_ACTIVE, Record_Updated, Record_UserUpdated
FROM [dbo].[T_ACCOUNTPLAN]

GO

GRANT SELECT ON [dbo].[AccountPlanView] TO [public]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--	 ���������� ������ � ������� T_ACCOUNTPLAN
--
-- �������� ���������:
-- 	@ACCOUNTPLAN_NAME										- ������������
--  @ACCOUNTPLAN_ACTIVE									- ������� "������ �������"				
--		@ACCOUNTPLAN_1C_CODE								- �� � ����������� 1�
--
-- �������� ���������:
--		@ACCOUNTPLAN_GUID										- ���������� ������������� ������
--
-- ���������:
--    0 - �������� ����������
--    <>0 - ������

CREATE PROCEDURE [dbo].[usp_AddAccountPlan] 
	@ACCOUNTPLAN_NAME					[dbo].[D_NAME],
	@ACCOUNTPLAN_ACTIVE				[dbo].[D_YESNO] = 1,
	@ACCOUNTPLAN_1C_CODE			[dbo].[D_NAME],

  @ACCOUNTPLAN_GUID					[dbo].[D_GUID] output,
  @ERROR_NUM									int output,
  @ERROR_MES									nvarchar( 4000 ) output

AS

BEGIN

	BEGIN TRY

    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';
		SET @ACCOUNTPLAN_GUID = NULL;

    SET @ACCOUNTPLAN_NAME = dbo.TrimSpace( @ACCOUNTPLAN_NAME );

   IF EXISTS ( SELECT [ACCOUNTPLAN_GUID] FROM [dbo].[T_ACCOUNTPLAN] WHERE [ACCOUNTPLAN_NAME] = @ACCOUNTPLAN_NAME )
     BEGIN
       SET @ERROR_NUM = 1;
       SET @ERROR_MES = '� ���� ������ ��������������� ����: ' + @ACCOUNTPLAN_NAME;
       
			 RETURN @ERROR_NUM;
     END

   IF EXISTS ( SELECT [ACCOUNTPLAN_GUID] FROM [dbo].[T_ACCOUNTPLAN] WHERE [ACCOUNTPLAN_1C_CODE] = @ACCOUNTPLAN_1C_CODE )
     BEGIN
       SET @ERROR_NUM = 1;
       SET @ERROR_MES = '� ���� ������ ��������������� ����: ' + @ACCOUNTPLAN_1C_CODE;
       
			 RETURN @ERROR_NUM;
     END

    DECLARE @NewID D_GUID;
    SET @NewID = NEWID ();	
    
		INSERT INTO [dbo].[T_ACCOUNTPLAN]( ACCOUNTPLAN_GUID, ACCOUNTPLAN_1C_CODE, ACCOUNTPLAN_NAME, ACCOUNTPLAN_ACTIVE,
			Record_Updated, Record_UserUpdated )
		VALUES( @NewID, @ACCOUNTPLAN_1C_CODE, @ACCOUNTPLAN_NAME, @ACCOUNTPLAN_ACTIVE,
			sysutcdatetime(), ( Host_Name() + ': ' + SUSER_SNAME() ));

		SET @ACCOUNTPLAN_GUID = @NewID;

	END TRY
	BEGIN CATCH
    SET @ERROR_NUM = ERROR_NUMBER();
    SET @ERROR_MES = ERROR_MESSAGE();

		RETURN @ERROR_NUM;
	END CATCH;

	IF( @ERROR_NUM = 0 )
		SET @ERROR_MES = '�������� ���������� ��������. � �� ��������� ���������� � ����� �����. ��: ' + CONVERT( nvarchar(36), @ACCOUNTPLAN_GUID );

	RETURN @ERROR_NUM;
END


GO

GRANT EXECUTE ON [dbo].[usp_AddAccountPlan] TO [public]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--	 �������������� ������ � ������� T_ACCOUNTPLAN
--
-- �������� ���������:
--		@ACCOUNTPLAN_GUID										- ���������� ������������� ������
-- 	@ACCOUNTPLAN_NAME										- ������������
--  @ACCOUNTPLAN_ACTIVE									- ������� "������ �������"				
--		@ACCOUNTPLAN_1C_CODE								- �� � ����������� 1�
--
-- �������� ���������:
--
-- ���������:
--    0 - �������� ����������
--    <>0 - ������

CREATE PROCEDURE [dbo].[usp_EditAccountPlan] 
  @ACCOUNTPLAN_GUID					[dbo].[D_GUID],
	@ACCOUNTPLAN_NAME					[dbo].[D_NAME],
	@ACCOUNTPLAN_ACTIVE				[dbo].[D_YESNO] = 1,
	@ACCOUNTPLAN_1C_CODE			[dbo].[D_NAME],

  @ERROR_NUM									int output,
  @ERROR_MES									nvarchar( 4000 ) output

AS

BEGIN

	BEGIN TRY

    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';

    SET @ACCOUNTPLAN_NAME = dbo.TrimSpace( @ACCOUNTPLAN_NAME );

   IF NOT EXISTS ( SELECT [ACCOUNTPLAN_GUID] FROM [dbo].[T_ACCOUNTPLAN] WHERE [ACCOUNTPLAN_GUID] = @ACCOUNTPLAN_GUID )
     BEGIN
       SET @ERROR_NUM = 1;
       SET @ERROR_MES = '� ���� ������ �� ������ ���� � ��������� ���������������: ' + CONVERT( nvarchar(36), @ACCOUNTPLAN_GUID );
       
			 RETURN @ERROR_NUM;
     END

   IF EXISTS ( SELECT [ACCOUNTPLAN_GUID] FROM [dbo].[T_ACCOUNTPLAN] WHERE [ACCOUNTPLAN_NAME] = @ACCOUNTPLAN_NAME AND [ACCOUNTPLAN_GUID] <> @ACCOUNTPLAN_GUID )
     BEGIN
       SET @ERROR_NUM = 2;
       SET @ERROR_MES = '� ���� ������ ��������������� ���� � ��������� �������������: ' + @ACCOUNTPLAN_NAME;
       
			 RETURN @ERROR_NUM;
     END

   IF EXISTS ( SELECT [ACCOUNTPLAN_GUID] FROM [dbo].[T_ACCOUNTPLAN] WHERE [ACCOUNTPLAN_1C_CODE] = @ACCOUNTPLAN_1C_CODE AND [ACCOUNTPLAN_GUID] <> @ACCOUNTPLAN_GUID )
     BEGIN
       SET @ERROR_NUM = 2;
       SET @ERROR_MES = '� ���� ������ ��������������� ���� � ��������� �����: ' + @ACCOUNTPLAN_1C_CODE;
       
			 RETURN @ERROR_NUM;
     END

		UPDATE [dbo].[T_ACCOUNTPLAN] SET [ACCOUNTPLAN_NAME] = @ACCOUNTPLAN_NAME, [ACCOUNTPLAN_1C_CODE] = @ACCOUNTPLAN_1C_CODE,
			[ACCOUNTPLAN_ACTIVE] = @ACCOUNTPLAN_ACTIVE, [Record_Updated] = sysutcdatetime(), [Record_UserUpdated] = ( Host_Name() + ': ' + SUSER_SNAME() )
		WHERE [ACCOUNTPLAN_GUID] = @ACCOUNTPLAN_GUID;
    
	END TRY
	BEGIN CATCH
    SET @ERROR_NUM = ERROR_NUMBER();
    SET @ERROR_MES = ERROR_MESSAGE();

		RETURN @ERROR_NUM;
	END CATCH;

	IF( @ERROR_NUM = 0 )
		SET @ERROR_MES = '�������� ���������� ��������. � �� ������� ��������� � ���������� � �����. ��: ' + CONVERT( nvarchar(36), @ACCOUNTPLAN_GUID );

	RETURN @ERROR_NUM;
END


GO

GRANT EXECUTE ON [dbo].[usp_EditAccountPlan] TO [public]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--	 �������� ������ � ������� T_ACCOUNTPLAN
--
-- �������� ���������:
--		@ACCOUNTPLAN_GUID					- ���������� ������������� ������
--
-- �������� ���������:
--
-- ���������:
--    0 - �������� ����������
--    <>0 - ������

CREATE PROCEDURE [dbo].[usp_DeleteAccountPlan] 
  @ACCOUNTPLAN_GUID					[dbo].[D_GUID],
	
  @ERROR_NUM				int output,
  @ERROR_MES				nvarchar( 4000 ) output

AS

BEGIN

	BEGIN TRY

    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';

    IF NOT EXISTS ( SELECT ACCOUNTPLAN_GUID FROM [dbo].[T_ACCOUNTPLAN] 
									  WHERE	[ACCOUNTPLAN_GUID] = @ACCOUNTPLAN_GUID )
     BEGIN
       SET @ERROR_NUM = 1;
       SET @ERROR_MES = '� ���� ������ �� ������ ���� � ��������� ���������������: ' +  CONVERT( nvarchar(36), @ACCOUNTPLAN_GUID );
       
			 RETURN @ERROR_NUM;
     END

   DELETE FROM [dbo].[T_ACCOUNTPLAN] WHERE [ACCOUNTPLAN_GUID] = @ACCOUNTPLAN_GUID;
	 

	END TRY
	BEGIN CATCH
    SET @ERROR_NUM = ERROR_NUMBER();
    SET @ERROR_MES = ERROR_MESSAGE();

		RETURN @ERROR_NUM;
	END CATCH;

	IF( @ERROR_NUM = 0 )
		SET @ERROR_MES = '�������� ���������� ��������. � �� ������� ������ � ��������� �����. ��: ' + CONVERT( nvarchar(36), @ACCOUNTPLAN_GUID );

	RETURN @ERROR_NUM;
END

GO

GRANT EXECUTE ON [dbo].[usp_DeleteAccountPlan] TO [public]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--	 ���������� ������ � ������� T_ACCOUNTPLAN
--
-- �������� ���������:
--
-- �������� ���������:
--		@ACCOUNTPLAN_GUID		- �� ������
--
-- ���������:
--    0 - �������� ����������
--    <>0 - ������

CREATE PROCEDURE [dbo].[usp_GetAccountPlan] 
	@ACCOUNTPLAN_GUID												D_GUID = NULL,

  @ERROR_NUM											int output,
  @ERROR_MES											nvarchar( 4000 ) output

AS

BEGIN

	BEGIN TRY

    SET @ERROR_NUM = 0;
    SET @ERROR_MES = '';

		IF( @ACCOUNTPLAN_GUID IS NULL )
			SELECT ACCOUNTPLAN_GUID, ACCOUNTPLAN_1C_CODE, ACCOUNTPLAN_NAME, ACCOUNTPLAN_ACTIVE, Record_Updated, Record_UserUpdated
			FROM [dbo].[AccountPlanView]
			ORDER BY  ACCOUNTPLAN_1C_CODE;		 
		ELSE
			SELECT ACCOUNTPLAN_GUID, ACCOUNTPLAN_1C_CODE, ACCOUNTPLAN_NAME, ACCOUNTPLAN_ACTIVE, Record_Updated, Record_UserUpdated
			FROM [dbo].[AccountPlanView]
			WHERE ACCOUNTPLAN_GUID = @ACCOUNTPLAN_GUID;

	END TRY
	BEGIN CATCH
    SET @ERROR_NUM = ERROR_NUMBER();
    SET @ERROR_MES = ERROR_MESSAGE();

		RETURN @ERROR_NUM;
	END CATCH;

	IF( @ERROR_NUM = 0 )
		SET @ERROR_MES = '�������� ���������� ��������.';

	RETURN @ERROR_NUM;
END

GO

GRANT EXECUTE ON [dbo].[usp_GetAccountPlan] TO [public]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[T_ACCOUNTPLAN_Archive](
	[ACCOUNTPLAN_GUID] [dbo].[D_GUID] NOT NULL,
	[ACCOUNTPLAN_1C_CODE] [dbo].[D_NAME] NOT NULL,
	[ACCOUNTPLAN_NAME] [dbo].[D_NAME] NOT NULL,
	[ACCOUNTPLAN_ACTIVE] [dbo].[D_YESNO] NOT NULL,
	[Record_Updated] [dbo].[D_DATETIME] NULL,
	[Record_UserUpdated] [dbo].[D_NAME] NULL,
	[Action_TypeId] [dbo].[D_ID] NOT NULL
) ON [PRIMARY]

GO


CREATE NONCLUSTERED INDEX [INDX_T_ACCOUNTPLAN_Archive_AccountPlan_Guid] ON [dbo].[T_ACCOUNTPLAN_Archive]
(
	[ACCOUNTPLAN_GUID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [INDEX]

GO

CREATE NONCLUSTERED INDEX [INDX_T_ACCOUNTPLAN_Archive_Action_TypeId] ON [dbo].[T_ACCOUNTPLAN_Archive]
(
	[Action_TypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [INDEX]

GO


CREATE NONCLUSTERED INDEX [INDX_T_ACCOUNTPLAN_Archive_Record_Updated] ON [dbo].[T_ACCOUNTPLAN_Archive]
(
	[Record_Updated] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [INDEX]

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- ������� ����������� ��� ����������/�������������� �������
-- =============================================
CREATE TRIGGER [dbo].[TG_ACCOUNTPLAN_AfterUpdate]
   ON  [dbo].[T_ACCOUNTPLAN] 
   AFTER INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;
	
	INSERT INTO dbo.T_ACCOUNTPLAN_Archive ( ACCOUNTPLAN_GUID, ACCOUNTPLAN_1C_CODE, ACCOUNTPLAN_NAME, ACCOUNTPLAN_ACTIVE, 
		Record_Updated, Record_UserUpdated, Action_TypeId )
	SELECT ACCOUNTPLAN_GUID, ACCOUNTPLAN_1C_CODE, ACCOUNTPLAN_NAME, ACCOUNTPLAN_ACTIVE, 
		sysutcdatetime(), ( Host_Name() + ': ' + SUSER_SNAME() ), 0
	FROM inserted;

	UPDATE dbo.[T_ACCOUNTPLAN] SET Record_Updated = sysutcdatetime(), [Record_UserUpdated] = ( Host_Name() + ': ' + SUSER_SNAME() )
	WHERE ACCOUNTPLAN_GUID IN ( SELECT ACCOUNTPLAN_GUID FROM inserted );
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- ������� ����������� � ������ �������� ������� �� �������
-- =============================================
CREATE TRIGGER [dbo].[TG_ACCOUNTPLAN_AfterDelete]
   ON [dbo].[T_ACCOUNTPLAN] 
   AFTER DELETE
AS 
BEGIN
	SET NOCOUNT ON;

	INSERT INTO dbo.T_ACCOUNTPLAN_Archive ( ACCOUNTPLAN_GUID, ACCOUNTPLAN_1C_CODE, ACCOUNTPLAN_NAME, ACCOUNTPLAN_ACTIVE, 
		Record_Updated, Record_UserUpdated, Action_TypeId )
	SELECT ACCOUNTPLAN_GUID, ACCOUNTPLAN_1C_CODE, ACCOUNTPLAN_NAME, ACCOUNTPLAN_ACTIVE, 
		sysutcdatetime(), ( Host_Name() + ': ' + SUSER_SNAME() ), 2
	FROM deleted;
	
END

GO


 ALTER TABLE [dbo].[T_Earning] ADD BudgetProjectSRC_Guid D_GUID_NULL
 ALTER TABLE [dbo].[T_Earning] ADD BudgetProjectDST_Guid D_GUID_NULL
 ALTER TABLE [dbo].[T_Earning] ADD CompanyPayer_Guid D_GUID_NULL
 ALTER TABLE [dbo].[T_Earning] ADD CustomerChild_Guid D_GUID_NULL
 ALTER TABLE [dbo].[T_Earning] ADD AccountPlan_Guid D_GUID_NULL
 ALTER TABLE [dbo].[T_Earning] ADD PaymentType_Guid D_GUID_NULL
 GO

 ALTER TABLE [dbo].[T_Earning] ADD Earning_IsBonus D_YESNO NULL 
 GO

 ALTER TABLE [dbo].[T_Earning] ADD  CONSTRAINT [DF_T_Earning_Earning_IsBonus]  DEFAULT ((0)) FOR [Earning_IsBonus]
 GO