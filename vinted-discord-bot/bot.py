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
from state import BrandCache, SeenItemsStore
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


def resolve_brands(client: VintedClient, brands_config: list, cache: BrandCache) -> dict:
    """name -> {'id':, 'title':} pour chaque marque de la config qu'on a pu
    identifier (via override manuel, cache, ou résolution en direct).

    Trois sources, par ordre de priorité :
    1. `id:` (+ `title:` optionnel) directement dans config.yaml — aucune
       requête réseau, utile pour une marque que Vinted refuse de résoudre
       en recherche (voir le README pour trouver l'id manuellement).
    2. Le cache disque (`brand_cache.json`) — une marque déjà résolue une
       fois n'est plus jamais redemandée à Vinted.
    3. Une recherche en direct sur `/brands`, en cas d'échec ou de résultat
       peu fiable (`match: fallback`, un signe classique de leurre
       anti-bot) la marque est simplement laissée de côté pour cette fois :
       elle sera retentée automatiquement au prochain cycle plutôt que
       d'insister avec de longues pauses bloquantes.
    """
    brand_info = {}

    for brand in brands_config:
        name = brand["name"]

        if brand.get("id") is not None:
            brand_info[name] = {"id": brand["id"], "title": brand.get("title") or name}
            continue

        cached = cache.get(name)
        if cached is not None:
            brand_info[name] = cached
            continue

        resolved = client.resolve_brand(name)

        if resolved is None:
            logger.warning("Marque introuvable sur Vinted, réessai au prochain cycle: %s", name)
            continue

        if resolved.get("match") == "fallback":
            logger.warning(
                "Résultat non fiable pour '%s' (correspondance approximative : '%s', "
                "id %s), probablement un leurre anti-bot Vinted : ignorée pour ce "
                "cycle, sera retentée automatiquement au prochain.",
                name,
                resolved.get("title"),
                resolved.get("id"),
            )
            continue

        brand_info[name] = {"id": resolved["id"], "title": resolved["title"]}
        cache.set(name, resolved["id"], resolved["title"])
        logger.info(
            "Marque résolue et mise en cache: %s -> id %s (%s)",
            name,
            resolved["id"],
            resolved["title"],
        )
        time.sleep(2)

    return brand_info


def build_brand_lookup(brand_info: dict, brands_config: list, default_max_price):
    """Retourne (by_id, by_title) : deux dicts id/titre -> {'name':, 'max_price':},
    pour reconnaître la marque d'une annonce quel que soit le champ que
    Vinted utilise dans sa réponse (id fiable en priorité, titre en repli)."""
    max_price_by_name = {
        b["name"]: b.get("max_price", default_max_price) for b in brands_config
    }
    by_id, by_title = {}, {}
    for name, info in brand_info.items():
        entry = {"name": name, "max_price": max_price_by_name.get(name)}
        if info.get("id") is not None:
            by_id[info["id"]] = entry
        title = (info.get("title") or "").strip().lower()
        if title:
            by_title[title] = entry
    return by_id, by_title


def item_brand_id(item: dict):
    if item.get("brand_id") is not None:
        return item["brand_id"]
    brand = item.get("brand")
    if isinstance(brand, dict):
        return brand.get("id")
    return None


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
    brand_lookup: tuple,
    overall_price_to,
    notify: bool,
) -> bool:
    """Retourne False si la recherche Vinted a échoué (utilisé pour le
    repli progressif en cas d'échecs répétés), True sinon."""
    by_id, by_title = brand_lookup
    all_ids = [info["id"] for info in brand_info.values()]

    if not all_ids:
        # Aucune marque résolue pour l'instant : rien à chercher ce cycle
        # (on évite surtout d'envoyer une recherche sans filtre de marque).
        return True

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

        entry = by_id.get(item_brand_id(item)) or by_title.get(
            item_brand_title(item).strip().lower()
        )
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
    brand_retry_interval = int(os.environ.get("BRAND_RETRY_INTERVAL_SECONDS", "300"))
    config_path = os.environ.get("CONFIG_PATH", "config.yaml")
    state_path = os.environ.get("STATE_PATH", "seen_items.json")
    brand_cache_path = os.environ.get("BRAND_CACHE_PATH", "brand_cache.json")
    log_path = os.environ.get("LOG_PATH", "bot.log")

    setup_logging(log_path)

    config = load_config(config_path)
    brands_config = config["brands"]
    default_max_price = config.get("default_max_price")

    client = create_client_with_retry(domain)
    notifier = DiscordNotifier(webhook_url)
    store = SeenItemsStore(state_path)
    brand_cache = BrandCache(brand_cache_path)

    def resolve_and_prepare():
        info = resolve_brands(client, brands_config, brand_cache)
        brand_cache.save()
        max_price_by_name = {
            b["name"]: b.get("max_price", default_max_price) for b in brands_config
        }
        prices = [max_price_by_name.get(name) for name in info]
        price_to = max(prices) if prices and all(p is not None for p in prices) else None
        return info, build_brand_lookup(info, brands_config, default_max_price), price_to

    brand_info, brand_lookup, overall_price_to = resolve_and_prepare()
    if not brand_info:
        logger.error(
            "Aucune marque n'a pu être résolue pour l'instant (Vinted bloque "
            "probablement les requêtes en ce moment). Le bot va quand même "
            "démarrer et réessaiera à chaque cycle."
        )

    if args.force_notify:
        if not brand_info:
            logger.error("Aucune marque résolue, rien à tester. Réessayez dans quelques minutes.")
            return
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
    last_brand_retry = time.monotonic()
    unresolved_count = len(brands_config) - len(brand_info)
    while True:
        try:
            # On ne retente les marques pas encore résolues qu'à un rythme
            # espacé (par défaut 5 min), séparé de l'intervalle rapide de
            # vérification des annonces : ça évite de marteler l'API des
            # marques (déjà à l'origine du blocage) tout en gardant les
            # cycles de recherche rapides pour les marques déjà connues.
            if unresolved_count > 0 and (time.monotonic() - last_brand_retry) >= brand_retry_interval:
                brand_info, brand_lookup, overall_price_to = resolve_and_prepare()
                unresolved_count = len(brands_config) - len(brand_info)
                last_brand_retry = time.monotonic()

            success = run_cycle(
                client,
                notifier,
                store,
                brand_info,
                brand_lookup,
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
