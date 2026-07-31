"""Tests hors-ligne (mocks) pour valider la logique sans réseau réel.

Usage: python test_offline.py
"""

import tempfile
from pathlib import Path
from unittest.mock import MagicMock, patch

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
    assert params["brand_ids[]"] == 53
    assert params["price_to"] == 20
    assert params["order"] == "newest_first"
    print("OK: search_new_items construit les bons paramètres de requête")


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
    test_discord_notifier_payload()
    test_seen_items_store_roundtrip()
    print("\nTous les tests hors-ligne sont passés.")
