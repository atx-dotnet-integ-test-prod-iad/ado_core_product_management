-- SQL Server CREATE TABLE for Products (for SQL Equivalency validation)
CREATE TABLE Products (
    ProductId INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500) NULL,
    Price DECIMAL(18, 2) NOT NULL,
    StockQuantity INT NOT NULL,
    CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
    ModifiedDate DATETIME NULL
);
