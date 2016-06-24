SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************** 
PURPOSE:		
AUTHOR:			Brian Brewer
DATE:			02/28/2012
NOTES:		

Sample Tree

Leaf Level											
0													Root Node									
1				Left Leaf															  Right Leaf		
2		Blue001	Blue002	Blue003				Blue004							Orange 001			Orange002
3									Purple001	Purple002	Purple003					 Yellow001	 Yellow002	Red001
4																												Green001
5																												Green002
6																												Green003
7																												Green004 
8																												Green005
9																												Green006

CHANGE CONTROL:	
********************************************************************/
IF OBJECT_ID('tempdb..#TestTree') IS NOT NULL
	DROP TABLE #TestTree;

CREATE TABLE #TestTree
(	ID		 INT IDENTITY(1,1) PRIMARY KEY
	,ParentID INT
	,NodeName VARCHAR(255)
	,Sort	 INT
) ON [Primary];
GO

INSERT INTO  #TestTree (ParentID,NodeName,Sort)
VALUES		(NULL,'Root',0)
			,(1,'Left Leaf',1)
			,(1,'Right Leaf',2)
			,(2,'Blue001',1)
			,(2,'Blue002',2)
			,(2,'Blue003',3)
			,(2,'Blue004',4)
			,(7,'Purple001',1)
			,(7,'Purple002',2)						
			,(7,'Purple003',3)						
			,(3,'Orange001',1)
			,(3,'Orange002',1)
			,(11,'Yellow001',1)
			,(11,'Yellow002',2)
			,(12,'Red001',1)			
			,(15,'Green001',1)
			,(16,'Green002',1)
			,(17,'Green003',1)
			,(18,'Green004',1)
			,(19,'Green005',1)
			,(20,'Green006',1)
			,(99,'Orphan',1);
						
;WITH TreeTraverse(ID,ParentID,NodeName,Sort,TreeLevel) AS 
(	-- Pull Root Node
    SELECT		ID
				,ParentID
				,NodeName
				,Sort
				,0 AS TreeLevel
    FROM		#TestTree 
    WHERE		ParentID IS NULL
    -- Children Node
    UNION ALL
    SELECT		TestTree.ID
				,TestTree.ParentID
				,TestTree.NodeName
				,TestTree.Sort
				,TreeTraverse.TreeLevel + 1 AS TreeLevel
    FROM		#TestTree  AS TestTree
    INNER JOIN	TreeTraverse AS TreeTraverse -- Joins back to itself; recursive :)
    ON			TestTree.ParentID = TreeTraverse.ID 
)

SELECT		ID
			,ParentID
			,NodeName
			,Sort
			,TreeLevel
FROM		TreeTraverse
ORDER BY	ParentID
			,ID
			,Sort;

GO

