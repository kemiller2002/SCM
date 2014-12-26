IF NOT EXISTS(SELECT * FROM sys.tables where name = 'UpdateLog')
BEGIN
	exec sp_sqlexec 'CREATE PROCEDURE InsertUpdateLogEntry AS PRINT ''TEMPLATE'' '
END

GO

ALTER PROCEDURE InsertUpdateLogEntry 
@ProductName VARCHAR(50) 
,@Major INT 
,@Minor INT 
,@Patch INT

AS
BEGIN
	INSERT INTO UpdateLogs
	(
		ProductName
		,Major
		,Minor
		,Patch
	)
	VALUES 
	(
		@ProductName 		
		,@Major
		,@Minor 
		,@Patch 
	)


END