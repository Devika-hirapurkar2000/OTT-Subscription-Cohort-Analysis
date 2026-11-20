OTT SUBSCRIPTION COHORT & RETENTION ANALYSIS
Beginner project pack | 1,000 synthetic customer records

FILES
- ott_subscriptions_1000.csv: source dataset (1,000 customers)
- ott_analysis_queries.sql: MySQL 8.0 analysis queries
- ott_analysis.py: Python cleaning, KPIs, cohort analysis and exports

DATA NOTES
- Synthetic practice data; not actual Netflix or another OTT company's data.
- One row represents one customer subscription.
- Observation date: 2025-12-31.
- Active means no cancellation on or before the observation date.
- Monthly fee is in Indian rupees (INR).
- Cohort retention is measured at each calendar month-end.

RUN ORDER
1. Import CSV into MySQL table named ott_subscriptions.
2. Run ott_analysis_queries.sql.
3. Install packages: pip install pandas numpy matplotlib
4. Keep CSV and Python file in the same folder; run python ott_analysis.py.
5. Import CSV into Power BI and follow the dashboard guide in the ChatGPT response.
