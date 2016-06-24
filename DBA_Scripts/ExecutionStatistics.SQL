USE [master]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/***********************************************************************
PURPOSE:		
AUTHOR:			Brian Brewer	
DATE:			
NOTES:			
CHANGE CONTROL: 
***********************************************************************/

SELECT		DISTINCT	
			TOP 100 PERCENT	
			[RS_SQL].[sql_handle],
			[databases].[database_id],
			[RS_SQL].[ObjectID] AS [object_id],			
			[databases].[name] AS [Database],
			[RS_SQL].[text] AS [sql_text],			
			([RS_SQL].total_worker_time/[RS_SQL].execution_count) AS [CPUTime],
			([RS_SQL].total_physical_reads/[RS_SQL].execution_count) AS [PhysicalReads],
			([RS_SQL].total_logical_writes/[RS_SQL].execution_count) AS [LogicalWrites],
			([RS_SQL].total_logical_reads/[RS_SQL].execution_count) AS [LogicalReads],
			([RS_SQL].total_elapsed_time/[RS_SQL].execution_count) AS [ElapsedTime],			
			RS_SQL.session_id,
			RS_SQL.connect_time,
			RS_SQL.client_net_address,
			RS_SQL.local_net_address,
			RS_SQL.local_tcp_port,
			RS_SQL.last_read,
			RS_SQL.last_write,
			RS_SQL.num_reads,
			RS_SQL.num_writes
--INTO		dbo.QueryStatistics			
FROM		(	SELECT		DISTINCT	
							TOP 100 PERCENT	
							sql_text.dbid,				
							sql_text.ObjectID,
							sql_text.text,
							query_stats.sql_handle,
							---------------------------------------------------------
							connections.client_net_address,
							connections.local_net_address,
							connections.local_tcp_port,
							MAX(connections.session_id) AS session_id,
							MAX(connections.connect_time) AS connect_time,
							MAX(connections.last_read) AS last_read,
							MAX(connections.last_write) AS last_write,
							SUM(connections.num_reads) AS num_reads,
							SUM(connections.num_writes) AS num_writes,
							---------------------------------------------------------	
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
							--Total time
							SUM(query_stats.total_elapsed_time) AS total_elapsed_time					
				FROM		sys.dm_exec_query_stats query_stats
				LEFT JOIN	sys.dm_exec_connections connections
				ON			query_stats.sql_handle = connections.most_recent_sql_handle
				CROSS APPLY sys.dm_exec_sql_text(query_stats.sql_handle) sql_text
				WHERE		(	sql_text.[text] LIKE '%insert%'
								OR sql_text.[text] LIKE '%update%'
								OR sql_text.[text] LIKE '%delete%'
							)
				GROUP BY	sql_text.dbid,				
							sql_text.ObjectID,
							sql_text.text,
							query_stats.sql_handle,
							---------------------------------------------------------
							connections.client_net_address,
							connections.local_net_address,
							connections.local_tcp_port
			) RS_SQL
LEFT JOIN	sys.databases [databases]
ON			[databases].[database_id] = [RS_SQL].[dbid]
ORDER BY	[RS_SQL].[sql_handle]



