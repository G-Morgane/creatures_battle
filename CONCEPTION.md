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

En attendant le PvP, l'adversaire est un **fantôme généré** autour d'un élément :
- **Budget** : tout l'or qu'un joueur aurait reçu jusqu'à cette manche. Un bonus par victoire
  du joueur existe (`OR_PAR_VICTOIRE`) mais est à 0 depuis la fusion.
- **Soin croissant** : en manche 1 il pose au hasard, à partir de la manche 7 il joue
  comme un joueur correct (arme d'abord, 3 copies maximum d'une relique, catalyseurs à côté d'un sort).
- Il fusionne aussi : une fois son Nid plein, son or part dans les trios.

Réglage mesuré sur 300 parties par joueur automatique (`tests/simulation.gd`) :

| Joueur | Victoires moyennes | Parties gagnées |
|---|---|---|
| Aléatoire | 1,8 | 5 % |
| Simple (un élément, catalyseurs bien placés) | 3,1 | 16 % |

Répartition du joueur simple : 0 victoire 17 %, 1 : 15 %, 2 : 17 %, 3 : 9 %, 4 : 10 %,
5 : 10 %, 6 : 6 %, 7 : 16 %.

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

- **Feu** : Braise, Plume de cendre, Souffle ardent, Foyer (fait)
- **Nuit** : Croc noir, Nuée, Voile, Lune creuse (fait)
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

**La rareté reste à concevoir** : chances de tirage en boutique qui évoluent avec les manches,
prix par rareté. Les légendaires ne fusionnent pas (comme les armes).

### Nature (Cerf) : épines et poison

Deux axes avec des ponts entre eux. **Les épines** blessent qui frappe le Cerf (contre les builds
à beaucoup de petits coups : Rafale, Nuée). **Le poison** s'accumule sur la cible.

Règles du poison et des épines :
- **Le poison s'empile** : chaque application ajoute des doses, chaque dose fait des dégâts par
  seconde, et les doses durent longtemps. **Il passe à travers le bouclier** (contre la Tortue).
  À distinguer de la brûlure du Feu : courte, intense, elle se renouvelle au lieu de s'empiler.
- **Plafond de 20 doses** de poison sur une cible.
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
| Légendaire | Graine du Jardin interdit | Une graine fendue, laissant sortir une pousse dorée aux épines violettes | Chaque déclenchement d'épines intensifie le poison ; chaque déclenchement du poison fait pousser les épines. **Plafonds : 20 doses de poison, épines x2 au maximum** |

#### Armes du cavalier (5)

| Rareté | Arme | Sort du cavalier | Rôle |
|---|---|---|---|
| Commun | Sarbacane de roseau | *Fléchette* : petit dard rapide (toutes les 2 s), pose 1 dose de poison | Prépare le poison |
| Commun | Dague d'épine | *Contre* : après 4 coups reçus, le cavalier frappe en retour, plus fort avec des épines | Défense, pont vers les épines |
| Rare | Arc de saule | *Flèche de chasse* (toutes les 5 s) : dégâts augmentés par dose de poison sur la cible | Récolte le poison |
| Épique | Fouet de ronces | *Lacération* : 4 coups rapides qui infligent des dégâts d'épines (profitent des bonus d'épines) | Fait des épines une attaque |
| Légendaire | Arc du Jardin interdit | *Flèche-graine* : se plante dans la cible ; chaque dose de poison qu'elle reçoit ensuite la blesse aussi d'épines | Assorti à la Graine du Jardin interdit |

Les plafonds (x2, 20 doses) sont des valeurs de départ, à régler par simulation.

---

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

- 4 éléments : Feu, Nuit, Terre, Vent, 16 reliques et 3 armes.
- Nid 4 x 4, reliques d'une case. **Les formes de reliques (2 x 1, L...) viendront après.**
- Pas d'hybride, pas de réseau.
- Boutique, manches, combat animé contre un adversaire généré, fin de partie.

**Question à valider avec le prototype** : est-ce que voir sa créature changer selon son Nid
donne envie de refaire un Nid ? Si non, rien d'autre ne compte.

---

## 8. Plus tard

- Formes de reliques et rotation.
- Coder la Nature (set ci-dessus) et la rareté.
- Refaire Feu, Nuit, Terre, Vent au format 15 objets.
- Glace, les quatre moments du jour, et les hybrides.
- Une arme propre à la Terre et au Vent (ils n'ont que la lance).
- 9 éléments donnent 36 paires d'hybrides : il faudra sûrement n'en garder qu'une partie.
- Stades d'évolution (visuel qui grandit).
- PvP asynchrone : stocker le Nid de chaque joueur par manche (Supabase), tirer un fantôme du même stade.
