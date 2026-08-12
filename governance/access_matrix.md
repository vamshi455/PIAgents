# Access matrix (summary)

See also `pii_inventory.md`.

## Groups to create

1. `industrial_ops_engineers` — pipeline owners
2. `industrial_ops_readers` — analysts / Genie users (safe data)
3. `industrial_ops_pii_readers` — HR/reliability leads needing identity
4. `plant_PLANT-01` — plant-scoped row access (extend per site)

## Service principals

| SP | Purpose | Schemas |
|---|---|---|
| `sp_pi_ingest` | Streaming + enrichment jobs | bronze RW, silver RW |
| `sp_genie_industrial` | Genie space | serving_safe R, metrics R |
| `sp_agent_maintenance` | Maintenance / RCA / shift agents | serving_safe R, metrics R |

## Hard rules

- Never grant Genie/agent SPs on `ops_pii_restricted` or bronze enrichment with PII.
- Prefer views in `serving_safe` over direct gold when columns may later gain PII.
- Plant row filters required before multi-site production.
