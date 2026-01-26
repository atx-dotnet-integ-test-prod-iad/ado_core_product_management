-- PostgreSQL Table Creation Script for Equivalency Testing

CREATE TABLE Products (
    ProductId SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Description VARCHAR(500) NULL,
    Price DECIMAL(18, 2) NOT NULL,
    StockQuantity INT NOT NULL,
    CategoryId INT NULL,
    SupplierId INT NULL,
    SKU VARCHAR(50) NULL,
    Weight DECIMAL(10, 2) NULL,
    Dimensions VARCHAR(50) NULL,
    IsDiscontinued BOOLEAN NOT NULL DEFAULT FALSE,
    ReorderLevel INT NOT NULL DEFAULT 10,
    CreatedDate TIMESTAMP NOT NULL DEFAULT NOW(),
    ModifiedDate TIMESTAMP NULL
);

CREATE TABLE ProductHistory (
    HistoryId SERIAL PRIMARY KEY,
    ProductId INT NOT NULL,
    Action VARCHAR(10) NOT NULL,
    OldPrice DECIMAL(18, 2) NULL,
    NewPrice DECIMAL(18, 2) NULL,
    OldStock INT NULL,
    NewStock INT NULL,
    ActionDate TIMESTAMP NOT NULL DEFAULT NOW(),
    ModifiedBy VARCHAR(100) NULL
);

CREATE TABLE ProductStats (
    StatId INT PRIMARY KEY DEFAULT 1,
    TotalProducts INT NOT NULL DEFAULT 0,
    AveragePrice DECIMAL(18, 2) NOT NULL DEFAULT 0,
    TotalStockValue DECIMAL(18, 2) NOT NULL DEFAULT 0,
    LowStockCount INT NOT NULL DEFAULT 0,
    DiscontinuedCount INT NOT NULL DEFAULT 0,
    LastUpdated TIMESTAMP NOT NULL DEFAULT NOW()
);
