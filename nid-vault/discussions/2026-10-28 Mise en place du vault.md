# 2026-10-28 Mise en place du vault

**Tags :** #discussion, #vault
**Pages touchées :** toutes (création)

## Contexte

Mise en place d'un vault Obsidian dans le projet pour garder la mémoire des discussions et avoir un graphe de connaissance. Premier remplissage à partir de CONCEPTION.md, du README et des derniers commits (a4634a5 cavaliers, a56fabc armes de la Nuit).

## Décisions

- Vault `nid-vault/` en français, ignoré par Godot (`.gdignore`), `00-inbox/` et `secrets/` gitignorés.
- Les pages gardent les règles, les décisions et leurs raisons ; les tableaux complets d'objets restent dans CONCEPTION.md.
- Quand CONCEPTION.md et le code divergent, le vault décrit le code et signale l'écart.

## Questions ouvertes

- ~~Réaligner CONCEPTION.md~~ : fait, CONCEPTION.md reste la référence et suit le code ([[Écarts entre CONCEPTION et le code]]).
- ~~Les légendaires fusionnent-ils ?~~ Oui, vérifié dans `nid.gd`.
- Familles d'armes : la Nuit en touche quatre, il ne reste que 2 places pour l'Automne et le Jour ([[Cavaliers et armes#Familles d'armes]]).
- Remesurer l'équilibrage après les retouches non commitées du Cerf, de l'Ours et du Lion ([[Équilibrage]]).

## Suite

En fin de session, consigner ici ce qui a été décidé, et reporter dans les pages de domaines.
