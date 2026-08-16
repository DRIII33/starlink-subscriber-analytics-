-- Target: driiiportfolio.starlink_analytics.stg_telemetry_daily
-- Description: Sanitized staging view for high-frequency telemetry logs with assertion bounds.

CREATE OR REPLACE VIEW `driiiportfolio.starlink_analytics.stg_telemetry_daily` AS
SELECT 
  TRIM(subscriber_id) AS subscriber_id,
  CAST(event_date AS DATE) AS event_date,
  UPPER(TRIM(region_code)) AS region_code,
  
  -- Apply data hygiene and bound enforcement
  CASE 
    WHEN avg_latency_ms < 1.0 THEN 1.0
    WHEN avg_latency_ms > 2000.0 THEN 2000.0
    ELSE ROUND(avg_latency_ms, 2)
  END AS avg_latency_ms,
  
  CASE 
    WHEN obstruction_rate < 0.0 THEN 0.0
    WHEN obstruction_rate > 1.0 THEN 1.0
    ELSE ROUND(obstruction_rate, 4)
  END AS obstruction_rate,
  
  CASE 
    WHEN ping_drop_rate < 0.0 THEN 0.0
    WHEN ping_drop_rate > 1.0 THEN 1.0
    ELSE ROUND(ping_drop_rate, 4)
  END AS ping_drop_rate,
  
  GREATEST(ROUND(throughput_mbps, 2), 0.0) AS throughput_mbps,
  IFNULL(CAST(hardware_error_flag AS INT64), 0) AS hardware_error_flag,
  
  -- Flag severe technical degradation (Corresponds with our 7-day pre-churn injection anomalies)
  CASE 
    WHEN obstruction_rate > 0.035 OR ping_drop_rate > 0.05 OR hardware_error_flag = 1 
    THEN 1 ELSE 0 
  END AS is_degraded_service
FROM `driiiportfolio.starlink_analytics.raw_telemetry_daily`
WHERE subscriber_id IS NOT NULL 
  AND event_date IS NOT NULL;

