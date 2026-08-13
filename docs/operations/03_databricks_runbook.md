# Databricks setup runbook (ordered)

Execute these steps **in order**. Do not skip foundation or land PII into Genie-facing schemas.

**Compute reminder:** attach classic cluster `0811-112417-qhhyebl0` only. Serverless is forbidden. See [05_jobs_and_compute.md](05_jobs_and_compute.md).

---

## 0. Preconditions checklist

- [ ] Azure workspace open: `https://adb-7405605697371162.2.azuredatabricks.net`
- [ ] Classic cluster exists and is idle/stopped until you need it
- [ ] You have privileges to create catalogs/schemas (or catalog already created with storage root)
- [ ] Mock API reachable from cluster (tunnel + `PI_API_BASE`) if running stream
- [ ] Owner approved **cost** for waking the cluster

**Status note:** README states no deploy/SQL/jobs have been run from this repo by default. Treat first execution as a change-controlled event.

---

## 1. Unity Catalog foundation

**File:** `databricks/sql/01_uc_foundation.sql`

### Important metastore caveat

This metastore has **no default storage root**. Plain `CREATE CATALOG industrial_ops` without a location can fail. Create the catalog via Databricks API/UI **with `storage_root`**, then run the SQL that creates schemas + volume:

| Object | Comment |
|---|---|
| Schema `industrial_ops.bronze` | Raw append-only landings |
| Schema `industrial_ops.silver` | Typed cleaned ops |
| Schema `industrial_ops.gold` | Facts / features |
| Schema `industrial_ops.ops_pii_restricted` | Privileged PII |
| Schema `industrial_ops.serving_safe` | Genie/agent surface |
| Schema `industrial_ops.metrics` | KPI views |
| Volume `industrial_ops.bronze.landing` | CSV landing + stream checkpoints |

Verify:

```sql
SHOW SCHEMAS IN industrial_ops;
LIST '/Volumes/industrial_ops/bronze/landing';
```

---

## 2. Bronze tables

**File:** `databricks/sql/02_bronze_tables.sql`

Creates:

- `bronze.pi_timeseries_raw` (CDF on)
- `bronze.assets_raw`
- `bronze.work_orders_raw`
- `bronze.alarms_raw`
- `bronze.production_events_raw`
- `bronze.shifts_raw`

Verify: `SHOW TABLES IN industrial_ops.bronze;`

---

## 3. Upload enrichment CSVs

Local path: `data/enrichment/`

Upload into UC volume (recommended):

```
/Volumes/industrial_ops/bronze/landing/assets.csv
/Volumes/industrial_ops/bronze/landing/work_orders.csv
/Volumes/industrial_ops/bronze/landing/alarms.csv
/Volumes/industrial_ops/bronze/landing/production_events.csv
/Volumes/industrial_ops/bronze/landing/shifts.csv
```

UI: Catalog → `industrial_ops` → `bronze` → volume `landing` → Upload.  
Or Databricks CLI / workspace file browser equivalent.

---

## 4. Start PI bronze stream

**Notebook:** `databricks/notebooks/01_bronze_pi_stream.py`

1. Ensure mock API + tunnel are live ([02_mock_pi_api.md](02_mock_pi_api.md)).
2. Set cluster env `PI_API_BASE` (or edit notebook default).
3. Attach classic cluster; run all cells.
4. Stream starts with 5-second trigger; leaves a streaming query running.

Verify:

```sql
SELECT count(*) FROM industrial_ops.bronze.pi_timeseries_raw;
SELECT max(ingest_ts) FROM industrial_ops.bronze.pi_timeseries_raw;
SELECT asset_id, tag_name, value, event_ts
FROM industrial_ops.bronze.pi_timeseries_raw
ORDER BY ingest_ts DESC
LIMIT 50;
```

Expect counts to grow while the stream and API are up.

**Stop:** cancel the streaming query / detach notebook when demos end to avoid idle cluster cost.

---

## 5. Load enrichment batch

**Notebook:** `databricks/notebooks/02_bronze_enrichment_batch.py`

Optional env: `ENRICHMENT_LANDING` (default volume path above).

Verify each bronze enrichment table has ≥1 row (MVP CSVs are small).

---

## 6. Silver + PII tables

**File:** `databricks/sql/03_silver_tables.sql`

Run entire script in a SQL warehouse **or** classic cluster SQL cell (classic preferred for consistency with policy).

Creates silver ops tables and `ops_pii_restricted` people tables.

Verify:

```sql
SELECT count(*) FROM industrial_ops.silver.pi_timeseries;
SELECT count(*) FROM industrial_ops.silver.work_orders;
SELECT * FROM industrial_ops.ops_pii_restricted.work_order_people LIMIT 5; -- privileged only
```

---

## 7. Gold + metrics

**File:** `databricks/sql/05_gold_and_metrics.sql`

Creates:

- `gold.asset_tag_hourly`
- `gold.asset_health_daily`
- `gold.maintenance_outcomes`
- `gold.oee_daily`
- metric views under `industrial_ops.metrics.*`

Verify:

```sql
SELECT * FROM industrial_ops.gold.asset_health_daily ORDER BY day_dt DESC LIMIT 20;
SELECT * FROM industrial_ops.metrics.anomaly_rate_7d;
```

---

## 8. Serving-safe views

**File:** `databricks/sql/04_serving_safe_views.sql`

Run after gold exists (views reference gold + silver).

Verify no PII columns:

```sql
DESCRIBE TABLE industrial_ops.serving_safe.work_orders;
DESCRIBE TABLE industrial_ops.serving_safe.shifts;
```

You should see `technician_role` / `handoff_notes_redacted`, not emails or phones.

---

## 9. PII masks, filters, grants

**File:** `databricks/sql/06_pii_masks_and_filters.sql`

Creates mask UDFs, applies column masks, plant row filter, tags, and grants.

**Before running:** create account groups / service principals named in [06_governance_security.md](06_governance_security.md). Adjust SQL if your identity names differ.

Verify as a non-PII user: emails appear masked; Genie SP cannot `SELECT` from `ops_pii_restricted`.

---

## 10. Optional notebooks (stubs)

| Notebook | Status | Action |
|---|---|---|
| `03_silver_gold_transforms.py` | Stub | Prefer SQL scripts until implemented |
| `04_governance_apply.py` | Stub | Prefer `06_pii_masks_and_filters.sql` |

---

## 11. Bundle deploy (optional, change-controlled)

```bash
cd databricks/jobs
# Ensure Databricks CLI auth to the Azure workspace
# Review databricks.yml host + existing_cluster_id
databricks bundle validate -t dev
# ONLY when approved:
databricks bundle deploy -t dev
databricks bundle run -t dev pi_bronze_stream
```

Do **not** deploy by default. Confirm FinOps owner first.

---

## 12. Post-setup Genie / agents

Follow [07_agents_and_genie.md](07_agents_and_genie.md) only after serving_safe + metrics exist and grants are correct.

---

## 13. Teardown / cost control

1. Stop streaming queries.
2. Stop/terminate classic cluster when idle.
3. Stop ngrok / local API if unused.
4. Leave UC data in place unless a purge is requested (PII retention rules apply — see governance).

---

## 14. Recommended execution order (cheat sheet)

```
01_uc_foundation.sql
02_bronze_tables.sql
upload CSVs → volume
01_bronze_pi_stream.py          # API must be up
02_bronze_enrichment_batch.py
03_silver_tables.sql
05_gold_and_metrics.sql
04_serving_safe_views.sql
06_pii_masks_and_filters.sql
configure Genie / agents
```
