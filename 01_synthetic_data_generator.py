import numpy as np
import pandas as pd
import uuid
import sys
from datetime import datetime, timedelta
from google.colab import auth
from google.cloud import bigquery
import pandas_gbq

# Authenticate GCP Session
auth.authenticate_user()
project_id = 'driiiportfolio'
dataset_id = 'starlink_analytics'
client = bigquery.Client(project=project_id)

# Global Configuration
np.random.seed(42)
NUM_SUBSCRIBERS = 100000
NUM_DAYS = 90

# FIXED: Explicit Cutoff Dates to eliminate CURRENT_DATE() variability bugs
TELEMETRY_START = datetime(2026, 1, 1)
ANALYTICAL_CUTOFF = datetime(2026, 3, 31) # Day 90
PRE_LIGHT_HISTORICAL_START = datetime(2024, 1, 1)

print("Generating subscriber dimension...")
subscriber_ids = [str(uuid.uuid4()) for _ in range(NUM_SUBSCRIBERS)]
regions = np.random.choice(['US', 'EEA', 'LATAM', 'APAC'], size=NUM_SUBSCRIBERS, p=[0.45, 0.25, 0.20, 0.10])

plan_tiers = []
monthly_prices = []
for r in regions:
    if r in ['US', 'EEA']:
        tier = np.random.choice(['Standard', 'Priority'], p=[0.85, 0.15])
        price = 110.0 if tier == 'Standard' else 250.0
    else:
        tier = np.random.choice(['Standard', 'Regional Lite'], p=[0.60, 0.40])
        price = 50.0 if tier == 'Standard' else 20.0
    plan_tiers.append(tier)
    monthly_prices.append(price)

# Distribute user signups across historical timeline up to the start of telemetry
delta_days = (TELEMETRY_START - PRE_LIGHT_HISTORICAL_START).days
signup_dates = [PRE_LIGHT_HISTORICAL_START + timedelta(days=int(np.random.randint(0, delta_days))) for _ in range(NUM_SUBSCRIBERS)]

# FIXED: Aligning churn strictly to the 2.5% baseline monthly spec
monthly_churn_rate = 0.025
daily_churn_rate = 1 - (1 - monthly_churn_rate) ** (1/30.41)

is_active = []
churn_dates = []

for signup in signup_dates:
    total_possible_days = (ANALYTICAL_CUTOFF - signup).days
    
    # Determine if user churns based on geometric daily distribution
    if np.random.rand() < (1 - (1 - daily_churn_rate) ** total_possible_days):
        random_life_days = np.random.geometric(p=daily_churn_rate)
        churn_dt = signup + timedelta(days=int(random_life_days))
        
        if churn_dt <= ANALYTICAL_CUTOFF:
            is_active.append(0)
            churn_dates.append(churn_dt.strftime('%Y-%m-%d'))
        else:
            is_active.append(1)
            churn_dates.append(None)
    else:
        is_active.append(1)
        churn_dates.append(None)

df_subscribers = pd.DataFrame({
    'subscriber_id': subscriber_ids,
    'signup_date': [d.strftime('%Y-%m-%d') for d in signup_dates],
    'region_code': regions,
    'plan_tier': plan_tiers,
    'monthly_price': monthly_prices,
    'is_active': is_active,
    'churn_date': churn_dates
})

print(f"Created {len(df_subscribers)} subscriber records. Realized Churn Rate: {round((1 - np.mean(is_active))*100, 2)}%")

print("Running pre-flight BigQuery storage budget checks...")
estimated_sub_bytes = df_subscribers.memory_usage(deep=True).sum()
estimated_tel_bytes = 9000000 * 112 # Avg bytes per row layout for telemetry schema
total_est_gb = (estimated_sub_bytes + estimated_tel_bytes) / (1024 ** 3)

print(f"-> Estimated Dataset Sandbox Size: {round(total_est_gb, 4)} GB")
print(f"-> Percent of BigQuery Free Tier Storage (10GB Limit): {round((total_est_gb / 10.0) * 100, 2)}%\")")

if total_est_gb > 10.0:
    print("🚨 CRITICAL WARNING: Data generation exceeds BigQuery Sandbox capacity boundaries. Halting script.")
    sys.exit()
else:
    print("✅ Budget Check Passed. Safely within BigQuery Free Tier limits.")

subscribers_schema = [
    {'name': 'subscriber_id', 'type': 'STRING'},
    {'name': 'signup_date', 'type': 'DATE'},
    {'name': 'region_code', 'type': 'STRING'},
    {'name': 'plan_tier', 'type': 'STRING'},
    {'name': 'monthly_price', 'type': 'FLOAT'},
    {'name': 'is_active', 'type': 'INTEGER'},
    {'name': 'churn_date', 'type': 'DATE'}
]

pandas_gbq.to_gbq(
    df_subscribers,
    destination_table=f'{dataset_id}.raw_subscribers',
    project_id=project_id,
    if_exists='replace',
    table_schema=subscribers_schema
)
print("Successfully uploaded raw_subscribers to BigQuery.")

print("Generating 90-day daily telemetry stream in optimized chunked batches...")
chunk_size = 50000 

# FIXED: Explicit schema mapping to officially define raw_telemetry_daily
telemetry_schema = [
    {'name': 'subscriber_id', 'type': 'STRING'},
    {'name': 'event_date', 'type': 'DATE'},
    {'name': 'region_code', 'type': 'STRING'},
    {'name': 'avg_latency_ms', 'type': 'FLOAT'},
    {'name': 'obstruction_rate', 'type': 'FLOAT'},
    {'name': 'ping_drop_rate', 'type': 'FLOAT'},
    {'name': 'throughput_mbps', 'type': 'FLOAT'},
    {'name': 'hardware_error_flag', 'type': 'INTEGER'}
]

for chunk_idx in range(0, NUM_SUBSCRIBERS, chunk_size):
    chunk_subs = subscriber_ids[chunk_idx:chunk_idx+chunk_size]
    chunk_regions = regions[chunk_idx:chunk_idx+chunk_size]
    chunk_churn_dates = churn_dates[chunk_idx:chunk_idx+chunk_size]
    
    telemetry_rows = []
    for s_id, reg, c_date_str in zip(chunk_subs, chunk_regions, chunk_churn_dates):
        
        # FIXED: Time-Aligned Churn Labeling. Skip telemetry if user churned before this window
        c_date = datetime.strptime(c_date_str, '%Y-%m-%d') if c_date_str else None
        if c_date and c_date < TELEMETRY_START:
            continue
            
        # Inject normal baseline distributions
        obs_base = np.random.lognormal(mean=-3.2, sigma=0.85, size=NUM_DAYS)
        obs_base = np.clip(obs_base, 0.0, 0.25)
        
        latencies = np.random.normal(loc=42.0, scale=12.5, size=NUM_DAYS)
        latencies = np.clip(latencies, 15.0, 200.0)
        
        ping_drops = np.random.beta(a=1.2, b=35.0, size=NUM_DAYS)
        throughputs = np.random.normal(loc=115.0, scale=35.0, size=NUM_DAYS)
        hw_errors = np.random.choice([0, 1], size=NUM_DAYS, p=[0.98, 0.02])
        
        # FIXED: Inject hardware/network anomalies directly before a churn event
        if c_date and TELEMETRY_START <= c_date <= ANALYTICAL_CUTOFF:
            churn_day_index = (c_date - TELEMETRY_START).days
            deg_start = max(0, churn_day_index - 7)
            
            # Degrade system connection quality for the 7 days prior to cancellation
            obs_base[deg_start:churn_day_index] *= 2.5
            latencies[deg_start:churn_day_index] += 45.0
            ping_drops[deg_start:churn_day_index] += 0.15
            throughputs[deg_start:churn_day_index] *= 0.4
            
        for day_i in range(NUM_DAYS):
            current_evt_date = TELEMETRY_START + timedelta(days=day_i)
            
            # Stop generating daily logs if the customer has already officially left
            if c_date and current_evt_date > c_date:
                continue
                
            telemetry_rows.append({
                'subscriber_id': s_id,
                'event_date': current_evt_date.strftime('%Y-%m-%d'),
                'region_code': reg,
                'avg_latency_ms': float(latencies[day_i]),
                'obstruction_rate': float(obs_base[day_i]),
                'ping_drop_rate': float(ping_drops[day_i]),
                'throughput_mbps': float(throughputs[day_i]),
                'hardware_error_flag': int(hw_errors[day_i])
            })
            
    df_chunk = pd.DataFrame(telemetry_rows)
    if_exists_mode = 'replace' if chunk_idx == 0 else 'append'
    
    pandas_gbq.to_gbq(
        df_chunk,
        destination_table=f'{dataset_id}.raw_telemetry_daily',
        project_id=project_id,
        if_exists=if_exists_mode,
        table_schema=telemetry_schema
    )
    print(f"Uploaded chunk {chunk_idx // chunk_size + 1} / {NUM_SUBSCRIBERS // chunk_size}")

print("Synthetic data pipeline execution complete. Structural anomalies resolved.")
