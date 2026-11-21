import 'package:flutter/material.dart';
import 'package:mes_taches/modele/taches.dart';

/// Tuile d'affichage d'une tâche dans une liste.
///
/// Ce widget est un [StatelessWidget] pur sans état interne.
class TuileTache extends StatelessWidget {
  const TuileTache({
    required this.tache,
    required this.aujourdhui,
    required this.onBasculer,
    required this.onOuvrir,
    super.key,
    this.estSelectionnee = false,
  });

  /// Tâche représentée par la tuile.
  final Tache tache;

  /// Date de référence pour déterminer le retard.
  final DateTime aujourdhui;

  /// Rappelé lorsque la case à cocher est activée ou désactivée.
  final ValueChanged<bool?> onBasculer;

  /// Rappelé lorsque l'utilisateur touche la tuile en dehors de la case.
  final VoidCallback onOuvrir;

  /// Indique si cette tuile est actuellement sélectionnée (mode grand écran).
  final bool estSelectionnee;

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
    final couleurSousTitre = enRetard
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;

    return Material(
      color: estSelectionnee
          ? theme.colorScheme.primaryContainer.withAlpha(80)
          : Colors.transparent,
      child: ListTile(
        onTap: onOuvrir,
        selected: estSelectionnee,
        leading: Checkbox(value: tache.faite, onChanged: onBasculer),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _couleurPriorite(context, tache.priorite).withAlpha(35),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _couleurPriorite(context, tache.priorite),
                  width: 1,
                ),
              ),
              child: Text(
                tache.priorite.libelle,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _couleurPriorite(context, tache.priorite),
                ),
              ),
            ),
            Expanded(
              child: Text(
                tache.titre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  decoration: tache.faite
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  color: tache.faite
                      ? theme.colorScheme.outline
                      : theme.colorScheme.onSurface,
                  fontWeight: tache.faite ? FontWeight.normal : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            if (enRetard) ...[
              Icon(
                Icons.warning_amber_rounded,
                size: 15,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                libelleEcheance(tache.echeance),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: couleurSousTitre,
                  fontWeight: enRetard ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
      ),
    );
  }
}
