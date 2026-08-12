-- Serving-safe views for Genie / agents (no direct PII columns)

CREATE OR REPLACE VIEW industrial_ops.serving_safe.work_orders AS
SELECT
  work_order_id,
  asset_id,
  plant_id,
  opened_at,
  closed_at,
  status,
  failure_code,
  priority,
  -- role proxy only; no name/email/badge
  CASE
    WHEN priority <= 1 THEN 'reliability_oncall'
    WHEN priority = 2 THEN 'technician'
    ELSE 'planner'
  END AS technician_role,
  parts_used,
  labor_hours
FROM industrial_ops.silver.work_orders;

CREATE OR REPLACE VIEW industrial_ops.serving_safe.alarms AS
SELECT
  alarm_id,
  asset_id,
  plant_id,
  raised_at,
  cleared_at,
  severity,
  alarm_code,
  alarm_text,
  acked_at,
  CASE WHEN acked_by_employee_id IS NOT NULL THEN TRUE ELSE FALSE END AS was_acked
FROM industrial_ops.silver.alarms;

CREATE OR REPLACE VIEW industrial_ops.serving_safe.shifts AS
SELECT
  shift_id,
  plant_id,
  area_id,
  shift_name,
  shift_start,
  shift_end,
  crew_id,
  -- strip personal identifiers from notes for default consumers
  regexp_replace(
    handoff_notes,
    '(?i)(Jordan Lee|Sam Rivera|Alex Chen|Morgan Patel|Riley Quinn|Casey Brooks|Taylor Kim|Jamie Ortiz)',
    '[PERSON]'
  ) AS handoff_notes_redacted
FROM industrial_ops.silver.shifts;

CREATE OR REPLACE VIEW industrial_ops.serving_safe.assets AS
SELECT * FROM industrial_ops.silver.assets;

CREATE OR REPLACE VIEW industrial_ops.serving_safe.asset_health_daily AS
SELECT * FROM industrial_ops.gold.asset_health_daily;

CREATE OR REPLACE VIEW industrial_ops.serving_safe.oee_daily AS
SELECT * FROM industrial_ops.gold.oee_daily;

CREATE OR REPLACE VIEW industrial_ops.serving_safe.maintenance_outcomes AS
SELECT
  work_order_id,
  plant_id,
  asset_id,
  opened_at,
  closed_at,
  status,
  failure_code,
  priority,
  parts_used,
  labor_hours,
  mttr_hours
FROM industrial_ops.gold.maintenance_outcomes;

CREATE OR REPLACE VIEW industrial_ops.serving_safe.pi_timeseries_recent AS
SELECT
  tag_name,
  asset_id,
  event_ts,
  value,
  quality,
  uom,
  plant_id,
  area_id,
  tag_suffix
FROM industrial_ops.silver.pi_timeseries
WHERE event_ts >= current_timestamp() - INTERVAL 7 DAYS;
