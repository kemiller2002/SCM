IF NOT EXISTS(SELECT * FROM sys.tables where name = 'Products')
BEGIN
		CREATE TABLE Products
		(
			ProductId INT NOT NULL
			,Name VARCHAR(50)
		)
END