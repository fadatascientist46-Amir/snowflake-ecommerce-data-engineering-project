# E-Commerce Data Engineering Project – Snowflake

##  Project Overview

This is an end-to-end **E-Commerce Data Engineering project built with Snowflake**.

The project takes raw transaction data, cleans and validates it, builds a **Star Schema**, creates business reporting marts, and displays the results in an interactive **Streamlit dashboard**.

The project also demonstrates Snowflake features such as:

* Streams
* Tasks
* Dynamic Tables
* Time Travel
* Zero-Copy Cloning
* Secure Views
* Resource Monitors
* Snowpark
* Streamlit

---

##  Data Pipeline

```text
CSV Transaction Data
        ↓
RAW Schema
        ↓
Data Profiling
        ↓
STAGING Schema
        ↓
Data Cleaning & Validation
        ↓
Deduplication
        ↓
FACT & DIMENSION Tables
        ↓
MART Schema
        ↓
Business KPIs
        ↓
Streamlit Dashboard
```

---

##  Snowflake Architecture

The project uses four schemas:

### RAW

Stores the original source transaction data.

### STAGING

Contains cleaned, validated, and deduplicated data.

### MART

Contains the final analytical tables used for reporting.

### AUDIT

Reserved for monitoring and audit-related information.

---

##  Data Model

The project uses a **Star Schema**.

### Fact Table

`MART.FACT_SALES`

Contains business transaction measures:

* User ID
* Product ID
* Payment Method
* Purchase Date
* Price
* Discount
* Final Price

### Dimension Tables

* `DIM_USER` → Customer information
* `DIM_PRODUCT` → Product and category information
* `DIM_PAYMENT` → Payment methods
* `DIM_DATE` → Date information

---

## Data Engineering Process

### 1. Data Profiling

The raw data is analyzed to check:

* Row count
* Categories
* Payment methods
* NULL values
* Column structure

### 2. Data Cleaning

The project performs:

* Removing extra spaces
* Converting categories to uppercase
* Converting payment methods to uppercase
* Converting string dates into DATE format
* Converting numeric values to proper data types

### 3. Data Validation

Invalid records are removed using rules such as:

```text
Price > 0
Final Price > 0
Discount between 0 and 100
User ID is not NULL
Product ID is not NULL
```

### 4. Deduplication

`ROW_NUMBER()` is used to identify duplicate transactions and keep only one valid record.

---

##  CDC with Snowflake Streams

A Snowflake **Stream** is created on the raw transaction table.

It tracks changes such as:

* New records
* Updated records
* Deleted records

This allows the pipeline to process new changes instead of processing the entire table every time.

---

##  Automated Processing with Tasks

A Snowflake **Task** is used to automatically process new transaction data.

The task is scheduled to run every **30 minutes**.

```text
New Data
   ↓
Stream
   ↓
Snowflake Task
   ↓
Clean & Transform
   ↓
Staging Table
```

---

## Reporting Marts

The project creates reporting tables including:

### Revenue Mart

Shows:

* Total orders
* Revenue
* Revenue by purchase date

### Category Mart

Shows:

* Category
* Total orders
* Revenue

### Payment Mart

Shows:

* Payment method
* Total transactions
* Revenue

---

## Business KPIs

The project calculates:

* **Total Revenue**
* **Total Orders**
* **Average Order Value**
* **Revenue by Category**
* **Revenue by Payment Method**
* **Monthly Revenue**

---

##  Secure View

A Snowflake **Secure View** is created for executive reporting.

`VW_EXECUTIVE_DASHBOARD`

It provides aggregated business information without directly exposing the underlying transaction table.

---

##  Dynamic Table

A Snowflake **Dynamic Table** is used for monthly revenue reporting.

`DT_MONTHLY_REVENUE`

It automatically refreshes based on source data changes.

Target lag:

```text
5 minutes
```

---

##  Time Travel

Snowflake **Time Travel** is demonstrated to access previous versions of the data.

Example use case:

```text
Accidental DELETE
       ↓
Time Travel
       ↓
View Previous Data
```

This helps recover or investigate accidentally changed data.

---

##  Zero-Copy Clone

The project uses Snowflake **Zero-Copy Cloning** to create a test copy of the staging table without physically duplicating the existing data.

Example:

```text
TRANSACTIONS_STG
       ↓
Zero-Copy Clone
       ↓
TRANSACTIONS_TEST
```

---

##  Resource Monitoring

A Snowflake **Resource Monitor** is configured to control project costs.

Example configuration:

* Monthly credit quota: 10 credits
* 80% usage → Notification
* 100% usage → Warehouse suspension

---

##  Streamlit Dashboard

The project includes an interactive **Streamlit dashboard** running inside Snowflake.

The dashboard displays:

### KPI Cards

* Total Revenue
* Total Orders
* Average Order Value

### Charts

* Revenue by Category
* Revenue by Payment Method
* Monthly Revenue Trend

### Data Table

* Sales transactions

The dashboard uses **Snowpark** to query Snowflake data.

---

##  Technologies Used

| Technology        | Purpose                           |
| ----------------- | --------------------------------- |
| Snowflake         | Cloud Data Warehouse              |
| SQL               | Data transformation and analytics |
| Snowflake Streams | Change Data Capture               |
| Snowflake Tasks   | Automation                        |
| Dynamic Tables    | Automatic data refresh            |
| Time Travel       | Data recovery                     |
| Zero-Copy Clone   | Test environments                 |
| Secure Views      | Controlled reporting              |
| Streamlit         | Dashboard                         |
| Snowpark          | Snowflake-Python integration      |
| Pandas            | Dashboard data processing         |
| GitHub            | Project documentation             |

---

##  Project Structure

```text
snowflake-ecommerce-project/
│
├── README.md
│
├── sql/
│   ├── database_setup.sql
│   ├── data_profiling.sql
│   ├── data_cleaning.sql
│   ├── star_schema.sql
│   ├── streams_tasks.sql
│   ├── reporting_marts.sql
│   └── snowflake_features.sql
│
├── streamlit/
│   └── app.py
│
└── data/
    └── transactions.csv
```

---

##  Key Learning Outcomes

Through this project, I practiced:

* Building a Snowflake data warehouse
* Designing RAW, STAGING, and MART layers
* Data cleaning and validation
* Deduplication
* Star Schema design
* Fact and Dimension tables
* Change Data Capture
* Pipeline automation
* Business KPI development
* Snowflake Dynamic Tables
* Snowflake Time Travel
* Zero-Copy Cloning
* Secure Views
* Cost monitoring
* Building a Streamlit analytics dashboard

---

##  Project Goal

The main goal of this project is to demonstrate an **end-to-end data engineering workflow in Snowflake**, from raw e-commerce transaction data to a business-ready analytics dashboard.

---

##  Author

**Farhan Aamir**

Data Engineering / Data Science

#
