"""Asset/tag catalog and continuous value simulation for predictive-maintenance demo."""

from __future__ import annotations

import math
import random
from datetime import datetime, timezone

from .models import PointQuality, TagDefinition, TimeSeriesPoint

ASSETS = [
    {
        "asset_id": "PMP-12",
        "plant_id": "PLANT-01",
        "area_id": "AREA-COMPRESS",
        "name": "Feed Pump 12",
        "criticality": "A",
    },
    {
        "asset_id": "PMP-14",
        "plant_id": "PLANT-01",
        "area_id": "AREA-COMPRESS",
        "name": "Feed Pump 14",
        "criticality": "B",
    },
    {
        "asset_id": "CMP-03",
        "plant_id": "PLANT-01",
        "area_id": "AREA-COMPRESS",
        "name": "Process Compressor 03",
        "criticality": "A",
    },
]

_TAG_SPECS: list[tuple[str, str, str, float, float, float]] = [
    # tag_suffix, uom, description, nominal, noise_pct, drift_per_hour
    ("Vibration", "mm/s", "RMS vibration", 2.5, 0.08, 0.015),
    ("BearingTemp", "degC", "Drive-end bearing temperature", 65.0, 0.03, 0.02),
    ("SuctionPressure", "bar", "Suction pressure", 1.2, 0.04, 0.0),
    ("DischargePressure", "bar", "Discharge pressure", 8.5, 0.05, 0.0),
    ("MotorAmps", "A", "Motor current", 42.0, 0.06, 0.01),
    ("RunStatus", "bool", "Running=1 / Stopped=0", 1.0, 0.0, 0.0),
    ("RuntimeHours", "h", "Cumulative runtime hours", 12400.0, 0.0, 1.0),
]


def build_tag_catalog() -> list[TagDefinition]:
    tags: list[TagDefinition] = []
    for asset in ASSETS:
        aid = asset["asset_id"]
        for suffix, uom, desc, nominal, noise, drift in _TAG_SPECS:
            tags.append(
                TagDefinition(
                    tag_name=f"\\\\PLANT-01\\{aid}|{suffix}",
                    asset_id=aid,
                    uom=uom,
                    description=desc,
                    nominal=nominal,
                    noise_pct=noise,
                    drift_per_hour=drift,
                )
            )
    return tags


class PointSimulator:
    """Stateful simulator that emits slowly degrading health on critical tags."""

    def __init__(self, seed: int = 42) -> None:
        self._rng = random.Random(seed)
        self._tags = build_tag_catalog()
        self._t0 = datetime.now(timezone.utc)
        self._runtime: dict[str, float] = {
            a["asset_id"]: next(s[3] for s in _TAG_SPECS if s[0] == "RuntimeHours")
            for a in ASSETS
        }
        self._degrade: dict[str, float] = {a["asset_id"]: 0.0 for a in ASSETS}
        self.points_emitted = 0

    @property
    def tags(self) -> list[TagDefinition]:
        return self._tags

    def _asset_meta(self, asset_id: str) -> dict:
        return next(a for a in ASSETS if a["asset_id"] == asset_id)

    def next_batch(self) -> list[TimeSeriesPoint]:
        now = datetime.now(timezone.utc)
        hours = (now - self._t0).total_seconds() / 3600.0
        points: list[TimeSeriesPoint] = []

        for asset in ASSETS:
            aid = asset["asset_id"]
            # Occasional mild degradation ramp for PMP-12 (demo failure path)
            if aid == "PMP-12":
                self._degrade[aid] = min(1.0, hours * 0.02 + self._rng.uniform(0, 0.002))
            else:
                self._degrade[aid] = max(0.0, self._degrade[aid] * 0.999)

            running = 1.0 if self._rng.random() > 0.02 else 0.0
            if running:
                self._runtime[aid] += 1.0 / 3600.0  # approx if called ~1/sec; scaled in emit loop

            for tag in self._tags:
                if tag.asset_id != aid:
                    continue
                value, quality = self._value_for(tag, hours, running, self._degrade[aid])
                meta = self._asset_meta(aid)
                points.append(
                    TimeSeriesPoint(
                        tag_name=tag.tag_name,
                        asset_id=aid,
                        timestamp=now,
                        value=value,
                        quality=quality,
                        uom=tag.uom,
                        source_system="mock_pi",
                        plant_id=meta["plant_id"],
                        area_id=meta["area_id"],
                    )
                )
                self.points_emitted += 1
        return points

    def _value_for(
        self, tag: TagDefinition, hours: float, running: float, degrade: float
    ) -> tuple[float, PointQuality]:
        suffix = tag.tag_name.rsplit("|", 1)[-1]
        if suffix == "RunStatus":
            return running, PointQuality.GOOD
        if suffix == "RuntimeHours":
            return round(self._runtime[tag.asset_id], 4), PointQuality.GOOD
        if running == 0.0 and suffix in {"Vibration", "MotorAmps"}:
            return 0.0, PointQuality.GOOD

        noise = tag.nominal * tag.noise_pct * self._rng.uniform(-1, 1)
        drift = tag.drift_per_hour * hours
        # Degradation inflates vibration / temp / amps
        inflate = 0.0
        if suffix in {"Vibration", "BearingTemp", "MotorAmps"}:
            inflate = tag.nominal * degrade * (1.5 if suffix == "Vibration" else 0.8)
        # Mild sinusoidal process swing
        swing = tag.nominal * 0.01 * math.sin(hours * 2 * math.pi)
        value = tag.nominal + noise + drift + inflate + swing
        quality = PointQuality.GOOD
        if self._rng.random() < 0.001:
            quality = PointQuality.UNCERTAIN
        return round(value, 4), quality
