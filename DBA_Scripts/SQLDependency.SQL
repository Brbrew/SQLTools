
/***********************************************************************
PURPOSE:		Find a specific string in a stored procedure (i.e. sp_findtext)
AUTHOR:			Brian Brewer
DATE:			
NOTES:			N denotes Unicode text
CHANGE CONTROL: 
***********************************************************************/
DECLARE		@String VARCHAR(255)
SET			@String = N'search_text'

SELECT		schemas.Name AS [Schema],
			procedures.Name AS [Procedure],
			'sp_helptext ''' + schemas.Name + '.' + procedures.Name + '''' [Helptext],
			sql_modules.[Definition],
			procedures.Create_Date,
			procedures.Modify_Date		
FROM		sys.procedures procedures
INNER JOIN	sys.sql_modules sql_modules
ON			procedures.object_id = sql_modules.object_id
INNER JOIN	sys.schemas schemas
ON			schemas.schema_id = procedures.schema_id
WHERE		[Definition] LIKE N'%' + @String + '%';
GO
/***********************************************************************
PURPOSE:		Find all tables that reference a specific columnn
AUTHOR:			Brian Brewer
DATE:			
NOTES:			N denotes Unicode text
CHANGE CONTROL: 
***********************************************************************/
DECLARE		@ColumnName VARCHAR(255)
SET			@ColumnName = N'ColumnName' -- Column to be found

SELECT		SysSchemas.[Name] AS [Schema],
			SysObjects.[Schema_ID],
			SysObjects.[Name] AS TableName,
			SysObjects.[Object_ID],			
			SysObjects.[Create_DATE],
			RS_AUDIT_COLUMNS.[Column_ID],
			RS_AUDIT_COLUMNS.ColumnName
FROM		sys.objects SysObjects
INNER JOIN	sys.schemas SysSchemas
ON			SysObjects.[Schema_ID] = SysSchemas.[Schema_ID]
INNER JOIN	(	SELECT	DISTINCT
						TOP 100 PERCENT
						[Object_ID],
						[Column_ID],
						[Name] AS ColumnName
				FROM	sys.columns 
				WHERE	[Name] LIKE N'%' + @ColumnName + '%'
			) RS_AUDIT_COLUMNS
ON			SysObjects.[Object_ID] = RS_AUDIT_COLUMNS.[Object_ID]
WHERE		SysObjects.TYPE = 'U' -- "U"ser table
ORDER BY	SysSchemas.[Name],
			SysObjects.[Name],
			RS_AUDIT_COLUMNS.ColumnName;
GO			
/***********************************************************************
PURPOSE:		Final all objects that reference a specific table
AUTHOR:			Brian Brewer
DATE:			
NOTES:			N denotes Unicode text
			

***********************************************************************/
DECLARE		@TableName VARCHAR(255)
SET			@TableName = N'dbo.MyTableName'

SELECT		OBJECT_NAME(referenced_id) [Referenced_Name]
			,OBJECT_SCHEMA_NAME(referencing_id) referencing_schema_name
			,OBJECT_NAME(referencing_id) referencing_entity_name 
			,[SysObjects].type_desc referencing_desciption 
			,COALESCE(COL_NAME(referencing_id, referencing_minor_id), '(n/a)') referencing_minor_id 
			,referencing_class_desc 
			,referenced_class_desc
			,referenced_server_name 
			,referenced_database_name 
			,referenced_schema_name
			,referenced_entity_name
			,COALESCE(COL_NAME(referenced_id, referenced_minor_id), '(n/a)') referenced_column_name
			,is_caller_dependent
			,is_ambiguous
			,referenced_database_name
FROM		sys.sql_expression_dependencies [Dependencies] WITH (NOLOCK)
INNER JOIN	sys.objects AS [SysObjects] WITH (NOLOCK)
ON			[Dependencies].referencing_id = [SysObjects].object_id
WHERE		(
					OBJECT_NAME(referenced_id) LIKE 'text%'
				
			)
ORDER BY	[Referenced_Name]
			,referencing_schema_name
			,referencing_entity_name 
--referenced_id = OBJECT_ID(@TableName);

GO
/***********************************************************************
PURPOSE:		Find all Stored Procedures that reference a specific parameter
AUTHOR:			Brian Brewer
DATE:			
NOTES:			N denotes Unicode text
CHANGE CONTROL: 
***********************************************************************/
DECLARE	@ParameterName VARCHAR(255)
SET		@ParameterName = N'TypeID'

SELECT   SPECIFIC_CATALOG	
		,SPECIFIC_SCHEMA	
		,SPECIFIC_NAME	
		,PARAMETER_MODE	
		,IS_RESULT	
		,PARAMETER_NAME	
		,DATA_TYPE	
		,CHARACTER_MAXIMUM_LENGTH	
FROM	Information_schema.PARAMETERS WITH (NOLOCK) 
WHERE	PARAMETER_NAME LIKE N'%' + @ParameterName + '%';
GO
