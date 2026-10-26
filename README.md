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

## Structure

- `scripts/data.gd` : constantes, formes, reliques
- `scripts/nid.gd` : grille, affinités, éclosion de la créature
- `scripts/combat.gd` : simulation déterministe par pas fixe
- `scripts/nid_screen.gd` : écran du Nid (glisser-déposer)
- `scripts/combat_screen.gd` : rejoue le combat simulé (barres de PV, sorts, brûlure)
- `scripts/creature_vue.gd` : monture et cavalier dessinés, en direct
- `scripts/exemples.gd` : Nids de démo
