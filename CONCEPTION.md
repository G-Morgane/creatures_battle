# Nid

*(titre de travail)*

**Autobattler roguelike, PvP asynchrone et PvE. On remplit un Nid de reliques, il en éclot une monture
qui se bat seule, avec son cavalier. Godot 4, 2D.**

> Ce que tu mets dans le Nid décide de ce qui en sort.
> Un Nid de braises donne un phénix, un Nid de nuit une chauve-souris,
> et les deux se battent avec les sorts que tu leur as donnés.

---

## 1. La thèse

Dans Backpack Battles ou Oaken Tower, le build est un inventaire qu'on regarde se battre.
Ici, **le build devient un corps** : on voit à l'écran ce qu'on a construit.

Corollaire de conception : chaque relique doit changer quelque chose de **visible**
sur la créature ou dans le combat. Une relique qui ne fait que +2 en silence est une relique ratée.

---

## 2. Univers

**Le royaume fae de Sylvaën** (nom de travail), partagé entre **huit Dynasties** : quatre saisons
et quatre moments du jour. Chaque Dynastie est un archétype, avec sa monture.

**Hommages, jamais de références directes.** Le jeu s'inspire d'univers de fantasy aimés
(cours fae, cavaliers liés à leur monture, assassins et sorcières, anneau et spectres,
école de magie) mais n'en reprend aucun nom propre, aucun personnage, aucun lieu. Les noms
de Dynasties restent génériques (Printemps, Été, Automne, Hiver, Aube, Jour, Crépuscule, Nuit) ; tout le reste
est inventé : élites, rencontres, objets neutres.

Le cœur du jeu est déjà un hommage : un cavalier **lié** à sa monture, et l'arme qu'il tient
comme la marque de ce lien.

---

## 2 bis. L'histoire : le Rêveur

Un roguelike de dark fantasy : on remonte jusqu'à un **dieu ancien qui possède les créatures à
travers son rêve**. Les boss de fin d'acte sont des **gardiens** possédés ; on les **purifie**
sans les tuer.

| Étape | Progression |
|---|---|
| Acte I, la vallée contaminée | Découvrir la possession et purifier le premier gardien |
| Acte II, les profondeurs | Comprendre que les créatures obéissent à une même volonté, briser son relais |
| Acte III, le sanctuaire englouti | Atteindre le dernier gardien et ouvrir l'accès à l'entité |
| Confrontation finale | Affronter une incarnation du dieu, obtenir une victoire permanente sur lui |

**Plusieurs runs victorieuses** sont nécessaires pour le tuer : d'abord son incarnation, puis ses
ancrages, avant de l'atteindre dans son rêve. Chaque étape change visiblement le monde et la
confrontation suivante. Tant que le dieu existe, il peut reprendre les gardiens entre deux
expéditions ; un ancrage détruit reste perdu pour lui. Nombre de victoires : à définir.

### Premier gardien : le Bastion endormi (fait)

Une tortue géante qui dort au fond du lac de la vallée ; on a bâti un sanctuaire sur son dos,
où trône son cavalier en armure. La possession s'y voit : filaments sombres, et un œil immense
dans la porte du temple (image `images/boss_tortue.png`).

**L'entité détourne la protection du gardien pour en faire une arme.** Un cycle :

| Moment | Ce qui se passe |
|---|---|
| Le rempart (8 s) | +7 de bouclier par seconde, attaques lentes (x1,8). L'œil rougeoie à mesure que le rempart grandit. |
| L'ouverture (3 s) | Immobile. La porte s'ouvre, la bête se teinte de violet, l'œil boit le bouclier restant. |
| Le regard | Une attaque égale à 1,5 x le bouclier absorbé, plafonnée à 90 (x la force de la manche). |
| La résistance (3 s) | Le cavalier referme la porte : aucun bouclier, +25 % de dégâts reçus. |

Un build offensif entame le bouclier et affaiblit le regard ; un build défensif l'encaisse et
profite de la résistance. Le vaincre affiche « Purifié ! Le Bastion endormi est libéré ».
Les autres actes gardent un boss fantôme en attendant leurs gardiens. Simulation : boss gagnés
41 % (34 % avant), 29 % de runs gagnées.

## 3. La run

Une run se joue sur une **carte**, comme dans Slay the Spire ou FTL, avec la boucle d'achat de TFT
entre chaque nœud.

### Carte

- **3 actes.** Chaque acte est une carte à embranchements de **10 étages** (4 colonnes, 4 chemins
  tracés au hasard qui ne se croisent pas) ; on choisit son chemin et l'on voit le type des nœuds à venir.
- Chaque acte finit par un **boss** (PvE).
- Gagner le boss du troisième acte gagne la run.

| Nœud | Contenu | Récompense |
|---|---|---|
| **Duel** | PvP asynchrone : le Nid d'un autre joueur, enregistré au même stade | Or |
| **Élite** | PvE : une créature plus forte, avec un gimmick lisible | Or et choix d'une relique rare ou mieux |
| **Rencontre** | Événement à choix (voir plus bas) | Variable, parfois un prix à payer |
| **Feu de camp** | Repos : raviver la Ferveur, ou une fusion gratuite | |
| **Boss** | Fin d'acte, PvE | Relique légendaire au choix |

Génération (`scripts/carte.gd`) : le premier étage est fait de Duels, l'étage avant le boss de
Feux de camp. Ailleurs, tirage pondéré : Duel 55, Rencontre 25, Élite 12, Feu 8. Pas
d'Élite avant le 5e étage du premier acte, pas de Feu avant le 5e étage. Pas de Marché : la
boutique est déjà ouverte entre chaque nœud.

### Choix des dynasties

En début de partie, on choisit **de 3 à 8 dynasties** (ou « Aléatoire » : 4 au hasard). La
boutique, les reliques offertes, le Heaume et les fantômes ne tirent que dans ces dynasties (et
les objets neutres). Au survol, chaque dynastie montre son identité et son passif. Automne et
Jour sont visibles mais pas encore jouables. Le nom « Cour » est abandonné : trop proche d'un
univers existant.

### Glossaire

Un bouton **Glossaire** (ou F1) en haut à droite, sur tous les écrans, ouvre un panneau qui
explique les règles, les états et les dynasties. Ses chiffres viennent de `Data`.

### Le sac

Le Nid est un **tapis de 8 colonnes sur 4 rangées**. Une run commence sur les **4 colonnes du
centre** (16 cases) et s'agrandit d'une colonne à la fois, en alternant les côtés :
- en boutique, bouton « Agrandir » : 8, 12, 16 puis 20 or (comme l'expérience de TFT) ;
- gratuitement, une colonne après chaque boss battu (actes 1 et 2).

À l'écran, le tapis est assemblé en tuiles (`images/tapis`, découpées de `damier_items.png`) :
chaque case prend la tuile dont les bords en cuir correspondent à sa place, et une case sur deux
est assombrie.

### Formes des reliques

Chaque relique occupe une **forme** dans le sac (`Data.empreinte`) :
- **armes, selon leur famille** : Hast, Faux et Bâton en 1 x 3, Tir et Lame en 1 x 2, Hache en 2 x 2 ;
- **les autres, selon leur rareté** : commun 1 case, rare 2 cases en ligne, épique 3 cases en L,
  légendaire 2 x 2 ;
- des exceptions à la main dans `FORMES_OBJETS`, pour coller à une image.

Plus une relique est rare, plus elle prend de place : son pouvoir se paie en cases, ce qui donne
son sens à l'agrandissement du sac. On **tourne** une relique tenue avec R ou la molette ; un
aperçu vert ou rouge montre où elle tomberait. Un catalyseur renforce toutes les reliques qui
touchent **n'importe laquelle** de ses cases : une grande relique a plus de voisines.
Déplacer une relique sur une autre les échange si l'autre tient à la place laissée.

Les Nids d'exemple et les tests de mécanique gardent une case par relique (`encombrement`
désactivé) ; la partie l'active. Simulation (100 runs) : joueur simple 30 % de runs gagnées,
inchangé.

### Les armes du cavalier

**Aucune limite** : chaque arme posée dans le sac lance son propre sort (la règle des deux mains
a été essayée puis retirée). Le cavalier en montre deux à l'écran. Le sac accepte autant de
copies que de place, et tout fusionne, armes et légendaires compris.

Simulation (100 runs) : le joueur simple tombe à 27 % de runs gagnées (40 % avec la limite),
le joueur aléatoire à 0 % : les fantômes, qui achètent les armes en premier, en empilent beaucoup.
À surveiller : il faudra sans doute baisser le prix ou la force des armes en grand nombre.

### Boutique entre chaque nœud

**Verrouiller** une offre (clic droit) la garde aux relances et à la boutique suivante, comme
la réservation de Backpack Battles. Une relique offerte (élite, boss) prend une place vide, sinon
une offre non verrouillée.

Comme dans TFT : **après chaque combat, la boutique est ouverte mais facultative**. On achète,
relance, réorganise le Nid, ou l'on passe directement au nœud suivant. L'or non dépensé se garde.

### Ferveur

La **Ferveur** (la volonté du cavalier de poursuivre la quête) remplace « 7 victoires ou 3 défaites ». À 0, la run est perdue.
- Une défaite coûte des PV selon le nœud (Duel peu, Élite plus, Boss beaucoup) et la force
  de ce qui reste à l'adversaire, comme dans TFT.
- Une égalité ne coûte rien.
- Prototype : **60 de Ferveur**. Défaite : Duel 3, Élite 6, Boss 10, plus jusqu'à 8 selon les PV
  qui restaient à l'adversaire. Feu de camp : +20. Perdre un boss coûte des PV mais on passe
  quand même à l'acte suivant ; le boss du dernier acte termine la run.
- Élite battue : une relique **épique offerte** dans la boutique (de l'élément du Nid si possible).
  Boss battu : une **légendaire offerte**. L'offre offerte survit aux relances.
- Le fantôme a des manches d'avance : 1 en duel, 3 en élite, 5 au boss (`Partie.AVANCE`, réglé le 2026-10-29 pour 40 % de runs gagnées par le joueur simple).
  Les vraies élites à gimmick viendront ensuite.
- Rencontres du prototype : le Heaume qui Juge, le Grand Chaudron, le Pont des Lames.

Mesure sur 100 runs par joueur automatique (`tests/simulation.gd`), environ 26 nœuds par run :

| Joueur | Runs gagnées | Arrivées à l'acte 3 | Duels gagnés | Élites | Boss |
|---|---|---|---|---|---|
| Aléatoire | 3 % | 48 % | 35 % | 21 % | 15 % |
| Simple | 31 % | 80 % | 59 % | 48 % | 44 % |

L'écart entre les deux joueurs est net. Par élément, il faudra plus de runs pour conclure. Les
fantômes ne rejouent plus toute leur partie à chaque combat : quatre fantômes avancent d'une
manche à la fois (sans cela, une run coûtait des secondes).

### Duels : PvP asynchrone

- À chaque Duel, on enregistre son Nid (reliques, niveaux, arme) avec l'acte, le nœud et sa Ferveur.
- L'adversaire est tiré parmi les Nids enregistrés **au même stade**, de préférence à PV proches.
- Le combat est déterministe : le Nid enregistré rejoue exactement. Seul le joueur qui joue
  perd ou gagne quelque chose ; le Nid enregistré ne subit rien.
- Serveur : une table de Nids (Supabase suffit). En attendant, l'adversaire est le
  **fantôme** (joueur automatique, ci-dessous).

### Élites (faites)

Trois élites, chacune le Nid d'un fantôme au même stade, avec sa règle et son image
(`images/ennemis`). Ses chiffres grandissent de 5 % par manche. Le nom de l'élite s'affiche sur la carte.

| Élite | Règle |
|---|---|
| Sanglier des Racines | +5 de bouclier par seconde ; toutes les 8 s, une charge qui le dépense (x1,5 en dégâts) |
| Phalène de l'Ouest | Toutes les 6 s, dissipe ses malus ; toutes les 7 s, un trait de 25 qui traverse le bouclier |
| Vouivre des Cendres | +3 % de dégâts par malus subi (plafond +90 %) ; à mi-vie, brise ses entraves : malus effacés, +40 % de dégâts et d'attaque |

Le Marché a été retiré de la carte : la boutique est déjà ouverte entre chaque nœud.

### Élites et boss (pistes)

Créatures conçues à la main, chacune avec une règle qu'on voit et qu'on peut contrer en adaptant son Nid.
Pistes :
- **Les Neuf Cavaliers Voilés** : neuf petites montures spectrales ; chaque mort rend les autres plus fortes.
- **Les Avaleurs de Joie** : aspirent les soins et les boucliers.
- **Le Seigneur à Collier** : prend le contrôle d'une relique adverse au début du combat.
- **La Reine du Fléau** : boss, empile des malédictions qu'on ne peut pas soigner.

### Rencontres (hommages)

- **Le Heaume qui Juge** : il te range dans une Dynastie et te donne une relique de départ.
- **Le Pont des Lames** : une épreuve ; réussir paye bien, échouer coûte de la Ferveur.
- **Le Grand Chaudron** : un pacte, une relique puissante contre de la Ferveur.
- **Le Marché Gobelin** : des échanges étranges (une relique contre deux, une rareté au hasard).

### Objets neutres (hommages)

Ils visent une famille d'armes (voir Familles d'armes). Pistes :
- **Lueur-d'Alarme** (Lame) : la dague brille face aux élites et y frappe plus fort.
- **L'Épée des Braves** : n'apparaît qu'aux joueurs à faible Ferveur.
- **La Lame de Rubis** (Lame ou Hache).

### Boutique et or

- **10 or par combat** ; feu de camp et rencontre ne donnent ni or ni boutique (on reste sur la carte). L'or non dépensé se garde.
- **9 offres** tirées au hasard. **Relance : 1 or, puis 1 de plus à chaque relance de la même
  boutique** (1, 2, 3...), remise à 1 à la boutique suivante.
- **Soldes** : chaque offre a 10 % de chances d'être à moitié prix (arrondi au-dessus).
- Arbitrages voulus (2026-10-29, d'après Backpack Battles et Oaken Tower) : relancer encore ou
  garder son or, verrouiller une offre qu'on ne peut pas payer, saisir un solde.
- Prix : essence 3, sort 4, catalyseur 4, arme 5.
- **On achète en posant** : glisser une offre dans une case vide du Nid.
- **Revente à moitié prix** (au moins 1 or) : ramener la relique à la boutique, ou clic droit.
- Tout le hasard passe par une graine : même graine, mêmes boutiques, mêmes adversaires.

- Prix : celui du type (essence 3, sort 4, catalyseur 4, arme 5) **+ la rareté**
  (rare +2, épique +4, légendaire +7).

### Rareté

Commun, rare, épique, légendaire. Les chances de tirage en boutique dépendent de la manche
(sur la carte : du nombre de nœuds franchis). Elles sont données par offre à quelques manches
repères et interpolées entre deux :

| Manche | Commun | Rare | Épique | Légendaire |
|---|---|---|---|---|
| 1 | 100 % | | | |
| 3 | 80 % | 20 % | | |
| 6 | 64,9 % | 28 % | 7 % | 0,1 % |
| 10 (boss 1) | 55,7 % | 30 % | 14 % | 0,3 % |
| 20 (boss 2) | 38 % | 33 % | 25 % | 4 % |
| 30 (boss 3) | 25 % | 33 % | 32 % | 10 % |

**Au plus un légendaire par boutique** : au-delà, le tirage donne un épique. Un légendaire en
boutique reste un événement en acte 1 ; le boss de chaque acte en offre déjà un.

Toutes les raretés fusionnent, légendaires compris (voir Fusion). Une tuile non commune porte une bande de couleur
(bleu rare, violet épique, or légendaire).

### Adversaire fantôme

En attendant le PvP, l'adversaire est un **joueur automatique qui a joué toutes les manches
jusqu'ici**, avec ses propres boutiques (une graine par manche) : mêmes règles que le joueur,
il ne choisit que parmi ses offres, relance, fusionne. C'est la préfiguration du PvP, où
l'on affrontera le Nid d'un vrai joueur au même stade.

Le premier générateur piochait directement dans tous les objets de son élément. Avec cinq
éléments, c'était un avantage énorme sur le joueur, limité à ses 5 offres.

Un bonus d'or par victoire du joueur existe (`OR_PAR_VICTOIRE`) mais est à 0.

Réglage mesuré sur 300 parties par joueur automatique (`tests/simulation.gd`) :

| Joueur | Victoires moyennes | Parties gagnées |
|---|---|---|
| Aléatoire | 2,5 | 17 % |
| Simple (un élément, catalyseurs bien placés) | 3,1 | 22 % |

Sans élimination, le joueur simple gagne 49 à 54 % de ses combats à chaque manche : la
difficulté est plate. Le fantôme n'est jamais meilleur que le joueur automatique simple,
d'où un joueur aléatoire encore trop à l'aise.

Par élément (joueur simple, **1 000 parties**, avec la nouvelle Terre) : Terre 3,8, Vent 3,7,
Nature 3,4, Crépuscule 3,3, Feu 3,0, Glace 3,0, Aube 3,0, Nuit 2,7. Joueur simple : 3,2 victoires
en moyenne, 23 % de parties gagnées. (Sur 300 parties, chaque élément n'a qu'une trentaine de
parties et les moyennes bougent de ±0,5 d'une mesure à l'autre.)

### Fusion

**3 copies d'une relique fusionnent en ★ (niveau 2), puis 2 ★ fusionnent en ★★ (niveau 3)** :
6 copies pour le niveau maximal (9 avant le 2026-10-29), à la place de la dernière posée.
- Stats multipliées : x2,5 au niveau 2, x5 au niveau 3. Un peu moins que les copies réunies
  (3 et 6), mais des cases libérées.
- L'affinité des copies est conservée : fusionner ne change pas la forme de la monture.
- Nid plein : on peut poser une offre **sur une copie** si elle complète un trio.
- Tout fusionne, armes et légendaires compris (copies illimitées tant que le sac a de la place).
- Revente : la moitié de ce qu'elle a coûté (1, 3 ou 6 copies).

C'est la progression de fin de partie : le Nid de 16 cases se remplit vers la manche 6, et
avant la fusion l'or ne servait plus à rien ensuite. La répartition des victoires était en
deux bosses (beaucoup de 0 à 2, un pic à 7, presque rien entre 4 et 6). Elle est maintenant
régulière.

---

## 4. Forme de la créature

Chaque relique donne des points d'**affinité** dans un élément.

- **Élément dominant** : fixe la forme de base, son identité de jeu et un passif.

### Les huit Dynasties

Quatre saisons et quatre moments du jour.

| Dynastie | Monture | Élément (code) | Identité | Ce qui la rend unique |
|---|---|---|---|---|
| Printemps | Cerf | nature | Qui me touche s'empoisonne | Les épines ripostent et empoisonnent |
| Été | Phénix | feu | Allumer puis consumer | Brûlures empilées puis consumées ; renaît une fois |
| Automne | Renard | automne | Esquiver, puis frapper juste | Chaque esquive prépare un critique |
| Hiver | Ours | glace | Ralentir jusqu'au gel | Le gel **bloque les recharges** adverses et ouvre une fenêtre d'attaque |
| Aube | Lion | aube | Soigner pour frapper | Le soin se stocke en Éclat, qui frappe |
| Jour | Paon | jour | Faire la roue | Chaque arme lancée renforce les suivantes (Éventail) |
| Crépuscule | Papillon | crepuscule | Sorts et illusions | Les sorts créent des Illusions qui encaissent puis éclatent en arcane |
| Nuit | Chauve-souris | nuit | Affaiblir avant de frapper | Plus forte par malédiction différente sur la cible |

L'Ours a remplacé le Loup (même set). La Raie et la Lumière sont abandonnées. **Vent (Cheval) et Terre (Tortue) sont retirés**, objets compris
(les mécaniques de combat qui leur servaient restent dans le code, sans objet pour les déclencher). À l'écran, les affinités portent le nom de la Dynastie (« Été 7 »).

Paires à garder distinctes :
- **Automne / Crépuscule** : l'esquive est au hasard, l'Illusion est une charge sûre que produisent les sorts.
- **Aube / Printemps** : l'Aube soigne, le Printemps punit.
- **Brûlure / poison** : la brûlure est courte et consumée, le poison s'empile et dure.
- **Jour / Aube** : le Jour enchaîne les armes, l'Aube convertit le soin en dégâts.

- **Hybride** : dès que le sac contient au moins 2 objets d'une autre dynastie que la principale,
  la monture est l'hybride des deux (28 images, `images/hybrides`), nommé dynastie dominante d'abord (« Phénix-Chauve-souris »).
  Le passif reste celui de la dynastie dominante.
- **Aucune affinité** : créature informe, sans passif.

### Le cavalier

La créature est une **monture** : un petit cavalier encapuchonné (visage sombre, deux yeux
lumineux) est assis dessus. Sa cape prend la couleur de l'élément dominant.

On **choisit son cavalier** en début de partie, après les dynasties (`images/cavaliers`). Il est
peint sur la monture en boutique et en combat. Chacun a un talent, d'un domaine différent
(combat offensif, sac, combat défensif, boutique). Les adversaires ont aussi un cavalier et son talent.

| Cavalier | Talent | Effet |
|---|---|---|
| L'Ombre | Embuscade | Au début de chaque combat, les armes lancent leur sort tout de suite |
| La Pousse | Croissance | Le sac commence avec une colonne de plus (5 au lieu de 4) |
| La Coquille | Éclosion | La monture commence chaque combat avec un bouclier de 40 |
| Le Capuchon | Érudit | La première relance de chaque boutique est gratuite |

Le cavalier tient **toutes les armes** du sac (voir Les armes du cavalier) : chacune vient d'une
relique de type Arme et lance son propre sort. Les catalyseurs voisins d'une arme s'appliquent à son sort.

La **Lance du guet** (Hast, estoc rapide qui **ignore l'esquive**) n'a pas d'élément : elle ne change
pas la forme de la monture, c'est un choix tactique pur. Une arme garde la couleur de son élément,
pas celle de la monture.

---

## 5. Reliques

| Type | Rôle |
|---|---|
| **Essence** | Affinité et stats brutes (PV, attaque, vitesse) |
| **Sort** | Capacité active avec recharge, plus forte si l'affinité de son élément est haute |
| **Catalyseur** | Modifie ses voisins orthogonaux |
| **Arme** | Tenue par le cavalier, lance son propre sort (autant que le sac en tient) |

### Format : 10 objets par Dynastie, un seul principe

Chaque Dynastie a **un grand principe** (un verbe, une ressource, un passif) et **10 objets** :
- **7 pour la monture** : 3 communs (essence offensive, essence défensive, sort qui produit la
  ressource), 2 rares (un catalyseur, une essence qui exploite la ressource), 1 épique qui renforce
  le principe, 1 légendaire qui en change une règle.
- **3 armes** d'**une seule famille** : commune, rare, légendaire.

Chaque objet produit la ressource ou l'exploite. Décidé le 2026-10-29 (`nid-vault/discussions/2026-10-29 Archétypes resserrés.md`) :
les 16 à 18 objets par Dynastie et leurs deux à quatre mécaniques rendaient les archétypes illisibles.

| Dynastie | Principe | Ressource | Famille | Passif |
|---|---|---|---|---|
| Été (Phénix) | Allumer puis consumer | Brûlure → combustion | Bâton | Renaît une fois à 50 %, et consume toutes les brûlures adverses |
| Hiver (Ours) | Ralentir jusqu'au gel | Givre → gel | Hache | Ses attaques posent du givre, +100 % contre une cible gelée |
| Printemps (Cerf) | Qui me touche s'empoisonne | Épines → poison | Tir | Épines 4 ; chaque riposte pose 1 dose de poison |
| Nuit (Chauve-souris) | Affaiblir avant de frapper | 3 malédictions | Faux | +30 % de dégâts par malédiction différente |
| Aube (Lion) | Soigner pour frapper | Éclat | Hast | Régénère 0,5 PV/s, ses soins chargent l'Éclat |
| Crépuscule (Papillon) | Lancer des sorts, semer des illusions | Illusions (2 au plus) | Bâton | Chaque sort de la monture crée une Illusion |
| Automne (Renard) | Esquiver, puis frapper juste | Esquive → crit | Lame | 15 % d'esquive ; après une esquive, crit garanti |
| Jour (Paon) | Faire la roue : enchaîner les armes | Éventail (10 au plus) | Tir | Chaque arme lancée donne 1 Éventail ; +8 % de dégâts et de recharge des armes par charge |

Les chiffres des tableaux sont ceux du code (`scripts/data.gd`) au 2026-10-29, après une première passe de réglage.

### Été (Phénix) : allumer puis consumer

**Brûlure** : s'empile (50 au plus), 2 dégâts par charge et par seconde, chaque charge s'éteint au bout de 5 s.
**Combustion** : consume des brûlures pour 4 dégâts par charge (x1,5 si totale). Brûlure et combustion passent le bouclier.

| Rareté | Objet | Effet |
|---|---|---|
| C | Charbon ardent | +3 attaque ; chaque attaque pose 1 brûlure |
| C | Cendre tiède | +40 PV ; les brûlures durent 1 s de plus |
| C | Graine de brasier (sort) | Toutes les 5 s : 3 brûlures (+0,3 par point d'Été) |
| R | Tison tenace (catalyseur) | Les voisins posent 50 % de brûlure en plus |
| R | Éclat d'obsidienne | Toutes les 8 brûlures posées : combustion partielle |
| É | Cœur de fournaise | La combustion laisse la moitié des charges en place |
| L | Œuf du Premier Brasier | Les brûlures ne s'éteignent plus ; une seconde renaissance |
| C | Bâton de braise | Boule de feu : 4 dégâts (+0,5 par point d'Été), 2 brûlures |
| R | Bâton du brasier | Combustion partielle |
| L | Bâton du Premier Brasier | Combustion totale, dégâts x2 |

### Hiver (Ours) : ralentir jusqu'au gel

**Givre** : chaque charge ralentit attaques et recharges de 3 % (40 % au plus). À 10 charges, la cible **gèle** 1,5 s : plus rien ne part, puis le givre retombe à zéro.

| Rareté | Objet | Effet |
|---|---|---|
| C | Flocon intact | +3 attaque ; +1 givre par attaque |
| C | Fourrure hivernale | +40 PV ; le gel dure 0,5 s de plus |
| C | Galet gelé (sort) | Souffle glacé : toutes les 5 s, 3 givre (+0,2 par point d'Hiver) |
| R | Croc du blizzard (catalyseur) | Les voisins posent 50 % de givre en plus |
| R | Cristal fêlé | Chaque gel inflige 30 dégâts |
| É | Cœur de banquise | Après un gel, la cible garde la moitié de son givre |
| L | Noyau de l'Hiver éternel | Le gel se déclenche à 6 charges au lieu de 10 |
| C | Hachette de givre | Coup lent de 18, 2 givre |
| R | Hache brise-glace | x2 contre une cible gelée |
| L | Hache du Grand Hiver | 3 givre ; prolonge de 1 s le gel d'une cible gelée |

### Printemps (Cerf) : qui me touche s'empoisonne

**Poison** : des doses qui s'empilent (100 au plus), 0,6 dégât par dose et par seconde, ne s'effacent pas et passent le bouclier.
**Épines** : blessent qui frappe le Cerf (attaque ou coup d'arme).

| Rareté | Objet | Effet |
|---|---|---|
| C | Épine de ronce | +40 PV ; +2 épines |
| C | Baie vénéneuse | +3 attaque ; chaque attaque pose 0,5 dose |
| C | Spore amère (sort) | Toutes les 6 s : 3 doses (+0,2 par point de Printemps) |
| R | Feuille d'ortie (catalyseur) | Les sorts et armes voisins posent 1 dose de plus |
| R | Liane barbelée | Chaque riposte d'épines pose 1 dose de plus |
| É | Fleur de belladone | Un adversaire empoisonné ne peut plus se soigner |
| L | Graine du Jardin interdit | À chaque coup reçu, le poison de l'attaquant inflige aussitôt une seconde de dégâts |
| C | Sarbacane de roseau | Fléchette : 2 dégâts, 2 doses |
| R | Arc de saule | 6 dégâts + les épines du Cerf |
| L | Arc du Jardin interdit | Tous les 2 coups reçus, une flèche de 4 qui pose 2 doses |

### Nuit (Chauve-souris) : affaiblir avant de frapper

**Malédictions** (6 s, renouvelées si on les repose) : **Faiblesse** (-15 % de dégâts infligés), **Flétrissure** (-30 % de soins reçus), **Stigmate** (+15 % de dégâts reçus).

| Rareté | Objet | Effet |
|---|---|---|
| C | Aiguille noire | +5 attaque ; 1 attaque sur 4 pose Stigmate |
| C | Sablier vermeil | +40 PV ; les malédictions durent 2 s de plus |
| C | Sceau de cire (sort) | Toutes les 4 s : Faiblesse |
| R | Poupée cousue (catalyseur) | Les sorts et armes voisins posent une malédiction manquante |
| R | Grimoire des noms perdus | Chaque nouvelle malédiction posée : 20 dégâts |
| É | Masque du festin | Quand les trois sont posées, elles ne s'effacent plus |
| L | Pacte de la Nuit profonde | Le passif compte double (+60 % par malédiction) |
| C | Faux lunaire | 10 dégâts, pose Flétrissure |
| R | Faux du festin | 12 dégâts, +35 % par malédiction sur la cible |
| L | Faux de la Nuit profonde | Consume toutes les malédictions : +15 par malédiction |

### Aube (Lion) : soigner pour frapper

**Éclat** : tous les soins chargent la jauge (0,75 par point, 2 par point de soin excédentaire). À 60, un coup de lumière de 45.
Un soin bloqué (Belladone) ou réduit (Flétrissure) charge quand même.

| Rareté | Objet | Effet |
|---|---|---|
| C | Bande de lin | +40 PV ; +1 PV/s |
| C | Miroir de poche | +3 attaque ; seuil d'Éclat -10 |
| C | Mèche de veille (sort) | Veille : toutes les 4 s, soigne 6 (+0,75 par point d'Aube) |
| R | Huile de première lumière (catalyseur) | Les sorts et armes voisins soignent 3 de plus |
| R | Voile de l'aube | Les soins excédentaires chargent l'Éclat deux fois plus |
| É | Carillon du réveil | Chaque Éclat soigne de 20 |
| L | Lanterne du Premier Matin | Les dégâts subis chargent aussi l'Éclat, à moitié |
| C | Lance de l'aurore | 6 dégâts, soigne 5 |
| R | Pique solaire | 8 dégâts + 10 % de la jauge d'Éclat |
| L | Lance du Premier Matin | 10 dégâts ; à mi-jauge, lance l'Éclat |

Les armes de l'Aube sont des Hast : elles percent l'esquive et les Illusions.

### Crépuscule (Papillon) : lancer des sorts, semer des illusions

**Illusion** : un double du Papillon (2 au plus). Elle encaisse une attaque ou un coup d'arme à sa place, puis éclate en projectile d'arcane de 5.
Seuls les sorts de la monture en créent avec le passif, pas les armes.

| Rareté | Objet | Effet |
|---|---|---|
| C | Poudre d'écailles | +3 attaque ; projectiles d'arcane +3 |
| C | Cocon | +40 PV ; commence avec 1 Illusion |
| C | Battement d'ailes (sort) | Toutes les 5 s : arcane de 10 (+0,5 par point de Crépuscule) |
| R | Pollen doré (catalyseur) | Les sorts et armes voisins rechargent 15 % plus vite |
| R | Mue | 3 Illusions au plus ; quand une Illusion éclate, le prochain sort part 1 s plus tôt |
| É | Phalène | À chaque sort lancé, chaque Illusion tire un projectile d'arcane |
| L | Chrysalide | Chaque sort se répète une fois, à moitié |
| C | Sceptre d'écailles | Arcane de 8 (+0,5 par point de Crépuscule) |
| R | Bâton de brume | 4 dégâts, crée 2 Illusions |
| L | Bâton de l'entre-deux | Fait éclater toutes les Illusions : 25 d'arcane chacune |

### Automne (Renard) : esquiver, puis frapper juste

**Esquive** : une attaque ou un coup d'arme esquivé ne fait rien (60 % au plus). Le Hast la perce.
**Crit** : x1,75. Les Lames donnent du crit à toute la monture (10 %, ou ce que l'arme précise).

| Rareté | Objet | Effet |
|---|---|---|
| C | Croc de renard | +3 attaque ; +8 % de crit |
| C | Feuille morte | +40 PV ; +5 % d'esquive |
| C | Bourrasque (sort) | Toutes les 6 s : +30 % d'esquive pendant 2 s |
| R | Pelage roux (catalyseur) | +8 % de crit pour chaque objet qui le touche |
| R | Bogue de châtaigne | Chaque esquive déclenche une contre-attaque |
| É | Œil du chasseur | Crits x2,5 au lieu de x1,75 |
| L | Queue du Vieux Renard | Après un crit, la prochaine attaque reçue est esquivée |
| C | Dague de feuille | Toutes les 1,5 s, 4 dégâts ; 20 % de crit |
| R | Lame rousse | 7 dégâts ; chaque crit la recharge 1 s plus tôt |
| L | Coutelas du Vieux Renard | 10 dégâts ; le crit qui suit une esquive fait x3 |

### Jour (Paon) : faire la roue

**Éventail** : chaque arme lancée en donne 1 (10 au plus) ; +8 % de dégâts et de vitesse de recharge des armes par charge. La Dynastie des builds d'armes.

| Rareté | Objet | Effet |
|---|---|---|
| C | Plume d'ocelle | +3 attaque ; commence avec 2 Éventail |
| C | Écu doré | +40 PV ; chaque arme lancée donne 6 de bouclier |
| C | Faire la roue (sort) | Toutes les 6 s : toutes les armes se rapprochent de 1 s |
| R | Broche de soleil (catalyseur) | Les armes et sorts voisins font +25 % de dégâts |
| R | Miroir d'ocelle | Chaque arme lancée inflige aussi 1 dégât par Éventail |
| É | Couronne de midi | L'Éventail monte jusqu'à 20 |
| L | Œil du Zénith | À 10 Éventail, chaque arme se lance deux fois |
| C | Arc à plumes | Volée : deux flèches de 3 |
| R | Arbalète dorée | 8 dégâts ; donne 2 Éventail au lieu de 1 |
| L | Arc du Zénith | Une flèche de 3, plus une par Éventail |

### Signature de dynastie

Chaque sort et chaque arme ajoute, à chaque activation, un petit effet de son élément (x niveau) :
Été 1 brûlure, Printemps 1 dose de poison, Hiver 1 givre, Nuit draine 5 PV, Aube soigne 3 PV,
Crépuscule un projectile d'arcane de 4, Automne une griffe de 3, Jour 3 de bouclier.
Chaque essence en donne un cinquième à chaque attaque de la monture.

### Familles d'armes

Chaque arme appartient à une **famille**, partagée entre Dynasties. **Une seule famille par Dynastie** ;
Bâton (Été, Crépuscule) et Tir (Printemps, Jour) sont partagées.

| Famille | Style | Dynasties |
|---|---|---|
| Tir | Rapide, plusieurs petits coups | Printemps, Jour |
| Lame | Rapide, **coups critiques** | Automne |
| Hast | Allonge, **perce l'esquive et les Illusions** | Aube, Lance du guet (neutre) |
| Hache | Lent, gros coup | Hiver |
| Bâton | Magie, grandit avec l'affinité | Été, Crépuscule |
| Faux | Plus forte contre une cible maudite | Nuit |

---

## 6. Pas d'avantage élémentaire

**Aucun élément ne bat un autre.** Pas de triangle, pas de multiplicateur caché.

Le contre-jeu passe par les mécaniques des sorts, lisibles à l'écran :
- Le gel de l'Hiver coupe les recharges adverses.
- Les épines du Printemps punissent les builds à beaucoup de petits coups (et les armes du Jour).
- La Belladone et la Flétrissure gênent l'Aube, qui charge quand même son Éclat.
- Le Hast de l'Aube perce l'esquive de l'Automne et les Illusions du Crépuscule.

On adapte son Nid à ce qu'on affronte, pas à une couleur.

---

## 7. Combat

- Simulation déterministe par pas de 0,1 s : même Nids, même résultat.
  Indispensable pour rejouer un combat asynchrone à l'identique.
- Attaques de base selon la vitesse, sorts sur leur recharge.
- Mort subite après 30 s : dégâts croissants des deux côtés, pas de match nul interminable.
- **Affichage = relecture** : le combat est simulé en entier d'abord, l'écran rejoue
  ses événements et ses PV. L'animation ne peut donc jamais changer le résultat.

---

## 8. Prototype (périmètre actuel)

- 6 Dynasties au format 15 objets : Printemps, Été, Hiver, Aube, Crépuscule, Nuit ; 1 arme neutre
  (Lance du guet). Restent l'Automne (Renard) et le Jour (Paon), montures prêtes. Vent et Terre sont retirés.
- Run sur carte : 3 actes de 10 étages, Ferveur, boutique facultative entre les nœuds,
  trois rencontres. Trois élites à règle et le gardien de l'acte I (Bastion endormi) ; les boss
  des actes II et III sont encore des fantômes en avance.
- Choix des dynasties, puis du cavalier et de son talent.
- Arène : vitesse x1 ou x2.
- Sac de 4 à 8 colonnes sur 4 rangées, reliques à formes (1 à 4 cases), rotation.
- Hybrides en place (28 images). Rareté et fusion en place. Pas de réseau.
- Boutique, manches, combat animé contre un adversaire généré, fin de partie.

**Question à valider avec le prototype** : est-ce que voir sa créature changer selon son Nid
donne envie de refaire un Nid ? Si non, rien d'autre ne compte.

---

## 9. Plus tard

- Formes à la main pour les objets dont l'image le demande (`FORMES_OBJETS`).
- Objets neutres qui visent une famille d'armes.
- Les sets de l'Automne (Renard) et du Jour (Paon).
- Les gardiens des actes II et III.
- 8 Dynasties donnent 28 paires d'hybrides : il faudra peut-être n'en garder qu'une partie.
- Stades d'évolution (visuel qui grandit).
- PvP asynchrone : stocker le Nid de chaque joueur par manche (Supabase), tirer un fantôme du même stade.
