# Cavaliers et armes

**Résumé :** Un cavalier encapuchonné monte la créature ; on le choisit en début de partie pour son talent, et il tient toutes les armes du sac, chacune lançant son sort.
**Tags :** #cavalier, #armes, #familles, #talents
**Mis à jour :** 2026-10-29
**Liens :** [[Dynasties]], [[Sac et formes]], [[Reliques]], [[Rencontres et objets neutres]], [[Équilibrage]], [[Nuit (Chauve-souris)]], [[Automne et Jour]]

---

## Le cavalier

Petit cavalier encapuchonné, visage sombre, deux yeux lumineux. Sa cape prend la couleur de la Dynastie dominante. À l'écran, il montre deux armes ; chaque arme garde la couleur de son élément.

## Talents des cavaliers (commit a4634a5)

Choisi en début de partie (`images/cavaliers`), peint sur la monture en boutique et en combat. Un talent par domaine : combat offensif, sac, combat défensif, boutique. Les adversaires ont aussi un cavalier.

| Cavalier | Talent | Effet |
|---|---|---|
| L'Ombre | Embuscade | Au début du combat, les armes lancent leur sort tout de suite |
| La Pousse | Croissance | 4 cases de sac offertes, à placer où l'on veut |
| La Coquille | Éclosion | La monture commence chaque combat avec 40 de bouclier |
| Le Capuchon | Érudit | Première relance de chaque boutique gratuite |

Décrit dans CONCEPTION.md, section 4 (ajouté le 2026-10-28).

## Armes

- Relique de type Arme. Chaque arme du sac lance **son propre sort** ; les catalyseurs voisins s'y appliquent.
- **Décision :** aucune limite d'armes. La règle des deux mains a été essayée puis retirée (commit b34ac1d).
- **Conséquence mesurée :** le joueur simple tombe à 27 % de runs gagnées (40 % avec la limite), l'aléatoire à 0 % : les fantômes achètent les armes en premier et en empilent.
  **Ouvert :** baisser le prix ou la force des armes en grand nombre. Voir [[Équilibrage]].
- Arme neutre : **Lance du guet** (Hast, sans élément), estoc rapide qui ignore l'esquive. Elle ne change pas la forme de la monture : choix tactique pur.

## Familles d'armes

Chaque arme appartient à une famille partagée entre Dynasties. Les futurs objets neutres viseront une famille ([[Rencontres et objets neutres]]) : builds croisés, neutres utiles sans être universels.

| Famille | Style | Forme | Dynasties (code actuel) |
|---|---|---|---|
| Tir | Rapide, plusieurs petits coups | 1 x 2 | Printemps, Jour |
| Lame | Rapide, **coups critiques** (x1,75) | 1 x 2 | Automne |
| Hast | Allonge, **perce l'esquive et les Illusions** | 1 x 3 | Aube, neutre |
| Hache | Lent, gros coup | 2 x 2 | Hiver |
| Bâton | Magie, grandit avec l'affinité | 1 x 3 | Été, Crépuscule |
| Faux | Plus forte contre une cible maudite | 1 x 3 | Nuit |

- **Crit** : aucune chance de base ; elles viennent des Lames (10 %, ou ce que l'arme précise) et des objets de l'Automne.

**Décision (2026-10-29) :** **une seule famille par Dynastie**, 3 armes chacune ([[2026-10-29 Archétypes resserrés]]).
**Pourquoi :** une identité nette ; règle la tension d'avant (la Nuit touchait quatre familles, il ne restait pas de place pour l'Automne et le Jour).
Bâton et Tir sont partagés par des Dynasties éloignées, et les six familles restent utilisées.
