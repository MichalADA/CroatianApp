import 'package:flutter/material.dart';

import '../../domain/entities/verb.dart';

class VerbTile extends StatelessWidget {
  const VerbTile({super.key, required this.verb});

  final Verb verb;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ExpansionTile(
        title: Row(
          children: [
            Text(verb.infinitive,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                )),
            const SizedBox(width: 10),
            Text('· ${verb.polish}', style: theme.textTheme.bodyMedium),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        children: [
          _ConjRow(pron: 'ja', form: verb.conjJa),
          _ConjRow(pron: 'ti', form: verb.conjTi),
          _ConjRow(pron: 'on/ona', form: verb.conjOn),
          _ConjRow(pron: 'mi', form: verb.conjMi),
          _ConjRow(pron: 'vi', form: verb.conjVi),
          _ConjRow(pron: 'oni', form: verb.conjOni),
          if (verb.exampleHr != null && verb.exampleHr!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: theme.colorScheme.primary, width: 3),
                ),
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(verb.exampleHr!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      )),
                  if (verb.examplePl != null && verb.examplePl!.isNotEmpty)
                    Text(verb.examplePl!,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConjRow extends StatelessWidget {
  const _ConjRow({required this.pron, required this.form});

  final String pron;
  final String? form;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(pron,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          ),
          Expanded(
            child: Text(
              (form ?? '').isEmpty ? '—' : form!,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
