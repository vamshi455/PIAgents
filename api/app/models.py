"""PI-like time series event contracts (compatible with future PI Web API adapter)."""

from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Literal

from pydantic import BaseModel, Field


class PointQuality(str, Enum):
    GOOD = "Good"
    BAD = "Bad"
    UNCERTAIN = "Uncertain"


class TagDefinition(BaseModel):
    tag_name: str
    asset_id: str
    uom: str
    description: str
    nominal: float
    noise_pct: float = 0.02
    drift_per_hour: float = 0.0


class TimeSeriesPoint(BaseModel):
    """Canonical event emitted by the mock API and expected by Databricks bronze ingest."""

    tag_name: str = Field(..., description="PI tag / attribute path")
    asset_id: str = Field(..., description="Equipment identifier")
    timestamp: datetime = Field(..., description="Event time (UTC)")
    value: float
    quality: PointQuality = PointQuality.GOOD
    uom: str
    source_system: Literal["mock_pi", "aveva_pi"] = "mock_pi"
    plant_id: str = "PLANT-01"
    area_id: str = "AREA-COMPRESS"


class StreamStatus(BaseModel):
    streaming: bool
    interval_ms: int
    assets: int
    tags_per_asset: int
    points_emitted: int


class HealthResponse(BaseModel):
    status: Literal["ok"] = "ok"
    service: str = "pi-mock-streamer"
    version: str = "0.1.0"