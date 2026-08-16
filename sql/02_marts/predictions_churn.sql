-- Target: driiiportfolio.starlink_analytics.predictions_churn
-- Description: Machine Learning analytical feature matrix tracking Jan-Mar 2026 performance signals against subsequent churn flags.

CREATE OR REPLACE TABLE `driiiportfolio.starlink_analytics.predictions_churn` AS
WITH aggregated_telemetry AS (
  SELECT 
    subscriber_id,
    ROUND(AVG(avg_latency_ms), 2) AS avg_latency_ms,
    ROUND(AVG(obstruction_rate), 4) AS avg_obstruction_rate,
    ROUND(AVG(ping_drop_rate), 4) AS avg_ping_drop_rate,
    ROUND(AVG(throughput_mbps), 2) AS avg_throughput_mbps,
    SUM(hardware_error_flag) AS total_hardware_errors,
    SUM(is_degraded_service) AS total_degraded_days
  FROM `driiiportfolio.starlink_analytics.fct_telemetry_daily`
  GROUP BY subscriber_id
)
SELECT 
  d.subscriber_id,
  d.region_code,
  d.plan_tier,
  d.monthly_price,
  d.tenure_days,
  
  -- Aggregated Technical Performance Features
  COALESCE(t.avg_latency_ms, 42.0) AS avg_latency_ms,
  COALESCE(t.avg_obstruction_rate, 0.0) AS avg_obstruction_rate,
  COALESCE(t.avg_ping_drop_rate, 0.0) AS avg_ping_drop_rate,
  COALESCE(t.avg_throughput_mbps, 115.0) AS avg_throughput_mbps,
  COALESCE(t.total_hardware_errors, 0) AS total_hardware_errors,
  COALESCE(t.total_degraded_days, 0) AS total_degraded_days,
  
  -- Target Variable: Churn Event happened specifically within our 90-day observation window
  CASE 
    WHEN d.churn_date BETWEEN DATE('2026-01-01') AND DATE('2026-03-31') THEN 1
    ELSE 0
  END AS is_churned_in_window
FROM `driiiportfolio.starlink_analytics.dim_subscriber` d
LEFT JOIN aggregated_telemetry t 
  ON d.subscriber_id = t.subscriber_id
WHERE d.churn_date IS NULL OR d.churn_date >= DATE('2026-01-01');
