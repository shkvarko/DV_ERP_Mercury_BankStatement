
UPDATE [dbo].[T_Earning_ForImport] SET [Customer_Guid] = ( SELECT Customer_Guid FROM T_Customer WHERE Customer_Id = [dbo].[T_Earning_ForImport].Customer_Id );

UPDATE [dbo].[T_Earning_ForImport] SET [Company_Guid] = ( SELECT Company_Guid FROM T_Company WHERE Company_Id = [dbo].[T_Earning_ForImport].Company_Id );

UPDATE [dbo].[T_Earning_ForImport] SET [Currency_Guid] = ( SELECT Currency_Guid FROM T_Currency WHERE Currency_Abbr = [dbo].[T_Earning_ForImport].Currency_Code );

UPDATE [dbo].[T_Earning_ForImport] SET [Bank_Guid] = ( SELECT Bank_Guid FROM T_Bank WHERE Bank_Code = [dbo].[T_Earning_ForImport].Bank_Code );

UPDATE [dbo].[T_Earning_ForImport] SET [Account_Guid] = ( SELECT Top 1 Account_Guid FROM T_Account WHERE Account_Number = [dbo].[T_Earning_ForImport].Account_Number );

UPDATE [dbo].[T_Earning_ForImport] SET [PaymentType_Guid] = '58636EC5-F64A-462C-90B1-7686ADFE70F9', [Earning_IsBonus] = 0;

UPDATE [dbo].[T_Earning_ForImport] SET [Bank_Guid] = ( SELECT Bank_Guid FROM T_Account WHERE Account_Guid = [dbo].[T_Earning_ForImport].Account_Guid )
WHERE ( Account_Guid IS NOT NULL ) AND ( [Bank_Guid] IS NULL );

DECLARE @Earning_Id			D_ID;
DECLARE @Customer_Guid	D_GUID;
DECLARE @Currency_Guid	D_GUID;
DECLARE @Company_Guid		D_GUID;
DECLARE @Bank_Guid			D_GUID;
DECLARE @Account_Guid		D_GUID;
DECLARE @PaymentType_Guid	D_GUID;
DECLARE @Earning_Date		D_DATE;
DECLARE @Earning_DocNum	D_NAME;
DECLARE @Earning_Value	D_MONEY;
DECLARE @Earning_Expense	D_MONEY;
DECLARE @Earning_IsBonus	D_YESNO;
DECLARE @Earning_CurrencyRate	D_MONEY;
DECLARE @Earning_CurrencyValue	D_MONEY;

DECLARE @InsertRecordCount int = 0;

  DECLARE crSynch CURSOR FOR SELECT Earning_Id, Customer_Guid, Currency_Guid, Company_Guid, Bank_Guid, 
		Account_Guid, PaymentType_Guid, Earning_Date, Earning_DocNum, Earning_Value, Earning_Expense, Earning_IsBonus, 
		Earning_CurrencyRate, Earning_CurrencyValue 
		FROM T_Earning_ForImport
		WHERE Customer_Guid IS NOT NULL 
			AND Currency_Guid IS NOT NULL 
			AND Company_Guid IS NOT NULL 
			AND Account_Guid IS NOT NULL 
			AND PaymentType_Guid IS NOT NULL
  OPEN crSynch;
  FETCH next FROM crSynch INTO @Earning_Id, @Customer_Guid, @Currency_Guid, @Company_Guid, @Bank_Guid, 
		@Account_Guid, @PaymentType_Guid, @Earning_Date, @Earning_DocNum, @Earning_Value, @Earning_Expense, @Earning_IsBonus, 
		@Earning_CurrencyRate, @Earning_CurrencyValue;
  WHILE @@fetch_status = 0
	  BEGIN
		
	    IF( ( @Earning_Id IS NOT NULL ) AND ( @Earning_Id <> 0 ) )
				BEGIN
					IF NOT EXISTS( SELECT [Earning_Guid] FROM [dbo].[T_Earning]
												 WHERE [Earning_Id] = @Earning_Id AND [PaymentType_Guid] = @PaymentType_Guid )
						BEGIN
							INSERT INTO [dbo].[T_Earning]( Earning_Guid, Earning_Id, Customer_Guid, Currency_Guid, Earning_Date, Earning_DocNum, Bank_Guid, Account_Guid, 
								Earning_Value, Earning_Expense, Company_Guid, Earning_CurrencyRate, Earning_CurrencyValue, Record_Updated, Record_UserUpdated, Earning_iKey, 
								PaymentType_Guid, Earning_IsBonus )
							VALUES( NEWID(), @Earning_Id, @Customer_Guid, @Currency_Guid, @Earning_Date, @Earning_DocNum, @Bank_Guid, @Account_Guid, 
								@Earning_Value, @Earning_Expense, @Company_Guid, @Earning_CurrencyRate, @Earning_CurrencyValue,  GETDATE(), 'Admin',  0,
								@PaymentType_Guid, 0 );

							SET @InsertRecordCount = ( @InsertRecordCount + 1 );
						END
				END

		  FETCH next FROM crSynch INTO @Earning_Id, @Customer_Guid, @Currency_Guid, @Company_Guid, @Bank_Guid, 
		@Account_Guid, @PaymentType_Guid, @Earning_Date, @Earning_DocNum, @Earning_Value, @Earning_Expense, @Earning_IsBonus, 
		@Earning_CurrencyRate, @Earning_CurrencyValue;
	  END
  CLOSE crSynch;
  DEALLOCATE crSynch;

	PRINT 'Добавлено записей: '
	PRINT @InsertRecordCount;
	SELECT @InsertRecordCount;
