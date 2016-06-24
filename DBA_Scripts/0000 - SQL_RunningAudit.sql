--USE [master];
GO

/******************************************************************** 
PURPOSE:		Sessions Connected
AUTHOR:			Brian Brewer
DATE:			05/16/2012
NOTES:			Total users connected to server
CHANGE CONTROL:	
********************************************************************/
/*
SElECT		DISTINCT
			'Total' AS login_name
			,COUNT([exec_sessions].session_id) [Session Count]
			,(SELECT COUNT(session_id) FROM sys.dm_exec_sessions WHERE [status] LIKE '%running%') [Active Running Queries]
			,COUNT([exec_requests].request_id) [Requests]
FROM		sys.dm_exec_sessions [exec_sessions]
LEFT JOIN	sys.dm_exec_requests [exec_requests]
ON			[exec_requests].session_id = [exec_sessions].session_id
UNION
SElECT		DISTINCT
			[exec_sessions].login_name
			,COUNT([exec_sessions].session_id) OVER(PARTITION BY login_name) [Session Count]
			,(SELECT COUNT(session_id) FROM sys.dm_exec_sessions WHERE [status] LIKE '%running%' AND login_name = [exec_sessions].login_name) [Active Running Queries]
			,COUNT([exec_requests].request_id) OVER(PARTITION BY login_name) [Requests]
FROM		sys.dm_exec_sessions [exec_sessions]
LEFT JOIN	sys.dm_exec_requests [exec_requests]
ON			[exec_requests].session_id = [exec_sessions].session_id
ORDER BY	[Active Running Queries] DESC
			,[Requests] DESC
			,[Session Count] DESC;
*/
/******************************************************************** 
PURPOSE:		Running Audit
AUTHOR:			BRB2399
DATE:			05/16/2012
NOTES:			All jobs currently running
CHANGE CONTROL:	
********************************************************************/
SELECT		TOP 100 PERCENT
			[exec_sessions].session_id
			,[exec_sessions].[login_time]
			,[exec_sessions].[host_name]
			,[exec_sessions].login_name
			,[domain].FullName
			--,REF_HUMANA_USERS.username	
			,DB_NAME([exec_requests].database_id) [Database]
			,[exec_sessions].[program_name]
			,[exec_sessions].[client_interface_Name]				
			,[exec_sessions].[status]
			,[exec_connections].connect_time
			,[exec_connections].endpoint_id
			,[exec_connections].num_reads
			,[exec_connections].num_writes
			,[exec_connections].last_read
			,[exec_connections].last_write
			,[exec_connections].client_net_address
			,[exec_connections].client_tcp_port
			,[exec_connections].local_net_address		
			,[exec_requests].blocking_session_id
				-- Notes for blocking_session_id
				-- -2 = The blocking resource is owned by an orphaned distributed transaction.
				-- -3 = The blocking resource is owned by a deferred recovery transaction.
				-- -4 = Session ID of the blocking latch owner could not be determined because of internal latch state transitions.	(I/O latch)		
			,[exec_requests].wait_type
			,[exec_requests].wait_time
			,[exec_requests].wait_resource --(DB_ID:_:OBJECT_ID)
			,[exec_requests].open_transaction_count
			,[exec_requests].cpu_time
			,[exec_requests].reads
			,[exec_requests].writes
			,[exec_requests].logical_reads
			,[exec_requests].row_count		
			,[SQL_HANDLE].[text]	
			,[SQL_HANDLE].objectid			
			--most_recent_sql_handle
			--sql_handle
FROM		sys.dm_exec_sessions [exec_sessions]
--LEFT JOIN	PIT.dbo.REF_HUMANA_USERS REF_HUMANA_USERS
--ON		REF_HUMANA_USERS.LoginName = REPLACE([exec_sessions].[login_name],'HUMAD\','')
LEFT JOIN	sys.dm_exec_connections [exec_connections]
ON			[exec_connections].session_id = [exec_sessions].session_id
LEFT JOIN	sys.dm_exec_requests [exec_requests]
ON			[exec_requests].session_id = [exec_sessions].session_id
LEFT JOIN	[pit].[intake].[domain] [domain]
ON			[domain].Network_ID = [exec_sessions].login_name
CROSS APPLY sys.dm_exec_sql_text(ISNULL([exec_requests].[sql_handle],[exec_connections].most_recent_sql_handle)) [SQL_HANDLE]
WHERE		[exec_sessions].[status] LIKE '%running%'
ORDER BY	blocking_session_id DESC
			,[exec_sessions].[login_name]
			,[Database];

