# Équilibrage

**Résumé :** Comment on mesure l'équilibre (simulations de runs par joueurs automatiques) et les derniers chiffres connus.
**Tags :** #equilibrage, #simulation, #tests
**Mis à jour :** 2026-10-28
**Liens :** [[Commandes et outils]], [[Adversaire fantôme et PvP]], [[Cavaliers et armes]], [[Élites et gardiens]], [[Combat]], [[Dynasties]]

---

## Outils

- `tests/equilibrage.gd` : durée et vainqueur de chaque matchup entre builds types. Durée visée : 15 à 25 s.
- `tests/simulation.gd` : 100 runs entières par joueur automatique (aléatoire, simple), `--runs=300` pour plus. Runs gagnées, acte atteint, victoires par type de nœud et par élément.
- Joueur **simple** : un élément, catalyseurs bien placés. Joueur **aléatoire** : témoin.

## Derniers chiffres (100 runs, ~26 nœuds par run)

| Joueur | Runs gagnées | Acte 3 atteint | Duels | Élites | Boss |
|---|---|---|---|---|---|
| Aléatoire | 3 % | 48 % | 35 % | 21 % | 15 % |
| Simple | 31 % | 80 % | 59 % | 48 % | 44 % |

Mesures plus récentes, d'autres sections :
- Sans limite d'armes : simple 27 % (40 % avec la limite), aléatoire 0 %.
- Avec le Bastion endormi : boss gagnés 41 % (34 % avant), 29 % de runs gagnées.
- Formes des reliques : simple 30 %, inchangé.

Les chiffres de Cerf, Ours et Lion viennent d'être modifiés (pas encore commités) : à remesurer.

## Leçons

- **Par élément, il faut beaucoup de runs** : sur 300 parties, chaque élément n'en a qu'une trentaine et les moyennes bougent de ±0,5. Les anciens classements (Terre, Vent devant, Nuit derrière) datent d'avant le retrait du Vent et de la Terre ([[Éléments abandonnés]]).
- L'écart entre joueur simple et aléatoire doit rester net : il prouve que les choix comptent.
- Ancien mode à manches : la difficulté était plate (le simple gagnait 49 à 54 % à chaque manche).

## Ouvert

- Prix ou force des armes en grand nombre.
- Plafonds du Printemps (x2 épines, 100 doses de poison).
- Inversion du Crépuscule.
