


IF OBJECT_ID('tempdb..#MyTestTable') IS NOT NULL
	DROP TABLE #MyTestTable;

CREATE TABLE #MyTestTable (
	MyTestTableID INT IDENTITY(1,1) PRIMARY KEY
	,MyTestValue VARCHAR(255)
	,CreateDT DATETIME DEFAULT(GETDATE()) NOT NULL
);


TRUNCATE TABLE #MyTestTable;

INSERT INTO #MyTestTable 
		(MyTestValue)
VALUES	('Test001')
		,('Test002')
		,('Test003')
		,('Test004')
		,('Test005')
		,('Test006')
		,('Test007')
		,('Test008')
		,('Test009')
		,('Test010')
		


SELECT		STUFF( (	SELECT	',' + MyTestValue
						FROM	#MyTestTable 
						FOR		XML PATH('') 
					),1,1,''
			) AS MyTestValue