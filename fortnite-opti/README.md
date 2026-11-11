# Optimisation Fortnite v4 : tweaks 0 délai (ping, latence, FPS, édition)

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
3. (Conseillé) Double-clic sur **`LANCER.bat`** > **8. Diagnostic** pour voir ton point de
   départ (BIOS, RAM, pilote, écran, ping).
4. **Double-clic sur `TWEAKS-0-DELAI.bat`** (une seule fois), puis réponds **Oui** à la fenêtre
   administrateur. L'outil te pose **2 questions** (voir plus bas), puis fait tout seul.
   Si ton écran change de fréquence, appuie sur **O** pour garder.
5. **Redémarre le PC** (l'outil te le propose).
6. Règle une fois les options de **construction / édition** dans Fortnite (section 4).
7. **Avant chaque session de jeu : double-clic sur `MODE-PARTIE.bat`** (voir plus bas).

| Fichier | Quand | Ce qu'il fait |
|---|---|---|
| `TWEAKS-0-DELAI.bat` | **Une fois** (et après une grosse mise à jour Windows) | Tous les tweaks d'un coup |
| `MODE-PARTIE.bat` | **Avant chaque session** | Ping au minimum pendant que tu joues |
| `LANCER.bat` | Quand tu veux | Le menu complet (catégories, diagnostic, restaurer) |

```
   1. TWEAKS 0 DÉLAI : TOUT OPTIMISER EN UN CLIC  (à faire une fois)
   2. MODE PARTIE  (avant chaque session : ping au minimum)

   3. Connexion  : réduire le ping et les pics de lag
   4. Latence    : supprimer le délai (input lag)
   5. FPS        : plus d'images par seconde, plus stables
   6. Fortnite   : réglages du jeu (plein écran, V-Sync, Reflex...)
   7. PC complet : Windows plus léger + nettoyage

   8. Diagnostic : BIOS, RAM, pilote, écran, Wi-Fi/câble, ping
   9. Restaurer  : tout remettre comme avant
   0. Quitter
```

**Pour tout annuler : 9. Restaurer.** Chaque valeur d'origine est sauvegardée dans
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

## 2. Le Mode Partie (avant chaque session)

Double-clic sur **`MODE-PARTIE.bat`** (ou choix **2** du menu), puis lance Fortnite.
**Laisse la fenêtre ouverte** (réduite) pendant que tu joues ; quand tu as fini, reviens
dessus et appuie sur **Entrée** : tout revient à la normale.

Pendant la session :

| Action | Pourquoi | Gain |
|---|---|---|
| Ferme les applis qui utilisent ta connexion en fond (OneDrive, Google Drive, Dropbox, torrents, Steam, EA app, Battle.net, Ubisoft Connect...) | Une synchro ou un téléchargement sature la connexion = pics de ping. Steam ne met **pas** ses téléchargements en pause pour Fortnite | **Énorme** si une de ces applis tournait |
| Ferme Overwolf et Corsair iCUE s'ils tournent | Overlay et logiciel RGB qui prennent du processeur / causent des micro-saccades | Moyen |
| Arrête les téléchargements de Windows Update | Pas de mise à jour de 3 Go qui démarre en pleine partie | Moyen à énorme |
| **En Wi-Fi :** coupe la recherche de réseaux en arrière-plan (tu restes connecté) | Windows cherche d'autres réseaux toutes les ~60 s, ce qui crée un pic de ping régulier | **Gros** en Wi-Fi |

À la fin, la synchro de fichiers (OneDrive...) et iCUE sont relancés et le Wi-Fi remis comme avant.
**Sécurité :** si tu fermes la fenêtre ou redémarres le PC sans appuyer sur Entrée, le Wi-Fi
est remis automatiquement au prochain démarrage (et au prochain lancement de l'outil).
Pendant le Mode Partie en Wi-Fi, si la connexion coupe, elle ne se rétablit pas toute seule :
appuie sur Entrée dans la fenêtre.

---

## 3. Ce que fait chaque catégorie

### Connexion : ping et pics de lag

| Réglage | Pourquoi | Gain |
|---|---|---|
| Économies d'énergie de la carte réseau coupées (Green Ethernet, EEE, ULP) | Elles mettent la carte en veille entre deux paquets | Faible à moyen |
| Regroupement et modération des paquets coupés | Chaque paquet est traité tout de suite au lieu d'attendre | Faible (quelques dizaines de µs) |
| Wi-Fi Intel : recherche de bornes au minimum + préférence pour le 5 GHz | Les scans créent des pics réguliers ; le 5 GHz est moins encombré | Moyen **en Wi-Fi** |
| Paquets de Fortnite marqués prioritaires (QoS, DSCP 46) | Priorité en Wi-Fi et sur les box qui gèrent la QoS | Faible à moyen selon la box |
| Bridage réseau de Windows coupé | Windows bride le réseau quand de la musique/vidéo tourne | Faible |
| Windows n'envoie plus de mises à jour à d'autres PC | Ça pouvait saturer ton envoi = pics de ping | Moyen si c'était actif |
| Mises à jour Windows en arrière-plan limitées à 20 % de ta connexion | Une mise à jour ne peut plus saturer ta ligne | Moyen |

### Latence : délai / input lag

| Réglage | Pourquoi | Gain |
|---|---|---|
| **Écran mis à sa fréquence maximale** (ex. 60 → 144 Hz), avec retour automatique si l'image disparaît | Chaque image arrive plus vite : 60 → 144 Hz = ~10 ms de moins par image | **Énorme** si ton écran était bridé |
| Accélération souris Windows coupée | Mouvement 1:1, menus et éditions cohérents | Confort |
| Raccourci « touches rémanentes » coupé | Plus de pop-up qui te sort du jeu quand tu spammes Maj | Confort |
| Planification GPU accélérée par le matériel | Moins de travail CPU pour piloter la carte graphique | Faible |
| Optimisations pour les jeux fenêtrés (Windows 11) | Moins de latence en mode fenêtré | Faible |
| Priorité maximale aux jeux (planificateur multimédia) | Plus de temps CPU/GPU pour le jeu | Faible |
| Mise en veille PCI Express et USB coupée | La carte graphique, le réseau et la souris ne s'endorment plus | Faible à moyen |

### FPS

| Réglage | Pourquoi | Gain |
|---|---|---|
| Plan « Performances optimales » | Le CPU ne baisse plus sa fréquence en plein combat | Moyen (FPS stables) |
| *Exception Ryzen X3D :* plan « Utilisation normale » gardé | Le pilote AMD en a besoin pour mettre le jeu sur les cœurs avec le cache 3D | Évite une perte de FPS |
| Mode Jeu + enregistrement Game Bar en arrière-plan coupé | L'enregistrement permanent coûte des FPS | Moyen |
| Fortnite forcé sur la carte graphique dédiée | Indispensable sur PC portable | Énorme sur portable |
| Intégrité de la mémoire (option) | Voir les 2 questions plus haut | +5 à 10 % |

### Fortnite (fichier de réglages du jeu)

L'outil modifie **uniquement le fichier de réglages** (`GameUserSettings.ini`), exactement
comme le menu Paramètres du jeu. Aucun fichier du jeu, aucun risque avec l'anti-cheat.

- Plein écran, V-Sync coupée, flou de mouvement coupé, compteur de FPS affiché
- NVIDIA Reflex « Activé + Boost » (cartes NVIDIA)
- Limite de FPS remontée si elle était **en dessous** de la fréquence de ton écran
- Graphismes compétitifs (option)

Fortnite doit avoir été lancé au moins une fois, et être **fermé** pendant l'opération.

### PC complet

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
- **Désactiver les protections CPU (Spectre/Meltdown)** : vrai risque de sécurité, gain quasi nul.
- **`bcdedit` (HPET, dynamic tick, useplatformclock)** : effets contradictoires, ça peut
  **augmenter** la latence ; et modifier la configuration de démarrage peut déclencher une
  demande de **clé de récupération BitLocker** au redémarrage (PC bloqué si tu ne l'as pas).
- **« Timer resolution » (ISLC, TimerResolution.exe)** : depuis Windows 10 2004 / Windows 11,
  ce réglage ne s'applique plus qu'au programme qui le demande, et Fortnite règle déjà le sien.
- **`MouseDataQueueSize` / `KeyboardDataQueueSize`** : c'est une file d'attente, pas un délai.
  La réduire ne rend rien plus rapide, et trop basse elle **fait perdre des clics** avec les
  souris à 4000/8000 Hz.
- **Mode MSI / affinité des interruptions** : gain de quelques microsecondes, et un mauvais
  réglage peut donner un **écran bleu au démarrage**.
- **`Win32PrioritySeparation`** : la valeur « magique » des vidéos (0x26) fait la même chose que
  le réglage par défaut de Windows.
- **Les tweaks « Nagle » / `TcpAckFrequency` / TCP** : la partie de Fortnite passe par UDP, ça ne change rien.
- **Changer de DNS** : aucun effet sur le ping en partie.
- **Modifier les fichiers du jeu ou forcer sa priorité via des clés spéciales** : risque avec
  l'anti-cheat, donc risque de ban.
- **Vider les caches de shaders** : provoque des saccades au lancement suivant.
- **« Debloaters » et nettoyeurs de registre** : cassent Windows pour un gain nul.

---

## 4. Construction et édition : le moins de délai possible

Ces options sont sauvegardées **dans le cloud d'Epic** : aucun fichier ne peut les changer à
ta place, il faut les régler **une fois** dans **Paramètres > Jeu** (l'outil te les rappelle).

| Réglage | Valeur | Pourquoi |
|---|---|---|
| **Éditer au relâchement** (« Edit on Release ») | **Activé** | L'édition se valide dès que tu lâches la touche : **LE** réglage pour éditer vite |
| Construction turbo (« Turbo Building ») | **Activé** | Construit en continu en maintenant le clic |
| Changement de matériau auto (« Auto Material Change ») | **Activé** | Plus de blocage quand un matériau est vide |
| Réinitialiser le choix de construction (« Reset Building Choice ») | **Désactivé** | Garde la dernière pièce choisie |
| Rediffusions (« Replays ») | **Enregistrement désactivé** | Moins de travail pour le PC pendant la partie |

**Touches :** édition sur une touche facile (F, E ou bouton latéral de la souris), murs et
escaliers sur les boutons latéraux pour ne pas lâcher ZQSD. Garde la **même sensibilité**
en construction et en édition qu'en visée, pour que tes gestes restent les mêmes.

**Matériel qui compte pour l'édition :** souris réglée à **1000 Hz** minimum (logiciel de la
souris), écran à sa fréquence max (l'outil le fait), FPS stables.

**Le réseau compte aussi :** chaque édition est **validée par le serveur**. Avec 15-30 ms de
ping, elle paraît instantanée ; au-delà de ~50 ms, tu sentiras toujours un petit retard, quels
que soient les tweaks. D'où le **câble Ethernet**, la **bonne région** et le **Mode Partie**.

---

## 5. À vérifier une fois dans Fortnite

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

## 6. Réglages de la carte graphique

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

## 7. Réseau : le seul vrai levier sur le ping

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

### Spécial Freebox Pop

- **La Freebox Pop ne permet pas de mettre ton PC en priorité** : pas de QoS réglable ni de
  « mode gaming ». La seule priorité qu'elle gère, c'est sa TV.
- **Branche ton PC en Ethernet** directement sur un port libre de la Freebox.
- **TV Freebox :** si tu sens plus de lag quand elle tourne, éteins-la pendant tes parties.
- **Partie importante :** l'appli **Freebox Connect** (ou `mafreebox.freebox.fr` > contrôle
  parental) permet de **mettre en pause Internet** sur les autres appareils. À faire avec
  l'accord des autres, évidemment.
- **En fibre**, la ligne est très large : fais le test bufferbloat ci-dessus pendant que les
  autres utilisent Internet. Si la note est A ou B, le partage n'est pas ton problème.
- **Option avancée :** un routeur gaming derrière la box (ASUS, TP-Link... avec priorité par
  appareil), mais ça ne marche que si les autres appareils passent par lui.

---

## 8. Matériel et BIOS

- **Écran** : l'outil le met à sa fréquence max. Active aussi le mode jeu / overdrive dans le
  menu de l'écran (boutons de l'écran).
- **Souris** : taux d'interrogation (polling rate) à **1000 Hz** minimum dans le logiciel de la
  souris, branchée directement sur le PC.
- **PC portable** : toujours **branché**, mode « Performance » du logiciel constructeur.
- **Une seule barrette de RAM** = mode simple canal = grosse perte de FPS (le diagnostic le dit).

**BIOS** (touche Suppr ou F2 au démarrage). Aucun script ne peut le régler : chaque carte mère
a ses menus et un mauvais réglage peut empêcher le PC de démarrer. Le diagnostic te dit quoi
faire ; dans l'ordre :

1. **XMP (Intel) / EXPO (AMD)** si le diagnostic dit « RAM bridée » : souvent le plus gros gain
   de FPS gratuit. Si le PC ne démarre pas, il revient seul aux anciens réglages après quelques essais.
2. **Mettre le BIOS à jour**, surtout sur Intel Core 13e/14e gen (correctif d'instabilité
   d'Intel). Ne jamais couper le courant pendant la mise à jour.
3. **Resizable BAR** (+ « Above 4G Decoding ») : petit gain sur les cartes récentes,
   **uniquement si le diagnostic affiche « Mode de démarrage : UEFI »**.
4. **À ne pas toucher** : overclock manuel, tensions, C-States, HPET. Sur Intel 13e/14e gen,
   aucun overclock.

---

## Checklist rapide

- [ ] **`TWEAKS-0-DELAI.bat`** + PC redémarré
- [ ] Construction : **Éditer au relâchement**, Construction turbo, Changement de matériau auto
- [ ] Diagnostic : RAM pas bridée (XMP/EXPO), BIOS et pilote à jour
- [ ] **`MODE-PARTIE.bat` avant chaque session**
- [ ] Câble Ethernet
- [ ] Écran à sa fréquence max
- [ ] Fortnite : Mode de rendu Performance, Reflex « Activé + Boost »
- [ ] Limite de FPS stable
- [ ] Bonne région de matchmaking + statistiques réseau affichées
- [ ] Pilote graphique à jour
- [ ] Personne ne télécharge pendant les parties
