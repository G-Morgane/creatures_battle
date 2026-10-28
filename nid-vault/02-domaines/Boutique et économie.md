# Boutique et économie

**Résumé :** Boutique à la TFT, facultative après chaque nœud : 5 offres, relance à 1 or, prix selon le type et la rareté, gel, revente et fusion par trois.
**Tags :** #boutique, #economie, #fusion, #rarete
**Mis à jour :** 2026-10-28
**Liens :** [[Run et carte]], [[Sac et formes]], [[Reliques]], [[Équilibrage]], [[Adversaire fantôme et PvP]], [[Cavaliers et armes]]

---

## Règles

- 10 or par nœud (à régler sur la carte), l'or non dépensé se garde. Un bonus par victoire existe (`OR_PAR_VICTOIRE`) mais vaut 0.
- 5 offres, relance à 1 or. Talent Érudit : première relance de chaque boutique gratuite.
- **Prix** : essence 3, sort 4, catalyseur 4, arme 5, plus la rareté (rare +2, épique +4, légendaire +7).
- On achète **en posant** l'offre dans le Nid. Revente à moitié prix (au moins 1 or), en ramenant la relique à la boutique ou par clic droit.
- **Geler** garde les offres pour le prochain passage ; une relance les dégèle. Les offres gelées portent un flocon.
- Une relique offerte (élite, boss) prend une place vide et survit aux relances.
- Tout le hasard passe par une graine : même graine, mêmes boutiques, mêmes adversaires.

## Rareté

| À partir de la manche | Commun | Rare | Épique | Légendaire |
|---|---|---|---|---|
| 1 | 100 % | | | |
| 2 | 75 % | 25 % | | |
| 4 | 55 % | 30 % | 15 % | |
| 6 | 40 % | 30 % | 20 % | 10 % |

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
