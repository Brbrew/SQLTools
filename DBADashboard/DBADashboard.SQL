                              
/********************************************************************* 
PURPOSE:		DBA Dashboard
AUTHOR:			BRB2399
DATE:			02/09/2012
NOTES:		
CHANGE CONTROL:	
********************************************************************/

CREATE PROCEDURE dbo.DBA_Health_RPT

AS

SET NOCOUNT ON;

DECLARE @tableHTML  VARCHAR(MAX)
		,@AltColor VARCHAR(6);

SET		@AltColor = 'DCE6F1';

SET		@tableHTML = '<STYLE type="text/css">
body {font-family:arial;font-size:10px;}
td {font-family:arial;font-size:10px;}
th {font-family:arial;font-size:12px;text-align:center;}
h1 {font-family:arial;font-size:16px;text-align:center;background-color:#244062;color:#FFFFFF;margin: 0px 0px 0px 0px;padding: 0px 0px 0px 0px;}
h2 {font-family:arial;font-size:12px;text-align:center;background-color:#366092;color:#FFFFFF;margin: 0px 0px 0px 0px;padding: 0px 0px 0px 0px;}
</STYLE>
<table cellspacing="0" cellpadding="0">
<tr><td colspan="2"><h1>DBA Health & Wellness Dashboard | ' + CONVERT(CHAR(10),GETDATE(),101) + '</h1></td></tr>
';

SET		@tableHTML = @tableHTML + '<tr><td colspan="2"><h2>Sever Information</h1></td></tr>
';
-- Basic System Info (Check for updates/patches/etc.)
SELECT	@tableHTML = @tableHTML 
		+ '	<tr><td style="width:225px;">Sever Name</td><td>' + RTRIM(LTRIM(@@SERVERNAME)) + '</td></tr>
'
		+ '	<tr style="background-color:#' + @AltColor + '"><td>Service</td><td>' + RTRIM(LTRIM(@@SERVICENAME)) + '</td></tr>
'		
		+ '	<tr><td>SQL Version</td><td>' + RTRIM(LTRIM(@@VERSION)) + '</td></tr>
'	
		+ '	<tr style="background-color:#' + @AltColor + '"><td>Logical CPU Count</td><td>' + RTRIM(LTRIM(CAST(cpu_count AS VARCHAR(255)))) + '</td></tr>
'
		+ '	<tr><td>Hyperthread Ratio</td><td>' + RTRIM(LTRIM(CAST(hyperthread_ratio AS VARCHAR(255)))) + '</td></tr>
'		
		+ '	<tr style="background-color:#' + @AltColor + '"><td>Physical CPU Count</td><td>' + RTRIM(LTRIM(CAST(cpu_count/hyperthread_ratio  AS VARCHAR(255)))) + '</td></tr>
'		
		+ '	<tr><td>Physical Memory (MB)</td><td>' + RTRIM(LTRIM(CAST(physical_memory_in_bytes/1048576   AS VARCHAR(255)))) + '</td></tr>
'		
		+ '	<tr style="background-color:#' + @AltColor + '"><td>SQL Server Start Time</td><td>' + RTRIM(LTRIM(CONVERT(CHAR(10),sqlserver_start_time,101))) + '</td></tr>
'	
FROM	sys.dm_os_sys_info OPTION (RECOMPILE);
/********************************************************************* 
PURPOSE:		Backup Data
AUTHOR:			BRB2399
DATE:			02/09/2012
NOTES:		
CHANGE CONTROL:	
********************************************************************/
SET		@tableHTML = @tableHTML + '<tr><td colspan="2"><h2>Backup Information</h1></td></tr>
';
-- msdb.dbo.backupmediafamily
SELECT		@tableHTML = @tableHTML 
			
			+ '	<tr><td>Database Name</td><td>' + RTRIM(LTRIM(Database_name)) + '</td></tr>
'		
			+ '	<tr style="background-color:#' + @AltColor + '"><td>Last Backup</td><td>' + RTRIM(LTRIM(CONVERT(CHAR(10),Backup_finish_date,101))) + '</td></tr>
'			
			+ '	<tr><td>Recovery Model</td><td>' + RTRIM(LTRIM(recovery_model)) + '</td></tr>
'			
			+ '	<tr style="background-color:#' + @AltColor + '"><td>Compressed Backup Size</td><td>' + RTRIM(LTRIM(compressed_backup_size)) + '</td></tr>
'
			+ '	<tr><td style="border-bottom:1px solid #244062;">Log Count (24hr)</td><td style="border-bottom:1px solid #244062;">' + RTRIM(LTRIM(			
			(	SELECT	COUNT(DISTINCT backup_set_id)
				FROM	msdb.dbo.backupset
				WHERE	[Type] = 'L' -- Log backup
				AND		Database_name = RS_DB.Database_name
				AND		Backup_finish_date >= DATEADD(dd,-1,GETDATE())
			))) + '</td></tr>
'
FROM		(	SELECT	Database_name			
						,Backup_finish_date
						,recovery_model
						,compressed_backup_size
						,RANK() OVER(PARTITION BY Database_name , [Type] ORDER BY Backup_finish_date DESC) [RANK]
				FROM	msdb.dbo.backupset
				WHERE	[Type] = 'D' -- Database backup
			) RS_DB
WHERE		[RANK] = 1
AND			Database_name IN ('PIT','msdb')
ORDER BY	Database_name;
/********************************************************************* 
PURPOSE:		TOP 10 Logins by Sessions
AUTHOR:			BRB2399
DATE:			02/09/2012
NOTES:		
CHANGE CONTROL:	
********************************************************************/
SET		@tableHTML = @tableHTML + '<tr><td colspan="2"><h2>TOP 10 Logins by Session</h1></td></tr>
';

SELECT		@tableHTML = @tableHTML 
			+ '	<tr><td style="border-bottom:1px solid #366092;">Total User Connections</td><td style="border-bottom:1px solid #366092;">' + RTRIM(LTRIM(cntr_value)) + '</td></tr>
'	
FROM		sys.dm_os_performance_counters
WHERE		[object_name] = N'SQLServer:General Statistics' -- Modify this if you have named instances
AND			counter_name = N'User Connections' OPTION (RECOMPILE);


SELECT		TOP 10
			@tableHTML = @tableHTML 			
			+ '	<tr><td'
			+ CASE WHEN (ROW_NUMBER() OVER(ORDER BY COUNT(session_id) DESC) % 2) = 0
				THEN ' style="background-color:#' + @AltColor + '"'				
				ELSE ''
			END
			+
			'>' + RTRIM(LTRIM(login_name))  +'</td><td'
			+ CASE WHEN (ROW_NUMBER() OVER(ORDER BY COUNT(session_id) DESC) % 2) = 0
				THEN ' style="background-color:#' + @AltColor + '"'				
				ELSE ''
			END
			+
			'>' +  RTRIM(LTRIM(CAST(COUNT(session_id) AS VARCHAR(255)))) + '</td></tr>
'		
FROM		sys.dm_exec_sessions 
GROUP BY	login_name
ORDER BY	COUNT(session_id) DESC OPTION (RECOMPILE);
/********************************************************************* 
PURPOSE:		CPU Status
AUTHOR:			BRB2399
DATE:			02/09/2012
NOTES:		
CHANGE CONTROL:	
********************************************************************/
-- CPU Status
SET		@tableHTML = @tableHTML + '<tr><td colspan="2"><h2>CPU Status</h1></td></tr>
';
SELECT	@tableHTML = @tableHTML 
		+ '	<tr><td>%Signal (CPU) Waits</td><td>' + RTRIM(LTRIM(CAST(CAST(100.0 * SUM(signal_wait_time_ms) / SUM (wait_time_ms) AS NUMERIC(20,2)) AS VARCHAR(255)))) + '</td></tr>
'		
		+ '	<tr style="background-color:#' + @AltColor + ';"><td style="border-bottom:1px solid #366092;">%Resource Waits</td><td style="border-bottom:1px solid #366092;">' + RTRIM(LTRIM(CAST( CAST(100.0 * SUM(wait_time_ms - signal_wait_time_ms) / SUM (wait_time_ms) AS NUMERIC(20,2)) AS VARCHAR(255)))) + '</td></tr>
'		
FROM	sys.dm_os_wait_stats OPTION (RECOMPILE);

WITH DB_CPU_Stats
AS	(	SELECT		DatabaseID
					,DB_Name(DatabaseID) AS [DatabaseName]
					,SUM(total_worker_time) AS [CPU_Time_Ms]
		FROM		sys.dm_exec_query_stats AS qs
		CROSS APPLY (	SELECT CONVERT(int, value) AS [DatabaseID] 
						FROM sys.dm_exec_plan_attributes(qs.plan_handle)
						WHERE attribute = N'dbid'
					) AS F_DB
		GROUP BY	DatabaseID 
) 
SELECT		TOP 10
			@tableHTML = @tableHTML 			
			+ '	<tr><td'	
			+ CASE WHEN (ROW_NUMBER() OVER(ORDER BY [CPUTimeMS] DESC) % 2) = 0
				THEN ' style="background-color:#' + @AltColor + '"'				
				ELSE ''
			END
			+
			'>' + DBName +'</td><td'
			
			+ CASE WHEN (ROW_NUMBER() OVER(ORDER BY [CPUTimeMS] DESC) % 2) = 0
				THEN ' style="background-color:#' + @AltColor + '"'				
				ELSE ''
			END
			+
			'>' 
			+ RTRIM(LTRIM(CAST([CPUTimeMS] AS VARCHAR(255))))
			+ ' ('
			+ [CPUPercentage]
			+ '%)</td></tr>
'		
FROM		(	 SELECT		TOP 10
							RTRIM(LTRIM(DatabaseName)) DBName
							,[CPU_Time_Ms]  [CPUTimeMS]
							, RTRIM(LTRIM(CAST((CAST([CPU_Time_Ms] * 1.0 / SUM([CPU_Time_Ms]) OVER() * 100.0 AS DECIMAL(5, 2))) AS VARCHAR(255)))) [CPUPercentage]			
				FROM		DB_CPU_Stats
				WHERE		DatabaseID > 4 -- system databases
				AND			DatabaseID <> 32767 -- ResourceDB
				ORDER BY	[CPU_Time_Ms] DESC
			) RS_DB_INFO
ORDER BY	[CPUTimeMS] DESC;
/********************************************************************* 
PURPOSE:		Memory
AUTHOR:			BRB2399
DATE:			02/09/2012
NOTES:		
CHANGE CONTROL:	
********************************************************************/
-- CPU Status
SET		@tableHTML = @tableHTML + '<tr><td colspan="2"><h2>System Memory</h1></td></tr>';

SELECT		@tableHTML = @tableHTML 
			+ '	<tr><td style="border-bottom:1px solid #366092;">Page Life Expectancy</td><td style="border-bottom:1px solid #366092;">' + RTRIM(LTRIM(cntr_value)) + '</td></tr>
'	
FROM		sys.dm_os_performance_counters
WHERE		[object_name] = N'SQLServer:Buffer Manager' -- Modify this if you have named instances
AND			counter_name = N'Page life expectancy' OPTION (RECOMPILE);

SELECT	@tableHTML = @tableHTML 
		+ '	<tr><td>Total Physical Memory (gb)</td><td>' + RTRIM(LTRIM(CAST(CAST(total_physical_memory_kb/1048510.0 AS DECIMAL(10,4)) AS VARCHAR(255)))) +  '</td></tr>
'		
		+ '	<tr style="background-color:#' + @AltColor + ';"><td>Available Physical Memory (gb)</td><td>' + RTRIM(LTRIM(CAST(CAST(available_physical_memory_kb/1048510.0 AS DECIMAL(10,4)) AS VARCHAR(255))))+  '</td></tr>
'		
		+ '	<tr><td>Total Page File (gb)</td><td>' + RTRIM(LTRIM(CAST(CAST(total_page_file_kb/1048510.0 AS DECIMAL(10,4)) AS VARCHAR(255)))) +  '</td></tr>
'		
		+ '	<tr style="background-color:#' + @AltColor + ';"><td>Available Page File (gb)</td><td>' + RTRIM(LTRIM(CAST(CAST(available_page_file_kb/1048510.0 AS DECIMAL(10,4)) AS VARCHAR(255)))) +  '</td></tr>
'		
		+ '	<tr><td>System Memory State</td><td>' + RTRIM(LTRIM(CAST(system_memory_state_desc AS VARCHAR(255)))) +  '</td></tr>
'		
FROM	sys.dm_os_sys_memory OPTION (RECOMPILE);
/********************************************************************* 
PURPOSE:		Table Information
AUTHOR:			BRB2399
DATE:			02/09/2012
NOTES:		
CHANGE CONTROL:	
********************************************************************/

-- Top 10 Largest by physical size
SET			@tableHTML = @tableHTML + '<tr><td colspan="2"><h2>Top 10 Largest Tables By Row Count</h1></td></tr>'

SELECT		TOP  10
			@tableHTML = @tableHTML 
			+ '	<tr><td'
			+ CASE WHEN (ROW_NUMBER() OVER(ORDER BY [RowCount] DESC) % 2) = 0
				THEN ' style="background-color:#' + @AltColor + '"'				
				ELSE ''
			END
			+
			'>' + [TableName] + ' (' + [Object_ID] + ')</td><td'
			+ CASE WHEN (ROW_NUMBER() OVER(ORDER BY [RowCount] DESC) % 2) = 0
				THEN ' style="background-color:#' + @AltColor + '"'				
				ELSE ''
			END
			+
			'>' + 
			'Rows: ' + RTRIM(LTRIM(CAST([RowCount] AS VARCHAR(255)))) + ' Size (gb): ' + RTRIM(LTRIM(CAST(Size AS VARCHAR(255)))) +  '</td></tr>
'			
FROM		(	SELECT		'[' + SysSchemas.[Name] + '].[' + SysObjects.[Name] + ']' [TableName]
							,RTRIM(LTRIM(CAST(SysObjects.[object_id] AS VARCHAR(255)))) [object_id]
							,CONVERT(CHAR(10),SysObjects.[Create_DATE],101) [Create_DATE]
							,CAST(SUM ( 	CASE  
										WHEN (SysPartitionStats.index_id < 2) THEN (SysPartitionStats.in_row_data_page_count + SysPartitionStats.lob_used_page_count + SysPartitionStats.row_overflow_used_page_count)  
										ELSE SysPartitionStats.lob_used_page_count + SysPartitionStats.row_overflow_used_page_count  
									END  
							)/131072.0 AS DECIMAL(10,4)) AS Size,  
							SUM ( 	CASE  
										WHEN (SysPartitionStats.index_id < 2) THEN row_count  
										ELSE 0  
									END  
							)   AS [RowCount]
				FROM		sys.objects SysObjects
				INNER JOIN	sys.dm_db_partition_stats SysPartitionStats 
				ON			SysPartitionStats.[Object_ID] = SysObjects.[Object_ID]
				INNER JOIN	sys.schemas SysSchemas
				ON			SysObjects.[Schema_ID] = SysSchemas.[Schema_ID]
				WHERE		SysObjects.TYPE = N'U'
				AND			SysObjects.is_ms_shipped = 0
				GROUP BY	SysSchemas.[Name],
							SysObjects.[Schema_ID],
							SysObjects.[Name],
							SysObjects.[Object_ID],			
							SysObjects.[Create_DATE]
			) TABLE_DATA
ORDER BY	[RowCount] DESC;

-- Top 10 Newest
SET			@tableHTML = @tableHTML + '<tr><td colspan="2"><h2>Top 10 Newest Tables</h1></td></tr>'

SELECT		TOP  10
			@tableHTML = @tableHTML 
			+ '	<tr><td'
			+ CASE WHEN (ROW_NUMBER() OVER(ORDER BY [Create_DATE] DESC) % 2) = 0
				THEN ' style="background-color:#' + @AltColor + '"'				
				ELSE ''
			END
			+
			'>' + '[' + SysSchemas.[Name] + '].[' + SysObjects.[Name] + ']' + ' (' + RTRIM(LTRIM(CAST(SysObjects.[object_id] AS VARCHAR(255))))  + ')</td><td'
			+ CASE WHEN (ROW_NUMBER() OVER(ORDER BY [Create_DATE] DESC) % 2) = 0
				THEN ' style="background-color:#' + @AltColor + '"'				
				ELSE ''
			END
			+
			'>' + 
			'Created By: ' + ISNULL(RS_DDL.e_username,'?') + ' On: ' + CONVERT(CHAR(10),SysObjects.[Create_DATE],101) +  '</td></tr>
'	
FROM		sys.objects SysObjects
INNER JOIN	sys.schemas SysSchemas
ON			SysObjects.[Schema_ID] = SysSchemas.[Schema_ID]
LEFT JOIN	(	SELECT		e_objectName
							,e_username
							,e_time
							,RANK() OVER(PARTITION BY e_objectName ORDER BY e_time DESC) [Rank]
				FROM		dbo.dbLOG				
			) RS_DDL
ON			RS_DDL.e_objectName = SysObjects.[Name]
AND			RS_DDL.[Rank] = 1
WHERE		SysObjects.TYPE = N'U'
AND			SysObjects.is_ms_shipped = 0
ORDER BY	SysObjects.[Create_DATE] DESC;			

/********************************************************************* 
PURPOSE:		Index Information
AUTHOR:			BRB2399
DATE:			02/09/2012
NOTES:		
CHANGE CONTROL:	
********************************************************************/
SET			@tableHTML = @tableHTML + '<tr><td colspan="2"><h2>Top 25 Indexes</h1></td></tr>'

SELECT		@tableHTML = @tableHTML 
			+ '	<tr><td style="border-bottom:1px solid #366092;">' + sys.objects.name + ' <b>Impact: ' + RTRIM(LTRIM(CAST( CAST((avg_total_user_cost * avg_user_impact) * (user_seeks + user_scans) AS BIGINT) AS VARCHAR(255)))) + '</b></td><td style="border-bottom:1px solid #366092;">' 
			+  'CREATE NONCLUSTERED INDEX ix_IndexName ON ' + sys.objects.name COLLATE DATABASE_DEFAULT + ' ( ' + IsNull(mid.equality_columns, '') + CASE WHEN mid.inequality_columns IS NULL 
							THEN ''  
				ELSE CASE WHEN mid.equality_columns IS NULL 
								THEN ''  
					ELSE ',' END + mid.inequality_columns END + ' ) ' + CASE WHEN mid.included_columns IS NULL 
							THEN ''  
				ELSE 'INCLUDE (' + mid.included_columns + ')' END + ';' 
			+	'</td></tr>
'
				
			--, mid.equality_columns
			--, mid.inequality_columns
			--, mid.included_columns 
FROM		sys.dm_db_missing_index_group_stats AS migs 
INNER JOIN	sys.dm_db_missing_index_groups AS mig ON migs.group_handle = mig.index_group_handle 
INNER JOIN	sys.dm_db_missing_index_details AS mid ON mig.index_handle = mid.index_handle AND mid.database_id = DB_ID() 
INNER JOIN	sys.objects WITH (nolock) ON mid.OBJECT_ID = sys.objects.OBJECT_ID 
WHERE		migs.group_handle IN 
			( 	SELECT		TOP (500) group_handle 
				FROM        sys.dm_db_missing_index_group_stats WITH (nolock) 
				ORDER BY	(avg_total_user_cost * avg_user_impact) * (user_seeks + user_scans) DESC
			)
        
AND			OBJECTPROPERTY(sys.objects.OBJECT_ID, 'isusertable')=1 
ORDER BY	(avg_total_user_cost * avg_user_impact) * (user_seeks + user_scans) DESC

/********************************************************************* 
PURPOSE:		Worst Performing Queries
AUTHOR:			BRB2399
DATE:			02/09/2012
NOTES:		
CHANGE CONTROL:	
********************************************************************/


/********************************************************************* 
PURPOSE:		Email
AUTHOR:			BRB2399
DATE:			02/09/2012
NOTES:		
CHANGE CONTROL:	
********************************************************************/
-- Output
SET		@tableHTML = @tableHTML
		+ '
</table>'
		
-- PRINT	@tableHTML

EXEC	msdb.dbo.sp_send_dbmail 
		@recipients='myEmail@MyCompany.com'
		,@subject = 'DBA Health & Wellness Dashboard'
		,@body = @tableHTML
		,@body_format = 'HTML';


