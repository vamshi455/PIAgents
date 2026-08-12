# Databricks notebook source
# MAGIC %md
# MAGIC # Bronze: PI time series streaming ingest
# MAGIC Polls the mock PI API `/snapshot/points` (or consume SSE externally into Kafka) and appends to bronze.

# COMMAND ----------

import json
import os
import urllib.request
from datetime import datetime, timezone

from pyspark.sql import functions as F
from pyspark.sql.types import (
    DoubleType,
    StringType,
    StructField,
    StructType,
    TimestampType,
)

PI_API_BASE = os.environ.get("PI_API_BASE", "http://host.docker.internal:8080")
CHECKPOINT = os.environ.get(
    "PI_BRONZE_CHECKPOINT",
    "/Volumes/industrial_ops/bronze/landing/checkpoints/pi_timeseries",
)
BRONZE_TABLE = "industrial_ops.bronze.pi_timeseries_raw"

schema = StructType(
    [
        StructField("tag_name", StringType()),
        StructField("asset_id", StringType()),
        StructField("timestamp", StringType()),
        StructField("value", DoubleType()),
        StructField("quality", StringType()),
        StructField("uom", StringType()),
        StructField("source_system", StringType()),
        StructField("plant_id", StringType()),
        StructField("area_id", StringType()),
    ]
)

# COMMAND ----------

def fetch_snapshot(base_url: str) -> list[dict]:
    with urllib.request.urlopen(f"{base_url.rstrip('/')}/snapshot/points", timeout=30) as resp:
        return json.loads(resp.read().decode("utf-8"))


# For Structured Streaming from a rate source that triggers pulls each micro-batch:
rate = spark.readStream.format("rate").option("rowsPerSecond", 1).load()

# COMMAND ----------

def write_batch(batch_df, batch_id: int) -> None:
    try:
        points = fetch_snapshot(PI_API_BASE)
    except Exception as exc:  # noqa: BLE001 — surface in driver logs
        print(f"batch={batch_id} fetch failed: {exc}")
        return
    if not points:
        return
    pdf = spark.createDataFrame(points, schema=schema)
    out = (
        pdf.withColumn("event_ts", F.to_timestamp("timestamp"))
        .withColumn("ingest_ts", F.lit(datetime.now(timezone.utc)))
        .withColumn("raw_payload", F.to_json(F.struct(*[F.col(c) for c in pdf.columns])))
        .drop("timestamp")
        .select(
            "tag_name",
            "asset_id",
            "event_ts",
            "value",
            "quality",
            "uom",
            "source_system",
            "plant_id",
            "area_id",
            "ingest_ts",
            "raw_payload",
        )
    )
    out.write.format("delta").mode("append").saveAsTable(BRONZE_TABLE)


(
    rate.writeStream.foreachBatch(write_batch)
    .option("checkpointLocation", CHECKPOINT)
    .trigger(processingTime="5 seconds")
    .start()
)
