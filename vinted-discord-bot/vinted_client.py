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

    def resolve_brand(self, brand_name: str) -> Optional[dict]:
        """Retrouve {'id':, 'title':} d'une marque Vinted à partir de son nom."""
        brands = self._get_json(
            f"{self.api_url}/brands", params={"search_text": brand_name}
        ).get("brands", [])

        if not brands:
            return None

        needle = brand_name.strip().lower()

        for brand in brands:
            if brand.get("title", "").strip().lower() == needle:
                return {"id": brand.get("id"), "title": brand.get("title")}

        for brand in brands:
            title = brand.get("title", "").strip().lower()
            if needle in title or title in needle:
                logger.warning(
                    "Pas de correspondance exacte pour '%s', marque '%s' (id %s) "
                    "utilisée par correspondance partielle.",
                    brand_name,
                    brand.get("title"),
                    brand.get("id"),
                )
                return {"id": brand.get("id"), "title": brand.get("title")}

        best = brands[0]
        logger.warning(
            "Pas de correspondance pour '%s' : la recherche Vinted n'a rien retourné "
            "de proche. Marque '%s' (id %s, 1er résultat) utilisée par défaut, ce qui "
            "est probablement FAUX. Vérifiez l'orthographe exacte dans config.yaml.",
            brand_name,
            best.get("title"),
            best.get("id"),
        )
        return {"id": best.get("id"), "title": best.get("title")}

    def resolve_brand_id(self, brand_name: str) -> Optional[int]:
        """Retrouve l'identifiant interne Vinted d'une marque à partir de son nom."""
        brand = self.resolve_brand(brand_name)
        return brand["id"] if brand else None

    def search_new_items(
        self,
        brand_id: int,
        price_to: Optional[float] = None,
        per_page: int = 20,
    ) -> list:
        return self.search_items_for_brands([brand_id], price_to=price_to, per_page=per_page)

    def search_items_for_brands(
        self,
        brand_ids: list,
        price_to: Optional[float] = None,
        per_page: int = 96,
    ) -> list:
        """Une seule requête couvrant plusieurs marques à la fois (rapide, peu
        de requêtes = moins de risque de blocage anti-bot)."""
        params = {
            "brand_ids[]": brand_ids,
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
