--create warehouse 
CREATE WAREHOUSE DE_WH -- compute the engine
WAREHOUSE_SIZE='XSMALL'
AUTO_SUSPEND=60
AUTO_RESUME=TRUE;

--use WAREHOUSE
USE WAREHOUSE DE_WAREHOUSE;

-- create database
CREATE DATABASE ECOMMERCE_DB;

USE DATABASE ECOMMERCE_DB;

--Create Schema
CREATE SCHEMA RAW; --Source Data
CREATE SCHEMA STAGING; --Clean Data
CREATE SCHEMA MART; --Reporting Layer
CREATE SCHEMA AUDIT; -- Monitoring

--Create RAW Table
CREATE TABLE RAW.TRANSACTIONS_RAW
(
USER_ID STRING,
PRODUCT_ID STRING,
CATEGORY STRING,
PRICE FLOAT,
DISCOUNT_PERCENT NUMBER,
FINAL_PRICE FLOAT,
PAYMENT_METHOD STRING,
PURCHASE_DATE STRING
);
--Rename the CSV headers before uploading
CREATE TABLE RAW.TRANSACTIONS_RAW
(
USER_ID STRING,
PRODUCT_ID STRING,
CATEGORY STRING,
PRICE NUMBER(10,2),
DISCOUNT_PERCENT NUMBER,
FINAL_PRICE NUMBER(10,2),
PAYMENT_METHOD STRING,
PURCHASE_DATE STRING
);
-- remove table
DROP TABLE RAW.TRANSACTIONS_RAW;

 --now create other
 CREATE TABLE RAW.TRANSACTIONS_RAW
(
"User_ID" STRING,
"Product_ID" STRING,
"Category" STRING,
"Price (Rs.)" FLOAT,
"Discount (%)" NUMBER,
"Final_Price(Rs.)" FLOAT,
"Payment_Method" STRING,
"Purchase_Date" STRING
);

--verify the csv load
SELECT *
FROM RAW.TRANSACTIONS_RAW
LIMIT 10;

--Data Profiling
--Understand data before cleaning.

--Check row count:
SELECT COUNT(*)
FROM RAW.TRANSACTIONS_RAW;

--Check categories:
SELECT DISTINCT "Category"
FROM RAW.TRANSACTIONS_RAW;

--Check payment methods:
SELECT DISTINCT "Payment_Method"
FROM RAW.TRANSACTIONS_RAW;

--check null
SELECT *
FROM RAW.TRANSACTIONS_RAW
WHERE "Category" IS NULL
   OR "Discount (%)" IS NULL
   OR "Final_Price(Rs.)" IS NULL
   OR "Payment_Method" IS NULL
   OR "Price (Rs.)" IS NULL
   OR "Product_ID" IS NULL
   OR "Purchase_Date" IS NULL
   OR "User_ID" IS NULL;

-- show column
SHOW COLUMNS IN TABLE RAW.TRANSACTIONS_RAW;
   
   --Data Cleaning
CREATE OR REPLACE TABLE STAGING.TRANSACTIONS_CLEAN AS --Creates a new table called TRANSACTIONS_CLEAN in the STAGING schema.
SELECT
    TRIM("User_ID") AS USER_ID,  --TRIM() → removes extra spaces.
    TRIM("Product_ID") AS PRODUCT_ID,
    UPPER(TRIM("Category")) AS CATEGORY, --UPPER() → converts text to uppercase for consistency.
    "Price (Rs.)" AS PRICE,
    "Discount (%)" AS DISCOUNT_PERCENT,
    "Final_Price(Rs.)" AS FINAL_PRICE,
    UPPER(TRIM("Payment_Method")) AS PAYMENT_METHOD,
    TO_DATE("Purchase_Date", 'DD-MM-YYYY') AS PURCHASE_DATE-- --TO_DATE() → converts text dates into proper date format.
FROM RAW.TRANSACTIONS_RAW;

--Data Validation
--Remove bad records.
--This query creates a new table containing only valid transaction records by removing rows with invalid prices, invalid discounts, or missing user and product IDs.

CREATE TABLE STAGING.TRANSACTIONS_VALID AS

SELECT *
FROM STAGING.TRANSACTIONS_CLEAN
WHERE

PRICE > 0
AND FINAL_PRICE > 0
AND DISCOUNT_PERCENT BETWEEN 0 AND 100
AND USER_ID IS NOT NULL
AND PRODUCT_ID IS NOT NULL;


--Deduplication
--remove duplicate
CREATE OR REPLACE TABLE STAGING.TRANSACTIONS_STG AS

SELECT *
FROM
(SELECT *,
ROW_NUMBER() OVER(   --Assigns a unique row number to each row.
PARTITION BY     --Finds records that have the same:User ID,Product ID,Purchase Date
USER_ID,
PRODUCT_ID,
PURCHASE_DATE
ORDER BY PURCHASE_DATE   --Determines the order of row numbering.
) RN
FROM STAGING.TRANSACTIONS_VALID
)
WHERE RN = 1;  --Keeps only the first record and removes the duplicate records.


--CDC 
--This query creates a Stream on the TRANSACTIONS_RAW table.
--A Stream tracks all changes made to the table, such as:
--A Stream tracks all changes made to the table, such as:New rows inserted,Existing rows updated,Rows deleted
--CDC (Change Data Capture) means capturing and tracking changes in data instead of processing the entire table every time.
 CREATE STREAM RAW.TRANSACTIONS_STREAM
ON TABLE RAW.TRANSACTIONS_RAW;

-- Create a Task:
--Runs every 30 minutes and loads new data automatically.
--No manual work needed.
CREATE TASK LOAD_TRANSACTION_TASK --Automates data loading.

WAREHOUSE=DE_WAREHOUSE

SCHEDULE='30 MINUTE'

AS
INSERT INTO STAGING.TRANSACTIONS_STG

SELECT
TRIM("User_ID"),
TRIM("Product_ID"),
UPPER(TRIM("Category")),
TRY_TO_NUMBER("Price (Rs.)"),
TRY_TO_NUMBER("Discount (%)"),
TRY_TO_NUMBER("Final_Price(Rs.)"),
UPPER(TRIM("Payment_Method")),
TO_DATE("Purchase_Date")

FROM RAW.TRANSACTIONS_STREAM; --Reads only the new changes from the streaM
--Every 30 minutes, this task automatically reads new transaction records from the stream, cleans the data, and loads it into the staging table.

--START
--This command activates the automated task, allowing it to run on schedule and load new transaction data automatically.

ALTER TASK LOAD_TRANSACTION_TASK RESUME;

--Create Dimension Tables
--A dimension table stores descriptive information such as products, categories, dates, or payment methods. It is created to reduce duplication, organize data, and make reporting and analytics easier and faster.

--DIM_USER
--This query creates a User Dimension table containing unique user IDs from the staging table for reporting and analytics.
CREATE TABLE MART.DIM_USER AS
SELECT DISTINCT
USER_ID
FROM STAGING.TRANSACTIONS_STG;
--Who purchased?

--DIM_PRODUCT

CREATE  TABLE MART.DIM_PRODUCT AS
SELECT DISTINCT
PRODUCT_ID,
CATEGORY
FROM STAGING.TRANSACTIONS_STG;
--What was purchased?
SELECT *
FROM MART.DIM_PRODUCT;

--DIM_PAYMENT
CREATE OR REPLACE TABLE MART.DIM_PAYMENT AS
SELECT DISTINCT
PAYMENT_METHOD
FROM STAGING.TRANSACTIONS_STG;
--How did customer pay?

--DIM_DATE
CREATE TABLE MART.DIM_DATE AS
SELECT DISTINCT
PURCHASE_DATE,
YEAR(PURCHASE_DATE) AS YEAR_NO,
MONTH(PURCHASE_DATE) AS MONTH_NO,
DAY(PURCHASE_DATE) AS DAY_NO

FROM STAGING.TRANSACTIONS_STG;
--When did purchase happen?

--Create FACT_Table
--Fact Table stores the main business transactions and numeric values such as:Price,Discount,Final

CREATE OR REPLACE TABLE MART.FACT_SALES AS
SELECT --Selects the columns to store in the fact table.
USER_ID,
PRODUCT_ID,
PAYMENT_METHOD,
PURCHASE_DATE,
PRICE,
DISCOUNT_PERCENT,
FINAL_PRICE

FROM STAGING.TRANSACTIONS_STG;
--Store business measures



--Step 15 — Validate Star Schema
--to verify or check
SELECT COUNT(*)
FROM MART.FACT_SALES;

SELECT COUNT(*)
FROM MART.DIM_PRODUCT;


--Create Revenue Mart
--REVENUE → Total sales amount per day
--Revenue Mart means a business-ready reporting table that stores summarized revenue information for analysis and dashboards.

CREATE TABLE MART.REVENUE_MART AS
SELECT
PURCHASE_DATE,
COUNT(*) TOTAL_ORDERS,
SUM(FINAL_PRICE) REVENUE
FROM MART.FACT_SALES
GROUP BY PURCHASE_DATE;

--verify
SELECT *
FROM MART.REVENUE_MART;

--Create Category Mart
CREATE OR REPLACE TABLE MART.CATEGORY_MART AS
SELECT
P.CATEGORY,
COUNT(*) TOTAL_ORDERS,
SUM(F.FINAL_PRICE) REVENUE
FROM MART.FACT_SALES F
JOIN MART.DIM_PRODUCT P
ON F.PRODUCT_ID=P.PRODUCT_ID
GROUP BY P.CATEGORY;

--verify
SELECT *
FROM MART.CATEGORY_MART;

--Create Payment Mart
CREATE OR REPLACE TABLE MART.PAYMENT_MART AS
SELECT
D.PAYMENT_METHOD,
COUNT(*) TOTAL_TRANSACTIONS,
SUM(F.FINAL_PRICE) REVENUE
FROM MART.FACT_SALES F
JOIN MART.DIM_PAYMENT D
ON F.PAYMENT_METHOD=D.PAYMENT_METHOD
GROUP BY D.PAYMENT_METHOD;

--Create Business KPI Queries
--KPI 1 Total Revenue
--Calculates the total sales revenue generated from all orders.
SELECT
SUM(FINAL_PRICE) AS TOTAL_REVENUE
FROM MART.FACT_SALES;

--KPI 2 Total Orders
--Counts the total number of orders placed.
SELECT
COUNT(*) AS TOTAL_ORDERS
FROM MART.FACT_SALES;

--KPI 3 Average Order Value
--Calculates the average amount spent per order.
SELECT
AVG(FINAL_PRICE) AS AVG_ORDER_VALUE
FROM MART.FACT_SALES;


--KPI 4 Top Category
--Shows product categories ranked from highest to lowest revenue.
SELECT *
FROM MART.CATEGORY_MART
ORDER BY REVENUE DESC;

--KPI 5 Revenue by Payment Method
--hows which payment methods generate the most revenue.
SELECT *
FROM MART.PAYMENT_MART
ORDER BY REVENUE DESC;


--SECURE VIEW
--Creates a secure dashboard view
--protects sensitive data and allows users to see only the authorized information without accessing the original table directly.
CREATE SECURE VIEW MART.VW_EXECUTIVE_DASHBOARD AS
SELECT
CATEGORY,
PAYMENT_METHOD,
COUNT(*) TOTAL_ORDERS,
SUM(FINAL_PRICE) REVENUE

FROM STAGING.TRANSACTIONS_STG

GROUP BY
CATEGORY,
PAYMENT_METHOD;
--verify
SELECT *
FROM MART.VW_EXECUTIVE_DASHBOARD;


--Dynamic Tables
--Instead of manually refreshing MART tables, Snowflake refreshes them automatically.

--Create Dynamic Revenue Table
CREATE OR REPLACE DYNAMIC TABLE MART.DT_MONTHLY_REVENUE
TARGET_LAG = '5 minutes' --Automatically refreshes the table so data is updated within 5 minutes of source changes.
WAREHOUSE = DE_WAREHOUSE

AS
SELECT

YEAR(PURCHASE_DATE) AS YEAR_NO,
MONTH(PURCHASE_DATE) AS MONTH_NO,
SUM(FINAL_PRICE) AS REVENUE,
COUNT(*) AS TOTAL_ORDERS

FROM MART.FACT_SALES

GROUP BY
YEAR_NO,
MONTH_NO;
--New Data Arrives,Dynamic Table Refreshes Automatically,Updated Revenue Report
SELECT *
FROM MART.DT_MONTHLY_REVENUE;

--Time Travel
--Time Travel (in Snowflake) to to recover tables if data is accidentally updated, deleted, or dropped.

--Test
--Check row count:
SELECT COUNT(*)
FROM STAGING.TRANSACTIONS_STG;

--Delete one row:
DELETE FROM STAGING.TRANSACTIONS_STG
WHERE USER_ID = '82abf471';

--Recover
SELECT *
FROM STAGING.TRANSACTIONS_STG
AT(OFFSET => -60);  --Show table as it existed 60 seconds ago


--ZERO COPY CLONE
--Zero Copy Clone in Snowflake means creating an exact copy of a database, schema, or table without physically copying the data

--Create Clone
CREATE TABLE STAGING.TRANSACTIONS_TEST --Creates a test table that is an exact copy of TRANSACTIONS_STG without physically copying the data.
CLONE STAGING.TRANSACTIONS_STG;

--Verify
SELECT COUNT(*)
FROM STAGING.TRANSACTIONS_TEST;

--Resource Monitor
--Control Snowflake costs 

--Create Monitor
CREATE RESOURCE MONITOR DE_PROJECT_MONITOR
WITH CREDIT_QUOTA = 10 --Sets a limit of 10 Snowflake credits.

FREQUENCY = MONTHLY  --Resets the credit limit every month.
START_TIMESTAMP = IMMEDIATELY  --Starts monitoring right away

TRIGGERS  
ON 80 PERCENT DO NOTIFY  --Sends a warning when 80% of the credits (8 out of 10) are used.
ON 100 PERCENT DO SUSPEND;  --Automatically stops warehouses when 100% of the credits (10 out of 10) are used.

--Attach Warehouse
--Links the warehouse to the resource monitor so Snowflake can track and control its credit usage.--
ALTER WAREHOUSE DE_WAREHOUSE
SET RESOURCE_MONITOR = DE_PROJECT_MONITOR;
--VERIFY
SHOW RESOURCE MONITORS;

--Power BI Dashboard

SELECT CURRENT_ACCOUNT();
SELECT CURRENT_ORGANIZATION_NAME(), CURRENT_ACCOUNT_NAME();
