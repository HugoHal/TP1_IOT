import 'package:flutter/material.dart';
import 'package:mes_taches/ecrans/ecran_accueil.dart';
import 'package:mes_taches/modele/taches.dart';

void main() => runApp(const MesTachesApp());

/// Application principale « Mes tâches ».
class MesTachesApp extends StatelessWidget {
  const MesTachesApp({super.key, this.tachesInitiales, this.aujourdhui});

  /// Tâches initiales (facultatif, utilisé principalement pour les tests).
  final List<Tache>? tachesInitiales;

  /// Date de référence pour la gestion des retards (facultatif).
  final DateTime? aujourdhui;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mes tâches',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: EcranAccueil(
        tachesInitiales: tachesInitiales,
        aujourdhui: aujourdhui,
      ),
    );
  }
}
