# Équilibrage

**Résumé :** Comment on mesure l'équilibre (simulations de runs par joueurs automatiques) et les derniers chiffres connus.
**Tags :** #equilibrage, #simulation, #tests
**Mis à jour :** 2026-10-29
**Liens :** [[Commandes et outils]], [[Adversaire fantôme et PvP]], [[Cavaliers et armes]], [[Élites et gardiens]], [[Combat]], [[Dynasties]]

---

## Outils

- `tests/equilibrage.gd` : durée et vainqueur de chaque matchup entre builds types. Durée visée : 15 à 25 s.
- `tests/simulation.gd` : 100 runs entières par joueur automatique (aléatoire, simple), `--runs=300` pour plus. Runs gagnées, acte atteint, victoires par type de nœud et par élément.
- Joueur **simple** : un élément, catalyseurs bien placés. Joueur **aléatoire** : témoin.
- Pour le joueur simple, la simulation affiche aussi, par élément, les dégâts faits et subis par combat avec les 3 premières sources, et le taux de victoire des combats où chaque relique est dans le sac (8 meilleures, 8 pires, reliques vues moins de 30 fois).

## Rééquilibrage de la Nuit (2026-10-28)

**Constat :** Nuit à 9 % de runs gagnées ; le moins de dégâts par combat (355 contre 393 à 732), 55 % par l'attaque de base ; ses 8 reliques en bas du classement.
**Décision :** passif +20 % de dégâts par malédiction (au lieu de 12), Ruban et Aiguille +4 d'attaque (au lieu de 2), Sceau toutes les 4 s (au lieu de 6), signature Nuit 3 PV (au lieu de 2).
**Résultat :** Nuit 48 %, 444 dégâts par combat. Comme les fantômes jouent aussi la Nuit, les autres baissent : Été 14 %, Hiver 27 %, Crépuscule 29 %, Aube 58 %, Printemps 64 %.
**À suivre :** l'Été devient le plus faible ; la Traînée de cendres et les reliques de l'Été ferment le classement.

## Rééquilibrage de l'Été (2026-10-28)

**Constat (200 runs) :** Été 14 % ; il fait peu de dégâts (368 par combat) mais surtout il en subit le plus (470) : il meurt avant que la brûlure ne travaille.
**Essai écarté seul :** brûlure plus forte (2 dégâts par charge et par seconde au lieu de 1,5, 5 s au lieu de 4) : dégâts 368 → 385 seulement.
**Décision :** renaissance à 50 % des PV (au lieu de 25 %), en plus de la brûlure renforcée et de la Traînée de cendres à +50 % (au lieu de 30).
**Résultat (200 runs) :** Été 25 %, 422 dégâts par combat. Écart entre dynasties ramené à 20–52 % (il était de 14 à 61 %) : Printemps 52 %, Aube 43 %, Nuit 43 %, Été 25 %, Crépuscule 24 %, Hiver 20 %.
**À suivre :** l'Hiver est le plus faible ; Fourrure, Galet, Écorce, Croc du blizzard et Lance du Grand Hiver ferment le classement. Le Reflet d'aile reste presque jamais acheté (13 combats).
**Leçon :** à 100 runs, un élément ne compte que 12 à 23 parties : un écart de 15 points peut être du bruit. Confirmer sur 200 runs (environ 12 minutes).

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

- Prix ou force des armes en grand nombre (le Jour en vit).
- Après la refonte du 2026-10-29 : Printemps trop faible, Aube et Crépuscule trop forts (voir plus bas).

## Rééquilibrage du Crépuscule (2026-10-29)

**Constat (200 runs, avec le niveau passif) :** Crépuscule 14 % ; il subit le plus de dégâts avec l'Été (612 par combat) pour 499 infligés.
**Décision :** projectiles d'arcane x1,5 (`ARCANE_PAR_PUISSANCE`), Brume 12 PV par vol (au lieu de 8), Cocon 30 de bouclier (au lieu de 20), signature 4 (au lieu de 3).
**Résultat (200 runs) :** Crépuscule 33 %, 559 infligés pour 547 subis. Aube 52 %, Printemps 52 %, Nuit 49 %, Hiver 24 %, Été 18 %.
**À suivre :** l'Été est retombé à 18 % depuis le niveau passif (il subit 634 par combat) ; l'Hiver reste bas (24 %), ses communs Flocon, Galet et Fourrure ferment le classement.

## Feu de camp et rencontre sans or (2026-10-29)

**Changement :** ni or ni boutique après un feu de camp ou une rencontre ; les fantômes perdent l'or d'une manche sur trois ([[Run et carte]]).
**Résultat (200 runs) :** simple 37 % de runs gagnées (36 % avant), aléatoire 6 %. Duels 60 %, élites 42 %, boss 46 % ; durées 17 / 20 / 20 s. Par élément : Crépuscule 52 %, Nuit 49 %, Aube 48 %, Printemps 39 %, Été 25 %, Hiver 8 % (25 runs seulement).
**Lecture :** comme les fantômes perdent autant d'or, l'équilibre ne bouge pas. L'Hiver reste le plus faible (Fourrure, Galet, Écorce, Stalagmite, Cristal, Croc du blizzard, Lance du Grand Hiver en bas du classement).

## Refonte des archétypes (2026-10-29)

Après le passage à 10 objets et un principe par Dynastie ([[2026-10-29 Archétypes resserrés]]). Le joueur automatique choisit désormais parmi les dynasties de la partie (il ignorait l'Automne et le Jour).

**Première mesure (200 runs) :** simple 48 %, aléatoire 19 %. Écart énorme : Crépuscule 89 %, Aube 85 %, Nuit 0 %, Jour 24 %, Printemps 25 %.
**Réglages :**
- Crépuscule : Illusions 2 au plus (3 avec la Mue), arcane d'Illusion 5 (au lieu de 8), Battement toutes les 5 s, Trait d'arcane 8, et **les armes ne créent plus d'Illusion** avec le passif.
- Aube : Éclat 45 (au lieu de 60).
- Nuit : passif +30 % par malédiction (au lieu de 20), Stigmate +15 %, Aiguille +5 d'attaque, Sceau toutes les 4 s, Grimoire 20, Faux lunaire 10, Faux du festin 12 et +35 %, signature 5.
- Jour : Éventail +8 % par charge (au lieu de 5), Écu doré 6.
- Printemps : épines du Cerf 4, poison 0,6 par dose. Automne : esquive du Renard 15 %.
**Résultat (200 runs, fusion 3 puis 2) :** simple 54 %, aléatoire 18 %. Aube 77 %, Hiver 70 %, Été 72 %, Crépuscule 68 %, Jour 67 %, Nuit 45 %, Automne 42 %, Printemps 18 %.
**À suivre :** le Printemps (44 runs, le chiffre le plus sûr) est nettement le plus faible ; Liane, Ortie et Arc de saule ferment le classement. Aube, Nuit et Crépuscule ont 11 à 19 runs chacun : bruit possible. Le taux du joueur simple (54 %) n'est pas comparable aux 37 % d'avant : les fantômes jouent maintenant les huit dynasties.
