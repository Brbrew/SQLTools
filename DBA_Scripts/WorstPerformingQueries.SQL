USE [master]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING OFF
GO

/***********************************************************************
PURPOSE:		
AUTHOR:			Brian Brewer
DATE:			
NOTES:			
CHANGE CONTROL: 
***********************************************************************/

IF OBJECT_ID(N'tempdb..#trnQueryPerformance', N'U') IS NOT NULL 
	DROP TABLE #trnQueryPerformance
	
CREATE TABLE #trnQueryPerformance
(
	[QueryPerformanceID] [int] identity(1,1) PRIMARY KEY,
	[EffectiveDT] [datetime],
	[dbid] [smallint] NULL,
	[objectid] [int] NULL,
	[plan_handle] [varbinary](64) NULL,
	[sql_handle] [varbinary](64) NULL,
	[statement_start_offset] [bigint] NULL,
	[statement_end_offset] [bigint] NULL,
	[query_plan] [xml],
	[creation_time] [datetime] NULL,		
	[Statement] [nvarchar](max) NULL,
	[objtype] [nvarchar](20) NULL,
	[execution_count] [bigint] NULL,
	[TotalIO] [bigint] NULL,
	[total_logical_reads] [bigint] NULL,
	[total_logical_writes] [bigint] NULL,
	[total_physical_reads] [bigint] NULL,
	[total_worker_time] [bigint] NULL,
	[total_elapsed_time] [bigint] NULL,
	[last_execution_time] [datetime] NULL,
	[plan_generation_num] [bigint] NULL,
	[last_elapsed_time]  [bigint] NULL,
	[CreateDT] [datetime] default GETDATE() NOT NULL
);	


/***********************************************************************
PURPOSE:		
AUTHOR:			Brian Brewer
DATE:			
NOTES:			
CHANGE CONTROL: 
***********************************************************************/
IF OBJECT_ID(N'tempdb..#tmpQueryPerformance', N'U') IS NOT NULL 
	DROP TABLE #tmpQueryPerformance;
 
CREATE TABLE #tmpQueryPerformance (
	[QueryPerformanceID] [int] identity(1,1) PRIMARY KEY,
	[dbid] [smallint] NULL,
	[objectid] [int] NULL,
	[plan_handle] [varbinary](64) NOT NULL,
	[sql_handle] [varbinary](64) NULL,
	[statement_start_offset] [bigint] NULL,
	[statement_end_offset] [bigint] NULL,
	[creation_time] [datetime] NULL,	
	[Database Name] [nvarchar](129) NULL,
	[Statement] [nvarchar](max) NULL,
	[Schema Name] [nvarchar](128) NULL,
	[Object Name] [nvarchar](128) NULL,
	[objtype] [nvarchar](20) NULL,
	[execution_count] [bigint] NOT NULL,	
	[total_logical_reads] [bigint] NOT NULL,
	[total_logical_writes] [bigint] NOT NULL,
	[total_physical_reads] [bigint] NOT NULL,
	[total_worker_time] [bigint] NOT NULL,
	[total_elapsed_time] [bigint] NOT NULL,
	[last_execution_time] [datetime] NOT NULL,
	[plan_generation_num] [bigint] NOT NULL
) ON [PRIMARY];

 --with XMLNAMESPACES ('http://schemas.microsoft.com/sqlserver/2004/07/showplan' as sql)
INSERT INTO #tmpQueryPerformance
(	[dbid]
	,[objectid]
	,[plan_handle]
	,[sql_handle]	
	,[statement_start_offset]
	,[statement_end_offset]
	,[creation_time]	
	--,[Statement]	
	,[objtype]
	,[execution_count]	
	,[total_logical_reads]
	,[total_logical_writes]
	,[total_physical_reads]
	,[total_worker_time]
	,[total_elapsed_time]
	,[last_execution_time]
	,[plan_generation_num]
	--,[last_elapsed_time]
)	
-- Pull top 500 query plans by total_worker_time / execution_count (avg time per execution)
SELECT		TOP 500
			dbid
			,objectid
			,plan_handle
			,[sql_handle]
			,statement_start_offset  
			,statement_end_offset 	
			,creation_time									  			
			 ,objtype			 
			 ,execution_count
			 ,total_logical_reads			
			 ,total_logical_writes			
			 ,total_physical_reads		
			 ,total_worker_time		
			 ,total_elapsed_time
			 ,last_execution_time		
			 ,plan_generation_num	
 FROM		(	 SELECT		[sql_text].dbid
							,[sql_text].objectid
							,[query_stats].plan_handle
							,[query_stats].sql_handle 
							,[query_stats].creation_time		
							,[query_stats].statement_start_offset  
							,[query_stats].statement_end_offset 							  
							 ,objtype
							--,[sql_text].text AS [Statement]  			
							 ,SUM(execution_count) execution_count
							 --,total_logical_reads/execution_count [Avg Logical Reads] 
							 ,SUM(total_logical_reads) total_logical_reads
							 --,total_logical_writes/execution_count [Avg Logical Writes]  
							 ,SUM(total_logical_writes) total_logical_writes
							 --,total_physical_reads/execution_count [Avg Physical Reads] 
							 ,SUM(total_physical_reads) total_physical_reads
							 --,total_worker_time / execution_count [Avg CPU] 
							 ,SUM(total_worker_time) total_worker_time
							 --,total_elapsed_time / execution_count [Avg Elapsed Time] 
							 ,SUM(total_elapsed_time) total_elapsed_time
							 ,MAX(last_execution_time) last_execution_time
							 --,qp.query_plan
							 ,MAX([query_stats].plan_generation_num) plan_generation_num			 
				FROM		sys.dm_exec_query_stats [query_stats]  
				LEFT JOIN	sys.dm_exec_cached_plans [cached_plans]
				ON			[query_stats].plan_handle = [cached_plans].plan_handle 
				CROSS APPLY sys.dm_exec_sql_text([query_stats].plan_handle) [sql_text]
				--CROSS APPLY sys.dm_exec_query_plan([query_stats].plan_handle) qp
				OUTER APPLY sys.dm_exec_plan_attributes([query_stats].plan_handle) [plan_attributes] 
				WHERE		ISNULL([sql_text].dbid,0) NOT IN (1,4) -- Master/MSDB
				AND			ISNULL(OBJECT_SCHEMA_NAME([sql_text].objectid,[sql_text].dbid),'') <> 'sys'
				GROUP BY	[sql_text].dbid
							,[sql_text].objectid
							,[query_stats].plan_handle
							,[query_stats].sql_handle
							,[query_stats].creation_time	
							,[query_stats].statement_start_offset  
							,[query_stats].statement_end_offset 								  
							 ,objtype
							 ,[sql_text].text
			) RS_STATEMENTS
ORDER BY	total_worker_time / execution_count DESC
/***********************************************************************
PURPOSE:		Create distinct listing of execution plans
AUTHOR:			Brian Brewer
DATE:			
NOTES:			
CHANGE CONTROL: 
***********************************************************************/
DELETE
FROM		#trnQueryPerformance
WHERE		CAST(CONVERT(CHAR(10),EffectiveDT,101) AS DATETIME) = CAST(CONVERT(CHAR(10),GETDATE(),101) AS DATETIME)

INSERT INTO	#trnQueryPerformance
(			[EffectiveDT]
			,[dbid]
			,[objectid]
			,[objtype]			
			,[plan_handle]
			,[sql_handle]	
			,[statement_start_offset]
			,[statement_end_offset]					
			,[plan_generation_num]
			,[creation_time]
			,[last_execution_time]
			,[execution_count]		
			,[total_logical_reads]
			,[total_logical_writes]
			,[total_physical_reads]
			,[total_worker_time]
			,[total_elapsed_time]
)
SELECT		GETDATE(),
			[dbid]
			,[objectid]
			,[objtype]			
			,[plan_handle]
			,[sql_handle]	
			,[statement_start_offset]
			,[statement_end_offset]
			,MAX([plan_generation_num]) [plan_generation_num]
			,MIN([creation_time]) [creation_time]
			,MAX([last_execution_time]) [last_execution_time]
			,SUM([execution_count]) [execution_count]			
			,SUM([total_logical_reads]) [total_logical_reads]
			,SUM([total_logical_writes]) [total_logical_writes]
			,SUM([total_physical_reads]) [total_physical_reads]
			,SUM([total_worker_time]) [total_worker_time]
			,SUM([total_elapsed_time]) [total_elapsed_time]			
FROM		#tmpQueryPerformance
GROUP BY	[dbid]
			,[objectid] 
			,[objtype]			
			,[plan_handle]
			,[sql_handle]	
			,[statement_start_offset]
			,[statement_end_offset]
/***********************************************************************
PURPOSE:		Find last good query plan
AUTHOR:			Brian Brewer
DATE:			
NOTES:			
CHANGE CONTROL: 
***********************************************************************/			
UPDATE		#trnQueryPerformance
SET			[plan_handle] = RS_PLAN.[plan_handle]
FROM		(	SELECT		DISTINCT
							trnQueryPerformance.[QueryPerformanceID]
							,tmpQueryPerformance.[plan_handle]			
							--,tmpQueryPerformance.[last_elapsed_time]			
				FROM		#tmpQueryPerformance tmpQueryPerformance
				INNER JOIN	#trnQueryPerformance trnQueryPerformance
				ON			trnQueryPerformance.[dbid] = tmpQueryPerformance.[dbid]
				AND			trnQueryPerformance.[objectid] = tmpQueryPerformance.[objectid]
				AND			trnQueryPerformance.[plan_generation_num] = tmpQueryPerformance.[plan_generation_num]
				AND			trnQueryPerformance.[last_execution_time] = tmpQueryPerformance.[last_execution_time]
			) RS_PLAN
WHERE		#trnQueryPerformance.[QueryPerformanceID] = RS_PLAN.[QueryPerformanceID]
/***********************************************************************
PURPOSE:		Update query plan XML
AUTHOR:			Brian Brewer
DATE:			
NOTES:			
CHANGE CONTROL: 
***********************************************************************/				
UPDATE		#trnQueryPerformance
SET			[query_plan] = RS_QP.[query_plan]
FROM		(	SELECT		#trnQueryPerformance.[QueryPerformanceID]			
							,[dm_query_plan].[query_plan]
				FROM		#trnQueryPerformance
				CROSS APPLY sys.dm_exec_query_plan(#trnQueryPerformance.[plan_handle]) [dm_query_plan]	
			) RS_QP
WHERE		#trnQueryPerformance.[QueryPerformanceID] = RS_QP.[QueryPerformanceID]
/***********************************************************************
PURPOSE:		Update query plan XML
AUTHOR:			Brian Brewer
DATE:			
NOTES:			
CHANGE CONTROL: 
***********************************************************************/
UPDATE		#trnQueryPerformance
SET			[Statement] = RS_Statement.[Statement]
FROM		(	SELECT		QueryPerformanceID
							,SUBSTRING([sql_text].text, 
								(	trnQueryPerformance.statement_start_offset/2) + 1,
									(	(	CASE	statement_end_offset 
													WHEN -1 THEN DATALENGTH([sql_text].text)
													ELSE trnQueryPerformance.statement_end_offset 
											END 
											- trnQueryPerformance.statement_start_offset
										) / 2
									) 
									+ 1
								) 
							AS [Statement]
				FROM		#trnQueryPerformance trnQueryPerformance
				CROSS APPLY sys.dm_exec_sql_text(trnQueryPerformance.sql_handle) [sql_text]
			) RS_Statement
WHERE		#trnQueryPerformance.QueryPerformanceID = RS_Statement.QueryPerformanceID
/***********************************************************************
PURPOSE:		Final pull
AUTHOR:			Brian Brewer
DATE:			
NOTES:			
CHANGE CONTROL: 
***********************************************************************/			
SELECT		[QueryPerformanceID]
			,[objtype]
			,DB_NAME([dbid]) AS [DATABASE]
			,OBJECT_SCHEMA_NAME([objectid],[dbid]) [Schema Name] 
			,OBJECT_NAME([objectid],[dbid]) [Object Name] 
			,[Statement]
			,total_logical_reads/execution_count [Avg Logical Reads] 
			,objtype [Cached Plan objtype] 
			,execution_count [Execution Count]  			
			,(total_logical_reads + total_logical_writes + total_physical_reads )/execution_count [Average IOs] 
			,total_logical_reads + total_logical_writes + total_physical_reads [Total IOs]  
			,total_logical_reads/execution_count [Avg Logical Reads] 
			,total_logical_reads [Total Logical Reads]  
			,total_logical_writes/execution_count [Avg Logical Writes]  
			,total_logical_writes [Total Logical Writes]  
			,total_physical_reads/execution_count [Avg Physical Reads] 
			,total_physical_reads [Total Physical Reads]   
			,total_worker_time / execution_count [Avg CPU Seconds] 
			,total_worker_time [Total CPU] 
			,total_elapsed_time / execution_count [Avg Elapsed Time Seconds] 
			,total_elapsed_time  [Total Elasped Time] 
			,last_execution_time [Last Execution Time]
			,[query_plan]        
FROM		#trnQueryPerformance   
ORDER BY	(total_worker_time / execution_count) DESC,
			2, -- Schema 
			3 -- OBJ


	  