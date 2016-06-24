/**************************************************************************
PURPOSE :		
AUTHOR :		Brian Brewer
DATE:			09-24-2010
Notes :    		
CHANGE CONTROL:
***************************************************************************/

IF EXISTS (SELECT OBJECT_ID('tempdb..#tmpIndexDuplicate'))
DROP TABLE #tmpIndexDuplicate
CREATE TABLE #tmpIndexDuplicate (
	[database_id] [smallint] NOT NULL
	,[schema_id] [int] NOT NULL
	,[object_id] [int] NOT NULL
	,[index_id] [int] NOT NULL
	,[schema] [nvarchar](256) NOT NULL
	,[object] [nvarchar](256) NOT NULL
	,[index] [nvarchar](256) NOT NULL
	,[IX_COL001] [nvarchar](256) NULL
	,[IX_COL002] [nvarchar](256) NULL
	,[IX_COL003] [nvarchar](256) NULL
	,[IX_COL004] [nvarchar](256) NULL
	,[IX_COL005] [nvarchar](256) NULL
	,[IX_COL006] [nvarchar](256) NULL
	,[IX_COL007] [nvarchar](256) NULL
	,[IX_COL008] [nvarchar](256) NULL
	,[IX_COL009] [nvarchar](256) NULL
	,[IX_COL010] [nvarchar](256) NULL
	,reads [int] NULL
	,writes [int] NULL
	,avg_fragmentation [float] NULL
	,DuplicateFlg [bit] DEFAULT(0) NOT NULL
)

TRUNCATE TABLE #tmpIndexDuplicate

INSERT INTO #tmpIndexDuplicate
(	[database_id]
	,[schema_id]
	,[object_id]
	,[index_id]
	,[schema]
	,[object]
	,[index]
	,[IX_COL001]
	,[IX_COL002]
	,[IX_COL003]
	,[IX_COL004]
	,[IX_COL005]
	,[IX_COL006]
	,[IX_COL007]
	,[IX_COL008]
	,[IX_COL009]
	,[IX_COL010]
	,reads
	,writes
)
SELECT		DB_ID() AS database_id
			,[sys_schemas].[schema_id]
			,[sys_objects].[object_id]
			,[sys_indexes].[index_id]
			,[sys_schemas].[name] [schema]
			,[sys_objects].[name] [object]
			,[sys_indexes].[name] [index]
			-- PULL 1st 10 Columns
			,INDEX_COL('[' + [sys_schemas].[name] + '].[' + [sys_objects].[name] + ']',[sys_indexes].[index_id],01) AS [IX_COL001]
			,INDEX_COL('[' + [sys_schemas].[name] + '].[' + [sys_objects].[name] + ']',[sys_indexes].[index_id],02) AS [IX_COL002]
			,INDEX_COL('[' + [sys_schemas].[name] + '].[' + [sys_objects].[name] + ']',[sys_indexes].[index_id],03) AS [IX_COL003]
			,INDEX_COL('[' + [sys_schemas].[name] + '].[' + [sys_objects].[name] + ']',[sys_indexes].[index_id],04) AS [IX_COL004]
			,INDEX_COL('[' + [sys_schemas].[name] + '].[' + [sys_objects].[name] + ']',[sys_indexes].[index_id],05) AS [IX_COL005]
			,INDEX_COL('[' + [sys_schemas].[name] + '].[' + [sys_objects].[name] + ']',[sys_indexes].[index_id],06) AS [IX_COL006]
			,INDEX_COL('[' + [sys_schemas].[name] + '].[' + [sys_objects].[name] + ']',[sys_indexes].[index_id],07) AS [IX_COL007]
			,INDEX_COL('[' + [sys_schemas].[name] + '].[' + [sys_objects].[name] + ']',[sys_indexes].[index_id],08) AS [IX_COL008]
			,INDEX_COL('[' + [sys_schemas].[name] + '].[' + [sys_objects].[name] + ']',[sys_indexes].[index_id],09) AS [IX_COL009]
			,INDEX_COL('[' + [sys_schemas].[name] + '].[' + [sys_objects].[name] + ']',[sys_indexes].[index_id],10) AS [IX_COL010]
			,([ix_usage_stats].[user_seeks] + [ix_usage_stats].[user_scans] + [ix_usage_stats].[user_lookups]) [reads]
			, [ix_usage_stats].[user_updates] [writes]
FROM		[sys].[objects] [sys_objects] WITH (NOLOCK) -- Allows dirty reads
INNER JOIN	[sys].[schemas] [sys_schemas] WITH (NOLOCK)
ON			[sys_schemas].[schema_id] = [sys_objects].[schema_id]
INNER JOIN	[sys].[indexes] [sys_indexes]
ON			[sys_indexes].[object_id] = [sys_objects].[object_id]
LEFT JOIN	sys.dm_db_index_usage_stats [ix_usage_stats]
ON			[ix_usage_stats].[object_id] = [sys_indexes].[object_id]
AND			[ix_usage_stats].[index_id] = [sys_indexes].[index_id]
WHERE		[sys_objects].name NOT LIKE 'sys%'
AND			[sys_objects].[TYPE] = 'U' -- Table
AND			[sys_indexes].[index_id] > 0

UPDATE		#tmpIndexDuplicate
SET			DuplicateFlg = 1
FROM		(	SELECT		DISTINCT
							[tmpIndexDuplicate].[database_id]
							,[tmpIndexDuplicate].[schema_id]
							,[tmpIndexDuplicate].[object_id]
							,[tmpIndexDuplicate].[index_id]
							,[tmpIndexDuplicate].[schema]
							,[tmpIndexDuplicate].[object]
							,[tmpIndexDuplicate].[index]
							,[tmpIndexDuplicate_duplicate].[index_id] [duplicate_index_id]
							,[tmpIndexDuplicate_duplicate].[index] [duplicate_index]
									,ISNULL([tmpIndexDuplicate].[IX_COL001],'')
							+ ',' + ISNULL([tmpIndexDuplicate].[IX_COL002],'')
							+ ',' + ISNULL([tmpIndexDuplicate].[IX_COL003],'')
							+ ',' + ISNULL([tmpIndexDuplicate].[IX_COL004],'')
							+ ',' + ISNULL([tmpIndexDuplicate].[IX_COL005],'')
							+ ',' + ISNULL([tmpIndexDuplicate].[IX_COL006],'')
							+ ',' + ISNULL([tmpIndexDuplicate].[IX_COL007],'')
							+ ',' + ISNULL([tmpIndexDuplicate].[IX_COL008],'')
							+ ',' + ISNULL([tmpIndexDuplicate].[IX_COL009],'')
							+ ',' + ISNULL([tmpIndexDuplicate].[IX_COL010],'') [ALL_IX_COLUMN]
									,ISNULL([tmpIndexDuplicate].[IX_COL001],'')
							+ ',' + ISNULL([tmpIndexDuplicate_duplicate].[IX_COL002],'')
							+ ',' + ISNULL([tmpIndexDuplicate_duplicate].[IX_COL003],'')
							+ ',' + ISNULL([tmpIndexDuplicate_duplicate].[IX_COL004],'')
							+ ',' + ISNULL([tmpIndexDuplicate_duplicate].[IX_COL005],'')
							+ ',' + ISNULL([tmpIndexDuplicate_duplicate].[IX_COL006],'')
							+ ',' + ISNULL([tmpIndexDuplicate_duplicate].[IX_COL007],'')
							+ ',' + ISNULL([tmpIndexDuplicate_duplicate].[IX_COL008],'')
							+ ',' + ISNULL([tmpIndexDuplicate_duplicate].[IX_COL009],'')
							+ ',' + ISNULL([tmpIndexDuplicate_duplicate].[IX_COL010],'') [ALL_IX_COLUMN_duplicate]
				FROM		#tmpIndexDuplicate [tmpIndexDuplicate]
				INNER JOIN	#tmpIndexDuplicate [tmpIndexDuplicate_duplicate]
				ON			[tmpIndexDuplicate_duplicate].[schema_id] = [tmpIndexDuplicate].[schema_id]
				AND			[tmpIndexDuplicate_duplicate].[object_id] = [tmpIndexDuplicate].[object_id]
				AND			[tmpIndexDuplicate_duplicate].[IX_COL001] = [tmpIndexDuplicate].[IX_COL001]
				AND			[tmpIndexDuplicate_duplicate].[IX_COL002] = [tmpIndexDuplicate].[IX_COL002]
				WHERE		[tmpIndexDuplicate].[index_id] <> [tmpIndexDuplicate_duplicate].[index_id]
			) RS_DUPLICATE
WHERE		[#tmpIndexDuplicate].[database_id] = RS_DUPLICATE.[database_id]
AND			[#tmpIndexDuplicate].[schema_id] = RS_DUPLICATE.[schema_id]
AND			[#tmpIndexDuplicate].[object_id] = RS_DUPLICATE.[object_id]
AND			[#tmpIndexDuplicate].[index_id] = RS_DUPLICATE.[index_id]



SELECT		DISTINCT
			[tmpIndexDuplicate].[database_id]
			,[tmpIndexDuplicate].[schema_id]
			,[tmpIndexDuplicate].[object_id]
			,[tmpIndexDuplicate].[index_id]
			,[tmpIndexDuplicate].[schema]
			,[tmpIndexDuplicate].[object]
			,[tmpIndexDuplicate].[index]			
					,ISNULL([tmpIndexDuplicate].[IX_COL001],'')
			+ ',' + ISNULL([tmpIndexDuplicate].[IX_COL002],'')
			+ ',' + ISNULL([tmpIndexDuplicate].[IX_COL003],'')
			+ ',' + ISNULL([tmpIndexDuplicate].[IX_COL004],'')
			+ ',' + ISNULL([tmpIndexDuplicate].[IX_COL005],'')
			+ ',' + ISNULL([tmpIndexDuplicate].[IX_COL006],'')
			+ ',' + ISNULL([tmpIndexDuplicate].[IX_COL007],'')
			+ ',' + ISNULL([tmpIndexDuplicate].[IX_COL008],'')
			+ ',' + ISNULL([tmpIndexDuplicate].[IX_COL009],'')
			+ ',' + ISNULL([tmpIndexDuplicate].[IX_COL010],'') [ALL_IX_COLUMN]
			,reads
			,writes
FROM		#tmpIndexDuplicate [tmpIndexDuplicate]		
WHERE		DuplicateFlg = 1
ORDER BY	[tmpIndexDuplicate].[database_id]
			,[tmpIndexDuplicate].[schema_id]
			,[tmpIndexDuplicate].[object_id]
			,[tmpIndexDuplicate].[index_id]
			
			
	
