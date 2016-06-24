/********************************************************************* 
PURPOSE:		
AUTHOR:			Brian Brewer
DATE:			08/17/2011
NOTES:		
CHANGE CONTROL:	
********************************************************************/

-- Columns

SELECT		[SysSchemas].[Name] [Schema]
			,[SysObjects].[name] [ObjectName]
			,[SysColumns].name [ColumnName]
			,[SysObjects].[Schema_ID]
			,[SysObjects].[object_id]
			,[SysColumns].column_id			
			--,RS_STATS.ReservedPages
			--,RS_STATS.UsedPages
			--,RS_STATS.Pages
			--,RS_STATS.[RowCount]
			--,[SysColumns].column_id
			--,[SysColumns].name [ColumnName]
			--,[SysTypes].name [ColumnType]
			--,[SysColumns].[is_identity]
			--,[SysColumns].[user_type_id]
			--,[SysColumns].[max_length]
			--,[SysColumns].[precision]
			--,[SysColumns].[scale]
			--,[SysColumns].[is_nullable]			
			,[SysExtendedProperties].value [ExtendedPropertyDescription]
			,'EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N'''' , @level0type=N''SCHEMA'',@level0name=N''' 
				+ [SysSchemas].[Name]
				+ ''', @level1type=N''TABLE'',@level1name=N''' 
				+ [SysObjects].[name]
				+ ''', @level2type=N''COLUMN'',@level2name=N''' 
				+ [SysColumns].name
				+ ''';' [ExtendedPropertyScript]
FROM		sys.objects	[SysObjects]
INNER JOIN	sys.columns [SysColumns]
ON			[SysObjects].[object_id] = [SysColumns].[object_id]
INNER JOIN	sys.types	[SysTypes]
ON			[SysTypes].system_type_id = [SysColumns].system_type_id
AND			[SysTypes].user_type_id = [SysColumns].user_type_id
INNER JOIN	sys.schemas [SysSchemas]
ON			[SysObjects].[Schema_ID] = [SysSchemas].[Schema_ID]
LEFT JOIN	sys.extended_properties [SysExtendedProperties]
ON			[SysExtendedProperties].class = 1 -- Object or column	
AND			[SysExtendedProperties].name = N'MS_Description'
AND			[SysExtendedProperties].major_id =  [SysColumns].[object_id]
AND			[SysExtendedProperties].minor_id =  [SysColumns].[column_id]
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
				FROM		sys.dm_db_partition_stats [SysPartitionStats]	
				GROUP BY	[Object_id]
				ORDER BY	[Object_id]		
			) RS_STATS
ON			[SysObjects].[object_id] = RS_STATS.[object_id]			
WHERE		[SysObjects].[TYPE] = N'U'
AND			[SysExtendedProperties].value IS NULL
-------------------------------------------------
--AND			[SysColumns].name = N'ModifyDT'
--AND			[SysSchemas].name = N'ARM'
--AND			[SysObjects].name LIKE N'tblCommunity%'
-------------------------------------------------
ORDER BY	[Schema]
			,[RowCount] DESC
			,[ObjectName]
			,[ColumnName];
GO			
			
			


-- Tables
SELECT		[SysObjects].[Schema_ID]
			,[SysObjects].[object_id]
			,[SysSchemas].[Name] [Schema]
			,[SysObjects].[name] [ObjectName]									
			,[SysExtendedProperties].value [ExtendedPropertyDescription]
			,'EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N'''' , @level0type=N''SCHEMA'',@level0name=N''' 
				+ [SysSchemas].[Name]
				+ ''', @level1type=N''TABLE'',@level1name=N''' 
				+ [SysObjects].[name]
				+ ''';' [ExtendedPropertyScript]								
FROM		sys.objects	[SysObjects]
INNER JOIN	sys.schemas [SysSchemas]
ON			[SysObjects].[Schema_ID] = [SysSchemas].[Schema_ID]
LEFT JOIN	sys.extended_properties [SysExtendedProperties]
ON			[SysExtendedProperties].class = 1 -- Object or column	
AND			[SysExtendedProperties].name = N'MS_Description'
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
				FROM		sys.dm_db_partition_stats [SysPartitionStats]	
				GROUP BY	[Object_id]
				ORDER BY	[Object_id]		
			) RS_STATS
ON			[SysObjects].[object_id] = RS_STATS.[object_id]			
WHERE		[SysObjects].[TYPE] = N'U'
--AND			[SysExtendedProperties].value IS NULL
-------------------------------------------------
--AND			[SysColumns].name = N'ModifyDT'
--AND			[SysSchemas].name = N'ARM'
--AND			[SysObjects].name LIKE N'tblCommunity%'
-------------------------------------------------
ORDER BY	[Schema]
			--,[RowCount] DESC
			,[ObjectName]
			

