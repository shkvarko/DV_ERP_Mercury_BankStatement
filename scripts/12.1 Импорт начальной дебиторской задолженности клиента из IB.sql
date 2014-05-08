USE [ERP_Mercury]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[T_CustomerInitalDebt_ForImport](
	[CustomerInitalDebt_Guid] [dbo].[D_GUID] NULL,
	[CustomerInitalDebt_Id] [dbo].[D_ID] NULL,
	[Customer_Guid] [dbo].[D_GUID] NULL,
	[Customer_Id] [dbo].[D_ID] NULL,
	[Currency_Guid] [dbo].[D_GUID] NULL,
	[Currency_Code] [dbo].[D_CURRENCYCODE] NULL,
	[CustomerInitalDebt_Date] [dbo].[D_DATE] NULL,
	[CustomerInitalDebt_DocNum] [dbo].[D_NAME] NULL,
	[CustomerInitalDebt_Value] [dbo].[D_MONEY] NULL,
	[CustomerInitalDebt_AmountPaid] [dbo].[D_MONEY] NULL,
	[CustomerInitalDebt_DateLastPaid]	[dbo].[D_DATE] NULL,
	[Company_Guid] [dbo].[D_GUID] NULL,
	[Company_Id] [dbo].[D_ID] NULL,
	[PaymentType_Guid] [dbo].[D_GUID_NULL] NULL,
	[Earning_IsBonus] [dbo].[D_YESNO] NULL,
	[Earning_CurrencyRate] [dbo].[D_MONEY] NULL,
	[Earning_CurrencyValue] [dbo].[D_MONEY] NULL,
	[CustomerChild_Guid] [dbo].[D_GUID] NULL,
	[CustomerChild_Id] [dbo].[D_ID] NULL
) ON [PRIMARY]

GO


