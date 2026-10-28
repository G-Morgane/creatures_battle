# Carte du code

**Résumé :** Quel script fait quoi dans `scripts/`.
**Tags :** #code, #godot, #architecture
**Mis à jour :** 2026-10-28
**Liens :** [[Commandes et outils]], [[Combat]], [[Run et carte]], [[Boutique et économie]], [[Adversaire fantôme et PvP]], [[Dynasties]]

---

| Script | Rôle |
|---|---|
| `data.gd` | Constantes, formes, reliques, cavaliers, élites, gardiens. Source des chiffres du glossaire |
| `descriptions.gd` | Textes des infobulles (à tenir à jour avec CONCEPTION.md) |
| `nid.gd` | Grille, affinités, éclosion de la créature |
| `combat.gd` | Simulation déterministe par pas fixe, règles des élites et gardiens |
| `partie.gd` | Run : PV, nœuds, récompenses, rencontres, bourse, boutique, rareté, fantômes |
| `carte.gd` | Génération de la carte (actes, étages, types de nœuds) |
| `joueur_auto.gd` | Joueur automatique (simulation et fantôme) |
| `exemples.gd` | Nids de démo |
| `palette.gd` | Couleurs |
| `glossaire.gd` | Panneau du glossaire |
| `main.gd` | Point d'entrée |
| `choix_screen.gd` | Choix des dynasties et du cavalier |
| `carte_screen.gd` | Écran de la carte et des rencontres |
| `nid_screen.gd` | Écran du Nid : boutique, glisser-déposer |
| `combat_screen.gd` | Relecture du combat |
| `creature_vue.gd` | Monture et cavalier dessinés |

Tests : `tests/smoke.gd`, `tests/equilibrage.gd`, `tests/simulation.gd`. Outil : `outils/decouper_icones.gd`.
