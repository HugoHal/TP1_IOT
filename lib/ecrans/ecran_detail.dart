import 'package:flutter/material.dart';
import 'package:mes_taches/ecrans/ecran_formulaire.dart';
import 'package:mes_taches/modele/taches.dart';
import 'package:mes_taches/widgets/detail_tache_contenu.dart';

/// Écran complet de consultation et d'action sur une tâche (utilisé en vue mobile).
class EcranDetail extends StatefulWidget {
  const EcranDetail({
    required this.tache,
    required this.aujourdhui,
    required this.onBasculerFait,
    required this.onModifier,
    required this.onSupprimer,
    super.key,
  });

  /// La tâche affichée.
  final Tache tache;

  /// Date de référence pour déterminer le retard.
  final DateTime aujourdhui;

  /// Rappelé pour basculer l'état fait / à faire.
  final void Function(Tache tache) onBasculerFait;

  /// Rappelé pour enregistrer une tâche modifiée.
  final void Function(Tache tache) onModifier;

  /// Rappelé pour supprimer la tâche.
  final void Function(String id) onSupprimer;

  @override
  State<EcranDetail> createState() => _EcranDetailState();
}

class _EcranDetailState extends State<EcranDetail> {
  late Tache _tacheCourante;

  @override
  void initState() {
    super.initState();
    _tacheCourante = widget.tache;
  }

  Future<void> _ouvrirModification() async {
    final modifiee = await Navigator.of(context).push<Tache>(
      MaterialPageRoute(
        builder: (_) => EcranFormulaire(
          tacheExistante: _tacheCourante,
          dateReference: widget.aujourdhui,
        ),
      ),
    );

    if (modifiee != null && mounted) {
      setState(() => _tacheCourante = modifiee);
      widget.onModifier(modifiee);
    }
  }

  void _basculerEtFermer() {
    final nouvelleTache = _tacheCourante.copierAvec(
      faite: !_tacheCourante.faite,
    );
    widget.onBasculerFait(nouvelleTache);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _supprimerEtFermer() {
    widget.onSupprimer(_tacheCourante.id);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail de la tâche'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Modifier',
            onPressed: _ouvrirModification,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Supprimer',
            onPressed: _supprimerEtFermer,
          ),
        ],
      ),
      body: DetailTacheContenu(
        tache: _tacheCourante,
        aujourdhui: widget.aujourdhui,
        onBasculerFait: _basculerEtFermer,
        onModifier: _ouvrirModification,
        onSupprimer: _supprimerEtFermer,
      ),
    );
  }
}
