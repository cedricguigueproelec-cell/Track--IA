# Guide de déploiement — Track-IA RP

## 1. Prérequis

- Un serveur Linux (recommandé) ou Windows avec au moins 4 Go de RAM libres.
- [Artifacts FXServer](https://runtime.fivem.net/artifacts/fivem/build_server_windows/master/)
  (ou `build_proot_linux` pour Linux) — prenez une version récente et stable.
- MySQL 8+ ou MariaDB 10.5+.
- Une clé serveur gratuite sur [Keymaster](https://keymaster.fivem.net)
  ("New Server" → copiez la ligne `sv_licenseKey`).
- [oxmysql](https://github.com/overextended/oxmysql) — dépendance base de
  données non incluse dans ce dépôt (licence tierce), à télécharger séparément.
- (Recommandé) [txAdmin](https://txadmin.core.re) pour l'administration, le
  monitoring de performance et les sauvegardes automatiques — livré avec
  FXServer depuis plusieurs versions.

## 2. Base de données

```bash
mysql -u root -p -e "CREATE DATABASE track_ia CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -p track_ia < sql/schema.sql
```

Créez un utilisateur dédié (ne pas utiliser `root` en production) :

```sql
CREATE USER 'trackia'@'localhost' IDENTIFIED BY 'UN_MOT_DE_PASSE_FORT';
GRANT ALL PRIVILEGES ON track_ia.* TO 'trackia'@'localhost';
FLUSH PRIVILEGES;
```

Reportez ces identifiants dans `server.cfg` → `mysql_connection_string`.

## 3. Arborescence serveur

```
mon-serveur/
├── FXServer / run.sh
├── server.cfg          <- fourni dans ce dépôt
├── permissions.cfg      <- fourni dans ce dépôt
└── resources/
    ├── [oxmysql]/oxmysql/    <- à télécharger séparément
    ├── core/
    ├── inventory/
    ├── ... (toutes les ressources de ce dépôt)
```

Copiez le contenu de `resources/` de ce dépôt dans le dossier `resources/`
de votre serveur, puis ajoutez `oxmysql` à côté (son propre dossier).

## 4. Configuration

1. Ouvrez `server.cfg` et remplacez toutes les valeurs `A_REMPLIR...`.
2. Ouvrez `permissions.cfg` et remplacez les identifiants `license:` par les
   vôtres (visibles dans la console serveur lors de votre première connexion,
   ligne `Handshake` ou via la commande `/id` une fois en jeu — cherchez
   `license:` dans les logs de connexion).
3. Adaptez `sv_hostname`, `tags`, le lien Discord.

## 5. Lancement

```bash
cd mon-serveur
./run.sh +exec server.cfg      # Linux
# ou FXServer.exe +exec server.cfg   # Windows
```

Vérifiez la console : le message `[core] Connexion base de données OK.`
doit apparaître. Toute ligne rouge `ERREUR` doit être corrigée avant d'ouvrir
le serveur au public.

## 6. Test avant ouverture publique

- Rejoignez seul, créez un personnage, vérifiez que le spawn fonctionne.
- Testez l'inventaire (TAB), la banque (ATM), le téléphone (M).
- Passez un métier police/EMS en admin (`/setjob <id> police 4`) et testez
  service, menottes, armurerie, MDT (F7).
- Testez un achat véhicule à la concession, sortie/rangement au garage.
- Testez un achat de logement et l'ouverture du coffre.
- Vérifiez les commandes admin (`/goto`, `/revive`, `/givemoney`) avec un
  compte ayant les permissions ACE.
- Redémarrez le serveur et vérifiez que l'argent/l'inventaire/la position
  ont bien été sauvegardés (autosave + sauvegarde à la déconnexion).

## 7. Mise en ligne

- Ouvrez les ports 30120 TCP **et** UDP sur votre pare-feu/routeur/hébergeur.
- Ajoutez votre serveur à la liste via Keymaster (automatique une fois
  `sv_licenseKey` valide et le serveur démarré).
- Configurez des sauvegardes automatiques de la base de données (cron
  `mysqldump` quotidien au minimum).
- Voir `docs/OPTIMIZATION.md` pour la checklist de performance/sécurité et
  `docs/MONETIZATION.md` avant d'ouvrir une boutique.
