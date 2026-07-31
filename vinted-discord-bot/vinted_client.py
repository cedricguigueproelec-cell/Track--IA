"""Petit client pour l'API publique (non officielle) de Vinted."""

import logging
import random
from typing import Optional

import requests

logger = logging.getLogger(__name__)

USER_AGENTS = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
]


class VintedClient:
    def __init__(self, domain: str = "vinted.fr"):
        self.base_url = f"https://www.{domain}"
        self.api_url = f"{self.base_url}/api/v2"
        self.session = requests.Session()
        self.session.headers.update(
            {
                "User-Agent": random.choice(USER_AGENTS),
                "Accept": "application/json, text/plain, */*",
            }
        )
        self._warm_up()

    def _warm_up(self) -> None:
        # Vinted protège son API avec des cookies anti-bot (DataDome). Une
        # simple visite de la page d'accueil suffit à obtenir ces cookies
        # avant d'appeler l'API.
        resp = self.session.get(self.base_url, timeout=15)
        resp.raise_for_status()

    def resolve_brand_id(self, brand_name: str) -> Optional[int]:
        """Retrouve l'identifiant interne Vinted d'une marque à partir de son nom."""
        brands = self._get_json(
            f"{self.api_url}/brands", params={"search_text": brand_name}
        ).get("brands", [])

        for brand in brands:
            if brand.get("title", "").strip().lower() == brand_name.strip().lower():
                return brand.get("id")
        return brands[0]["id"] if brands else None

    def search_new_items(
        self,
        brand_id: int,
        price_to: Optional[float] = None,
        per_page: int = 20,
    ) -> list:
        params = {
            "brand_ids[]": brand_id,
            "order": "newest_first",
            "per_page": per_page,
        }
        if price_to is not None:
            params["price_to"] = price_to

        return self._get_json(f"{self.api_url}/catalog/items", params=params).get(
            "items", []
        )

    def _get_json(self, url: str, params: dict) -> dict:
        resp = self.session.get(url, params=params, timeout=15)
        if resp.status_code == 401:
            # Cookies expirés : on relance une visite de la page d'accueil.
            self._warm_up()
            resp = self.session.get(url, params=params, timeout=15)
        resp.raise_for_status()
        return resp.json()
