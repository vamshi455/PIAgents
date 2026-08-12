-- Gold facts / features + metric views (no PII columns)

CREATE OR REPLACE TABLE industrial_ops.gold.asset_tag_hourly AS
SELECT
  plant_id,
  area_id,
  asset_id,
  tag_suffix,
  date_trunc('HOUR', event_ts) AS hour_ts,
  avg(value) AS avg_value,
  max(value) AS max_value,
  min(value) AS min_value,
  stddev_samp(value) AS std_value,
  count(*) AS sample_count
FROM industrial_ops.silver.pi_timeseries
GROUP BY plant_id, area_id, asset_id, tag_suffix, date_trunc('HOUR', event_ts);

-- Simple rule-based health score (0-100): penalize high vibration / bearing temp / amps
CREATE OR REPLACE TABLE industrial_ops.gold.asset_health_daily AS
WITH pivot AS (
  SELECT
    plant_id,
    asset_id,
    CAST(hour_ts AS DATE) AS day_dt,
    max(CASE WHEN tag_suffix = 'Vibration' THEN avg_value END) AS vib,
    max(CASE WHEN tag_suffix = 'BearingTemp' THEN avg_value END) AS bearing_temp,
    max(CASE WHEN tag_suffix = 'MotorAmps' THEN avg_value END) AS motor_amps,
    max(CASE WHEN tag_suffix = 'RunStatus' THEN avg_value END) AS run_frac
  FROM industrial_ops.gold.asset_tag_hourly
  GROUP BY plant_id, asset_id, CAST(hour_ts AS DATE)
)
SELECT
  p.plant_id,
  p.asset_id,
  a.asset_name,
  a.criticality,
  p.day_dt,
  p.vib,
  p.bearing_temp,
  p.motor_amps,
  p.run_frac,
  greatest(
    0.0,
    least(
      100.0,
      100.0
        - greatest(p.vib - 2.5, 0) * 15
        - greatest(p.bearing_temp - 70, 0) * 2
        - greatest(p.motor_amps - 48, 0) * 1.5
    )
  ) AS health_score,
  CASE
    WHEN p.vib > 4.0 OR p.bearing_temp > 85 THEN TRUE
    ELSE FALSE
  END AS anomaly_flag
FROM pivot p
LEFT JOIN industrial_ops.silver.assets a
  ON p.asset_id = a.asset_id AND p.plant_id = a.plant_id;

CREATE OR REPLACE TABLE industrial_ops.gold.maintenance_outcomes AS
SELECT
  w.work_order_id,
  w.plant_id,
  w.asset_id,
  w.opened_at,
  w.closed_at,
  w.status,
  w.failure_code,
  w.priority,
  w.parts_used,
  w.labor_hours,
  CASE
    WHEN w.closed_at IS NOT NULL
    THEN (unix_timestamp(w.closed_at) - unix_timestamp(w.opened_at)) / 3600.0
  END AS mttr_hours
FROM industrial_ops.silver.work_orders w;

CREATE OR REPLACE TABLE industrial_ops.gold.oee_daily AS
SELECT
  plant_id,
  area_id,
  line_id,
  CAST(event_start AS DATE) AS day_dt,
  sum(CASE WHEN event_type = 'RUN' THEN unix_timestamp(event_end) - unix_timestamp(event_start) ELSE 0 END) / 3600.0 AS run_hours,
  sum(CASE WHEN event_type = 'DOWNTIME' THEN unix_timestamp(event_end) - unix_timestamp(event_start) ELSE 0 END) / 3600.0 AS down_hours,
  sum(coalesce(good_count, 0)) AS good_count,
  sum(coalesce(scrap_count, 0)) AS scrap_count,
  sum(coalesce(planned_count, 0)) AS planned_count,
  CASE
    WHEN sum(coalesce(planned_count, 0)) > 0
    THEN sum(coalesce(good_count, 0)) * 1.0 / sum(planned_count)
  END AS quality_ratio,
  CASE
    WHEN (
      sum(CASE WHEN event_type = 'RUN' THEN unix_timestamp(event_end) - unix_timestamp(event_start) ELSE 0 END)
      + sum(CASE WHEN event_type = 'DOWNTIME' THEN unix_timestamp(event_end) - unix_timestamp(event_start) ELSE 0 END)
    ) > 0
    THEN sum(CASE WHEN event_type = 'RUN' THEN unix_timestamp(event_end) - unix_timestamp(event_start) ELSE 0 END) * 1.0
      / (
        sum(CASE WHEN event_type = 'RUN' THEN unix_timestamp(event_end) - unix_timestamp(event_start) ELSE 0 END)
        + sum(CASE WHEN event_type = 'DOWNTIME' THEN unix_timestamp(event_end) - unix_timestamp(event_start) ELSE 0 END)
      )
  END AS availability_ratio
FROM industrial_ops.silver.production_events
GROUP BY plant_id, area_id, line_id, CAST(event_start AS DATE);

-- Metric views (Databricks metric view DDL; adjust syntax per workspace runtime)
CREATE OR REPLACE VIEW industrial_ops.metrics.asset_health_score AS
SELECT
  plant_id,
  asset_id,
  asset_name,
  criticality,
  day_dt,
  health_score,
  anomaly_flag,
  vib AS vibration_avg,
  bearing_temp,
  motor_amps
FROM industrial_ops.gold.asset_health_daily;

CREATE OR REPLACE VIEW industrial_ops.metrics.anomaly_rate_7d AS
SELECT
  plant_id,
  asset_id,
  count_if(anomaly_flag) AS anomaly_days,
  count(*) AS days_observed,
  count_if(anomaly_flag) * 1.0 / count(*) AS anomaly_rate_7d
FROM industrial_ops.gold.asset_health_daily
WHERE day_dt >= date_add(current_date(), -7)
GROUP BY plant_id, asset_id;

CREATE OR REPLACE VIEW industrial_ops.metrics.mtbf_proxy AS
SELECT
  plant_id,
  asset_id,
  count(*) AS closed_failure_wos,
  avg(mttr_hours) AS avg_mttr_hours
FROM industrial_ops.gold.maintenance_outcomes
WHERE status = 'CLOSED' AND failure_code IS NOT NULL
GROUP BY plant_id, asset_id;

CREATE OR REPLACE VIEW industrial_ops.metrics.oee_by_line AS
SELECT
  plant_id,
  area_id,
  line_id,
  day_dt,
  availability_ratio,
  quality_ratio,
  availability_ratio * coalesce(quality_ratio, 1.0) AS oee_proxy
FROM industrial_ops.gold.oee_daily;
