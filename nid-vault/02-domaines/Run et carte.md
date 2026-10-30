# Run et carte

**Résumé :** Une run, c'est 3 actes de 10 étages sur une carte à embranchements, avec une jauge de Ferveur et une boutique facultative entre chaque nœud.
**Tags :** #run, #carte, #roguelike
**Mis à jour :** 2026-10-30
**Liens :** [[Boutique et économie]], [[Élites et gardiens]], [[Rencontres et objets neutres]], [[Adversaire fantôme et PvP]], [[Sac et formes]], [[Équilibrage]], [[Cavaliers et armes]]

---

## Carte (`scripts/carte.gd`)

- 3 actes de 10 étages, 4 colonnes, 4 chemins tirés au hasard qui ne se croisent pas. On voit le type des nœuds à venir.
- Étage 1 : des Duels. Étage avant le boss : des Feux de camp. Ailleurs, tirage pondéré (`POIDS` du code) : Duel 55, Rencontre 25, Élite 12, Feu 8.
- Pas d'Élite avant le 5e étage de l'acte 1, pas de Feu avant le 5e étage.
- Gagner le boss de l'acte 3 gagne la run.

| Nœud | Contenu | Récompense |
|---|---|---|
| Duel | [[Adversaire fantôme et PvP]] | Or |
| Élite | PvE avec une règle lisible ([[Élites et gardiens]]) | Or et une relique épique offerte |
| Rencontre | Événement à choix ([[Rencontres et objets neutres]]) | Variable, parfois un prix à payer |
| Feu de camp | +20 de Ferveur, ou une fusion gratuite | |
| Boss | Gardien de fin d'acte | Légendaire offerte ; +1 colonne de sac après les actes 1 et 2 |

**Décision :** le Marché est retiré de la carte.
**Pourquoi :** la boutique est déjà ouverte après chaque combat.
Retiré du code et de CONCEPTION.md.

## Ferveur

**Décision :** la Ferveur remplace « 7 victoires ou 3 défaites ». À 0, la run est perdue.

- Prototype : 60 PV. Défaite : Duel 3, Élite 6, Boss 10, plus jusqu'à 8 selon les PV qui restaient à l'adversaire (comme TFT). Égalité : rien.
- Perdre un boss coûte des PV mais on passe à l'acte suivant ; seul le boss de l'acte 3 termine la run.

## Début de partie

1. Choix de 3 à 8 [[Dynasties]] (ou « Aléatoire » : 4). Boutique, reliques offertes, Heaume et fantômes ne tirent que dans celles-ci, plus les objets neutres.
2. Choix du cavalier et de son talent ([[Cavaliers et armes#Talents des cavaliers]]).

## Glossaire

Bouton Glossaire (ou F1) en haut à droite de tous les écrans. Ses chiffres viennent de `Data`.

## Niveau

**Décision :** un niveau qui monte seul, d'un point d'expérience par nœud franchi (`Partie.XP_NIVEAUX` : niveaux 2 à 8 à 2, 5, 8, 12, 16, 21 et 26 XP). Chaque niveau gagné donne **+40 PV à la monture** (20 au départ, doublé avec les PV de base le 2026-10-29) et **une case de sac offerte**. Les fantômes ont le niveau de leurs manches jouées (boss : 4 manches d'avance). Affiché dans le bandeau du Nid.
**Pourquoi :** demandé le 2026-10-29 ([[2026-10-29 Niveau]]) : la monture doit se renforcer et le sac grandir sans que tout passe par l'or.
**Alternatives écartées :** acheter de l'expérience avec de l'or comme TFT (l'agrandissement payant fait déjà ce rôle) ; expérience par victoire seulement (punirait deux fois une défaite).

## Feu de camp et rencontre sans boutique (2026-10-29)

**Décision :** après un feu de camp ou une rencontre, ni or ni nouvelle boutique : on reste sur la carte et le résultat s'affiche sous le bandeau. Une relique gagnée (Heaume, Chaudron) attend, offerte, dans la boutique en cours ; « Retour au Nid » reste possible.
**Pourquoi :** demandé par l'utilisatrice ; l'or et la boutique récompensent les combats.
**Fantômes :** une manche sur trois sans or ni relance (environ un tiers des nœuds sont des feux ou des rencontres), pour garder la même économie que le joueur.
**À surveiller :** deux reliques offertes d'affilée sans passer par une boutique : la seconde prend la place de la première si la boutique est pleine.

## Progression entre les runs : le Rêveur (2026-10-30)

**Décision :** une sauvegarde `user://progression.json` ne garde que le nombre de runs gagnées ; les étapes s'en déduisent (`scripts/progression.gd`, constantes `INCARNATION`, `ANCRAGES`, `REVE`).

| Runs gagnées | Étape franchie | État affiché |
|---|---|---|
| 0 | | Incarnation intacte |
| 1 | l'incarnation est détruite | Incarnation détruite, ancrages 0/2 |
| 2, 3 | un ancrage par victoire | ancrages 1/2, puis « Ancrages détruits, le rêve est ouvert » |
| 4 | vaincu dans son rêve | Le Rêveur est vaincu |

- Seule une run gagnée compte (dernier boss battu), une seule fois : `Progression.compter_run` dans `main.gd` après `conclure_combat`, gardé par `Partie.victoire_comptee`. Une défaite ne fait jamais reculer : un ancrage détruit reste perdu pour lui.
- Visible : bandeau « Le Rêveur » sur l'écran de départ (survol : ce qu'il reste à abattre), et la fin d'une run gagnée dit ce qui vient de tomber. Chapitre « Le Rêveur » dans le glossaire.
- Fichier absent ou illisible : on repart de 0.
**Pourquoi :** trame de [[Univers et histoire#Le Rêveur]] ; le compte de victoires seul suffit et laisse régler les seuils sans migrer la sauvegarde.
**Ouvert :** ce que change chaque étape dans le jeu lui-même (carte, gardiens, fond) au-delà du texte ; que faire après la victoire finale.
