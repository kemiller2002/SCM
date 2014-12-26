IF NOT EXISTS(SELECT * FROM sys.tables t join sys.schemas s ON t.name = 'Versions')
BEGIN
	CREATE TABLE Versions
	(
		VersionId AS (Major * 1000000 + Minor * 10000 + Patch) PERSISTED PRIMARY KEY NOT NULL 
		,Major INT NOT NULL
		,Minor INT NOT NULL
		,Patch INT NOT NULL
	)

	DECLARE @Major INT 
	DECLARE @Minor INT 
	DECLARE @Patch INT
		DECLARE @OP VARCHAR(50)
	SET @Major = 200

	WHILE @Major >= 0
	BEGIN
		SET @Minor = 50

		WHILE @Minor >= 0
		BEGIN
			SET @Patch = 50
		
			WHILE @Patch >= 0
			BEGIN

				INSERT INTO Versions
				(
					Major
					,Minor
					,Patch
				)
				VALUES 
				(
					@Major
					,@Minor
					,@Patch
				)

			
				SET @OP = 'INSERT ' + CAST(@Major AS VARCHAR) + '.' + CAST(@Minor AS VARCHAR)+ '.' + CAST(@Patch AS VARCHAR)

				RAISERROR (@OP , 0, 0) WITH NOWAIT

				SET @Patch = @Patch -1
			END
			SET @Minor = @Minor -1
		END

		SET @Major = @Major -1
	END


END

--DROP TABLE KeyDeployment.versions