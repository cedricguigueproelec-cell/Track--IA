# Optimisation Fortnite v2 : ping, latence, FPS

Un outil Windows **en un clic**, **sûr et 100 % réversible**, plus le guide des réglages
qui comptent vraiment pour réduire le délai entre ton clic et l'action à l'écran.

---

## ⚠️ La vérité sur le « 0 ping / 0 delay »

**Le 0 ping n'existe pas, pour personne, même chez les pros.** Le ping, c'est le temps
d'un aller-retour entre ton PC et le serveur d'Epic. Même à la vitesse de la
lumière dans la fibre, un aller-retour France ↔ Francfort prend au minimum ~5-6 ms,
avant même de compter la box et le réseau du FAI. **Aucun logiciel ne rapproche ta
maison du serveur.** Les « boosters de ping » payants sont presque toujours une arnaque.

Ce qu'on peut **vraiment** réduire, et ce que fait cet outil :

| Source de délai | Ce qui la fait baisser | Gain possible |
|---|---|---|
| **Délai du PC** (souris → jeu → écran) | FPS élevés et stables, Reflex, V-Sync coupée, plein écran | **Énorme** (souvent 20 à 50 ms) |
| **Instabilité réseau** (pics, gigue, pertes) | Câble Ethernet, carte réseau réglée, rien qui sature la connexion | **Énorme** sur la sensation de lag |
| **Ping de base** | Fibre, bonne région de matchmaking | Limité par la distance |
| **Délai de l'écran** | Fréquence max (144/240 Hz) | Moyen |

Objectif réaliste en France avec la fibre et un câble : **10 à 25 ms de ping**, stable,
sans pertes, et un input lag au plancher.

---

## 1. Lancer l'outil (2 minutes)

1. Télécharge le zip, puis **clic droit dessus > Propriétés > coche « Débloquer »**, puis extrais-le.
2. Ferme Fortnite.
3. Double-clic sur **`LANCER.bat`**, puis réponds **Oui** à la fenêtre administrateur.
4. (Conseillé) **7. Diagnostic** pour voir ton point de départ.
5. **1. TOUT OPTIMISER**. L'outil te pose **2 questions** (voir plus bas), puis fait tout seul.
6. **Redémarre le PC** (l'outil te le propose).

```
   1. TOUT OPTIMISER EN UN CLIC  (recommandé)

   2. Connexion  : réduire le ping et les pics de lag
   3. Latence    : supprimer le délai (input lag)
   4. FPS        : plus d'images par seconde, plus stables
   5. Fortnite   : réglages du jeu (plein écran, V-Sync, Reflex...)
   6. PC complet : Windows plus léger + nettoyage

   7. Diagnostic : écran, Wi-Fi ou câble, ping, gigue, pertes
   8. Restaurer  : tout remettre comme avant
   0. Quitter
```

**Pour tout annuler : 8. Restaurer.** Chaque valeur d'origine est sauvegardée dans
`C:\Users\<toi>\FortniteOpti-Sauvegarde\` avant d'être modifiée, et un point de
restauration Windows « Avant optimisation Fortnite » est créé en plus.

### Les 2 questions qu'on te pose (ton choix)

- **Intégrité de la mémoire** (seulement si elle est activée) : la couper donne souvent
  **+5 à 10 % de FPS**, mais Windows est moins protégé contre les virus qui visent le cœur
  du système. Réponds Oui si tu fais attention à ce que tu télécharges, sinon Non.
- **Graphismes compétitifs** : ombres, effets, reflets, post-traitement, illumination et
  herbe au minimum. **Beaucoup plus de FPS et une meilleure visibilité**, mais une image
  moins jolie. Les textures et la distance d'affichage ne sont pas touchées.

---

## 2. Ce que fait chaque catégorie

### 2. Connexion : ping et pics de lag

| Réglage | Pourquoi | Gain |
|---|---|---|
| Économies d'énergie de la carte réseau coupées (Green Ethernet, EEE, ULP) | Elles mettent la carte en veille entre deux paquets | Faible à moyen |
| Regroupement et modération des paquets coupés | Chaque paquet est traité tout de suite au lieu d'attendre | Faible (quelques dizaines de µs) |
| Wi-Fi Intel : recherche de bornes au minimum | Les scans en arrière-plan créent des pics réguliers | Moyen **en Wi-Fi** |
| Paquets de Fortnite marqués prioritaires (QoS, DSCP 46) | Priorité en Wi-Fi et sur les box qui gèrent la QoS | Faible à moyen selon la box |
| Bridage réseau de Windows coupé | Windows bride le réseau quand de la musique/vidéo tourne | Faible |
| Windows n'envoie plus de mises à jour à d'autres PC | Ça pouvait saturer ton envoi = pics de ping | Moyen si c'était actif |

### 3. Latence : délai / input lag

| Réglage | Pourquoi | Gain |
|---|---|---|
| Accélération souris Windows coupée | Mouvement 1:1, menus et éditions cohérents | Confort |
| Raccourci « touches rémanentes » coupé | Plus de pop-up qui te sort du jeu quand tu spammes Maj | Confort |
| Planification GPU accélérée par le matériel | Moins de travail CPU pour piloter la carte graphique | Faible |
| Optimisations pour les jeux fenêtrés (Windows 11) | Moins de latence en mode fenêtré | Faible |
| Priorité maximale aux jeux (planificateur multimédia) | Plus de temps CPU/GPU pour le jeu | Faible |
| Mise en veille PCI Express et USB coupée | La carte graphique, le réseau et la souris ne s'endorment plus | Faible à moyen |

### 4. FPS

| Réglage | Pourquoi | Gain |
|---|---|---|
| Plan « Performances optimales » | Le CPU ne baisse plus sa fréquence en plein combat | Moyen (FPS stables) |
| *Exception Ryzen X3D :* plan « Utilisation normale » gardé | Le pilote AMD en a besoin pour mettre le jeu sur les cœurs avec le cache 3D | Évite une perte de FPS |
| Mode Jeu + enregistrement Game Bar en arrière-plan coupé | L'enregistrement permanent coûte des FPS | Moyen |
| Fortnite forcé sur la carte graphique dédiée | Indispensable sur PC portable | Énorme sur portable |
| Intégrité de la mémoire (option) | Voir les 2 questions plus haut | +5 à 10 % |

### 5. Fortnite (fichier de réglages du jeu)

L'outil modifie **uniquement le fichier de réglages** (`GameUserSettings.ini`), exactement
comme le menu Paramètres du jeu. Aucun fichier du jeu, aucun risque avec l'anti-cheat.

- Plein écran, V-Sync coupée, flou de mouvement coupé, compteur de FPS affiché
- NVIDIA Reflex « Activé + Boost » (cartes NVIDIA)
- Limite de FPS remontée si elle était **en dessous** de la fréquence de ton écran
- Graphismes compétitifs (option)

Fortnite doit avoir été lancé au moins une fois, et être **fermé** pendant l'opération.

### 6. PC complet

| Réglage | Pourquoi | Gain |
|---|---|---|
| Applications du Store bloquées en arrière-plan | Moins de tâches de fond (Discord, Steam... ne sont pas concernés) | Faible |
| Transparence et animations coupées | Windows plus vif | Faible (bureau) |
| Démarrage rapide coupé | Pilotes et mémoire repartent propres à chaque allumage | Stabilité |
| Télémétrie Microsoft coupée | Une tâche de fond en moins | Faible |
| Nettoyage des fichiers temporaires | Place libérée (les caches de shaders sont gardés, sinon saccades) | Espace disque |
| Liste des programmes au démarrage | À toi de couper l'inutile (Ctrl+Maj+Échap > Applications de démarrage) | Moyen |

### Ce que l'outil ne fait volontairement PAS (et pourquoi)

Beaucoup de « packs de tweaks » sur YouTube font plus de mal que de bien :

- **Désactiver l'antivirus, le pare-feu ou les mises à jour de sécurité** : dangereux, aucun gain réel en jeu.
- **Désactiver les protections CPU (Spectre/Meltdown), toucher à `bcdedit` (HPET, dynamic
  tick, useplatformclock), forcer une « timer resolution »** : effets contradictoires, ça peut
  **augmenter** la latence.
- **Les tweaks « Nagle » / `TcpAckFrequency` / TCP** : la partie de Fortnite passe par UDP, ça ne change rien.
- **Changer de DNS** : aucun effet sur le ping en partie.
- **Modifier les fichiers du jeu ou forcer sa priorité via des clés spéciales** : risque avec
  l'anti-cheat, donc risque de ban.
- **Vider les caches de shaders** : provoque des saccades au lancement suivant.
- **« Debloaters » et nettoyeurs de registre** : cassent Windows pour un gain nul.

---

## 3. À vérifier une fois dans Fortnite

**Paramètres > Vidéo :**

| Réglage | Valeur |
|---|---|
| Mode de rendu | **Performance** (le plus réactif). DirectX 12 seulement si grosse carte et que tu préfères l'image |
| NVIDIA Reflex | **Activé + Boost** (cartes NVIDIA) |
| AMD Anti-Lag 2 | **Activé** si l'option apparaît (cartes AMD) |
| Limite de FPS | Voir la règle ci-dessous |

**Règle pour la limite de FPS :**
- **Avec Reflex :** plafonne au nombre de FPS que ton PC **tient en permanence**, même en fin de partie.
- **Sans Reflex :** plafonne 5 à 10 FPS **en dessous** de ton minimum. Une carte graphique bloquée
  à 99 % ajoute de la latence ; un FPS stable est plus réactif qu'un FPS élevé qui yo-yote.

**Paramètres > Jeu :**
- **Région de matchmaking** : celle avec le ping le plus bas (Europe).
- Active les **statistiques réseau** (« Net Debug Stats ») : c'est **le vrai ping** vers le
  serveur, avec la perte de paquets.

---

## 4. Réglages de la carte graphique

### NVIDIA (Panneau de configuration NVIDIA > Gérer les paramètres 3D > Fortnite)
- Mode de gestion de l'alimentation : **Performances maximales préférées**
- Synchronisation verticale : **Désactivée** (sauf G-Sync, voir plus bas)
- Filtrage de texture, qualité : **Haute performance**
- Mode faible latence : peu importe, **Reflex dans le jeu prend le dessus**
- *Modifier la résolution* : fréquence de rafraîchissement **au maximum**

### AMD (Logiciel AMD Adrenalin > Jeux > Fortnite)
- Radeon Anti-Lag : **Activé**
- Radeon Chill, Radeon Boost, Enhanced Sync : **Désactivés**
- Attendre la synchro verticale : **Toujours désactivé**

### Écran G-Sync / FreeSync
Laisse G-Sync/FreeSync activé, active la V-Sync **dans le panneau du pilote** (pas en jeu) et
Reflex dans le jeu : Reflex plafonne automatiquement juste sous la fréquence de l'écran.

Mets le pilote graphique à jour une fois par mois (NVIDIA App ou AMD Adrenalin).

---

## 5. Réseau : le seul vrai levier sur le ping

1. **Câble Ethernet (RJ45) entre le PC et la box.** Changement n°1 : le Wi-Fi crée des pics
   et de la gigue. Un câble Cat 6 de 10-15 m coûte moins de 10 €. Sinon : Wi-Fi **5 GHz**
   près de la box (le CPL est moins bien).
2. **Personne ne télécharge pendant que tu joues** (streaming 4K, mises à jour, cloud).
   Teste la saturation de ta box : <https://www.waveform.com/tools/bufferbloat>. Note A ou B,
   c'est bon ; C, D ou F, active la QoS / priorité gaming de ta box si elle en a une.
3. **Mets Windows Update en pause** pendant tes sessions.
4. **Redémarre ta box** de temps en temps.
5. **Pas de VPN** : ça ajoute un détour, donc du ping.
6. **Fibre > ADSL > 4G/5G** : le meilleur investissement possible pour le ping.

---

## 6. Matériel

- **Écran** : à sa fréquence max (le diagnostic te le dit). Un écran 144 Hz réglé à 60 Hz est
  une erreur très fréquente. Active le mode jeu / overdrive de l'écran.
- **Souris** : taux d'interrogation (polling rate) à **1000 Hz** dans le logiciel de la souris,
  branchée directement sur le PC.
- **PC portable** : toujours **branché**, mode « Performance » du logiciel constructeur.
- **RAM** : si tu sais aller dans le BIOS, active **XMP** (Intel) / **EXPO** (AMD). Sans ça, la
  RAM tourne souvent bien en dessous de sa vitesse : gros gain de FPS sur Fortnite.

---

## Checklist rapide

- [ ] `LANCER.bat` > **1. TOUT OPTIMISER** + PC redémarré
- [ ] Câble Ethernet
- [ ] Écran à sa fréquence max
- [ ] Fortnite : Mode de rendu Performance, Reflex « Activé + Boost »
- [ ] Limite de FPS stable
- [ ] Bonne région de matchmaking + statistiques réseau affichées
- [ ] Pilote graphique à jour
- [ ] Personne ne télécharge pendant les parties
