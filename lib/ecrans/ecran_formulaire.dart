import 'package:flutter/material.dart';
import 'package:mes_taches/modele/taches.dart';

int _compteurId = 0;

/// Écran de création ou de modification d'une tâche.
class EcranFormulaire extends StatefulWidget {
  const EcranFormulaire({super.key, this.tacheExistante, this.dateReference});

  /// La tâche existante en cas de modification, ou `null` en création.
  final Tache? tacheExistante;

  /// Date de référence pour valider l'antériorité (défaut : maintenant).
  final DateTime? dateReference;

  @override
  State<EcranFormulaire> createState() => _EcranFormulaireState();
}

class _EcranFormulaireState extends State<EcranFormulaire> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titreController;
  late final TextEditingController _noteController;

  late Priorite _priorite;
  DateTime? _dateChoisie;
  int? _jourHebdoChoisi;

  // Type d'échéance sélectionné : 0 = aucune, 1 = date précise, 2 = hebdomadaire
  int _typeEcheance = 0;

  DateTime get _aujourdhuiRef {
    final now = widget.dateReference ?? DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    final t = widget.tacheExistante;
    _titreController = TextEditingController(text: t?.titre ?? '');
    _noteController = TextEditingController(text: t?.note ?? '');
    _priorite = t?.priorite ?? Priorite.normale;
    final echeanceInitiale = t?.echeance ?? const Echeance.aucune();

    switch (echeanceInitiale) {
      case SansEcheance():
        _typeEcheance = 0;
      case DatePrecise(:final date):
        _typeEcheance = 1;
        _dateChoisie = date;
      case Hebdomadaire(:final jourSemaine):
        _typeEcheance = 2;
        _jourHebdoChoisi = jourSemaine;
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _choisirDate() async {
    final initiale =
        _dateChoisie != null && !_dateChoisie!.isBefore(_aujourdhuiRef)
        ? _dateChoisie!
        : _aujourdhuiRef;

    final date = await showDatePicker(
      context: context,
      initialDate: initiale,
      firstDate: _aujourdhuiRef,
      lastDate: DateTime(2040, 12, 31),
    );

    if (date != null && mounted) {
      setState(() {
        _dateChoisie = date;
        _typeEcheance = 1;
      });
    }
  }

  void _enregistrer() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final titreNettoye = _titreController.text.trim();
    final noteBrute = _noteController.text.trim();
    final noteNettoyee = noteBrute.isEmpty ? null : noteBrute;

    final Echeance echeanceFinale = switch (_typeEcheance) {
      1 when _dateChoisie != null => Echeance.date(_dateChoisie!),
      2 when _jourHebdoChoisi != null => Echeance.hebdomadaire(
        _jourHebdoChoisi!,
      ),
      _ => const Echeance.aucune(),
    };

    final tExistante = widget.tacheExistante;
    final Tache resultat;
    if (tExistante != null) {
      resultat = tExistante.copierAvec(
        titre: titreNettoye,
        priorite: _priorite,
        echeance: echeanceFinale,
        note: noteNettoyee,
      );
    } else {
      final nouveauId =
          't_${DateTime.now().microsecondsSinceEpoch}_${_compteurId++}';
      resultat = Tache(
        id: nouveauId,
        titre: titreNettoye,
        priorite: _priorite,
        echeance: echeanceFinale,
        note: noteNettoyee,
        faite: false,
      );
    }

    Navigator.of(context).pop(resultat);
  }

  @override
  Widget build(BuildContext context) {
    final estModification = widget.tacheExistante != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(estModification ? 'Modifier la tâche' : 'Nouvelle tâche'),
        actions: [
          TextButton(onPressed: _enregistrer, child: const Text('Enregistrer')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Champ Titre
              TextFormField(
                controller: _titreController,
                decoration: const InputDecoration(
                  labelText: 'Titre *',
                  hintText: 'Que devez-vous accomplir ?',
                  border: OutlineInputBorder(),
                ),
                autofocus: !estModification,
                validator: (valeur) {
                  final texte = (valeur ?? '').trim();
                  if (texte.isEmpty) {
                    return 'Le titre est obligatoire.';
                  }
                  if (texte.length > 60) {
                    return 'Le titre ne doit pas dépasser 60 caractères.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Champ Priorité
              Text('Priorité', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<Priorite>(
                segments: Priorite.values
                    .map(
                      (p) => ButtonSegment<Priorite>(
                        value: p,
                        label: Text(p.libelle),
                      ),
                    )
                    .toList(),
                selected: {_priorite},
                onSelectionChanged: (nouveauSet) {
                  setState(() => _priorite = nouveauSet.first);
                },
              ),
              const SizedBox(height: 24),

              // Champ Échéance
              Text('Échéance', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              FormField<DateTime?>(
                initialValue: _dateChoisie,
                validator: (val) {
                  if (_typeEcheance == 1) {
                    if (_dateChoisie == null) {
                      return 'Veuillez choisir une date.';
                    }
                    final dateRef = _aujourdhuiRef;
                    final dateChoisieCal = DateTime(
                      _dateChoisie!.year,
                      _dateChoisie!.month,
                      _dateChoisie!.day,
                    );
                    if (dateChoisieCal.isBefore(dateRef)) {
                      return 'La date ne peut pas être passée.';
                    }
                  }
                  return null;
                },
                builder: (field) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text('Aucune'),
                            selected: _typeEcheance == 0,
                            onSelected: (sel) {
                              if (sel) {
                                setState(() {
                                  _typeEcheance = 0;
                                });
                                field.didChange(null);
                              }
                            },
                          ),
                          ChoiceChip(
                            label: Text(
                              _dateChoisie != null
                                  ? 'Le ${_dateChoisie!.day}/${_dateChoisie!.month}/${_dateChoisie!.year}'
                                  : 'Choisir une date',
                            ),
                            selected: _typeEcheance == 1,
                            onSelected: (sel) {
                              if (sel) {
                                _choisirDate().then((_) {
                                  if (mounted) {
                                    field.didChange(_dateChoisie);
                                  }
                                });
                              }
                            },
                          ),
                          if (_typeEcheance == 1) ...[
                            IconButton(
                              icon: const Icon(Icons.edit_calendar),
                              tooltip: 'Changer la date',
                              onPressed: () {
                                _choisirDate().then((_) {
                                  if (mounted) {
                                    field.didChange(_dateChoisie);
                                  }
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.clear),
                              tooltip: 'Supprimer l’échéance',
                              onPressed: () {
                                setState(() {
                                  _typeEcheance = 0;
                                  _dateChoisie = null;
                                });
                                field.didChange(null);
                              },
                            ),
                          ],
                        ],
                      ),
                      if (field.hasError) ...[
                        const SizedBox(height: 6),
                        Text(
                          field.errorText!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Champ Note
              TextFormField(
                controller: _noteController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Note (facultative)',
                  hintText: 'Détails, liens ou mémos...',
                  border: OutlineInputBorder(),
                ),
                validator: (valeur) {
                  final texte = (valeur ?? '').trim();
                  if (texte.length > 200) {
                    return 'La note ne doit pas dépasser 200 caractères.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Bouton Enregistrer en bas
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _enregistrer,
                  icon: const Icon(Icons.save),
                  label: Text(
                    estModification ? 'Mettre à jour' : 'Créer la tâche',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
