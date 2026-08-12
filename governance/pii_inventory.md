# PII inventory — industrial_ops lakehouse

Industrial PI tags are generally non-PII. PII enters through people-linked enrichment.

## Classification

| Field | Entity | Class | Retention |
|---|---|---|---|
| technician_name, technician_email, technician_badge_id | work_orders | direct identifier | WO + 2 years |
| acked_by_name | alarms | direct identifier | alarm + 1 year |
| supervisor_*/operator_* name, email, phone, employee_id | shifts | direct identifier | 90 days operational; archive restricted |
| handoff_notes | shifts | sensitive free text | 90 days |
| crew_id, technician_employee_id (alone) | shifts / WO | quasi-identifier | align to parent entity |
| plant_id + shift + role | shifts | quasi-identifier when joined | — |
| All PI tag values | pi_timeseries | non-PII | long (engineering) |

## Storage rules

1. **Bronze** may contain PII in `*_raw` enrichment tables (access restricted).
2. **Silver** operational tables keep `*_employee_id` where needed for joins; names/emails/phones live only in `ops_pii_restricted.*`.
3. **Gold / metrics / serving_safe** must not expose direct identifiers.
4. Agent and Genie service principals use **only** `serving_safe` + `metrics`.
5. Privileged humans in `industrial_ops_pii_readers` may query `ops_pii_restricted` (masked unless group member).

## Access matrix

| Principal | bronze | silver | gold | metrics | serving_safe | ops_pii_restricted |
|---|---|---|---|---|---|---|
| `industrial_ops_engineers` | RW | RW | RW | R | R | — |
| `industrial_ops_readers` | — | — | R | R | R | — |
| `industrial_ops_pii_readers` | R (enrichment) | R | R | R | R | R (unmasked) |
| Genie / agent SP | — | — | — | R | R | **deny** |

## Audit checklist

- [ ] UC audit log enabled for catalog `industrial_ops`
- [ ] Column masks applied on email/phone/name
- [ ] Row filters by `plant_id` on PII tables
- [ ] Genie space tables = serving_safe + metrics only
- [ ] Agent tool allowlist excludes `ops_pii_restricted`
- [ ] No PII in agent prompt/debug logs (log asset_id, WO id, crew_id only)
- [ ] Shorter TTL / purge job for `shift_people` and handoff notes
