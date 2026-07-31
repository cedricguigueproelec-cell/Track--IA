"""Tests hors-ligne (mocks) pour valider la logique sans réseau réel.

Usage: python test_offline.py
"""

import tempfile
from pathlib import Path
from unittest.mock import MagicMock, patch

import bot
from discord_notifier import DiscordNotifier
from state import BrandCache, SeenItemsStore
from vinted_client import VintedClient


def test_resolve_brand_id():
    with patch.object(VintedClient, "_warm_up", return_value=None):
        client = VintedClient(domain="vinted.fr")

    fake_response = MagicMock()
    fake_response.status_code = 200
    fake_response.json.return_value = {
        "brands": [
            {"id": 88, "title": "Nike"},
            {"id": 99, "title": "Nike Golf"},
        ]
    }
    fake_response.raise_for_status.return_value = None

    with patch.object(client.session, "get", return_value=fake_response) as mock_get:
        brand_id = client.resolve_brand_id("Nike")

    assert brand_id == 88, f"Attendu 88, obtenu {brand_id}"
    called_url = mock_get.call_args[0][0]
    assert called_url.endswith("/brands")
    print("OK: resolve_brand_id trouve le bon id de marque")


def test_search_new_items_params():
    with patch.object(VintedClient, "_warm_up", return_value=None):
        client = VintedClient(domain="vinted.fr")

    fake_response = MagicMock()
    fake_response.status_code = 200
    fake_response.json.return_value = {
        "items": [{"id": 1, "title": "Polo Ralph Lauren"}]
    }
    fake_response.raise_for_status.return_value = None

    with patch.object(client.session, "get", return_value=fake_response) as mock_get:
        items = client.search_new_items(brand_id=53, price_to=20)

    assert items == [{"id": 1, "title": "Polo Ralph Lauren"}]
    params = mock_get.call_args.kwargs["params"]
    assert params["brand_ids[]"] == [53]
    assert params["price_to"] == 20
    assert params["order"] == "newest_first"
    print("OK: search_new_items construit les bons paramètres de requête")


def test_search_items_for_brands_multi():
    with patch.object(VintedClient, "_warm_up", return_value=None):
        client = VintedClient(domain="vinted.fr")

    fake_response = MagicMock()
    fake_response.status_code = 200
    fake_response.json.return_value = {"items": [{"id": 1}, {"id": 2}]}
    fake_response.raise_for_status.return_value = None

    with patch.object(client.session, "get", return_value=fake_response) as mock_get:
        items = client.search_items_for_brands([53, 304, 88], price_to=25)

    assert len(items) == 2
    params = mock_get.call_args.kwargs["params"]
    assert params["brand_ids[]"] == [53, 304, 88]
    assert params["price_to"] == 25
    print("OK: search_items_for_brands regroupe plusieurs marques en une requête")


def test_run_cycle_dispatches_by_brand_and_filters_price():
    brand_info = {
        "Nike": {"id": 53, "title": "Nike"},
        "Lacoste": {"id": 304, "title": "Lacoste"},
    }
    brands_config = [
        {"name": "Nike", "max_price": 20},
        {"name": "Lacoste", "max_price": 15},
    ]
    brand_lookup = bot.build_brand_lookup(brand_info, brands_config, default_max_price=None)

    items = [
        {"id": 1, "brand_title": "Nike", "price": {"amount": "18", "currency_code": "EUR"}, "title": "Nike OK"},
        {"id": 2, "brand_title": "Nike", "price": {"amount": "45", "currency_code": "EUR"}, "title": "Nike trop cher"},
        {"id": 3, "brand_title": "Lacoste", "price": {"amount": "10", "currency_code": "EUR"}, "title": "Lacoste OK"},
        {"id": 4, "brand_title": "Shein", "price": {"amount": "5", "currency_code": "EUR"}, "title": "Marque non suivie"},
    ]

    client = MagicMock()
    client.search_items_for_brands.return_value = items
    client.base_url = "https://www.vinted.fr"

    notifier = MagicMock()
    store = SeenItemsStore(str(Path(tempfile.mkdtemp()) / "seen.json"))

    bot.run_cycle(client, notifier, store, brand_info, brand_lookup, overall_price_to=20, notify=True)

    sent_titles = {call.args[0].get("title") for call in notifier.send_item.call_args_list}
    assert sent_titles == {"Nike OK", "Lacoste OK"}, sent_titles
    assert store.is_seen(1) and store.is_seen(2) and store.is_seen(3) and not store.is_seen(4)
    print("OK: run_cycle envoie seulement les bonnes marques sous leur prix max")


def test_run_cycle_matches_by_brand_id_when_title_missing():
    """Si Vinted ne renvoie pas brand_title mais un id, le matching doit
    quand même fonctionner (utile pour les marques ajoutées via id: manuel
    dans config.yaml, sans titre Vinted connu)."""
    brand_info = {"MaMarque": {"id": 999, "title": "MaMarque"}}
    brands_config = [{"name": "MaMarque", "max_price": 50}]
    brand_lookup = bot.build_brand_lookup(brand_info, brands_config, default_max_price=None)

    items = [{"id": 1, "brand_id": 999, "price": {"amount": "10", "currency_code": "EUR"}, "title": "Trouvé par id"}]

    client = MagicMock()
    client.search_items_for_brands.return_value = items
    client.base_url = "https://www.vinted.fr"
    notifier = MagicMock()
    store = SeenItemsStore(str(Path(tempfile.mkdtemp()) / "seen.json"))

    bot.run_cycle(client, notifier, store, brand_info, brand_lookup, overall_price_to=None, notify=True)

    notifier.send_item.assert_called_once()
    print("OK: run_cycle reconnaît une marque par id même sans brand_title")


def test_resolve_brands_uses_cache_and_manual_override():
    """Une marque en cache ou avec un id manuel ne doit jamais déclencher
    d'appel réseau ; une marque avec un résultat 'fallback' (non fiable,
    ex: leurre anti-bot) doit être laissée de côté pour ce cycle plutôt
    que d'être acceptée telle quelle."""
    client = MagicMock()
    client.resolve_brand.side_effect = [
        {"id": 1, "title": "Nike", "match": "exact"},
        {"id": 14, "title": "adidas", "match": "fallback"},
    ]

    cache = BrandCache(str(Path(tempfile.mkdtemp()) / "brand_cache.json"))
    cache.set("Lacoste", 304, "Lacoste")

    brands_config = [
        {"name": "Nike"},  # à résoudre en direct
        {"name": "Lacoste"},  # déjà en cache
        {"name": "The North Face", "id": 777, "title": "The North Face"},  # override manuel
        {"name": "Introuvable"},  # renvoie un résultat non fiable
    ]

    with patch("bot.time.sleep"):
        brand_info = bot.resolve_brands(client, brands_config, cache)

    assert brand_info["Nike"]["id"] == 1
    assert brand_info["Lacoste"]["id"] == 304
    assert brand_info["The North Face"]["id"] == 777
    assert "Introuvable" not in brand_info, "un résultat non fiable ne doit jamais être accepté"
    assert client.resolve_brand.call_count == 2, "Lacoste (cache) et The North Face (override) ne doivent pas appeler l'API"
    assert cache.get("Nike") == {"id": 1, "title": "Nike"}, "un succès doit être mis en cache"
    print("OK: resolve_brands utilise le cache/l'override et ignore les résultats non fiables")


def test_discord_notifier_payload():
    notifier = DiscordNotifier(webhook_url="https://discord.com/api/webhooks/fake/fake")

    item = {
        "id": 42,
        "title": "Pull Lacoste vintage",
        "url": "https://www.vinted.fr/items/42",
        "price": {"amount": "15.0", "currency_code": "EUR"},
        "size_title": "M",
        "photo": {"url": "https://example.com/photo.jpg"},
    }

    fake_response = MagicMock()
    fake_response.ok = True
    fake_response.status_code = 200

    with patch("discord_notifier.requests.post", return_value=fake_response) as mock_post:
        notifier.send_item(item, brand_name="Lacoste")

    payload = mock_post.call_args.kwargs["json"]
    embed = payload["embeds"][0]
    assert embed["title"] == "Pull Lacoste vintage"
    assert embed["url"] == "https://www.vinted.fr/items/42"
    assert {"name": "Prix", "value": "15.0 EUR", "inline": True} in embed["fields"]
    assert embed["thumbnail"]["url"] == "https://example.com/photo.jpg"
    print("OK: DiscordNotifier construit un embed correct")


def test_seen_items_store_roundtrip():
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "seen.json"
        store = SeenItemsStore(str(path))
        assert not store.is_seen(1)
        store.mark_seen(1)
        store.mark_seen(2)
        store.save()

        reloaded = SeenItemsStore(str(path))
        assert reloaded.is_seen(1)
        assert reloaded.is_seen(2)
        assert not reloaded.is_seen(3)
    print("OK: SeenItemsStore persiste et recharge correctement")


def test_seen_items_store_is_empty_reflects_prior_runs():
    """is_empty() doit refléter l'état chargé du disque, pas le fait que le
    processus vient de démarrer : c'est ce qui permet à bot.py de savoir si
    c'est vraiment le tout premier lancement (pas de notification, pour
    éviter un flood) ou une relance normale (notifier dès le 1er cycle) -
    important pour GitHub Actions, qui relance un processus neuf à chaque
    exécution et n'aurait donc jamais aucune vraie alerte sans ça."""
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "seen.json"

        fresh_store = SeenItemsStore(str(path))
        assert fresh_store.is_empty(), "un tout premier lancement doit être détecté comme vide"

        fresh_store.mark_seen(1)
        fresh_store.save()

        restarted_store = SeenItemsStore(str(path))
        assert not restarted_store.is_empty(), "un état déjà existant ne doit pas repasser à vide au redémarrage"
    print("OK: SeenItemsStore.is_empty() distingue premier lancement et redémarrage")


if __name__ == "__main__":
    test_resolve_brand_id()
    test_search_new_items_params()
    test_search_items_for_brands_multi()
    test_resolve_brands_uses_cache_and_manual_override()
    test_run_cycle_dispatches_by_brand_and_filters_price()
    test_run_cycle_matches_by_brand_id_when_title_missing()
    test_discord_notifier_payload()
    test_seen_items_store_roundtrip()
    test_seen_items_store_is_empty_reflects_prior_runs()
    print("\nTous les tests hors-ligne sont passés.")
