﻿
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fncEndOfMonth]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fncEndOfMonth]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fncEndOfMonth]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'
/******************************************************************** 
PURPOSE:		
AUTHOR:			Brian Brewer
DATE:			04/10/2012
NOTES:		
CHANGE CONTROL:	
********************************************************************/
CREATE FUNCTION [dbo].[fncEndOfMonth] (@InputDate DATETIME)
RETURNS DATETIME
AS
BEGIN
	DECLARE @OutputDate DATETIME
	SET @OutputDate = DATEADD(dd,-1,DATEADD(mm,1,CAST(CAST(MONTH(CAST(@InputDate AS DATETIME)) AS VARCHAR(2)) + ''/01/'' + CAST(YEAR(CAST(@InputDate AS DATETIME)) AS VARCHAR(4)) AS DATETIME)))
	RETURN @OutputDate
END





' 
END

GO
