USE [ERP_Mercury]
GO

/****** Object:  StoredProcedure [dbo].[usp_DeleteEarning2FromIB]    Script Date: 17.01.2014 15:51:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ������� � InterBase ���������� � �������

-- ������� ���������
-- @Earning_Guid					- �� �������
-- @IBLINKEDSERVERNAME		- ��� LINKEDSERVER

-- �������� ���������
-- @ERROR_NUM						- ����� ������
-- @ERROR_MES						- ��������� �� ������

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
	  SET @EventSrc = '�������� ������� � IB';

 	  IF( @IBLINKEDSERVERNAME IS NULL ) SELECT @IBLINKEDSERVERNAME = dbo.GetIBLinkedServerName();

    DECLARE @strIBSQLText nvarchar( 250 );
    DECLARE	@Earning_Id int; 

		-- ���������, ���� �� �������� � ��������� ��������������� 
    IF NOT EXISTS ( SELECT * FROM dbo.T_Earning WHERE Earning_Guid = @Earning_Guid )
      BEGIN
        SET @ERROR_NUM = 1;
        SET @ERROR_MES = '[usp_DeleteEarning2FromIB] �� ������ ����� � ��������� ���������������: ' +  CONVERT( nvarchar(36), @Earning_Guid );
        RETURN @ERROR_NUM;
      END
      
		SELECT @Earning_Id = Earning_Id
		FROM dbo.T_Earning WHERE Earning_Guid = @Earning_Guid;
		
		IF( @Earning_Id = 0 )
			BEGIN
				SET @ERROR_NUM = 0;
				SET @ERROR_MES = '������ �� ���������������� � "���������"';

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

-- �������� �������� �� ������� dbo.T_Earning
--
-- �������� ���������:
--
--		@Earning_Guid - ���������� ������������� ������
--
-- �������� ���������:
--
--		@ERROR_NUM		- ����� ������
--		@ERROR_MES		- ��������� �� ������

-- ���������:
--    0 - �������� ����������
--    <>0 - ������

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
			SET @ERROR_MES = '� ���� ������ �� ������ ����� � ��������� ���������������: ' + CAST( @Earning_Guid as nvarchar(36) );

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
		SET @ERROR_MES = '����� ������� �����. �� �������: ' + CAST( @Earning_Guid as nvarchar(36) );
	
	RETURN @ERROR_NUM;
END

GO

/****** Object:  StoredProcedure [dbo].[usp_AddEarningToSQLandIB]    Script Date: 17.01.2014 10:57:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ��������� ����� ������ � ������� dbo.T_Earning
--
-- �������� ���������:
--
--		@Earning_CustomerGuid				- �� �������
--		@Earning_CurrencyGuid				- �� ������
--		@Earning_Date								- ���� �������
--		@Earning_DocNum							- � ���������
--		@Earning_BankCode						- ��� �����
--		@Earning_Account						- � �/�
--		@Earning_Value							- ����� �������
--		@Earning_CompanyGuid				- �� ��������-���������� �������
--		@Earning_CurrencyRate				- ���� !?
--		@Earning_CurrencyValue			- !?
--		@Earning_CustomerText				-	
--		@Earning_DetailsPaymentText	- 
--		@Earning_iKey								- 
--		@BudgetProjectSRC_Guid			- �� �������-���������
--		@BudgetProjectDST_Guid			- �� �������-����������
--		@CompanyPayer_Guid					- �� ��������-�����������
--		@ChildDepart_Guid						- �� ��������� �������
--		@AccountPlan_Guid						- �� ������ � ����� ������
--		@PaymentType_Guid						- �� ����� ������
--		@Earning_IsBonus						- ������� "�������� �����"
--		@EarningType_Guid						- �� ���� ������
--
-- �������� ���������:
--
--  @Earning_Guid								- �� ������
--  @ERROR_NUM										- ����� ������
--  @ERROR_MES										- ����� ������
--
-- ���������:
--    0 - �������� ����������
--    <>0 - ������

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

    SET @EventSrc = '���������� �������';
    
		-- ���������� �� �����    
    DECLARE @Account_Guid D_GUID = NULL;
    SELECT TOP 1 @Account_Guid = Account_Guid, @Bank_Guid = Bank_Guid FROM T_Account 
		WHERE Account_Guid = @Earning_AccountGuid;
    
		IF NOT EXISTS ( SELECT [Account_Guid] FROM [dbo].[T_Account]	WHERE [Account_Guid] = @Earning_AccountGuid )
			BEGIN
				SET @ERROR_NUM = 3;
				SET @ERROR_MES = '� ���� ������ �� ������ ���� � ��������� ���������������: ' + CAST( @Earning_AccountGuid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	
		ELSE 
			SELECT TOP 1 @Account_Guid = Account_Guid, @Bank_Guid = Bank_Guid FROM T_Account 
			WHERE Account_Guid = @Earning_AccountGuid;			

    -- ������-��������
		IF( @BudgetProjectSRC_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [BUDGETPROJECT_GUID] FROM [dbo].[T_BudgetProject] 
				WHERE [BUDGETPROJECT_GUID] = @BudgetProjectSRC_Guid )
			BEGIN
				SET @ERROR_NUM = 4;
				SET @ERROR_MES = '� ���� ������ �� ������ ������-�������� � ��������� ���������������: ' + CAST( @BudgetProjectSRC_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- ������-����������
		IF( @BudgetProjectDST_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [BUDGETPROJECT_GUID] FROM [dbo].[T_BudgetProject] 
				WHERE [BUDGETPROJECT_GUID] = @BudgetProjectDST_Guid )
			BEGIN
				SET @ERROR_NUM = 5;
				SET @ERROR_MES = '� ���� ������ �� ������ ������-���������� � ��������� ���������������: ' + CAST( @BudgetProjectDST_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- ��������-����������
		IF( @CompanyPayer_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [Company_Guid] FROM [dbo].[T_Company]
				WHERE [Company_Guid] = @CompanyPayer_Guid )
			BEGIN
				SET @ERROR_NUM = 6;
				SET @ERROR_MES = '� ���� ������ �� ������� ��������-���������� � ��������� ���������������: ' + CAST( @CompanyPayer_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- �������� ������
		DECLARE	@CustomerChild_Guid	D_GUID_NULL = NULL;
		IF( @ChildDepart_Guid IS NOT NULL )
			BEGIN
				SELECT @CustomerChild_Guid = [CustomerChild_Guid] FROM [dbo].[T_CustomerChild]
				WHERE ( [ChildDepart_Guid] = @ChildDepart_Guid ) AND ( [Customer_Guid] = @Earning_CustomerGuid );

				IF( @CustomerChild_Guid IS NULL )
				BEGIN
					SET @ERROR_NUM = 7;
					SET @ERROR_MES = '� ���� ������ �� ������ �������� ������ � ��������� ���������������: ' + CAST( @CustomerChild_Guid as nvarchar(36) );

					RETURN @ERROR_NUM;
				END	
			END

    -- ���� ������
		IF( @AccountPlan_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [ACCOUNTPLAN_GUID] FROM [dbo].[T_AccountPlan]
				WHERE [ACCOUNTPLAN_GUID] = @AccountPlan_Guid )
			BEGIN
				SET @ERROR_NUM = 8;
				SET @ERROR_MES = '� ���� ������ �� ������� ������ � ����� ������ � ��������� ���������������: ' + CAST( @AccountPlan_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- ����� ������
		IF( @PaymentType_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [PaymentType_Guid]  FROM [dbo].[T_PaymentType]
				WHERE [PaymentType_Guid] = @PaymentType_Guid )
			BEGIN
				SET @ERROR_NUM = 9;
				SET @ERROR_MES = '� ���� ������ �� ������� ����� ������ � ��������� ���������������: ' + CAST( @PaymentType_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

     -- ������
     IF( @Earning_CustomerGuid IS NOT NULL)
       IF NOT EXISTS ( SELECT Customer_Guid FROM dbo.T_Customer WHERE Customer_Guid = @Earning_CustomerGuid )
        BEGIN
         SET @ERROR_NUM = 10;
         SET @ERROR_MES = '� ���� ������ �� ������ ������ � ��������� ���������������: ' + CAST( @Earning_CustomerGuid as nvarchar(36) );

         RETURN @ERROR_NUM;
        END    

     -- ������
		 IF NOT EXISTS ( SELECT Currency_Guid FROM dbo.T_Currency WHERE Currency_Guid = @Earning_CurrencyGuid )
      BEGIN
        SET @ERROR_NUM = 11;
        SET @ERROR_MES = '� ���� ������ �� ������� ������ � ��������� ���������������: ' + CAST( @Earning_CurrencyGuid as nvarchar(36) );

        RETURN @ERROR_NUM;
      END    

     IF NOT EXISTS ( SELECT Company_Guid FROM dbo.T_Company WHERE Company_Guid = @Earning_CompanyGuid )
      BEGIN
        SET @ERROR_NUM = 12;
        SET @ERROR_MES = '� ���� ������ �� ������� �������� � ��������� ���������������: ' + CAST( @Earning_CompanyGuid as nvarchar(36) );

        RETURN @ERROR_NUM;
      END       

    -- ��� ������
		IF( @EarningType_Guid IS NOT NULL )
			BEGIN
				IF NOT EXISTS ( SELECT [EarningType_Guid]  FROM [dbo].[T_EarningType]	WHERE [EarningType_Guid] = @EarningType_Guid )
					BEGIN
						SET @ERROR_NUM = 13;
						SET @ERROR_MES = '� ���� ������ �� ������ ��� ������ � ��������� ���������������: ' + CAST( @EarningType_Guid as nvarchar(36) );
						RETURN @ERROR_NUM;
					END
			END	
		ELSE
			SELECT TOP 1 @EarningType_Guid = [EarningType_Guid] FROM [dbo].[T_EarningType] WHERE [EarningType_IsDefault] = 1;

		-- �������� �� ���������� ���������� ���������� ��������
		IF( ( @CompanyPayer_Guid IS NOT NULL ) OR ( @BudgetProjectSRC_Guid IS NOT NULL ) )
			BEGIN
				-- ������ ������-�������� ���� ��������-����������
				IF( ( ( @CompanyPayer_Guid IS NOT NULL ) AND ( @BudgetProjectSRC_Guid IS NULL ) ) OR
						( ( @CompanyPayer_Guid IS NULL ) AND ( @BudgetProjectSRC_Guid IS NOT NULL ) ) )
					BEGIN
						SET @ERROR_NUM = 14;
						SET @ERROR_MES = '� ��� ������, ���� ������� ���� ��������-����������, ���� ������-��������, ���������� ������� ��� ���������.';
						RETURN @ERROR_NUM;
					END
				ELSE IF ( ( @CompanyPayer_Guid IS NOT NULL ) AND ( @BudgetProjectSRC_Guid IS NOT NULL ) )
					BEGIN
						-- ������� ��� ���������, ��� ������ ������ ���� "���������� ��������"
						IF( @EarningType_Guid IS NULL )
							BEGIN
								SET @ERROR_NUM = 14;
								SET @ERROR_MES = '�������, ����������, ��� ������ "���������� ��������".';
								RETURN @ERROR_NUM;
							END
						ELSE
							BEGIN
								IF NOT EXISTS( SELECT [EarningType_Guid] FROM [dbo].[T_EarningType] WHERE [EarningType_Guid] = @EarningType_Guid AND EarningType_Id = 1 )
									BEGIN
										SET @ERROR_NUM = 14;
										SET @ERROR_MES = '���������� ������� ��� ������ "���������� ��������"!';
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
								SET @ERROR_MES = '��� ���������� ������ ���������� ������� ��������-����������� � ������-��������.';
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

		-- � ��� ������, ���� ������ ������ � ��������� ����, ���������� ���������, �������� �� ���� ���� �������
		-- ���� ���� �� ��������, �� ��������� ���� � ������ ������ �������
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
				SET @strMessage = '� �� ��������� ���������� � ����� �������. �� ������: ' + CONVERT( nvarchar(36), @Earning_Guid );
				COMMIT TRANSACTION UpdateData
			END
		ELSE 
			BEGIN
				SET @strMessage = '������ ����������� �������. ' + @ERROR_MES;
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
		SET @ERROR_MES = '�������� ���������� ��������.';

	RETURN @ERROR_NUM;
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ��������� � InterBase ���������� � ����� ���������� �������

-- ������� ���������
-- 
-- @Earning_Guid - �� �������
-- @IBLINKEDSERVERNAME		- ��� LINKEDSERVER ��� ����������� � InterBase
--
-- �������� ���������
--
-- @Earning_Id						- �� ������� � InterBase
-- @ERROR_NUM						- ����� ������
-- @ERROR_MES						- ��������� �� ������

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
				SET @ERROR_MES = '� ���� ������ �� ������ ����� � ��������� ���������������: ' + CAST( @Earning_Guid as nvarchar(36) );

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
				SET @ERROR_MES = '������ �� �������������� � "���������"';

				RETURN @ERROR_NUM;
			END  

    DECLARE @EventID D_ID = NULL;
    DECLARE @ParentEventID D_ID = NULL;
    DECLARE @strMessage D_EVENTMSG = '';
    DECLARE @EventSrc D_NAME = '�������� ������ �� ���������� ������� � IB';

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
        SET @ERROR_MES = '�� ������� ��������, ��������� � �������. �� �������: ' + CAST( @Earning_Guid as nvarchar(36) );

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
		SET @ERROR_MES = '�������� ���������� ��������. ��� ������� � IB: ' + CAST( @NewEarningId as nvarchar( 56 ) );

	RETURN @ERROR_NUM;

END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ����������� � InterBase ���������� � �������

-- ������� ���������
-- 
-- @Earning_Guid - �� �������
-- @IBLINKEDSERVERNAME		- ��� LINKEDSERVER ��� ����������� � InterBase
--
-- �������� ���������
--
-- @ERROR_NUM						- ����� ������
-- @ERROR_MES						- ��������� �� ������

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
				SET @ERROR_MES = '� ���� ������ �� ������ ����� � ��������� ���������������: ' + CAST( @Earning_Guid as nvarchar(36) );

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
				SET @ERROR_MES = '������ �� �������������� � "���������"';

				RETURN @ERROR_NUM;
			END  

    DECLARE @EventID D_ID = NULL;
    DECLARE @ParentEventID D_ID = NULL;
    DECLARE @strMessage D_EVENTMSG = '';
    DECLARE @EventSrc D_NAME = '�������� ������ �� ���������� ������� � IB';

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
        SET @ERROR_MES = '�� ������� ��������, ��������� � �������. �� �������: ' + CAST( @Earning_Guid as nvarchar(36) );

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
		SET @ERROR_MES = '�������� ���������� ��������. ��� ������� � IB: ' + CAST( @Earning_Id as nvarchar( 56 ) );

	RETURN @ERROR_NUM;

END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ����������� ������ � ������� dbo.T_Earning
--
-- �������� ���������:
--
--  @Earning_Guid								- �� ������
--		@Earning_CustomerGuid				- �� �������
--		@Earning_CurrencyGuid				- �� ������
--		@Earning_Date								- ���� �������
--		@Earning_DocNum							- � ���������
--		@Earning_BankCode						- ��� �����
--		@Earning_Account						- � �/�
--		@Earning_Value							- ����� �������
--		@Earning_CompanyGuid				- �� ��������-���������� �������
--		@Earning_CurrencyRate				- ���� !?
--		@Earning_CurrencyValue			- !?
--		@Earning_CustomerText				-	
--		@Earning_DetailsPaymentText	- 
--		@Earning_iKey								- 
--		@BudgetProjectSRC_Guid			- �� �������-���������
--		@BudgetProjectDST_Guid			- �� �������-����������
--		@CompanyPayer_Guid					- �� ��������-�����������
--		@ChildDepart_Guid						- �� ��������� �������
--		@AccountPlan_Guid						- �� ������ � ����� ������
--		@PaymentType_Guid						- �� ����� ������
--		@Earning_IsBonus						- ������� "�������� �����"
--		@EarningType_Guid						- �� ���� ������
--
-- �������� ���������:
--
--  @ERROR_NUM										- ����� ������
--  @ERROR_MES										- ����� ������
--
-- ���������:
--    0 - �������� ����������
--    <>0 - ������

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
    SET @EventSrc = '�����';
    
    -- �������� �� ������� ������� � ��������� ���������������
		IF NOT EXISTS( SELECT [Earning_Guid] FROM [dbo].[T_Earning] WHERE [Earning_Guid] = @Earning_Guid )
			BEGIN
				SET @ERROR_NUM = 1;
				SET @ERROR_MES = '� �� ��� �� ������ ����� � ��������� ���������������: ' + CAST( @Earning_Guid AS nvarchar( 36 ) );

				RETURN @ERROR_NUM;
			END
		
		-- ���������� �� �����    
    DECLARE @Account_Guid D_GUID = NULL;
    SELECT TOP 1 @Account_Guid = Account_Guid, @Bank_Guid = Bank_Guid FROM T_Account 
		WHERE Account_Guid = @Earning_AccountGuid;
    
		IF NOT EXISTS ( SELECT [Account_Guid] FROM [dbo].[T_Account]	WHERE [Account_Guid] = @Earning_AccountGuid )
			BEGIN
				SET @ERROR_NUM = 3;
				SET @ERROR_MES = '� ���� ������ �� ������ ���� � ��������� ���������������: ' + CAST( @Earning_AccountGuid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	
		ELSE 
			SELECT TOP 1 @Account_Guid = Account_Guid, @Bank_Guid = Bank_Guid FROM T_Account 
			WHERE Account_Guid = @Earning_AccountGuid;			

    -- ������-��������
		IF( @BudgetProjectSRC_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [BUDGETPROJECT_GUID] FROM [dbo].[T_BudgetProject] 
				WHERE [BUDGETPROJECT_GUID] = @BudgetProjectSRC_Guid )
			BEGIN
				SET @ERROR_NUM = 4;
				SET @ERROR_MES = '� ���� ������ �� ������ ������-�������� � ��������� ���������������: ' + CAST( @BudgetProjectSRC_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- ������-����������
		IF( @BudgetProjectDST_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [BUDGETPROJECT_GUID] FROM [dbo].[T_BudgetProject] 
				WHERE [BUDGETPROJECT_GUID] = @BudgetProjectDST_Guid )
			BEGIN
				SET @ERROR_NUM = 5;
				SET @ERROR_MES = '� ���� ������ �� ������ ������-���������� � ��������� ���������������: ' + CAST( @BudgetProjectDST_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- ��������-����������
		IF( @CompanyPayer_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [Company_Guid] FROM [dbo].[T_Company]
				WHERE [Company_Guid] = @CompanyPayer_Guid )
			BEGIN
				SET @ERROR_NUM = 6;
				SET @ERROR_MES = '� ���� ������ �� ������� ��������-���������� � ��������� ���������������: ' + CAST( @CompanyPayer_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- �������� ������
		DECLARE	@CustomerChild_Guid	D_GUID_NULL = NULL;
		IF( @ChildDepart_Guid IS NOT NULL )
			BEGIN
				SELECT @CustomerChild_Guid = [CustomerChild_Guid] FROM [dbo].[T_CustomerChild]
				WHERE ( [ChildDepart_Guid] = @ChildDepart_Guid ) AND ( [Customer_Guid] = @Earning_CustomerGuid );

				IF( @CustomerChild_Guid IS NULL )
				BEGIN
					SET @ERROR_NUM = 7;
					SET @ERROR_MES = '� ���� ������ �� ������ �������� ������ � ��������� ���������������: ' + CAST( @CustomerChild_Guid as nvarchar(36) );

					RETURN @ERROR_NUM;
				END	
			END

    -- ���� ������
		IF( @AccountPlan_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [ACCOUNTPLAN_GUID] FROM [dbo].[T_AccountPlan]
				WHERE [ACCOUNTPLAN_GUID] = @AccountPlan_Guid )
			BEGIN
				SET @ERROR_NUM = 8;
				SET @ERROR_MES = '� ���� ������ �� ������� ������ � ����� ������ � ��������� ���������������: ' + CAST( @AccountPlan_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- ����� ������
		IF( @PaymentType_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [PaymentType_Guid]  FROM [dbo].[T_PaymentType]
				WHERE [PaymentType_Guid] = @PaymentType_Guid )
			BEGIN
				SET @ERROR_NUM = 9;
				SET @ERROR_MES = '� ���� ������ �� ������� ����� ������ � ��������� ���������������: ' + CAST( @PaymentType_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

     -- ������
     IF( @Earning_CustomerGuid IS NOT NULL)
       IF NOT EXISTS ( SELECT Customer_Guid FROM dbo.T_Customer WHERE Customer_Guid = @Earning_CustomerGuid )
        BEGIN
         SET @ERROR_NUM = 10;
         SET @ERROR_MES = '� ���� ������ �� ������ ������ � ��������� ���������������: ' + CAST( @Earning_CustomerGuid as nvarchar(36) );

         RETURN @ERROR_NUM;
        END    

     -- ������
		 IF NOT EXISTS ( SELECT Currency_Guid FROM dbo.T_Currency WHERE Currency_Guid = @Earning_CurrencyGuid )
      BEGIN
        SET @ERROR_NUM = 11;
        SET @ERROR_MES = '� ���� ������ �� ������� ������ � ��������� ���������������: ' + CAST( @Earning_CurrencyGuid as nvarchar(36) );

        RETURN @ERROR_NUM;
      END    
			
		 -- ��������
     IF NOT EXISTS ( SELECT Company_Guid FROM dbo.T_Company WHERE Company_Guid = @Earning_CompanyGuid )
      BEGIN
        SET @ERROR_NUM = 12;
        SET @ERROR_MES = '� ���� ������ �� ������� �������� � ��������� ���������������: ' + CAST( @Earning_CompanyGuid as nvarchar(36) );

        RETURN @ERROR_NUM;
      END       

    -- ��� ������
		IF( @EarningType_Guid IS NOT NULL )
			BEGIN
				IF NOT EXISTS ( SELECT [EarningType_Guid]  FROM [dbo].[T_EarningType]	WHERE [EarningType_Guid] = @EarningType_Guid )
					BEGIN
						SET @ERROR_NUM = 13;
						SET @ERROR_MES = '� ���� ������ �� ������ ��� ������ � ��������� ���������������: ' + CAST( @EarningType_Guid as nvarchar(36) );
						
						RETURN @ERROR_NUM;
					END
			END	
		ELSE
			BEGIN
				SET @ERROR_NUM = 13;
				SET @ERROR_MES = '����������, ������� ��� ������ (������ �� �����, ������� � �.�.)';
				
				RETURN @ERROR_NUM;
			END

		-- ���� ���������������
		DECLARE @CurrencyMainGuid D_GUID; 

		SELECT TOP 1 @CurrencyMainGuid = [Currency_Guid] FROM [dbo].[T_Currency]
		WHERE [Currency_IsMain] = 1;
		SELECT @Earning_CurrencyRate = [dbo].[GetCurrencyRatePricingInOut]( @CurrencyMainGuid, @Earning_CurrencyGuid, @Earning_Date );

		DECLARE @Earning_ValueByCurrencyRate money = 0;
		IF( @Earning_CurrencyRate <> 0 )
			SET @Earning_ValueByCurrencyRate = ( @Earning_Value/@Earning_CurrencyRate );

		-- �������� �� ��������� ���� ������
		--
		-- ���� "������ �� �����" --> "�������" ��� "������ ������", �� ���������� ���������, ���������� �� ������ � ������ ������
		-- ���� ����������, �� �������������� ��������� ������������ ������, � ���� �� ����������, �� � InterBase ������ ���������
		-- 
		-- ���� "�������" ��� "������ ������" --> "������ �� �����", �� ������ ���������� ���������������� � InterBase � ��� ������, ���� Earning_Id = 0
		-- ��� "��������" � "������� �������" �������� ������ �� ������ �� �������������, �� � ����� ������ ���������� ���������, ���������� �� ������ � ������ ������
		-- ���� ����� ������� ������� ������ ����, �� ���������� ������������ ������
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
				SET @ERROR_MES = '������� �� ������� ���������� ������� ��� ������. �������� ��������. ����������, ���������� � ������������.';
				
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
				SET @ERROR_MES = '������ ���������� �� ������. �������������, ����������, ������, � ��������� ��������.';
				
				RETURN @ERROR_NUM;
			END

		BEGIN TRANSACTION UpdateData;

		-- � ��� ������, ���� ������ ������ � ��������� ����, ���������� ���������, �������� �� ���� ���� �������
		-- ���� ���� �� ��������, �� ��������� ���� � ������ ������ �������
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
				-- � ����� � ������� ���� ������ ������ �������� ��������� "������ ���������� ����������� � InterBase"
				IF( ( @PrevEarningType_DublicateInIB = 0 ) AND ( @EarningType_DublicateInIB = 1 ) )
					BEGIN
						IF( @Earning_Id = 0 )
							BEGIN
								-- ������ �� ��������������� � InterBase, ��� ���������� ��������
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
								-- ��� ���������� ��� ������� ���������� ������� ������ �� InterBase (T_EARNING ) 
								EXEC dbo.usp_DeleteEarning2FromIB @Earning_Guid = @Earning_Guid, @IBLINKEDSERVERNAME = NULL, 
									@ERROR_NUM = @ERROR_NUM output, @ERROR_MES = @ERROR_MES output;
								IF( @ERROR_NUM = 0 )
									UPDATE [dbo].[T_Earning] SET Earning_Id = 0 WHERE Earning_Guid = @Earning_Guid;
							END

					END
			END
		ELSE
			BEGIN
				-- ��� ������ �� ��������
				EXEC dbo.usp_EditEarningInIB @Earning_Guid = @Earning_Guid, @IBLINKEDSERVERNAME = NULL, 
					@ERROR_NUM = @ERROR_NUM output, @ERROR_MES = @ERROR_MES output;
			END


		IF( @ERROR_NUM = 0 )
			BEGIN
				SET @strMessage = '� �� ������� ��������� � ���������� � �������. �� ������: ' + CONVERT( nvarchar(36), @Earning_Guid );
				COMMIT TRANSACTION UpdateData
			END
		ELSE 
			BEGIN
				SET @strMessage = '������ ��������� ���������� �������. ' + @ERROR_MES;
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
		SET @ERROR_MES = '�������� ���������� ��������.';

	RETURN @ERROR_NUM;
END

GO

/****** Object:  StoredProcedure [dbo].[usp_EditEarningInSQLandIB]    Script Date: 17.01.2014 16:43:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ����������� ������ � ������� dbo.T_Earning
--
-- �������� ���������:
--
--  @Earning_Guid								- �� ������
--		@Earning_CustomerGuid				- �� �������
--		@Earning_CurrencyGuid				- �� ������
--		@Earning_Date								- ���� �������
--		@Earning_DocNum							- � ���������
--		@Earning_BankCode						- ��� �����
--		@Earning_Account						- � �/�
--		@Earning_Value							- ����� �������
--		@Earning_CompanyGuid				- �� ��������-���������� �������
--		@Earning_CurrencyRate				- ���� !?
--		@Earning_CurrencyValue			- !?
--		@Earning_CustomerText				-	
--		@Earning_DetailsPaymentText	- 
--		@Earning_iKey								- 
--		@BudgetProjectSRC_Guid			- �� �������-���������
--		@BudgetProjectDST_Guid			- �� �������-����������
--		@CompanyPayer_Guid					- �� ��������-�����������
--		@ChildDepart_Guid						- �� ��������� �������
--		@AccountPlan_Guid						- �� ������ � ����� ������
--		@PaymentType_Guid						- �� ����� ������
--		@Earning_IsBonus						- ������� "�������� �����"
--		@EarningType_Guid						- �� ���� ������
--
-- �������� ���������:
--
--  @ERROR_NUM										- ����� ������
--  @ERROR_MES										- ����� ������
--
-- ���������:
--    0 - �������� ����������
--    <>0 - ������

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
    SET @EventSrc = '�����';
    
    -- �������� �� ������� ������� � ��������� ���������������
		IF NOT EXISTS( SELECT [Earning_Guid] FROM [dbo].[T_Earning] WHERE [Earning_Guid] = @Earning_Guid )
			BEGIN
				SET @ERROR_NUM = 1;
				SET @ERROR_MES = '� �� ��� �� ������ ����� � ��������� ���������������: ' + CAST( @Earning_Guid AS nvarchar( 36 ) );

				RETURN @ERROR_NUM;
			END
		
		-- ���������� �� �����    
    DECLARE @Account_Guid D_GUID = NULL;
    SELECT TOP 1 @Account_Guid = Account_Guid, @Bank_Guid = Bank_Guid FROM T_Account 
		WHERE Account_Guid = @Earning_AccountGuid;
    
		IF NOT EXISTS ( SELECT [Account_Guid] FROM [dbo].[T_Account]	WHERE [Account_Guid] = @Earning_AccountGuid )
			BEGIN
				SET @ERROR_NUM = 3;
				SET @ERROR_MES = '� ���� ������ �� ������ ���� � ��������� ���������������: ' + CAST( @Earning_AccountGuid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	
		ELSE 
			SELECT TOP 1 @Account_Guid = Account_Guid, @Bank_Guid = Bank_Guid FROM T_Account 
			WHERE Account_Guid = @Earning_AccountGuid;			

    -- ������-��������
		IF( @BudgetProjectSRC_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [BUDGETPROJECT_GUID] FROM [dbo].[T_BudgetProject] 
				WHERE [BUDGETPROJECT_GUID] = @BudgetProjectSRC_Guid )
			BEGIN
				SET @ERROR_NUM = 4;
				SET @ERROR_MES = '� ���� ������ �� ������ ������-�������� � ��������� ���������������: ' + CAST( @BudgetProjectSRC_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- ������-����������
		IF( @BudgetProjectDST_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [BUDGETPROJECT_GUID] FROM [dbo].[T_BudgetProject] 
				WHERE [BUDGETPROJECT_GUID] = @BudgetProjectDST_Guid )
			BEGIN
				SET @ERROR_NUM = 5;
				SET @ERROR_MES = '� ���� ������ �� ������ ������-���������� � ��������� ���������������: ' + CAST( @BudgetProjectDST_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- ��������-����������
		IF( @CompanyPayer_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [Company_Guid] FROM [dbo].[T_Company]
				WHERE [Company_Guid] = @CompanyPayer_Guid )
			BEGIN
				SET @ERROR_NUM = 6;
				SET @ERROR_MES = '� ���� ������ �� ������� ��������-���������� � ��������� ���������������: ' + CAST( @CompanyPayer_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- �������� ������
		DECLARE	@CustomerChild_Guid	D_GUID_NULL = NULL;
		IF( @ChildDepart_Guid IS NOT NULL )
			BEGIN
				SELECT @CustomerChild_Guid = [CustomerChild_Guid] FROM [dbo].[T_CustomerChild]
				WHERE ( [ChildDepart_Guid] = @ChildDepart_Guid ) AND ( [Customer_Guid] = @Earning_CustomerGuid );

				IF( @CustomerChild_Guid IS NULL )
				BEGIN
					SET @ERROR_NUM = 7;
					SET @ERROR_MES = '� ���� ������ �� ������ �������� ������ � ��������� ���������������: ' + CAST( @CustomerChild_Guid as nvarchar(36) );

					RETURN @ERROR_NUM;
				END	
			END

    -- ���� ������
		IF( @AccountPlan_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [ACCOUNTPLAN_GUID] FROM [dbo].[T_AccountPlan]
				WHERE [ACCOUNTPLAN_GUID] = @AccountPlan_Guid )
			BEGIN
				SET @ERROR_NUM = 8;
				SET @ERROR_MES = '� ���� ������ �� ������� ������ � ����� ������ � ��������� ���������������: ' + CAST( @AccountPlan_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

    -- ����� ������
		IF( @PaymentType_Guid IS NOT NULL )
			IF NOT EXISTS ( SELECT [PaymentType_Guid]  FROM [dbo].[T_PaymentType]
				WHERE [PaymentType_Guid] = @PaymentType_Guid )
			BEGIN
				SET @ERROR_NUM = 9;
				SET @ERROR_MES = '� ���� ������ �� ������� ����� ������ � ��������� ���������������: ' + CAST( @PaymentType_Guid as nvarchar(36) );

				RETURN @ERROR_NUM;
			END	

     -- ������
     IF( @Earning_CustomerGuid IS NOT NULL)
       IF NOT EXISTS ( SELECT Customer_Guid FROM dbo.T_Customer WHERE Customer_Guid = @Earning_CustomerGuid )
        BEGIN
         SET @ERROR_NUM = 10;
         SET @ERROR_MES = '� ���� ������ �� ������ ������ � ��������� ���������������: ' + CAST( @Earning_CustomerGuid as nvarchar(36) );

         RETURN @ERROR_NUM;
        END    

     -- ������
		 IF NOT EXISTS ( SELECT Currency_Guid FROM dbo.T_Currency WHERE Currency_Guid = @Earning_CurrencyGuid )
      BEGIN
        SET @ERROR_NUM = 11;
        SET @ERROR_MES = '� ���� ������ �� ������� ������ � ��������� ���������������: ' + CAST( @Earning_CurrencyGuid as nvarchar(36) );

        RETURN @ERROR_NUM;
      END    
			
		 -- ��������
     IF NOT EXISTS ( SELECT Company_Guid FROM dbo.T_Company WHERE Company_Guid = @Earning_CompanyGuid )
      BEGIN
        SET @ERROR_NUM = 12;
        SET @ERROR_MES = '� ���� ������ �� ������� �������� � ��������� ���������������: ' + CAST( @Earning_CompanyGuid as nvarchar(36) );

        RETURN @ERROR_NUM;
      END       

    -- ��� ������
		IF( @EarningType_Guid IS NOT NULL )
			BEGIN
				IF NOT EXISTS ( SELECT [EarningType_Guid]  FROM [dbo].[T_EarningType]	WHERE [EarningType_Guid] = @EarningType_Guid )
					BEGIN
						SET @ERROR_NUM = 13;
						SET @ERROR_MES = '� ���� ������ �� ������ ��� ������ � ��������� ���������������: ' + CAST( @EarningType_Guid as nvarchar(36) );
						
						RETURN @ERROR_NUM;
					END
			END	
		ELSE
			BEGIN
				SET @ERROR_NUM = 13;
				SET @ERROR_MES = '����������, ������� ��� ������ (������ �� �����, ������� � �.�.)';
				
				RETURN @ERROR_NUM;
			END

		-- �������� �� ���������� ���������� ���������� ��������
		IF( ( @CompanyPayer_Guid IS NOT NULL ) OR ( @BudgetProjectSRC_Guid IS NOT NULL ) )
			BEGIN
				-- ������ ������-�������� ���� ��������-����������
				IF( ( ( @CompanyPayer_Guid IS NOT NULL ) AND ( @BudgetProjectSRC_Guid IS NULL ) ) OR
						( ( @CompanyPayer_Guid IS NULL ) AND ( @BudgetProjectSRC_Guid IS NOT NULL ) ) )
					BEGIN
						SET @ERROR_NUM = 14;
						SET @ERROR_MES = '� ��� ������, ���� ������� ���� ��������-����������, ���� ������-��������, ���������� ������� ��� ���������.';
						RETURN @ERROR_NUM;
					END
				ELSE IF ( ( @CompanyPayer_Guid IS NOT NULL ) AND ( @BudgetProjectSRC_Guid IS NOT NULL ) )
					BEGIN
						-- ������� ��� ���������, ��� ������ ������ ���� "���������� ��������"
						IF( @EarningType_Guid IS NULL )
							BEGIN
								SET @ERROR_NUM = 14;
								SET @ERROR_MES = '�������, ����������, ��� ������ "���������� ��������".';
								RETURN @ERROR_NUM;
							END
						ELSE
							BEGIN
								IF NOT EXISTS( SELECT [EarningType_Guid] FROM [dbo].[T_EarningType] WHERE [EarningType_Guid] = @EarningType_Guid AND EarningType_Id = 1 )
									BEGIN
										SET @ERROR_NUM = 14;
										SET @ERROR_MES = '���������� ������� ��� ������ "���������� ��������"!';
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
								SET @ERROR_MES = '��� ���������� ������ ���������� ������� ��������-����������� � ������-��������.';
								RETURN @ERROR_NUM;
							END
					END
			END

		-- ���� ���������������
		DECLARE @CurrencyMainGuid D_GUID; 

		SELECT TOP 1 @CurrencyMainGuid = [Currency_Guid] FROM [dbo].[T_Currency]
		WHERE [Currency_IsMain] = 1;
		SELECT @Earning_CurrencyRate = [dbo].[GetCurrencyRatePricingInOut]( @CurrencyMainGuid, @Earning_CurrencyGuid, @Earning_Date );

		DECLARE @Earning_ValueByCurrencyRate money = 0;
		IF( @Earning_CurrencyRate <> 0 )
			SET @Earning_ValueByCurrencyRate = ( @Earning_Value/@Earning_CurrencyRate );

		-- �������� �� ��������� ���� ������
		--
		-- ���� "������ �� �����" --> "�������" ��� "������ ������", �� ���������� ���������, ���������� �� ������ � ������ ������
		-- ���� ����������, �� �������������� ��������� ������������ ������, � ���� �� ����������, �� � InterBase ������ ���������
		-- 
		-- ���� "�������" ��� "������ ������" --> "������ �� �����", �� ������ ���������� ���������������� � InterBase � ��� ������, ���� Earning_Id = 0
		-- ��� "��������" � "������� �������" �������� ������ �� ������ �� �������������, �� � ����� ������ ���������� ���������, ���������� �� ������ � ������ ������
		-- ���� ����� ������� ������� ������ ����, �� ���������� ������������ ������
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
				SET @ERROR_MES = '������� �� ������� ���������� ������� ��� ������. �������� ��������. ����������, ���������� � ������������.';
				
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
				SET @ERROR_MES = '������ ���������� �� ������. �������������, ����������, ������, � ��������� ��������.';
				
				RETURN @ERROR_NUM;
			END

		BEGIN TRANSACTION UpdateData;

		-- � ��� ������, ���� ������ ������ � ��������� ����, ���������� ���������, �������� �� ���� ���� �������
		-- ���� ���� �� ��������, �� ��������� ���� � ������ ������ �������
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
				-- � ����� � ������� ���� ������ ������ �������� ��������� "������ ���������� ����������� � InterBase"
				IF( ( @PrevEarningType_DublicateInIB = 0 ) AND ( @EarningType_DublicateInIB = 1 ) )
					BEGIN
						IF( @Earning_Id = 0 )
							BEGIN
								-- ������ �� ��������������� � InterBase, ��� ���������� ��������
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
								-- ��� ���������� ��� ������� ���������� ������� ������ �� InterBase (T_EARNING ) 
								EXEC dbo.usp_DeleteEarning2FromIB @Earning_Guid = @Earning_Guid, @IBLINKEDSERVERNAME = NULL, 
									@ERROR_NUM = @ERROR_NUM output, @ERROR_MES = @ERROR_MES output;
								IF( @ERROR_NUM = 0 )
									UPDATE [dbo].[T_Earning] SET Earning_Id = 0 WHERE Earning_Guid = @Earning_Guid;
							END

					END
			END
		ELSE
			BEGIN
				-- ��� ������ �� ��������
				EXEC dbo.usp_EditEarningInIB @Earning_Guid = @Earning_Guid, @IBLINKEDSERVERNAME = NULL, 
					@ERROR_NUM = @ERROR_NUM output, @ERROR_MES = @ERROR_MES output;
			END


		IF( @ERROR_NUM = 0 )
			BEGIN
				SET @strMessage = '� �� ������� ��������� � ���������� � �������. �� ������: ' + CONVERT( nvarchar(36), @Earning_Guid );
				COMMIT TRANSACTION UpdateData
			END
		ELSE 
			BEGIN
				SET @strMessage = '������ ��������� ���������� �������. ' + @ERROR_MES;
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
		SET @ERROR_MES = '�������� ���������� ��������.';

	RETURN @ERROR_NUM;
END

GO
