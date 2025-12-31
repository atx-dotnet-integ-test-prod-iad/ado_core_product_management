-- TABLE SCHEMAS FOR SQL EQUIVALENCY VALIDATION
-- Microsoft SQL Server to PostgreSQL Migration

-- ========================================================================================================
-- SQL SERVER TABLE SCHEMAS
-- ========================================================================================================

-- SQL Server Products Table
CREATE TABLE Products (
    ProductId INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500),
    Price DECIMAL(18,2) NOT NULL,
    StockQuantity INT NOT NULL DEFAULT 0,
    CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
    ModifiedDate DATETIME
);

-- SQL Server ProductHistory Table
CREATE TABLE ProductHistory (
    HistoryId INT PRIMARY KEY IDENTITY(1,1),
    ProductId INT NOT NULL,
    Action NVARCHAR(50) NOT NULL,
    OldPrice DECIMAL(18,2),
    NewPrice DECIMAL(18,2),
    OldStock INT,
    NewStock INT,
    ActionDate DATETIME NOT NULL
);

-- SQL Server ProductStats Table
CREATE TABLE ProductStats (
    StatId INT PRIMARY KEY,
    TotalProducts INT NOT NULL DEFAULT 0,
    AveragePrice DECIMAL(18,2) NOT NULL DEFAULT 0,
    LastUpdated DATETIME NOT NULL
);

-- ========================================================================================================
-- POSTGRESQL TABLE SCHEMAS
-- ========================================================================================================

-- PostgreSQL Products Table
CREATE TABLE productmanagement_dbo.products (
    productid SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    price NUMERIC(18,2) NOT NULL,
    stockquantity INTEGER NOT NULL DEFAULT 0,
    createddate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modifieddate TIMESTAMP
);

-- PostgreSQL ProductHistory Table
CREATE TABLE productmanagement_dbo.producthistory (
    historyid SERIAL PRIMARY KEY,
    productid INTEGER NOT NULL,
    action VARCHAR(50) NOT NULL,
    oldprice NUMERIC(18,2),
    newprice NUMERIC(18,2),
    oldstock INTEGER,
    newstock INTEGER,
    actiondate TIMESTAMP NOT NULL
);

-- PostgreSQL ProductStats Table
CREATE TABLE productmanagement_dbo.productstats (
    statid INTEGER PRIMARY KEY,
    totalproducts INTEGER NOT NULL DEFAULT 0,
    averageprice NUMERIC(18,2) NOT NULL DEFAULT 0,
    lastupdated TIMESTAMP NOT NULL
);
