# Sac et formes

**Résumé :** Le Nid est un tapis de 8 x 4 qui commence à 4 colonnes et grandit case par case ; chaque relique y occupe une forme qui grandit avec sa rareté.
**Tags :** #sac, #inventaire, #ui
**Mis à jour :** 2026-10-28
**Liens :** [[Boutique et économie]], [[Reliques]], [[Cavaliers et armes]], [[Run et carte]]

---

## Tapis

- 8 colonnes sur 4 rangées. Départ : les 4 colonnes du centre (16 cases), plus 4 cases offertes à placer avec le talent Croissance ([[Cavaliers et armes#Talents des cavaliers]]).
- On agrandit d'**une case à la fois, au choix**, forcément collée au sac : « Agrandir » en boutique (2 or, puis +1 à chaque case achetée), ou une case offerte après les boss des actes 1 et 2. Le sac peut prendre n'importe quelle forme dans le damier. **Pourquoi :** décidé le 2026-10-28 ([[2026-10-28 Refonte de la boutique]]), pour que la forme du sac devienne un choix de construction.
- Rendu : tuiles de `images/tapis`, découpées de `damier_items.png` ; chaque case prend la tuile dont les bords en cuir correspondent à sa place, une case sur deux est assombrie.

## Formes (`Data.empreinte`)

- **Armes, selon leur famille** : Hast, Faux et Bâton en 1 x 3 ; Tir et Lame en 1 x 2 ; Hache en 2 x 2.
- **Autres reliques, selon leur rareté** : commun 1 case, rare 2 cases en ligne, épique 3 cases en L, légendaire 2 x 2.
- Exceptions à la main dans `FORMES_OBJETS`, pour coller à une image.

**Décision :** plus une relique est rare, plus elle prend de place.
**Pourquoi :** son pouvoir se paie en cases, ce qui donne son sens à l'agrandissement du sac.

## Manipulation

- Rotation de la relique tenue : R ou molette. Un aperçu vert ou rouge montre où elle tomberait.
- Un catalyseur renforce toutes les reliques qui touchent **n'importe laquelle** de ses cases : une grande relique a plus de voisines.
- Déposer une relique sur une autre les échange si l'autre tient à la place laissée.
- Les Nids d'exemple et les tests de mécanique gardent une case par relique (`encombrement` désactivé) ; la partie l'active.
