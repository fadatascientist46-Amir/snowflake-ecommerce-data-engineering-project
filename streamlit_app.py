import streamlit as st
import pandas as pd
from snowflake.snowpark.context import get_active_session

# --------------------------------------------------
# PAGE TITLE
# --------------------------------------------------

st.set_page_config(
    page_title="E-Commerce Analytics Dashboard",
    layout="wide"
)

st.title(" E-Commerce Analytics Dashboard")

# --------------------------------------------------
# SNOWFLAKE SESSION
# --------------------------------------------------

session = get_active_session()

# --------------------------------------------------
# KPI QUERY
# --------------------------------------------------

kpi_query = """
SELECT
    SUM(FINAL_PRICE) AS TOTAL_REVENUE,
    COUNT(*) AS TOTAL_ORDERS,
    AVG(FINAL_PRICE) AS AVG_ORDER_VALUE
FROM ECOMMERCE_DB.MART.FACT_SALES
"""

kpi_df = session.sql(kpi_query).to_pandas()

# --------------------------------------------------
# KPI CARDS
# --------------------------------------------------

st.subheader("Business KPIs")

col1, col2, col3 = st.columns(3)

col1.metric(
    "Total Revenue",
    f"Rs. {round(float(kpi_df['TOTAL_REVENUE'][0]),2)}"
)

col2.metric(
    "Total Orders",
    int(kpi_df['TOTAL_ORDERS'][0])
)

col3.metric(
    "Average Order Value",
    f"Rs. {round(float(kpi_df['AVG_ORDER_VALUE'][0]),2)}"
)

st.divider()

# --------------------------------------------------
# CATEGORY ANALYSIS
# --------------------------------------------------

st.subheader("Revenue by Category")

category_df = session.sql("""
SELECT *
FROM ECOMMERCE_DB.MART.CATEGORY_MART
""").to_pandas()

st.bar_chart(
    category_df,
    x="CATEGORY",
    y="REVENUE"
)

st.divider()

# --------------------------------------------------
# PAYMENT ANALYSIS
# --------------------------------------------------

st.subheader("Revenue by Payment Method")

payment_df = session.sql("""
SELECT *
FROM ECOMMERCE_DB.MART.PAYMENT_MART
""").to_pandas()

st.bar_chart(
    payment_df,
    x="PAYMENT_METHOD",
    y="REVENUE"
)

st.divider()

# --------------------------------------------------
# MONTHLY REVENUE TREND
# --------------------------------------------------

st.subheader("Monthly Revenue Trend")

trend_df = session.sql("""
SELECT *
FROM ECOMMERCE_DB.MART.DT_MONTHLY_REVENUE
""").to_pandas()

st.line_chart(
    trend_df,
    x="MONTH_NO",
    y="REVENUE"
)

st.divider()

# --------------------------------------------------
# FACT TABLE DATA
# --------------------------------------------------

st.subheader("Sales Transactions")

sales_df = session.sql("""
SELECT *
FROM ECOMMERCE_DB.MART.FACT_SALES
LIMIT 100
""").to_pandas()

st.dataframe(
    sales_df,
    use_container_width=True
)

# --------------------------------------------------
# PROJECT FOOTER
# --------------------------------------------------

st.success("End-to-End Snowflake Data Engineering Project Completed Successfully")