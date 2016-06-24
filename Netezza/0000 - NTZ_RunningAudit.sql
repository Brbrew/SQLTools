/******************************************************************** 
PURPOSE:             Running Queries
AUTHOR:              Brian Brewer
DATE:                08/15/2012
NOTES:        
CHANGE CONTROL:      
********************************************************************/                           
SELECT		q.qs_planid -- Query Plan ID
			,q.qs_sessionid -- Session ID
			,q.qs_clientid -- Client ID
			,t.dbname -- Database                    
			,t.session_username  -- User      
			,t.client_host -- Host
			,t.client_ip -- IP                
			,q.qs_sql -- SQL 
			,q.qs_tsubmit  -- Time submitted 
			,q.qs_tstart -- Time Started
			,CASE WHEN q.qs_tstart = 'epoch'
			THEN '0'
			ELSE abstime 'now' - q.qs_tstart
			END AS RunningTime   -- Running time            
			,q.qs_estdisk -- Disk
			,q.qs_estmem -- Memory     
			,q.qs_resrows -- Rows returned
			,q.qs_resbytes -- Bytes retunred
FROM		_v_qrystat q -- Query stats
INNER JOIN	_t_sessctx t -- Session Stats
ON			t.session_id = q.qs_sessionid
AND			t.session_state_name = 'active' -- Actively running queries
