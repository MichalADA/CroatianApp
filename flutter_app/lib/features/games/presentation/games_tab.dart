import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../rooms/data/words_repository.dart';
import '../../rooms/domain/entities/word.dart';

/// Placeholder-ready implementacja gier — MVP: Dopasowanie i Rozsypanka.
/// Wisielec dodamy w kolejnej iteracji (opcjonalne).
class GamesTab extends ConsumerStatefulWidget {
  const GamesTab({super.key, required this.roomId});

  final int roomId;

  @override
  ConsumerState<GamesTab> createState() => _GamesTabState();
}

class _GamesTabState extends ConsumerState<GamesTab> {
  _GameType _selected = _GameType.matching;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(wordsProvider((roomId: widget.roomId, q: null, category: null)));
    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Wrap(
              spacing: 8,
              children: _GameType.values
                  .map((t) => ChoiceChip(
                        label: Text(t.label),
                        selected: _selected == t,
                        onSelected: (_) => setState(() => _selected = t),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const LoadingView(),
              error: (e, _) => AppErrorView(
                message: e is Failure ? e.message : e.toString(),
                onRetry: () => ref.invalidate(wordsProvider),
              ),
              data: (words) {
                if (words.length < 4) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Za mało słów w pokoju do rozegrania gry (min. 4).',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return switch (_selected) {
                  _GameType.matching => MatchingGame(words: words),
                  _GameType.scramble => ScrambleGame(words: words),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}

enum _GameType {
  matching('Dopasowanie'),
  scramble('Rozsypanka');

  const _GameType(this.label);
  final String label;
}

/// Gra dopasowanie — dwie kolumny: lewa polska, prawa target — klikasz parę.
class MatchingGame extends StatefulWidget {
  const MatchingGame({super.key, required this.words, this.pairs = 6});

  final List<Word> words;
  final int pairs;

  @override
  State<MatchingGame> createState() => _MatchingGameState();
}

class _MatchingGameState extends State<MatchingGame> {
  late List<Word> _round;
  late List<Word> _leftShuffled;
  late List<Word> _rightShuffled;
  Word? _selectedLeft;
  Word? _selectedRight;
  final _matched = <int>{};

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    final rng = Random();
    final shuffled = [...widget.words]..shuffle(rng);
    _round = shuffled.take(min(widget.pairs, widget.words.length)).toList();
    _leftShuffled = [..._round]..shuffle(rng);
    _rightShuffled = [..._round]..shuffle(rng);
    _selectedLeft = null;
    _selectedRight = null;
    _matched.clear();
    setState(() {});
  }

  void _pick({Word? left, Word? right}) {
    setState(() {
      if (left != null) _selectedLeft = left;
      if (right != null) _selectedRight = right;
    });
    if (_selectedLeft != null && _selectedRight != null) {
      final match = _selectedLeft!.id == _selectedRight!.id;
      Future.delayed(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        setState(() {
          if (match) _matched.add(_selectedLeft!.id);
          _selectedLeft = null;
          _selectedRight = null;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final complete = _matched.length == _round.length;
    if (complete) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎯', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text('Wszystkie ${_round.length} par dopasowane!',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _newRound,
              icon: const Icon(Icons.replay),
              label: const Text('Nowa runda'),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: _leftShuffled
                  .map((w) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _MatchCard(
                          text: w.polish,
                          selected: _selectedLeft == w,
                          matched: _matched.contains(w.id),
                          onTap: () => _pick(left: w),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: _rightShuffled
                  .map((w) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _MatchCard(
                          text: w.targetWord,
                          selected: _selectedRight == w,
                          matched: _matched.contains(w.id),
                          onTap: () => _pick(right: w),
                          isTarget: true,
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.text,
    required this.selected,
    required this.matched,
    required this.onTap,
    this.isTarget = false,
  });

  final String text;
  final bool selected;
  final bool matched;
  final VoidCallback onTap;
  final bool isTarget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color? bg;
    Color? border;
    if (matched) {
      bg = Colors.green.withValues(alpha: 0.2);
      border = Colors.green;
    } else if (selected) {
      bg = theme.colorScheme.primary.withValues(alpha: 0.15);
      border = theme.colorScheme.primary;
    }
    return InkWell(
      onTap: matched ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: bg ?? theme.colorScheme.surface,
          border: Border.all(color: border ?? theme.colorScheme.outline.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isTarget ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Gra rozsypanka — user układa target z pomieszanych liter.
class ScrambleGame extends StatefulWidget {
  const ScrambleGame({super.key, required this.words});

  final List<Word> words;

  @override
  State<ScrambleGame> createState() => _ScrambleGameState();
}

class _ScrambleGameState extends State<ScrambleGame> {
  late Word _current;
  late List<String> _letters;
  final _picked = <int>[];

  @override
  void initState() {
    super.initState();
    _pick();
  }

  void _pick() {
    _current = (widget.words.toList()..shuffle()).first;
    _letters = _current.targetWord.split('')..shuffle();
    _picked.clear();
    setState(() {});
  }

  String get _picked_text => _picked.map((i) => _letters[i]).join();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final correct = _picked_text == _current.targetWord;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text('Ułóż słowo:', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Text(_current.polish,
              style: theme.textTheme.headlineMedium?.copyWith(fontSize: 30)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border.all(
                color: correct
                    ? Colors.green
                    : theme.colorScheme.outline.withValues(alpha: 0.5),
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _picked_text.isEmpty ? ' ' : _picked_text,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: correct ? Colors.green : theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _letters.length; i++)
                _LetterChip(
                  letter: _letters[i],
                  used: _picked.contains(i),
                  onTap: () => setState(() {
                    if (!_picked.contains(i)) _picked.add(i);
                  }),
                ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(_picked.clear),
                  icon: const Icon(Icons.clear),
                  label: const Text('Wyczyść'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _pick,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Następne'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LetterChip extends StatelessWidget {
  const _LetterChip({required this.letter, required this.used, required this.onTap});

  final String letter;
  final bool used;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: used ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedOpacity(
        opacity: used ? 0.25 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            letter.toUpperCase(),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ),
    );
  }
}
