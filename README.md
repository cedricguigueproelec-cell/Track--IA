# Track-IA RP — Serveur FiveM Roleplay

Framework RP complet et autonome pour **FiveM (GTA V)**, pensé pour être posté et
lancé rapidement, avec une économie, des métiers, une administration et des
interfaces soignées de bout en bout.

## ⚠️ À lire avant tout : GTA 6 vs FiveM

**GTA 6 n'est pas encore sorti et ne dispose d'aucun support de mods.** FiveM
(Cfx.re) ne fonctionne que sur **GTA V**. Il n'existe donc pas de "serveur FiveM
GTA 6" — quiconque vous vendrait ça vous mentirait. Ce projet est un serveur
**FiveM / GTA V** avec une direction artistique et une architecture "nouvelle
génération" (interfaces néon inspirées de l'esthétique des derniers trailers
GTA), afin de proposer la meilleure expérience possible sur la plateforme qui
existe réellement aujourd'hui. Communiquez dessus comme un serveur RP FiveM
moderne — ne prétendez jamais qu'il tourne sur GTA 6.

## Contenu du framework

- **Core** — sessions, multi-personnages, économie (cash/banque), permissions,
  callbacks serveur/client, sauvegarde auto.
- **Inventaire** — slot-based, serveur-autoritaire, coffre/boîte à gants/stash/
  objets au sol, anti-dupe (transactions atomiques, tout-ou-rien).
- **Banque** — comptes, dépôt/retrait, virements par numéro de téléphone,
  historique complet, interface ATM.
- **HUD** — vie/armure/faim/soif/stamina/voix, compteur véhicule, notifications.
- **Médical** — état "à terre", saignement, réanimation, respawn hôpital payant.
- **Police** — service, menottes, fouille/saisie, cellule, armurerie par grade,
  MDT léger (recherche citoyen/plaque), véhicules de service.
- **EMS** — service, réanimation, soins, matériel médical, ambulances.
- **Mécanicien** — réparation de véhicules sur le terrain (kit consommable).
- **Taxi** — service, compteur au kilomètre.
- **Dispatch/911** — alertes police/EMS avec blip carte, appel 911 joueur.
- **Véhicules & garages** — concession, essai, garages multiples, fourrière.
- **Logements** — achat/vente, coffre personnel par palier.
- **Téléphone** — contacts, SMS, appli banque, appel d'urgence.
- **Commerces** — 24/7, armurerie, boutique de vêtements, station essence.
- **Economie illégale** — culture/conditionnement/vente de cannabis, planque
  et chat de gang, système de prison (via la police).
- **Admin & anti-cheat** — commandes ACE (kick/ban/setjob/goto/noclip...),
  détection de vitesse/téléportation anormale et d'armes interdites.

## Démarrage rapide

1. Lire `docs/DEPLOYMENT.md` pour l'installation complète pas-à-pas.
2. Importer `sql/schema.sql` dans une base MySQL/MariaDB `utf8mb4`.
3. Copier `server.cfg` et `permissions.cfg` à la racine de votre serveur
   FXServer, renseigner les valeurs `A REMPLIR`.
4. Placer le dossier `resources/` dans votre dossier serveur.
5. Télécharger [oxmysql](https://github.com/overextended/oxmysql) dans
   `resources/[core]/oxmysql` (dépendance externe, non fournie ici).
6. Lancer le serveur, vérifier la console (aucune erreur rouge).

## Structure du dépôt

```
resources/       toutes les ressources FiveM (un dossier = un script)
sql/schema.sql   schéma complet de la base de données
server.cfg       configuration serveur prête à l'emploi
permissions.cfg  groupes ACE (admin/modérateur)
docs/            déploiement, checklist d'optimisation, guide de monétisation
```

## Personnalisation attendue avant mise en ligne

- Coordonnées des marqueurs (police/EMS/garages/commerces) — vérifiez qu'elles
  correspondent à votre carte si vous ajoutez des maps custom.
- Prix, salaires, grades — ajustez à l'économie souhaitée pour votre serveur.
- Textes de bannissement/whitelist — adaptez à votre règlement et Discord.
- Identifiants admin dans `permissions.cfg`.

## Licence / crédits

Code original écrit pour ce projet. FiveM, GTA V, Rockstar Games et Take-Two
sont des marques de leurs propriétaires respectifs — ce projet n'est ni
affilié ni approuvé par eux. Respectez les [Standards for Servers de
Cfx.re](https://fivem.net/terms) et la politique de monétisation en vigueur
(voir `docs/MONETIZATION.md`).
