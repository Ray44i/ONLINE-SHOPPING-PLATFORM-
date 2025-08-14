-- 1. Trigger Test: Automatically update 'UpdatedAt' column in the Order table

-- Check the current UpdatedAt value for the given OrderID
SELECT OrderID, UpdatedAt FROM [Order] WHERE OrderID = 1;

-- Perform an update on the Order to trigger the UpdatedAt change
UPDATE [Order]
SET TotalAmount = TotalAmount + 50
WHERE OrderID = 1;

-- Re-check the UpdatedAt value to verify it has been updated
SELECT OrderID, UpdatedAt FROM [Order] WHERE OrderID = 1;




-- 2. Trigger Test: Decrease stock quantity in ProductVariant after inserting into OrderItem

-- Check current stock quantity for the given VariantID before the insert
SELECT VariantID, StockQuantity FROM ProductVariant WHERE VariantID = 2;

-- Insert a new OrderItem record, which should trigger a decrease in stock
INSERT INTO [OrderItem] (OrderID, VariantID, Quantity)
VALUES (1, 2, 2);  -- Assumes VariantID = 2 exists

-- Check stock quantity again to confirm it decreased by the ordered quantity
SELECT VariantID, StockQuantity FROM ProductVariant WHERE VariantID = 2;




-- 3. Trigger Test: Insert a notification when an Order status is updated

-- Check existing notifications for the user linked to CustomerID = 1
SELECT * FROM [Notification] 
WHERE UserID = (SELECT UserID FROM Customer WHERE CustomerID = 1);

-- Update the OrderStatus to trigger a notification
UPDATE [Order]
SET OrderStatus = 'Shipped'
WHERE OrderID = 1;

-- Check notifications again to confirm a new one was inserted
SELECT * FROM [Notification] 
WHERE UserID = (SELECT UserID FROM Customer WHERE CustomerID = 1);




-- 4. Trigger Test: Update 'UpdatedAt' column in OrderItem on record update

-- Check UpdatedAt before updating the OrderItem
SELECT OrderItemID, UpdatedAt FROM [OrderItem] WHERE OrderItemID = 1;

-- Perform an update that triggers the UpdatedAt field
UPDATE [OrderItem]
SET Quantity = Quantity + 1
WHERE OrderItemID = 1;

-- Check if UpdatedAt has changed as expected
SELECT OrderItemID, UpdatedAt FROM [OrderItem] WHERE OrderItemID = 1;




-- 5. Trigger Test: Update 'UpdatedAt' field when User record is modified

-- Check current UpdatedAt value for the User before update
SELECT UserID, UpdatedAt FROM [User] WHERE UserID = 1;

-- Update the User's email to trigger an UpdatedAt update
UPDATE [User]
SET Email = 'newemail@example.com'
WHERE UserID = 1;

-- Confirm UpdatedAt has been modified
SELECT UserID, UpdatedAt FROM [User] WHERE UserID = 1;









--------------------------------------------------------------------------------
-- Test user Procedure
--------------------------------------------------------------------------------
-- Declare a variable to hold the new UserID
DECLARE @NewUserID INT;

-- Test inserting a new user
EXEC dbo.InsertUser
    @PhoneNo = '555-123-4567',
    @PasswordHash = 'rabi**********',
    @Email = 'rabimadrk@gmail.com',
    @NewUserID = @NewUserID OUTPUT;

-- Show the new UserID returned by the procedure
SELECT @NewUserID AS NewUserID;

-- Verify the inserted user record by selecting it from the User table
SELECT * FROM [User] WHERE UserID = @NewUserID;


--------------------------------------------------------------------------------
-- Test InsertProduct Procedure
--------------------------------------------------------------------------------
-- Check before insert
SELECT * FROM Product WHERE ProductName = 'Test Product';

-- Declare variable for output ProductID
DECLARE @NewProductID INT;

-- Insert product and get new ProductID
EXEC dbo.InsertProduct 
    @ProductName = 'Test Product', 
    @CategoryID = 1, 
    @BrandID = 1, 
    @Description = 'This is a test product.', 
    @Price = 19.99, 
    @NewProductID = @NewProductID OUTPUT;

-- Show the new ProductID
SELECT @NewProductID AS NewProductID;

-- Check the new product inserted
SELECT * FROM Product WHERE ProductID = @NewProductID;


--------------------------------------------------------------------------------
-- Test InsertOrder Procedure
--------------------------------------------------------------------------------

PRINT 'Before inserting new order for CustomerID = 1';

SELECT * FROM [Order] WHERE CustomerID = 1;

DECLARE @NewOrderID INT;

PRINT 'Inserting new order...';

EXEC dbo.InsertOrder 
    @CustomerID = 1,
    @OrderDate = '2025-05-30',
    @DeliveryDate = '2025-06-10',
    @TotalAmount = 150.00,
    @OrderStatus = 'Pending',
    @NewOrderID = @NewOrderID OUTPUT;

PRINT 'After insert, new OrderID:';
SELECT @NewOrderID AS NewOrderID;

SELECT * FROM [Order] WHERE OrderID = @NewOrderID;

PRINT '--- Testing dbo.GetTotalSales ---';

SELECT
    ProductID,
    ProductName,
    Price AS UnitPrice,
    dbo.GetTotalSales(ProductID) AS TotalSalesRevenue
FROM Product
WHERE ProductID = 1;

SELECT dbo.GetTotalSales(9999) AS TotalSales_NonExistentProduct;

PRINT ' ';



-- =============================================
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

-- ============================================= 
-- 3) Test dbo.GetOrdersWithTotalPrice table-valued function 
PRINT '--- Testing dbo.GetOrdersWithTotalPrice ---';

-- Show all orders between Jan 1, 2024 and Dec 31, 2024 with total prices 
SELECT * 
FROM dbo.GetOrdersWithTotalPrice('2024-01-01', '2024-12-31');

-- Test with a date range that has no orders (should return empty set)
SELECT * 
FROM dbo.GetOrdersWithTotalPrice('1900-01-01', '1900-01-31');

PRINT ' ';
