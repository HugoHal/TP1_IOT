# Mes tâches - HAI912I · TP 1

## 1. Projet

**Mes tâches** est un gestionnaire de tâches personnel développé en Flutter / Dart dans le cadre du TP 1 de l'UE *HAI912I - Développement mobile avancé, IoT et embarqué* (Université de Montpellier, 2026-2027).

### Membres du groupe
- **CANI Nicolas - 22112854 - Parcours IASD**
- **JOIGNEAULT Clément - 22203471 - Parcours IASD**
- **HALABLIAN Hugo - 22108781 - Parcours IASD**

### Fonctionnalités réalisées
- **Modèle Dart pur et immuable** (`Priorite`, `Echeance` scellée, `Tache`, décodage JSON strict avec validation calendaire, calcul de retard, bilan par record nommé, filtrage/tri).
- **Liste de tâches interactive** : chargement depuis `tachesExempleJson`, compteur global *« n à faire »* et progression *« faites/total terminées »*, cochage/décochage immédiat sans mutation.
- **Filtrage** : sélecteur à trois choix (*Toutes*, *À faire*, *Faites*) sans altération du compteur global, messages dédiés si la liste filtrée est vide.
- **Consultation et action depuis le détail** : affichage complet (titre intégral, priorité, statut, échéance, indicateur de retard, note ou *« aucune note »*), marquage fait/à faire cohérent même avec un filtre actif.
- **Formulaire de création validé** : titre obligatoire (≤ 60 caractères), priorité (*Normale* par défaut), échéance facultative (date picker bloquant les dates passées), note facultative multilignes (≤ 200 caractères), nettoyage automatique des espaces (`trim()`).
- **Bonus G1 à G4** : modification en place, suppression avec annulation (`SnackBar`), tri et regroupement par échéance, mise en page adaptative Master-Detail (≥ 840 px).

---

## 2. Architecture

```text
mes_taches/
├── lib/
│   ├── main.dart                         # Point d'entrée, MaterialApp (Material 3) et injection optionnelle pour les tests
│   ├── donnees/
│   │   └── exemples.dart                 # Jeu de données JSON initial (tachesExempleJson)
│   ├── modele/
│   │   └── taches.dart                   # Modèle métier pur Dart (contrat public § 4.1, aucun import Flutter)
│   ├── ecrans/
│   │   ├── ecran_accueil.dart            # Écran principal : état global, filtres, tris, adaptatif Master-Detail
│   │   ├── ecran_detail.dart             # Écran de détail mobile (consultation + actions)
│   │   └── ecran_formulaire.dart         # Formulaire validé de création et de modification (G1)
│   └── widgets/
│       ├── tuile_tache.dart              # Widget Stateless réutilisable pour une ligne de tâche
│       └── detail_tache_contenu.dart     # Contenu de détail partagé entre EcranDetail (mobile) et Master-Detail (large)
├── test/
│   ├── modele_test.dart                  # Tests unitaires exhaustifs de la partie A
│   ├── widget_test.dart                  # Tests de widgets end-to-end (B2, C1, C3, D1/D2, E1, E2, G1-G4)
│   └── ecrans_test.dart                  # Tests unitaires de widgets (TuileTache, DetailTacheContenu, états vides, tris)
├── analysis_options.yaml                 # Configuration de l'analyseur statique (flutter_lints)
├── pubspec.yaml                          # Métadonnées et dépendances du projet
└── README.md                             # Documentation du projet
```

---

## 3. Environnement

- **Système d'exploitation** : Ubuntu 24.04.3 LTS (Linux 7.0.0-43-generic, x86_64)
- **Flutter & Dart** (`flutter --version`) :
  ```text
  Flutter 3.50.1 • channel stable • https://github.com/flutter/flutter.git
  Framework • revision ae9b586f34 • 2026-11-18 17:01:07 -0800
  Engine • hash 51379e6df48ea8ee7205623b90fe66491cad8df3 (revision 4d35714800)
  Tools • Dart 3.14.0 • DevTools 2.61.0
  ```
- **Environnement de développement (IDE)** : Android Studio 2026.2.2.10 (installé dans `~/develop/android-studio`)
- **Extensions / Greffons** : Flutter, Dart
- **Chaîne Android** : Android SDK 36 (`android-36`, `build-tools 36.1.0`, `platform-tools`, JDK 25 embarqué)
- **Dépendances principales (`pubspec.yaml`)** :
  - `flutter` (SDK)
  - `cupertino_icons: ^1.0.8`
  - `flutter_test` (dev)
  - `flutter_lints: ^6.0.0` (dev)

---

## 4. Plateformes

- **Web (obligatoire)** :
  - Navigateurs testés : **Firefox** (via `flutter run -d web-server --web-port=8080`, ouvert sur `http://localhost:8080`) et **Chromium** (`/snap/bin/chromium`, via `CHROME_EXECUTABLE=/snap/bin/chromium` et `flutter run -d chrome`)
  - Build vérifié : `flutter build web`
- **Android (encouragé)** :
  - SDK Android 36 configuré (`ANDROID_HOME=~/Android/Sdk`, `build-tools 36.1.0`, licences acceptées)
  - Build vérifié : `flutter build apk --debug`
  - Appareil testé : [À COMPLÉTER : modèle de votre téléphone Android connecté en débogage USB]
  ```text
  [✓] Flutter (Channel stable, 3.50.1, on Ubuntu 24.04.3 LTS 7.0.0-43-generic, locale fr_FR.UTF-8)
  [✓] Android toolchain - develop for Android devices (Android SDK version 36.1.0)
  [✓] Chrome - develop for the web
  [✓] Connected device (2 available)
  [✓] Network resources
  ```

---

## 5. Installation (depuis une copie propre)

Depuis le dossier `source/mes_taches/` de l'archive (placé dans un chemin court, sans espaces ni accents) :

```bash
# 1. Générer les dossiers plateformes (web/ et android/) sans écraser lib/ ni test/
flutter create --platforms=web,android .

# 2. Récupérer les dépendances
flutter pub get
```

---

## 6. Exécution et tests

```bash
# Lancer l'application sur Chrome / Chromium (Web)
flutter run -d chrome

# Lancer l'application sur serveur Web local (pour tester dans Firefox : http://localhost:8080)
flutter run -d web-server --web-port=8080

# Lancer l'application sur Android (si un émulateur ou téléphone est connecté)
flutter devices
flutter run -d <id_appareil>

# Exécuter l'ensemble des tests unitaires et de widgets
flutter test

# Vérifier l'analyse statique (0 problème attendu)
flutter analyze

# Vérifier le formatage du code
dart format lib test

# Construire la version Web de production (obligatoire)
flutter build web

# Construire l'APK de débogage Android (si la chaîne Android est installée)
flutter build apk --debug
```

### Dépannage rapide
- **`flutter` introuvable** : vérifier que `<sdk>/flutter/bin` est bien dans le `PATH`, puis rouvrir le terminal.
- **Chrome non détecté** : vérifier `flutter doctor` et définir `CHROME_EXECUTABLE` si nécessaire.
- **Erreur de dépendances** : exécuter `flutter clean && flutter pub get`.

---

## 7. Limites

- Les données sont conservées uniquement **en mémoire** (conformément au périmètre du TP 1) et sont réinitialisées lors d'un redémarrage complet (`R` ou rechargement de la page).
- Le formulaire permet de choisir une échéance *Aucune* ou *Date précise* (conformément à E1) ; la création directe d'une échéance *Hebdomadaire* depuis l'interface n'est pas proposée, bien que le modèle, l'affichage et la conservation lors de l'édition (G1) la prennent intégralement en charge.

---

## 8. Bonus réalisés

Tous les bonus de la partie G sont implémentés et couverts par des tests de widgets :

- **G1 - Modifier une tâche** : bouton *Modifier* dans l'écran de détail ([lib/ecrans/ecran_detail.dart](lib/ecrans/ecran_detail.dart)) et dans le panneau latéral ([lib/widgets/detail_tache_contenu.dart](lib/widgets/detail_tache_contenu.dart)), ouvrant `EcranFormulaire` pré-rempli tout en conservant le même `id`.
- **G2 - Supprimer avec annulation** : glissement vers la gauche (`Dismissible`) dans la liste ou bouton *Supprimer* dans le détail, affichant une `SnackBar` avec action *Annuler* qui remet la tâche à sa position exacte ([lib/ecrans/ecran_accueil.dart](lib/ecrans/ecran_accueil.dart)).
- **G3 - Trier et regrouper** : menu de tri (`Icons.sort`) dans la barre d'application (Défaut, Priorité, Échéance, Titre) ; le tri par *Échéance* regroupe les tâches sous les en-têtes *En retard*, *Datées*, *Hebdomadaires* et *Sans échéance*.
- **G4 - Mise en page adaptative** : `LayoutBuilder` basculant automatiquement en vue Master-Detail côte à côte au-delà de 840 px de largeur, tout en conservant la navigation mobile en dessous.

---

## 9. Liens

- **Dépôt Git** : https://github.com/HugoHal/TP1_IOT
- **Vidéo de démonstration** : [À COMPLÉTER : `video/demonstration.mp4` dans l'archive ou URL externe]
