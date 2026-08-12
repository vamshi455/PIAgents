# Databricks notebook source
# MAGIC %md
# MAGIC # Silver + Gold transforms
# MAGIC Runs curated SQL scripts. Prefer `%run` of SQL files or execute via Job task.

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Execute silver DDL/DML from repo: databricks/sql/03_silver_tables.sql
# MAGIC -- In CI/CD, use Databricks Asset Bundles or `databricks bundle run`.
# MAGIC SELECT 'Run 03_silver_tables.sql then 05_gold_and_metrics.sql' AS next_step;

# COMMAND ----------

spark.sql("SHOW TABLES IN industrial_ops.silver").show(truncate=False)
spark.sql("SHOW TABLES IN industrial_ops.gold").show(truncate=False)
