import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../data/sentences_repository.dart';
import '../domain/entities/sentence.dart';

class SentencesTab extends ConsumerWidget {
  const SentencesTab({super.key, required this.roomId});

  final int roomId;

  Future<void> _addSentence(BuildContext context, WidgetRef ref) async {
    final hrCtrl = TextEditingController();
    final plCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    var status = 'do sprawdzenia';

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (context, setSt) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Dodaj zdanie', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                  controller: hrCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Zdanie w języku docelowym *',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: plCtrl,
                  decoration: const InputDecoration(labelText: 'Tłumaczenie po polsku'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Notatka'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'do sprawdzenia', child: Text('Do sprawdzenia')),
                    DropdownMenuItem(value: 'poprawne', child: Text('Poprawne')),
                    DropdownMenuItem(value: 'trudne', child: Text('Trudne')),
                  ],
                  onChanged: (v) => setSt(() => status = v ?? status),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Anuluj'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          if (hrCtrl.text.trim().isEmpty) return;
                          try {
                            await ref.read(sentencesRepositoryProvider).create(
                                  roomId: roomId,
                                  textHr: hrCtrl.text.trim(),
                                  textPl: plCtrl.text.trim().isEmpty ? null : plCtrl.text.trim(),
                                  note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                                  status: status,
                                );
                            if (context.mounted) Navigator.of(context).pop(true);
                          } on Failure catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.message)),
                              );
                            }
                          }
                        },
                        child: const Text('Zapisz'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    hrCtrl.dispose();
    plCtrl.dispose();
    noteCtrl.dispose();

    if (saved == true) {
      ref.invalidate(sentencesProvider(roomId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sentencesProvider(roomId));
    return Scaffold(
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => AppErrorView(
          message: e is Failure ? e.message : e.toString(),
          onRetry: () => ref.invalidate(sentencesProvider(roomId)),
        ),
        data: (sentences) {
          if (sentences.isEmpty) {
            return const EmptyView(
              icon: Icons.edit_note,
              title: 'Brak zdań',
              message: 'Dodaj pierwsze zdanie, żeby zbierać własne przykłady.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
            itemCount: sentences.length,
            itemBuilder: (context, i) => _SentenceCard(
              sentence: sentences[i],
              onDelete: () async {
                try {
                  await ref.read(sentencesRepositoryProvider).delete(sentences[i].id);
                  ref.invalidate(sentencesProvider(roomId));
                } on Failure catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.message)),
                    );
                  }
                }
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addSentence(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nowe zdanie'),
      ),
    );
  }
}

class _SentenceCard extends StatelessWidget {
  const _SentenceCard({required this.sentence, required this.onDelete});

  final Sentence sentence;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(sentence.textHr,
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDelete,
                  tooltip: 'Usuń',
                ),
              ],
            ),
            if (sentence.textPl != null && sentence.textPl!.isNotEmpty)
              Text(sentence.textPl!, style: theme.textTheme.bodyMedium),
            if (sentence.note != null && sentence.note!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                sentence.note!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(sentence.status,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}
