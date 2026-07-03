import 'package:flutter/material.dart';

import '../../domain/entities/word.dart';

class WordTile extends StatelessWidget {
  const WordTile({super.key, required this.word});

  final Word word;

  Color _statusColor(BuildContext context) {
    switch (word.status) {
      case 'znam':
        return Colors.green;
      case 'trudne':
        return Colors.red;
      case 'uczę się':
        return Theme.of(context).colorScheme.primary;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _statusColor(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(word.targetWord, style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontSize: 16,
                  )),
                  const SizedBox(height: 2),
                  Text(word.polish, style: theme.textTheme.bodyMedium),
                  if (word.exampleHr != null && word.exampleHr!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      word.exampleHr!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (word.category != null && word.category!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  word.category!,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
