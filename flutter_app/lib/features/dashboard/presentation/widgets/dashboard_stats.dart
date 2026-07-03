import 'package:flutter/material.dart';

import '../../domain/entities/dashboard_summary.dart';

class DashboardStats extends StatelessWidget {
  const DashboardStats({super.key, required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _StatTile(value: '${summary.totalWords}', label: 'słów w bazie'),
      _StatTile(value: '${summary.totalVerbs}', label: 'czasowników'),
      _StatTile(
        value: '${summary.known}',
        label: 'znam',
        color: Theme.of(context).colorScheme.primary,
      ),
      _StatTile(
        value: '${summary.dueToday}',
        label: 'do powtórki dziś',
        color: summary.dueToday > 0 ? Colors.orange : null,
      ),
    ];
    // Na wąskich ekranach 2 kolumny, na szerokich 4 w jednej linii.
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 640 ? 4 : 2;
      return GridView.count(
        crossAxisCount: cols,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        // Stała wysokość zapobiega rozdymaniu tile'a na wide screenach.
        childAspectRatio: cols == 4 ? 1.6 : 2.4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: tiles,
      );
    });
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label, this.color});

  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: color ?? theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
