# Nid

*(titre de travail)*

**Autobattler PvP asynchrone. On remplit un Nid de reliques, il en éclot une créature qui se bat seule. Godot 4, 2D.**

> Ce que tu mets dans le Nid décide de ce qui en sort.
> Un Nid de braises donne un phénix, un Nid d'ombre une chauve-souris,
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

Fin de partie : X victoires ou Y défaites (valeurs à régler).

---

## 3. Forme de la créature

Chaque relique donne des points d'**affinité** dans un élément.

- **Élément dominant** : fixe la forme de base et un passif.

| Élément | Forme | Passif |
|---|---|---|
| Feu | Phénix | Renaît une fois à 30 % de PV |
| Ombre | Chauve-souris | Vol de vie sur les attaques de base |
| Givre | Loup | Les attaques ralentissent |
| Nature | Cerf ancien | Régénère, gagne de l'épine |

- **Hybride** (plus tard) : deux éléments au-dessus d'un seuil donnent une forme mixte
  (Feu + Ombre : Wyverne cendrée, Givre + Nature : Ours de toundra...).
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
| Faux lunaire | Ombre | Moisson, lente, **double sous 40 % de PV** |

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

### Lot complet visé (16)

- **Feu** : Braise, Plume de cendre, Souffle ardent, Foyer
- **Ombre** : Croc noir, Nuée, Voile, Lune creuse
- **Givre** : Éclat, Carapace gelée, Prison de glace, Cœur d'hiver
- **Nature** : Racine, Ronces, Sève, Graine mère

---

## 5. Pas d'avantage élémentaire

**Aucun élément ne bat un autre.** Pas de triangle, pas de multiplicateur caché.

Le contre-jeu passe par les mécaniques des sorts, lisibles à l'écran :
- Prison de glace (étourdit) coupe une Nuée en pleine série.
- Ronces (renvoie les dégâts) punit les builds à beaucoup de petits coups.
- Le vol de vie de l'Ombre tient face au soin Nature.

On adapte son Nid à ce qu'on affronte, pas à une couleur.

---

## 6. Combat

- Simulation déterministe par pas de 0,1 s : même Nids, même résultat.
  Indispensable pour rejouer un combat asynchrone à l'identique.
- Attaques de base selon la vitesse, sorts sur leur recharge.
- Mort subite après 30 s : dégâts croissants des deux côtés, pas de match nul interminable.

---

## 7. Prototype (périmètre actuel)

- 2 éléments : Feu et Ombre, 8 reliques et 3 armes.
- Nid 4 x 4, reliques d'une case. **Les formes de reliques (2 x 1, L...) viendront après.**
- Pas d'hybride, pas de boutique, pas de réseau.
- Deux Nids d'exemple qui se battent, journal du combat à l'écran.

**Question à valider avec le prototype** : est-ce que voir sa créature changer selon son Nid
donne envie de refaire un Nid ? Si non, rien d'autre ne compte.

---

## 8. Plus tard

- Boutique et économie d'or.
- Formes de reliques et rotation.
- Givre, Nature, hybrides.
- Stades d'évolution (visuel qui grandit).
- PvP asynchrone : stocker le Nid de chaque joueur par manche (Supabase), tirer un fantôme du même stade.
