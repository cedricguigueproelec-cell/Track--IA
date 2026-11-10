# Optimisation Fortnite : latence minimale

Un script Windows **sûr et 100 % réversible** et le guide des réglages qui comptent
vraiment pour réduire le délai entre ton clic et l'action à l'écran.

---

## ⚠️ La vérité sur le « 0 ping / 0 delay »

**Le 0 ping n'existe pas, pour personne, même chez les pros.** Le ping, c'est le temps
d'un aller-retour entre ton PC et le serveur d'Epic. Même à la vitesse de la
lumière dans la fibre (~200 000 km/s), un aller-retour France ↔ Francfort prend
au minimum ~5-6 ms, avant même de compter la box et les équipements du FAI. **Aucun
logiciel ni tweak ne rapproche ta maison du serveur.** Les « boosters de ping »
payants sont presque toujours une arnaque.

Ce qu'on peut **vraiment** réduire :

| Source de délai | Ce qui la fait baisser | Gain possible |
|---|---|---|
| **Délai du PC** (souris → jeu → écran) | FPS élevés et stables, NVIDIA Reflex, V-Sync coupée, plein écran | **Énorme** (souvent 20 à 50 ms gagnées) |
| **Instabilité réseau** (pics, gigue, pertes) | Câble Ethernet, personne qui télécharge, bonne région | **Énorme** sur la sensation de lag |
| **Ping de base** | Fibre plutôt qu'ADSL/4G, bonne région de matchmaking | Limité par la distance |
| **Délai de l'écran** | Fréquence max (144/240 Hz), mode jeu de l'écran | Moyen |

Objectif réaliste en France avec la fibre et un câble : **10 à 25 ms de ping**, stable,
sans pertes, et un input lag au plancher.

---

## 1. Lancer le script (2 minutes)

1. Télécharge le dossier `fortnite-opti` (ou le zip), puis **clic droit sur le zip >
   Propriétés > coche « Débloquer »** avant d'extraire.
2. Ferme Fortnite et le launcher Epic.
3. Double-clic sur **`LANCER.bat`**, puis réponds **Oui** à la fenêtre administrateur.
4. Choisis **3 (Diagnostic)** d'abord pour voir ton point de départ (écran, Wi-Fi ou
   câble, ping, gigue, pertes).
5. Choisis **1 (Appliquer)**, puis **redémarre le PC**.

**Pour tout annuler :** relance `LANCER.bat` et choisis **2 (Restaurer)**. Chaque valeur
d'origine est sauvegardée dans `C:\Users\<toi>\FortniteOpti-Sauvegarde\`, et un point
de restauration Windows « Avant optimisation Fortnite » est créé en plus.

### Ce que fait le script

| Réglage | Pourquoi | Gain |
|---|---|---|
| Plan d'alimentation « Performances optimales » | Le CPU ne baisse plus sa fréquence en plein combat | Moyen (stabilité des FPS) |
| *Exception Ryzen X3D :* on garde « Utilisation normale » | Le pilote AMD en a besoin pour placer le jeu sur les cœurs avec le cache 3D | Évite une perte de FPS |
| Mode Jeu activé | Windows Update ne s'installe pas pendant la partie | Moyen |
| Enregistrement en arrière-plan de la Game Bar coupé | Il enregistre en continu et coûte des FPS | Moyen |
| Fortnite forcé sur la carte graphique dédiée | Indispensable sur PC portable (sinon il peut tourner sur le chipset) | Énorme sur portable |
| Optimisations pour les jeux fenêtrés (Windows 11) | Moins de latence en mode fenêtré | Léger |
| Accélération souris Windows coupée | Mouvement 1:1 et cohérent (menus, éditions) | Confort |
| Priorité aux jeux (planificateur multimédia) | Moins de bridage réseau et plus de temps CPU pour le jeu | Léger, sans risque |
| Économies d'énergie de la carte réseau coupées | « Green Ethernet » / EEE peut ajouter des micro-coupures | Léger à moyen |

### Ce que le script ne fait volontairement PAS (et pourquoi)

Beaucoup de « packs de tweaks » sur YouTube font plus de mal que de bien :

- **Désactiver Defender, le pare-feu ou Windows Update** : dangereux, et aucun gain réel en jeu.
- **Désactiver les protections CPU (Spectre/Meltdown), toucher à `bcdedit` (HPET,
  dynamic tick, useplatformclock)** : effets contradictoires, ça peut **augmenter** la latence.
- **Les tweaks « Nagle » / `TcpAckFrequency`** : Fortnite passe par UDP, ça ne change rien.
- **Changer de DNS** : n'a **aucun effet** sur le ping en partie.
- **Modifier les fichiers du jeu, forcer la priorité via des clés spéciales** : risque avec
  l'anti-cheat (Easy Anti-Cheat), donc risque de ban.
- **« Debloaters » et nettoyeurs de registre** : cassent Windows pour un gain nul.

---

## 2. Réglages dans Fortnite (le plus gros gain)

**Paramètres > Vidéo :**

| Réglage | Valeur |
|---|---|
| Mode de fenêtre | **Plein écran** |
| Résolution | Native de ton écran |
| Limite de FPS | Voir la règle ci-dessous |
| Mode de rendu | **Performance** (le plus réactif, idéal PC moyen/portable). DirectX 12 seulement si grosse carte (RTX 3070 / RX 6800 et plus) et que tu préfères l'image |
| Synchronisation verticale | **Désactivée** |
| Flou de mouvement | **Désactivé** |
| NVIDIA Reflex (faible latence) | **Activé + Boost** (cartes NVIDIA) |
| AMD Anti-Lag 2 | **Activé** si l'option apparaît (cartes AMD) |
| Afficher les FPS | Activé, pour vérifier |

**Règle pour la limite de FPS :**
- **Avec Reflex activé :** plafonne au nombre de FPS que ton PC **tient en permanence**,
  même en fin de partie (ex. 240 si tu ne descends jamais en dessous). Pas plus que nécessaire.
- **Sans Reflex :** plafonne 5 à 10 FPS **en dessous** de ton minimum. Une carte graphique
  bloquée à 99 % ajoute de la latence ; un plafond stable donne une sensation plus réactive
  qu'un FPS élevé qui yo-yote.

**Paramètres > Jeu :**
- **Région de matchmaking** : celle avec le ping le plus bas (Europe), pas « Auto » si
  Auto te met ailleurs.
- Active les **statistiques réseau** (cherche « Net Debug Stats » / « statistiques
  réseau » dans les paramètres) : c'est **le vrai ping** vers le serveur, avec la perte de
  paquets. C'est ce chiffre-là qui compte.

---

## 3. Réglages de la carte graphique

### NVIDIA (Panneau de configuration NVIDIA > Gérer les paramètres 3D > Fortnite)
- Mode de gestion de l'alimentation : **Performances maximales préférées**
- Synchronisation verticale : **Désactivée** (sauf si tu utilises G-Sync, voir plus bas)
- Filtrage de texture, qualité : **Haute performance**
- Mode faible latence : peu importe, **Reflex dans le jeu prend le dessus**
- Taille du cache de shaders : **Valeur par défaut du pilote** (ou 10 Go)
- Onglet *Modifier la résolution* : fréquence de rafraîchissement **au maximum**

### AMD (Logiciel AMD Adrenalin > Jeux > Fortnite)
- Radeon Anti-Lag : **Activé**
- Radeon Chill : **Désactivé** · Radeon Boost : **Désactivé**
- Enhanced Sync : **Désactivé** · Attendre la synchro verticale : **Toujours désactivé**

### Si tu as un écran G-Sync / FreeSync
Laisse G-Sync/FreeSync activé, active la V-Sync **dans le panneau du pilote** (pas en jeu)
et Reflex dans le jeu : Reflex plafonne automatiquement juste sous la fréquence de
l'écran. Zéro déchirement, latence quasi identique.

### Pilotes
Mets à jour le pilote graphique (NVIDIA App ou AMD Adrenalin), une fois par mois environ.

---

## 4. Réseau : le seul vrai levier sur le ping

1. **Câble Ethernet (RJ45) entre le PC et la box.** C'est le changement n°1 : le Wi-Fi
   crée des pics et de la gigue. Un câble Cat 6 de 10-15 m coûte moins de 10 €.
   Si vraiment impossible : CPL (moins bien) ou Wi-Fi **5 GHz** près de la box.
2. **Personne ne télécharge pendant que tu joues** : streaming 4K, mises à jour
   Windows/Steam/Epic, sauvegardes cloud (OneDrive, Google Photos). Un gros téléchargement
   sature la box et fait exploser le ping (« bufferbloat »).
   Teste-le ici : <https://www.waveform.com/tools/bufferbloat>. Une note A ou B, c'est bon ;
   C, D ou F, active la QoS / priorité gaming dans l'interface de ta box si elle en a une.
3. **Mets Windows Update en pause** pendant tes sessions (Paramètres > Windows Update >
   Suspendre).
4. **Redémarre ta box** de temps en temps.
5. **Pas de VPN** : ça ajoute un détour, donc du ping.
6. **Fibre > ADSL > 4G/5G** : si tu es en ADSL et que la fibre est disponible, c'est le
   meilleur investissement possible pour le ping.

---

## 5. Matériel et Windows

- **Écran** : vérifie qu'il tourne à sa fréquence max (le diagnostic du script te le dit).
  Un écran 144 Hz réglé à 60 Hz est une erreur très fréquente. Active le mode jeu /
  overdrive dans le menu de l'écran.
- **Souris** : taux d'interrogation (polling rate) à **1000 Hz** dans le logiciel de la souris.
  Branche-la directement sur le PC, pas sur un hub USB.
- **PC portable** : toujours **branché sur secteur**, mode « Performance » du logiciel
  constructeur (Armoury Crate, Lenovo Vantage...), écran externe si possible.
- **RAM** : si tu sais aller dans le BIOS, active le profil **XMP** (Intel) / **EXPO**
  (AMD). Sans ça, la RAM tourne souvent bien en dessous de sa vitesse ; c'est un gros gain
  de FPS sur Fortnite.
- **Arrière-plan** : ferme Chrome, les logiciels RGB inutiles, et coupe les overlays (Discord,
  Steam) pendant que tu joues. Gestionnaire des tâches > Démarrage : désactive ce qui ne sert
  à rien au lancement de Windows.

---

## Checklist rapide

- [ ] Script lancé (option 1) + PC redémarré
- [ ] Câble Ethernet
- [ ] Écran à sa fréquence max
- [ ] Fortnite : Plein écran, Mode Performance, V-Sync off, Reflex « Activé + Boost »
- [ ] Limite de FPS stable
- [ ] Bonne région de matchmaking + statistiques réseau affichées
- [ ] Pilote graphique à jour
- [ ] Personne ne télécharge pendant les parties
