USE [Master];
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_tabledetail]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[sp_tabledetail];
GO


/******************************************************************** 
PURPOSE:		
AUTHOR:			Brian Brewer
DATE:			08/29/2011
NOTES:		
CHANGE CONTROL:	
********************************************************************/
--------------------------------------------------
--DECLARE	@OBJECT_NAME VARCHAR(255) = NULL
--SET @OBJECT_NAME = 'ARM.tblPatient'
--------------------------------------------------

CREATE PROCEDURE dbo.sp_tabledetail
		@OBJECT VARCHAR(1024) = NULL		
AS

SET NOCOUNT ON;


DECLARE	@OBJECT_ID INT
		,@OBJECT_NAME VARCHAR(255)
		,@SCHEMA_NAME VARCHAR(255)
		,@DATABASE_NAME VARCHAR(255)
		,@SQL VARCHAR(MAX);

-- Validate OBJECT properties		
SET		@OBJECT_NAME =	RIGHT(@OBJECT,
							CASE 
								WHEN CHARINDEX('.',REVERSE(@OBJECT)) = 0
								THEN LEN(@OBJECT)
								ELSE CHARINDEX('.',REVERSE(@OBJECT)) - 1
							END	
						);
						
SET		@OBJECT = REPLACE(@OBJECT,@OBJECT_NAME,'');

IF CHARINDEX('.',REVERSE(@OBJECT)) = 1
	SET		@OBJECT = LEFT(@OBJECT,LEN(@OBJECT) - 1);
	
SET		@SCHEMA_NAME =	RIGHT(@OBJECT,
							CASE 
								WHEN CHARINDEX('.',REVERSE(@OBJECT)) = 0
								THEN LEN(@OBJECT)
								ELSE CHARINDEX('.',REVERSE(@OBJECT)) - 1
							END	
						);						
						
SET		@OBJECT = REPLACE(@OBJECT,@SCHEMA_NAME,'');						

SET		@DATABASE_NAME = (SELECT TOP 1 NAME FROM master.sys.databases WHERE name = RTRIM(LTRIM(REPLACE(@OBJECT,'.',''))));

SET		@SCHEMA_NAME	 =	CASE WHEN LEN(RTRIM(LTRIM(ISNULL(@SCHEMA_NAME,'')))) = 0
								THEN 'dbo'
								ELSE RTRIM(LTRIM(@SCHEMA_NAME))
							END;	
							
SET		@DATABASE_NAME	=	CASE WHEN LEN(RTRIM(LTRIM(ISNULL(@DATABASE_NAME,'')))) = 0
								THEN DB_NAME()
								ELSE RTRIM(LTRIM(@DATABASE_NAME))
							END;	
		
SET		@OBJECT_ID = OBJECT_ID('[' + @DATABASE_NAME + '].[' + @SCHEMA_NAME + '].[' + @OBJECT_NAME + ']')


-- Check for existance of object
IF @OBJECT_ID IS NULL
    BEGIN       
            RAISERROR (15165, -1,-1,@OBJECT);
			RETURN;
    END


-- Table Details
/******************************************************************** 
PURPOSE:		Specific table details
AUTHOR:			Brian Brewer
DATE:			08/29/2011
NOTES:		
CHANGE CONTROL:	
********************************************************************/

SET @SQL = 'SELECT		''' + @DATABASE_NAME + ''' [DB NAME]			
			,[SysObjects].[Object_Id] [Object ID]
			,[SysObjects].[Schema_ID] [Schema ID]		 
			,[SysSchemas].[Name] [Schema]
			,[SysObjects].[Name] 								
			,[SysObjects].create_Date [Create Date]
			,[SysObjects].modify_date [Modify Date]
			,[SysObjects].is_ms_shipped [MS Shipped]
			,ISNULL([SysExtendedProperties].value,'''') [Description]
			,RS_STATS.Pages [Pages]
			,CAST((RS_STATS.Pages*8.0)/1024.00 AS DECIMAL(10,3)) [Size Mb]
			,RS_STATS.[RowCount] [Row Count]			
FROM		[' + @DATABASE_NAME + '].sys.objects	[SysObjects]
INNER JOIN	[' + @DATABASE_NAME + '].sys.schemas [SysSchemas]
ON			[SysObjects].[Schema_ID] = [SysSchemas].[Schema_ID]
LEFT JOIN	[' + @DATABASE_NAME + '].sys.extended_properties [SysExtendedProperties]
ON			[SysExtendedProperties].class = 1 -- Object or column	
AND			[SysExtendedProperties].name = N''MS_Description''
AND			[SysExtendedProperties].major_id =  [SysObjects].[object_id]
AND			ISNULL([SysExtendedProperties].major_id,0) =  0
LEFT JOIN	(	SELECT		DISTINCT
							TOP 100 PERCENT
							[Object_id]
							,SUM (SysPartitionStats.reserved_page_count) AS ReservedPages 	
							,SUM (SysPartitionStats.used_page_count) AS UsedPages  
							,SUM ( 	CASE  
										WHEN (SysPartitionStats.index_id < 2) THEN (SysPartitionStats.in_row_data_page_count + SysPartitionStats.lob_used_page_count + SysPartitionStats.row_overflow_used_page_count)  
										ELSE SysPartitionStats.lob_used_page_count + SysPartitionStats.row_overflow_used_page_count  
									END  
							) AS Pages  
							,SUM ( 	CASE  
										WHEN (SysPartitionStats.index_id < 2) THEN row_count  
										ELSE 0  
									END  
							)   AS [RowCount]
				FROM		[' + @DATABASE_NAME + '].sys.dm_db_partition_stats [SysPartitionStats]	
				GROUP BY	[Object_id]
				ORDER BY	[Object_id]		
			) RS_STATS
ON			[SysObjects].[object_id] = RS_STATS.[object_id]			
WHERE		[SysObjects].[object_id] = ' + CAST(@OBJECT_ID AS VARCHAR(1024));

EXEC(@SQL);

-- COLUMNS
/******************************************************************** 
PURPOSE:		Column details
AUTHOR:			Brian Brewer
DATE:			08/29/2011
NOTES:		
CHANGE CONTROL:	
********************************************************************/
SET @SQL = 'SELECT	[SysColumns].column_id [Column ID]		
			,[SysColumns].name [Column Name]			
			,CASE 
				WHEN [SysTypes].collation_name IS NOT NULL
				THEN [SysTypes].name + ''('' + RTRIM(LTRIM(CAST([SysColumns].[max_length] AS VARCHAR(255)))) + '')''
				ELSE [SysTypes].name
			END [Base Type]
			,ISNULL([SysExtendedProperties].value,'''') [Description]			
			--,[SysTypes].collation_name			
			,[SysColumns].[is_identity] [Identity]
			,[SysColumns].[is_nullable]	[Nullable]					
FROM		[' + @DATABASE_NAME + '].sys.objects	[SysObjects]
INNER JOIN	[' + @DATABASE_NAME + '].sys.columns [SysColumns]
ON			[SysObjects].[object_id] = [SysColumns].[object_id]
INNER JOIN	[' + @DATABASE_NAME + '].sys.types	[SysTypes]
ON			[SysTypes].system_type_id = [SysColumns].system_type_id
AND			[SysTypes].user_type_id = [SysColumns].user_type_id
INNER JOIN	[' + @DATABASE_NAME + '].sys.schemas [SysSchemas]
ON			[SysObjects].[Schema_ID] = [SysSchemas].[Schema_ID]
LEFT JOIN	[' + @DATABASE_NAME + '].sys.extended_properties [SysExtendedProperties]
ON			[SysExtendedProperties].class = 1 -- Object or column	
AND			[SysExtendedProperties].name = N''MS_Description''
AND			[SysExtendedProperties].major_id =  [SysColumns].[object_id]
AND			[SysExtendedProperties].minor_id =  [SysColumns].[column_id]
WHERE		[SysObjects].[object_id] = ' + CAST(@OBJECT_ID AS VARCHAR(1024)) + '
ORDER BY	[SysColumns].[is_identity] DESC
			,[SysColumns].[is_nullable]
			,[SysExtendedProperties].value DESC
			,[SysColumns].name';

EXEC(@SQL);
-- Indexes
/******************************************************************** 
PURPOSE:		Index details
AUTHOR:			Brian Brewer
DATE:			08/29/2011
NOTES:		
CHANGE CONTROL:	
********************************************************************/

SET @SQL = 'SELECT		[Primary Key]
			,[Index ID]
			,[Index]
			,[Type]			
			,[Unique]
			,LEFT([Index Keys],LEN([Index Keys]) - 1) [Index Keys]
			,CASE WHEN LEN(RTRIM(LTRIM([Included Columns]))) > 0
				THEN LEFT([Included Columns],LEN([Included Columns]) - 1)
				ELSE ''''
			END  [Included Columns]	
			,[Index Reads]
			,[Index Writes]
FROM		(
SELECT		DISTINCT
			[SysIndexes].index_id [Index ID]
			,[SysIndexes].name [Index]
			,[SysIndexes].type_desc [Type]
			,[SysIndexes].is_unique [Unique]
			,[SysIndexes].is_primary_key [Primary Key]
			,CAST(	(SELECT		[columns].[name] + 
								CASE WHEN is_descending_key = 1
									THEN ''(-)''
									ELSE ''''
								END + '', ''
					FROM		[' + @DATABASE_NAME + '].sys.index_columns [index_columns]
					INNER JOIN	[' + @DATABASE_NAME + '].sys.columns [columns]
					ON			[index_columns].[object_id] = [columns].[object_id]
					AND			[index_columns].[column_id] = [columns].[column_id]
					WHERE		[index_columns].is_included_column = 0
					AND			[index_columns].[object_id] = [SysIndexes].[object_id]
					AND			[index_columns].[index_id] = [SysIndexes].[index_id]
					ORDER BY	[index_columns].key_ordinal
					FOR			XML PATH(''''))
			AS VARCHAR(MAX)) [Index Keys]			
			,ISNULL(CAST(	(SELECT		[columns].[name] + 
								CASE WHEN is_descending_key = 1
									THEN ''(-)''
									ELSE ''''
								END + '', ''
					FROM		[' + @DATABASE_NAME + '].sys.index_columns [index_columns]
					INNER JOIN	[' + @DATABASE_NAME + '].sys.columns [columns]
					ON			[index_columns].[object_id] = [columns].[object_id]
					AND			[index_columns].[column_id] = [columns].[column_id]
					WHERE		[index_columns].is_included_column = 1
					AND			[index_columns].[object_id] = [SysIndexes].[object_id]
					AND			[index_columns].[index_id] = [SysIndexes].[index_id]
					ORDER BY	[index_columns].key_ordinal
					FOR			XML PATH(''''))
			AS VARCHAR(MAX)),'''') [Included Columns]
			,SUM((usage_stats.user_seeks + usage_stats.user_scans + usage_stats.user_lookups)) OVER(PARTITION BY usage_stats.index_id) [Index Reads]
			,SUM(user_updates) OVER(PARTITION BY usage_stats.index_id) [Index Writes]
FROM		[' + @DATABASE_NAME + '].sys.indexes [SysIndexes]
INNER JOIN	[' + @DATABASE_NAME + '].sys.dm_db_index_usage_stats usage_stats
ON			usage_stats.index_id = [SysIndexes].[index_id]
AND			usage_stats.object_id = [SysIndexes].[object_id]
WHERE		[SysIndexes].[object_id] = ' + CAST(@OBJECT_ID AS VARCHAR(1024)) + '
			) RS_INDEX
ORDER BY	[Primary Key] DESC
			,[Unique] DESC
			,[Index]';
			
EXEC(@SQL);			


-- Referenced By
/******************************************************************** 
PURPOSE:		Referenced details
AUTHOR:			Brian Brewer
DATE:			08/29/2011
NOTES:			Returns all SPs, Functions, etc. that make a call
				to this table in query plan. This is only compatible
				with SQL 2008 or higher
CHANGE CONTROL:	
********************************************************************/

DECLARE @ProductVersion VARCHAR(255)
SET		@ProductVersion = CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(255))

IF (CAST(RTRIM(LTRIM(LEFT(@ProductVersion,CHARINDEX('.',REVERSE(@ProductVersion))))) AS DECIMAL(10,2))) > = 10
BEGIN

	SET	@SQL = 'SELECT		[SysObjects].[type] [Reference Type]
				,''['' + [SysSchemas].[name] + ''].['' + [SysObjects].[name] + '']'' [Reference Name]
	FROM		[' + @DATABASE_NAME + '].sys.sql_expression_dependencies [Dependencies] WITH (NOLOCK)
	INNER JOIN	[' + @DATABASE_NAME + '].sys.objects AS [SysObjects] WITH (NOLOCK)
	ON			[Dependencies].referencing_id = [SysObjects].[object_id]
	INNER JOIN	[' + @DATABASE_NAME + '].sys.schemas [SysSchemas]
	ON			[SysSchemas].[schema_id] = [SysObjects].[schema_id]
	WHERE		referenced_id = ' + CAST(@OBJECT_ID AS VARCHAR(1024)) + '
	ORDER BY	[SysObjects].[type]
				,[Reference Name]';
	
	EXEC(@SQL);

END
ELSE
	SELECT 'Note: Table references only available in SQL 2008 or higher' [Warning Message];


-- Constraints
/******************************************************************** 
PURPOSE:		Constraint details
AUTHOR:			Brian Brewer
DATE:			08/29/2011
NOTES:			Whenever we finish added foriegn key constraints,
				it will be added here

CHANGE CONTROL:	
********************************************************************/


GO

