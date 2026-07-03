import 'package:flutter/material.dart';

/// Placeholder — pełna implementacja w Kroku 6.
class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key, required this.roomId});

  final int roomId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Powtórki')),
      body: Center(child: Text('Review dla pokoju #$roomId — krok 6.')),
    );
  }
}
