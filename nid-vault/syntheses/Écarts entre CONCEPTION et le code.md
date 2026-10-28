# Écarts entre CONCEPTION et le code

**Résumé :** Les points où CONCEPTION.md ne décrivait plus le code, relevés au remplissage du vault, et leur réalignement.
**Tags :** #synthese, #documentation
**Mis à jour :** 2026-10-28
**Liens :** [[Nuit (Chauve-souris)]], [[Cavaliers et armes]], [[Run et carte]], [[Boutique et économie]], [[Périmètre du prototype]]

---

**État : réaligné le 2026-10-28.** CONCEPTION.md suit de nouveau le code sur tous les points ci-dessous.

| Sujet | Avant dans CONCEPTION.md | Corrigé selon le code |
|---|---|---|
| Armes de la Nuit | Faux lunaire, Faux du festin ; « Faux et Lame » | Arc de l'écho (Tir), Hache du bourreau (Hache) |
| Malédictions | Trois | Quatre, avec Stigmate (+10 % de dégâts reçus) |
| Pacte de la Nuit profonde | « les trois malédictions » | Au moins trois malédictions différentes (`PACTE_SEUIL`) |
| Cavaliers | Un cavalier générique, « une seule arme » | Quatre cavaliers à talent ; il tient toutes les armes |
| Nœud Marché | Tableau et pondération 50/22/12/8/8 | Retiré ; Duel 55, Rencontre 25, Élite 12, Feu 8 |
| Fusion des légendaires | « ne fusionnent pas » (section Rareté) | Tout fusionne : `Nid.peut_fusionner` ne teste que le niveau |
| Section 8 | « Pas d'hybride », élites en fantômes | Hybrides, élites, Bastion, choix du cavalier |
| Section 9 | Glace, moments du jour, hybrides à faire ; 21 paires | Automne, Jour, gardiens II et III ; 28 paires |
| Univers | « sept Dynasties » | Huit |
| Fusion | Ligne sur Voile, Foyer, Lune creuse (objets retirés) | Supprimée |

**Reste ouvert :** la répartition des familles d'armes ([[Cavaliers et armes#Familles d'armes]]), maintenant signalée « À trancher » dans CONCEPTION.md aussi.

**Leçon :** les deux derniers commits ont changé le code sans toucher CONCEPTION.md. À chaque note de discussion, vérifier si CONCEPTION.md doit suivre.
