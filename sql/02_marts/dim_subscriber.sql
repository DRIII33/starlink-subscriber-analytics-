-- Target: driiiportfolio.starlink_analytics.dim_subscriber
-- Description: Production dimensional table clustered by region and tier for BI optimization.

CREATE OR REPLACE TABLE `driiiportfolio.starlink_analytics.dim_subscriber`
CLUSTER BY region_code, plan_tier AS
SELECT 
  s.subscriber_id,
  s.signup_date,
  s.region_code,
  s.plan_tier,
  s.monthly_price,
  s.is_active,
  s.churn_date,
  s.tenure_days,
  
  -- Business Logic Attributes
  CASE 
    WHEN s.tenure_days <= 90 THEN '0-3 Months'
    WHEN s.tenure_days <= 180 THEN '3-6 Months'
    WHEN s.tenure_days <= 365 THEN '6-12 Months'
    ELSE '12+ Months'
  END AS tenure_cohort,
  
  CASE 
    WHEN s.region_code IN ('US', 'EEA') THEN 'Developed Market'
    ELSE 'Emerging Market'
  END AS market_category,
  
  -- Calculate expected baseline Customer Lifetime Value (LTV)
  ROUND(s.monthly_price * (s.tenure_days / 30.4375), 2) AS realized_revenue_to_date
FROM `driiiportfolio.starlink_analytics.stg_subscribers` s;
