-- MySQL 8.0+ | Import CSV as table ott_subscriptions
-- Basic checks
SELECT COUNT(*) AS rows_count, COUNT(DISTINCT Customer_ID) AS unique_customers
FROM ott_subscriptions;

SELECT Customer_ID, COUNT(*) AS n
FROM ott_subscriptions GROUP BY Customer_ID HAVING COUNT(*) > 1;

-- KPIs
SELECT COUNT(DISTINCT Customer_ID) AS total_customers,
       COUNT(DISTINCT CASE WHEN Status='Active' THEN Customer_ID END) AS active_customers,
       COUNT(DISTINCT CASE WHEN Status='Cancelled' THEN Customer_ID END) AS churned_customers
FROM ott_subscriptions;

-- Plan-wise churn
SELECT Subscription_Plan, COUNT(*) AS customers,
       SUM(Status='Cancelled') AS churned,
       ROUND(100*SUM(Status='Cancelled')/COUNT(*),2) AS churn_rate_pct
FROM ott_subscriptions GROUP BY Subscription_Plan ORDER BY customers DESC;

-- New subscribers by month
SELECT DATE_FORMAT(Subscription_Date,'%Y-%m') AS signup_month,
       COUNT(DISTINCT Customer_ID) AS new_subscribers
FROM ott_subscriptions GROUP BY signup_month ORDER BY signup_month;

-- Cancellations by month
SELECT DATE_FORMAT(Cancellation_Date,'%Y-%m') AS cancellation_month,
       COUNT(*) AS cancellations
FROM ott_subscriptions
WHERE Cancellation_Date IS NOT NULL
GROUP BY cancellation_month ORDER BY cancellation_month;

-- Active MRR and ARPU at 2025-12-31
SELECT SUM(Monthly_Fee_INR) AS monthly_recurring_revenue_inr,
       ROUND(AVG(Monthly_Fee_INR),2) AS arpu_inr
FROM ott_subscriptions WHERE Status='Active';

-- Cohort retention at each month end
WITH RECURSIVE months AS (
  SELECT DATE('2025-01-01') AS month_start
  UNION ALL
  SELECT DATE_ADD(month_start, INTERVAL 1 MONTH)
  FROM months WHERE month_start < '2025-12-01'
),
cohorts AS (
  SELECT Customer_ID,
         DATE_SUB(DATE(Subscription_Date),
                  INTERVAL DAYOFMONTH(Subscription_Date)-1 DAY) AS cohort_month
  FROM ott_subscriptions
),
sizes AS (
  SELECT cohort_month, COUNT(*) AS cohort_size
  FROM cohorts GROUP BY cohort_month
),
retained AS (
  SELECT c.cohort_month,
         TIMESTAMPDIFF(MONTH,c.cohort_month,m.month_start) AS month_number,
         COUNT(DISTINCT c.Customer_ID) AS retained_customers
  FROM cohorts c
  JOIN months m ON m.month_start >= c.cohort_month
  JOIN ott_subscriptions s ON s.Customer_ID=c.Customer_ID
   AND s.Subscription_Date <= LAST_DAY(m.month_start)
   AND (s.Cancellation_Date IS NULL OR s.Cancellation_Date > LAST_DAY(m.month_start))
  GROUP BY c.cohort_month, month_number
)
SELECT r.cohort_month, r.month_number, z.cohort_size,
       r.retained_customers,
       ROUND(100*r.retained_customers/z.cohort_size,1) AS retention_rate_pct
FROM retained r JOIN sizes z ON z.cohort_month=r.cohort_month
ORDER BY r.cohort_month,r.month_number;

-- Churn by device/payment method
SELECT Device, COUNT(*) AS customers, SUM(Status='Cancelled') AS churned,
       ROUND(100*SUM(Status='Cancelled')/COUNT(*),2) AS churn_rate_pct
FROM ott_subscriptions GROUP BY Device ORDER BY churn_rate_pct DESC;

SELECT Payment_Method, COUNT(*) AS customers, SUM(Status='Cancelled') AS churned,
       ROUND(100*SUM(Status='Cancelled')/COUNT(*),2) AS churn_rate_pct
FROM ott_subscriptions GROUP BY Payment_Method ORDER BY churn_rate_pct DESC;
