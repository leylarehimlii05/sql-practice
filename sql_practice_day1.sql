-- =====================================================
-- SQL Practice: Day 1
-- Database: SQL Server Express (T-SQL)
-- Tables: customers, orders
-- Topics: SELECT, aggregates, aliases, JOINs, GROUP BY, HAVING
-- =====================================================


-- =====================================================
-- 00. SETUP (run once only, running it again causes errors)
-- =====================================================

CREATE TABLE customers (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    city VARCHAR(100)
);

CREATE TABLE orders (
    id INT PRIMARY KEY,
    customer_id INT,          -- foreign key: links to customers.id
    order_date DATE,
    amount DECIMAL(10,2)
);

INSERT INTO customers (id, name, city) VALUES
(1, 'Aysel', 'Baku'),
(2, 'Elvin', 'Baku'),
(3, 'Nigar', 'Ganja'),
(4, 'Rauf', 'Sumqayit'),
(5, 'Leyla', 'Ganja'),
(6, 'Tural', 'Baku');

INSERT INTO orders (id, customer_id, order_date, amount) VALUES
(1, 1, '2026-01-10', 500),
(2, 1, '2026-02-15', 700),
(3, 2, '2026-01-20', 300),
(4, 3, '2026-02-05', 1200),
(5, 3, '2026-03-01', 400),
(6, 5, '2026-03-12', 250),
(7, 2, '2026-03-20', 900);

-- Check that the data was loaded
SELECT * FROM customers;
SELECT * FROM orders;


-- =====================================================
-- 01. SELECT, WHERE, ORDER BY
-- =====================================================

-- Which customers live in Baku?
-- WHERE filters rows before anything else is calculated.
SELECT name
FROM customers
WHERE city = 'Baku';                      -- Expected: Aysel, Elvin, Tural

-- Which orders are bigger than 500, largest first?
-- Note: > excludes 500 itself, use >= to include it.
SELECT *
FROM orders
WHERE amount > 500
ORDER BY amount DESC;                     -- Expected: 1200, 900, 700


-- =====================================================
-- 02. AGGREGATE FUNCTIONS (COUNT, SUM, AVG)
-- =====================================================

-- Overall order statistics for the whole table
SELECT COUNT(*) AS order_count,
       SUM(amount) AS total,
       AVG(amount) AS average
FROM orders;                              -- Expected: 7, 4250, 607.142857

-- Total of orders above 1000 (WHERE filters rows before SUM is applied)
SELECT SUM(amount) AS total
FROM orders
WHERE amount > 1000;                      -- Expected: 1200


-- =====================================================
-- 03. ALIASES
-- =====================================================

-- Column alias (AS): renames a column in the result only, not in the table
SELECT name AS customer_name, city AS customer_city
FROM customers;

-- Aggregates have no name by default, so always give them an alias
SELECT SUM(amount) AS total_sales
FROM orders;

-- Table alias: c is a short name for customers
SELECT c.name, c.city
FROM customers c;

-- Without table aliases, a column that exists in both tables (id) is ambiguous.
-- c.id tells SQL Server exactly which id we mean.
SELECT c.id, c.name, o.amount
FROM customers c
JOIN orders o ON c.id = o.customer_id;


-- =====================================================
-- 04. JOINS
-- =====================================================

-- INNER JOIN: only rows that match in BOTH tables
SELECT c.name, o.amount
FROM customers c
INNER JOIN orders o ON c.id = o.customer_id;          -- 7 rows (Rauf and Tural missing)

-- LEFT JOIN: all customers, NULL where no order exists
SELECT c.name, o.amount
FROM customers c
LEFT JOIN orders o ON c.id = o.customer_id;           -- 9 rows (Rauf and Tural with NULL)

-- RIGHT JOIN: all orders, plus matching customers
SELECT c.name, o.amount
FROM customers c
RIGHT JOIN orders o ON c.id = o.customer_id;          -- 7 rows (every order has a customer)

-- FULL OUTER JOIN: everything from both tables
SELECT c.name, o.amount
FROM customers c
FULL OUTER JOIN orders o ON c.id = o.customer_id;     -- 9 rows


-- =====================================================
-- 05. ANTI-JOIN AND ON vs WHERE
-- =====================================================

-- Customers who never placed an order.
-- LEFT JOIN keeps everyone, then IS NULL keeps only those with no match.
-- Use IS NULL, not = NULL.
SELECT c.name
FROM customers c
LEFT JOIN orders o ON c.id = o.customer_id
WHERE o.id IS NULL;                       -- Expected: Rauf, Tural

-- Condition in WHERE: filters AFTER the join, NULL rows are removed,
-- so the LEFT JOIN behaves like an INNER JOIN.
SELECT c.name, o.amount
FROM customers c
LEFT JOIN orders o ON c.id = o.customer_id
WHERE o.amount > 500;                     -- 3 rows

-- Condition in ON: filters the right table BEFORE the join,
-- so all customers stay in the result.
SELECT c.name, o.amount
FROM customers c
LEFT JOIN orders o ON c.id = o.customer_id AND o.amount > 500;   -- 6 rows


-- =====================================================
-- 06. GROUP BY AND HAVING
-- =====================================================

-- How many customers live in each city?
-- GROUP BY makes one group per city, COUNT(*) is calculated per group.
SELECT city, COUNT(*) AS customer_count
FROM customers
GROUP BY city;                            -- Baku 3, Ganja 2, Sumqayit 1

-- Which cities have more than one customer?
-- HAVING filters groups after grouping (WHERE cannot use aggregates).
SELECT city, COUNT(*) AS customer_count
FROM customers
GROUP BY city
HAVING COUNT(*) > 1;                      -- Baku 3, Ganja 2

-- Monthly sales
SELECT FORMAT(order_date, 'yyyy-MM') AS month, SUM(amount) AS total
FROM orders
GROUP BY FORMAT(order_date, 'yyyy-MM');   -- 2026-01: 800, 2026-02: 1900, 2026-03: 1550


-- =====================================================
-- 07. JOIN + GROUP BY
-- =====================================================

-- Total spending per customer (only customers with orders)
SELECT c.name, SUM(o.amount) AS total_spent
FROM customers c
JOIN orders o ON c.id = o.customer_id
GROUP BY c.name;                          -- Aysel 1200, Elvin 1200, Leyla 250, Nigar 1600

-- Customers who spent more than 1000 in total
SELECT c.name, SUM(o.amount) AS total_spent
FROM customers c
JOIN orders o ON c.id = o.customer_id
GROUP BY c.name
HAVING SUM(o.amount) > 1000;              -- Aysel, Elvin, Nigar

-- Number of orders per customer (customers without orders are excluded)
SELECT c.name, COUNT(o.id) AS order_count
FROM customers c
JOIN orders o ON c.id = o.customer_id
GROUP BY c.name;                          -- Aysel 2, Elvin 2, Leyla 1, Nigar 2

-- Number of orders per customer INCLUDING customers with 0 orders.
-- COUNT(o.id) ignores NULL, so Rauf and Tural show 0 (COUNT(*) would show 1).
SELECT c.name, COUNT(o.id) AS order_count
FROM customers c
LEFT JOIN orders o ON c.id = o.customer_id
GROUP BY c.name;

-- Total sales per city
SELECT c.city, SUM(o.amount) AS total_sales
FROM customers c
JOIN orders o ON c.id = o.customer_id
GROUP BY c.city;                          -- Baku 2400, Ganja 1850

-- Top 5 customers by spending (T-SQL uses TOP, not LIMIT)
SELECT TOP 5 c.name, SUM(o.amount) AS total_spent
FROM customers c
JOIN orders o ON c.id = o.customer_id
GROUP BY c.name
ORDER BY total_spent DESC;                -- Nigar 1600, Aysel 1200, Elvin 1200, Leyla 250


-- =====================================================
-- 08. GROUP BY RULE
-- Every column in SELECT must be in GROUP BY or inside an aggregate function.
-- =====================================================

-- This FAILS: c.name is not in GROUP BY and not inside an aggregate.
-- SELECT c.city, c.name, COUNT(*) AS customer_count
-- FROM customers c
-- GROUP BY c.city;

-- Fix A: add c.name to GROUP BY (groups become city + name pairs, 6 rows)
SELECT c.city, c.name, COUNT(*) AS customer_count
FROM customers c
GROUP BY c.city, c.name;

-- Fix B: remove c.name from SELECT (one row per city, 3 rows)
SELECT c.city, COUNT(*) AS customer_count
FROM customers c
GROUP BY c.city;


-- =====================================================
-- 09. LOGICAL EXECUTION ORDER (interview question)
-- FROM/JOIN -> WHERE -> GROUP BY -> HAVING -> SELECT -> ORDER BY
-- This is why a SELECT alias works in ORDER BY but not in WHERE.
-- =====================================================
