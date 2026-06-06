from __future__ import annotations

from pathlib import Path
from typing import Any

from green_vigilance.config import load_config


def load_scenario(path: str | Path) -> dict[str, Any]:
    return load_config(path)
