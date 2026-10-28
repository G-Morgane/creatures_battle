# 2026-10-28 Chances de rareté

**Tags :** #discussion, #rarete, #boutique
**Pages touchées :** [[Boutique et économie]], [[Run et carte]]

## Contexte

Demande : un système de chances d'apparition par rareté, où un légendaire en début de partie est très rare. Le code avait déjà une table à paliers (10 % de légendaire par offre dès la manche 6), qui donnait un légendaire dans 61 % des boutiques à l'étage 6 de l'acte 1 et ne progressait plus après.

## Décisions

- **Courbe continue** sur les 30 manches : repères aux manches 1, 3, 6, 10, 20, 30, interpolation linéaire. Détails et chiffres mesurés dans [[Boutique et économie#Rareté]].
- **Légendaire très rare en acte 1** : 0,1 % puis 0,3 % par offre. Résultat : 8 % des runs voient un légendaire en boutique avant le boss 1 sans relancer, 19 % avec 2 relances par manche. Pourquoi : le boss 1 offre déjà un légendaire.
- **Au plus un légendaire par boutique**, le surplus devient épique. Pourquoi : une relance chanceuse ne doit pas en sortir plusieurs.
- **Pas de pitié** : redondante avec le légendaire offert par les boss.
- Une première version (1 % en manche 10) a été écartée : elle donnait 52 % de runs avec un légendaire vu en acte 1, parce que les relances multiplient les tirages.
- Le code mort du Marché (`marche`, `AVANCE_MARCHE`, son cas dans `conclure`, son test) est retiré.

## Questions ouvertes

- Raisonner en tirages par manche (relances comprises) plutôt que par boutique ? Les joueurs qui relancent beaucoup voient nettement plus de légendaires.
- Joueur aléatoire à 0 % de runs gagnées (3 % noté avant), joueur simple 33 % (31 %). D'autres changements en cours (sac case par case) brouillent la comparaison.

## Suite

- Relancer `tests/simulation.gd --runs=300` une fois le sac par case stabilisé, et mettre à jour [[Équilibrage]].
