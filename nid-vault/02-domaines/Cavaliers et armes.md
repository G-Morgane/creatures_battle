# Cavaliers et armes

**Résumé :** Un cavalier encapuchonné monte la créature ; on le choisit en début de partie pour son talent, et il tient toutes les armes du sac, chacune lançant son sort.
**Tags :** #cavalier, #armes, #familles, #talents
**Mis à jour :** 2026-10-28
**Liens :** [[Dynasties]], [[Sac et formes]], [[Reliques]], [[Rencontres et objets neutres]], [[Équilibrage]], [[Nuit (Chauve-souris)]], [[Automne et Jour]]

---

## Le cavalier

Petit cavalier encapuchonné, visage sombre, deux yeux lumineux. Sa cape prend la couleur de la Dynastie dominante. À l'écran, il montre deux armes ; chaque arme garde la couleur de son élément.

## Talents des cavaliers (commit a4634a5)

Choisi en début de partie (`images/cavaliers`), peint sur la monture en boutique et en combat. Un talent par domaine : combat offensif, sac, combat défensif, boutique. Les adversaires ont aussi un cavalier.

| Cavalier | Talent | Effet |
|---|---|---|
| L'Ombre | Embuscade | Au début du combat, les armes lancent leur sort tout de suite |
| La Pousse | Croissance | Le sac commence à 5 colonnes au lieu de 4 |
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
| Tir | Rapide, plusieurs petits coups | 1 x 2 | Printemps, Crépuscule, Nuit |
| Lame | Rapide, riposte, **coups critiques** (x1,75) | 1 x 2 | Printemps, Nuit |
| Hast | Allonge, perce l'esquive | 1 x 3 | Hiver, Crépuscule, neutre |
| Hache | Lent, gros coup | 2 x 2 | Hiver, Aube, Nuit |
| Bâton | Magie, grandit avec l'affinité | 1 x 3 | Été, Aube |
| Faux | Achève les cibles affaiblies | 1 x 3 | Été, Nuit |

- **Crit** : aucune chance de base, elles viennent des Lames et de certains objets (10 % par Lame, 25 % Dague de minuit, 15 % Lame de la veuve, 8 % Peigne).
- **Faux** : trait commun « achever » (plus forte contre une cible affaiblie), sur lequel jouera un futur neutre. Chaque Dynastie y ajoute sa saveur.

**Règle d'origine :** chaque Dynastie utilise une ou deux familles ; 8 x 2 = 16 places pour 6 familles.
**Tension :** depuis a56fabc, la Nuit touche quatre familles (Lame, Tir, Hache, Faux), et les six Dynasties faites occupent déjà 14 places. Il en reste 2 pour l'[[Automne et Jour|Automne et le Jour]], qui en voudraient 4. À trancher : assouplir la règle, ou recentrer la Nuit.
