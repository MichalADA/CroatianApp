import 'package:flutter/material.dart';

import '../../../rooms/domain/entities/room.dart';

class RoomCard extends StatelessWidget {
  const RoomCard({
    super.key,
    required this.room,
    required this.locked,
    required this.onTap,
  });

  final Room room;
  final bool locked;
  final VoidCallback onTap;

  Color get _accentColor {
    final raw = room.color;
    if (raw == null || raw.isEmpty) return const Color(0xFFE8C07D);
    try {
      final hex = raw.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } on Object {
      return const Color(0xFFE8C07D);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = room.progressRatio.clamp(0.0, 1.0);

    return Opacity(
      opacity: locked ? 0.55 : 1.0,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(room.emoji ?? '🚪', style: const TextStyle(fontSize: 32)),
                    const Spacer(),
                    if (locked)
                      Icon(Icons.lock,
                          size: 20, color: theme.colorScheme.primary),
                  ],
                ),
                const SizedBox(height: 8),
                Text(room.name, style: theme.textTheme.titleMedium),
                if (room.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    room.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Badge(text: '${room.wordCount} słów'),
                    _Badge(text: '${room.verbCount} cz.'),
                    if (!locked && room.dueToday > 0)
                      _Badge(
                        text: '⏰ ${room.dueToday}',
                        color: theme.colorScheme.primary,
                      ),
                    if (!locked && room.knownCount > 0)
                      _Badge(
                        text: '✓ ${room.knownCount}',
                        color: _accentColor,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor:
                        theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(_accentColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: c),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(color: c, fontSize: 12),
      ),
    );
  }
}
