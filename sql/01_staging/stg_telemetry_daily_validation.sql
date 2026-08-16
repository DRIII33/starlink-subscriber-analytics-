SELECT
  'obstruction_rate_out_of_range' AS check_name,
  COUNTIF(obstruction_rate < 0 OR obstruction_rate > 1) AS failed_rows
FROM `driiiportfolio.starlink_analytics.stg_telemetry_daily`
UNION ALL
SELECT
  'ping_drop_rate_out_of_range' AS check_name,
  COUNTIF(ping_drop_rate < 0 OR ping_drop_rate > 1) AS failed_rows
FROM `driiiportfolio.starlink_analytics.stg_telemetry_daily`
UNION ALL
SELECT
  'avg_latency_ms_not_greater_than_0' AS check_name,
  COUNTIF(avg_latency_ms <= 0) AS failed_rows
FROM `driiiportfolio.starlink_analytics.stg_telemetry_daily`
UNION ALL
SELECT
  'subscriber_id_is_null' AS check_name,
  COUNTIF(subscriber_id IS NULL) AS failed_rows
FROM `driiiportfolio.starlink_analytics.stg_telemetry_daily`
UNION ALL
SELECT
  'event_date_is_null' AS check_name, COUNTIF(event_date IS NULL) AS failed_rows
FROM `driiiportfolio.starlink_analytics.stg_telemetry_daily`;
