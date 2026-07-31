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
                return set(json.loads(self.path.read_text(encoding="utf-8")))
            except (json.JSONDecodeError, OSError):
                logger.warning("Impossible de lire %s, redémarrage à vide.", self.path)
        return set()

    def is_seen(self, item_id: int) -> bool:
        return item_id in self._ids

    def is_empty(self) -> bool:
        return not self._ids

    def mark_seen(self, item_id: int) -> None:
        self._ids.add(item_id)

    def save(self) -> None:
        ids = list(self._ids)[-MAX_STORED_IDS:]
        self.path.write_text(json.dumps(ids), encoding="utf-8")


class BrandCache:
    """Mémorise durablement les marques déjà résolues (nom -> id/titre
    Vinted) pour ne plus jamais avoir à les rechercher une fois trouvées.

    Vinted limite/bloque la recherche de marques après quelques requêtes
    (anti-bot). Sans ce cache, un simple redémarrage du bot (ou chaque
    exécution GitHub Actions, qui repart de zéro) devrait tout re-résoudre
    à chaque fois et retomberait sur la même limite. Une fois une marque
    en cache, elle n'est plus jamais re-demandée à Vinted."""

    def __init__(self, path: str = "brand_cache.json"):
        self.path = Path(path)
        self._data: dict = self._load()

    def _load(self) -> dict:
        if self.path.exists():
            try:
                return json.loads(self.path.read_text(encoding="utf-8"))
            except (json.JSONDecodeError, OSError):
                logger.warning("Impossible de lire %s, cache de marques vide.", self.path)
        return {}

    def get(self, brand_name: str):
        return self._data.get(brand_name)

    def set(self, brand_name: str, id_: int, title: str) -> None:
        self._data[brand_name] = {"id": id_, "title": title}

    def save(self) -> None:
        self.path.write_text(
            json.dumps(self._data, ensure_ascii=False, indent=2), encoding="utf-8"
        )
