
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APX].[fncFindTreeObjectByID]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [APX].[fncFindTreeObjectByID]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/***********************************************************************
PURPOSE:		Returns TreeObjects in Tree
AUTHOR:			Brian Brewer
DATE:			
NOTES:		

CHANGE CONTROL: 
***********************************************************************/
CREATE FUNCTION [APX].[fncFindTreeObjectByID] (@TreeObjectID BIGINT)

	RETURNS @TreeObjectTable	TABLE(			
			RootTreeObjectID BIGINT
			,TreeObjectGroupID BIGINT			
			,TreeObjectID BIGINT			
			,ParentTreeObjectID BIGINT
			,TreeObjectTypeID INT	
			,TreeObject VARCHAR(255)
			,SubItem VARCHAR(255)
			,TimeCreated DATETIME
			,Depth INT 
			,MaxDepth INT 
			,ChildCount INT 
			,IsRoot INT
			,Sort INT
			)
		
AS
BEGIN		
	--------------------------------------------------------------------------
	--//Find Root Node
	--------------------------------------------------------------------------
	DECLARE @MaxIteration INT = 100 -- Max Iterations; Check against infinite loop
			,@Depth INT
			,@RootTreeObjectID INT
			,@ParentTreeObjectID INT					
		
	SELECT	TOP 1 		
			@RootTreeObjectID  = TreeObjectID
			,@ParentTreeObjectID = ParentTreeObjectID
			,@Depth = Depth		
	FROM	[APX].[TreeObject]
	WHERE	TreeObjectID = @TreeObjectID

	WHILE	@Depth > 0 AND @MaxIteration > 0
	BEGIN
	
		SELECT	TOP 1
				@RootTreeObjectID  = TreeObjectID
				,@ParentTreeObjectID = ParentTreeObjectID		
				,@Depth = Depth				
		FROM	[APX].[TreeObject]
		WHERE	TreeObjectID = @ParentTreeObjectID

		----------------------------------
		SET @MaxIteration -= 1;
	END
	--------------------------------------------------------------------------
	--//Find Leafs
	--------------------------------------------------------------------------
	;WITH	TreeObjectTraverse(	TreeObjectGroupID
								,TreeObjectID
								,ParentTreeObjectID
								,TreeObject
								,ChildCount
								,TimeCreated
								,Depth		
								,TreeObjectTypeID
								,SubItem					
								,MaxDepth
								,IsRoot		
				) AS 
				(	-- Pull Root Node
					SELECT		CAST(NULL AS BIGINT)  AS TreeObjectGroupID
								,TreeObjectID
								,ParentTreeObjectID
								,TreeObject
								,ChildCount
								--,Sort
								,TimeCreated
								,0 AS Depth									
								,TreeObjectTypeID
								,SubItem									
								,MaxDepth
								,IsRoot		
					FROM		[APX].[TreeObject]
					WHERE		ParentTreeObjectID IS NULL
					AND			TreeObjectID = @RootTreeObjectID
					-- Sub Tree
					UNION ALL
					SELECT		[TreeObject].TreeObjectID AS TreeObjectGroupID
								,[TreeObject].TreeObjectID
								,[TreeObject].ParentTreeObjectID
								,[TreeObject].TreeObject
								,[TreeObject].ChildCount
								,[TreeObject].TimeCreated
								--,TestTree.Sort
								,TreeObjectTraverse.Depth + 1 AS Depth									
								,[TreeObject].TreeObjectTypeID
								,[TreeObject].SubItem									
								,[TreeObject].MaxDepth
								,[TreeObject].IsRoot																		
					FROM		[APX].[TreeObject] AS [TreeObject]
					INNER JOIN	TreeObjectTraverse AS TreeObjectTraverse -- Joins back to itself; recursive 
					ON			[TreeObject].ParentTreeObjectID = TreeObjectTraverse.TreeObjectID 
					WHERE		[TreeObject].ParentTreeObjectID IS NOT NULL
					AND			[TreeObject].ChildCount > 0		
					UNION ALL
					SELECT		[TreeObject].ParentTreeObjectID AS TreeObjectGroupID
								,[TreeObject].TreeObjectID
								,[TreeObject].ParentTreeObjectID
								,[TreeObject].TreeObject
								,[TreeObject].ChildCount
								,[TreeObject].TimeCreated
								--,TestTree.Sort
								,TreeObjectTraverse.Depth + 1 AS Depth									
								,[TreeObject].TreeObjectTypeID
								,[TreeObject].SubItem									
								,[TreeObject].MaxDepth
								,[TreeObject].IsRoot				
					FROM		[APX].[TreeObject] AS [TreeObject]
					INNER JOIN	TreeObjectTraverse AS TreeObjectTraverse -- Joins back to itself; recursive 
					ON			[TreeObject].ParentTreeObjectID = TreeObjectTraverse.TreeObjectID 
					WHERE		[TreeObject].ParentTreeObjectID IS NOT NULL
					AND			[TreeObject].ChildCount = 0	
				)
	INSERT	INTO @TreeObjectTable (
				RootTreeObjectID
				,TreeObjectGroupID
				,TreeObjectID
				,ParentTreeObjectID
				,TreeObject
				,ChildCount
				,TimeCreated
				,Depth		
				,TreeObjectTypeID
				,SubItem					
				,MaxDepth
				,IsRoot		
				,Sort
				)
	SELECT		DISTINCT
				RootTreeObjectID
				,TreeObjectGroupID
				,TreeObjectID
				,ParentTreeObjectID
				,TreeObject
				,ChildCount
				,TimeCreated
				,Depth		
				,TreeObjectTypeID
				,SubItem					
				,MaxDepth
				,IsRoot		
				,row_number() OVER (PARTITION BY 1 ORDER BY TreeObjectGroupID,TreeObjectID,TimeCreated ) AS Sort	
	FROM		(	SELECT		DISTINCT
								@RootTreeObjectID AS RootTreeObjectID
								,MIN(TreeObjectGroupID) OVER (PARTITION BY TreeObjectID ORDER BY TimeCreated) AS TreeObjectGroupID
								,TreeObjectID
								,ParentTreeObjectID
								,TreeObject
								,ChildCount										
								,TimeCreated
								,Depth		
								,TreeObjectTypeID
								,SubItem									
								,MaxDepth
								,IsRoot						
					FROM		TreeObjectTraverse
				) RS
	ORDER BY	TreeObjectGroupID
				,ChildCount DESC


	RETURN
END	


GO
