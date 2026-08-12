# Databricks notebook source
# MAGIC %md
# MAGIC # Apply governance: serving_safe + PII masks
# MAGIC Run after silver/gold. Execute SQL from repo files 04 and 06.

# COMMAND ----------

# MAGIC %sql
# MAGIC SHOW VIEWS IN industrial_ops.serving_safe;

# COMMAND ----------

# MAGIC %sql
# MAGIC SHOW TABLES IN industrial_ops.ops_pii_restricted;

# COMMAND ----------

print("Apply databricks/sql/04_serving_safe_views.sql and 06_pii_masks_and_filters.sql via SQL editor or bundle task.")
