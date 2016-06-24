
/***********************************************************************
PURPOSE:		Pivot Function
AUTHOR:			Brian Brewer
DATE:			07/14/2009
NOTES:			
CHANGE CONTROL: 
***********************************************************************/

---------------------------------------------------------------------------
-- TESTING
DECLARE	@PivotColumn Varchar(5000)
DECLARE	@Columns Varchar(5000)
DECLARE	@AggregateFunction Varchar(500)
DECLARE	@AggregateColumn Varchar(500)
DECLARE	@Table Varchar(5000)


SET		@Columns = 'Column1,Column2,Column3,Column4'
SET		@PivotColumn = 'PivotColumn'
SET		@Table = 'dbo.myTable'
SET		@AggregateFunction = 'SUM'
SET		@AggregateColumn = 'Amount'
--------------------------------------------------------------------------
/*
-- Stub
CREATE Function 

AS
*/
DECLARE @Pivot Varchar(5000)
DECLARE @PivotSelect VARCHAR(5000)
DECLARE	@SQL Varchar(5000)
DECLARE @PivotColumns Table (PivotColumn Varchar(500))
/***********************************************************************
PURPOSE:		Pull distinct list of columns
AUTHOR:			Brian Brewer
DATE:			07/14/2009
NOTES:			
CHANGE CONTROL: 
***********************************************************************/
SET @SQL = 'SELECT DISTINCT ' + @PivotColumn + ' FROM ' + @Table

INSERT INTO @PivotColumns
(
	PivotColumn
)
EXEC(@SQL)
-- Clear out @SQL
SET	@SQL = ''
/***********************************************************************
PURPOSE:		
AUTHOR:			Brian Brewer
DATE:			07/14/2009
NOTES:			
CHANGE CONTROL: 
***********************************************************************/
SELECT	@pivot = coalesce(@pivot+',','')+'['+RTRIM(LTRIM(PivotColumn))+']' from @PivotColumns
SELECT	@PivotSelect = coalesce(@PivotSelect+',','')+'ISNULL(['+RTRIM(LTRIM(PivotColumn))+'],0) AS ['+RTRIM(LTRIM(PivotColumn))+']' from @PivotColumns

SET @SQL = '
	SELECT		' + REPLACE(@Columns,@AggregateColumn,' NULL AS EmptyColumn') + ', ' + @PivotSelect + '
	FROM	   (	SELECT	DISTINCT
							TOP 100 PERCENT
							' +  REPLACE(@Columns,@AggregateColumn,'ISNULL(' + @AggregateColumn + ',0) AS ' + @AggregateColumn) + ', ' + @PivotColumn + '
					FROM	' +  @Table + '	
				) as t	
    PIVOT
				(
					' + @AggregateFunction + '(' + @AggregateColumn + ')' + ' FOR ' + @PivotColumn + ' IN (' + @pivot + ')
				) as p'

PRINT @SQL
EXEC(@SQL)

GO


