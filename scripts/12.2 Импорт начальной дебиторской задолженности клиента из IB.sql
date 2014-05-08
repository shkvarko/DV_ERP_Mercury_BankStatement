USE [ERP_Mercury]
GO

UPDATE [dbo].[T_CustomerInitalDebt_ForImport] SET [Customer_Guid] = ( SELECT Customer_Guid FROM T_Customer WHERE Customer_Id = [dbo].[T_CustomerInitalDebt_ForImport].Customer_Id );

UPDATE [dbo].[T_CustomerInitalDebt_ForImport] SET [Company_Guid] = ( SELECT Company_Guid FROM T_Company WHERE Company_Id = [dbo].[T_CustomerInitalDebt_ForImport].Company_Id );

UPDATE [dbo].[T_CustomerInitalDebt_ForImport] SET [Currency_Guid] = ( SELECT Currency_Guid FROM T_Currency WHERE Currency_Abbr = [dbo].[T_CustomerInitalDebt_ForImport].Currency_Code );

UPDATE [dbo].[T_CustomerInitalDebt_ForImport] SET [PaymentType_Guid] = '58636EC5-F64A-462C-90B1-7686ADFE70F9' WHERE Currency_Code = 'BYB'; -- форма оплаты №1
UPDATE [dbo].[T_CustomerInitalDebt_ForImport] SET [PaymentType_Guid] = 'E872B5E3-83FF-4B1A-925D-0F1B3C4D5C85' WHERE Currency_Code <> 'BYB'; -- форма оплаты №2

UPDATE [dbo].[T_CustomerInitalDebt_ForImport] SET [CustomerChild_Guid] = ( SELECT [CustomerChild_Guid] FROM [dbo].[T_CustomerChild] 
																																						WHERE [CustomerChild_Id] = [dbo].[T_CustomerInitalDebt_ForImport].CustomerChild_Id )
WHERE ( [CustomerChild_Id] IS NOT NULL ) AND ( [CustomerChild_Id] <> 0 )
	AND [Customer_Guid] IS NOT NULL;


DECLARE @CustomerInitalDebt_Id			D_ID;
DECLARE @Customer_Guid	D_GUID;
DECLARE @Currency_Guid	D_GUID;
DECLARE @Company_Guid		D_GUID;
DECLARE @PaymentType_Guid	D_GUID;
DECLARE @CustomerChild_Guid	D_GUID;

DECLARE @CustomerInitalDebt_Date					D_DATE;
DECLARE @CustomerInitalDebt_DateLastPaid	D_DATE;
DECLARE @CustomerInitalDebt_DocNum	D_NAME;
DECLARE @CustomerInitalDebt_Value	D_MONEY;
DECLARE @CustomerInitalDebt_AmountPaid	D_MONEY;

DECLARE @InsertRecordCount int = 0;

  DECLARE crSynch CURSOR FOR SELECT CustomerInitalDebt_Id, Customer_Guid, Currency_Guid, Company_Guid,  
		PaymentType_Guid, CustomerInitalDebt_Date, CustomerInitalDebt_DocNum, CustomerInitalDebt_Value, 
		CustomerInitalDebt_AmountPaid, CustomerInitalDebt_DateLastPaid, CustomerChild_Guid
		FROM [dbo].[T_CustomerInitalDebt_ForImport]
		WHERE Customer_Guid IS NOT NULL 
			AND Currency_Guid IS NOT NULL 
			AND Company_Guid IS NOT NULL 
			AND PaymentType_Guid IS NOT NULL
  OPEN crSynch;
  FETCH next FROM crSynch INTO @CustomerInitalDebt_Id, @Customer_Guid, @Currency_Guid, @Company_Guid,  
		@PaymentType_Guid, @CustomerInitalDebt_Date, @CustomerInitalDebt_DocNum, @CustomerInitalDebt_Value, 
		@CustomerInitalDebt_AmountPaid, @CustomerInitalDebt_DateLastPaid, @CustomerChild_Guid;
  WHILE @@fetch_status = 0
	  BEGIN
		
	    IF( ( @CustomerInitalDebt_Id IS NOT NULL ) AND ( @CustomerInitalDebt_Id <> 0 ) )
				BEGIN
					IF NOT EXISTS( SELECT [CustomerInitalDebt_Guid] FROM [dbo].[T_CustomerInitalDebt]
												 WHERE [CustomerInitalDebt_Id] = @CustomerInitalDebt_Id AND [PaymentType_Guid] = @PaymentType_Guid )
						BEGIN
							INSERT INTO [dbo].[T_CustomerInitalDebt]( CustomerInitalDebt_Guid, CustomerInitalDebt_Id, Customer_Guid, Currency_Guid, 
								CustomerInitalDebt_Date, CustomerInitalDebt_DocNum, CustomerInitalDebt_Value, CustomerInitalDebt_AmountPaid, 
								CustomerInitalDebt_DateLastPaid, Company_Guid, CustomerChild_Guid, PaymentType_Guid, Record_Updated, Record_UserUpdated )
							VALUES( NEWID(), @CustomerInitalDebt_Id, @Customer_Guid, @Currency_Guid,  
								@CustomerInitalDebt_Date, @CustomerInitalDebt_DocNum, @CustomerInitalDebt_Value, @CustomerInitalDebt_AmountPaid,
								@CustomerInitalDebt_DateLastPaid, @Company_Guid, @CustomerChild_Guid, @PaymentType_Guid,
								GETDATE(), 'Admin' );

							SET @InsertRecordCount = ( @InsertRecordCount + 1 );
						END
				END

		  FETCH next FROM crSynch INTO @CustomerInitalDebt_Id, @Customer_Guid, @Currency_Guid, @Company_Guid,  
		@PaymentType_Guid, @CustomerInitalDebt_Date, @CustomerInitalDebt_DocNum, @CustomerInitalDebt_Value, 
		@CustomerInitalDebt_AmountPaid, @CustomerInitalDebt_DateLastPaid, @CustomerChild_Guid;
	  END
  CLOSE crSynch;
  DEALLOCATE crSynch;

	PRINT 'Добавлено записей: '
	PRINT @InsertRecordCount;
	SELECT @InsertRecordCount;
