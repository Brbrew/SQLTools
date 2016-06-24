

GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

/***********************************************************************
PURPOSE:		Create [tmpSysDBAudit]
AUTHOR:			Brian Brewer
DATE:			01-18-2010
NOTES:			
CHANGE CONTROL: 
***********************************************************************/
SELECT		procedures.[object_id]
			,schemas.Name AS [Schema]
			,procedures.Name AS [Procedure]
			,sql_modules.[Definition]
			,procedures.Create_Date
			,procedures.Modify_Date
FROM		sys.procedures procedures
INNER JOIN	sys.sql_modules sql_modules
ON			procedures.object_id = sql_modules.object_id
INNER JOIN	sys.schemas schemas
ON			schemas.schema_id = procedures.schema_id
LEFT JOIN	sys.sql_expression_dependencies dependencies 
ON			dependencies.referencing_id = procedures.[object_id]
WHERE		OBJECT_DEFINITION(procedures.object_id) LIKE '%text to search%' -- Put whatever text you want in here
OR			referenced_id = OBJECT_ID('dbo.myobjectname') -- specific table name; feel free to comment out

