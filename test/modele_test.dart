import 'package:flutter_test/flutter_test.dart';
import 'package:mes_taches/modele/taches.dart';

void main() {
  group('Priorite & prioriteDepuisCode', () {
    test('l’énumération respecte l’ordre basse, normale, haute', () {
      expect(Priorite.values, [
        Priorite.basse,
        Priorite.normale,
        Priorite.haute,
      ]);
      expect(Priorite.basse.libelle, 'Basse');
      expect(Priorite.normale.libelle, 'Normale');
      expect(Priorite.haute.libelle, 'Haute');
    });

    test('prioriteDepuisCode associe correctement les codes valides', () {
      expect(prioriteDepuisCode('low'), Priorite.basse);
      expect(prioriteDepuisCode('normal'), Priorite.normale);
      expect(prioriteDepuisCode('high'), Priorite.haute);
    });

    test(
      'prioriteDepuisCode renvoie null pour les codes inconnus ou invalides',
      () {
        expect(prioriteDepuisCode('High'), isNull);
        expect(prioriteDepuisCode('urgent'), isNull);
        expect(prioriteDepuisCode(''), isNull);
        expect(prioriteDepuisCode('LOW'), isNull);
        expect(prioriteDepuisCode('autre'), isNull);
      },
    );
  });

  group('Echeance & libelleEcheance', () {
    test('Echeance.aucune produit "sans échéance"', () {
      const echeance = Echeance.aucune();
      expect(libelleEcheance(echeance), 'sans échéance');
      expect(echeance, equals(const SansEcheance()));
    });

    test('Echeance.date produit "pour le J/M" sans zéro initial', () {
      final echeance1 = Echeance.date(DateTime(2026, 12, 1));
      expect(libelleEcheance(echeance1), 'pour le 1/12');

      final echeance2 = Echeance.date(DateTime(2026, 3, 5, 14, 30));
      expect(libelleEcheance(echeance2), 'pour le 5/3');
    });

    test('Echeance.hebdomadaire produit "chaque <jour>" en minuscules', () {
      expect(libelleEcheance(Echeance.hebdomadaire(1)), 'chaque lundi');
      expect(libelleEcheance(Echeance.hebdomadaire(2)), 'chaque mardi');
      expect(libelleEcheance(Echeance.hebdomadaire(3)), 'chaque mercredi');
      expect(libelleEcheance(Echeance.hebdomadaire(4)), 'chaque jeudi');
      expect(libelleEcheance(Echeance.hebdomadaire(5)), 'chaque vendredi');
      expect(libelleEcheance(Echeance.hebdomadaire(6)), 'chaque samedi');
      expect(libelleEcheance(Echeance.hebdomadaire(7)), 'chaque dimanche');
    });

    test('Echeance.hebdomadaire lève ArgumentError si hors de [1, 7]', () {
      expect(() => Echeance.hebdomadaire(0), throwsArgumentError);
      expect(() => Echeance.hebdomadaire(8), throwsArgumentError);
      expect(() => Echeance.hebdomadaire(-1), throwsArgumentError);
    });
  });

  group('Tache & Immuabilité', () {
    test('constructeur refuse id vide ou titre vide', () {
      expect(() => Tache(id: '', titre: 'Test'), throwsArgumentError);
      expect(() => Tache(id: '1', titre: ''), throwsArgumentError);
    });

    test(
      'copierAvec ne modifie pas l’originale et permet de remettre note à null',
      () {
        final originale = Tache(
          id: 't1',
          titre: 'Tâche originale',
          priorite: Priorite.haute,
          echeance: Echeance.hebdomadaire(2),
          note: 'Une note initiale',
          faite: false,
        );

        final modifiee = originale.copierAvec(
          titre: 'Tâche modifiée',
          faite: true,
          note: null,
        );

        expect(modifiee.id, 't1');
        expect(modifiee.titre, 'Tâche modifiée');
        expect(modifiee.faite, isTrue);
        expect(modifiee.note, isNull);
        expect(modifiee.priorite, Priorite.haute);
        expect(modifiee.echeance, Echeance.hebdomadaire(2));

        // L'originale est rigoureusement intacte
        expect(originale.titre, 'Tâche originale');
        expect(originale.faite, isFalse);
        expect(originale.note, 'Une note initiale');
      },
    );
  });

  group('tacheDepuisJson', () {
    test('document valide minimal (sans due ni note)', () {
      final json = {
        'id': 't1',
        'title': 'Installer Flutter',
        'priority': 'high',
        'done': true,
      };

      final tache = tacheDepuisJson(json);
      expect(tache.id, 't1');
      expect(tache.titre, 'Installer Flutter');
      expect(tache.priorite, Priorite.haute);
      expect(tache.faite, isTrue);
      expect(tache.echeance, const Echeance.aucune());
      expect(tache.note, isNull);
    });

    test('document valide complet avec clés superflues ignorées', () {
      final json = {
        'id': 't2',
        'title': 'Appeler le médecin',
        'priority': 'normal',
        'done': false,
        'due': '2026-11-20',
        'note': 'Rappeler à 14h',
        'extra_key': 'ignored',
        'metadata': 42,
      };

      final tache = tacheDepuisJson(json);
      expect(tache.id, 't2');
      expect(tache.titre, 'Appeler le médecin');
      expect(tache.priorite, Priorite.normale);
      expect(tache.faite, isFalse);
      expect(tache.echeance, equals(Echeance.date(DateTime(2026, 11, 20))));
      expect(tache.note, 'Rappeler à 14h');
    });

    test(
      'lève FormatException si clé obligatoire manquante ou mauvaise priorité',
      () {
        // id manquant
        expect(
          () =>
              tacheDepuisJson({'title': 'T', 'priority': 'low', 'done': false}),
          throwsFormatException,
        );
        // title manquant
        expect(
          () => tacheDepuisJson({'id': '1', 'priority': 'low', 'done': false}),
          throwsFormatException,
        );
        // priority manquante
        expect(
          () => tacheDepuisJson({'id': '1', 'title': 'T', 'done': false}),
          throwsFormatException,
        );
        // done manquant
        expect(
          () => tacheDepuisJson({'id': '1', 'title': 'T', 'priority': 'low'}),
          throwsFormatException,
        );
        // priorité inconnue
        expect(
          () => tacheDepuisJson({
            'id': '1',
            'title': 'T',
            'priority': 'unknown',
            'done': false,
          }),
          throwsFormatException,
        );
      },
    );

    test('lève FormatException si type invalide ou chaîne vide', () {
      expect(
        () => tacheDepuisJson({
          'id': '',
          'title': 'T',
          'priority': 'low',
          'done': false,
        }),
        throwsFormatException,
      );
      expect(
        () => tacheDepuisJson({
          'id': 123,
          'title': 'T',
          'priority': 'low',
          'done': false,
        }),
        throwsFormatException,
      );
      expect(
        () => tacheDepuisJson({
          'id': '1',
          'title': '',
          'priority': 'low',
          'done': false,
        }),
        throwsFormatException,
      );
      expect(
        () => tacheDepuisJson({
          'id': '1',
          'title': 'T',
          'priority': 'low',
          'done': 'true',
        }),
        throwsFormatException,
      );
      expect(
        () => tacheDepuisJson({
          'id': '1',
          'title': 'T',
          'priority': 'low',
          'done': false,
          'note': 999,
        }),
        throwsFormatException,
      );
      expect(
        () => tacheDepuisJson({
          'id': '1',
          'title': 'T',
          'priority': 'low',
          'done': false,
          'due': 20261120,
        }),
        throwsFormatException,
      );
    });

    test('lève FormatException si due a un format invalide ou une date calendaire impossible', () {
      // Format incorrect
      expect(
        () => tacheDepuisJson({
          'id': '1',
          'title': 'T',
          'priority': 'low',
          'done': false,
          'due': '2026/11/20',
        }),
        throwsFormatException,
      );
      expect(
        () => tacheDepuisJson({
          'id': '1',
          'title': 'T',
          'priority': 'low',
          'done': false,
          'due': '2026-1-1',
        }),
        throwsFormatException,
      );
      // Date inexistante : 30 février 2026
      expect(
        () => tacheDepuisJson({
          'id': '1',
          'title': 'T',
          'priority': 'low',
          'done': false,
          'due': '2026-02-30',
        }),
        throwsFormatException,
      );
      // Mois 13
      expect(
        () => tacheDepuisJson({
          'id': '1',
          'title': 'T',
          'priority': 'low',
          'done': false,
          'due': '2026-13-01',
        }),
        throwsFormatException,
      );
      // 31 avril
      expect(
        () => tacheDepuisJson({
          'id': '1',
          'title': 'T',
          'priority': 'low',
          'done': false,
          'due': '2026-04-31',
        }),
        throwsFormatException,
      );
    });
  });

  group('estEnRetard', () {
    final ref = DateTime(2026, 11, 21, 10, 0);

    test(
      'true si et seulement si non faite et date antérieure au jour calendaire',
      () {
        final hier = Tache(
          id: '1',
          titre: 'Tâche d’hier',
          echeance: Echeance.date(DateTime(2026, 11, 20)),
          faite: false,
        );
        expect(estEnRetard(hier, aujourdhui: ref), isTrue);
      },
    );

    test('false si la tâche est déjà faite même si la date est passée', () {
      final hierFaite = Tache(
        id: '1',
        titre: 'Tâche faite',
        echeance: Echeance.date(DateTime(2026, 11, 20)),
        faite: true,
      );
      expect(estEnRetard(hierFaite, aujourdhui: ref), isFalse);
    });

    test('false pour le jour même quelle que soit l’heure', () {
      final aujourdhuiMemeHeure = Tache(
        id: '1',
        titre: 'Aujourd’hui',
        echeance: Echeance.date(DateTime(2026, 11, 21, 8, 0)),
        faite: false,
      );
      expect(estEnRetard(aujourdhuiMemeHeure, aujourdhui: ref), isFalse);
    });

    test('false pour une date future', () {
      final demain = Tache(
        id: '1',
        titre: 'Demain',
        echeance: Echeance.date(DateTime(2026, 11, 22)),
        faite: false,
      );
      expect(estEnRetard(demain, aujourdhui: ref), isFalse);
    });

    test('false sans échéance ou pour une échéance hebdomadaire', () {
      final sans = Tache(id: '1', titre: 'Sans', faite: false);
      final hebdo = Tache(
        id: '2',
        titre: 'Hebdo',
        echeance: Echeance.hebdomadaire(5),
        faite: false,
      );
      expect(estEnRetard(sans, aujourdhui: ref), isFalse);
      expect(estEnRetard(hebdo, aujourdhui: ref), isFalse);
    });
  });

  group('bilan', () {
    test('collection vide renvoie (faites: 0, total: 0)', () {
      final b = bilan([]);
      expect(b, (faites: 0, total: 0));
    });

    test('collection non vide renvoie le nombre exact de faites et total', () {
      final taches = [
        Tache(id: '1', titre: 'T1', faite: true),
        Tache(id: '2', titre: 'T2', faite: false),
        Tache(id: '3', titre: 'T3', faite: true),
      ];
      final b = bilan(taches);
      expect(b.faites, 2);
      expect(b.total, 3);
    });
  });

  group('aFaire', () {
    test('filtre par auMoins et trie par priorité décroissante puis titre croissant', () {
      final tBasseA = Tache(
        id: '1',
        titre: 'Alpha',
        priorite: Priorite.basse,
        faite: false,
      );
      final tBasseZ = Tache(
        id: '2',
        titre: 'Zeta',
        priorite: Priorite.basse,
        faite: false,
      );
      final tNormale = Tache(
        id: '3',
        titre: 'Beta',
        priorite: Priorite.normale,
        faite: false,
      );
      final tHaute = Tache(
        id: '4',
        titre: 'Gamma',
        priorite: Priorite.haute,
        faite: false,
      );
      final tFaite = Tache(
        id: '5',
        titre: 'Delta',
        priorite: Priorite.haute,
        faite: true,
      );

      final source = [tBasseZ, tBasseA, tFaite, tNormale, tHaute];
      final copieSource = List<Tache>.from(source);

      final resultat = aFaire(source, auMoins: Priorite.normale);

      // tFaite est exclue car faite
      // tBasseA et tBasseZ sont exclues car priorité < normale
      expect(resultat, [tHaute, tNormale]);

      // Vérifie que la source n'a pas été mutée
      expect(source, equals(copieSource));

      // Test avec toutes les priorités
      final toutesAFaire = aFaire(source, auMoins: Priorite.basse);
      expect(toutesAFaire, [
        tHaute,
        tNormale,
        tBasseA, // Alpha avant Zeta
        tBasseZ,
      ]);
    });
  });
}
