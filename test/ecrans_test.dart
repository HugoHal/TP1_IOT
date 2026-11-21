import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mes_taches/ecrans/ecran_detail.dart';
import 'package:mes_taches/main.dart';
import 'package:mes_taches/modele/taches.dart';
import 'package:mes_taches/widgets/detail_tache_contenu.dart';
import 'package:mes_taches/widgets/tuile_tache.dart';

void main() {
  final dateRef = DateTime(2026, 11, 21, 10, 0);

  group('TuileTache', () {
    testWidgets('affiche le titre barré quand la tâche est faite', (
      tester,
    ) async {
      final tacheFaite = Tache(id: '1', titre: 'Tâche terminée', faite: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TuileTache(
              tache: tacheFaite,
              aujourdhui: dateRef,
              onBasculer: (_) {},
              onOuvrir: () {},
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('Tâche terminée'));
      expect(textWidget.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('signale visuellement un retard avec icône et libellé', (
      tester,
    ) async {
      final tacheEnRetard = Tache(
        id: '1',
        titre: 'En retard',
        echeance: Echeance.date(DateTime(2026, 11, 20)),
        faite: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TuileTache(
              tache: tacheEnRetard,
              aujourdhui: dateRef,
              onBasculer: (_) {},
              onOuvrir: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.text('pour le 20/11'), findsOneWidget);
    });
  });

  group('DetailTacheContenu', () {
    testWidgets('affiche "aucune note" en italique si la note est absente', (
      tester,
    ) async {
      final tacheSansNote = Tache(id: '1', titre: 'Tâche sans note');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DetailTacheContenu(
              tache: tacheSansNote,
              aujourdhui: dateRef,
              onBasculerFait: () {},
              onModifier: () {},
              onSupprimer: () {},
            ),
          ),
        ),
      );

      final noteWidget = tester.widget<Text>(find.text('aucune note'));
      expect(noteWidget.style?.fontStyle, FontStyle.italic);
    });

    testWidgets('affiche le badge "En retard" si la date est dépassée', (
      tester,
    ) async {
      final tacheEnRetard = Tache(
        id: '1',
        titre: 'Tâche urgente',
        echeance: Echeance.date(DateTime(2026, 11, 15)),
        faite: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DetailTacheContenu(
              tache: tacheEnRetard,
              aujourdhui: dateRef,
              onBasculerFait: () {},
              onModifier: () {},
              onSupprimer: () {},
            ),
          ),
        ),
      );

      expect(find.text('En retard'), findsOneWidget);
    });
  });

  group('Messages de liste vide (C3)', () {
    testWidgets(
      'affiche "Aucune tâche" si la collection est initialement vide',
      (tester) async {
        await tester.pumpWidget(
          MesTachesApp(tachesInitiales: const [], aujourdhui: dateRef),
        );
        await tester.pumpAndSettle();

        expect(find.text('Aucune tâche'), findsOneWidget);
        expect(find.text('0 à faire'), findsOneWidget);
      },
    );

    testWidgets('affiche "Aucune tâche faite" quand aucune tâche n’est faite', (
      tester,
    ) async {
      final taches = [
        Tache(id: '1', titre: 'T1', faite: false),
        Tache(id: '2', titre: 'T2', faite: false),
      ];

      await tester.pumpWidget(
        MesTachesApp(tachesInitiales: taches, aujourdhui: dateRef),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Faites'));
      await tester.pumpAndSettle();

      expect(find.text('Aucune tâche faite'), findsOneWidget);
    });

    testWidgets(
      'affiche "Aucune tâche à faire" quand toutes les tâches sont faites',
      (tester) async {
        final taches = [Tache(id: '1', titre: 'T1', faite: true)];

        await tester.pumpWidget(
          MesTachesApp(tachesInitiales: taches, aujourdhui: dateRef),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('À faire'));
        await tester.pumpAndSettle();

        expect(find.text('Aucune tâche à faire'), findsOneWidget);
      },
    );
  });

  group('Tris de la liste (G3)', () {
    testWidgets('le tri par Titre classe les tâches par ordre alphabétique', (
      tester,
    ) async {
      final taches = [
        Tache(id: '1', titre: 'Zoulou'),
        Tache(id: '2', titre: 'Alpha'),
        Tache(id: '3', titre: 'Bravo'),
      ];

      await tester.pumpWidget(
        MesTachesApp(tachesInitiales: taches, aujourdhui: dateRef),
      );
      await tester.pumpAndSettle();

      // Ouvrir le menu de tri
      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();

      // Choisir 'Titre'
      await tester.tap(find.text('Titre'));
      await tester.pumpAndSettle();

      // Vérifier l'ordre des tuiles
      final tuiles = tester
          .widgetList<TuileTache>(find.byType(TuileTache))
          .toList();
      expect(tuiles.map((t) => t.tache.titre).toList(), [
        'Alpha',
        'Bravo',
        'Zoulou',
      ]);
    });

    testWidgets(
      'le tri par Priorité classe de la plus urgente (Haute) à la moins urgente (Basse)',
      (tester) async {
        final taches = [
          Tache(id: '1', titre: 'Basse', priorite: Priorite.basse),
          Tache(id: '2', titre: 'Haute', priorite: Priorite.haute),
          Tache(id: '3', titre: 'Normale', priorite: Priorite.normale),
        ];

        await tester.pumpWidget(
          MesTachesApp(tachesInitiales: taches, aujourdhui: dateRef),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.sort));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Priorité'));
        await tester.pumpAndSettle();

        final tuiles = tester
            .widgetList<TuileTache>(find.byType(TuileTache))
            .toList();
        expect(tuiles.map((t) => t.tache.priorite).toList(), [
          Priorite.haute,
          Priorite.normale,
          Priorite.basse,
        ]);
      },
    );
  });

  group('EcranDetail', () {
    testWidgets('le bouton de suppression appelle le callback onSupprimer', (
      tester,
    ) async {
      var supprimeId = '';
      final t = Tache(id: 't_del', titre: 'À supprimer');

      await tester.pumpWidget(
        MaterialApp(
          home: EcranDetail(
            tache: t,
            aujourdhui: dateRef,
            onBasculerFait: (_) {},
            onModifier: (_) {},
            onSupprimer: (id) => supprimeId = id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Cliquer sur l'icône poubelle dans l'AppBar
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      expect(supprimeId, 't_del');
    });
  });
}
