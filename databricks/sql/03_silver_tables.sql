-- Silver curated tables (operational; PII columns moved to ops_pii_restricted)

CREATE OR REPLACE TABLE industrial_ops.silver.assets AS
SELECT
  plant_id,
  area_id,
  unit_id,
  asset_id,
  asset_name,
  asset_type,
  criticality,
  manufacturer,
  CAST(install_date AS DATE) AS install_date,
  NULLIF(parent_asset_id, '') AS parent_asset_id
FROM industrial_ops.bronze.assets_raw;

CREATE OR REPLACE TABLE industrial_ops.silver.pi_timeseries AS
SELECT
  tag_name,
  asset_id,
  event_ts,
  value,
  quality,
  uom,
  source_system,
  plant_id,
  area_id,
  regexp_extract(tag_name, '\\\\|(.+)$', 1) AS tag_suffix,
  ingest_ts
FROM industrial_ops.bronze.pi_timeseries_raw
WHERE quality IN ('Good', 'Uncertain');

CREATE OR REPLACE TABLE industrial_ops.silver.work_orders AS
SELECT
  work_order_id,
  asset_id,
  plant_id,
  CAST(opened_at AS TIMESTAMP) AS opened_at,
  CAST(NULLIF(closed_at, '') AS TIMESTAMP) AS closed_at,
  status,
  failure_code,
  CAST(priority AS INT) AS priority,
  technician_employee_id,
  NULLIF(parts_used, '') AS parts_used,
  CAST(NULLIF(labor_hours, '') AS DOUBLE) AS labor_hours,
  notes
FROM industrial_ops.bronze.work_orders_raw;

CREATE OR REPLACE TABLE industrial_ops.silver.alarms AS
SELECT
  alarm_id,
  asset_id,
  plant_id,
  CAST(raised_at AS TIMESTAMP) AS raised_at,
  CAST(NULLIF(cleared_at, '') AS TIMESTAMP) AS cleared_at,
  severity,
  alarm_code,
  alarm_text,
  CAST(NULLIF(acked_at, '') AS TIMESTAMP) AS acked_at,
  acked_by_employee_id
FROM industrial_ops.bronze.alarms_raw;

CREATE OR REPLACE TABLE industrial_ops.silver.production_events AS
SELECT
  event_id,
  plant_id,
  area_id,
  line_id,
  asset_id,
  CAST(event_start AS TIMESTAMP) AS event_start,
  CAST(event_end AS TIMESTAMP) AS event_end,
  event_type,
  NULLIF(downtime_code, '') AS downtime_code,
  CAST(NULLIF(good_count, '') AS BIGINT) AS good_count,
  CAST(NULLIF(scrap_count, '') AS BIGINT) AS scrap_count,
  CAST(NULLIF(planned_count, '') AS BIGINT) AS planned_count,
  notes
FROM industrial_ops.bronze.production_events_raw;

CREATE OR REPLACE TABLE industrial_ops.silver.shifts AS
SELECT
  shift_id,
  plant_id,
  area_id,
  shift_name,
  CAST(shift_start AS TIMESTAMP) AS shift_start,
  CAST(shift_end AS TIMESTAMP) AS shift_end,
  crew_id,
  supervisor_employee_id,
  operator_employee_id,
  handoff_notes
FROM industrial_ops.bronze.shifts_raw;

-- PII-restricted projections (names/emails/phones/badges)
CREATE OR REPLACE TABLE industrial_ops.ops_pii_restricted.work_order_people AS
SELECT
  work_order_id,
  plant_id,
  technician_employee_id,
  technician_name,
  technician_email,
  technician_badge_id
FROM industrial_ops.bronze.work_orders_raw;

CREATE OR REPLACE TABLE industrial_ops.ops_pii_restricted.alarm_ack_people AS
SELECT
  alarm_id,
  plant_id,
  acked_by_employee_id,
  acked_by_name
FROM industrial_ops.bronze.alarms_raw;

CREATE OR REPLACE TABLE industrial_ops.ops_pii_restricted.shift_people AS
SELECT
  shift_id,
  plant_id,
  crew_id,
  supervisor_employee_id,
  supervisor_name,
  supervisor_email,
  supervisor_phone,
  operator_employee_id,
  operator_name,
  operator_email,
  operator_phone,
  handoff_notes
FROM industrial_ops.bronze.shifts_raw;
