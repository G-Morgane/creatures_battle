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
- **Budget** : tout l'or qu'un joueur aurait reçu jusqu'à cette manche, **+ 3 or par victoire
  du joueur** (comme en PvP, on affronte des joueurs au même palmarès).
- **Soin croissant** : en manche 1 il pose au hasard, à partir de la manche 7 il joue
  comme un joueur correct (arme d'abord, 3 copies maximum d'une relique, catalyseurs à côté d'un sort).

Réglage mesuré sur 300 parties par joueur automatique (`tests/simulation.gd`) :

| Joueur | Victoires moyennes | Parties gagnées |
|---|---|---|
| Aléatoire | 1,2 | 2 % |
| Simple (un élément, catalyseurs bien placés) | 2,3 | 15 % |

### Problème connu : le plafond du Nid

Le Nid fait 16 cases et se remplit vers la manche 6. Après, l'or ne sert plus à rien et seule
la composition compte : un bon Nid gagne en boucle, un mauvais ne peut plus se rattraper.
D'où une répartition en deux bosses (beaucoup de 0 à 2 victoires, un pic à 7, presque rien
entre 4 et 6). **Aucun réglage de chiffres ne corrige ça.** Il faut une progression de fin
de partie qui consomme de l'or : fusion (3 copies d'une relique donnent une relique
de niveau 2), stades d'évolution, ou cases du Nid à débloquer.

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
- **Glace** : Éclat, Carapace gelée, Prison de glace, Cœur d'hiver
- **Nature** : Racine, Ronces, Sève, Graine mère
- **Vent, Terre, Aube, Lumière, Crépuscule** : à concevoir

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

- 2 éléments : Feu et Nuit, 8 reliques et 3 armes.
- Nid 4 x 4, reliques d'une case. **Les formes de reliques (2 x 1, L...) viendront après.**
- Pas d'hybride, pas de réseau.
- Boutique, manches, combat animé contre un adversaire généré, fin de partie.

**Question à valider avec le prototype** : est-ce que voir sa créature changer selon son Nid
donne envie de refaire un Nid ? Si non, rien d'autre ne compte.

---

## 8. Plus tard

- Formes de reliques et rotation.
- **Prochains éléments : Terre et Vent**, deux opposés (combat long contre combat rapide),
  pour vérifier que ça reste lisible avant d'aller jusqu'à neuf.
- Puis Glace, Nature, les quatre moments du jour, et les hybrides.
- 9 éléments donnent 36 paires d'hybrides : il faudra sûrement n'en garder qu'une partie.
- Stades d'évolution (visuel qui grandit).
- PvP asynchrone : stocker le Nid de chaque joueur par manche (Supabase), tirer un fantôme du même stade.
