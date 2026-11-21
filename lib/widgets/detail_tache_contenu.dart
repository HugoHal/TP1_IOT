import 'package:flutter/material.dart';
import 'package:mes_taches/modele/taches.dart';

/// Contenu visuel des détails d'une tâche.
///
/// Ce widget est réutilisable aussi bien dans l'écran dédié que dans la vue
/// adaptative Master-Detail (écrans larges).
class DetailTacheContenu extends StatelessWidget {
  const DetailTacheContenu({
    required this.tache,
    required this.aujourdhui,
    required this.onBasculerFait,
    required this.onModifier,
    required this.onSupprimer,
    super.key,
  });

  /// La tâche à afficher.
  final Tache tache;

  /// Date de référence pour le calcul du retard.
  final DateTime aujourdhui;

  /// Action pour changer l'état fait / à faire.
  final VoidCallback onBasculerFait;

  /// Action pour modifier la tâche.
  final VoidCallback onModifier;

  /// Action pour supprimer la tâche.
  final VoidCallback onSupprimer;

  Color _couleurPriorite(BuildContext context, Priorite priorite) {
    return switch (priorite) {
      Priorite.haute => Theme.of(context).colorScheme.error,
      Priorite.normale => Theme.of(context).colorScheme.primary,
      Priorite.basse => Theme.of(context).colorScheme.outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enRetard = estEnRetard(tache, aujourdhui: aujourdhui);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 88),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badges d'état et de priorité
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: Icon(
                      tache.faite
                          ? Icons.check_circle_outline
                          : Icons.pending_outlined,
                      color: tache.faite ? Colors.green : Colors.orange,
                      size: 18,
                    ),
                    label: Text(
                      tache.faite ? 'Faite' : 'À faire',
                      style: TextStyle(
                        color: tache.faite
                            ? Colors.green.shade800
                            : Colors.orange.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor:
                        (tache.faite ? Colors.green : Colors.orange).withAlpha(
                          30,
                        ),
                  ),
                  Chip(
                    label: Text(
                      'Priorité ${tache.priorite.libelle.toLowerCase()}',
                      style: TextStyle(
                        color: _couleurPriorite(context, tache.priorite),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: _couleurPriorite(
                      context,
                      tache.priorite,
                    ).withAlpha(30),
                  ),
                  if (enRetard)
                    Chip(
                      avatar: const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 18,
                      ),
                      label: const Text(
                        'En retard',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: Colors.red.withAlpha(30),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Titre complet
              Text(
                tache.titre,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  decoration: tache.faite
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
              const SizedBox(height: 20),

              // Échéance
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(90),
                child: ListTile(
                  leading: Icon(
                    Icons.calendar_today_outlined,
                    color: enRetard
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                  title: const Text('Échéance'),
                  subtitle: Text(
                    libelleEcheance(tache.echeance),
                    style: TextStyle(
                      color: enRetard
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: enRetard
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Note
              SizedBox(
                width: double.infinity,
                child: Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(
                    90,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.notes_outlined,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Note',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          (tache.note != null && tache.note!.trim().isNotEmpty)
                              ? tache.note!
                              : 'aucune note',
                          style: TextStyle(
                            fontStyle:
                                (tache.note != null &&
                                    tache.note!.trim().isNotEmpty)
                                ? FontStyle.normal
                                : FontStyle.italic,
                            color:
                                (tache.note != null &&
                                    tache.note!.trim().isNotEmpty)
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Actions principales
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: onBasculerFait,
                      icon: Icon(
                        tache.faite
                            ? Icons.radio_button_unchecked
                            : Icons.check_circle_outline,
                      ),
                      label: Text(
                        tache.faite ? 'Marquer à faire' : 'Marquer comme faite',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onModifier,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text(
                              'Modifier',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onSupprimer,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text(
                              'Supprimer',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
