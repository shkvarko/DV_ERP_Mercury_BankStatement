USE [ERP_Mercury]
GO

DECLARE	@return_value int

EXEC	@return_value = [dbo].[AddRights]
		@strName = N'������ � ������� �� �2 �� ��������������',
		@strDescription = N'������ � ������� �� �2 �� ��������������',
		@strRole = N'������ � ������� �� �2 �� ��������������'

SELECT	'Return Value' = @return_value

GO