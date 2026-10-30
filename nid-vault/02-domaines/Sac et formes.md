# Sac et formes

**Résumé :** Le Nid est un damier de 8 x 6 qui commence par un carré de 4 x 4 au centre et grandit dans tous les sens ; chaque relique y prend une forme propre à sa dynastie, et sa puissance suit sa taille.
**Tags :** #sac, #inventaire, #ui
**Mis à jour :** 2026-10-30
**Liens :** [[Boutique et économie]], [[Reliques]], [[Cavaliers et armes]], [[Run et carte]]

---

## Tapis

- 8 colonnes sur 6 rangées. Départ : un carré de 4 x 4 au centre (16 cases), qui peut grandir vers le haut et le bas comme sur les côtés, plus 4 cases offertes à placer avec le talent Croissance ([[Cavaliers et armes#Talents des cavaliers]]).
- On agrandit **case par case, au choix**, forcément collée au sac : « Agrandir » en boutique ouvre **2 cases** pour un achat (2 or, puis +1 à chaque achat), la seconde à placer comme une case offerte, ou une case offerte après les boss des actes 1 et 2, et une à chaque niveau gagné ([[Run et carte#Niveau]]). Le sac peut prendre n'importe quelle forme dans le damier. **Pourquoi :** décidé le 2026-10-28 ([[2026-10-28 Refonte de la boutique]]), pour que la forme du sac devienne un choix de construction.
- Rendu : tuiles de `images/tapis`, découpées de `damier_items.png` ; chaque case prend la tuile dont les bords en cuir correspondent à sa place, une case sur deux est assombrie.

## Formes (`Data.empreinte`)

- **Gabarit par dynastie** (`Data.FORMES_DYNASTIE`, dessins `"##/#."`) : Automne petit (1 à 3 cases), Jour en largeur, Crépuscule en S ou en ailes, Été en T ou en croix, Printemps en longues lignes, Aube en colonnes, Hiver en blocs, Nuit en grosses formes (jusqu'à 5). Chaque dynastie garde des objets d'une case parmi ses communs, pour combler les trous.
- **Objets neutres** : règle d'avant (armes selon leur famille, le reste selon la rareté : 1, 2, 3 en L, 2 x 2).
- Exceptions à la main dans `FORMES_OBJETS`.
- **Puissance** (`Data.puissance_forme`) : multipliée par (cases / cases de la règle neutre)^0,5 ; pas pour les catalyseurs, que leur taille fait déjà toucher plus de reliques. Sans encombrement (Nids d'exemple, tests), facteur 1.

**Décision (2026-10-30) :** la forme dépend de la dynastie et entre dans l'équilibrage, au lieu d'être forcée par la rareté.
**Pourquoi :** donner une identité de placement à chaque dynastie (Automne beaucoup de petits objets, Nuit peu de gros) ; le prix ne change pas, donc les petits objets coûtent de l'or, les gros de la place.
**Alternatives écartées :** puissance proportionnelle aux cases (exposant 0,85) : un petit objet perdait près de la moitié de sa force au même prix, l'Automne et la Nuit tombaient à 0 % en simulation. Formes 4 cases en long pour le Jour : injouables en début de partie (retour de jeu), le Jour a maintenant des objets d'une case.

## Manipulation

- Clic droit sur une relique du sac : elle va dans la première place libre de la réserve, qui est une rangée de 8 juste au-dessus du sac.
- Rotation de la relique tenue : R ou molette. Un aperçu vert ou rouge montre où elle tomberait.
- Un catalyseur renforce toutes les reliques qui touchent **n'importe laquelle** de ses cases : une grande relique a plus de voisines.
- Déposer une relique sur une autre les échange si l'autre tient à la place laissée.
- Les Nids d'exemple et les tests de mécanique gardent une case par relique (`encombrement` désactivé) ; la partie l'active.
