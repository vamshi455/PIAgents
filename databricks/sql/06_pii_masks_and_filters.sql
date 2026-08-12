-- Column masks, row filters, tags, and grants for PII governance

-- Tags (apply in UC; syntax may vary by runtime — illustrative)
ALTER TABLE industrial_ops.ops_pii_restricted.work_order_people
SET TAGS ('sensitivity' = 'high', 'domain' = 'cmms');

ALTER TABLE industrial_ops.ops_pii_restricted.shift_people
SET TAGS ('sensitivity' = 'high', 'domain' = 'workforce');

ALTER TABLE industrial_ops.ops_pii_restricted.alarm_ack_people
SET TAGS ('sensitivity' = 'medium', 'domain' = 'alarms');

-- Column masks: non-privileged users see redaction
CREATE OR REPLACE FUNCTION industrial_ops.ops_pii_restricted.mask_email(email STRING)
RETURNS STRING
RETURN CASE
  WHEN is_account_group_member('industrial_ops_pii_readers') THEN email
  ELSE regexp_replace(email, '(^.).*(@.*$)', '$1***$2')
END;

CREATE OR REPLACE FUNCTION industrial_ops.ops_pii_restricted.mask_phone(phone STRING)
RETURNS STRING
RETURN CASE
  WHEN is_account_group_member('industrial_ops_pii_readers') THEN phone
  ELSE '***-***-' || right(phone, 4)
END;

CREATE OR REPLACE FUNCTION industrial_ops.ops_pii_restricted.mask_name(name STRING)
RETURNS STRING
RETURN CASE
  WHEN is_account_group_member('industrial_ops_pii_readers') THEN name
  ELSE 'REDACTED'
END;

ALTER TABLE industrial_ops.ops_pii_restricted.work_order_people
ALTER COLUMN technician_email SET MASK industrial_ops.ops_pii_restricted.mask_email;

ALTER TABLE industrial_ops.ops_pii_restricted.work_order_people
ALTER COLUMN technician_name SET MASK industrial_ops.ops_pii_restricted.mask_name;

ALTER TABLE industrial_ops.ops_pii_restricted.shift_people
ALTER COLUMN supervisor_email SET MASK industrial_ops.ops_pii_restricted.mask_email;

ALTER TABLE industrial_ops.ops_pii_restricted.shift_people
ALTER COLUMN operator_email SET MASK industrial_ops.ops_pii_restricted.mask_email;

ALTER TABLE industrial_ops.ops_pii_restricted.shift_people
ALTER COLUMN supervisor_phone SET MASK industrial_ops.ops_pii_restricted.mask_phone;

ALTER TABLE industrial_ops.ops_pii_restricted.shift_people
ALTER COLUMN operator_phone SET MASK industrial_ops.ops_pii_restricted.mask_phone;

ALTER TABLE industrial_ops.ops_pii_restricted.shift_people
ALTER COLUMN supervisor_name SET MASK industrial_ops.ops_pii_restricted.mask_name;

ALTER TABLE industrial_ops.ops_pii_restricted.shift_people
ALTER COLUMN operator_name SET MASK industrial_ops.ops_pii_restricted.mask_name;

-- Row filter by plant tenancy
CREATE OR REPLACE FUNCTION industrial_ops.ops_pii_restricted.plant_filter(plant_id STRING)
RETURNS BOOLEAN
RETURN (
  is_account_group_member('industrial_ops_pii_readers')
  OR is_account_group_member(concat('plant_', plant_id))
);

ALTER TABLE industrial_ops.ops_pii_restricted.shift_people
SET ROW FILTER industrial_ops.ops_pii_restricted.plant_filter ON (plant_id);

ALTER TABLE industrial_ops.ops_pii_restricted.work_order_people
SET ROW FILTER industrial_ops.ops_pii_restricted.plant_filter ON (plant_id);

-- Grants (create groups in account console first)
-- GRANT USE CATALOG ON CATALOG industrial_ops TO `industrial_ops_readers`;
-- GRANT USE SCHEMA ON SCHEMA industrial_ops.serving_safe TO `industrial_ops_readers`;
-- GRANT SELECT ON SCHEMA industrial_ops.serving_safe TO `industrial_ops_readers`;
-- GRANT SELECT ON SCHEMA industrial_ops.metrics TO `industrial_ops_readers`;
-- GRANT USE SCHEMA ON SCHEMA industrial_ops.ops_pii_restricted TO `industrial_ops_pii_readers`;
-- GRANT SELECT ON SCHEMA industrial_ops.ops_pii_restricted TO `industrial_ops_pii_readers`;
-- REVOKE ALL PRIVILEGES ON SCHEMA industrial_ops.ops_pii_restricted FROM `industrial_ops_readers`;
