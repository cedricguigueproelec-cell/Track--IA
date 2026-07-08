# Checklist d'optimisation — point par point

## Performance serveur

- [x] **OneSync Infinity/Beyond activé** (`server.cfg`) — nécessaire au-delà
      de 32 joueurs, réduit la charge réseau par joueur.
- [x] **Index SQL** sur toutes les colonnes de recherche fréquente
      (`citizenid`, `identifier`, `plate`, `phone_number`, `owner_id+slot`) —
      voir `sql/schema.sql`. Sans index, une table de quelques milliers de
      lignes suffit à ralentir chaque requête de plusieurs centaines de ms.
- [x] **Requêtes DB asynchrones uniquement** (`oxmysql` `_async`) — aucune
      requête ne bloque la boucle principale du serveur.
- [x] **Rate limiting sur les callbacks** (`core/server/callbacks.lua`) —
      60 requêtes/s max par joueur, protège contre un client modifié qui
      spammerait les callbacks.
- [x] **Autosave espacé** (5 min par défaut) plutôt qu'à chaque changement —
      évite d'écrire en base à chaque frame.
- [ ] **À faire vous-même** : surveillez le `resmon` (commande `F8 > resmon`
      en jeu, ou l'onglet Performance de txAdmin) après ajout de tout script
      tiers. Un script > 0.1 ms en `always on` doit être optimisé ou retiré.
- [ ] **À faire vous-même** : limitez le nombre de `CreateThread` avec des
      `Wait(0)` — préférez `Wait(300)`+ dès que la précision à la frame
      n'est pas nécessaire (déjà appliqué dans toutes les ressources de ce
      dépôt, à respecter dans vos ajouts).
- [ ] **À faire vous-même** : si vous ajoutez des cartes (MLO/YMAP), utilisez
      un `stream` optimisé (textures compressées DXT, LODs) — la première
      cause de lag client sur les serveurs RP est le contenu additionnel mal
      optimisé, pas le framework.

## Sécurité / anti-triche

- [x] **Toute mutation d'argent passe par `Core.Functions.AddMoney/RemoveMoney`**
      côté serveur — jamais de solde modifié depuis le client.
- [x] **Inventaire serveur-autoritaire**, transferts tout-ou-rien, aucune
      opération basée sur un montant envoyé tel quel par le client sans
      validation (`Utils.IsValidAmount`, bornes de poids/slots).
- [x] **Requêtes SQL paramétrées partout** (`?` + tableau de paramètres) —
      aucune concaténation de chaîne dans une requête, donc pas d'injection
      SQL possible depuis un pseudo/message/objet.
- [x] **Anti-cheat basique actif** (`admin/server/anticheat.lua`) : vitesse
      implicite anormale, téléportation non justifiée, armes interdites.
      Journalisé dans `anticheat_flags` + alerte aux admins connectés.
- [x] **`sv_scriptHookAllowed 0`** — bloque les mod menus `.asi` classiques.
- [x] **`sv_filterRequestControl 1`** — empêche le vol de contrôle d'entité
      (exploit classique pour voler un véhicule/duper).
- [x] **Whitelist désactivable** (`Config.WhitelistEnabled` dans
      `core/config.lua`) — activez-la pendant les phases de test fermées.
- [ ] **À faire vous-même** : changez tous les identifiants admin par défaut
      dans `permissions.cfg` avant l'ouverture.
- [ ] **À faire vous-même** : activez `AdminConfig.AntiCheat.AutoKick` une
      fois les faux positifs éliminés en beta fermée (désactivé par défaut
      pour éviter de kicker des joueurs légitimes à cause du lag).
- [ ] **À faire vous-même** : sauvegardez la base de données quotidiennement
      hors du serveur de jeu (un exploit non détecté à temps doit pouvoir
      être annulé par restauration).

## Base de données

- [x] Toutes les tables en `InnoDB` + `utf8mb4` (support des accents/emoji,
      transactions, clés étrangères).
- [x] Clés étrangères avec `ON DELETE CASCADE` où pertinent (suppression
      d'un compte supprime proprement ses personnages/véhicules).
- [ ] **À faire vous-même** : au-delà de quelques centaines de joueurs
      actifs, envisagez un pool de connexions dédié et un serveur MySQL
      séparé du serveur de jeu.

## Expérience joueur (qui impacte directement la rétention/revenus)

- [x] Interfaces cohérentes, chargement rapide (NUI légères, pas de
      framework JS lourd chargé depuis un CDN — tout est en HTML/CSS/JS
      natif pour un temps d'ouverture instantané).
- [x] Messages d'erreur clairs en français à chaque action refusée (fonds
      insuffisants, permissions, inventaire plein...).
- [ ] **À faire vous-même** : rédigez un règlement clair et un guide de
      prise en main (première impression = rétention).

## Comment vérifier vous-même après toute modification

1. `F8` en jeu → `resmon` → repérez les scripts > 0.1 ms.
2. Consultez la console serveur à chaque redémarrage : zéro erreur rouge.
3. Testez avec 2-3 comptes simultanés avant chaque mise en ligne de mise à
   jour (un bug d'inventaire ou d'argent découvert après coup coûte cher en
   confiance joueur).
