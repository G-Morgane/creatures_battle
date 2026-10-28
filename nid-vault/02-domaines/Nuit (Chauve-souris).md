# Nuit (Chauve-souris)

**Résumé :** Dynastie du vol de vie, des malédictions et des coups critiques : elle affaiblit l'adversaire et se soigne en frappant.
**Tags :** #dynastie, #nuit, #vol-de-vie, #maledictions, #crit
**Mis à jour :** 2026-10-28
**Liens :** [[Dynasties]], [[Combat]], [[Cavaliers et armes]], [[Aube (Lion)]], [[Printemps (Cerf)]], [[Hiver (Ours)]], [[Écarts entre CONCEPTION et le code]]

---

Code : `nuit`. Fait. Ce set remplace l'ancienne Nuit (Croc noir, Nuée, Voile, Lune creuse).

## Deux axes

- **Vol de vie** : passif de la Chauve-souris sur les attaques de base, Ruban sanguin, Masque du festin.
- **Malédictions** : des objets **comptent les malédictions différentes** (Masque, Grimoire, Pacte) ; le Chapelet des rancunes permet au contraire d'**empiler la même**. Choix de build : largeur ou profondeur.

## Malédictions (6 s, renouvelées si réappliquées)

| Malédiction | Effet | Avec le Chapelet (3 charges) |
|---|---|---|
| Faiblesse | La cible inflige moins de dégâts (-15 %) | -10 % par charge |
| Langueur | Attaque moins vite (-15 %), pas les sorts | -10 % par charge |
| Flétrissure | Reçoit moins de soins (-30 %) | -25 % par charge |
| **Stigmate** | Reçoit +10 % de dégâts de toutes les sources | |

**Stigmate** a été ajoutée au commit a56fabc. Elle est posée par l'Arc de l'écho et les crits de la Lame de la veuve.

## Passif

**+20 % de dégâts par malédiction différente sur la cible.**
**Pourquoi :** sans lui (et sans attaque sur ses essences), la Chauve-souris ne faisait presque aucun dégât : 0,8 victoire en moyenne.

## Armes du cavalier (état du code)

| Rareté | Arme | Famille | Effet |
|---|---|---|---|
| Commun | Dague de minuit | Lame | Coups rapides, fortes chances de crit (25 %) |
| Commun | Arc de l'écho | Tir | *Écho* : deux flèches qui posent Stigmate |
| Rare | Lame de la veuve | Lame | Chaque crit pose Stigmate |
| Épique | Hache du bourreau | Hache | *Sentence* : plus forte par malédiction, double sous 40 % de vie |
| Légendaire | Faux de la Nuit profonde | Faux | Consume toutes les malédictions pour un coup énorme et un gros drain |

**Décision (a56fabc) :** l'Arc de l'écho et la Hache du bourreau remplacent la Faux lunaire et la Faux du festin ; la Faux ne reste que pour le légendaire. Le Pacte s'active à partir de 3 malédictions différentes.
**Ouvert :** la Nuit touche quatre familles, ce qui pèse sur la répartition par Dynastie ([[Cavaliers et armes#Familles d'armes]]).

## Rapports avec les autres

- Le vol de vie tient face au soin de l'[[Aube (Lion)]] ; la Flétrissure gêne le Lion sans le neutraliser.
- La Flétrissure réduit les soins ; la Belladone du [[Printemps (Cerf)]] les bloque, mais seulement sur une cible empoisonnée.
- La Langueur reste distincte du givre de l'[[Hiver (Ours)]].
- La Coupelle d'étain (bonus de vol de vie) a été retirée au profit du Chapelet.
