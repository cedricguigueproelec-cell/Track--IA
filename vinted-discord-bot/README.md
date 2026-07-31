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
CHECK_INTERVAL_SECONDS=20
```

Le bot fait **une seule requête Vinted par cycle**, quel que soit le nombre
de marques suivies (elles sont toutes vérifiées en même temps). C'est ce
qui permet un intervalle aussi court sans multiplier les appels à l'API.

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
(le bot fait une recherche et prend la meilleure correspondance). Une
marque résolue avec succès est **mise en cache définitivement**
(`brand_cache.json`) : elle n'est plus jamais redemandée à Vinted, même
après un redémarrage. Si une marque refuse de se résoudre correctement
(Vinted limite les recherches de marque après quelques requêtes), vous
pouvez lui donner directement son id Vinted pour court-circuiter la
recherche :

```yaml
brands:
  - name: "The North Face"
    id: 12345          # trouvé en filtrant par marque sur vinted.fr et en
                        # lisant l'URL (?brand_ids[]=12345)
    title: "The North Face"   # optionnel, juste pour l'affichage
    max_price: 30
```

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

Tout est aussi écrit dans `bot.log` (à côté de `bot.py`), en plus de la
console — pratique pour relire ce qui s'est passé après une absence sans
avoir eu besoin de laisser la fenêtre ouverte sous les yeux.

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

### Windows — relance automatique + Planificateur de tâches

Le dossier contient déjà `run-forever.bat` : il relance le bot tout seul
s'il plante ou s'arrête, sans intervention (contrairement à un lancement
direct de `bot.py`, qui s'arrête définitivement en cas de crash imprévu).

1. Double-cliquez sur `run-forever.bat` pour le lancer manuellement, ou :
2. Pour qu'il démarre automatiquement avec Windows : **Planificateur de
   tâches** → **Créer une tâche** → déclencheur "Au démarrage de
   l'ordinateur" → action "Démarrer un programme" → pointez vers
   `run-forever.bat`.

## 7. Alternative gratuite : GitHub Actions (tourne même PC éteint)

Le dépôt contient un workflow (`.github/workflows/vinted-bot.yml`) qui fait
tourner le bot **gratuitement, sur les serveurs de GitHub**, toutes les 5
minutes (le minimum permis par GitHub), sans que votre PC ait besoin d'être
allumé. Une seule étape est nécessaire :

1. Sur GitHub, allez dans votre dépôt → **Settings** → **Secrets and
   variables** → **Actions** → **New repository secret**
   (ou directement via l'URL `https://github.com/<votre-repo>/settings/secrets/actions/new`).
2. **Name** : `DISCORD_WEBHOOK_URL`
3. **Secret** : collez votre URL de webhook Discord.
4. Cliquez **Add secret**.

C'est tout. Le workflow se déclenche automatiquement toutes les 5 minutes
(vérifiable dans l'onglet **Actions** du dépôt). Il utilise le
`config.yaml` du dépôt (donc modifiez-le et poussez sur la branche par
défaut pour changer les marques suivies) et sauvegarde l'état des annonces
déjà vues directement dans le dépôt entre deux exécutions.

⚠️ Limites à connaître :
- GitHub peut retarder légèrement les exécutions programmées en cas de forte
  charge (rarement plus de quelques minutes).
- Si le dépôt reste 60 jours sans aucune activité (aucun push), GitHub
  désactive automatiquement les workflows programmés — il suffit alors
  d'aller dans l'onglet **Actions** et de cliquer sur **"Enable workflow"**.
- Les serveurs GitHub utilisent des IP de datacenter, que Vinted peut
  bloquer plus facilement qu'une IP résidentielle. Si les exécutions
  échouent en boucle avec des erreurs 403, l'option "faire tourner sur mon
  PC/Raspberry Pi" reste la plus fiable.
- Vous pouvez aussi déclencher une exécution manuelle immédiate : onglet
  **Actions** → **Bot alertes Vinted** → **Run workflow**.

## Robustesse (pensé pour tourner sans surveillance)

- **Le bot ne s'arrête jamais tout seul** : toute erreur inattendue dans un
  cycle est journalisée puis ignorée, la boucle continue.
- **Cache de marques permanent** (`brand_cache.json`) : une marque résolue
  une fois n'est plus jamais redemandée à Vinted, même après un
  redémarrage — donc même après chaque exécution GitHub Actions, qui
  repart pourtant de zéro. Sans ce cache, une longue liste de marques
  redéclencherait la même limite anti-bot à chaque exécution.
- **Résolution étalée dans le temps** : une marque pas encore résolue
  (bloquée, mal orthographiée, ou temporairement limitée par Vinted) est
  simplement laissée de côté pour ce cycle plutôt que de bloquer le bot
  avec une longue pause — elle est retentée automatiquement toutes les
  `BRAND_RETRY_INTERVAL_SECONDS` (5 min par défaut), pendant que la
  recherche des annonces continue normalement et rapidement pour les
  marques déjà connues.
- **Jamais de résultat "leurre" accepté à tort** : si Vinted renvoie une
  correspondance approximative (`match: fallback`, signe classique d'un
  faux résultat anti-bot plutôt qu'une vraie erreur), la marque est
  ignorée pour ce cycle plutôt que mise en cache avec un id probablement
  faux.
- **Repli automatique en cas d'échecs répétés** sur la recherche
  d'annonces : l'intervalle entre les tentatives augmente progressivement
  (jusqu'à 5 min) après plusieurs échecs de suite, au lieu d'insister.
- **Reprise au démarrage** : si le réseau n'est pas encore prêt (ex: juste
  après le démarrage du PC), le bot réessaie plusieurs fois avant
  d'abandonner.
- **Logs persistants** : tout est écrit dans `bot.log` (rotation
  automatique, pas de fichier qui grossit indéfiniment), en plus de la
  console.
- **Auto-relance locale** : `run-forever.bat` (Windows) et l'unité systemd
  (Linux, `Restart=on-failure`) redémarrent le bot s'il plante.
- **Filet gratuit indépendant de votre PC** : le workflow GitHub Actions
  (section 7) tourne de son côté, même si votre machine est éteinte ou en
  vacances avec vous.

## Avant de partir : checklist en 4 points

1. **Laissez le cache de marques se remplir** : lancez `python bot.py
   --once` plusieurs fois à quelques minutes d'intervalle (ou laissez
   GitHub Actions tourner un moment). Chaque marque encore inconnue affiche
   soit `Marque résolue et mise en cache` (bon signe, définitif), soit
   `Résultat non fiable ... ignorée pour ce cycle` (sera retentée plus
   tard). Vérifiez `brand_cache.json` : une fois qu'il contient toutes vos
   marques, plus aucune requête de résolution n'est nécessaire.
2. **Pour une marque qui reste bloquée après plusieurs essais**, donnez-lui
   directement son id Vinted dans `config.yaml` (voir section 3) plutôt que
   d'attendre indéfiniment.
3. **Testez le webhook** : `python bot.py --force-notify` doit poster un
   message par marque déjà résolue dans Discord.
4. **Confirmez que GitHub Actions tourne** : onglet **Actions** du dépôt,
   au moins une exécution récente en ✅ vert. C'est ce filet-là qui continue
   de veiller même si votre PC est éteint pendant votre absence — pensez à
   `git pull` en local de temps en temps pour récupérer le cache de marques
   que GitHub Actions aura complété de son côté.

## Personnalisation

- **Ajouter/retirer une marque** : éditez `config.yaml`, relancez le bot
  (et poussez sur la branche par défaut si vous utilisez GitHub Actions).
- **Changer le pays Vinted** : `VINTED_DOMAIN` dans `.env` (`vinted.fr`,
  `vinted.de`, `vinted.be`, `vinted.it`, `vinted.es`...).
- **Vérifier plus/moins souvent** : `CHECK_INTERVAL_SECONDS` dans `.env`
  (défaut : 20s). Ne concerne que la recherche d'annonces (marques déjà
  résolues) ; si vous voyez des erreurs 403 répétées dans les logs sur la
  recherche elle-même (pas la résolution de marque), remontez cette valeur.
- **Changer la fréquence de nouvelle tentative pour les marques bloquées** :
  `BRAND_RETRY_INTERVAL_SECONDS` dans `.env` (défaut : 300s = 5 min).
- **Réinitialiser l'historique** (renvoyer toutes les annonces comme
  "nouvelles") : supprimez `seen_items.json` puis relancez.
- **Forcer une marque à se re-résoudre** (ex: après une correction
  d'orthographe) : supprimez son entrée dans `brand_cache.json` (ou tout le
  fichier pour tout re-résoudre) puis relancez.

## Dépannage

- **Erreur 401/403 en boucle sur la recherche d'annonces** : Vinted a
  probablement renforcé sa protection anti-bot pour votre IP. Le bot espace
  déjà automatiquement ses tentatives dans ce cas ; si ça persiste
  plusieurs heures, augmentez `CHECK_INTERVAL_SECONDS` ou changez de
  réseau.
- **Une marque reste bloquée pendant longtemps** ("Résultat non fiable"
  répété dans les logs) : c'est le signe que Vinted limite fortement la
  recherche de marques après quelques requêtes (observé après ~5 marques
  résolues d'affilée). Le bot réessaie tout seul toutes les 5 minutes sans
  bloquer le reste, mais si ça persiste plusieurs heures, donnez l'id
  Vinted de cette marque directement dans `config.yaml` (voir section 3)
  plutôt que d'attendre.
- **Aucune alerte ne part** : vérifiez que `DISCORD_WEBHOOK_URL` est bien
  collée en entier dans `.env` (ou dans le secret GitHub), et que le
  webhook n'a pas été supprimé côté Discord (Paramètres du salon →
  Intégrations → Webhooks).
- **"Marque introuvable sur Vinted"** ou **correspondance approximative**
  dans les logs : vérifiez l'orthographe exacte du nom dans `config.yaml`
  (celui affiché sur le filtre marque de Vinted) — si l'orthographe est
  correcte, c'est probablement le blocage anti-bot ci-dessus, pas une
  faute de frappe.
