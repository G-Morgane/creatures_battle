# Adversaire fantôme et PvP

**Résumé :** Les Duels seront du PvP asynchrone contre des Nids enregistrés au même stade ; en attendant, l'adversaire est un fantôme, joueur automatique soumis aux mêmes règles.
**Tags :** #pvp, #fantome, #ia, #reseau
**Mis à jour :** 2026-10-28
**Liens :** [[Run et carte]], [[Combat]], [[Boutique et économie]], [[Équilibrage]], [[Élites et gardiens]]

---

## PvP asynchrone (à faire)

- À chaque Duel, on enregistre son Nid (reliques, niveaux, armes) avec l'acte, le nœud et sa Ferveur.
- L'adversaire est tiré parmi les Nids enregistrés **au même stade**, de préférence à PV proches.
- Le combat est [[Combat|déterministe]] : le Nid enregistré rejoue exactement. Seul le joueur actif gagne ou perd quelque chose.
- Serveur : une table de Nids, Supabase suffit.

## Fantôme (fait, `scripts/joueur_auto.gd`)

- Joueur automatique qui a joué toutes les manches jusqu'ici, avec ses propres boutiques (une graine par manche) : il ne choisit que parmi ses offres, relance, fusionne.
- **Pourquoi :** le premier générateur piochait directement dans tous les objets de son élément ; avec cinq éléments, c'était un avantage énorme sur le joueur, limité à ses 5 offres.
- Performance : quatre fantômes avancent d'une manche à la fois, au lieu de rejouer toute leur partie à chaque combat (une run coûtait des secondes).
- Les fantômes ne tirent que dans les Dynasties de la partie, et ont un cavalier et son talent.
- Faiblesse connue : le fantôme n'est jamais meilleur que le joueur automatique simple, d'où un joueur aléatoire trop à l'aise. Il achète les armes en premier et en empile ([[Cavaliers et armes#Armes]]).
- **Avance (2026-10-29)** : le fantôme a joué 1 manche de plus en duel, 3 en élite, 5 au boss (`Partie.AVANCE`, avant 0, 0, 4).
  **Pourquoi :** viser 40 % de runs gagnées par le joueur simple ; il faut optimiser pour gagner. La pénurie de boutique ne change rien, le fantôme la subit aussi ([[Difficulté et leçons de Backpack Battles et Oaken Tower]]).
- Le fantôme passe par `Partie.nouvelle_boutique()` comme le joueur : sans elle, sa relance qui s'enchérit ne revenait jamais à 1 et il cessait de relancer (joueur simple mesuré à 66 % à cause de ce défaut).
