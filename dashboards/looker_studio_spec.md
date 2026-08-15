# Looker Studio Executive Dashboard Specification

## 1. Overview
This specification details the layout, data sources, calculated fields, and interactive filtering options for the 4-page executive Looker Studio dashboard connected to BigQuery project `driiiportfolio`.

## 2. Data Sources & Direct Connectors
1. `driiiportfolio.starlink_analytics.dim_subscriber`
2. `driiiportfolio.starlink_analytics.fct_telemetry_daily`
3. `driiiportfolio.starlink_analytics.predictions_churn`

## 3. Page Layout & Component Specifications

### Page 1: Executive Summary & ARR Scorecard
* **Target Audience:** C-Suite, VP Customer Success
* **Top KPI Scorecards:**
  * **Total ARR:** `SUM(monthly_price * 12)` | Format: $ USD
  * **Active Subscribers:** `COUNT(DISTINCT IF(is_active = 1, subscriber_id, NULL))`
  * **Monthly Voluntary Churn Rate:** `COUNT(DISTINCT IF(is_active = 0, subscriber_id, NULL)) / COUNT(DISTINCT subscriber_id)` | Format: %
  * **Average ARPU:** `AVG(monthly_price)` | Format: $ USD
* **Visuals:**
  * **Regional Subscribers Breakdown:** Stacked Bar Chart (`region_code` vs. `plan_tier`).
  * **Monthly Retention Cohort Heatmap:** Matrix (`signup_date` aggregated by Month vs. `tenure_cohort`).

### Page 2: Telemetry & Survival Analytics
* **Target Audience:** Operations, Technical Customer Success Leads
* **Top KPI Scorecards:**
  * **Severe Obstruction Rate Count:** `COUNT(DISTINCT IF(rolling_3d_obstruction_rate > 0.035, subscriber_id, NULL))`
  * **Average Network Latency:** `AVG(avg_latency_ms)` | Target: < 45 ms
* **Visuals:**
  * **Obstruction vs. Churn Hazard Scatter Plot:** X-Axis = `rolling_3d_obstruction_rate`, Y-Axis = `churn_probability`, Color = `region_code`.
  * **Survival Distribution Chart:** Kaplan-Meier survival curves segmented by Market Category (Developed vs. Emerging).

### Page 3: Financial Yield & Downsell Analytics
* **Target Audience:** Commercial Pricing & Revenue Operations
* **Top KPI Scorecards:**
  * **Retained Downsell Revenue:** `SUM(IF(plan_tier = 'Regional Lite', monthly_price * 12, 0))`
  * **Dunning Mitigation Capture:** `COUNT(IF(risk_decile <= 2 AND plan_tier = 'Regional Lite', subscriber_id, NULL))`
* **Visuals:**
  * **Downsell Conversion Funnel:** Stages: High-Risk Flagged -> Dunning Failure -> Regional Lite Offer -> Converted/Saved.
  * **Yield Comparison Table:** `region_code` x `plan_tier` x `monthly_price` x `Retained_LTV`.

### Page 4: Predictive Risk & Scenario Forecasting
* **Target Audience:** Executive Strategy & Financial Planning
* **Visuals:**
  * **Prophet 24-Month Forecast Chart:** Line chart with confidence intervals displaying Baseline, Upside, and Downside subscriber projections.
  * **Top-Decile Risk Table:** List of top 1,000 highest-risk subscribers sorted by `churn_probability` descending with hardware obstruction indicators.
