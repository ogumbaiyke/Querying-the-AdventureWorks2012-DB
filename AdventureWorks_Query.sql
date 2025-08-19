-- Q1 Provide the 10 customers (fullname) by revenue, the country they shipped to, the cities and their revenue (orderqty * unitprice).

SELECT TOP 10
    p.FirstName + ' ' + p.LastName AS FullName,
    a.City,
    cr.Name AS Country,
    SUM(sod.OrderQty * sod.UnitPrice) AS Revenue
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
JOIN Person.Address a ON soh.ShipToAddressID = a.AddressID
JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
JOIN Person.CountryRegion cr ON sp.CountryRegionCode = cr.CountryRegionCode
GROUP BY p.FirstName, p.LastName, a.City, cr.Name
ORDER BY Revenue DESC;


-- Q2 Create 4 distinct Customer Segments using the total revenue. 

WITH CustomerRevenue AS (
    SELECT
        c.CustomerID,
        s.Name AS CompanyName,
        SUM(sod.OrderQty * sod.UnitPrice) AS TotalRevenue
    FROM Sales.SalesOrderHeader soh
    JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
    JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
    JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID
    WHERE s.Name IS NOT NULL
    GROUP BY c.CustomerID, s.Name
),
SegmentedRevenue AS (
    SELECT *,
        NTILE(4) OVER (ORDER BY TotalRevenue DESC) AS RevenueSegment
    FROM CustomerRevenue
)
SELECT 
    CustomerID,
    CompanyName,
    TotalRevenue,
    CASE RevenueSegment
        WHEN 1 THEN 'Platinum'
        WHEN 2 THEN 'Gold'
        WHEN 3 THEN 'Silver'
        WHEN 4 THEN 'Bronze'
    END AS Segment
FROM SegmentedRevenue
ORDER BY TotalRevenue DESC;



-- Q3. What products  with their respective categories did our customers buy on our last day of business?

WITH LastOrderDate AS (
    SELECT MAX(OrderDate) AS LastDay
    FROM Sales.SalesOrderHeader
)
SELECT
    soh.CustomerID,
    p.ProductID,
    p.Name AS ProductName,
    pc.Name AS CategoryName,
    soh.OrderDate
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
JOIN Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
JOIN Production.ProductCategory pc ON psc.ProductCategoryID = pc.ProductCategoryID
JOIN LastOrderDate lod ON soh.OrderDate = lod.LastDay
ORDER BY soh.CustomerID, p.ProductID;





-- Q4 Create a view called customersegment that shows the details (id, name, revenue) for customers – and their segments.

CREATE VIEW CustomerSegment AS
WITH CustomerRevenue AS (
    SELECT
        c.CustomerID,
        -- Use CompanyName for stores, or Full Name for individuals
        COALESCE(s.Name, p.FirstName + ' ' + p.LastName) AS CustomerName,
        SUM(sod.OrderQty * sod.UnitPrice) AS Revenue
    FROM Sales.SalesOrderHeader soh
    JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
    JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
    LEFT JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID
    LEFT JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
    GROUP BY c.CustomerID, s.Name, p.FirstName, p.LastName
),
SegmentedRevenue AS (
    SELECT *,
        NTILE(4) OVER (ORDER BY Revenue DESC) AS RevenueSegment
    FROM CustomerRevenue
)
SELECT
    CustomerID,
    CustomerName,
    Revenue,
    CASE RevenueSegment
        WHEN 1 THEN 'Platinum'
        WHEN 2 THEN 'Gold'
        WHEN 3 THEN 'Silver'
        WHEN 4 THEN 'Bronze'
    END AS Segment
FROM SegmentedRevenue;



--This shows the three top selling product (include productname) in each category (include categoryname) – by revenue?

WITH ProductRevenue AS (
    SELECT
        pc.Name AS CategoryName,
        p.Name AS ProductName,
        p.ProductID,
        SUM(sod.OrderQty * sod.UnitPrice) AS Revenue
    FROM Sales.SalesOrderDetail sod
    JOIN Production.Product p ON sod.ProductID = p.ProductID
    JOIN Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
    JOIN Production.ProductCategory pc ON psc.ProductCategoryID = pc.ProductCategoryID
    GROUP BY pc.Name, p.Name, p.ProductID
),
RankedProducts AS (
    SELECT *,
        RANK() OVER (PARTITION BY CategoryName ORDER BY Revenue DESC) AS ProductRank
    FROM ProductRevenue
)
SELECT
    CategoryName,
    ProductName,
    ProductID,
    Revenue
FROM RankedProducts
WHERE ProductRank <= 3
ORDER BY CategoryName, Revenue DESC;




