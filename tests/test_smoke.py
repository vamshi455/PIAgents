"""Ensure enrichment CSVs and API modules are present (local CI smoke)."""

from __future__ import annotations

import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_enrichment_files_exist() -> None:
    enrich = ROOT / "data" / "enrichment"
    for name in (
        "assets.csv",
        "work_orders.csv",
        "alarms.csv",
        "production_events.csv",
        "shifts.csv",
    ):
        path = enrich / name
        assert path.exists(), path
        with path.open(newline="") as f:
            rows = list(csv.DictReader(f))
        assert len(rows) >= 1, name


def test_simulator_batch() -> None:
    import sys

    sys.path.insert(0, str(ROOT / "api"))
    from app.simulator import PointSimulator

    batch = PointSimulator().next_batch()
    assert len(batch) == 3 * 7  # 3 assets × 7 tags
    assert batch[0].source_system == "mock_pi"
