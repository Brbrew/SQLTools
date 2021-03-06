/****** Object:  UserDefinedFunction [dbo].[SplitString]    Script Date: 4/11/2016 10:57:51 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SplitString]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[SplitString]
GO
/****** Object:  UserDefinedFunction [dbo].[SplitString]    Script Date: 4/11/2016 10:57:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SplitString]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

/***********************************************************************
PURPOSE:		Creates Split String Table Function
AUTHOR:			Brian Brewer
DATE:			01-24-2011
NOTES:			Bypasses CHARINDEX 8k limit

Loops through each charecter looking for delimiter, creates substrings
of charecters between each delemeter and stores those in a table variable

CHANGE CONTROL: 
***********************************************************************/
CREATE FUNCTION [dbo].[SplitString] (@StringInput VARCHAR(MAX),@Delimiter CHAR(1))
	RETURNS	@SplitTable 
			TABLE(	ID INT IDENTITY(1,1) PRIMARY KEY 
					,Value VARCHAR(Max)
			)
AS
BEGIN	
	DECLARE	@CharValue CHAR(1)
			,@String VARCHAR(MAX);		
	WHILE LEN(@StringInput) > 0
	BEGIN
		SET @CharValue = LEFT(@StringInput,1);	
		-- Valid ASCII charecters, ignores breaks, spaces, etc.
		IF @CharValue <> @Delimiter AND ASCII(@CharValue) BETWEEN 32 AND 126 
			SET @String	= COALESCE(@String + @CharValue,@CharValue);	
		IF  @CharValue = @Delimiter
		BEGIN
			INSERT INTO @SplitTable (Value) VALUES(RTRIM(LTRIM(@String)));
			SET @String = NULL;
		END	
		SET	@StringInput = RIGHT(@StringInput,LEN(@StringInput)-1);	
	END		
	-- Insert Last Value
	INSERT INTO @SplitTable (Value) VALUES(RTRIM(LTRIM(@String)));
	RETURN 	
END	




' 
END

GO
