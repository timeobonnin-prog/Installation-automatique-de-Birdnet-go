# Journal des modifications (Changelog)

Toutes les modifications notables de ce projet sont documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/lang/fr/).

## [Non publié]
### Ajouté
- Dashboard avec statistiques (sparkline 24h, top 5 espèces).
- Vérification SHA-256 automatique avant toute mise à jour.
- Synchronisation automatique du port avec `config.yaml` du moteur.
- Raccourci clavier global `Ctrl+Alt+B`.
- 16 langues prises en charge avec aperçu instantané.

### Modifié
- Passage à un canal de mise à jour statique (`update.json`) pour éviter les quotas API GitHub.
- Amélioration de la détection des crashs du moteur (watchdog).

### Corrigé
- Freeze de l'interface lors du calcul du hash SHA-256 (déporté en tâche de fond).
- Fichiers de mise à jour verrouillés dans le dossier Temp (utilisation de noms horodatés uniques).

## [1.0.0] - 2024-XX-XX
### Ajouté
- Première version stable du panneau de contrôle WPF.
- Installateur Inno Setup multilingue avec option de pare-feu.
- Support Windows, Linux (deb), macOS (pkg).
