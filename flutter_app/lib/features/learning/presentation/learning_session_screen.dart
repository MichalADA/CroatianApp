import 'package:flutter/material.dart';

/// Placeholder — pełna implementacja w Kroku 6.
class LearningSessionScreen extends StatelessWidget {
  const LearningSessionScreen({super.key, required this.roomId});

  final int roomId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sesja nauki')),
      body: Center(child: Text('Learning session dla pokoju #$roomId — krok 6.')),
    );
  }
}
