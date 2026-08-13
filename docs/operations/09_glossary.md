# Glossary

| Term | Meaning in this project |
|---|---|
| **AVEVA PI / PI System** | Industrial historian for high-frequency time series; we mock its feed |
| **TimeSeriesPoint** | Canonical JSON/event contract for one tag reading |
| **Mock PI API** | Local FastAPI service emitting simulated points |
| **SSE** | Server-Sent Events (`/stream/points`); not used by bronze notebook |
| **Snapshot** | One-shot JSON batch (`/snapshot/points`) polled by Databricks |
| **ngrok** | Tunnel exposing local API to Azure Databricks |
| **Unity Catalog (UC)** | Databricks governance layer for catalogs/schemas/volumes/grants |
| **Catalog `industrial_ops`** | Project UC catalog |
| **Medallion** | bronze → silver → gold layered lakehouse pattern |
| **Bronze** | Raw landings (append/overwrite) |
| **Silver** | Typed, cleaned operational tables |
| **Gold** | Business facts/features (health, OEE, maintenance) |
| **serving_safe** | De-identified views for Genie/agents |
| **ops_pii_restricted** | Privileged identity tables |
| **metrics** | KPI-oriented views over gold |
| **Landing volume** | UC volume for CSV + checkpoints |
| **CDF** | Change Data Feed (enabled on PI bronze table) |
| **Classic cluster** | Traditional Databricks all-purpose cluster (required here) |
| **Serverless** | Forbidden compute mode for this MVP |
| **DAB / Asset Bundle** | `databricks.yml` job packaging |
| **Genie** | Databricks natural-language analytics over bound tables |
| **Agent** | Tool-using assistant (maintenance / RCA / shift) over safe data |
| **Health score** | 0–100 rule-based asset score from vibration/temp/amps |
| **Anomaly flag** | Boolean when vibration or bearing temp exceed hard thresholds |
| **OEE proxy** | Availability × quality ratios from production events (MVP approximation) |
| **MTTR** | Mean time to repair (hours between WO open and close) |
| **MTBF proxy** | MVP metric from closed failure WOs (not true statistical MTBF) |
| **PII** | Personally identifiable information |
| **Row filter** | UC predicate limiting rows (e.g. by `plant_id`) |
| **Column mask** | UC function redacting column values for non-privileged users |
| **crew_id** | Non-personal crew identifier safe for serving layer |
| **tag_suffix** | Parsed metric name from PI tag path (e.g. `Vibration`) |
| **sp_*** | Service principal identities for ingest / Genie / agents |
