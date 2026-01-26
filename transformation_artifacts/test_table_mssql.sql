-- MS SQL Server Table Creation Script for Equivalency Testing

CREATE TABLE Products (
    ProductId INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500) NULL,
    Price DECIMAL(18, 2) NOT NULL,
    StockQuantity INT NOT NULL,
    CategoryId INT NULL,
    SupplierId INT NULL,
    SKU NVARCHAR(50) NULL,
    Weight DECIMAL(10, 2) NULL,
    Dimensions NVARCHAR(50) NULL,
    IsDiscontinued BIT NOT NULL DEFAULT 0,
    ReorderLevel INT NOT NULL DEFAULT 10,
    CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
    ModifiedDate DATETIME NULL
);

CREATE TABLE ProductHistory (
    HistoryId INT IDENTITY(1,1) PRIMARY KEY,
    ProductId INT NOT NULL,
    Action VARCHAR(10) NOT NULL,
    OldPrice DECIMAL(18, 2) NULL,
    NewPrice DECIMAL(18, 2) NULL,
    OldStock INT NULL,
    NewStock INT NULL,
    ActionDate DATETIME NOT NULL DEFAULT GETDATE(),
    ModifiedBy NVARCHAR(100) NULL
);

CREATE TABLE ProductStats (
    StatId INT PRIMARY KEY DEFAULT 1,
    TotalProducts INT NOT NULL DEFAULT 0,
    AveragePrice DECIMAL(18, 2) NOT NULL DEFAULT 0,
    TotalStockValue DECIMAL(18, 2) NOT NULL DEFAULT 0,
    LowStockCount INT NOT NULL DEFAULT 0,
    DiscontinuedCount INT NOT NULL DEFAULT 0,
    LastUpdated DATETIME NOT NULL DEFAULT GETDATE()
);
