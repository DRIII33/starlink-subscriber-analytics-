-- Target: driiiportfolio.starlink_analytics.stg_subscribers
-- Description: Cleaned and deduplicated staging view for subscriber entities.

CREATE OR REPLACE VIEW `driiiportfolio.starlink_analytics.stg_subscribers` AS
WITH raw_dedup AS (
  SELECT 
    TRIM(subscriber_id) AS subscriber_id,
    CAST(signup_date AS DATE) AS signup_date,
    UPPER(TRIM(region_code)) AS region_code,
    CASE 
      WHEN UPPER(TRIM(plan_tier)) IN ('STANDARD', 'PRIORITY', 'REGIONAL LITE') 
      THEN UPPER(TRIM(plan_tier))
      ELSE 'STANDARD'
    END AS plan_tier,
    CAST(monthly_price AS NUMERIC) AS monthly_price,
    CAST(is_active AS INT64) AS is_active,
    CAST(churn_date AS DATE) AS churn_date,
    ROW_NUMBER() OVER (
      PARTITION BY subscriber_id 
      ORDER BY signup_date DESC, is_active ASC
    ) AS row_num
  FROM `driiiportfolio.starlink_analytics.raw_subscribers`
  WHERE subscriber_id IS NOT NULL AND subscriber_id != ''
)
SELECT 
  subscriber_id,
  signup_date,
  region_code,
  plan_tier,
  monthly_price,
  is_active,
  churn_date,
  CASE 
    WHEN churn_date IS NOT NULL THEN DATE_DIFF(churn_date, signup_date, DAY)
    ELSE DATE_DIFF(CURRENT_DATE(), signup_date, DAY)
  END AS tenure_days
FROM raw_dedup
WHERE row_num = 1;
