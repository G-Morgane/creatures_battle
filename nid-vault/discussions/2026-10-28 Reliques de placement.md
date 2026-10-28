# 2026-10-28 Reliques de placement

**Tags :** #discussion, #reliques, #placement, #combat
**Pages touchées :** [[Reliques]], [[Rencontres et objets neutres]], [[Combat]]

## Contexte

Retour de l'utilisatrice : trop peu d'objets agissent sur ceux qui les entourent. Seuls 8 catalyseurs sur 94 reliques le faisaient, tous sur le même modèle (+50 % sur un effet), aucun dans la Nuit ; les effets de catalyseur « vol de vie » et « recharge » existaient dans le code sans objet.

## Décisions

- **Six mécaniques de placement, un objet chacune** (une relique par dynastie, deux pour le Printemps) :
  - Calice de sang (Nuit, catalyseur vol de vie) et Cadran solaire (Aube, catalyseur recharge) : utilisent les effets orphelins.
  - Mousse des sous-bois (Printemps) : **grappe**, +15 PV par voisine de sa dynastie. Pourquoi : récompenser le regroupement.
  - Stalagmite solitaire (Hiver) : **solitaire**, bonus seulement si rien ne la touche. Pourquoi : contrepoids à la grappe, une raison de laisser des trous.
  - Traînée de cendres (Été) : catalyseur de **rangée**. Pourquoi : un placement à longue portée.
  - Reflet d'aile (Crépuscule) : **copie** 75 % de l'essence voisine la plus forte. Pourquoi : colle au Transfert.
  - Terreau fertile (Printemps) : **croissance**, +4 % aux voisines par victoire avec lui dans le sac (10 au plus). Compteur `saisons` sur le Nid, pas sur la relique : plus simple que de suivre une charge à travers déplacements et réserve. Les fantômes comptent chaque manche comme une victoire.
- **Signature de dynastie** (demande suivante) : chaque sort et arme ajoute un petit effet de son élément à chaque activation ([[Reliques#Signature de dynastie]]). Les tests à dégâts exacts en tiennent compte.
- **Pas de Dévoreur** (relique qui absorbe une voisine) : écarté par l'utilisatrice.
- **Plus d'objets neutres en jeu** : la Lance du guet (seul neutre) n'est plus tirée ; elle reste dans `data.gd` pour les tests.
- **Arène** : montures +50 % (zoom 1.725), cavalier à pied devant sa monture, à 85 %, les deux cavaliers face à face ; Phénix et Papillon volent au-dessus de leur ombre, Phénix élargi (320 au lieu de 260).

## Questions ouvertes

- Icônes à dessiner pour les sept nouvelles reliques (le jeu affiche leur nom à défaut).
- Équilibrage des nouvelles valeurs non mesuré.
- La Chauve-souris doit-elle voler aussi en arène ?
