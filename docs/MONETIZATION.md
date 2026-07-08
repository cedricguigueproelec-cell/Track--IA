# Guide de monétisation — à lire avant d'ouvrir une boutique

## Le cadre légal (important, lisez avant d'encaisser le moindre euro)

FiveM appartient à Rockstar Games / Take-Two (rachat officialisé). L'usage de
la plateforme est encadré par le **Creator Platform License Agreement** de
Cfx.re/Rockstar (voir [fivem.net/terms](https://fivem.net/terms) — vérifiez la
version en vigueur au moment de votre lancement, ces règles évoluent).

Ce que les sources publiques disponibles début 2026 indiquent, de façon
constante :

- **Interdit** : vendre de la monnaie virtuelle, des loot boxes, ou tout objet
  in-game contre de l'argent réel qui procure un **avantage de gameplay**
  (pay-to-win). Vendre du "cash en jeu" ou des objets qui avantagent un joueur
  payant par rapport aux autres est une violation directe.
- **Toléré / attendu** : monétiser pour couvrir les **coûts opérationnels**
  (hébergement, nom de domaine, temps de développement) via :
  - Abonnements / paliers VIP donnant accès à une **file d'attente
    prioritaire**, un salon Discord, des **skins/tenues cosmétiques** sans
    avantage de gameplay.
  - Dons volontaires (Ko-fi, Patreon, Discord boosts...).
  - Boutique de cosmétique pur (skins de véhicules visuels only, tenues,
    animations, plaques personnalisées) — tant qu'aucun avantage chiffré
    (argent, stats, dégâts, vitesse) n'est vendu.
  - Depuis début 2026, un canal officiel existe via le **Cfx Marketplace**
    pour vendre des ressources/contenus dans un cadre validé par Cfx.re.

**Ne vendez jamais** : de l'argent en jeu, des armes/véhicules avec stats
supérieures à ce qui est accessible gratuitement, un accès à des grades
police/EMS payants, un déblocage de recettes de drogue plus rentables, etc.
Ce sont exactement les pratiques qui font blacklister un serveur de la liste
FiveM (perte totale de visibilité) voire une action légale de Rockstar.

**Avant d'encaisser un seul paiement**, relisez la page officielle des
règles à jour et, en cas de doute, restez du côté le plus conservateur
(cosmétique + confort, jamais de pouvoir).

## Ce que ce framework rend déjà possible sans violer les règles

- `players.donator_tier` (voir `sql/schema.sql`) + `Config.DonatorPerks`
  (`core/config.lua`) : structure prête pour des paliers donateur donnant
  des **slots de personnage supplémentaires** et un **bonus de poids
  d'inventaire** — un avantage de confort, pas de puissance brute. Restez
  dans cet esprit si vous étendez le système (queue prioritaire, salon
  Discord exclusif, tenues cosmétiques via la boutique de vêtements).
- La boutique de vêtements (`resources/shops`) peut recevoir des tenues
  exclusives "VIP" sans toucher à l'équilibre du jeu (armes, argent, stats).
- Le système de véhicules peut recevoir des **skins visuels** premium sans
  changer les performances du véhicule sous-jacent.

## Stratégie de lancement recommandée

1. **Phase fermée (whitelist)** : `Config.WhitelistEnabled = true`, 20-50
   joueurs triés, corrigez les bugs remontés avant l'ouverture publique.
2. **Communauté Discord** : réglement clair, candidature whitelist, support.
3. **Ouverture publique** avec annonce sur les canaux FiveM (forum Cfx.re,
   réseaux communautaires francophones RP).
4. **Monétisation progressive** : commencez par les dons volontaires, ajoutez
   des paliers VIP (queue + cosmétique) une fois une base de joueurs stable
   établie — ne monétisez pas un serveur vide, construisez d'abord la
   communauté.
5. **Réinvestissement** : hébergement plus solide, dev de contenu (nouvelles
   maps, nouveaux métiers) plutôt que retrait immédiat — la valeur d'un
   serveur RP se construit sur des mois, pas des jours.

## Outils de paiement courants (à intégrer côté site web, hors périmètre code)

- Tebex (le plus utilisé dans l'écosystème FiveM, gère la conformité TVA).
- Discord (dons/boosts, abonnements de salon).
- Ko-fi / Patreon pour les dons libres.

Aucun de ces outils n'est intégré dans le code serveur de ce dépôt (ils
opèrent via un site web + webhook, hors périmètre d'un script FiveM) — mais
la table `players.donator_tier` est prête à être mise à jour par un webhook
externe le jour où vous connectez un système de paiement.

---

**Sources consultées (à revérifier avant lancement, ces règles évoluent) :**
recherche web menée en juillet 2026 sur le Creator Platform License
Agreement de fivem.net/terms et plusieurs guides communautaires 2025-2026
sur la monétisation FiveM. Ce document ne constitue pas un avis juridique —
en cas de doute, consultez un professionnel ou le support Cfx.re directement.
