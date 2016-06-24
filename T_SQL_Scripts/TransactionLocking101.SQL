
/******************************************************************** 
PURPOSE:		Transaction Locking
AUTHOR:			Brian Brewer
DATE:			02/15/2012
NOTES:		
CHANGE CONTROL:	
********************************************************************/

-- Checks for the existance of an object
-- Note there is no BEGIN and END here SQL runs the first line after an IF statement
-- if the condition is true without a BEGIN or END statement.
-- For multiple satements after an IF clause and BEGIN and END are necessary
IF OBJECT_ID('dbo.MyTestTable') IS NOT NULL
	DROP TABLE dbo.MyTestTable;


-- Create dbo.MyTestTable
CREATE TABLE dbo.MyTestTable
(	TestTableID INT IDENTITY(1,1) PRIMARY KEY -- Auto genterated number used as a primary key
	,TestTableValue VARCHAR(255)
) ON [PRIMARY] -- SQL Partition to create the table in. PRIMARY is default

-- Insert a few sample values
INSERT INTO		dbo.MyTestTable (TestTableValue)
VALUES			('One')
				,('Two')
				,('Three')
				,('Four')
				,('Five');				
				
-- Validate Data
SELECT		TestTableID
			,TestTableValue
FROM		dbo.MyTestTable;		

GO



BEGIN TRANSACTION

	INSERT INTO		dbo.MyTestTable (TestTableValue)
	VALUES			('Six')
					,('Seven')
					,('Eight')
					,('Nine')
					,('Ten');	


-- COMMIT;
-- ROLLBACK;

--READUNCOMMITTED
SELECT		TestTableID
			,TestTableValue
FROM		dbo.MyTestTable	WITH(NOLOCK);

GO
