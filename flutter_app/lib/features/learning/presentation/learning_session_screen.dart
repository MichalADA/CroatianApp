import 'package:flutter/material.dart';

import 'learning_tab.dart';

/// Standalone route (deep link) — właściwa treść żyje w [LearningTab],
/// ekran pokoju osadza tab w bottom nav.
class LearningSessionScreen extends StatelessWidget {
  const LearningSessionScreen({super.key, required this.roomId});

  final int roomId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sesja nauki')),
      body: LearningTab(roomId: roomId),
    );
  }
}
