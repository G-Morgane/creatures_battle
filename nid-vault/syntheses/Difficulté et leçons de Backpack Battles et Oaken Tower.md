# Difficulté et leçons de Backpack Battles et Oaken Tower

**Résumé :** Pour viser 40 % de runs gagnées par le joueur simple, l'économie ne suffit pas (les fantômes la subissent aussi) ; il faut des adversaires en avance. Pour récompenser l'optimisation, les deux jeux misent sur des arbitrages d'économie et des synergies de placement.
**Tags :** #synthese, #equilibrage, #boutique, #references
**Mis à jour :** 2026-10-29
**Liens :** [[Équilibrage]], [[Boutique et économie]], [[Adversaire fantôme et PvP]], [[Thèse du jeu]], [[Reliques]], [[Run et carte]]

---

Question de l'utilisatrice (2026-10-29) : le jeu est trop facile (joueur simple 54 %), viser **40 %**. Il faut devoir chercher et optimiser, pas aller tout droit.
Sources : wiki Oaken Tower, page Shop ; wiki Backpack Battles, page Game Mechanics (consultés le 2026-10-29).

## Ce qu'ils font

| | Nid | Backpack Battles | Oaken Tower |
|---|---|---|---|
| Offres par boutique | 9 | 5 | 7 |
| Relance | 1 or, fixe | 1 or les 4 premières, puis 2 | 3 or, +2 par relance après 15 |
| Garder des offres | Gel de toute la boutique | Verrou **par objet** | Gel de toute la boutique |
| Or | 10 par combat | 10 à 22 par manche, irrégulier | Revenu qui monte avec le niveau de boutique |
| Rareté | Courbe fixe selon la manche | Courbe fixe selon la manche, jusqu'à 20 % de divin | **Selon le niveau de boutique, qu'on achète** (52 or, +4 par niveau) |
| Surprises | Aucune | 10 % des offres en solde à -50 % | Lucky Shops (offres spéciales) |
| Synergies | Catalyseurs voisins | Étoiles et losanges : un objet demande des voisins précis | — |
| Rangement | Réserve sans effet | Stockage sans effet | — |

## Leçons

1. **La rareté des ressources ne rend pas le jeu plus dur contre des fantômes.** Mesuré : 6 offres et relance à 2 or → joueur simple 56 % (54 % avant). Les fantômes jouent avec les mêmes boutiques. La difficulté de Backpack Battles vient d'adversaires humains qui optimisent.
2. **Ce qui fait chercher, ce sont les arbitrages**, pas la pénurie :
   - investir ou dépenser (le niveau de boutique d'Oaken Tower : de l'or maintenant contre de meilleures raretés et plus de revenu ensuite) ;
   - relancer de plus en plus cher (les deux jeux) ;
   - garder un objet précis (verrou par objet de Backpack Battles) ;
   - saisir une occasion (soldes, Lucky Shops).
3. **Les synergies de placement exigeantes** (étoiles et losanges) récompensent celui qui cherche la bonne disposition. Nid vient de retirer ses mots-clés de placement pour simplifier ([[2026-10-29 Archétypes resserrés]]) : tension à arbitrer.

## Mesures sur la difficulté (200 runs, joueur simple)

Levier : `Partie.AVANCE`, les manches d'avance du fantôme selon le nœud (aujourd'hui duel 0, élite 0, boss 4).

| Avance (duel, élite, boss) | Simple | Aléatoire |
|---|---|---|
| 0, 0, 4 (avant) | 54 % | 18 % |
| 1, 2, 4 | 49 % | 14 % |
| 1, 3, 6 | 35 % | 6 % |
| 2, 3, 5 | 34 % | 10 % |

Appliqué : (1, 3, 5), avec la nouvelle boutique : simple 41 %, aléatoire 17 % ([[Équilibrage]]).

## Pistes

- **Chiffre** : fait, `AVANCE` (1, 3, 5).
- **Arbitrages** : faits (relance qui s'enchérit, verrou par offre, soldes). Reste : un niveau de boutique achetable.
- **Mesurer l'optimisation** : un joueur automatique « expert » qui relance, garde et place mieux. Il doit gagner nettement plus que le simple, sinon optimiser ne paie pas.
