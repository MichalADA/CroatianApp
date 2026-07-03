import 'package:flutter/material.dart';

import 'review_tab.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key, required this.roomId});

  final int roomId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Powtórki')),
      body: ReviewTab(roomId: roomId),
    );
  }
}
