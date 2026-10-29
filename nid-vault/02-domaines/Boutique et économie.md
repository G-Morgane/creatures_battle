# Boutique et économie

**Résumé :** Boutique à la TFT, facultative après chaque combat : 9 offres en carré 3 x 3, relance à 1 or, prix selon le type et la rareté, gel, revente et fusion par trois.
**Tags :** #boutique, #economie, #fusion, #rarete
**Mis à jour :** 2026-10-29
**Liens :** [[Run et carte]], [[Sac et formes]], [[Reliques]], [[Équilibrage]], [[Adversaire fantôme et PvP]], [[Cavaliers et armes]]

---

## Règles

- 10 or par combat (feu de camp et rencontre : ni or ni boutique, [[Run et carte]]), l'or non dépensé se garde. Un bonus par victoire existe (`OR_PAR_VICTOIRE`) mais vaut 0.
- 9 offres en carré de 3 x 3 ([[2026-10-28 Refonte de la boutique]]), relance à 1 or. Talent Érudit : première relance de chaque boutique gratuite.
- **Prix** : essence 3, sort 4, catalyseur 4, arme 5, plus la rareté (rare +2, épique +4, légendaire +7).
- On achète **en posant** l'offre dans le Nid. Revente à moitié prix (au moins 1 or), en ramenant la relique à la boutique ou par clic droit.
- **Geler** garde les offres pour le prochain passage ; une relance les dégèle. Les offres gelées portent un flocon.
- Une relique offerte (élite, boss) prend une place vide et survit aux relances.
- Tout le hasard passe par une graine : même graine, mêmes boutiques, mêmes adversaires.

## Rareté

Chances **par offre** à des manches repères, interpolées entre deux (`Partie.chances`). Dernière colonne : boutique de 9 offres contenant au moins un légendaire (mesuré).

| Manche | Commun | Rare | Épique | Légendaire | Boutique avec un légendaire |
|---|---|---|---|---|---|
| 1 | 100 % | | | | 0 % |
| 3 | 80 % | 20 % | | | 0 % |
| 6 | 64,9 % | 28 % | 7 % | 0,1 % | ~1 % |
| 10 (boss 1) | 55,7 % | 30 % | 14 % | 0,3 % | ~3 % |
| 20 (boss 2) | 38 % | 33 % | 25 % | 4 % | ~31 % |
| 30 (boss 3) | 25 % | 33 % | 32 % | 10 % | ~61 % |

**Au plus un légendaire par boutique** : au-delà, le tirage donne un épique (ce plafond ramène le légendaire réel à ~7 % par offre en manche 30). Les reliques offertes (élite, boss, Chaudron) ne comptent pas dans le plafond.

Légendaire vu en boutique avant le boss 1 : **8 % des runs** sans relancer, 19 % avec 2 relances par manche, 35 % avec 5.

**Décision (2026-10-28) :** courbe continue sur les 30 manches, légendaires très rares en acte 1, plafond d'un par boutique.
**Pourquoi :** l'ancienne table à paliers donnait 10 % de légendaire par offre dès la manche 6. Avec 9 offres, cela faisait 61 % de boutiques avec un légendaire à l'étage 6 de l'acte 1. Et elle ne progressait plus après la manche 6, alors qu'une run en compte 30. Le boss 1 offre déjà un légendaire : inutile d'en donner en boutique avant.
**Alternatives écartées :** une pitié (légendaire garanti après N boutiques), redondante avec la légendaire des boss ; une première cible à 1 % en manche 10, qui donnait 52 % de runs avec un légendaire vu en acte 1, relances comprises.

Sur la carte, la manche est le nombre de nœuds franchis. Une tuile non commune porte une bande de couleur : bleu rare, violet épique, or légendaire.

## Fusion

- 3 copies au même niveau donnent 1 relique du niveau suivant (★, puis ★★), à la place de la dernière posée.
- Stats x2,5 au niveau 2, x6 au niveau 3 : un peu moins que trois copies, mais deux cases libérées.
- L'affinité des trois copies est conservée : fusionner ne change pas la forme de la monture.
- Nid plein : on peut poser une offre **sur une copie** si elle complète un trio.
- Tout fusionne, armes et légendaires compris, et les copies sont illimitées tant que le sac a de la place.
- Revente : la moitié de ce qu'elle a coûté (3 copies par niveau).

**Pourquoi la fusion :** le Nid de 16 cases se remplissait vers la manche 6, et l'or ne servait plus à rien ensuite. La répartition des victoires avait deux bosses (beaucoup de 0 à 2, un pic à 7) ; elle est devenue régulière.

Vérifié dans le code : `Nid.peut_fusionner` ne teste que le niveau, les légendaires fusionnent. CONCEPTION.md corrigé le 2026-10-28.
