"""Source adapters: mock today; AVEVA PI Web API later without changing consumers."""

from __future__ import annotations

from abc import ABC, abstractmethod
from typing import AsyncIterator

from .models import TagDefinition, TimeSeriesPoint
from .simulator import PointSimulator


class TimeSeriesSource(ABC):
    @abstractmethod
    async def stream_points(self) -> AsyncIterator[list[TimeSeriesPoint]]:
        raise NotImplementedError

    @abstractmethod
    def list_tags(self) -> list[TagDefinition]:
        raise NotImplementedError

    @abstractmethod
    def status(self) -> dict:
        raise NotImplementedError


class MockPISource(TimeSeriesSource):
    def __init__(self, interval_ms: int = 1000, seed: int = 42) -> None:
        self.interval_ms = interval_ms
        self.simulator = PointSimulator(seed=seed)
        self._streaming = False

    def list_tags(self) -> list[TagDefinition]:
        return self.simulator.tags

    def status(self) -> dict:
        assets = {t.asset_id for t in self.simulator.tags}
        tags_per = len(self.simulator.tags) // max(len(assets), 1)
        return {
            "streaming": self._streaming,
            "interval_ms": self.interval_ms,
            "assets": len(assets),
            "tags_per_asset": tags_per,
            "points_emitted": self.simulator.points_emitted,
            "source": "mock_pi",
        }

    async def stream_points(self) -> AsyncIterator[list[TimeSeriesPoint]]:
        import asyncio

        self._streaming = True
        try:
            while True:
                yield self.simulator.next_batch()
                await asyncio.sleep(self.interval_ms / 1000.0)
        finally:
            self._streaming = False


class AvevaPIWebAPISource(TimeSeriesSource):
    """Stub for real PI Web API / PI Channels integration.

    Replace MockPISource with this adapter when plant connectivity is available.
    Expected endpoints (illustrative): streams/channel, streams/{webId}/value.
    """

    def __init__(self, base_url: str, api_key: str | None = None) -> None:
        self.base_url = base_url.rstrip("/")
        self.api_key = api_key

    def list_tags(self) -> list[TagDefinition]:
        raise NotImplementedError(
            "Wire PI Web API attribute search here; map AF attributes to TagDefinition."
        )

    def status(self) -> dict:
        return {
            "streaming": False,
            "source": "aveva_pi",
            "base_url": self.base_url,
            "configured": bool(self.api_key),
        }

    async def stream_points(self) -> AsyncIterator[list[TimeSeriesPoint]]:
        raise NotImplementedError(
            "Subscribe to PI Channels or poll GetRecordedValues; map to TimeSeriesPoint."
        )
        yield []  # pragma: no cover — makes this an async generator for type checkers
