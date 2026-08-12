# Agent tool contracts (governed)

All agents run as `sp_agent_maintenance` and may only call tools backed by `serving_safe` / `metrics`.

## Shared rules
- Log `asset_id`, `work_order_id`, `alarm_id`, `crew_id` — never email/phone/name.
- If a user asks for a person by name, refuse and suggest contacting reliability lead (PII path).
- Time windows default to last 24h unless specified.

---

## 1. Maintenance advisor agent

**Goal:** Prioritize assets needing attention and suggest next actions from health + open WOs.

### Tools
| Tool | Input | Source |
|---|---|---|
| `list_unhealthy_assets` | `plant_id`, `min_health` (default 70) | `metrics.asset_health_score` |
| `get_asset_health` | `asset_id`, `days` | `serving_safe.asset_health_daily` |
| `list_open_work_orders` | `asset_id?`, `plant_id?` | `serving_safe.work_orders` WHERE status='OPEN' |
| `get_anomaly_rate` | `asset_id` | `metrics.anomaly_rate_7d` |
| `get_mtbf_proxy` | `asset_id` | `metrics.mtbf_proxy` |

### Output shape
```json
{
  "asset_id": "PMP-12",
  "health_score": 62.4,
  "anomaly_flag": true,
  "open_wos": ["WO-1004"],
  "recommendation": "Inspect DE bearing; vibration elevated vs nominal 2.5 mm/s",
  "confidence": "medium"
}
```

---

## 2. RCA / incident agent

**Goal:** Correlate tags, alarms, and downtime around an incident window.

### Tools
| Tool | Input | Source |
|---|---|---|
| `get_alarms_in_window` | `asset_id`, `start`, `end` | `serving_safe.alarms` |
| `get_tag_series` | `asset_id`, `tag_suffix`, `start`, `end` | `serving_safe.pi_timeseries_recent` |
| `get_downtime_events` | `asset_id`, `start`, `end` | `serving_safe.oee_daily` + production via gold if exposed |
| `get_recent_failures` | `asset_id` | `serving_safe.maintenance_outcomes` |

### Output shape
```json
{
  "incident_window": {"start": "...", "end": "..."},
  "asset_id": "PMP-12",
  "alarms": ["ALM-9001"],
  "tag_signals": ["Vibration rising", "BearingTemp rising"],
  "likely_failure_code": "BRG-WEAR",
  "narrative": "..."
}
```

---

## 3. Shift briefing agent

**Goal:** Overnight summary for incoming crew without exposing personal contact data.

### Tools
| Tool | Input | Source |
|---|---|---|
| `get_shift_context` | `plant_id`, `area_id`, `as_of` | `serving_safe.shifts` |
| `list_overnight_anomalies` | `plant_id`, `hours` | `serving_safe.asset_health_daily` / alarms |
| `list_open_high_priority_wos` | `plant_id` | `serving_safe.work_orders` |
| `list_active_alarms` | `plant_id` | `serving_safe.alarms` WHERE cleared_at IS NULL |

### Output shape
```json
{
  "crew_id": "CREW-N1",
  "anomalies": [{"asset_id": "CMP-03", "signal": "VIB_HI"}],
  "open_priority_wos": ["WO-1004"],
  "handoff_notes_redacted": "...",
  "briefing": "..."
}
```

---

## Privileged escalation (human only)
Identity lookup (name/email) requires `industrial_ops_pii_readers` querying `ops_pii_restricted` — **not** exposed as an agent tool in MVP.
