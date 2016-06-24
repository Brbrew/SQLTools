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
)
/**************************************************************************
PURPOSE :		
AUTHOR :		Brian Brewer
DATE:			09-24-2010
Notes :    		
CHANGE CONTROL:
***************************************************************************/
TRUNCATE TABLE #tmpIndexTableReview
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
							, rows = (SELECT SUM(p.rows) FROM sys.partitions p WHERE p.index_id = usage_stats.index_id AND usage_stats.object_id = p.object_id)
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
WHERE		#tmpIndexTableReview.IndexTableReviewID = rs_usage_stats.IndexTableReviewID		

				
/**************************************************************************
PURPOSE :		
AUTHOR :		Brian Brewer
DATE:			09-24-2010
Notes :    		
CHANGE CONTROL:
***************************************************************************/
DECLARE		@IndexTableReviewID int,
			@object_id int,
			@index_id int,
			@db_id int
SET			@db_id = DB_ID()			
DECLARE		ix_cursor CURSOR FAST_FORWARD FOR 
----------------------------------------------
SELECT		[IndexTableReviewID]
			,[object_id]
			,[index_id]
FROM		#tmpIndexTableReview
WHERE		pages > 0	
AND			index_id > 0
--AND			[rowcount] > 0
AND			fragmentation is null
--AND		[tablename] IN ('PSPROJECTITEM','PS_EX_EE_PYMNT_DTL','PS_CAP_DET')
ORDER BY	[rowcount] DESC
----------------------------------------------
OPEN 		ix_cursor
FETCH		NEXT 
			FROM 		ix_cursor
			INTO		@IndexTableReviewID,
						@object_id,
						@index_id
WHILE @@FETCH_STATUS = 0	
BEGIN
	----------------------------------------------
	UPDATE		#tmpIndexTableReview
	SET			partitionnumber = rs_stats.partitionnumber
				,fragmentation = rs_stats.fragmentation
				,page_count = rs_stats.page_count
	FROM		(	SELECT		@IndexTableReviewID IndexTableReviewID 
								, ps.partition_number AS partitionnumber
								, ps.avg_fragmentation_in_percent AS fragmentation
								, ps.page_count	
					FROM		sys.dm_db_index_physical_stats (@db_id, @object_id, @index_id , NULL, N'Limited') ps
					WHERE		ps.index_id > 0 
					--AND		ps.page_count > 100 
					--AND		ps.avg_fragmentation_in_percent > 30					
				) rs_stats
	WHERE		#tmpIndexTableReview.IndexTableReviewID = rs_stats.IndexTableReviewID				
	OPTION		(MaxDop 1);
	----------------------------------------------
	FETCH		NEXT 
				FROM 		ix_cursor
				INTO		@IndexTableReviewID,
							@object_id,
							@index_id
END
CLOSE ix_cursor
DEALLOCATE ix_cursor



--reads help
--writes hurt
--reads per right - higher more effecient

SELECT		DISTINCT	
			[tablename]
			,[rowcount]
			--,[indexname]
			--,[fragmentation]
			--,[reads]
			--,[writes]
			--,[reads_per_write]
			--,[reservedpages]	
			,[usedpages]
			,[pages]		
FROM		#tmpIndexTableReview
WHERE		pages > 0	
--AND			index_id > 0
--AND			[rowcount] > 1000000
ORDER BY	pages desc,
			[rowcount] desc,
			[tablename]


SELECT		[tablename]
			,[rowcount]
			,[indexname]
			,[type_desc]
			,[fragmentation]
			,[reads]
			,[writes]
			,[reads_per_write]
			,[reservedpages]	
			,[usedpages]
			,[pages]	
			,[pages]*([fragmentation]/100) [Pages Out Of Order]
FROM		#tmpIndexTableReview
WHERE		[pages] > 0	
AND			[index_id] > 0
AND			[rowcount] > 0
ORDER BY	[fragmentation] DESC
			,[pages] DESC	
			
			
-- Heaps


SELECT		[tablename]
			,[rowcount]
			,[indexname]			
			,[reads]
			,[writes]
			,[reads_per_write]
			,[reservedpages]	
			,[usedpages]
			,[pages]		
FROM		#tmpIndexTableReview
WHERE		pages > 0	
AND			index_id > 0
AND			[rowcount] > 0
AND			[object_id] NOT IN (
				SELECT		DISTINCT
							[Object_ID]
				FROM		#tmpIndexTableReview					
				WHERE		type_desc = N'CLUSTERED'
)
ORDER BY	[rowcount] DESC,
			[pages] DESC,
			[tablename],
			[indexname]
			



SELECT		DISTINCT
			[tablename]
			,[rowcount]
			,[pages]		
			
FROM		#tmpIndexTableReview

ORDER BY	[pages] DESC,
			[tablename]
			


--------------------------------------


SELECT	AVG([fragmentation]) AvgFragmentation
		,MIN([fragmentation]) MinFragmentation
		,MAX([fragmentation]) MaxFragmentation		
FROM	#tmpIndexTableReview
WHERE	ISNULL(tmpFlag,0) = 0
AND		[rowcount] >= (
			SELECT	AVG([rowcount]) [rowcount]		
			FROM	#tmpIndexTableReview
			WHERE	ISNULL(tmpFlag,0) = 0
			AND		[rowcount] > 0			
			AND		[index_id] > 0
		)			
AND		[index_id] > 0
		

SELECT	'PeopleSoft Tables' [Metric]
		,COUNT(DISTINCT [object_id]) [ObjectCount]
		,COUNT(DISTINCT [index_id]) [IndexCount]
		,SUM([reservedpages]) [Reserved Pages]
		,SUM([usedpages]) [Used Pages]
		,SUM([pages]) [Total Pages]
		,SUM([rowcount]) [Total Records]
		,AVG([rowcount]) [Average Records]		
		,MIN([rowcount]) [Min Records]
		,MAX([rowcount]) [Max Records]		
		,AVG([fragmentation]) AvgFragmentation
		,MIN([fragmentation]) MinFragmentation
		,MAX([fragmentation]) MaxFragmentation		
FROM	#tmpIndexTableReview
WHERE	ISNULL(tmpFlag,0) = 0
AND		[rowcount] > 0			
AND		[index_id] > 0
UNION
SELECT	'Temporary Tables' [Metric]
		,COUNT(DISTINCT [object_id]) [ObjectCount]
		,COUNT(DISTINCT [index_id]) [IndexCount]
		,SUM([reservedpages]) [Reserved Pages]
		,SUM([usedpages]) [Used Pages]
		,SUM([pages]) [Total Pages]
		,SUM([rowcount]) [Total Records]
		,AVG([rowcount]) [Average Records]		
		,MIN([rowcount]) [Min Records]
		,MAX([rowcount]) [Max Records]		
		,AVG([fragmentation]) AvgFragmentation
		,MIN([fragmentation]) MinFragmentation
		,MAX([fragmentation]) MaxFragmentation			
FROM	#tmpIndexTableReview
WHERE	tmpFlag = 1
UNION
SELECT	'Empty Tables' [Metric]
		,COUNT(DISTINCT [object_id]) [ObjectCount]
		,COUNT(DISTINCT [index_id]) [IndexCount]
		,SUM([reservedpages]) [Reserved Pages]
		,SUM([usedpages]) [Used Pages]
		,SUM([pages]) [Total Pages]
		,SUM([rowcount]) [Total Records]
		,AVG([rowcount]) [Average Records]		
		,MIN([rowcount]) [Min Records]
		,MAX([rowcount]) [Max Records]		
		,AVG([fragmentation]) AvgFragmentation
		,MIN([fragmentation]) MinFragmentation
		,MAX([fragmentation]) MaxFragmentation		
FROM	#tmpIndexTableReview
WHERE	[rowcount] = 0			
AND		[index_id] > 0			
AND		tmpFlag = 0		
			
		


select * from #tmpIndexTableReview