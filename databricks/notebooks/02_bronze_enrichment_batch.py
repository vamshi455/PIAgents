# Databricks notebook source
# MAGIC %md
# MAGIC # Bronze: batch load enrichment CSVs
# MAGIC Upload `data/enrichment/*.csv` to a UC volume or DBFS path, then run.

# COMMAND ----------

import os
from datetime import datetime, timezone

from pyspark.sql import functions as F

LANDING = os.environ.get(
    "ENRICHMENT_LANDING",
    "/Volumes/industrial_ops/bronze/landing/enrichment",
)
INGEST_TS = datetime.now(timezone.utc)

# COMMAND ----------

def load_csv(name: str, table: str) -> None:
    path = f"{LANDING}/{name}"
    df = (
        spark.read.option("header", True)
        .option("inferSchema", False)
        .csv(path)
        .withColumn("ingest_ts", F.lit(INGEST_TS))
        .withColumn("source_file", F.lit(name))
    )
    df.write.format("delta").mode("overwrite").option("overwriteSchema", "true").saveAsTable(
        table
    )
    print(f"Loaded {df.count()} rows -> {table}")


load_csv("assets.csv", "industrial_ops.bronze.assets_raw")
load_csv("work_orders.csv", "industrial_ops.bronze.work_orders_raw")
load_csv("alarms.csv", "industrial_ops.bronze.alarms_raw")
load_csv("production_events.csv", "industrial_ops.bronze.production_events_raw")
load_csv("shifts.csv", "industrial_ops.bronze.shifts_raw")
