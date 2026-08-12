# Unity Catalog tag taxonomy

| Tag key | Example values | Applied to |
|---|---|---|
| `sensitivity` | `low`, `medium`, `high` | tables/columns |
| `pii` | `direct`, `quasi`, `none` | columns |
| `domain` | `pi`, `cmms`, `alarms`, `mes`, `workforce` | tables |
| `layer` | `bronze`, `silver`, `gold`, `serving` | schemas/tables |
| `retention_days` | `90`, `365`, `1825` | tables |

## Recommended column tags

```sql
-- Example
ALTER TABLE industrial_ops.ops_pii_restricted.shift_people
ALTER COLUMN operator_email SET TAGS ('pii' = 'direct', 'sensitivity' = 'high');

ALTER TABLE industrial_ops.silver.pi_timeseries
ALTER COLUMN value SET TAGS ('pii' = 'none', 'domain' = 'pi');
```
