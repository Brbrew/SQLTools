

/*
MX is the mean of X
MY is the mean of Y
sX is the standard deviation of X
sY is the standard deviation of Y
R is the correlation between X and Y. 



x = X - mean of X
y = Y - mean of y
xy
x2
y2


Total
Mean


   1  4 -3 -5 15  9 25 
   3  6 -1 -3  3  1  9 
   5 10  1  1  1  1  1 
   5 12  1  3  3  1  9 
   6 13  2  4  8  4 16 
Total 20 45  0  0 30 16 60 
Mean  4  9  0  0  6     

*/

IF OBJECT_ID('tempdb..#temp') IS NOT NULL
	DROP TABLE #temp
	
CREATE 
TABLE	#temp
(
ID INT IDENTITY(1,1) PRIMARY KEY
,XParam FLOAT
,YParam FLOAT
);


DECLARE @Count INT = 0
		,@XParam FLOAT
		,@YParam FLOAT

WHILE @Count <= 1000
BEGIN
	
	SET @XParam = (@Count*RAND())
	SET @YParam = 10*@XParam + 25


	INSERT INTO #temp (XParam, YParam)
	VALUES(@XParam,@YParam)
		   
	SET @Count += 1;
END

/*
TRUNCATE TABLE #temp
INSERT INTO #temp (XParam, YParam)
VALUES(1,1)
,(2,2)
,(3,1.3)
,(4,3.75)
,(5,2.25)
*/

DECLARE @StdX FLOAT		
		,@StdY FLOAT
		,@VarX FLOAT	 	
		,@VarY FLOAT
		,@MeanX FLOAT
		,@MeanY FLOAT
		,@RValue FLOAT
		,@Coef FLOAT
		,@Intercept FLOAT

SELECT	@StdX = STDEV(XParam) 
		,@StdY = STDEV(YParam)
		,@VarX = VAR(XParam) 
		,@VarY = VAR(YParam) 
		,@MeanX = AVG(XParam)
		,@MeanY = AVG(YParam)
FROM	#temp

IF OBJECT_ID('tempdb..#temp') IS NOT NULL
	DROP TABLE #tmpFindR
	
CREATE TABLE #tmpFindR (
	ID INT IDENTITY(1,1) PRIMARY KEY
	,XParam FLOAT
	,YParam FLOAT
	,x FLOAT
	,y FLOAT
	,xy FLOAT
	,x2 FLOAT
	,y2 FLOAT
)

TRUNCATE TABLE #tmpFindR
INSERT INTO #tmpFindR 
(	XParam
	,YParam
	,x
	,y
)
SELECT	XParam
		,YParam
		,XParam - @MeanX
		,YParam - @MeanY
FROM	#temp

UPDATE #tmpFindR
SET		xy = x*y
		,x2 = x*x
		,y2 = y*y;


SELECT	@RValue = SUM(xy) / SQRT((SUM(x2)*SUM(y2)))
FROM	#tmpFindR

SET @Coef = (@RValue*@StdY)/@StdX   --m = r sY/sX --coef

SET @Intercept = @MeanY - (@Coef*@MeanX)

SELECT	@StdX AS StdX
		,@StdY AS StdY
		,@VarX AS VarX
		,@VarY AS VarY 
		,@MeanX AS MeanX
		,@MeanY AS MeanY
		,@RValue*@RValue AS  RValue
		,@Coef AS  Coef
		,@Intercept AS  Intercept

SELECT *
FROM #temp