SELECT
  'null_subscriber_ids' AS check_name,
  COUNTIF(subscriber_id IS NULL) AS failed_rows
FROM `driiiportfolio.starlink_analytics.stg_subscribers`
UNION ALL
SELECT
  'duplicate_subscriber_ids' AS check_name,
  (
    SELECT COUNT(*)
    FROM
      (
        SELECT subscriber_id
        FROM `driiiportfolio.starlink_analytics.stg_subscribers`
        GROUP BY 1
        HAVING COUNT(*) > 1
      )
  ) AS failed_rows
FROM (SELECT 1)
UNION ALL
SELECT
  'invalid_regions' AS check_name,
  COUNTIF(region_code IS NULL OR TRIM(region_code) = '') AS failed_rows
FROM `driiiportfolio.starlink_analytics.stg_subscribers`
UNION ALL
SELECT
  'invalid_plans' AS check_name,
  COUNTIF(plan_tier IS NULL OR TRIM(plan_tier) = '') AS failed_rows
FROM `driiiportfolio.starlink_analytics.stg_subscribers`
UNION ALL
SELECT
  'future_signup_dates' AS check_name,
  COUNTIF(signup_date > CURRENT_DATE()) AS failed_rows
FROM `driiiportfolio.starlink_analytics.stg_subscribers`
UNION ALL
SELECT
  'invalid_tenure_dates' AS check_name,
  COUNTIF(churn_date IS NOT NULL AND churn_date < signup_date) AS failed_rows
FROM `driiiportfolio.starlink_analytics.stg_subscribers`;

