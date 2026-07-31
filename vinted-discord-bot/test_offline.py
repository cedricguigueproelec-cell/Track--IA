"""Tests hors-ligne (mocks) pour valider la logique sans réseau réel.

Usage: python test_offline.py
"""

import tempfile
from pathlib import Path
from unittest.mock import MagicMock, patch

import bot
from discord_notifier import DiscordNotifier
from state import SeenItemsStore
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
    title_lookup = bot.build_title_lookup(brand_info, brands_config, default_max_price=None)

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

    bot.run_cycle(client, notifier, store, brand_info, title_lookup, overall_price_to=20, notify=True)

    sent_titles = {call.args[0].get("title") for call in notifier.send_item.call_args_list}
    assert sent_titles == {"Nike OK", "Lacoste OK"}, sent_titles
    assert store.is_seen(1) and store.is_seen(2) and store.is_seen(3) and not store.is_seen(4)
    print("OK: run_cycle envoie seulement les bonnes marques sous leur prix max")


def test_resolve_brands_never_trusts_fallback_without_retry():
    """Un résultat 'fallback' (correspondance non fiable, ex: leurre
    anti-bot type 'toujours adidas') ne doit jamais être accepté tel quel :
    le bot doit rafraîchir sa session et réessayer avant de faire
    confiance, et exclure la marque si le nouvel essai est encore mauvais."""
    client = MagicMock()
    client.resolve_brand.side_effect = [
        {"id": 1, "title": "Nike", "match": "exact"},
        {"id": 14, "title": "adidas", "match": "fallback"},  # Introuvable, 1er essai
        {"id": 14, "title": "adidas", "match": "fallback"},  # Introuvable, réessai -> toujours mauvais
        {"id": 14, "title": "adidas", "match": "fallback"},  # Carhartt, 1er essai
        {"id": 77, "title": "Carhartt", "match": "exact"},  # Carhartt, réessai -> bon résultat
    ]

    with patch("bot.time.sleep"):
        brand_info = bot.resolve_brands(
            client,
            [{"name": "Nike"}, {"name": "Introuvable"}, {"name": "Carhartt"}],
        )

    assert brand_info["Nike"]["id"] == 1
    assert brand_info["Carhartt"]["id"] == 77, "doit utiliser le résultat du réessai, pas le leurre"
    assert "Introuvable" not in brand_info, "un résultat resté suspect après réessai ne doit jamais être accepté"
    assert client.refresh_session.call_count == 2
    print("OK: resolve_brands ne fait jamais confiance à un résultat 'fallback' sans vérification")


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


if __name__ == "__main__":
    test_resolve_brand_id()
    test_search_new_items_params()
    test_search_items_for_brands_multi()
    test_resolve_brands_never_trusts_fallback_without_retry()
    test_run_cycle_dispatches_by_brand_and_filters_price()
    test_discord_notifier_payload()
    test_seen_items_store_roundtrip()
    print("\nTous les tests hors-ligne sont passés.")
