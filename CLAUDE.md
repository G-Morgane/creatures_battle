# Nid

Autobattler roguelike en Godot 4 (2D) : on remplit un Nid de reliques, il en éclot une monture qui se bat avec son cavalier. Conception de référence : `CONCEPTION.md`.

> Les instructions de l'utilisatrice priment toujours sur ce fichier.

## Approche

- Lire les fichiers existants avant d'écrire du code.
- Réponses concises, raisonnement rigoureux.
- Modifier plutôt que réécrire un fichier entier.
- Ignorer les fichiers de plus de 100 Ko sauf nécessité.
- Tester avant de déclarer terminé.
- Pas de formules d'introduction ni de conclusion inutiles.
- Solutions simples et directes.

## Mémoire du projet : `nid-vault/`

Le dossier `nid-vault/` est un wiki maintenu par Claude, ouvrable comme vault Obsidian (vue Graphe via les liens `[[...]]`). La connaissance du projet s'y accumule au lieu de se perdre entre les sessions.

```
Sources brutes        →    nid-vault/         →    CLAUDE.md
(00-inbox/, notes,        (wiki markdown          (ce schéma)
 CONCEPTION.md)            maintenu par Claude)
```

**En début de session** : lire `nid-vault/index.md` et les dernières lignes de `nid-vault/log.md`, puis les pages liées au sujet du jour.

### Opérations

**Discussion** : à la fin d'une session où quelque chose a été décidé, appris ou laissé en suspens :
1. Écrire `nid-vault/discussions/AAAA-MM-JJ sujet.md` (décisions avec leur raison, questions ouvertes, suite).
2. Reporter les décisions dans les pages de `02-domaines/` concernées (les créer si besoin).
3. Mettre à jour `index.md` et ajouter une ligne à `log.md`.
Ne pas consigner ce que le code ou l'historique git disent déjà ; consigner le *pourquoi*.

**Ingestion** : quand une source arrive dans `00-inbox/` :
1. La lire, repérer les pages concernées via `index.md`.
2. Mettre à jour ou créer les pages.
3. `log.md` : `| date | ingest | source → pages |`.

**Question** : répondre depuis le wiki ; si la réponse est une synthèse non évidente, la ranger dans `syntheses/`. Ligne dans `log.md`.

**Nettoyage** (sur demande ou quand le wiki vieillit) : contradictions entre pages ou avec le code, pages absentes de l'index, sujets cités partout sans page propre. Ligne dans `log.md`.

Conventions détaillées (format des pages, dossiers) : `nid-vault/CLAUDE.md`.
`00-inbox/` et `secrets/` sont gitignorés ; `.gdignore` tient le vault hors de l'import Godot.

## Code

- Ne rien supposer : expliciter les hypothèses, demander si c'est ambigu.
- Le minimum de code qui résout le problème, pas d'abstraction spéculative.
- Changements chirurgicaux : ne toucher que ce que la demande exige, suivre le style existant.
- Transformer la demande en critère vérifiable (test, lancement du jeu) et boucler jusqu'à ce qu'il passe.
