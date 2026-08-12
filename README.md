# PI Time Series → Databricks Lakehouse + Governance

Mock AVEVA PI–style continuous time series API, Databricks medallion lakehouse (Unity Catalog), PII governance, metric views, Genie, and maintenance/RCA/shift agents.

## Compute / cost (read first)

- **Repo + local mock API alone incur $0 Databricks cost.**
- Do **not** deploy jobs or run SQL/notebooks until you intentionally attach your **existing small classic cluster**.
- **Serverless is forbidden** for this project. Jobs are pinned to classic cluster `0811-112417-qhhyebl0` (`vsingam@mhktechinc.com's Cluster 2026-08-11 06:19:00`) via `databricks/jobs/databricks.yml`.
- Workspace host is set to `https://adb-7405605697371162.2.azuredatabricks.net` (Azure RG `databricks-rg-vamshi-dev-npujx7didcsju`). **No deploy/SQL/jobs have been run from this repo.**
- Creating UC objects or running notebooks later will use that classic cluster while it is awake — only do that when you ask.

## Quick start (API)

```bash
cd api
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --host 127.0.0.1 --port 8080
```

- Health: `GET http://localhost:8080/health`
- Tags: `GET http://localhost:8080/tags`
- SSE stream: `GET http://localhost:8080/stream/points`
- Snapshot (for Databricks poll): `GET http://localhost:8080/snapshot/points`

For Azure Databricks to reach this Mac, keep a tunnel up (e.g. `ngrok http 127.0.0.1:8080`) and set `PI_API_BASE` to the https URL. The bronze notebook sends `ngrok-skip-browser-warning` for free-tier tunnels.

## Databricks setup order

1. Run `databricks/sql/01_uc_foundation.sql`
2. Run `databricks/sql/02_bronze_tables.sql`
3. Upload `data/enrichment/*.csv` to landing volume
4. Run notebooks `01_bronze_pi_stream` (while API is up) and `02_bronze_enrichment_batch`
5. Run `03_silver_tables.sql` → `05_gold_and_metrics.sql` → `04_serving_safe_views.sql` → `06_pii_masks_and_filters.sql`
6. Configure Genie/agents per `agents/`

## Layout

```
api/                  FastAPI mock PI emitter + PI adapter stub
data/enrichment/      MVP CSVs (assets, WOs, alarms, production, shifts)
databricks/notebooks/ Bronze stream + enrichment + curate stubs
databricks/sql/       UC, bronze/silver/gold, serving_safe, PII masks
databricks/jobs/      Databricks Asset Bundle skeleton
governance/           PII inventory, tags, access matrix
agents/               Genie space + agent tool contracts
docs/                 Architecture + data dictionary
```

## Governance highlights

- PII lives in `industrial_ops.ops_pii_restricted`
- Genie/agents bind only to `serving_safe` + `metrics`
- Column masks + plant row filters documented in SQL and `governance/`
