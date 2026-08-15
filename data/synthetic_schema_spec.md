# Synthetic Data Schema Specification & Data Generation Rules

---

**Business Analyst:** Daniel Rodriguez III
**Date:** 15 August 2026

---

## 1. Executive Summary
This document specifies the statistical distributions, seed parameters, boundary constraints, and structural definitions used to generate synthetic datasets for the Starlink Customer Success Analytics Architecture. All synthetic data is grounded in empirical public benchmarks (FCC broadband reports, Ookla speed testing, and satellite industry filings) to ensure realistic business and operational behavior.

## 2. Global Seed & Sampling Constraints
* **Random Seed:** `42` (Enforced across Python, NumPy, Scikit-Learn, and Synthetic Generators).
* **Population Size ($N$):** 100,000 distinct subscriber entities.
* **Temporal Horizon:** 90 consecutive days of daily aggregated telemetry records ($9,000,000$ total telemetry rows).
* **Target GCP Project ID:** `driiiportfolio`
* **Target Dataset:** `starlink_analytics`

## 3. Entity Distributions & Field Specs

### 3.1 Subscriber Dimension (`raw_subscribers`)
* `subscriber_id`: UUID4 string format.
* `signup_date`: Uniform random sampling between `2024-01-01` and `2025-12-31`.
* `region_code`: Multinomial distribution:
  * `US` (45%)
  * `EEA` (25%)
  * `LATAM` (20%)
  * `APAC` (10%)
* `plan_tier`: Conditional distribution based on `region_code`:
  * `US / EEA`: Standard ($110/mo, 85%), Priority ($250/mo, 15%).
  * `LATAM / APAC`: Standard ($50/mo, 60%), Regional Lite ($20/mo, 40%).
* `is_active`: Binary flag (0 = Churned, 1 = Active). Baseline monthly churn rate forced to 2.5%.
* `churn_date`: Populated if `is_active = 0`; NULL if `is_active = 1`.

### 3.2 Telemetry Fact (`raw_telemetry_daily`)
* `avg_latency_ms`: Normal distribution $\mathcal{N}(\mu=42.0, \sigma=12.5)$, clipped to $[1.0, 500.0]$.
* `obstruction_rate`: Log-normal distribution $\text{Lognormal}(\mu=-3.2, \sigma=0.85)$, clipped to $[0.0, 1.0]$. Forced spike trigger: Accounts with `obstruction_rate > 0.035` have a 2.50x higher hazard multiplier for churn.
* `ping_drop_rate`: Beta distribution $\text{Beta}(\alpha=1.2, \beta=35.0)$, clipped to $[0.0, 1.0]$.
* `throughput_mbps`: Normal distribution $\mathcal{N}(\mu=115.0, \sigma=35.0)$, clipped to $[5.0, 500.0]$.
* `hardware_error_flag`: Bernoulli distribution with $p = 0.02$. Correlated with `ping_drop_rate > 0.08`.

## 4. Quality Assertion Rules
1. `subscriber_id` must be non-null and strictly unique in dimensional tables.
2. `obstruction_rate` must lie within $[0.0, 1.0]$.
3. `avg_latency_ms` must be positive (> 0.0).
4. Referential integrity: Every `subscriber_id` in `raw_telemetry_daily` must exist in `raw_subscribers`.
