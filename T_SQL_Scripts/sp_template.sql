USE [master];
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_template]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[sp_template];
GO

CREATE PROCEDURE dbo.sp_template

AS



PRINT 'USE ' + DB_NAME() + ';
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

------------------------------------------------------------------------------------------------------------------------
-- //
------------------------------------------------------------------------------------------------------------------------
PURPOSE:		
AUTHOR:			Brian Brewer
DATE:			' + CONVERT(CHAR(10),GETDATE(),101) + '
NOTES:		
CHANGE CONTROL:	
********************************************************************/

BEGIN TRANSACTION;



-- ROLLBACK;
COMMIT;
GO';

GO
