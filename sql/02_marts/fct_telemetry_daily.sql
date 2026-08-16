-- Target: driiiportfolio.starlink_analytics.fct_telemetry_daily
-- Description: Production fact table partitioned by event_date and clustered by subscriber_id for optimal query execution.

CREATE OR REPLACE TABLE `driiiportfolio.starlink_analytics.fct_telemetry_daily`
PARTITION BY event_date
CLUSTER BY subscriber_id, region_code AS
SELECT 
  t.subscriber_id,
  t.event_date,
  t.region_code,
  t.avg_latency_ms,
  t.obstruction_rate,
  t.ping_drop_rate,
  t.throughput_mbps,
  t.hardware_error_flag,
  t.is_degraded_service,
  
  -- Window functions for 3-day rolling analytics
  ROUND(AVG(t.obstruction_rate) OVER(
    PARTITION BY t.subscriber_id 
    ORDER BY t.event_date 
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ), 4) AS rolling_3d_obstruction_rate,
  
  ROUND(AVG(t.avg_latency_ms) OVER(
    PARTITION BY t.subscriber_id 
    ORDER BY t.event_date 
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ), 2) AS rolling_3d_latency_ms
FROM `driiiportfolio.starlink_analytics.stg_telemetry_daily` t;

