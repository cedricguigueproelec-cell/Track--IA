"""Bot de veille Vinted -> alertes Discord.

Surveille une liste de marques configurées (config.yaml) et poste dans un
salon Discord (via webhook) les nouvelles annonces en dessous du prix max
défini, dès qu'elles apparaissent sur Vinted.

Une seule requête Vinted par cycle couvre toutes les marques à la fois
(recherche multi-marques), ce qui permet un intervalle de vérification
court sans multiplier les appels à l'API.
"""

import argparse
import logging
import logging.handlers
import os
import time

import yaml
from dotenv import load_dotenv

from discord_notifier import DiscordNotifier
from state import SeenItemsStore
from vinted_client import VintedClient

logger = logging.getLogger(__name__)

MAX_STARTUP_ATTEMPTS = 5
MAX_BACKOFF_SECONDS = 300


def setup_logging(log_path: str) -> None:
    """Logs en console ET dans un fichier tournant, pour pouvoir relire ce
    qui s'est passé pendant une absence sans avoir laissé la fenêtre ouverte."""
    formatter = logging.Formatter("%(asctime)s [%(levelname)s] %(message)s")

    root = logging.getLogger()
    root.setLevel(logging.INFO)

    console_handler = logging.StreamHandler()
    console_handler.setFormatter(formatter)
    root.addHandler(console_handler)

    try:
        file_handler = logging.handlers.RotatingFileHandler(
            log_path, maxBytes=5 * 1024 * 1024, backupCount=3, encoding="utf-8"
        )
        file_handler.setFormatter(formatter)
        root.addHandler(file_handler)
    except OSError:
        # Pas grave si on ne peut pas écrire le fichier (ex: dossier en
        # lecture seule) : la sortie console reste disponible.
        logger.warning("Impossible d'écrire le fichier de log %s, console uniquement.", log_path)


def load_config(path: str) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def resolve_brands(client: VintedClient, brands_config: list) -> dict:
    """name -> {'id':, 'title':} pour chaque marque valide de la config.

    Vinted répond parfois par un résultat générique/factice (souvent
    "adidas") au lieu d'une vraie erreur quand il détecte un usage
    automatisé trop rapide. Un résultat "fallback" (déjà la correspondance
    la moins fiable en soi) n'est donc JAMAIS accepté directement : on
    marque une pause, on renouvelle la session, et on réessaie une fois
    avant de faire confiance au résultat — sinon la marque est ignorée
    pour ce cycle plutôt que mappée sur une valeur probablement fausse.
    """
    brand_info = {}

    for brand in brands_config:
        name = brand["name"]
        resolved = client.resolve_brand(name)

        if resolved is not None and resolved.get("match") == "fallback":
            logger.warning(
                "Résultat non fiable pour '%s' (correspondance approximative : '%s', "
                "id %s) — pause et nouvelle tentative avant d'y faire confiance.",
                name,
                resolved.get("title"),
                resolved.get("id"),
            )
            time.sleep(15)
            client.refresh_session()
            time.sleep(2)
            retry = client.resolve_brand(name)
            if retry is not None and retry.get("match") != "fallback":
                resolved = retry
            else:
                logger.error(
                    "'%s' toujours pas résolue de façon fiable après nouvelle tentative "
                    "(Vinted bloque probablement les requêtes en ce moment) : marque "
                    "ignorée pour ce cycle.",
                    name,
                )
                time.sleep(3)
                continue

        if resolved is None:
            logger.warning("Marque introuvable sur Vinted, ignorée: %s", name)
            continue

        brand_info[name] = resolved
        logger.info(
            "Marque résolue: %s -> id %s (%s)", name, resolved["id"], resolved["title"]
        )
        time.sleep(2)
    return brand_info


def build_title_lookup(brand_info: dict, brands_config: list, default_max_price) -> dict:
    """titre Vinted (minuscule) -> {'name': nom config, 'max_price':}."""
    max_price_by_name = {
        b["name"]: b.get("max_price", default_max_price) for b in brands_config
    }
    lookup = {}
    for name, info in brand_info.items():
        title = (info.get("title") or "").strip().lower()
        lookup[title] = {"name": name, "max_price": max_price_by_name.get(name)}
    return lookup


def item_brand_title(item: dict) -> str:
    if item.get("brand_title"):
        return item["brand_title"]
    brand = item.get("brand")
    if isinstance(brand, dict):
        return brand.get("title", "")
    return ""


def item_price_amount(item: dict):
    price = item.get("price")
    if isinstance(price, dict):
        try:
            return float(price.get("amount"))
        except (TypeError, ValueError):
            return None
    try:
        return float(price)
    except (TypeError, ValueError):
        return None


def run_cycle(
    client: VintedClient,
    notifier: DiscordNotifier,
    store: SeenItemsStore,
    brand_info: dict,
    title_lookup: dict,
    overall_price_to,
    notify: bool,
) -> bool:
    """Retourne False si la recherche Vinted a échoué (utilisé pour le
    repli progressif en cas d'échecs répétés), True sinon."""
    all_ids = [info["id"] for info in brand_info.values()]

    try:
        items = client.search_items_for_brands(
            all_ids, price_to=overall_price_to, per_page=96
        )
    except Exception:
        logger.exception("Erreur lors de la recherche Vinted (cycle multi-marques).")
        return False

    new_items = []
    for item in items:
        if store.is_seen(item["id"]):
            continue

        entry = title_lookup.get(item_brand_title(item).strip().lower())
        if entry is None:
            # Article d'une marque non suivie remonté par erreur : on l'ignore
            # sans le marquer vu, au cas où le filtre serveur ne l'exclurait
            # pas correctement à un prochain essai.
            continue

        max_price = entry["max_price"]
        price = item_price_amount(item)
        if max_price is not None and (price is None or price > max_price):
            store.mark_seen(item["id"])
            continue

        store.mark_seen(item["id"])
        new_items.append((entry["name"], item))

    if not notify:
        return True

    # On envoie du plus ancien au plus récent pour un ordre de lecture logique.
    for name, item in reversed(new_items):
        if not item.get("url"):
            item["url"] = f"{client.base_url}/items/{item['id']}"
        try:
            notifier.send_item(item, name)
            logger.info("Alerte envoyée: [%s] %s", name, item.get("title"))
        except Exception:
            logger.exception("Erreur envoi Discord pour l'item %s", item.get("id"))
        time.sleep(0.5)

    return True


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Bot d'alertes Vinted vers Discord.")
    parser.add_argument(
        "--once",
        action="store_true",
        help="Effectue une seule vérification puis s'arrête (pratique pour tester).",
    )
    parser.add_argument(
        "--force-notify",
        action="store_true",
        help=(
            "Envoie les notifications dès le premier passage, y compris pour des "
            "annonces déjà vues. Sert uniquement à vérifier que le webhook Discord "
            "fonctionne. À ne pas utiliser en usage normal (spam le salon)."
        ),
    )
    return parser.parse_args()


def create_client_with_retry(domain: str) -> VintedClient:
    """Se connecte à Vinted au démarrage, avec plusieurs tentatives : utile
    si le bot démarre avant que le réseau soit prêt (ex: juste après un
    redémarrage du PC ou du routeur)."""
    delay = 5
    for attempt in range(1, MAX_STARTUP_ATTEMPTS + 1):
        try:
            return VintedClient(domain=domain)
        except Exception:
            if attempt == MAX_STARTUP_ATTEMPTS:
                raise
            logger.exception(
                "Échec de connexion à Vinted au démarrage (tentative %d/%d), "
                "nouvel essai dans %ds.",
                attempt,
                MAX_STARTUP_ATTEMPTS,
                delay,
            )
            time.sleep(delay)
            delay = min(delay * 2, MAX_BACKOFF_SECONDS)
    raise RuntimeError("Impossible de joindre Vinted au démarrage.")  # pragma: no cover


def main() -> None:
    args = parse_args()
    load_dotenv()

    webhook_url = os.environ["DISCORD_WEBHOOK_URL"]
    domain = os.environ.get("VINTED_DOMAIN", "vinted.fr")
    check_interval = int(os.environ.get("CHECK_INTERVAL_SECONDS", "20"))
    config_path = os.environ.get("CONFIG_PATH", "config.yaml")
    state_path = os.environ.get("STATE_PATH", "seen_items.json")
    log_path = os.environ.get("LOG_PATH", "bot.log")

    setup_logging(log_path)

    config = load_config(config_path)
    brands_config = config["brands"]
    default_max_price = config.get("default_max_price")

    client = create_client_with_retry(domain)
    notifier = DiscordNotifier(webhook_url)
    store = SeenItemsStore(state_path)

    brand_info = resolve_brands(client, brands_config)
    if not brand_info:
        logger.error("Aucune marque valide dans la config, arrêt du bot.")
        return

    title_lookup = build_title_lookup(brand_info, brands_config, default_max_price)

    max_prices = [entry["max_price"] for entry in title_lookup.values()]
    overall_price_to = max(max_prices) if all(p is not None for p in max_prices) else None

    if args.force_notify:
        logger.warning(
            "Mode test --force-notify : envoi d'une annonce existante par marque, "
            "sans marquer d'état (juste pour vérifier le webhook Discord)."
        )
        for name, info in brand_info.items():
            price_to = next(
                (b.get("max_price") for b in brands_config if b["name"] == name),
                default_max_price,
            )
            try:
                items = client.search_new_items(info["id"], price_to=price_to, per_page=1)
            except Exception:
                logger.exception("Erreur recherche test pour %s", name)
                time.sleep(2)
                continue
            time.sleep(1)
            if not items:
                logger.info("Aucune annonce actuelle pour %s, rien à envoyer.", name)
                continue
            item = items[0]
            if not item.get("url"):
                item["url"] = f"{client.base_url}/items/{item['id']}"
            notifier.send_item(item, name)
            logger.info("Test envoyé pour %s: %s", name, item.get("title"))
            time.sleep(1)
        logger.info("Test terminé, vérifie le salon Discord.")
        return

    logger.info(
        "Bot Vinted démarré (%d marque(s) suivie(s), vérification toutes les %ss, "
        "1 requête Vinted par cycle).",
        len(brand_info),
        check_interval,
    )

    first_pass = True
    consecutive_failures = 0
    while True:
        try:
            success = run_cycle(
                client,
                notifier,
                store,
                brand_info,
                title_lookup,
                overall_price_to,
                notify=not first_pass,
            )
            consecutive_failures = 0 if success else consecutive_failures + 1
        except Exception:
            # Filet de sécurité ultime : quoi qu'il arrive, le bot ne doit
            # jamais s'arrêter tout seul pendant une absence prolongée.
            consecutive_failures += 1
            logger.exception(
                "Erreur inattendue dans le cycle (échec consécutif n°%d), on continue.",
                consecutive_failures,
            )

        try:
            store.save()
        except OSError:
            logger.exception("Impossible d'écrire %s, l'état ne sera pas persisté ce cycle.", state_path)

        if first_pass:
            logger.info("Premier passage terminé, les alertes démarrent maintenant.")
            first_pass = False
        if args.once:
            logger.info("Mode --once : arrêt après un seul passage.")
            return

        # Si Vinted bloque plusieurs fois de suite, on espace les tentatives
        # (jusqu'à 5 min) pour ne pas insister et risquer un blocage plus long.
        sleep_for = check_interval
        if consecutive_failures > 0:
            sleep_for = min(check_interval * (2 ** consecutive_failures), MAX_BACKOFF_SECONDS)
            logger.warning("Attente prolongée (%ds) suite aux échecs récents.", sleep_for)
        time.sleep(sleep_for)


if __name__ == "__main__":
    main()
