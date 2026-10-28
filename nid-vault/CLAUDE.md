# Vault Nid — conventions

Wiki maintenu par Claude pour le projet Nid. Architecture et opérations : voir le `CLAUDE.md` à la racine.
S'ouvre tel quel comme vault Obsidian : la vue Graphe se construit à partir des liens `[[...]]`.

## Dossiers

- **`00-inbox/`** : sources brutes (notes, captures, exports). Jamais modifiées. **Gitignoré.**
- **`01-projets/`** : chantiers en cours avec une fin (ex. « refonte des armes de la Nuit »).
- **`02-domaines/`** : sujets permanents du jeu, le cœur du wiki (combat, éléments, montures, cavaliers, reliques, boutique, carte…).
- **`03-ressources/`** : références durables (pipeline des images, conventions Godot, outils).
- **`04-archives/`** : terminé ou abandonné, avec la raison.
- **`discussions/`** : une note par session de travail avec Claude, `AAAA-MM-JJ sujet.md`.
- **`syntheses/`** : réponses non évidentes à une question, rangées pour ne pas les redériver.
- **`secrets/`** : clés et fichiers privés. **Gitignoré.** Ne jamais recopier leur contenu dans une page.

`.gdignore` empêche Godot d'importer le vault.

## Format d'une page

```
# Titre

**Résumé :** une phrase.
**Tags :** #combat, #nuit
**Mis à jour :** AAAA-MM-JJ
**Liens :** [[Autre page]], [[Encore une]]

---

Contenu
```

- Un sujet par page, découper au-delà de ~400 lignes.
- Nom de fichier = titre de la page, pour que `[[Titre]]` résolve.
- Lier généreusement : chaque concept nommé qui a sa page est un `[[lien]]`. Un lien vers une page pas encore écrite est permis, il signale un trou.
- Même terme pour le même concept partout (celui de `CONCEPTION.md` et du code).
- Une décision s'écrit avec sa raison : **Décision**, **Pourquoi**, **Alternatives écartées**.

## Note de discussion

```
# AAAA-MM-JJ Sujet

**Tags :** #discussion
**Pages touchées :** [[...]]

## Contexte
## Décisions
## Questions ouvertes
## Suite
```

## index.md et log.md

- `index.md` : toutes les pages par catégorie. Mis à jour à chaque nouvelle page.
- `log.md` : ajout seulement, une ligne par opération. Ne jamais modifier les lignes passées.
