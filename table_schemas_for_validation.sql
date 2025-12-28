-- SQL Server Table Creation Scripts
-- MS SQL Table for Products
CREATE TABLE Products (
    ProductId INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(200) NOT NULL,
    Description NVARCHAR(MAX),
    Price DECIMAL(18,2) NOT NULL,
    StockQuantity INT NOT NULL,
    CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
    ModifiedDate DATETIME
);

-- MS SQL Table for ProductHistory
CREATE TABLE ProductHistory (
    HistoryId INT IDENTITY(1,1) PRIMARY KEY,
    ProductId INT NOT NULL,
    Action NVARCHAR(50) NOT NULL,
    OldPrice DECIMAL(18,2),
    NewPrice DECIMAL(18,2),
    OldStock INT,
    NewStock INT,
    ActionDate DATETIME NOT NULL
);

-- MS SQL Table for ProductStats
CREATE TABLE ProductStats (
    StatId INT PRIMARY KEY,
    TotalProducts INT NOT NULL DEFAULT 0,
    AveragePrice DECIMAL(18,2) NOT NULL DEFAULT 0,
    LastUpdated DATETIME NOT NULL DEFAULT GETDATE()
);

-- PostgreSQL Table Creation Scripts
-- PostgreSQL Table for Products
CREATE TABLE productmanagement_dbo.products (
    productid SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    price DECIMAL(18,2) NOT NULL,
    stockquantity INT NOT NULL,
    createddate TIMESTAMP NOT NULL DEFAULT NOW(),
    modifieddate TIMESTAMP
);

-- PostgreSQL Table for ProductHistory
CREATE TABLE productmanagement_dbo.producthistory (
    historyid SERIAL PRIMARY KEY,
    productid INT NOT NULL,
    action VARCHAR(50) NOT NULL,
    oldprice DECIMAL(18,2),
    newprice DECIMAL(18,2),
    oldstock INT,
    newstock INT,
    actiondate TIMESTAMP NOT NULL
);

-- PostgreSQL Table for ProductStats
CREATE TABLE productmanagement_dbo.productstats (
    statid INT PRIMARY KEY,
    totalproducts INT NOT NULL DEFAULT 0,
    averageprice DECIMAL(18,2) NOT NULL DEFAULT 0,
    lastupdated TIMESTAMP NOT NULL DEFAULT NOW()
);
