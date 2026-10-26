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

## Structure

- `scripts/data.gd` : constantes, formes, reliques
- `scripts/nid.gd` : grille, affinités, éclosion de la créature
- `scripts/combat.gd` : simulation déterministe par pas fixe
- `scripts/exemples.gd` : Nids de démo
