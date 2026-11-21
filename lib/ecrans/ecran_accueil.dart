import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mes_taches/donnees/exemples.dart';
import 'package:mes_taches/ecrans/ecran_detail.dart';
import 'package:mes_taches/ecrans/ecran_formulaire.dart';
import 'package:mes_taches/modele/taches.dart';
import 'package:mes_taches/widgets/detail_tache_contenu.dart';
import 'package:mes_taches/widgets/tuile_tache.dart';

/// Filtres disponibles pour la liste des tâches.
enum FiltreTaches {
  toutes('Toutes'),
  aFaire('À faire'),
  faites('Faites');

  const FiltreTaches(this.libelle);
  final String libelle;
}

/// Critères de tri disponibles.
enum TriTaches {
  defaut('Ordre par défaut'),
  priorite('Priorité'),
  echeance('Échéance'),
  titre('Titre');

  const TriTaches(this.libelle);
  final String libelle;
}

/// Écran principal de l'application « Mes tâches ».
class EcranAccueil extends StatefulWidget {
  const EcranAccueil({super.key, this.tachesInitiales, this.aujourdhui});

  /// Tâches injectées (utile pour les tests), sinon chargées depuis les exemples.
  final List<Tache>? tachesInitiales;

  /// Date de référence injectée (défaut : maintenant).
  final DateTime? aujourdhui;

  @override
  State<EcranAccueil> createState() => _EcranAccueilState();
}

class _EcranAccueilState extends State<EcranAccueil> {
  late List<Tache> _taches;
  FiltreTaches _filtreActif = FiltreTaches.toutes;
  TriTaches _triActif = TriTaches.defaut;
  String? _idTacheSelectionnee;

  DateTime get _aujourdhui => widget.aujourdhui ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.tachesInitiales != null) {
      _taches = List<Tache>.from(widget.tachesInitiales!);
    } else {
      final decodage = jsonDecode(tachesExempleJson) as List<dynamic>;
      _taches = decodage
          .map((e) => tacheDepuisJson(e as Map<String, Object?>))
          .toList();
    }
  }

  void _basculerTache(String id) {
    setState(() {
      final index = _taches.indexWhere((t) => t.id == id);
      if (index != -1) {
        final t = _taches[index];
        _taches[index] = t.copierAvec(faite: !t.faite);
      }
    });
  }

  void _ajouterTache(Tache nouvelleTache) {
    setState(() {
      _taches.add(nouvelleTache);
      _idTacheSelectionnee = nouvelleTache.id;
    });
  }

  void _modifierTache(Tache tacheModifiee) {
    setState(() {
      final index = _taches.indexWhere((t) => t.id == tacheModifiee.id);
      if (index != -1) {
        _taches[index] = tacheModifiee;
      }
    });
  }

  void _supprimerTache(String id) {
    final index = _taches.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final supprimee = _taches[index];
    setState(() {
      _taches.removeAt(index);
      if (_idTacheSelectionnee == id) {
        _idTacheSelectionnee = null;
      }
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tâche « ${supprimee.titre} » supprimée'),
        action: SnackBarAction(
          label: 'Annuler',
          onPressed: () {
            if (!mounted) return;
            setState(() {
              final position = index.clamp(0, _taches.length);
              _taches.insert(position, supprimee);
              _idTacheSelectionnee = supprimee.id;
            });
          },
        ),
      ),
    );
  }

  Future<void> _ouvrirFormulaireCreation() async {
    final nouvelleTache = await Navigator.of(context).push<Tache>(
      MaterialPageRoute(
        builder: (_) => EcranFormulaire(dateReference: _aujourdhui),
      ),
    );

    if (nouvelleTache != null && mounted) {
      _ajouterTache(nouvelleTache);
    }
  }

  Future<void> _ouvrirDetailMobile(Tache tache) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EcranDetail(
          tache: tache,
          aujourdhui: _aujourdhui,
          onBasculerFait: () => _basculerTache(tache.id),
          onModifier: _modifierTache,
          onSupprimer: _supprimerTache,
        ),
      ),
    );
  }

  Future<void> _ouvrirModification(Tache tache) async {
    final modifiee = await Navigator.of(context).push<Tache>(
      MaterialPageRoute(
        builder: (_) =>
            EcranFormulaire(tacheExistante: tache, dateReference: _aujourdhui),
      ),
    );

    if (modifiee != null && mounted) {
      _modifierTache(modifiee);
    }
  }

  List<Tache> get _tachesFiltrees {
    return switch (_filtreActif) {
      FiltreTaches.toutes => List<Tache>.from(_taches),
      FiltreTaches.aFaire => _taches.where((t) => !t.faite).toList(),
      FiltreTaches.faites => _taches.where((t) => t.faite).toList(),
    };
  }

  String get _messageListeVide => switch (_filtreActif) {
    FiltreTaches.toutes => 'Aucune tâche',
    FiltreTaches.aFaire => 'Aucune tâche à faire',
    FiltreTaches.faites => 'Aucune tâche faite',
  };

  Widget _construireListe(bool estGrandEcran) {
    final base = _tachesFiltrees;

    if (base.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.task_alt,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                _messageListeVide,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.outline),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_triActif == TriTaches.echeance) {
      return _construireListeGroupeeParEcheance(base, estGrandEcran);
    }

    // Autres tris
    final listeTriee = List<Tache>.from(base);
    switch (_triActif) {
      case TriTaches.priorite:
        listeTriee.sort((a, b) {
          final comp = b.priorite.index.compareTo(a.priorite.index);
          return comp != 0 ? comp : a.titre.compareTo(b.titre);
        });
      case TriTaches.titre:
        listeTriee.sort((a, b) => a.titre.compareTo(b.titre));
      case TriTaches.defaut:
      case TriTaches.echeance:
        break;
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: listeTriee.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final tache = listeTriee[index];
        return _construireTuileDismissible(tache, estGrandEcran);
      },
    );
  }

  Widget _construireListeGroupeeParEcheance(
    List<Tache> items,
    bool estGrandEcran,
  ) {
    final enRetard = <Tache>[];
    final datees = <Tache>[];
    final hebdo = <Tache>[];
    final sansEcheance = <Tache>[];

    for (final t in items) {
      if (estEnRetard(t, aujourdhui: _aujourdhui)) {
        enRetard.add(t);
      } else {
        switch (t.echeance) {
          case DatePrecise():
            datees.add(t);
          case Hebdomadaire():
            hebdo.add(t);
          case SansEcheance():
            sansEcheance.add(t);
        }
      }
    }

    // Tri interne des groupes
    enRetard.sort((a, b) {
      final da = (a.echeance as DatePrecise).date;
      final db = (b.echeance as DatePrecise).date;
      return da.compareTo(db);
    });

    datees.sort((a, b) {
      final da = (a.echeance as DatePrecise).date;
      final db = (b.echeance as DatePrecise).date;
      return da.compareTo(db);
    });

    hebdo.sort((a, b) {
      final ja = (a.echeance as Hebdomadaire).jourSemaine;
      final jb = (b.echeance as Hebdomadaire).jourSemaine;
      return ja.compareTo(jb);
    });

    final sections = <({String titre, List<Tache> taches, Color? couleur})>[
      (
        titre: 'En retard',
        taches: enRetard,
        couleur: Theme.of(context).colorScheme.error,
      ),
      (titre: 'Datées', taches: datees, couleur: null),
      (titre: 'Hebdomadaires', taches: hebdo, couleur: null),
      (titre: 'Sans échéance', taches: sansEcheance, couleur: null),
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: [
        for (final section in sections)
          if (section.taches.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.surfaceContainerHighest
                  .withAlpha(60),
              child: Text(
                section.titre,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color:
                      section.couleur ??
                      Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            for (var i = 0; i < section.taches.length; i++) ...[
              _construireTuileDismissible(section.taches[i], estGrandEcran),
              if (i < section.taches.length - 1) const Divider(height: 1),
            ],
          ],
      ],
    );
  }

  Widget _construireTuileDismissible(Tache tache, bool estGrandEcran) {
    return Dismissible(
      key: ValueKey(tache.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _supprimerTache(tache.id),
      child: TuileTache(
        tache: tache,
        aujourdhui: _aujourdhui,
        estSelectionnee: estGrandEcran && _idTacheSelectionnee == tache.id,
        onBasculer: (_) => _basculerTache(tache.id),
        onOuvrir: () {
          if (estGrandEcran) {
            setState(() => _idTacheSelectionnee = tache.id);
          } else {
            _ouvrirDetailMobile(tache);
          }
        },
      ),
    );
  }

  Widget _construireEnTeteFixe() {
    final b = bilan(_taches);
    final nbAFaire = b.total - b.faites;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withAlpha(80),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '$nbAFaire à faire',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${b.faites}/${b.total} terminées',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.outline),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<FiltreTaches>(
              showSelectedIcon: false,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
              segments: FiltreTaches.values
                  .map(
                    (f) => ButtonSegment<FiltreTaches>(
                      value: f,
                      label: Text(f.libelle, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              selected: {_filtreActif},
              onSelectionChanged: (nouveauSet) {
                setState(() => _filtreActif = nouveauSet.first);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirePanneauDetail(Tache? selectionnee) {
    if (selectionnee == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.touch_app_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Sélectionnez une tâche pour voir ses détails',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.outline),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return DetailTacheContenu(
      tache: selectionnee,
      aujourdhui: _aujourdhui,
      onBasculerFait: () => _basculerTache(selectionnee.id),
      onModifier: () => _ouvrirModification(selectionnee),
      onSupprimer: () => _supprimerTache(selectionnee.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final estGrandEcran = constraints.maxWidth >= 840;

        Tache? tacheSelectionnee;
        if (_idTacheSelectionnee != null) {
          final index = _taches.indexWhere((t) => t.id == _idTacheSelectionnee);
          if (index != -1) {
            tacheSelectionnee = _taches[index];
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mes tâches'),
            actions: [
              PopupMenuButton<TriTaches>(
                icon: const Icon(Icons.sort),
                tooltip: 'Trier la liste',
                initialValue: _triActif,
                onSelected: (tri) => setState(() => _triActif = tri),
                itemBuilder: (context) => TriTaches.values
                    .map(
                      (t) => PopupMenuItem<TriTaches>(
                        value: t,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              child: _triActif == t
                                  ? const Icon(Icons.check, size: 18)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                t.libelle,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          body: estGrandEcran
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 380,
                      child: Column(
                        children: [
                          _construireEnTeteFixe(),
                          Expanded(child: _construireListe(true)),
                        ],
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: _construirePanneauDetail(tacheSelectionnee),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _construireEnTeteFixe(),
                    Expanded(child: _construireListe(false)),
                  ],
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _ouvrirFormulaireCreation,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter'),
          ),
        );
      },
    );
  }
}
