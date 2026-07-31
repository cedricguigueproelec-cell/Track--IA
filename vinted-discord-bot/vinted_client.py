"""Petit client pour l'API publique (non officielle) de Vinted."""

import logging
import random
import time
from typing import Optional

import requests

logger = logging.getLogger(__name__)

USER_AGENTS = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
]

RETRYABLE_STATUS_CODES = {401, 403}


class VintedClient:
    def __init__(self, domain: str = "vinted.fr"):
        self.base_url = f"https://www.{domain}"
        self.api_url = f"{self.base_url}/api/v2"
        self.session = requests.Session()
        self.session.headers.update(
            {
                "User-Agent": random.choice(USER_AGENTS),
                "Accept": "application/json, text/plain, */*",
                "Accept-Language": "fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7",
                "Sec-Fetch-Mode": "cors",
                "Sec-Fetch-Site": "same-origin",
                "Sec-Fetch-Dest": "empty",
            }
        )
        self._warm_up()

    def _warm_up(self) -> None:
        # Vinted protège son API avec des cookies anti-bot (DataDome). Une
        # visite de la page d'accueil, puis d'une page de recherche (celle-là
        # même qui appelle l'API en arrière-plan dans un vrai navigateur),
        # permet d'obtenir les cookies nécessaires avant d'appeler l'API.
        resp = self.session.get(self.base_url, timeout=15, headers={"Sec-Fetch-Mode": "navigate"})
        resp.raise_for_status()
        time.sleep(1)
        resp = self.session.get(
            f"{self.base_url}/catalog",
            params={"search_text": ""},
            timeout=15,
            headers={"Sec-Fetch-Mode": "navigate", "Referer": self.base_url},
        )
        resp.raise_for_status()
        time.sleep(1)

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
        headers = {"Referer": f"{self.base_url}/catalog"}
        resp = self.session.get(url, params=params, headers=headers, timeout=15)
        if resp.status_code in RETRYABLE_STATUS_CODES:
            # Cookies manquants/expirés ou requête flaguée : on relance un
            # passage par les pages du site avant de réessayer une fois.
            logger.warning(
                "Réponse %s de Vinted sur %s, nouvelle tentative après re-visite du site.",
                resp.status_code,
                url,
            )
            time.sleep(2)
            self._warm_up()
            resp = self.session.get(url, params=params, headers=headers, timeout=15)
        resp.raise_for_status()
        return resp.json()
