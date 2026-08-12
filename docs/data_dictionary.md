# Enrichment data model (MVP)

Canonical mock files live in `data/enrichment/`. Databricks bronze loads them as batch (CSV → Delta).

## Entities

### `assets` (low PII)
| Column | Type | Notes |
|---|---|---|
| plant_id, area_id, unit_id, asset_id | string | Hierarchy keys |
| asset_name, asset_type, criticality | string | A/B/C criticality |
| manufacturer, install_date | string/date | |
| parent_asset_id | string | Optional |

### `work_orders` (medium PII)
| Column | Type | PII |
|---|---|---|
| work_order_id, asset_id, plant_id | string | |
| opened_at, closed_at, status, failure_code, priority | | |
| technician_employee_id, technician_name, technician_email, technician_badge_id | | **direct PII** |
| parts_used, labor_hours, notes | | notes may contain names → restricted |

### `alarms` (low–medium PII)
| Column | Type | PII |
|---|---|---|
| alarm_id, asset_id, plant_id, raised_at, cleared_at | | |
| severity, alarm_code, alarm_text | | |
| acked_by_employee_id, acked_by_name | | **direct PII** (name) |

### `production_events` (low PII)
| Column | Type | Notes |
|---|---|---|
| event_id, plant_id, area_id, line_id, asset_id | | |
| event_start, event_end, event_type, downtime_code | | |
| good_count, scrap_count, planned_count | long | OEE inputs |
| notes | string | Prefer no personal names |

### `shifts` (high PII)
| Column | Type | PII |
|---|---|---|
| shift_id, plant_id, area_id, shift_name, shift_start, shift_end, crew_id | | crew_id OK for serving |
| supervisor_* / operator_* name, email, phone, employee_id | | **direct PII** |
| handoff_notes | string | **sensitive** — may embed names |

## Serving-safe projections

Gold / Genie must use:
- `crew_id`, `technician_role` (derived), `employee_id` hashed or omitted
- Never: email, phone, badge_id, clear-text person names in default Genie space

See `governance/pii_inventory.md` and `databricks/sql/04_serving_safe_views.sql`.
