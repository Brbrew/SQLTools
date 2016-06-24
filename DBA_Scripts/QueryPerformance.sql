
SELECT		procedures.object_id,
			schemas.Name AS [Schema],
			procedures.Name AS [Procedure],
			--sql_modules.Definition,			
			procedures.Create_Date,
			procedures.Modify_Date,
			(total_worker_time/execution_count) AS [CPU Time],
			(total_physical_reads/execution_count) AS [Physical Reads],
			(total_logical_writes/execution_count) AS [Logical Writes],
			(total_logical_reads/execution_count) AS [Logical Reads],
			(total_elapsed_time/execution_count) AS [Elapsed Time]
FROM		sys.procedures procedures
INNER JOIN	sys.sql_modules sql_modules
ON			procedures.object_id = sql_modules.object_id
INNER JOIN	sys.schemas schemas
ON			schemas.schema_id = procedures.schema_id
INNER JOIN	(	SELECT		DISTINCT	
							TOP 100 PERCENT					
							sql_text.ObjectID,
							sql_text.text,	
							-- Execution Count
							SUM(query_stats.execution_count) AS execution_count,
							--CPU Time (microseconds)
							SUM(query_stats.total_worker_time) AS total_worker_time,							
							--HDD Reads
							SUM(query_stats.total_physical_reads) AS total_physical_reads,							
							--Logical Writes
							SUM(query_stats.total_logical_writes) AS total_logical_writes,							
							--Logical Reads
							SUM(query_stats.total_logical_reads) AS total_logical_reads,							
							-- .NET Framework Common Language Runtime (CLR)
							--SUM(query_stats.total_clr_time) AS total_clr_time,
							--SUM(query_stats.min_clr_time) AS min_clr_time,
							--SUM(query_stats.max_clr_time) AS max_clr_time,
							-- Total Time (microseconds)
							SUM(query_stats.total_elapsed_time) AS total_elapsed_time					
				FROM		sys.dm_exec_query_stats query_stats
				CROSS APPLY sys.dm_exec_sql_text(query_stats.sql_handle) sql_text
				WHERE		sql_text.ObjectID IS NOT NULL
				GROUP BY	sql_text.text, sql_text.ObjectID
				
			) RS_EXEC
ON			procedures.object_id = RS_EXEC.ObjectID	
ORDER BY	[CPU Time] DESC,
			schemas.Name,
			procedures.Name
			
			
