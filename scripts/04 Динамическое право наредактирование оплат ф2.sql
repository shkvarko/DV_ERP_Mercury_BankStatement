USE [ERP_Mercury]
GO

DECLARE	@return_value int

EXEC	@return_value = [dbo].[AddRights]
		@strName = N'ƒоступ к оплатам по ф2 на редактирование',
		@strDescription = N'ƒоступ к оплатам по ф2 на редактирование',
		@strRole = N'ƒоступ к оплатам по ф2 на редактирование'

SELECT	'Return Value' = @return_value

GO