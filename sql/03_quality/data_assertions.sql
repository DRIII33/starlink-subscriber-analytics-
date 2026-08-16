-- Description: Automated data quality assertions and auditing script for Google BigQuery.
-- Executes critical integrity checks across staging and analytical marts.

-- Assertion 1: Verify Zero Duplicate Primary Keys in dim_subscriber
SELECT 
  'Assertion_1_Duplicate_Subscribers' AS assertion_name,
  COUNT(subscriber_id) - COUNT(DISTINCT subscriber_id) AS failure_count
FROM `driiiportfolio.starlink_analytics.dim_subscriber`
HAVING failure_count > 0

UNION ALL

-- Assertion 2: Verify Bound Compliance on Telemetry Facts
SELECT 
  'Assertion_2_Telemetry_Bound_Violations' AS assertion_name,
  COUNT(1) AS failure_count
FROM `driiiportfolio.starlink_analytics.fct_telemetry_daily`
WHERE obstruction_rate < 0.0 OR obstruction_rate > 1.0
   OR ping_drop_rate < 0.0 OR ping_drop_rate > 1.0
   OR avg_latency_ms <= 0.0
HAVING failure_count > 0

UNION ALL

-- Assertion 3: Verify Orphan Records in Fact Telemetry
SELECT 
  'Assertion_3_Orphan_Telemetry_Records' AS assertion_name,
  COUNT(1) AS failure_count
FROM `driiiportfolio.starlink_analytics.fct_telemetry_daily` f
LEFT JOIN `driiiportfolio.starlink_analytics.dim_subscriber` d 
  ON f.subscriber_id = d.subscriber_id
WHERE d.subscriber_id IS NULL
HAVING failure_count > 0

UNION ALL

-- FIXED GAP 5 ASSERTION: Verify Zero Post-Churn Activity Logs
-- Ensures no telemetry logs exist after a customer's official cancellation date
SELECT
  'Assertion_4_Post_Churn_Activity_Violation' AS assertion_name,
  COUNT(1) AS failure_count
FROM `driiiportfolio.starlink_analytics.fct_telemetry_daily` f
INNER JOIN `driiiportfolio.starlink_analytics.dim_subscriber` d 
  ON f.subscriber_id = d.subscriber_id
WHERE d.is_active = 0 AND f.event_date > d.churn_date
HAVING failure_count > 0;
