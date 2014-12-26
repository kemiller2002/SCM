IF NOT EXISTS(SELECT * FROM sys.tables where name = 'Branches')
BEGIN
		CREATE TABLE Branches
		(
			BranchId INT NOT NULL
			,Version_VersionId INT NOT NULL REFERENCES Versions(VersionId)
		)
END