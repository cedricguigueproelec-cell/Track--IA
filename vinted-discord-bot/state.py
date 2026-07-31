"""Persistance des annonces déjà notifiées, pour éviter les doublons."""

import json
import logging
from pathlib import Path
from typing import Set

logger = logging.getLogger(__name__)

MAX_STORED_IDS = 3000


class SeenItemsStore:
    def __init__(self, path: str = "seen_items.json"):
        self.path = Path(path)
        self._ids: Set[int] = self._load()

    def _load(self) -> Set[int]:
        if self.path.exists():
            try:
                return set(json.loads(self.path.read_text()))
            except (json.JSONDecodeError, OSError):
                logger.warning("Impossible de lire %s, redémarrage à vide.", self.path)
        return set()

    def is_seen(self, item_id: int) -> bool:
        return item_id in self._ids

    def mark_seen(self, item_id: int) -> None:
        self._ids.add(item_id)

    def save(self) -> None:
        ids = list(self._ids)[-MAX_STORED_IDS:]
        self.path.write_text(json.dumps(ids))
