# Reliques

**Résumé :** Les quatre types de reliques (essence, sort, catalyseur, arme), leur rôle, et leur format par Dynastie (7 de monture, 3 armes).
**Tags :** #reliques, #objets
**Mis à jour :** 2026-10-29
**Liens :** [[Dynasties]], [[Sac et formes]], [[Boutique et économie]], [[Cavaliers et armes]], [[Thèse du jeu]], [[Rencontres et objets neutres]], [[2026-10-29 Archétypes resserrés]]

---

| Type | Rôle | Prix de base |
|---|---|---|
| Essence | Affinité et stats brutes (PV, attaque) et un effet permanent | 3 |
| Sort | Capacité active avec recharge, plus forte si l'affinité de son élément est haute | 4 |
| Catalyseur | Renforce ses voisins (toute relique qui touche une de ses cases) | 4 |
| Arme | Tenue par le cavalier, lance son propre sort | 5 |

- Chaque relique donne de l'affinité à sa Dynastie : c'est ce qui fait éclore la monture ([[Dynasties#Forme de la créature]]).
- Règle de la [[Thèse du jeu]] : chaque relique change quelque chose de visible.
- Format par Dynastie : 7 objets de monture + 3 armes ([[Dynasties#Format : 10 objets, un principe]]). 80 reliques en tout, plus la Lance du guet (neutre).
- Descriptions des infobulles : `scripts/descriptions.gd`, à tenir à jour avec CONCEPTION.md.

## Catalyseurs

Un par Dynastie, au rang rare. Deux sortes :
- **Multiplicateurs** : Tison (brûlure +50 %), Croc du blizzard (givre +50 %), Broche de soleil (dégâts +25 %), Pollen doré (recharge +15 %).
- **Ajouts à chaque activation** des sorts et armes voisins : Feuille d'ortie (+1 dose de poison), Huile (+3 de soin), Poupée cousue (une malédiction manquante).
- **Pelage roux** : +8 % de crit par objet qui le touche.

## Signature de dynastie

**Décision :** chaque sort et chaque arme ajoute, à chaque activation, un petit effet de **son** élément (× niveau) : Été 1 brûlure, Printemps 1 dose de poison, Hiver 1 givre, Nuit draine 5 PV, Aube soigne 3 PV, Crépuscule un projectile d'arcane de 4, Automne une griffe de 3, Jour 3 de bouclier (`Data.SIGNATURES`).
**Pourquoi :** que chaque objet nourrisse la mécanique de sa dynastie, même ceux qui font autre chose.
**Essences :** sans activation, chacune donne un cinquième de sa signature à chaque attaque de la monture (`Data.SIGNATURE_ESSENCE`), demandé par l'utilisatrice.
**Alternatives écartées :** dépendre de la monture dominante (moins lisible, punit les hybrides).

## Placement

Les mots-clés de placement du 2026-10-28 (grappe, solitaire, rangée, copie, terreau) sont **retirés** le 2026-10-29 avec leurs objets : seul reste le voisinage des catalyseurs ([[Éléments abandonnés]]).

- Images : planches dans `images/`, découpées en icônes par `outils/decouper_icones.gd` ([[Commandes et outils]]). Les objets nouveaux (Automne, Jour, plusieurs armes) n'ont pas encore d'icône.
