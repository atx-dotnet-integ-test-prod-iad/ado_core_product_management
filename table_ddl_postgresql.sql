-- ============================================================================
-- PostgreSQL TABLE CREATION DDL FOR EQUIVALENCY VALIDATION
-- Used by sql-equivalency___validate_sql_equivalence tool
-- Schema: productmanagement_dbo (as converted by DMS)
-- ============================================================================

-- Products Table (PostgreSQL)
CREATE TABLE productmanagement_dbo.products(
    productid SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    price DECIMAL(18, 2) NOT NULL,
    stockquantity INTEGER NOT NULL,
    categoryid INTEGER,
    supplierid INTEGER,
    sku VARCHAR(50),
    weight DECIMAL(10, 2),
    dimensions VARCHAR(50),
    isdiscontinued BOOLEAN NOT NULL DEFAULT FALSE,
    reorderlevel INTEGER NOT NULL DEFAULT 10,
    createddate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modifieddate TIMESTAMP
);

-- ProductHistory Table (PostgreSQL)
CREATE TABLE productmanagement_dbo.producthistory(
    historyid SERIAL PRIMARY KEY,
    productid INTEGER NOT NULL,
    action VARCHAR(10) NOT NULL,
    oldprice DECIMAL(18, 2),
    newprice DECIMAL(18, 2),
    oldstock INTEGER,
    newstock INTEGER,
    actiondate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modifiedby VARCHAR(100)
);

-- ProductStats Table (PostgreSQL)
CREATE TABLE productmanagement_dbo.productstats(
    statid INTEGER PRIMARY KEY DEFAULT 1,
    totalproducts INTEGER NOT NULL DEFAULT 0,
    averageprice DECIMAL(18, 2) NOT NULL DEFAULT 0,
    totalstockvalue DECIMAL(18, 2) NOT NULL DEFAULT 0,
    lowstockcount INTEGER NOT NULL DEFAULT 0,
    discontinuedcount INTEGER NOT NULL DEFAULT 0,
    lastupdated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
