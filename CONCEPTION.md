# Nid

*(titre de travail)*

**Autobattler PvP asynchrone. On remplit un Nid de reliques, il en éclot une créature qui se bat seule. Godot 4, 2D.**

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

## 2. Boucle

1. **Boutique** : acheter des reliques avec l'or de la manche.
2. **Nid** : les placer dans une grille. L'adjacence compte.
3. **Éclosion** : le Nid fixe la forme, les stats et les sorts de la créature.
4. **Combat automatique** contre la créature fantôme d'un autre joueur au même stade.
5. Victoire ou défaite, la créature évolue (stade 1, 2, 3) et on recommence.

Fin de partie : **7 victoires ou 3 défaites**. Une égalité ne compte pas.

### Boutique et or

- **10 or par manche**, l'or non dépensé se garde.
- **5 offres** tirées au hasard, **relance pour 1 or**.
- Prix : essence 3, sort 4, catalyseur 4, arme 5.
- **On achète en posant** : glisser une offre dans une case vide du Nid.
- **Revente à moitié prix** (au moins 1 or) : ramener la relique à la boutique, ou clic droit.
- Tout le hasard passe par une graine : même graine, mêmes boutiques, mêmes adversaires.

- Prix : celui du type (essence 3, sort 4, catalyseur 4, arme 5) **+ la rareté**
  (rare +2, épique +4, légendaire +7).

### Rareté

Commun, rare, épique, légendaire. Les chances de tirage en boutique dépendent de la manche :

| À partir de la manche | Commun | Rare | Épique | Légendaire |
|---|---|---|---|---|
| 1 | 100 % | | | |
| 2 | 75 % | 25 % | | |
| 4 | 55 % | 30 % | 15 % | |
| 6 | 40 % | 30 % | 20 % | 10 % |

Les légendaires ne fusionnent pas. Une tuile non commune porte une bande de couleur
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

Par élément (joueur simple, avec l'Aube) : **Terre 4,1**, Feu 3,2, Vent 3,2, Nature 2,8, Glace 2,7,
Aube 2,6, Nuit 2,6. Joueur simple : 3,0 victoires en moyenne, 20 % de parties gagnées.

### Fusion

**3 copies d'une relique au même niveau fusionnent** en une seule relique du niveau suivant
(★ niveau 2, ★★ niveau 3), à la place de la dernière posée.
- Stats multipliées : x2,5 au niveau 2, x6 au niveau 3. Un peu moins que trois copies
  (x3), mais deux cases libérées.
- L'affinité des trois copies est conservée : fusionner ne change pas la forme de la monture.
- Voile (sans dégâts) : recharge plus rapide. Foyer : brûlure plus forte. Lune creuse : plus de vol de vie.
- Nid plein : on peut poser une offre **sur une copie** si elle complète un trio.
- Les armes ne fusionnent pas (une seule par Nid).
- Revente : la moitié de ce qu'elle a coûté (3 copies par niveau).

C'est la progression de fin de partie : le Nid de 16 cases se remplit vers la manche 6, et
avant la fusion l'or ne servait plus à rien ensuite. La répartition des victoires était en
deux bosses (beaucoup de 0 à 2, un pic à 7, presque rien entre 4 et 6). Elle est maintenant
régulière.

---

## 3. Forme de la créature

Chaque relique donne des points d'**affinité** dans un élément.

- **Élément dominant** : fixe la forme de base, son identité de jeu et un passif.

### Les neuf éléments

Deux familles : **cinq éléments de la nature** et **quatre moments du jour**.

| Famille | Élément | Monture | Identité | Ce qui la rend unique |
|---|---|---|---|---|
| Nature | Vent | Cheval | Esquive, orage | Esquive **au hasard**, et chaque esquive charge l'orage qui frappe en retour |
| Nature | Terre | Tortue | Bouclier, fatigue | **Veut des combats longs** : bouclier qui se recharge, fait venir la fatigue plus tôt chez l'adversaire et y résiste mieux |
| Nature | Glace | Loup | Gel | Le gel **bloque les recharges** de sorts adverses (pas les attaques) |
| Nature | Feu | Phénix | Brûlure, hâte | Dégâts sur la durée, attaque de plus en plus vite. Renaît une fois à 25 % de PV |
| Nature | Nature | Cerf | Épines, poison | Punit qui le frappe (épines), poison qui s'accumule |
| Jour | Aube | Lion | Soin | Soins et régénération, se relève des combats serrés |
| Jour | Lumière | Raie | Illusion | Crée des **leurres** qui absorbent des coups (différent de l'esquive du Vent) |
| Jour | Crépuscule | Papillon | Transfert | **Vole les bonus** adverses et **renvoie ses malus** à l'envoyeur : le moment où tout s'inverse |
| Jour | Nuit | Chauve-souris | Vol de vie, malédictions | Se soigne en frappant, affaiblit l'adversaire |

Paires à garder distinctes :
- **Vent / Lumière** : le Vent évite au hasard puis contre-attaque, la Lumière place des leurres visibles.
- **Glace / Crépuscule** : la Glace ralentit la machine adverse, le Crépuscule retourne ses effets contre elle.
- **Aube / Nature** : l'Aube soigne, la Nature punit. Le Cerf ne régénère plus.

Le Crépuscule n'a de sens que face à un build qui a des bonus ou des malus à voler :
contre un build d'attaques brutes, il doit rester correct mais sans éclat.

- **Hybride** (plus tard) : deux éléments au-dessus d'un seuil donnent une forme mixte
  (Feu + Nuit : Wyverne cendrée, Glace + Nature : Ours de toundra...).
  Plus de variété de sorts, passif plus faible. Pur = spécialisé et fort.
- **Aucune affinité** : créature informe, sans passif.

### Le cavalier

La créature est une **monture** : un petit cavalier encapuchonné (visage sombre, deux yeux
lumineux) est assis dessus. Sa cape prend la couleur de l'élément dominant.
Le cavalier tient **une seule arme**, qui vient d'une relique de type Arme et lance
son propre sort. Les catalyseurs voisins de l'arme s'appliquent à ce sort.

| Arme | Élément | Sort du cavalier |
|---|---|---|
| Bâton de braise | Feu | Boule de feu, dégâts selon l'affinité Feu |
| Lance du guet | Aucun | Estoc, rapide, **ignore l'esquive** (contre le Voile) |
| Faux lunaire | Nuit | Moisson, lente, **double sous 40 % de PV** |

La lance n'a pas d'élément : elle ne change pas la forme de la monture, c'est un choix
tactique pur. L'arme garde la couleur de son élément, pas celle de la monture.

---

## 4. Reliques

| Type | Rôle |
|---|---|
| **Essence** | Affinité et stats brutes (PV, attaque, vitesse) |
| **Sort** | Capacité active avec recharge, plus forte si l'affinité de son élément est haute |
| **Catalyseur** | Modifie ses voisins orthogonaux |
| **Arme** | Une seule par Nid, tenue par le cavalier, lance son propre sort |

### Lots par élément (4 reliques chacun : essence, essence ou sort, sort, catalyseur)

- **Feu** : Braise, Plume de cendre, Souffle ardent, Foyer (ancien lot, remplacé par le set du Phénix ci-dessous)
- **Nuit** : Croc noir, Nuée, Voile, Lune creuse (ancien lot, remplacé par le set de la Chauve-souris ci-dessous)
- **Terre** : Pierre (+PV), Écaille (bouclier de départ), Rempart (sort de bouclier), Socle (les sorts voisins donnent du bouclier) (fait)
- **Vent** : Sabot (attaque, vitesse), Crin (esquive), Rafale (3 coups rapides), Girouette (les sorts voisins rechargent plus vite) (fait)
- **Glace** : Éclat, Carapace gelée, Prison de glace, Cœur d'hiver
- **Nature** : Racine, Ronces, Sève, Graine mère
- **Aube, Lumière, Crépuscule** : à concevoir

Règles de Terre et Vent :
- **Bouclier** : encaisse les coups avant les PV. La brûlure et la fatigue passent à travers.
- **Tortue** : la fatigue de l'adversaire commence 10 s plus tôt (à 20 s), la sienne est réduite de moitié.
  Ses combats durent 27 à 35 s, plus que la cible de 15 à 25 s : c'est son identité.
- **Cheval** : 15 % d'esquive (plafond 50 % avec les Crins), chaque esquive lance un éclair de 10 dégâts
  qui ne s'esquive pas. Le tirage est fait avec une graine fixe : le combat reste déterministe.
  L'Estoc de la lance ignore aussi cette esquive.
- Fatigue : les dégâts montent de 2 par seconde chaque seconde après son début.

Résultats en partie simulée (joueur simple, 400 parties) : Terre 3,3 victoires en moyenne,
Vent 3,2, Feu 2,1, Nuit 1,5. **La Nuit est à remonter.**

---

### Format cible : 15 objets par archétype

Chaque élément aura **15 objets** :
- **10 pour la monture** : 4 communs, 3 rares, 2 épiques, 1 légendaire.
- **5 armes pour le cavalier** : 2 communes, 1 rare, 1 épique, 1 légendaire.

Le prototype n'a encore que 4 objets de monture par élément (Feu, Nuit, Terre, Vent) et
3 armes partagées. Les lots ci-dessus seront refaits à ce format.

La rareté est décrite dans la section Boutique.

### Nature (Cerf) : épines et poison

**Fait** (images de `images/`, découpées par `outils/decouper_icones.gd`). Chiffres de départ :
épines du Cerf 2 par coup reçu, Épine de ronce +2, Baie 0,5 dose par attaque, Nuage de spores
2 doses + 0,2 par point de Nature toutes les 6 s, poison 0,2 dégât par dose et par seconde,
Ortie et Amanite +50 % à leurs voisins, Gousse : salve de 15 tous les 5 coups reçus.

Deux axes avec des ponts entre eux. **Les épines** blessent qui frappe le Cerf (contre les builds
à beaucoup de petits coups : Rafale, Nuée). **Le poison** s'accumule sur la cible.

Règles du poison et des épines :
- **Le poison s'empile** : chaque application ajoute des doses, chaque dose fait des dégâts par
  seconde, et les doses durent longtemps. **Il passe à travers le bouclier** (contre la Tortue).
  À distinguer de la brûlure du Feu : courte, intense, elle se renouvelle au lieu de s'empiler.
- **Plafond de 100 doses** de poison sur une cible.
- **Les épines** se déclenchent à chaque coup reçu (attaque ou sort), pas sur la brûlure,
  le poison ni la fatigue.

#### Monture (10)

| Rareté | Objet | Apparence | Effet |
|---|---|---|---|
| Commun | Épine de ronce | Une longue épine courbée, vert sombre | Ajoute des dégâts d'épines lorsqu'on est attaqué |
| Commun | Baie vénéneuse | Une petite grappe de baies violettes | Les attaques appliquent un peu de poison |
| Commun | Feuille d'ortie | Une feuille dentelée aux nervures claires | **Catalyseur** : renforce les épines des objets voisins |
| Commun | Spore amère | Une petite vesse-de-loup verdâtre | **Sort** *Nuage de spores* : toutes les 6 s, un nuage de poison visible |
| Rare | Liane barbelée | Une liane enroulée, couverte de crochets | Les ripostes d'épines appliquent aussi du poison |
| Rare | Amanite pourpre | Un champignon violet à quelques taches crème | **Catalyseur** : renforce le poison appliqué par les objets voisins |
| Rare | Gousse éclatante | Une capsule sèche entrouverte, pleine de graines pointues | Après plusieurs attaques reçues, projette une salve d'épines |
| Épique | Fleur de belladone | Une fleur en cloche sombre accompagnée d'une baie brillante | **Un adversaire empoisonné ne peut plus se soigner** (soins, vol de vie, régénération) |
| Épique | Cœur de roncier | Un nœud de racines épineuses autour d'un cœur vert | Les déclenchements d'épines renforcent les prochaines ripostes, **jusqu'à x2 au maximum** |
| Légendaire | Graine du Jardin interdit | Une graine fendue, laissant sortir une pousse dorée aux épines violettes | Chaque déclenchement d'épines intensifie le poison ; chaque déclenchement du poison fait pousser les épines. **Plafonds : 100 doses de poison, épines x2 au maximum** |

#### Armes du cavalier (5)

| Rareté | Arme | Sort du cavalier | Rôle |
|---|---|---|---|
| Commun | Sarbacane de roseau | *Fléchette* : petit dard rapide (toutes les 2 s), pose 1 dose de poison | Prépare le poison |
| Commun | Dague d'épine | *Contre* : après 4 coups reçus, le cavalier frappe en retour, plus fort avec des épines | Défense, pont vers les épines |
| Rare | Arc de saule | *Flèche de chasse* (toutes les 5 s) : dégâts augmentés par dose de poison sur la cible | Récolte le poison |
| Épique | Serpe de ronces | *Lacération* : 4 coups rapides qui infligent des dégâts d'épines (profitent des bonus d'épines) | Fait des épines une attaque (Lame, remplace le Fouet) |
| Légendaire | Arc du Jardin interdit | *Flèche-graine* : se plante dans la cible ; chaque dose de poison qu'elle reçoit ensuite la blesse aussi d'épines | Assorti à la Graine du Jardin interdit |

Les plafonds (x2, 100 doses) sont des valeurs de départ, à régler par simulation.

---

### Familles d'armes

Chaque arme appartient à une **famille**, partagée entre plusieurs éléments. Les futurs objets
neutres viseront une famille (« Carquois : les arcs tirent une flèche de plus ») : builds
croisés, objets neutres utiles sans être universels, style lisible quel que soit l'élément.
**Chaque élément utilise une ou deux familles.**

| Famille | Style | Armes actuelles |
|---|---|---|
| Tir | Rapide, plusieurs petits coups | Sarbacane de roseau, Arc de saule, Arc du Jardin interdit |
| Lame | Rapide, riposte, **coups critiques** | Dague d'épine, Serpe de ronces, armes de la Nuit |
| Hast | Allonge, perce l'esquive | Lance du guet (neutre), armes du Loup |
| Hache | Lent, gros coup | armes du Loup, armes du Lion |
| Bâton | Magie, grandit avec l'affinité | armes du Phénix, armes du Lion |
| Faux | Achève les cibles affaiblies | Faux de tison, Faux des cendres, armes de la Nuit |

Familles par élément : **Cerf : Tir et Lame. Loup : Hast et Hache. Phénix : Bâton et Faux. Nuit : Faux et Lame.
Lion : Bâton et Hache.**

**Coups critiques** : identité de la famille Lame. Un crit fait **x1,75** de dégâts ; les chances
viennent des armes Lame et de certains objets (aucune chance de base). Les Lames du Cerf
(Dague d'épine, Serpe de ronces) en profiteront aussi.

**Faux** : toutes partagent le trait « achever » (plus fortes contre une cible affaiblie), sur
lequel jouera un futur objet neutre. Chaque élément y ajoute sa saveur : le feu pour le Phénix,
le drain et les malédictions pour la Nuit.

### Glace (Loup) : givre et bouclier qui se brise

**Fait** (images de `images/`). Chiffres de départ : passif du Loup, 1 charge de givre par attaque
et **+50 % de dégâts contre une cible gelée** (le gel est une fenêtre d'attaque, sinon le Loup
jouait comme une seconde Tortue : combats de 24 à 40 s, trop peu de dégâts) ; Armure de givre
6 + 1 par point de Glace ; Éclat de givre 20 ; Javelot 8 ; Écorce 20 de bouclier 3 s après un bris ;
Cœur de banquise 25 ; Noyau 20 ; Rose des neiges 3 charges de moins.

Là où la Tortue veut que son bouclier tienne, **le Loup veut qu'il se brise** : chaque bris
déclenche des effets. C'est le même bouclier que la Terre (plus simple à lire) : les hybrides
Terre et Glace sont à surveiller en simulation. Le poison du Cerf passe à travers le bouclier
sans le briser : le Loup souffre contre la Nature, c'est voulu.

Règles du givre :
- Chaque **charge de givre** ralentit les attaques **et** les recharges de sorts de la cible
  (3 % par charge pour commencer).
- À **10 charges**, la cible **gèle** : plus rien ne part pendant 1,5 s, puis ses charges
  retombent à zéro.

#### Monture (10)

| Rareté | Objet | Effet |
|---|---|---|
| Commun | Flocon intact | Les attaques appliquent du givre |
| Commun | Galet gelé | **Sort** *Armure de givre* : un petit bouclier toutes les 6 s |
| Commun | Éclat de givre | Inflige des dégâts lorsque ton bouclier est brisé |
| Commun | Fourrure hivernale | **Catalyseur** : plus de bouclier pour les objets voisins |
| Rare | Croc du blizzard | **Catalyseur** : les objets voisins posent 50 % de givre en plus |
| Rare | Écorce de pergélisol | Reforme un petit bouclier après un délai lorsqu'il est brisé |
| Rare | Cristal fêlé | Les dégâts de bris du bouclier appliquent aussi du givre |
| Épique | Cœur de banquise | Geler la cible accorde du bouclier |
| Épique | Rose des neiges | Quand le bouclier est brisé, le prochain gel demande moins de charges |
| Légendaire | Noyau de l'Hiver éternel | Quand le bouclier est brisé : une nova qui inflige des dégâts et gèle immédiatement la cible si elle est déjà ralentie |

#### Armes du cavalier (5, Hast et Hache)

| Rareté | Arme | Famille | Sort du cavalier |
|---|---|---|---|
| Commun | Javelot de stalactite | Hast | Lancer toutes les 3 s qui pose 2 charges de givre |
| Commun | Hachette de givre | Hache | Gros coup lent, doublé contre une cible ralentie |
| Rare | Pique de banquise | Hast | Perce l'esquive, double les charges de givre posées |
| Épique | Hache brise-glace | Hache | *Fracas* : brise ton propre bouclier et ajoute sa valeur aux dégâts (déclenche les effets de bris) |
| Légendaire | Lance du Grand Hiver | Hast | Brise le gel de la cible pour un coup énorme |

---

### Feu (Phénix) : brûlure, combustion, Braise

**Fait** (images de `images/`). Chiffres de départ : brûlure 1,5 dégât par charge et par seconde,
4 s par charge, 50 charges au plus ; combustion 4 par charge consumée (x1,5 si totale) ; Braise
+4 % de vitesse par point, 10 au plus ; Charbon 1 brûlure par attaque ; Embrasement toutes les 5 s ;
Cendre tiède 4 PV par combustion, Fleur 1 PV par charge consumée ; Éclat d'obsidienne +4 ;
Résine : brûlure doublée sous 50 % de PV ; Cœur de fournaise : +5 Braise pendant 6 s.
La combustion passe à travers le bouclier, comme la brûlure.

**On allume, puis on consume.** La brûlure s'accumule sur la cible, puis une **combustion** la
fait exploser d'un coup. Le Phénix **brûle plus fort au bord de la mort** (Résine ambrée, Cœur
de fournaise, renaissance). Familles d'armes : **Bâton et Faux** (la Faux est partagée avec la Nuit).

Ce set remplace les anciens objets du Feu (Braise, Plume de cendre, Souffle ardent, Foyer).
Le Bâton de braise garde son nom avec sa nouvelle version.

Règles :
- **Brûlure** : s'empile, mais **chaque charge s'éteint au bout de 4 s**, il faut l'entretenir.
  Le poison, lui, s'empile et dure tout le combat sans jamais être consommé.
- **Combustion** : consume les brûlures de la cible pour des dégâts immédiats.
  *Partielle* : la moitié des charges. *Totale* : toutes, avec un bonus.
- **Braise = hâte** : +1 Braise à chaque combustion déclenchée (jusqu'à 10), chaque point
  accélère attaques et recharges de sorts. C'est l'inverse du givre du Loup, les deux se
  compensent. (Le crit reste à concevoir, pour une autre famille ou un autre élément.)
- **Renaissance** (passif) : une fois, à 25 % de PV.

#### Monture (10)

| Rareté | Objet | Apparence | Effet |
|---|---|---|---|
| Commun | Charbon ardent | Un morceau de charbon noir fendu d'orange | Les attaques appliquent de la brûlure |
| Commun | Plume incandescente | Une plume rouge à la pointe dorée | **Catalyseur** : brûlure des objets voisins +50 % |
| Commun | Tison tenace | Un petit morceau de bois rougeoyant | **Catalyseur** : Braise gagnée par les objets voisins +50 % |
| Commun | Cendre tiède | Un petit tas de cendres claires abritant une braise | Chaque combustion rend un peu de vie |
| Rare | Graine de brasier | Une graine sombre dont sort une petite flamme | **Sort** *Embrasement* : une combustion partielle toutes les 7 s |
| Rare | Éclat d'obsidienne | Une lame de pierre noire au bord rougeoyant | Les attaques contre une cible en feu infligent des dégâts supplémentaires |
| Rare | Résine ambrée | Une goutte épaisse d'ambre contenant une étincelle | Renforce les nouvelles brûlures quand ta vie est basse |
| Épique | Cœur de fournaise | Un cœur de roche sombre au centre incandescent | En passant sous la moitié de ta vie : une combustion et un fort bonus de Braise temporaire. Une fois par combat |
| Épique | Fleur des cendres | Une fleur aux pétales gris, orange vif au centre | Les soins des combustions augmentent selon les charges consumées |
| Légendaire | Œuf du Premier Brasier | Un œuf rouge sombre fendu, éclairé d'or de l'intérieur | **Seconde renaissance** ; chaque renaissance déclenche une combustion totale |

#### Armes du cavalier (5, Bâton et Faux)

| Rareté | Arme | Famille | Sort du cavalier |
|---|---|---|---|
| Commun | Bâton de braise | Bâton | Une étincelle qui applique de la brûlure, dégâts selon l'affinité Feu |
| Commun | Faux de tison | Faux | Plus de dégâts contre une cible sous la moitié de sa vie |
| Rare | Bâton du brasier | Bâton | Applique plus de brûlure selon l'affinité Feu |
| Épique | Faux des cendres | Faux | Contre une cible affaiblie : une combustion qui consume ses brûlures et soigne le Phénix |
| Légendaire | Bâton du Premier Brasier | Bâton | Une combustion totale après plusieurs tirs ; la renaissance déclenche aussitôt un tir renforcé |

Points ouverts :
- **Faux de tison et Faux lunaire** : réglé avec le set de la Nuit (trait « achever » commun,
  saveur propre à chaque élément).
- **Le Phénix se soigne** (Cendre tiède, Fleur, Faux des cendres) : à surveiller face à l'Aube,
  dont le soin est l'identité. La Belladone du Cerf le contre.

### Nuit (Chauve-souris) : vol de vie et malédictions

**Fait** (images de `images/`, le Chapelet et la Serpe de ronces dans `chapelet_serpe.png`). Chiffres : malédictions 6 s, Faiblesse -15 %
de dégâts, Langueur -15 % de vitesse d'attaque, Flétrissure -30 % de soins par charge ; passif
de la Chauve-souris **+12 % de dégâts par malédiction différente sur la cible** (sans lui, et
sans attaque sur ses essences, elle ne faisait presque aucun dégât : 0,8 victoire en moyenne) ;
Ruban sanguin +2 attaque et 8 % de vol de vie ; Aiguille noire +2 attaque, Faiblesse toutes les
3 attaques ; Sceau toutes les 6 s ; Sablier +3 s ; Poupée 30 % ; Masque +6 % de vol de vie par
malédiction ; Grimoire tous les 40 PV volés ; Pacte 5 par attaque. Crit : x1,75, 10 % par Lame
(25 % pour la Dague de minuit, 15 % pour la Lame de la veuve), 8 % pour le Peigne.

Deux axes : **le vol de vie** et **les malédictions**, trois états qui affaiblissent l'adversaire.
Des objets **comptent les malédictions différentes** (Masque, Grimoire, Pacte) ; le Chapelet
permet au contraire d'**empiler la même** : un choix de build en largeur ou en profondeur.
Familles d'armes : **Faux et Lame**. Ce set remplace l'ancienne Nuit (Croc noir, Nuée, Voile,
Lune creuse). Passif de la Chauve-souris inchangé : vol de vie sur les attaques de base.

Règles des malédictions :
- **Faiblesse** : la cible inflige moins de dégâts.
- **Langueur** : la cible attaque moins vite (attaques seulement, pas les sorts ; pourcentage fixe
  et durée limitée, là où le givre du Loup s'accumule, touche aussi les sorts et finit en gel).
- **Flétrissure** : la cible reçoit moins de soins (réduction, là où la Belladone du Cerf bloque
  tout soin, mais seulement sur une cible empoisonnée).
- **Durée : 6 s**, renouvelée si on la réapplique. Sans le Chapelet, une malédiction ne compte
  qu'une fois. Avec lui, jusqu'à 3 charges : Faiblesse -10 % de dégâts par charge, Langueur -10 %
  de vitesse d'attaque par charge, Flétrissure -25 % de soins par charge (valeurs de départ).

#### Monture (10)

| Rareté | Objet | Effet |
|---|---|---|
| Commun | Ruban sanguin | Accorde du vol de vie aux attaques |
| Commun | Aiguille noire | Après plusieurs attaques, applique Faiblesse |
| Commun | Sceau de cire | **Sort** *Sceau* : applique Langueur toutes les 8 s |
| Commun | Sablier vermeil | Prolonge les malédictions que tu appliques |
| Rare | Poupée cousue | Une partie des dégâts reçus est renvoyée à l'adversaire tant qu'il est maudit |
| Rare | Peigne de la veuve | Les coups critiques appliquent Flétrissure |
| Rare | Chapelet des rancunes | *Un chapelet de perles noires dont une seule rougeoie* : chaque malédiction peut s'empiler jusqu'à 3 fois |
| Épique | Masque du festin | Plus de vol de vie pour chaque malédiction différente sur l'adversaire |
| Épique | Grimoire des noms perdus | Après une certaine quantité de vie volée, applique une malédiction manquante |
| Légendaire | Pacte de la Nuit profonde | Quand la cible porte les trois malédictions, tes attaques drainent aussi un peu de vie, indépendamment de leurs dégâts (le drain passe le bouclier) |

La Coupelle d'étain (bonus de vol de vie) a été retirée au profit du Chapelet.

#### Armes du cavalier (5, Faux et Lame)

| Rareté | Arme | Famille | Sort du cavalier |
|---|---|---|---|
| Commun | Dague de minuit | Lame | Coups rapides, fortes chances de crit |
| Commun | Faux lunaire | Faux | Achève sous 40 % de vie **et vole de la vie** (retravaillée) |
| Rare | Lame de la veuve | Lame | Chaque crit pose une malédiction au hasard |
| Épique | Faux du festin | Faux | Plus forte pour chaque malédiction sur la cible |
| Légendaire | Faux de la Nuit profonde | Faux | Consume toutes les malédictions de la cible pour un coup énorme et un gros drain |

### Aube (Lion) : soin et Éclat

**Fait** (images de `images/`). Chiffres : régénération du Lion 1,5 PV/s ; charge 0,75 par point
de soin et 2 par point d'excédent (le Voile ajoute +100 % sur l'excédent) ; seuil 60 (Miroir -10,
20 au moins) ; Éclat 40 dégâts (Prisme +15, Lanterne + l'excédent accumulé) ; Veille (Mèche) 8 de
soin + 1 par point d'Aube toutes les 4 s ; Bande de lin +2 PV/s sous 50 % ; Encensoir +3 PV/s pendant
4 s ; Vasque 50 % de l'excédent en bouclier ; Carillon 40 tous les 3 Éclats. L'outil de découpe
retire maintenant aussi les « poussières » (petits îlots isolés) des icônes et des montures.

**On stocke du soin pour frapper.** Un soigneur qui ne fait que se soigner ne gagne jamais : ici,
chaque soin charge une jauge d'**Éclat**, qui part en coup de lumière sur l'adversaire.
Familles d'armes : **Bâton et Hache** (chacune partagée avec un autre élément).

Règles :
- **Passif du Lion** : régénère un peu en continu, et **ses soins chargent l'Éclat**. La jauge est
  propre au Lion ; hors Lion, les objets d'Éclat ne serviront qu'aux futurs hybrides.
- **Charge** : tous les soins chargent l'Éclat **à moitié** ; les **soins excédentaires** (au-delà
  des PV max) comptent **double** (plus avec le Voile de l'aube).
- **Éclat** : quand la jauge atteint son seuil (60 pour commencer, moins avec le Miroir de poche),
  il part : un coup de lumière sur l'adversaire (plus fort avec le Prisme d'aurore).
- **Un soin bloqué** (Belladone) ou réduit (Flétrissure) charge quand même l'Éclat à moitié :
  le Lion reste gêné par ces contres, sans être neutralisé.

#### Monture (10)

| Rareté | Objet | Apparence | Effet |
|---|---|---|---|
| Commun | Mèche de veille | Une courte mèche allumée dans une coupelle de céramique pêche | **Sort** *Veille* : rend un peu de vie à intervalles réguliers |
| Commun | Huile de première lumière | Une petite burette ivoire laissant perler une goutte dorée | **Catalyseur** : soins des objets voisins +50 % |
| Commun | Miroir de poche | Un miroir rond en cuivre pâle, avec un manche court | Réduit le seuil de l'Éclat |
| Commun | Bande de lin | Une bande crème roulée, dont une extrémité se déroule | Sous la moitié de ta vie, renforce la régénération |
| Rare | Encensoir du matin | Un brûle-parfum trapu, percé de trois ouvertures, avec une volute de fumée rose | Chaque Éclat renforce temporairement la régénération |
| Rare | Vasque de rosée | Une vasque peu profonde sur un petit pied, contenant une eau nacrée | **Les soins excédentaires deviennent du bouclier** |
| Rare | Prisme d'aurore | Un prisme triangulaire laissant passer trois larges bandes de lumière pêche et or | Augmente les dégâts de l'Éclat |
| Épique | Voile de l'aube | Une étoffe légère, crème et rose, tenue par une attache de cuivre | Les soins excédentaires chargent davantage l'Éclat |
| Épique | Carillon du réveil | Trois petites cloches plates suspendues à une arche dorée | Tous les trois Éclats, un soin important |
| Légendaire | Lanterne du Premier Matin | Une lanterne ronde en céramique ajourée, abritant un soleil flottant, avec deux anses en volutes | L'Éclat ajoute à ses dégâts les soins excédentaires accumulés depuis le dernier Éclat |

#### Armes du cavalier (5, Bâton et Hache)

| Rareté | Arme | Famille | Sort du cavalier |
|---|---|---|---|
| Commun | Sceptre de l'aurore | Bâton | Un rayon dont les dégâts grandissent avec l'affinité Aube |
| Commun | Hachette du matin | Hache | Un coup lent qui charge l'Éclat |
| Rare | Bâton de rosée | Bâton | Chaque tir soigne un peu ; l'excédent nourrit l'Éclat |
| Épique | Hache solaire | Hache | Après chaque Éclat, le prochain coup est doublé |
| Légendaire | Sceptre du Premier Matin | Bâton | Un Éclat gratuit tous les quelques tirs |

Points à surveiller : la **Vasque** crée un pont avec la Terre et la Glace (bouclier, effets de bris) ;
le Lion est contré par la Nature (Belladone) et la Nuit (Flétrissure), adouci par la règle ci-dessus.

## 5. Pas d'avantage élémentaire

**Aucun élément ne bat un autre.** Pas de triangle, pas de multiplicateur caché.

Le contre-jeu passe par les mécaniques des sorts, lisibles à l'écran :
- Prison de glace (gel des recharges) coupe une Nuée avant qu'elle parte.
- Ronces (renvoie les dégâts) punit les builds à beaucoup de petits coups.
- Le vol de vie de la Nuit tient face au soin de l'Aube.
- La Tortue punit les builds lents, le Cheval punit les builds à gros coups uniques.
- Le Papillon punit les builds qui empilent bonus et malus.

On adapte son Nid à ce qu'on affronte, pas à une couleur.

---

## 6. Combat

- Simulation déterministe par pas de 0,1 s : même Nids, même résultat.
  Indispensable pour rejouer un combat asynchrone à l'identique.
- Attaques de base selon la vitesse, sorts sur leur recharge.
- Mort subite après 30 s : dégâts croissants des deux côtés, pas de match nul interminable.
- **Affichage = relecture** : le combat est simulé en entier d'abord, l'écran rejoue
  ses événements et ses PV. L'animation ne peut donc jamais changer le résultat.

---

## 7. Prototype (périmètre actuel)

- 7 éléments : Terre, Vent (4 objets chacun), Feu, Nature, Glace, Nuit et Aube (15 objets chacun),
  1 arme neutre (Lance du guet).
- Nid 4 x 4, reliques d'une case. **Les formes de reliques (2 x 1, L...) viendront après.**
- Pas d'hybride, pas de réseau. Rareté en place.
- Boutique, manches, combat animé contre un adversaire généré, fin de partie.

**Question à valider avec le prototype** : est-ce que voir sa créature changer selon son Nid
donne envie de refaire un Nid ? Si non, rien d'autre ne compte.

---

## 8. Plus tard

- Formes de reliques et rotation.
- Équilibrage : la Terre un cran au-dessus des autres.
- Une image pour la Serpe de ronces (le Fouet a été remplacé).
- Refaire Feu, Nuit, Terre, Vent au format 15 objets, avec une ou deux familles d'armes chacun.
- Objets neutres qui visent une famille d'armes.
- Glace, les quatre moments du jour, et les hybrides.
- Une arme propre à la Terre et au Vent (ils n'ont que la lance).
- 9 éléments donnent 36 paires d'hybrides : il faudra sûrement n'en garder qu'une partie.
- Stades d'évolution (visuel qui grandit).
- PvP asynchrone : stocker le Nid de chaque joueur par manche (Supabase), tirer un fantôme du même stade.
