# Commandes et outils

**Résumé :** Lancer le jeu, les tests, l'équilibrage et la découpe d'images.
**Tags :** #outils, #godot, #tests, #images
**Mis à jour :** 2026-10-28
**Liens :** [[Équilibrage]], [[Carte du code]], [[Reliques]]

---

| But | Commande |
|---|---|
| Lancer le prototype | `godot --path .` |
| Ouvrir l'éditeur | `godot -e --path .` |
| Tests de fumée | `godot --headless --path . res://tests/smoke.tscn` |
| Matchups entre builds | `godot --headless --path . -s res://tests/equilibrage.gd` |
| Simulation de runs | `godot --headless --path . -s res://tests/simulation.gd` (`-- --runs=300`) |
| Découper icônes et montures | `godot --headless --path . -s res://outils/decouper_icones.gd` |

- La découpe produit `images/icones/` et `images/montures/`, retire les « poussières » (petits îlots isolés). `images/controle.png` montre toutes les découpes sur fond sombre.
- Polices : Cinzel Decorative (titres), Nunito Sans (texte), licence OFL, dans `polices/`.
- Le vault a un `.gdignore` pour que Godot ne l'importe pas.
