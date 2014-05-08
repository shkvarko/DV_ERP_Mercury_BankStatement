	USE [ERP_Mercury]
	GO

	DECLARE	@Earning_Guid	D_GUID;
	DECLARE	@ERROR_NUM		int;
	DECLARE	@ERROR_MES		nvarchar;

  DECLARE crSynch CURSOR FOR SELECT Earning_Guid FROM dbo.T_Earning  WHERE [Earning_Date] BETWEEN '20130401' AND '20130425';
  OPEN crSynch;
  FETCH next FROM crSynch INTO @Earning_Guid;
  WHILE @@fetch_status = 0
	  BEGIN
		
	    EXEC dbo.usp_CorrectEarningInfo @Earning_Guid = @Earning_Guid, @ERROR_NUM = @ERROR_NUM output, @ERROR_MES = @ERROR_MES output;

			PRINT @ERROR_NUM;

		  FETCH next FROM crSynch INTO @Earning_Guid;
	  END
  CLOSE crSynch;
  DEALLOCATE crSynch;

