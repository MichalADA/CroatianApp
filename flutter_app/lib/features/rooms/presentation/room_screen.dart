import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Placeholder — pełna implementacja w Kroku 5.
class RoomScreen extends ConsumerWidget {
  const RoomScreen({super.key, required this.roomId});

  final int roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Pokój #$roomId')),
      body: const Center(child: Text('Room screen — krok 5.')),
    );
  }
}
