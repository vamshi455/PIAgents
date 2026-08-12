# Genie space — Industrial Ops (serving_safe)

## Purpose
Natural-language analytics over governed predictive-maintenance and OEE metrics **without PII**.

## Bind these objects only
- `industrial_ops.serving_safe.assets`
- `industrial_ops.serving_safe.asset_health_daily`
- `industrial_ops.serving_safe.pi_timeseries_recent`
- `industrial_ops.serving_safe.work_orders`
- `industrial_ops.serving_safe.alarms`
- `industrial_ops.serving_safe.maintenance_outcomes`
- `industrial_ops.serving_safe.oee_daily`
- `industrial_ops.serving_safe.shifts` (redacted notes only)
- `industrial_ops.metrics.asset_health_score`
- `industrial_ops.metrics.anomaly_rate_7d`
- `industrial_ops.metrics.mtbf_proxy`
- `industrial_ops.metrics.oee_by_line`

## Do not add
- Any table in `industrial_ops.ops_pii_restricted`
- Bronze enrichment tables with name/email/phone/badge

## Sample questions
- What is the health score trend for PMP-12 over the last 7 days?
- Which assets have anomaly_flag = true today?
- Show open work orders for criticality A assets.
- Compare OEE proxy for LINE-A vs LINE-B.
- List high-severity uncleared alarms.

## Setup notes (workspace UI)
1. Create Genie space `industrial-ops-pm`.
2. Attach service principal `sp_genie_industrial` with SELECT on `serving_safe` + `metrics`.
3. Add table descriptions from `docs/data_dictionary.md`.
4. Add certified answers for health_score and anomaly_rate_7d definitions.
