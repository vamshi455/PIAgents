"""FastAPI service that continuously emits PI-like time series points."""

from __future__ import annotations

import json
import os
from typing import AsyncIterator

from fastapi import FastAPI, Query
from fastapi.responses import JSONResponse
from sse_starlette.sse import EventSourceResponse

from .adapters import MockPISource
from .models import HealthResponse, StreamStatus

INTERVAL_MS = int(os.getenv("PI_STREAM_INTERVAL_MS", "1000"))
SOURCE = MockPISource(interval_ms=INTERVAL_MS)

app = FastAPI(
    title="PI Mock Time Series API",
    description=(
        "Continuous mock AVEVA PI–style time series emitter for Databricks streaming ingest. "
        "Swap MockPISource for AvevaPIWebAPISource when connecting to a real PI System."
    ),
    version="0.1.0",
)


@app.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    return HealthResponse()


@app.get("/tags")
def list_tags() -> JSONResponse:
    return JSONResponse([t.model_dump() for t in SOURCE.list_tags()])


@app.get("/status", response_model=StreamStatus)
def stream_status() -> StreamStatus:
    s = SOURCE.status()
    return StreamStatus(
        streaming=s["streaming"],
        interval_ms=s["interval_ms"],
        assets=s["assets"],
        tags_per_asset=s["tags_per_asset"],
        points_emitted=s["points_emitted"],
    )


@app.get("/stream/points")
async def stream_points(
    interval_ms: int | None = Query(
        default=None, ge=100, le=60_000, description="Override emit interval"
    ),
) -> EventSourceResponse:
    """Server-Sent Events stream of TimeSeriesPoint batches (JSON arrays)."""

    if interval_ms is not None:
        SOURCE.interval_ms = interval_ms

    async def event_generator() -> AsyncIterator[dict]:
        async for batch in SOURCE.stream_points():
            payload = [p.model_dump(mode="json") for p in batch]
            yield {"event": "points", "data": json.dumps(payload)}

    return EventSourceResponse(event_generator())


@app.get("/snapshot/points")
def snapshot_points() -> JSONResponse:
    """One-shot batch for Databricks polling / testing without SSE."""
    batch = SOURCE.simulator.next_batch()
    return JSONResponse([p.model_dump(mode="json") for p in batch])
