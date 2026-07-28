from __future__ import annotations

from abc import ABC, abstractmethod
from pathlib import Path
from typing import Any

ReportData = dict[str, Any]


class BaseProvider(ABC):
    """Provider contract used by the build pipeline.

    The renderer receives only the resolved report object. It does not know whether
    fields came from manual JSON, FiinPro, or the BSC database.
    """

    def __init__(self, project_root: Path, config: dict[str, Any]):
        self.project_root = project_root
        self.config = config

    @abstractmethod
    def load(self) -> ReportData:
        raise NotImplementedError
