     -- Complex SQL Queries:


 -- 1. Get detailed discounted price info for a specific product
--    Retrieves the original price and discounted price (using a user-defined function) for a product with ProductID = 1
SELECT 
    p.ProductID,
    p.ProductName,
    p.Price AS OriginalPrice,
    dbo.GetDiscountedPrice(p.ProductID, 10) AS DiscountedPrice
FROM Product p
WHERE p.ProductID = 1;
-- ---------------------------------------

-- 2. Get full name and contact info of a customer
--    Joins Customer and User tables and uses a scalar function to get the full name for CustomerID = 5
SELECT 
    c.CustomerID,
    dbo.GetCustomerFullName(c.CustomerID) AS FullName,
    u.Email,
    u.PhoneNo
FROM Customer c
JOIN [User] u ON c.UserID = u.UserID;

-- ---------------------------------------

-- 3. Get all orders within a date range including total prices
--    Uses a table-valued function to get orders and total prices between '2023-01-01' and '2023-12-31'
--    Joins orders with customers to display full details ordered by OrderDate descending
SELECT 
    o.OrderID,
    c.CustomerID,
    dbo.GetCustomerFullName(c.CustomerID) AS FullName,
    o.OrderDate,
    ot.TotalPrice
FROM dbo.GetOrdersWithTotalPrice('2024-01-01', '2024-12-31') AS ot
JOIN [Order] AS o ON ot.OrderID = o.OrderID
JOIN Customer AS c ON o.CustomerID = c.CustomerID
ORDER BY o.OrderDate DESC;

-- ---------------------------------------

-- 4. This query finds the top 10 customers who have placed more than 3 orders.
SELECT TOP 10
    c.CustomerID,
    c.FirstName + ' ' + c.LastName AS CustomerName,  -- Concatenate first and last names
    COUNT(o.OrderID) AS TotalOrders,                 -- Total number of orders placed by the customer
    AVG(ot.OrderTotal) AS AvgOrderValue              -- Average value of the customer's orders
FROM Customer c
INNER JOIN [Order] o ON c.CustomerID = o.CustomerID -- Join customers with their orders
INNER JOIN (
    -- Subquery: Calculate total price for each order by summing quantity * price of each item
    SELECT 
        oi.OrderID,
        SUM(oi.Quantity * pv.Price) AS OrderTotal
    FROM OrderItem oi
    INNER JOIN ProductVariant pv ON oi.VariantID = pv.VariantID -- Join order items with product variants to get prices
    GROUP BY oi.OrderID -- Group by order to get total per order
) AS ot ON o.OrderID = ot.OrderID -- Join the precomputed order totals back to the orders
GROUP BY c.CustomerID, c.FirstName, c.LastName -- Group by customer to aggregate order counts and averages
HAVING COUNT(o.OrderID) > 3                     -- Only include customers with more than 3 orders
ORDER BY AvgOrderValue DESC;                      -- Sort by average order value descending
              -- Order results by average order value descending (highest first)


-- 5. List all products priced above average, including total quantity sold (may be zero)
--    Retrieves products with prices higher than the average product price
--    Shows total quantity sold for each product (including products with no sales)
SELECT 
    p.ProductID,
    p.ProductName,
    p.Price,
    COALESCE(SUM(oi.Quantity), 0) AS TotalQuantitySold
FROM Product p
LEFT JOIN ProductVariant pv ON p.ProductID = pv.ProductID
LEFT JOIN OrderItem oi ON pv.VariantID = oi.VariantID
WHERE p.Price > (
    SELECT AVG(Price) FROM Product
)
GROUP BY p.ProductID, p.ProductName, p.Price
ORDER BY TotalQuantitySold DESC;
-- ---------------------------------------

-- 6. Latest order date for each customer (including customers with no orders)
--    Shows the most recent order date for each customer
--    Includes customers who have never placed an order (may show NULL for LatestOrderDate)
SELECT 
    c.CustomerID,
    c.FirstName + ' ' + c.LastName AS CustomerName,
    MAX(o.OrderDate) AS LatestOrderDate
FROM Customer c
RIGHT JOIN [Order] o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName
ORDER BY LatestOrderDate DESC;
-- ---------------------------------------

-- 7. Products with total quantity ordered over 100
--    Lists products where the sum of quantities ordered exceeds 100 units
--    Uses a subquery to calculate total quantity per product and filters by total quantity > 100
SELECT 
    ProductID,
    ProductName,
    TotalQuantity
FROM (
    SELECT 
        p.ProductID,
        p.ProductName,
        SUM(oi.Quantity) AS TotalQuantity
    FROM Product p
    INNER JOIN ProductVariant pv ON p.ProductID = pv.ProductID
    INNER JOIN OrderItem oi ON pv.VariantID = oi.VariantID
    GROUP BY p.ProductID, p.ProductName
) AS ProductSales
WHERE TotalQuantity > 100
ORDER BY TotalQuantity DESC;
-- ---------------------------------------

-- 8. Top 5 customers with most orders and count of distinct products ordered
--    Finds top 5 customers by total number of orders placed
--    Also counts distinct product variants each customer ordered
SELECT TOP 5
    c.CustomerID,
    c.FirstName + ' ' + c.LastName AS CustomerName,
    COUNT(o.OrderID) AS TotalOrders,
    (
        SELECT COUNT(DISTINCT oi.VariantID)
        FROM [Order] o2
        INNER JOIN OrderItem oi ON o2.OrderID = oi.OrderID
        WHERE o2.CustomerID = c.CustomerID
    ) AS DistinctProductsOrdered
FROM Customer c
INNER JOIN [Order] o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName
ORDER BY TotalOrders DESC;
-- ---------------------------------------




                                                                --3 user-defined functions 




-- 1) Function to calculate discounted price for a product
CREATE FUNCTION dbo.GetDiscountedPrice
(
    @ProductID INT,
    @DiscountPercent DECIMAL(5,2)
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @OriginalPrice DECIMAL(10,2);
    DECLARE @DiscountedPrice DECIMAL(10,2);

    SELECT @OriginalPrice = Price
    FROM Product
    WHERE ProductID = @ProductID;

    IF @OriginalPrice IS NULL
        RETURN NULL;  -- Product not found

    SET @DiscountedPrice = @OriginalPrice * (1 - (@DiscountPercent / 100));

    RETURN ROUND(@DiscountedPrice, 2);
END;
GO


-- 2) Function to get full customer name formatted as "LastName, FirstName"

CREATE FUNCTION dbo.GetCustomerFullName
(
    @CustomerID INT
)
RETURNS NVARCHAR(100)
AS
BEGIN
    DECLARE @FullName NVARCHAR(100);

    SELECT @FullName = LastName + ', ' + FirstName
    FROM Customer
    WHERE CustomerID = @CustomerID;

    RETURN @FullName;
END;
GO

-- 3) Table-valued function to get all orders placed within a date range with total prices
-- FIXED FUNCTION: renamed TotalOrderPrice to TotalPrice
CREATE FUNCTION dbo.GetOrdersWithTotalPrice
(
    @StartDate DATE,
    @EndDate DATE
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        o.OrderID,
        o.OrderDate,
        c.CustomerID,
        c.FirstName + ' ' + c.LastName AS CustomerName,
        u.Email,
        ISNULL(p.PaymentMethod, 'N/A') AS PaymentMethod,
        ISNULL(p.PaymentStatus, 'N/A') AS PaymentStatus,


        -- Renamed and ensuring NULL-safe calculation

        ISNULL((
            SELECT SUM(ISNULL(oi.Quantity, 0) * ISNULL(pv.Price, 0))
            FROM [OrderItem] oi
            INNER JOIN [ProductVariant] pv ON oi.VariantID = pv.VariantID
            WHERE oi.OrderID = o.OrderID
        ), 0) AS TotalPrice
    FROM [Order] o
    INNER JOIN [Customer] c ON o.CustomerID = c.CustomerID
    INNER JOIN [User] u ON c.UserID = u.UserID
    LEFT JOIN [Payment] p ON o.OrderID = p.OrderID
    WHERE o.OrderDate BETWEEN @StartDate AND @EndDate
);
GO



-- ===============================
-- TEST SCRIPT FOR COMPLEX QUERIES
-- ===============================

-- 1. Get detailed discounted price info for ProductID = 1
PRINT '--- Query 1: Discounted price info for ProductID = 1 ---';
SELECT 
    p.ProductID,
    p.ProductName,
    p.Price AS OriginalPrice,
    dbo.GetDiscountedPrice(p.ProductID, 10) AS DiscountedPrice
FROM Product p
WHERE p.ProductID = 1;
PRINT ' ';

-- ---------------------------------------

-- 2. Get full name and contact info of CustomerID = 5
SELECT 
    c.CustomerID,
    dbo.GetCustomerFullName(c.CustomerID) AS FullName,
    u.Email,
    u.PhoneNo
FROM Customer c
LEFT JOIN [User] u ON c.UserID = u.UserID
WHERE c.CustomerID = 2;


-- ---------------------------------------

-- 3. Get all orders between 2023-01-01 and 2023-12-31 including total prices
PRINT '--- Query 3: Orders with total prices (2023) ---';
SELECT 
    o.OrderID,
    c.CustomerID,
    dbo.GetCustomerFullName(c.CustomerID) AS FullName,
    o.OrderDate,
    ot.TotalPrice
FROM dbo.GetOrdersWithTotalPrice('2023-01-01', '2023-12-31') AS ot
JOIN [Order] AS o ON ot.OrderID = o.OrderID
JOIN Customer AS c ON o.CustomerID = c.CustomerID
ORDER BY o.OrderDate DESC;
PRINT ' ';

-- ---------------------------------------

-- 4. Top 10 customers who placed more than 3 orders with average order value
PRINT '--- Query 4: Top 10 customers with >3 orders, average order value ---';
SELECT TOP 10
    c.CustomerID,
    c.FirstName + ' ' + c.LastName AS CustomerName,
    COUNT(o.OrderID) AS TotalOrders,
    AVG(ot.OrderTotal) AS AvgOrderValue
FROM Customer c
INNER JOIN [Order] o ON c.CustomerID = o.CustomerID
INNER JOIN (
    SELECT 
        oi.OrderID,
        SUM(oi.Quantity * pv.Price) AS OrderTotal
    FROM OrderItem oi
    INNER JOIN ProductVariant pv ON oi.VariantID = pv.VariantID
    GROUP BY oi.OrderID
) AS ot ON o.OrderID = ot.OrderID
GROUP BY c.CustomerID, c.FirstName, c.LastName
HAVING COUNT(o.OrderID) > 3
ORDER BY AvgOrderValue DESC;
PRINT ' ';

-- ---------------------------------------

-- 5. Products priced above average, with total quantity sold (including zero sales)
PRINT '--- Query 5: Products priced above average with total quantity sold ---';
SELECT 
    p.ProductID,
    p.ProductName,
    p.Price,
    COALESCE(SUM(oi.Quantity), 0) AS TotalQuantitySold
FROM Product p
LEFT JOIN ProductVariant pv ON p.ProductID = pv.ProductID
LEFT JOIN OrderItem oi ON pv.VariantID = oi.VariantID
WHERE p.Price > (
    SELECT AVG(Price) FROM Product
)
GROUP BY p.ProductID, p.ProductName, p.Price
ORDER BY TotalQuantitySold DESC;
PRINT ' ';

-- ---------------------------------------

-- 6. Latest order date for each customer (including customers with no orders)
PRINT '--- Query 6: Latest order date for each customer ---';
SELECT 
    c.CustomerID,
    c.FirstName + ' ' + c.LastName AS CustomerName,
    MAX(o.OrderDate) AS LatestOrderDate
FROM Customer c
LEFT JOIN [Order] o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName
ORDER BY LatestOrderDate DESC;
PRINT ' ';

-- ---------------------------------------

-- 7. Products with total quantity ordered over 100
PRINT '--- Query 7: Products with total quantity ordered > 100 ---';
SELECT 
    ProductID,
    ProductName,
    TotalQuantity
FROM (
    SELECT 
        p.ProductID,
        p.ProductName,
        SUM(oi.Quantity) AS TotalQuantity
    FROM Product p
    INNER JOIN ProductVariant pv ON p.ProductID = pv.ProductID
    INNER JOIN OrderItem oi ON pv.VariantID = oi.VariantID
    GROUP BY p.ProductID, p.ProductName
) AS ProductSales
WHERE TotalQuantity > 100
ORDER BY TotalQuantity DESC;
PRINT ' ';

-- ---------------------------------------

-- 8. Top 5 customers with most orders and count of distinct products ordered
PRINT '--- Query 8: Top 5 customers by orders and distinct products ordered ---';
SELECT TOP 5
    c.CustomerID,
    c.FirstName + ' ' + c.LastName AS CustomerName,
    COUNT(o.OrderID) AS TotalOrders,
    (
        SELECT COUNT(DISTINCT oi.VariantID)
        FROM [Order] o2
        INNER JOIN OrderItem oi ON o2.OrderID = oi.OrderID
        WHERE o2.CustomerID = c.CustomerID
    ) AS DistinctProductsOrdered
FROM Customer c
INNER JOIN [Order] o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName
ORDER BY TotalOrders DESC;
PRINT ' ';







-- =============================================
-- FULL TEST SCRIPT FOR USER-DEFINED FUNCTIONS
-- =============================================

-- 1) Test dbo.GetDiscountedPrice function
PRINT '--- Testing dbo.GetDiscountedPrice ---';

-- Check original price for ProductID = 1
SELECT ProductID, ProductName, Price
FROM Product
WHERE ProductID = 1;

-- Calculate discounted price with 15% discount
SELECT dbo.GetDiscountedPrice(1, 15.0) AS DiscountedPrice_15Percent;

-- Calculate discounted price for non-existent product (should return NULL)
SELECT dbo.GetDiscountedPrice(9999, 10.0) AS DiscountedPrice_NonExistentProduct;

PRINT ' ';


-- 2) Test dbo.GetCustomerFullName function
PRINT '--- Testing dbo.GetCustomerFullName ---';

-- Get full name for CustomerID = 1
SELECT CustomerID, FirstName, LastName
FROM Customer
WHERE CustomerID = 1;

-- Get full name using the function
SELECT dbo.GetCustomerFullName(1) AS FullName;

-- Test with invalid CustomerID (should return NULL or empty)
SELECT dbo.GetCustomerFullName(9999) AS FullName_InvalidCustomer;

PRINT ' ';


-- 3) Test dbo.GetOrdersWithTotalPrice table-valued function
PRINT '--- Testing dbo.GetOrdersWithTotalPrice ---';

-- Show all orders between Jan 1, 2025 and Dec 31, 2025 with total prices
SELECT * FROM dbo.GetOrdersWithTotalPrice('2025-01-01', '2025-12-31');

-- Test with a date range that has no orders (should return empty set)
SELECT * FROM dbo.GetOrdersWithTotalPrice('1900-01-01', '1900-01-31');

PRINT ' ';

