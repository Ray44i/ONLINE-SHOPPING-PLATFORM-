# 🛒 Online Shopping System (SQL Project)

This project is a comprehensive relational database model for an **Online Shopping System**, designed to simulate real-world e-commerce operations. It includes data definition (DDL), data manipulation (DML), and advanced SQL features such as user-defined functions, stored procedures, and triggers.

## 📌 Features

- Complete schema for entities like Users, Customers, Vendors, Products, Orders, Reviews, and more
- Sample data inserts for testing and demonstration
- Scalar and table-valued functions for key business logic
- Stored procedures for common actions (e.g., placing orders)
- Triggers for stock management, logging, and automated updates
- Complex SQL queries with test scripts for business insights

## 🧱 Database Structure

The project includes the following main components:

- **Users & Roles:** `User`, `Admin`, `Customer`, `Vendor`
- **Products:** `Product`, `ProductVariant`, `ProductImage`, `Category`, `Brand`, `Discount`
- **Orders:** `Order`, `OrderItem`, `Wishlist`, `Review`, `Rating`
- **Support & Communication:** `SupportTicket`, `Message`, `Notification`
- **Logistics:** `Address`

The relationships are modeled using primary and foreign keys to ensure referential integrity. Subtyping is applied for roles such as Customer and Vendor, derived from the base User entity.

## 🔧 Functionality Overview

### ✅ Phase 1 – Database Design
- Defined 20+ interrelated tables
- Handled 1:N, M:N relationships with join tables
- Used meaningful constraints, data types, and consistent naming

### ✅ Phase 2 – Data Population & Basic Queries
- Inserted sample records into each table
- Performed SELECT, JOIN, and aggregate queries for verification

### ✅ Phase 3 – Advanced SQL Operations
- **Functions:** 
  - `GetDiscountedPrice(productId, percent)` – returns price after discount
  - `GetCustomerFullName(customerId)` – returns full name of a customer
  - `GetOrdersWithTotalPrice(startDate, endDate)` – returns orders and their total prices
- **Procedures:** 
  - `PlaceOrder(customerId, ...)` – adds a new order and items
- **Triggers:**
  - Automatically update stock
  - Log order placements
  - Set order timestamps

### ✅ Complex Queries (Examples):
- Customers with highest average order value
- Products sold in quantities over 100
- Orders placed within a specific year
- Customers with most distinct products ordered

> 📸 Screenshots included to demonstrate each function and query with output results.

## 💡 How to Use

1. **Import schema.sql** to your SQL environment (MySQL/PostgreSQL/SQL Server).
2. **Run insert_data.sql** to populate the database.
3. **Execute functions and procedures** in `functions_procedures.sql`.
4. **Run `test_script.sql`** to view query outputs.

## 📁 File Structure



## 🛠️ Tools Used

- SQL Server / MySQL / PostgreSQL
- SQL Management Tool (SSMS, DBeaver, or pgAdmin)
- Optional: ERD tools (e.g., dbdiagram.io, Draw.io)



## 📌 Notes

- Designed to reflect realistic e-commerce operations
- Prioritizes data consistency, normalization, and modularity
- Fully testable and customizable for extensions (e.g., returns, coupons, delivery tracking)

---



