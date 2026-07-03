import 'package:flutter/material.dart';

import '../../domain/entities/learning_item.dart';

/// Prezentuje pojedynczą kartę flashcard — polski front, target po odsłonięciu.
class FlashcardView extends StatelessWidget {
  const FlashcardView({
    super.key,
    required this.item,
    required this.revealed,
    required this.onReveal,
  });

  final LearningItem item;
  final bool revealed;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.isVerb ? '🔤 Czasownik' : '📖 Słowo',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                letterSpacing: 2,
                fontSize: 11,
              ),
            ),
            if (item.category != null && item.category!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(item.category!,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              item.polish,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: 32,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 24),
            if (revealed) ...[
              Text(
                item.targetText,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontSize: 28,
                ),
              ),
              if (item.hasConjugations) ...[
                const SizedBox(height: 20),
                _ConjTable(item: item),
              ],
              if (item.exampleHr != null && item.exampleHr!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(color: theme.colorScheme.primary, width: 3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.exampleHr!,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700)),
                      if (item.examplePl != null && item.examplePl!.isNotEmpty)
                        Text(item.examplePl!, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ] else
              FilledButton(
                onPressed: onReveal,
                child: const Text('Pokaż odpowiedź'),
              ),
          ],
        ),
      ),
    );
  }
}

class _ConjTable extends StatelessWidget {
  const _ConjTable({required this.item});

  final LearningItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <(String, String?)>[
      ('ja', item.conjJa),
      ('ti', item.conjTi),
      ('on/ona', item.conjOn),
      ('mi', item.conjMi),
      ('vi', item.conjVi),
      ('oni', item.conjOni),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: rows.map((r) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(r.$1,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                ),
                Expanded(
                  child: Text(
                    (r.$2 ?? '').isEmpty ? '—' : r.$2!,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
