// Modèle métier pur Dart pour l'application « Mes tâches ».
// Ce fichier ne doit contenir aucun import de `package:flutter/...`.

/// Priorité d'une tâche.
enum Priorite implements Comparable<Priorite> {
  basse('Basse'),
  normale('Normale'),
  haute('Haute');

  const Priorite(this.libelle);

  /// Libellé affichable de la priorité.
  final String libelle;

  @override
  int compareTo(Priorite other) => index.compareTo(other.index);
}

/// Échéance d'une tâche (classe scellée).
sealed class Echeance {
  const Echeance();

  /// Aucune échéance.
  const factory Echeance.aucune() = SansEcheance;

  /// Échéance à une date précise (seuls l'année, le mois et le jour comptent).
  factory Echeance.date(DateTime date) = DatePrecise;

  /// Échéance hebdomadaire avec un jour de la semaine (1 = lundi, ..., 7 = dimanche).
  factory Echeance.hebdomadaire(int jourSemaine) = Hebdomadaire;
}

/// Représente l'absence d'échéance.
final class SansEcheance extends Echeance {
  const SansEcheance();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SansEcheance;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Représente une échéance à une date précise.
final class DatePrecise extends Echeance {
  DatePrecise(DateTime date) : date = DateTime(date.year, date.month, date.day);

  /// Date de l'échéance (normalisée au jour près).
  final DateTime date;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DatePrecise &&
          date.year == other.date.year &&
          date.month == other.date.month &&
          date.day == other.date.day;

  @override
  int get hashCode => Object.hash(date.year, date.month, date.day);
}

/// Représente une échéance récurrente chaque semaine.
final class Hebdomadaire extends Echeance {
  Hebdomadaire(this.jourSemaine) {
    if (jourSemaine < 1 || jourSemaine > 7) {
      throw ArgumentError.value(
        jourSemaine,
        'jourSemaine',
        'Le jour de la semaine doit être compris entre 1 (lundi) et 7 (dimanche).',
      );
    }
  }

  /// Jour de la semaine (1 = lundi, ..., 7 = dimanche).
  final int jourSemaine;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Hebdomadaire && jourSemaine == other.jourSemaine;

  @override
  int get hashCode => jourSemaine.hashCode;
}

/// Sentinelle interne utilisée par `copierAvec` pour distinguer l'absence
/// d'argument de la valeur explicite `null`.
const Object _sentinelle = Object();

/// Représente une tâche strictement immuable.
class Tache {
  Tache({
    required this.id,
    required this.titre,
    this.priorite = Priorite.normale,
    this.echeance = const Echeance.aucune(),
    this.note,
    this.faite = false,
  }) {
    if (id.isEmpty) {
      throw ArgumentError.value(
        id,
        'id',
        'L’identifiant d’une tâche ne peut pas être vide.',
      );
    }
    if (titre.isEmpty) {
      throw ArgumentError.value(
        titre,
        'titre',
        'Le titre d’une tâche ne peut pas être vide.',
      );
    }
  }

  /// Identifiant unique et immuable de la tâche.
  final String id;

  /// Titre descriptif de la tâche.
  final String titre;

  /// Niveau de priorité de la tâche.
  final Priorite priorite;

  /// Échéance associée à la tâche.
  final Echeance echeance;

  /// Note textuelle facultative.
  final String? note;

  /// Indique si la tâche a été accomplie.
  final bool faite;

  /// Retourne une nouvelle instance de [Tache] avec les propriétés modifiées,
  /// sans altérer l'instance existante.
  /// Passer `note: null` permet de supprimer la note existante.
  Tache copierAvec({
    String? titre,
    Priorite? priorite,
    Echeance? echeance,
    bool? faite,
    Object? note = _sentinelle,
  }) {
    return Tache(
      id: id,
      titre: titre ?? this.titre,
      priorite: priorite ?? this.priorite,
      echeance: echeance ?? this.echeance,
      faite: faite ?? this.faite,
      note: identical(note, _sentinelle) ? this.note : (note as String?),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tache &&
          id == other.id &&
          titre == other.titre &&
          priorite == other.priorite &&
          echeance == other.echeance &&
          note == other.note &&
          faite == other.faite;

  @override
  int get hashCode => Object.hash(id, titre, priorite, echeance, note, faite);
}

/// Convertit un code textuel de priorité en valeur d'énumération [Priorite].
///
/// Renvoie `null` pour toute chaîne inconnue ou invalide.
Priorite? prioriteDepuisCode(String code) => switch (code) {
  'low' => Priorite.basse,
  'normal' => Priorite.normale,
  'high' => Priorite.haute,
  _ => null,
};

/// Construit une [Tache] à partir d'un objet JSON représenté par une [Map].
///
/// Lève une [FormatException] si le format, les types ou les valeurs sont invalides.
Tache tacheDepuisJson(Map<String, Object?> json) {
  final idRaw = json['id'];
  if (idRaw is! String || idRaw.isEmpty) {
    throw const FormatException(
      'La clé "id" est obligatoire, doit être une chaîne de caractères et ne peut pas être vide.',
    );
  }

  final titleRaw = json['title'];
  if (titleRaw is! String || titleRaw.isEmpty) {
    throw const FormatException(
      'La clé "title" est obligatoire, doit être une chaîne de caractères et ne peut pas être vide.',
    );
  }

  final priorityRaw = json['priority'];
  if (priorityRaw is! String) {
    throw const FormatException(
      'La clé "priority" est obligatoire et doit être une chaîne de caractères.',
    );
  }
  final priorite = prioriteDepuisCode(priorityRaw);
  if (priorite == null) {
    throw FormatException('Priorité inconnue : "$priorityRaw".');
  }

  final doneRaw = json['done'];
  if (doneRaw is! bool) {
    throw const FormatException(
      'La clé "done" est obligatoire et doit être un booléen.',
    );
  }

  Echeance echeance = const Echeance.aucune();
  if (json.containsKey('due') && json['due'] != null) {
    final dueRaw = json['due'];
    if (dueRaw is! String) {
      throw const FormatException(
        'La clé "due" doit être une chaîne de caractères.',
      );
    }
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(dueRaw);
    if (match == null) {
      throw FormatException(
        'Format de date invalide pour "due" : "$dueRaw" (AAAA-MM-JJ attendu).',
      );
    }
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    if (month < 1 || month > 12) {
      throw FormatException('Mois invalide dans la date "due" : "$dueRaw".');
    }
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      throw FormatException('Jour invalide dans la date "due" : "$dueRaw".');
    }
    echeance = Echeance.date(date);
  }

  String? note;
  if (json.containsKey('note') && json['note'] != null) {
    final noteRaw = json['note'];
    if (noteRaw is! String) {
      throw const FormatException(
        'La clé "note" doit être une chaîne de caractères.',
      );
    }
    note = noteRaw;
  }

  return Tache(
    id: idRaw,
    titre: titleRaw,
    priorite: priorite,
    echeance: echeance,
    note: note,
    faite: doneRaw,
  );
}

String _nomJourSemaine(int jour) => switch (jour) {
  1 => 'lundi',
  2 => 'mardi',
  3 => 'mercredi',
  4 => 'jeudi',
  5 => 'vendredi',
  6 => 'samedi',
  7 => 'dimanche',
  _ => throw ArgumentError('Jour de la semaine invalide : $jour'),
};

/// Produit le libellé textuel associé à une [Echeance].
///
/// L'évaluation est exhaustive sur la classe scellée [Echeance] sans aucun cas par défaut.
String libelleEcheance(Echeance echeance) => switch (echeance) {
  SansEcheance() => 'sans échéance',
  DatePrecise(:final date) => 'pour le ${date.day}/${date.month}',
  Hebdomadaire(:final jourSemaine) => 'chaque ${_nomJourSemaine(jourSemaine)}',
};

/// Indique si une tâche est en retard par rapport à la date de référence [aujourdhui].
///
/// Seules les tâches non faites avec une échéance à date précise antérieure au jour
/// calendaire courant sont considérées en retard.
bool estEnRetard(Tache tache, {required DateTime aujourdhui}) {
  if (tache.faite) return false;
  return switch (tache.echeance) {
    DatePrecise(:final date) => () {
      final dateTache = DateTime(date.year, date.month, date.day);
      final dateRef = DateTime(
        aujourdhui.year,
        aujourdhui.month,
        aujourdhui.day,
      );
      return dateTache.isBefore(dateRef);
    }(),
    SansEcheance() => false,
    Hebdomadaire() => false,
  };
}

/// Calcule le bilan des tâches (nombre de tâches accomplies et nombre total).
({int faites, int total}) bilan(Iterable<Tache> taches) {
  var faites = 0;
  var total = 0;
  for (final t in taches) {
    total++;
    if (t.faite) faites++;
  }
  return (faites: faites, total: total);
}

/// Filtre et trie les tâches non faites selon un seuil de priorité minimale [auMoins].
///
/// Retourne une nouvelle liste triée de la plus urgente (`haute`) à la moins urgente
/// (`basse`), puis par ordre alphabétique croissant du titre.
List<Tache> aFaire(
  Iterable<Tache> taches, {
  Priorite auMoins = Priorite.basse,
}) {
  final resultat = taches
      .where((t) => !t.faite && t.priorite.index >= auMoins.index)
      .toList();

  resultat.sort((a, b) {
    final compPriorite = b.priorite.index.compareTo(a.priorite.index);
    if (compPriorite != 0) return compPriorite;
    return a.titre.compareTo(b.titre);
  });

  return resultat;
}
