# Dynasties

**Résumé :** Huit Dynasties (4 saisons, 4 moments du jour), chacune un grand principe et sa monture ; l'affinité dominante du Nid fixe la forme, une seconde dynastie donne un hybride.
**Tags :** #dynasties, #elements, #montures, #hybrides
**Mis à jour :** 2026-10-29
**Liens :** [[Printemps (Cerf)]], [[Été (Phénix)]], [[Hiver (Ours)]], [[Nuit (Chauve-souris)]], [[Aube (Lion)]], [[Crépuscule (Papillon)]], [[Automne et Jour]], [[Reliques]], [[Cavaliers et armes]], [[Combat]], [[Éléments abandonnés]], [[2026-10-29 Archétypes resserrés]]

---

## Les huit

| Dynastie | Monture | Code | Principe | Famille d'armes |
|---|---|---|---|---|
| [[Printemps (Cerf)\|Printemps]] | Cerf | `nature` | Qui me touche s'empoisonne | Tir |
| [[Été (Phénix)\|Été]] | Phénix | `feu` | Allumer puis consumer | Bâton |
| [[Automne et Jour\|Automne]] | Renard | `automne` | Esquiver, puis frapper juste | Lame |
| [[Hiver (Ours)\|Hiver]] | Ours | `glace` | Ralentir jusqu'au gel | Hache |
| [[Aube (Lion)\|Aube]] | Lion | `aube` | Soigner pour frapper | Hast |
| [[Automne et Jour\|Jour]] | Paon | `jour` | Faire la roue : enchaîner les armes | Tir |
| [[Crépuscule (Papillon)\|Crépuscule]] | Papillon | `crepuscule` | Lancer des sorts, semer des illusions | Bâton |
| [[Nuit (Chauve-souris)\|Nuit]] | Chauve-souris | `nuit` | Affaiblir avant de frapper | Faux |

Toutes jouables depuis le 2026-10-29. À l'écran, une affinité porte le nom de la Dynastie (« Été 7 »), pas le code.

## Format : 10 objets, un principe

**Décision (2026-10-29) :** chaque Dynastie a un seul grand principe (un verbe, une ressource, un passif) et 10 objets : 7 de monture (3 communs, 2 rares, 1 épique, 1 légendaire qui change une règle) et 3 armes d'une seule famille.
**Pourquoi :** 16 à 18 objets et deux à quatre mécaniques par Dynastie ; les archétypes se lisaient mal et se chevauchaient.
**Alternatives écartées :** 15 objets par Dynastie (10 + 5 armes), l'ancien format cible.

Le gabarit et les tableaux d'objets sont dans CONCEPTION.md, section 5. `tests/smoke.gd` (`_familles`) vérifie le format.

## Forme de la créature

- Chaque relique donne des points d'**affinité** dans un élément.
- **Dominante** : fixe la forme de base, l'identité de jeu et le passif.
- **Hybride** : dès que le sac contient au moins 2 objets d'une autre dynastie, la monture est l'hybride des deux (28 images dans `images/hybrides`), nommé dominante d'abord (« Phénix-Chauve-souris »). Le passif reste celui de la dominante.
- **Aucune affinité** : créature informe, sans passif.
- Les montures sont cachées à la sélection et dans le glossaire.

## Paires à garder distinctes

- **Automne / Crépuscule** : l'esquive est au hasard, l'Illusion est une charge sûre produite par les sorts.
- **Aube / Printemps** : l'Aube soigne, le Printemps punit.
- **Brûlure / poison** : la brûlure est courte et consumée, le poison s'empile et dure.
- **Jour / Aube** : le Jour enchaîne les armes, l'Aube convertit le soin en dégâts.

## Contres

- Le Hast de l'Aube perce l'esquive de l'Automne et les Illusions du Crépuscule.
- Les épines du Printemps punissent les armes rapides du Jour.
- La Belladone et la Flétrissure gênent l'Aube, qui charge quand même son Éclat.
