# Nid

*(titre de travail)*

Autobattler PvP asynchrone : on remplit un Nid de reliques, il en éclot une créature
(Phénix, Chauve-souris...) qui se bat seule avec les sorts qu'on lui a donnés. Godot 4.

**[CONCEPTION.md](CONCEPTION.md) est le document de référence.**

## Lancer

```bash
godot --path .              # lance le prototype
godot -e --path .           # ouvre l'éditeur
```

## Tester

```bash
godot --headless --path . res://tests/smoke.tscn
```

## Équilibrer

```bash
godot --headless --path . -s res://tests/equilibrage.gd
```

Affiche la durée et le vainqueur de chaque matchup entre builds types. Cible : 15 à 25 s.

```bash
godot --headless --path . -s res://tests/simulation.gd
```

Simule 100 runs entières par joueur automatique (aléatoire, simple) : carte, boutique,
rencontres, combats. Affiche les runs gagnées, l'acte atteint, le taux de victoire par type de
nœud (duel, élite, boss) et les runs gagnées par élément. Pour plus de runs (plus long) :

```bash
godot --headless --path . -s res://tests/simulation.gd -- --runs=300
```

## Images

Les planches d'objets et les montures dessinées sont dans `images/`. Pour regénérer les icônes
détourées (`images/icones/`) et la monture (`images/montures/`) après une modification :

```bash
godot --headless --path . -s res://outils/decouper_icones.gd
```

`images/controle.png` montre toutes les découpes sur fond sombre pour vérifier.

## Structure

- `scripts/data.gd` : constantes, formes, reliques
- `scripts/nid.gd` : grille, affinités, éclosion de la créature
- `scripts/combat.gd` : simulation déterministe par pas fixe
- `scripts/descriptions.gd` : ce que fait chaque relique, pour les infobulles (à tenir à jour avec CONCEPTION.md)
- `polices/` : Cinzel Decorative (titres) et Nunito Sans (texte), Google Fonts, licence OFL
- `images/damier_items.png` : les 16 tuiles du tapis du sac, découpées par l'outil d'images dans `images/tapis/`
- `scripts/carte.gd` : carte d'une run (3 actes, étages, types de nœuds)
- `scripts/carte_screen.gd` : écran de la carte et des rencontres
- `scripts/partie.gd` : run (Ferveur, nœuds, récompenses, rencontres), bourse, boutique, rareté, adversaire fantôme
- `scripts/joueur_auto.gd` : joueur automatique (simulation, adversaire fantôme)
- `scripts/nid_screen.gd` : écran du Nid (boutique, glisser-déposer)
- `scripts/combat_screen.gd` : rejoue le combat simulé (barres de PV, sorts, brûlure)
- `scripts/creature_vue.gd` : monture et cavalier dessinés, en direct
- `scripts/exemples.gd` : Nids de démo
