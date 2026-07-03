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

class LearningTab extends ConsumerStatefulWidget {
  const LearningTab({super.key, required this.roomId});

  final int roomId;

  @override
  ConsumerState<LearningTab> createState() => _LearningTabState();
}

class _LearningTabState extends ConsumerState<LearningTab> {
  List<LearningItem>? _queue;
  int _index = 0;
  bool _revealed = false;
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  final _stats = <ReviewAnswer, int>{
    ReviewAnswer.nieWiem: 0,
    ReviewAnswer.prawie: 0,
    ReviewAnswer.wiem: 0,
  };

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() {
      _loading = true;
      _error = null;
      _revealed = false;
      _index = 0;
      _queue = null;
      for (final k in _stats.keys) {
        _stats[k] = 0;
      }
    });
    try {
      final items = await ref.read(learningRepositoryProvider).session(widget.roomId);
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
        _stats[a] = (_stats[a] ?? 0) + 1;
        _index++;
        _revealed = false;
        _submitting = false;
      });
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView(message: 'Ładowanie sesji…');
    if (_error != null) {
      return AppErrorView(message: _error!, onRetry: _start);
    }
    final q = _queue;
    if (q == null || q.isEmpty) {
      return EmptyView(
        icon: Icons.check_circle_outline,
        title: 'Sesja pusta',
        message: 'Brak słów do nauki. Wróć jutro po powtórki albo dodaj więcej.',
        action: FilledButton.tonalIcon(
          onPressed: _start,
          icon: const Icon(Icons.refresh),
          label: const Text('Sprawdź ponownie'),
        ),
      );
    }
    if (_index >= q.length) {
      return _Summary(stats: _stats, total: q.length, onRestart: _start);
    }

    final item = q[_index];
    final progress = _index / q.length;

    return SafeArea(
      top: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                Text(
                  '${_index + 1} / ${q.length}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: 2,
                      ),
                ),
                const Spacer(),
                Text('polski → target',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        )),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: progress),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
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

class _Summary extends StatelessWidget {
  const _Summary({required this.stats, required this.total, required this.onRestart});

  final Map<ReviewAnswer, int> stats;
  final int total;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text('Sesja zakończona!', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('Przerobione: $total kart', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatCard(label: 'Nie wiem', value: stats[ReviewAnswer.nieWiem]!, color: Colors.redAccent),
                _StatCard(label: 'Prawie', value: stats[ReviewAnswer.prawie]!, color: Colors.orangeAccent),
                _StatCard(
                    label: 'Wiem',
                    value: stats[ReviewAnswer.wiem]!,
                    color: Colors.greenAccent.shade700),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRestart,
              icon: const Icon(Icons.refresh),
              label: const Text('Kolejna sesja'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text('$value', style: theme.textTheme.headlineMedium?.copyWith(color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
      ],
    );
  }
}
