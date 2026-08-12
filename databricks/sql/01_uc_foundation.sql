-- Unity Catalog foundation for PI lakehouse MVP
-- Catalog: industrial_ops | Schemas follow medallion + PII segregation

CREATE CATALOG IF NOT EXISTS industrial_ops
COMMENT 'PI time series + enrichment lakehouse for predictive maintenance demo';

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

-- Volume for file landing (enrichment CSVs, optional)
-- REPLACE <storage> with your UC external location
-- CREATE EXTERNAL VOLUME IF NOT EXISTS industrial_ops.bronze.landing
-- LOCATION 'abfss://landing@<storage>.dfs.core.windows.net/industrial_ops';
