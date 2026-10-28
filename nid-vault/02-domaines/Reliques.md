# Reliques

**Résumé :** Les quatre types de reliques (essence, sort, catalyseur, arme), leur rôle et leur format par Dynastie.
**Tags :** #reliques, #objets
**Mis à jour :** 2026-10-28
**Liens :** [[Dynasties]], [[Sac et formes]], [[Boutique et économie]], [[Cavaliers et armes]], [[Thèse du jeu]], [[Rencontres et objets neutres]]

---

| Type | Rôle | Prix de base |
|---|---|---|
| Essence | Affinité et stats brutes (PV, attaque, vitesse) | 3 |
| Sort | Capacité active avec recharge, plus forte si l'affinité de son élément est haute | 4 |
| Catalyseur | Renforce ses voisins (toute relique qui touche une de ses cases) | 4 |
| Arme | Tenue par le cavalier, lance son propre sort | 5 |

- Chaque relique donne de l'affinité à sa Dynastie : c'est ce qui fait éclore la monture ([[Dynasties#Forme de la créature]]).
- Règle de la [[Thèse du jeu]] : chaque relique change quelque chose de visible.
- Format par Dynastie : 10 objets de monture + 5 armes ([[Dynasties#Format cible : 15 objets par Dynastie]]).
- Descriptions des infobulles : `scripts/descriptions.gd`, à tenir à jour avec CONCEPTION.md.
## Signature de dynastie

**Décision :** chaque sort et chaque arme ajoute, à chaque activation, un petit effet de **son** élément (× niveau) : Été 1 brûlure, Printemps 1 dose de poison, Hiver 1 givre, Nuit draine 2 PV, Aube soigne 3 PV, Crépuscule un projectile d'arcane de 3 (`Data.SIGNATURES`).
**Pourquoi :** que chaque objet nourrisse la mécanique de sa dynastie, même ceux qui font autre chose.
**Essences :** sans activation, chacune donne un cinquième de sa signature à chaque attaque de la monture (`Data.SIGNATURE_ESSENCE`), demandé par l'utilisatrice.
**Alternatives écartées :** dépendre de la monture dominante (moins lisible, punit les hybrides).

## Placement

Au-delà des catalyseurs voisins, des reliques lisent leur position ([[2026-10-28 Reliques de placement]]) :

| Mot-clé | Effet | Objet |
|---|---|---|
| grappe | stats par voisine de la même dynastie | Mousse des sous-bois |
| solitaire | stats seulement si rien ne la touche | Stalagmite solitaire |
| rangée (`portee`) | catalyseur qui agit sur toute sa rangée | Traînée de cendres |
| copie | reprend une part de l'essence voisine la plus forte | Reflet d'aile |
| terreau | voisines +4 % par victoire avec lui dans le sac | Terreau fertile |

Catalyseurs vol de vie (Calice de sang, Nuit) et recharge (Cadran solaire, Aube) : les deux effets génériques qui n'avaient pas d'objet.

- Images : planches dans `images/`, découpées en icônes par `outils/decouper_icones.gd` ([[Commandes et outils]]).
