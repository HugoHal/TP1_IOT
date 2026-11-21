import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mes_taches/ecrans/ecran_formulaire.dart';
import 'package:mes_taches/main.dart';
import 'package:mes_taches/widgets/tuile_tache.dart';

void main() {
  final dateFixe = DateTime(2026, 11, 21, 10, 0);

  testWidgets("l'application démarre et affiche son titre", (tester) async {
    await tester.pumpWidget(MesTachesApp(aujourdhui: dateFixe));
    await tester.pumpAndSettle();

    expect(find.text('Mes tâches'), findsOneWidget);
  });

  testWidgets(
    'B2 : cocher puis décocher une tâche met à jour le compteur global',
    (tester) async {
      await tester.pumpWidget(MesTachesApp(aujourdhui: dateFixe));
      await tester.pumpAndSettle();

      // Initialement : 1 faite (t1), 5 à faire (t2..t6)
      expect(find.text('5 à faire'), findsOneWidget);

      // Trouver la case à cocher de la deuxième tâche ("Relire le CM 01")
      final premierCheckbox = find.byType(Checkbox).at(1);
      await tester.tap(premierCheckbox);
      await tester.pumpAndSettle();

      // La tâche est maintenant faite -> 4 à faire
      expect(find.text('4 à faire'), findsOneWidget);

      // Décocher à nouveau
      await tester.tap(premierCheckbox);
      await tester.pumpAndSettle();

      // Retour à 5 à faire
      expect(find.text('5 à faire'), findsOneWidget);
    },
  );

  testWidgets(
    'C1 : basculer entre Toutes, À faire et Faites filtre la liste en conservant le compteur global',
    (tester) async {
      await tester.pumpWidget(MesTachesApp(aujourdhui: dateFixe));
      await tester.pumpAndSettle();

      expect(find.text('5 à faire'), findsOneWidget);

      // Basculer sur 'À faire'
      await tester.tap(find.text('À faire'));
      await tester.pumpAndSettle();

      // Compteur global inchangé
      expect(find.text('5 à faire'), findsOneWidget);
      // t1 ("Installer Flutter") est faite, elle ne doit plus être visible
      expect(find.text('Installer Flutter'), findsNothing);
      // t2 ("Relire le CM 01") est non faite, elle doit être visible
      expect(find.text('Relire le CM 01'), findsOneWidget);

      // Basculer sur 'Faites'
      await tester.tap(find.text('Faites'));
      await tester.pumpAndSettle();

      expect(find.text('5 à faire'), findsOneWidget);
      // Seule t1 doit être visible
      expect(find.text('Installer Flutter'), findsOneWidget);
      expect(find.text('Relire le CM 01'), findsNothing);

      // Basculer sur 'Toutes'
      await tester.tap(find.text('Toutes'));
      await tester.pumpAndSettle();

      expect(find.text('Installer Flutter'), findsOneWidget);
      expect(find.text('Relire le CM 01'), findsOneWidget);
    },
  );

  testWidgets(
    'D1 & D2 : avec le filtre À faire actif, ouvrir la 2e tâche, marquer comme faite, vérifier pop et mise à jour',
    (tester) async {
      await tester.pumpWidget(MesTachesApp(aujourdhui: dateFixe));
      await tester.pumpAndSettle();

      // Activer filtre 'À faire'
      await tester.tap(find.text('À faire'));
      await tester.pumpAndSettle();

      expect(find.text('5 à faire'), findsOneWidget);

      // Dans 'À faire', la 2e tâche est "Faire les courses" (t3)
      expect(find.text('Faire les courses'), findsOneWidget);
      await tester.tap(find.text('Faire les courses'));
      await tester.pumpAndSettle();

      // Sur l'écran de détail : vérifier contenu complet
      expect(find.text('Détail de la tâche'), findsOneWidget);
      expect(find.text('Faire les courses'), findsOneWidget);
      expect(find.text('pain, lait, café'), findsOneWidget);
      expect(find.text('Priorité basse'), findsOneWidget);

      // Cliquer sur 'Marquer comme faite'
      await tester.tap(find.text('Marquer comme faite'));
      await tester.pumpAndSettle();

      // L'écran de détail s'est fermé, on est de retour sur la liste
      expect(find.text('Détail de la tâche'), findsNothing);

      // Elle a disparu du filtre 'À faire'
      expect(find.text('Faire les courses'), findsNothing);

      // Le compteur a été décrémenté
      expect(find.text('4 à faire'), findsOneWidget);

      // Dans 'Faites', elle est maintenant présente
      await tester.tap(find.text('Faites'));
      await tester.pumpAndSettle();
      expect(find.text('Faire les courses'), findsOneWidget);
    },
  );

  testWidgets(
    'E2 : soumettre un formulaire invalide affiche les messages d’erreur et bloque la soumission',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: EcranFormulaire(dateReference: dateFixe)),
      );
      await tester.pumpAndSettle();

      final boutonEnregistrer = find.text('Enregistrer');

      // 1. Titre vide ou espaces uniquement
      final champTitre = find.byType(TextFormField).first;
      await tester.enterText(champTitre, '    ');
      await tester.tap(boutonEnregistrer);
      await tester.pumpAndSettle();

      expect(find.text('Le titre est obligatoire.'), findsOneWidget);

      // 2. Titre de 61 caractères
      await tester.enterText(champTitre, 'A' * 61);
      await tester.tap(boutonEnregistrer);
      await tester.pumpAndSettle();

      expect(
        find.text('Le titre ne doit pas dépasser 60 caractères.'),
        findsOneWidget,
      );

      // 3. Titre valide, mais note de 201 caractères
      await tester.enterText(champTitre, 'Titre valide');
      final champNote = find.byType(TextFormField).last;
      await tester.enterText(champNote, 'B' * 201);
      await tester.tap(boutonEnregistrer);
      await tester.pumpAndSettle();

      expect(
        find.text('La note ne doit pas dépasser 200 caractères.'),
        findsOneWidget,
      );

      // Le formulaire est toujours ouvert
      expect(find.text('Nouvelle tâche'), findsOneWidget);
    },
  );

  testWidgets(
    'E1 : créer une tâche valide l’ajoute à la liste (avec nettoyage des espaces) et met à jour le compteur',
    (tester) async {
      await tester.pumpWidget(MesTachesApp(aujourdhui: dateFixe));
      await tester.pumpAndSettle();

      expect(find.text('5 à faire'), findsOneWidget);

      // Ouvrir le formulaire
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Remplir le titre avec des espaces superflus en début et fin
      final champTitre = find.byType(TextFormField).first;
      await tester.enterText(champTitre, '  Préparer le TP 2  ');

      // Cliquer sur 'Enregistrer'
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      // De retour sur l'accueil, le compteur passe à 6 et le titre est nettoyé
      expect(find.text('6 à faire'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Préparer le TP 2'), 200);
      expect(find.text('Préparer le TP 2'), findsOneWidget);
    },
  );

  testWidgets(
    'Bonus G1 : modifier une tâche depuis le détail met à jour la tâche en gardant le même id',
    (tester) async {
      await tester.pumpWidget(MesTachesApp(aujourdhui: dateFixe));
      await tester.pumpAndSettle();

      // Ouvrir t2
      await tester.tap(find.text('Relire le CM 01'));
      await tester.pumpAndSettle();

      // Cliquer sur le bouton Modifier
      await tester.tap(find.widgetWithText(OutlinedButton, 'Modifier'));
      await tester.pumpAndSettle();

      expect(find.text('Modifier la tâche'), findsOneWidget);

      // Modifier le titre
      final champTitre = find.byType(TextFormField).first;
      await tester.enterText(champTitre, 'Relire le CM 01 et CM 02');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      // Revenir à l'accueil via retour AppBar
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Relire le CM 01 et CM 02'), findsOneWidget);
      // Vérifier pas de doublon : 5 à faire toujours
      expect(find.text('5 à faire'), findsOneWidget);
    },
  );

  testWidgets(
    'Bonus G2 : supprimer une tâche puis cliquer sur Annuler dans la SnackBar la restaure à son index',
    (tester) async {
      await tester.pumpWidget(MesTachesApp(aujourdhui: dateFixe));
      await tester.pumpAndSettle();

      expect(find.text('Relire le CM 01'), findsOneWidget);
      expect(find.text('5 à faire'), findsOneWidget);

      // Supprimer via Dismissible swipe
      await tester.drag(find.text('Relire le CM 01'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // La tâche a disparu
      expect(find.text('Relire le CM 01'), findsNothing);
      expect(find.text('4 à faire'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);

      // Cliquer sur Annuler
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      // La tâche est restaurée à son index d'origine (index 1, juste après t1)
      expect(find.text('Relire le CM 01'), findsOneWidget);
      expect(find.text('5 à faire'), findsOneWidget);
      final titresApresAnnulation = tester
          .widgetList<TuileTache>(find.byType(TuileTache))
          .map((t) => t.tache.titre)
          .toList();
      expect(titresApresAnnulation[1], 'Relire le CM 01');
    },
  );

  testWidgets(
    'Bonus G3 : trier par Échéance affiche les en-têtes de regroupement',
    (tester) async {
      await tester.pumpWidget(MesTachesApp(aujourdhui: dateFixe));
      await tester.pumpAndSettle();

      // Ouvrir le menu de tri
      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();

      // Choisir 'Échéance'
      await tester.tap(find.text('Échéance'));
      await tester.pumpAndSettle();

      // Vérifier les en-têtes de groupe
      expect(find.text('En retard'), findsOneWidget);
      expect(find.text('Datées'), findsOneWidget);
      expect(find.text('Sans échéance'), findsOneWidget);
    },
  );

  testWidgets(
    'Bonus G4 : Master-Detail sur grand écran (>= 840 px) affiche liste et détail côte à côte',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(MesTachesApp(aujourdhui: dateFixe));
      await tester.pumpAndSettle();

      // Initialement, message d'invitation à sélectionner une tâche
      expect(
        find.text('Sélectionnez une tâche pour voir ses détails'),
        findsOneWidget,
      );

      // Toucher une tâche dans la liste de gauche
      await tester.tap(find.text('Faire les courses'));
      await tester.pumpAndSettle();

      // Le détail s'affiche à droite sans pousser de nouvelle route
      expect(
        find.text('Sélectionnez une tâche pour voir ses détails'),
        findsNothing,
      );
      expect(find.text('pain, lait, café'), findsOneWidget);
      expect(find.text('Priorité basse'), findsOneWidget);

      // Marquer comme faite depuis le panneau droit
      await tester.tap(find.text('Marquer comme faite'));
      await tester.pumpAndSettle();

      expect(find.text('4 à faire'), findsOneWidget);
    },
  );

  testWidgets(
    'C3 : aucun débordement (RenderFlex overflow) entre 360 px et 1280 px de large',
    (tester) async {
      for (final largeur in [360.0, 480.0, 720.0, 840.0, 1024.0, 1280.0]) {
        tester.view.physicalSize = Size(largeur, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(MesTachesApp(aujourdhui: dateFixe));
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'Débordement détecté pour largeur $largeur px',
        );
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );
}
