# Bot d'alertes Vinted → Discord

Surveille Vinted en continu pour une liste de marques que vous choisissez
(ex: Ralph Lauren, Lacoste, Nike...) sous un prix maximum, et poste chaque
nouvelle annonce dans un salon Discord via un **webhook**. Les marques non
listées (Shein, Kiabi, etc.) ne remontent jamais, puisque le bot ne
recherche que ce que vous avez explicitement configuré.

> ⚠️ Ce bot utilise l'API publique (non officielle) de Vinted, la même que
> celle utilisée par le site web. Elle n'est pas garantie stable dans le
> temps : Vinted peut la modifier ou la bloquer sans préavis. Restez
> raisonnable sur la fréquence de vérification (`CHECK_INTERVAL_SECONDS`)
> pour ne pas vous faire bannir temporairement par leur protection anti-bot.

## 1. Créer le webhook Discord

Un webhook permet au bot de poster des messages dans un salon **sans**
créer de vraie application Discord ni gérer de token bot.

1. Ouvrez Discord, allez sur le salon où vous voulez recevoir les alertes.
2. Cliquez sur l'icône ⚙️ **Modifier le salon** (ou clic droit sur le salon
   → *Modifier le salon*).
3. Allez dans **Intégrations** → **Webhooks** → **Nouveau webhook**.
4. Donnez-lui un nom (ex: "Vinted Alertes"), choisissez le salon cible.
5. Cliquez sur **Copier l'URL du webhook**. Gardez-la précieusement, elle
   sert de "mot de passe" pour poster dans ce salon.

## 2. Installer le bot

Prérequis : [Python 3.10+](https://www.python.org/downloads/).

```bash
cd vinted-discord-bot

# Environnement virtuel (recommandé)
python3 -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate

pip install -r requirements.txt
```

## 3. Configurer

```bash
cp .env.example .env
cp config.example.yaml config.yaml
```

Éditez `.env` :

```
DISCORD_WEBHOOK_URL=<collez l'URL copiée à l'étape 1>
VINTED_DOMAIN=vinted.fr
CHECK_INTERVAL_SECONDS=300
```

Éditez `config.yaml` pour lister les marques à suivre et le prix max par
marque (les marques non listées ne sont jamais recherchées) :

```yaml
default_max_price: 20

brands:
  - name: "Ralph Lauren"
    max_price: 25
  - name: "Lacoste"
    max_price: 20
  - name: "Nike"
    max_price: 20
```

Le nom doit correspondre au nom de la marque tel qu'il apparaît sur Vinted
(le bot fait une recherche et prend la meilleure correspondance).

## 4. Tester avant de lancer en continu

Trois niveaux de test, du plus sûr au plus complet :

1. **Logique du code, sans réseau ni Discord** (rapide, à faire en premier) :
   ```bash
   python test_offline.py
   ```
   Doit afficher `Tous les tests hors-ligne sont passés.`

2. **Webhook Discord uniquement** — envoie une annonce réelle et actuelle
   par marque configurée, pour vérifier que le webhook fonctionne :
   ```bash
   python bot.py --force-notify
   ```
   Regardez le salon Discord : vous devriez voir un message par marque en
   quelques secondes. Le script s'arrête tout seul après l'envoi.

3. **Un cycle complet sans notifier** (vérifie la connexion à Vinted, la
   résolution des marques et la récupération des annonces, sans rien
   poster dans Discord) :
   ```bash
   python bot.py --once
   ```

## 5. Lancer le bot

```bash
python bot.py
```

Au premier lancement, le bot indexe les annonces déjà en ligne **sans**
les notifier (sinon vous recevriez des centaines de messages d'un coup).
À partir du deuxième passage, chaque nouvelle annonce détectée est postée
dans le salon Discord configuré.

Arrêt : `Ctrl+C`.

## 6. Le faire tourner en continu

Le script doit rester lancé pour continuer à surveiller. Quelques options :

### Linux (systemd) — recommandé sur un serveur/VPS ou Raspberry Pi

Créez `/etc/systemd/system/vinted-bot.service` :

```ini
[Unit]
Description=Bot d'alertes Vinted vers Discord
After=network-online.target

[Service]
Type=simple
WorkingDirectory=/chemin/vers/vinted-discord-bot
ExecStart=/chemin/vers/vinted-discord-bot/venv/bin/python bot.py
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Puis :

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now vinted-bot
journalctl -u vinted-bot -f    # voir les logs en direct
```

### macOS / Linux — session `screen` ou `tmux` (rapide, non persistant au redémarrage)

```bash
tmux new -s vinted-bot
source venv/bin/activate
python bot.py
# Détacher : Ctrl+B puis D. Rattacher plus tard : tmux attach -t vinted-bot
```

### Windows — Planificateur de tâches

1. Créez un fichier `run.bat` dans le dossier du bot :
   ```bat
   cd /d %~dp0
   venv\Scripts\python.exe bot.py
   ```
2. Ouvrez le **Planificateur de tâches** → **Créer une tâche** → déclencheur
   "Au démarrage de l'ordinateur" → action "Démarrer un programme" →
   pointez vers `run.bat`.

## Personnalisation

- **Ajouter/retirer une marque** : éditez `config.yaml`, relancez le bot.
- **Changer le pays Vinted** : `VINTED_DOMAIN` dans `.env` (`vinted.fr`,
  `vinted.de`, `vinted.be`, `vinted.it`, `vinted.es`...).
- **Vérifier plus/moins souvent** : `CHECK_INTERVAL_SECONDS` — évitez de
  descendre sous 120s pour ne pas déclencher la protection anti-bot de
  Vinted.
- **Réinitialiser l'historique** (renvoyer toutes les annonces comme
  "nouvelles") : supprimez `seen_items.json` puis relancez.

## Dépannage

- **Erreur 401/403 en boucle** : Vinted a probablement renforcé sa
  protection anti-bot pour votre IP. Attendez quelques minutes,
  augmentez `CHECK_INTERVAL_SECONDS`, ou changez de réseau.
- **Aucune alerte ne part** : vérifiez que `DISCORD_WEBHOOK_URL` est bien
  collée en entier dans `.env`, et que le webhook n'a pas été supprimé côté
  Discord (Paramètres du salon → Intégrations → Webhooks).
- **"Marque introuvable sur Vinted"** dans les logs : vérifiez l'orthographe
  exacte du nom dans `config.yaml` (celui affiché sur le filtre marque de
  Vinted).
