# Élites et gardiens

**Résumé :** Les adversaires PvE : trois élites à règle propre et le premier gardien de fin d'acte, le Bastion endormi ; chacun se contre en adaptant son Nid.
**Tags :** #pve, #elites, #boss, #gardiens
**Mis à jour :** 2026-10-28
**Liens :** [[Run et carte]], [[Univers et histoire]], [[Adversaire fantôme et PvP]], [[Combat]], [[Équilibrage]]

---

**Principe :** une créature avec une règle qu'on voit et qu'on peut contrer en adaptant son Nid. Techniquement, c'est le Nid d'un fantôme au même stade, plus sa règle (`Combat._elite`) et son image.

## Élites (faites, `images/ennemis`)

Chiffres +5 % par manche. Le nom s'affiche sur la carte.

| Élite | Dynastie | Règle |
|---|---|---|
| Sanglier des Racines | Printemps | +5 de bouclier par seconde ; toutes les 8 s, une charge qui le dépense (x1,5) |
| Phalène de l'Ouest | Crépuscule | Toutes les 6 s, dissipe ses malus ; toutes les 7 s, un trait de 25 qui traverse le bouclier |
| Vouivre des Cendres | Été | +3 % de dégâts par malus subi (plafond +90 %) ; à mi-vie, brise ses entraves : malus effacés, +40 % de dégâts et d'attaque |

## Le Bastion endormi

Gardien de l'acte I ([[Univers et histoire#Le Rêveur]]). Tortue géante qui dort au fond du lac, un sanctuaire sur le dos, son cavalier en armure. Possession visible : filaments sombres, un œil immense dans la porte du temple (`images/boss_tortue.png`).

**L'entité détourne la protection du gardien pour en faire une arme.**

| Moment | Ce qui se passe |
|---|---|
| Rempart (8 s) | +7 de bouclier par seconde, attaques lentes (x1,8). L'œil rougeoie. |
| Ouverture (3 s) | Immobile. L'œil boit le bouclier restant. |
| Regard | Attaque de 1,5 x le bouclier absorbé, plafonnée à 90 (x la force de la manche) |
| Résistance (3 s) | Le cavalier referme la porte : aucun bouclier, +25 % de dégâts reçus |

Un build offensif entame le bouclier et affaiblit le regard ; un build défensif l'encaisse et profite de la résistance. Victoire : « Purifié ! Le Bastion endormi est libéré ».
Simulation : boss gagnés 41 % (34 % avant), 29 % de runs gagnées.

Actes II et III : encore un boss fantôme (5 manches d'avance) en attendant leurs gardiens.

## Pistes

- **Les Neuf Cavaliers Voilés** : neuf petites montures spectrales, chaque mort renforce les autres.
- **Les Avaleurs de Joie** : aspirent soins et boucliers.
- **Le Seigneur à Collier** : prend le contrôle d'une relique adverse au début du combat.
- **La Reine du Fléau** (boss) : empile des malédictions qu'on ne peut pas soigner.
