import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../data/learning_repository.dart';
import '../domain/entities/learning_item.dart';
import 'widgets/answer_buttons.dart';
import 'widgets/flashcard_view.dart';

class ReviewTab extends ConsumerStatefulWidget {
  const ReviewTab({super.key, required this.roomId});

  final int roomId;

  @override
  ConsumerState<ReviewTab> createState() => _ReviewTabState();
}

class _ReviewTabState extends ConsumerState<ReviewTab> {
  List<LearningItem>? _queue;
  int _index = 0;
  bool _revealed = false;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _revealed = false;
      _index = 0;
    });
    try {
      final items = await ref.read(learningRepositoryProvider).reviews(widget.roomId);
      if (!mounted) return;
      setState(() {
        _queue = items;
        _loading = false;
      });
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _answer(ReviewAnswer a) async {
    final q = _queue;
    if (q == null || _index >= q.length) return;
    setState(() => _submitting = true);
    try {
      await ref.read(learningRepositoryProvider).submitAnswer(
            item: q[_index],
            roomId: widget.roomId,
            answer: a,
          );
      if (!mounted) return;
      setState(() {
        _index++;
        _revealed = false;
        _submitting = false;
      });
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView(message: 'Ładowanie powtórek…');
    if (_error != null) return AppErrorView(message: _error!, onRetry: _load);

    final q = _queue;
    if (q == null || q.isEmpty) {
      return EmptyView(
        icon: Icons.sentiment_very_satisfied,
        title: 'Nic do powtórki',
        message: 'Brak zaległych słów. Świetna robota!',
        action: FilledButton.tonalIcon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: const Text('Odśwież'),
        ),
      );
    }

    if (_index >= q.length) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text('Powtórki zakończone!', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Wszystkie ${q.length} kart przerobione'),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Sprawdź ponownie'),
            ),
          ],
        ),
      );
    }

    final item = q[_index];
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Text('Powtórka ${_index + 1} / ${q.length}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary, letterSpacing: 1.5)),
                const Spacer(),
                IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FlashcardView(
                item: item,
                revealed: _revealed,
                onReveal: () => setState(() => _revealed = true),
              ),
            ),
          ),
          if (_revealed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: AnswerButtons(onAnswer: _answer, disabled: _submitting),
            ),
        ],
      ),
    );
  }
}
