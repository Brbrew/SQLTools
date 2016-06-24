USE [APEXDW]
GO
/****** Object:  UserDefinedFunction [dbo].[fncBeginningOfWeek]    Script Date: 4/11/2016 10:57:51 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fncBeginningOfWeek]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fncBeginningOfWeek]
GO
/****** Object:  UserDefinedFunction [dbo].[fncBeginningOfWeek]    Script Date: 4/11/2016 10:57:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fncBeginningOfWeek]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'
/******************************************************************** 
PURPOSE:		
AUTHOR:			BRB2399
DATE:			04/10/2012
NOTES:		
CHANGE CONTROL:	
********************************************************************/
CREATE FUNCTION [dbo].[fncBeginningOfWeek] (@InputDate DATETIME)
RETURNS DATETIME
AS
BEGIN
	DECLARE @OutputDate DATETIME
	SET @OutputDate = DATEADD(dd,(-1*DATEPART(dw,@InputDate))+1,@InputDate)
	RETURN @OutputDate
END


' 
END

GO
