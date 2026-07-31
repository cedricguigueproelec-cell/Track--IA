"""Bot de veille Vinted -> alertes Discord.

Surveille une liste de marques configurées (config.yaml) et poste dans un
salon Discord (via webhook) les nouvelles annonces en dessous du prix max
défini, dès qu'elles apparaissent sur Vinted.
"""

import logging
import os
import time

import yaml
from dotenv import load_dotenv

from discord_notifier import DiscordNotifier
from state import SeenItemsStore
from vinted_client import VintedClient

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger(__name__)


def load_config(path: str) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def resolve_brands(client: VintedClient, brands_config: list) -> dict:
    brand_ids = {}
    for brand in brands_config:
        name = brand["name"]
        brand_id = client.resolve_brand_id(name)
        if brand_id is None:
            logger.warning("Marque introuvable sur Vinted, ignorée: %s", name)
            continue
        brand_ids[name] = brand_id
        logger.info("Marque résolue: %s -> id %s", name, brand_id)
    return brand_ids


def run_cycle(
    client: VintedClient,
    notifier: DiscordNotifier,
    store: SeenItemsStore,
    brands_config: list,
    brand_ids: dict,
    default_max_price,
    notify: bool,
) -> None:
    for brand in brands_config:
        name = brand["name"]
        if name not in brand_ids:
            continue
        price_to = brand.get("max_price", default_max_price)

        try:
            items = client.search_new_items(brand_ids[name], price_to=price_to)
        except Exception:
            logger.exception("Erreur lors de la recherche Vinted pour %s", name)
            continue

        new_items = [item for item in items if not store.is_seen(item["id"])]

        # On traite du plus ancien au plus récent pour un ordre d'envoi logique.
        for item in reversed(new_items):
            store.mark_seen(item["id"])
            if not notify:
                continue
            if not item.get("url"):
                item["url"] = f"{client.base_url}/items/{item['id']}"
            try:
                notifier.send_item(item, name)
                logger.info("Alerte envoyée: [%s] %s", name, item.get("title"))
            except Exception:
                logger.exception("Erreur envoi Discord pour l'item %s", item.get("id"))
            time.sleep(1)

        time.sleep(2)


def main() -> None:
    load_dotenv()

    webhook_url = os.environ["DISCORD_WEBHOOK_URL"]
    domain = os.environ.get("VINTED_DOMAIN", "vinted.fr")
    check_interval = int(os.environ.get("CHECK_INTERVAL_SECONDS", "300"))
    config_path = os.environ.get("CONFIG_PATH", "config.yaml")
    state_path = os.environ.get("STATE_PATH", "seen_items.json")

    config = load_config(config_path)
    brands_config = config["brands"]
    default_max_price = config.get("default_max_price")

    client = VintedClient(domain=domain)
    notifier = DiscordNotifier(webhook_url)
    store = SeenItemsStore(state_path)

    brand_ids = resolve_brands(client, brands_config)
    if not brand_ids:
        logger.error("Aucune marque valide dans la config, arrêt du bot.")
        return

    logger.info(
        "Bot Vinted démarré (%d marque(s) suivie(s), vérification toutes les %ss).",
        len(brand_ids),
        check_interval,
    )

    first_pass = True
    while True:
        run_cycle(
            client,
            notifier,
            store,
            brands_config,
            brand_ids,
            default_max_price,
            notify=not first_pass,
        )
        store.save()
        if first_pass:
            logger.info("Premier passage terminé, les alertes démarrent maintenant.")
            first_pass = False
        time.sleep(check_interval)


if __name__ == "__main__":
    main()
