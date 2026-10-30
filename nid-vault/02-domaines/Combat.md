# Combat

**Résumé :** Le combat est simulé en entier, de façon déterministe par pas de 0,1 s, puis rejoué à l'écran ; aucun élément n'a d'avantage, le contre-jeu passe par les mécaniques.
**Tags :** #combat, #simulation
**Mis à jour :** 2026-10-30
**Liens :** [[Dynasties]], [[Adversaire fantôme et PvP]], [[Équilibrage]], [[Reliques]], [[Carte du code]]

---

## Moteur (`scripts/combat.gd`)

- Pas fixe de 0,1 s : mêmes Nids, même résultat.
  **Pourquoi :** indispensable pour rejouer un duel asynchrone à l'identique.
- Attaques de base selon la vitesse, sorts sur leur recharge.
- Mort subite après 30 s : dégâts croissants des deux côtés, pas de match nul interminable.
- **Affichage = relecture** : `combat_screen.gd` rejoue les événements et les PV. L'animation ne peut donc jamais changer le résultat.
- Vitesse de l'arène : x1 ou x2 (x3 retiré, combats trop vite lus). Durée visée : 15 à 25 s (`tests/equilibrage.gd`, et la durée par type de nœud dans `tests/simulation.gd`).
- **PV** (2026-10-29) : 600 de base (au lieu de 300), +40 par niveau, et les deux combattants ×1,75 en élite, ×2 en boss (`Partie.PV_NOEUD`). **Pourquoi :** combats trop rapides (duel 9 s, boss 6 s) ; mesuré ensuite : duel 15 s, élite 17 s, boss 18 s, taux de victoire inchangé.

## Pas d'avantage élémentaire

**Décision :** aucun élément n'en bat un autre ; pas de triangle, pas de multiplicateur caché. On adapte son Nid à ce qu'on affronte, pas à une couleur.

Les contre-jeux sont lisibles à l'écran :
- le givre de l'[[Hiver (Ours)]] gèle les recharges adverses ;
- les épines du [[Printemps (Cerf)]] punissent les builds à beaucoup de petits coups, la Belladone coupe les soins ;
- le vol de vie de la [[Nuit (Chauve-souris)]] tient face au soin de l'[[Aube (Lion)]] ;
- le [[Crépuscule (Papillon)]] punit les builds qui empilent bonus et malus.

## États récurrents

| État | Source | Particularité |
|---|---|---|
| Poison | Printemps | S'empile, dure tout le combat, traverse le bouclier, 100 doses au plus |
| Brûlure | Été | S'empile, chaque charge s'éteint après 4 s, la combustion la consume |
| Givre et gel | Hiver | Ralentit attaques **et** recharges, gèle à 10 charges |
| Malédictions | Nuit | Faiblesse, Flétrissure, Stigmate ; 6 s |
| Bouclier | Hiver, Crépuscule, élites, gardien | Se vole, se brise |
| Coup critique | Famille Lame | x1,75, aucune chance de base |

## Récap de fin de combat

Chaque source (relique ou mécanique) a sa ligne : dégâts, soins, bouclier, activations. **Décision (2026-10-30) :** un malus montre aussi son effet sur l'adversaire, au compte de celui qui l'a posé : Faiblesse, dégâts évités ; Flétrissure, soins empêchés ; Stigmate, dégâts ajoutés ; givre et gel, secondes de recharge volées. **Pourquoi :** sans chiffre, un objet qui pose un malus semble ne rien faire.
