/********************************************************************                                      
PURPOSE:		Simple hashing example to show a basic brute force
				decryption an why it's important to "salt" a hash
				A 3 charecter pasword encrypted by an unsalted MD2 hashing algorithm 
				takes seconds to decrypt
				
AUTHOR:			Brian Brewer
DATE:			06/15/2012
NOTES:			HASH Algorithms: MD2 | MD4 | MD5 | SHA | SHA1 | SHA2_256 | SHA2_512
CHANGE CONTROL:	
********************************************************************/
DECLARE @MyPWD CHAR(3) = 't0#' -- Type any 3 charecters you want in here

DECLARE @HashValue varbinary(8000);
		
-- Create Hash from SHA1, simplest HASHING algorithm
SELECT	@HashValue = HASHBYTES('SHA1', @MyPWD)

-- Table Variable
DECLARE @AsciiTable TABLE (AsciiValue INT)
-- Loop through valid ASCII Charecter Set
DECLARE @AsciiValue INT = 33
WHILE @AsciiValue < 127
BEGIN
	INSERT INTO @AsciiTable (AsciiValue) VALUES (@AsciiValue)
	SET @AsciiValue+=1;	
END

-- Create a list of all possible two charecter combinations
IF OBJECT_ID('tempdb..#Bytes') IS NOT NULL
	DROP TABLE #Bytes

SELECT		CHAR(AsciiTable1.AsciiValue) + CHAR(AsciiTable2.AsciiValue) + CHAR(AsciiTable3.AsciiValue) AS Bytes
INTO		#Bytes
FROM		@AsciiTable AS AsciiTable1
CROSS JOIN	@AsciiTable AS AsciiTable2
CROSS JOIN	@AsciiTable AS AsciiTable3 -- If you wanted to do a 4,5, etc. bit charecter field, keep cartesian joining
--CROSS JOIN	@AsciiTable AS AsciiTable4
--CROSS JOIN	@AsciiTable AS AsciiTable5
ORDER BY	AsciiTable1.AsciiValue
			,AsciiTable2.AsciiValue
			,AsciiTable3.AsciiValue;

-- Hash all possible combinations until a match is found
SELECT		Bytes
FROM		#Bytes
WHERE		HASHBYTES('SHA1', Bytes) = @HashValue; -- Hashing algorithm needs to be the same from above

GO

