# Run et carte

**Résumé :** Une run, c'est 3 actes de 10 étages sur une carte à embranchements, avec une jauge de Ferveur et une boutique facultative entre chaque nœud.
**Tags :** #run, #carte, #roguelike
**Mis à jour :** 2026-10-28
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
**Pourquoi :** la boutique est déjà ouverte entre chaque nœud.
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
