USE [ERP_Mercury]
GO

DECLARE	@return_value int

EXEC	@return_value = [dbo].[AddRights]
		@strName = N'Доступ к оплатам по ф2 на просмотр',
		@strDescription = N'Доступ к оплатам по ф2 на просмотр',
		@strRole = N'Доступ к оплатам по ф2 на просмотр'

SELECT	'Return Value' = @return_value

GO
