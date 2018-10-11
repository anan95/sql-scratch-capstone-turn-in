-- Q.1
SELECT
  *
FROM subscriptions
LIMIT 100;
-- Q.2
SELECT
  MIN(subscription_start) AS 'min_date',
  MAX(subscription_start) AS 'max_date'
FROM subscriptions;
-- Q.3
WITH months
AS (SELECT
  '2017-01-01' AS first_day,
  '2017-01-31' AS last_day
UNION
SELECT
  '2017-02-01' AS first_day,
  '2017-02-28' AS last_day
UNION
SELECT
  '2017-03-01' AS first_day,
  '2017-03-31' AS last_day),
-- Q.4
cross_join
AS (SELECT
  *
FROM subscriptions
CROSS JOIN months),
-- Q.5
status
AS (SELECT
  id,
  first_day AS 'month',
  CASE
    WHEN segment = 87 AND
      (subscription_start < first_day AND
      (subscription_end >= first_day OR
      subscription_end IS NULL)) THEN 1
    ELSE 0
  END AS 'is_active_87',
  CASE
    WHEN segment = 30 AND
      (subscription_start < first_day AND
      (subscription_end >= first_day OR
      subscription_end IS NULL)) THEN 1
    ELSE 0
  END AS 'is_active_30',
  -- Q.6
  CASE
    WHEN segment = 87 AND
      (subscription_end >= first_day AND
      (subscription_end <= last_day)) THEN 1
    ELSE 0
  END AS 'is_canceled_87',
  CASE
    WHEN segment = 30 AND
      (subscription_end >= first_day AND
      (subscription_end <= last_day)) THEN 1
    ELSE 0
  END AS 'is_canceled_30'
FROM cross_join),
-- Q.7
status_aggregate
AS (SELECT
  month,
  SUM(is_active_87) AS 'sum_active_87',
  SUM(is_active_30) AS 'sum_active_30',
  SUM(is_canceled_87) AS 'sum_canceled_87',
  SUM(is_canceled_30) AS 'sum_canceled_30'
FROM status
GROUP BY month)
-- Q.8
SELECT
  month,
  ROUND(1.0 * sum_canceled_87 / sum_active_87, 3) AS 'churn_rate_87',
  ROUND(1.0 * sum_canceled_30 / sum_active_30, 3) AS 'churn_rate_30',
  /* Add a third column to capture the overall churn rate */
  ROUND(1.0 * (sum_canceled_87 + sum_canceled_30) / (sum_active_87 + sum_active_30), 3) AS 'overall_churn'
FROM status_aggregate;
-- Q.9
/* Below is a rewrite of the previous code to support a large number of segments */ 
WITH months
AS (SELECT
  '2017-01-01' AS first_day,
  '2017-01-31' AS last_day
UNION
SELECT
  '2017-02-01' AS first_day,
  '2017-02-28' AS last_day
UNION
SELECT
  '2017-03-01' AS first_day,
  '2017-03-31' AS last_day),
cross_join
AS (SELECT
  *
FROM subscriptions
CROSS JOIN months),
status
-- Add segment to the SELECT statement
AS (SELECT
  segment,
  id,
  first_day AS 'month',
/* Remove the segment filters from the CASE statements */
  CASE
    WHEN
      subscription_start < first_day AND
      (subscription_end >= first_day OR
      subscription_end IS NULL) THEN 1
    ELSE 0
  END AS 'is_active',
  CASE
    WHEN
      subscription_end >= first_day AND
      subscription_end <= last_day THEN 1
    ELSE 0
  END AS 'is_canceled'
FROM cross_join),
status_aggregate
/* Add segment to the SELECT statement and remove the segment-specific SUMs */
AS (SELECT
  month,
  segment,
  SUM(is_active) AS 'sum_active',
  SUM(is_canceled) AS 'sum_canceled'
FROM status
GROUP BY month,
         segment)
/* Select segment and create a single function to calculate churn_rate */
SELECT
  month,
  segment,
  ROUND(1.0 * sum_canceled / sum_active, 3) AS 'churn_rate'
FROM status_aggregate;