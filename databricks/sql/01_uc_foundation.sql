-- Unity Catalog foundation for PI lakehouse MVP
-- Catalog industrial_ops is created via Databricks API with storage_root
-- (metastore has no default root; SQL CREATE CATALOG without location fails)

CREATE SCHEMA IF NOT EXISTS industrial_ops.bronze
COMMENT 'Raw append-only landings';

CREATE SCHEMA IF NOT EXISTS industrial_ops.silver
COMMENT 'Typed, cleaned, joined operational data';

CREATE SCHEMA IF NOT EXISTS industrial_ops.gold
COMMENT 'Feature / fact tables for analytics';

CREATE SCHEMA IF NOT EXISTS industrial_ops.ops_pii_restricted
COMMENT 'PII-bearing curated tables; privileged access only';

CREATE SCHEMA IF NOT EXISTS industrial_ops.serving_safe
COMMENT 'De-identified views for Genie and agents';

CREATE SCHEMA IF NOT EXISTS industrial_ops.metrics
COMMENT 'Metric views for governed KPIs';

CREATE VOLUME IF NOT EXISTS industrial_ops.bronze.landing
COMMENT 'Landing zone for enrichment CSVs and streaming checkpoints';
