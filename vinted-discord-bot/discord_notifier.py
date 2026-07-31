"""Envoi des alertes vers un salon Discord via webhook."""

import logging
import time

import requests

logger = logging.getLogger(__name__)

EMBED_COLOR = 0x09B1BA


class DiscordNotifier:
    def __init__(self, webhook_url: str):
        self.webhook_url = webhook_url

    def send_item(self, item: dict, brand_name: str) -> None:
        price = item.get("price")
        if isinstance(price, dict):
            amount = price.get("amount")
            currency = price.get("currency_code", "EUR")
        else:
            amount = price
            currency = "EUR"

        photo_url = None
        photo = item.get("photo")
        if isinstance(photo, dict):
            photo_url = photo.get("url") or photo.get("full_size_url")

        embed = {
            "title": (item.get("title") or "Nouvelle annonce Vinted")[:256],
            "url": item.get("url"),
            "color": EMBED_COLOR,
            "fields": [
                {"name": "Marque", "value": brand_name, "inline": True},
                {"name": "Prix", "value": f"{amount} {currency}", "inline": True},
                {
                    "name": "Taille",
                    "value": item.get("size_title") or "N/A",
                    "inline": True,
                },
            ],
        }
        if photo_url:
            embed["thumbnail"] = {"url": photo_url}

        self._post({"embeds": [embed]})

    def _post(self, payload: dict) -> None:
        resp = requests.post(self.webhook_url, json=payload, timeout=15)
        if resp.status_code == 429:
            retry_after = resp.json().get("retry_after", 1)
            logger.warning("Rate limit Discord, nouvelle tentative dans %.1fs", retry_after)
            time.sleep(retry_after)
            resp = requests.post(self.webhook_url, json=payload, timeout=15)
        if not resp.ok:
            logger.error("Erreur webhook Discord %s: %s", resp.status_code, resp.text)
