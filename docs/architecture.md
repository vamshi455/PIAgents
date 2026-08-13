# Architecture

Concise reference. For operations-grade detail, diagrams, and runbooks see [operations/00_handbook.md](operations/00_handbook.md) and the [docs index](README.md).

## Data flow

1. **Mock PI API** (`api/`) emits continuous `TimeSeriesPoint` batches (SSE + snapshot).
2. **Bronze stream** notebook polls `/snapshot/points` via Structured Streaming `foreachBatch` and appends to `industrial_ops.bronze.pi_timeseries_raw`.
3. **Enrichment batch** loads CMMS/alarms/MES/shifts CSVs into bronze.
4. **Silver** types and cleans; people attributes land in `ops_pii_restricted`.
5. **Gold** builds hourly tag features, daily health scores, maintenance outcomes, OEE.
6. **Metric views** + **serving_safe** views feed Genie and agents without direct PII.

## PI adapter boundary

| Component | Role |
|---|---|
| `TimeSeriesPoint` | Canonical contract for lakehouse consumers |
| `MockPISource` | Demo continuous generator |
| `AvevaPIWebAPISource` | Stub for real PI Web API / channels |

Consumers never depend on mock internals — only on the contract.

## Medallion map

| Layer | Schema | Contents |
|---|---|---|
| Bronze | `industrial_ops.bronze` | Raw PI + enrichment |
| Silver | `industrial_ops.silver` | Typed ops (ids, not names) |
| Gold | `industrial_ops.gold` | Health, OEE, maintenance facts |
| Metrics | `industrial_ops.metrics` | KPI views |
| Serving | `industrial_ops.serving_safe` | De-identified Genie/agent surface |
| PII | `industrial_ops.ops_pii_restricted` | Names, emails, phones, badges |

## Primary use cases

1. **Predictive maintenance** — health_score / anomaly_flag + open WOs → maintenance advisor
2. **RCA** — tags + alarms + downtime window → incident narrative
3. **Shift briefing** — overnight anomalies + redacted handoff → crew briefing
4. **OEE proxy** — production events → line metrics for Genie

## Security

See `governance/pii_inventory.md`. Agents must not query restricted schemas.
