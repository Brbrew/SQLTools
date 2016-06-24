/**************************************************************************
PURPOSE :		
AUTHOR :		Brian Brewer
DATE:			09-24-2010
Notes :    		
CHANGE CONTROL:
***************************************************************************/
IF OBJECT_ID('tempdb..#tmpIndexTableReview') IS NOT NULL
	DROP TABLE #tmpIndexTableReview

CREATE TABLE #tmpIndexTableReview
(	IndexTableReviewID int identity(1,1) primary key
	,[schema] varchar(255)
	,[schema_id] int
	,[object_id] int
	,index_id int
	,tablename varchar(255)
	,reservedpages bigint
	,usedpages bigint
	,pages bigint
	,[rowcount] bigint
	,[rows] bigint
	,indexname varchar(255)
	,type_desc varchar(255)
	,is_unique bit
	,partitionnumber int
	,fragmentation float
	,page_count bigint	
	,reads bigint
	,writes bigint
	,reads_per_write float	
	,tmpFlag INT DEFAULT 0
);
/**************************************************************************
PURPOSE :		
AUTHOR :		Brian Brewer
DATE:			09-24-2010
Notes :    		
CHANGE CONTROL:
***************************************************************************/
TRUNCATE TABLE #tmpIndexTableReview;

INSERT INTO #tmpIndexTableReview
(	[schema]
	,[schema_id]
	,tablename
	,[object_id]
	,reservedpages	
	,usedpages
	,pages
	,[rowcount]
	,indexname
	,index_id 
	,type_desc
	,is_unique
)
SELECT		SysSchemas.[Name] AS [Schema],
			SysObjects.[Schema_ID],
			SysObjects.[Name] AS TableName,
			SysObjects.[Object_ID],							
			SUM (SysPartitionStats.reserved_page_count) AS reservedpages, 	
			SUM (SysPartitionStats.used_page_count) AS UsedPages,  
			SUM ( 	CASE  
						WHEN (SysPartitionStats.index_id < 2) THEN (SysPartitionStats.in_row_data_page_count + SysPartitionStats.lob_used_page_count + SysPartitionStats.row_overflow_used_page_count)  
						ELSE SysPartitionStats.lob_used_page_count + SysPartitionStats.row_overflow_used_page_count  
					END  
			) AS Pages,  
			SUM ( 	CASE  
						WHEN (SysPartitionStats.index_id < 2) THEN row_count  
						ELSE 0  
					END  
			)   AS [RowCount]
			,SysIndexes.name
			,SysIndexes.index_id 
			,SysIndexes.type_desc
			,SysIndexes.is_unique			
FROM		sys.objects SysObjects
INNER JOIN	sys.dm_db_partition_stats SysPartitionStats 
ON			SysPartitionStats.[Object_ID] = SysObjects.[Object_ID]
INNER JOIN	sys.schemas SysSchemas
ON			SysObjects.[Schema_ID] = SysSchemas.[Schema_ID]
LEFT JOIN	sys.indexes SysIndexes
ON			SysIndexes.object_id = SysObjects.[Object_ID]
AND			SysIndexes.index_id <= 1
WHERE		SysObjects.TYPE = 'U'
--AND		SysSchemas.[Name] = 'ARM' -- ISNULL(@SearchSchema,SysSchemas.[Name])
GROUP BY	SysSchemas.[Name],
			SysObjects.[Schema_ID],
			SysObjects.[Name],
			SysObjects.[Object_ID]		
			,SysIndexes.name
			,SysIndexes.index_id 
			,SysIndexes.type_desc
			,SysIndexes.is_unique	
ORDER BY	SysSchemas.[Name],
			SysObjects.[Name]
			,SysIndexes.name
			,SysIndexes.index_id 
			,SysIndexes.type_desc
			,SysIndexes.is_unique	
/**************************************************************************
PURPOSE :		
AUTHOR :		Brian Brewer
DATE:			09-24-2010
Notes :    		
CHANGE CONTROL:
***************************************************************************/
UPDATE		#tmpIndexTableReview
SET			reads = rs_usage_stats.reads
			,writes = rs_usage_stats.writes
			,[rows] = rs_usage_stats.[rows]
			,reads_per_write = rs_usage_stats.reads_per_write
FROM		(	SELECT 		[IndexTableReviewID]
							, reads = usage_stats.user_seeks + usage_stats.user_scans + usage_stats.user_lookups   
							, writes =  user_updates   
							, rows = (SELECT SUM(p.rows) FROM sys.partitions p WHERE p.index_id = usage_stats.index_id AND usage_stats.object_id = p.object_id) -- Usually sub-selects like this in a query are bad; ok here
							, CASE
								WHEN usage_stats.user_updates < 1 THEN 100
								ELSE 1.0000 * (usage_stats.user_seeks + usage_stats.user_scans + usage_stats.user_lookups) / usage_stats.user_updates
							  END AS reads_per_write
				FROM		#tmpIndexTableReview tmpIndexTableReview
				INNER JOIN	sys.dm_db_index_usage_stats usage_stats
				ON			usage_stats.index_id = tmpIndexTableReview.[index_id]
				AND			usage_stats.object_id = tmpIndexTableReview.[object_id]
				AND			usage_stats.database_id = DB_ID()
			) rs_usage_stats
WHERE		#tmpIndexTableReview.IndexTableReviewID = rs_usage_stats.IndexTableReviewID;		


SELECT		DISTINCT	
			[Object_ID]
			,'[' + [schema] + '].[' + [tablename] + ']' AS [table]
			,[rowcount]
			,[indexname]
			,[type_desc]
			,[is_unique]
			--,[fragmentation]
			--,[reads]
			--,[writes]
			--,[reads_per_write]
			--,[reservedpages]	
			,[usedpages]
			,[pages]		
FROM		#tmpIndexTableReview
WHERE		pages > 0	
--AND		index_id > 0
--AND		[rowcount] > 1000000
ORDER BY	pages desc,
			[rowcount] desc,
			[table];


GO