# Pack zéro délai Fortnite : être le plus rapide en édit

| Fichier | Quand | Ce qu'il fait |
|---|---|---|
| **`ZERO-DELAI.bat`** | **Une fois** | Applique automatiquement **tous les tweaks Windows** qui réduisent le délai. **Ne touche pas aux réglages de Fortnite.** |
| `MODE-PARTIE.bat` | Avant chaque session | Ferme ce qui tourne en fond et met Windows Update en pause le temps de la partie. |
| `ANALYSEUR-LATENCE.bat` | Avant / après | **Mesure ton vrai délai** pendant que tu édites, et dit ce qui te ralentit. |
| `RESTAURER-TOUT.bat` | Si ça ne te plaît pas | Remet **tout** ce que `ZERO-DELAI.bat` a changé exactement comme avant. |

`Optimiser-Fortnite.ps1` et `Analyseur-Latence.ps1` sont les programmes utilisés par ces
fichiers : garde tout dans le même dossier.

## La méthode en 4 étapes

1. **Mesure** avec `ANALYSEUR-LATENCE.bat` (choix 1) : note ton « délai habituel ».
2. Double-clic sur **`ZERO-DELAI.bat`**, **Oui** à la fenêtre administrateur, puis **O**.
   - Un **point de restauration** est créé et **vérifié** avant tout changement.
   - Une seule question : couper l'« intégrité de la mémoire » (plus de FPS, un peu moins
     de sécurité). C'est ton choix.
   - **Redémarre** à la fin.
3. **Remesure** avec l'analyseur : il compare automatiquement avec ta mesure précédente.
4. Si ton délai a **baissé** : garde. S'il a **monté** : double-clic sur **`RESTAURER-TOUT.bat`**.

Avant chaque session : **`MODE-PARTIE.bat`**.

### Ce que fait `ZERO-DELAI.bat` (uniquement Windows)

- **Processeur** : plan d'alimentation hautes performances (sauf Ryzen X3D), Mode Jeu, priorité aux
  jeux, enregistrement vidéo de la Game Bar coupé, applis en arrière-plan coupées, télémétrie coupée.
- **Latence** : écran à sa fréquence max, mise en veille USB et PCI Express coupée, souris 1:1,
  planification GPU matérielle, pas de pop-up « touches rémanentes ».
- **Connexion** : carte réseau sans économie d'énergie, priorité réseau pour Fortnite, mises à jour
  Windows limitées en arrière-plan.

Chaque valeur d'origine est sauvegardée, d'où la restauration exacte avec `RESTAURER-TOUT.bat`.

---

# Analyseur de latence

Un mini logiciel qui **mesure ton vrai délai** entre ton clic (ou ta touche) et l'image à
l'écran **pendant que tu édites**, puis te dit **précisément** ce qui te ralentit sur **ton**
PC, par ordre d'importance.

Fini les tweaks « au feeling » : tu mesures, tu changes **une** chose, tu remesures, et tu
gardes seulement ce qui fait vraiment baisser le chiffre.

> **L'analyseur ne modifie RIEN**, ni dans Windows ni dans Fortnite : il mesure et il explique.
> Un **point de restauration** est quand même créé au lancement (un par jour), et l'option
> **4. Revenir en arrière** l'ouvre directement.

---

## Utilisation (5 minutes)

1. Extrais le zip, puis **clic droit sur le zip > Propriétés > « Débloquer »** avant d'extraire.
2. Lance **Fortnite** et va sur une **carte Créatif d'entraînement à l'édition** (ou une partie).
3. Double-clic sur **`ANALYSEUR-LATENCE.bat`**, puis **Oui** à la fenêtre administrateur.
   Le point de restauration se crée (jusqu'à 1 minute, une fois par jour).
4. Choisis **1. MESURER MA LATENCE**, puis **Entrée**, et **retourne dans Fortnite** (Alt+Tab).
5. Au **BIP**, édite, construis et **clique beaucoup** pendant **60 secondes**.
6. Au **DOUBLE BIP**, reviens sur la fenêtre : ton résultat et tes conseils s'affichent.

La première fois, le programme télécharge **PresentMon** (1 Mo), l'outil gratuit et open
source d'Intel qui mesure l'affichage image par image. Le fichier est **vérifié** (empreinte
SHA-256 et signature numérique d'Intel) : s'il ne correspond pas à l'original, il est refusé.

```
   1. MESURER MA LATENCE  (pendant que je joue / édite, 60 s)
   2. Bilan : ce qui peut ajouter du délai (lecture seule)
   3. Historique : comparer mes mesures
   4. Revenir en arrière (point de restauration)
   0. Quitter
```

---

## Ce que la mesure te donne

| Résultat | Ce que ça veut dire |
|---|---|
| **Délai habituel** | LE chiffre à faire baisser. Mesuré par **NVIDIA Reflex** si tu l'as activé (le plus fiable), sinon estimé par PresentMon. |
| Note | **EXCELLENT** ≤ 12 ms · **TRÈS BON** ≤ 20 ms · **MOYEN** ≤ 35 ms · **LENT** au-delà |
| FPS moyen et 1 % les plus bas | Les « 1 % bas » montrent les chutes : plus ils sont proches de la moyenne, plus c'est régulier. Si l'écart est grand, l'analyseur te propose une limite de FPS. |
| **Saccades** + **qui les cause** | Chaque image anormalement longue, et le programme qui tournait à ce moment-là (Windows Update, antivirus, navigateur, Discord...). |
| Mode d'affichage | « Hardware... » = affichage direct (le mieux). « Composed... » = l'image passe par Windows = environ 1 image de délai en plus. |
| V-Sync | Activée dans le jeu = une des plus grosses sources de délai. |
| Qui limite tes FPS | Carte graphique à 100 % (= délai en plus sans Reflex) ou processeur. |
| NVIDIA Reflex | Détecté automatiquement, avec la latence qu'il mesure lui-même. |
| Conseils | Triés **par ordre d'importance**, seulement ceux qui concernent **ton** PC. |

Chaque mesure est enregistrée : **3. Historique** et la comparaison automatique te montrent
si ton dernier changement a fait **baisser** (ou monter) ton délai.

**Limite honnête :** c'est le délai **côté PC**. La souris (environ 1 ms à 1000 Hz) et la dalle
de l'écran (quelques ms) s'y ajoutent. Et « 0 délai » n'existe pas : le but est d'atteindre
le plus bas possible **sur ton matériel**.

---

## Le bilan (choix 2, lecture seule)

Il vérifie, **sans rien modifier** : fréquence de l'écran, plein écran / V-Sync / limite de FPS
/ Reflex dans Fortnite, plan d'alimentation, Mode Jeu, enregistrement continu de la Game Bar,
accélération souris, intégrité de la mémoire, préversions Windows Update, Windows Update en
cours, Wi-Fi ou câble, et programmes gourmands ouverts.

---

## La méthode pour être le plus rapide en édit

1. **Mesure** une première fois : c'est ta référence.
2. Corrige **le conseil n° 1** de la liste.
3. **Remesure**. Si le délai a baissé, garde le changement ; sinon, remets comme avant.
4. Passe au conseil suivant.

Les gains les plus fréquents, du plus gros au plus petit :

1. **Écran à sa fréquence max** (60 → 144 Hz = environ 10 ms de moins par image).
2. **V-Sync désactivée** dans Fortnite.
3. **Plein écran** + overlays coupés (Discord, NVIDIA, Xbox Game Bar).
4. **NVIDIA Reflex « Activé + Boost »** (ou AMD Anti-Lag).
5. **FPS stables** : rien qui tourne en fond (lance `MODE-PARTIE.bat` du pack d'optimisation).
6. **Souris à 1000 Hz** dans son logiciel : Epic indique qu'un taux trop élevé peut faire
   chuter les FPS quand tu bouges la souris, et conseille 500 à 1000 Hz.

**Réglages d'édition dans Fortnite** (Paramètres > Jeu, à toi de les régler) :
« Éditer au relâchement » **activé**, Construction turbo **activée**, touche d'édition sur une
touche facile (F, E ou bouton latéral de la souris).

---

## Sécurité et confidentialité de l'analyseur

- **L'analyseur ne modifie rien** dans Windows ni dans Fortnite. Le seul réglage touché est la limite
  « un point de restauration par 24 h », levée le temps de créer le point puis **remise comme avant**.
- **PresentMon** lit les événements d'affichage de Windows : il ne touche pas au jeu.
- **Fichiers créés**, chez toi uniquement :
  - mesures et historique : `C:\Users\<toi>\FortniteOpti-Sauvegarde\mesures\`
  - PresentMon : `C:\Users\<toi>\AppData\Local\FortniteOpti\outils\`
- Rien n'est envoyé sur Internet. Le seul accès réseau est le téléchargement de PresentMon
  depuis le GitHub officiel d'Intel.
