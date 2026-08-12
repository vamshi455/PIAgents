-- Bronze tables: raw PI stream + enrichment landings

CREATE TABLE IF NOT EXISTS industrial_ops.bronze.pi_timeseries_raw (
  tag_name STRING,
  asset_id STRING,
  event_ts TIMESTAMP,
  value DOUBLE,
  quality STRING,
  uom STRING,
  source_system STRING,
  plant_id STRING,
  area_id STRING,
  ingest_ts TIMESTAMP,
  raw_payload STRING
) USING DELTA
COMMENT 'Append-only PI-like points from streaming API'
TBLPROPERTIES (
  'delta.enableChangeDataFeed' = 'true'
);

CREATE TABLE IF NOT EXISTS industrial_ops.bronze.assets_raw (
  plant_id STRING,
  area_id STRING,
  unit_id STRING,
  asset_id STRING,
  asset_name STRING,
  asset_type STRING,
  criticality STRING,
  manufacturer STRING,
  install_date STRING,
  parent_asset_id STRING,
  ingest_ts TIMESTAMP,
  source_file STRING
) USING DELTA;

CREATE TABLE IF NOT EXISTS industrial_ops.bronze.work_orders_raw (
  work_order_id STRING,
  asset_id STRING,
  plant_id STRING,
  opened_at STRING,
  closed_at STRING,
  status STRING,
  failure_code STRING,
  priority STRING,
  technician_employee_id STRING,
  technician_name STRING,
  technician_email STRING,
  technician_badge_id STRING,
  parts_used STRING,
  labor_hours STRING,
  notes STRING,
  ingest_ts TIMESTAMP,
  source_file STRING
) USING DELTA;

CREATE TABLE IF NOT EXISTS industrial_ops.bronze.alarms_raw (
  alarm_id STRING,
  asset_id STRING,
  plant_id STRING,
  raised_at STRING,
  cleared_at STRING,
  severity STRING,
  alarm_code STRING,
  alarm_text STRING,
  acked_at STRING,
  acked_by_employee_id STRING,
  acked_by_name STRING,
  ingest_ts TIMESTAMP,
  source_file STRING
) USING DELTA;

CREATE TABLE IF NOT EXISTS industrial_ops.bronze.production_events_raw (
  event_id STRING,
  plant_id STRING,
  area_id STRING,
  line_id STRING,
  asset_id STRING,
  event_start STRING,
  event_end STRING,
  event_type STRING,
  downtime_code STRING,
  good_count STRING,
  scrap_count STRING,
  planned_count STRING,
  notes STRING,
  ingest_ts TIMESTAMP,
  source_file STRING
) USING DELTA;

CREATE TABLE IF NOT EXISTS industrial_ops.bronze.shifts_raw (
  shift_id STRING,
  plant_id STRING,
  area_id STRING,
  shift_name STRING,
  shift_start STRING,
  shift_end STRING,
  crew_id STRING,
  supervisor_employee_id STRING,
  supervisor_name STRING,
  supervisor_email STRING,
  supervisor_phone STRING,
  operator_employee_id STRING,
  operator_name STRING,
  operator_email STRING,
  operator_phone STRING,
  handoff_notes STRING,
  ingest_ts TIMESTAMP,
  source_file STRING
) USING DELTA;
