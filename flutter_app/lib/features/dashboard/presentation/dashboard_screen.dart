import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/errors/failure.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../languages/data/languages_repository.dart';
import '../../rooms/data/rooms_repository.dart';
import '../../rooms/domain/entities/room.dart';
import '../data/dashboard_repository.dart';
import 'widgets/dashboard_stats.dart';
import 'widgets/language_switcher.dart';
import 'widgets/room_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(languagesListProvider);
    ref.invalidate(roomsListProvider);
    ref.invalidate(dashboardSummaryProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final languagesAsync = ref.watch(languagesListProvider);
    final roomsAsync = ref.watch(roomsListProvider);
    final dashboardAsync = ref.watch(dashboardSummaryProvider);

    if (auth is! AuthAuthenticated) {
      return const Scaffold(body: LoadingView());
    }
    final user = auth.user;

    // Znajdź aktualny język
    final currentLang = languagesAsync.value?.firstWhere(
      (l) => l.code == user.selectedLanguage,
      orElse: () => languagesAsync.value!.first,
    );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: _UserChip(username: user.username, avatar: user.avatar),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 6),
            child: LanguageSwitcher(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Ustawienia',
            onPressed: () => context.pushNamed(AppRoutes.profile),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          children: [
            _Hero(languageFlag: currentLang?.flag ?? '🌍', title: currentLang?.title ?? user.selectedLanguage),
            const SizedBox(height: 24),
            dashboardAsync.when(
              loading: () => const SizedBox(height: 160, child: LoadingView()),
              error: (err, _) => AppErrorView(
                message: err is Failure ? err.message : err.toString(),
                onRetry: () => ref.invalidate(dashboardSummaryProvider),
              ),
              data: (summary) => DashboardStats(summary: summary),
            ),
            const SizedBox(height: 32),
            _SectionTitle(text: 'Pokoje pałacu pamięci'),
            const SizedBox(height: 12),
            roomsAsync.when(
              loading: () => const SizedBox(height: 200, child: LoadingView()),
              error: (err, _) => AppErrorView(
                message: err is Failure ? err.message : err.toString(),
                onRetry: () => ref.invalidate(roomsListProvider),
              ),
              data: (rooms) {
                if (rooms.isEmpty) {
                  return EmptyView(
                    icon: Icons.language,
                    title: currentLang?.title ?? 'Brak zawartości',
                    message:
                        'Ten język nie ma jeszcze dodanych pokoi. Wróć później albo przełącz język.',
                  );
                }
                final locked = ref.read(lockedRoomsProvider(
                    (rooms: rooms, username: user.username)));
                return _RoomsGrid(rooms: rooms, lockedIds: locked);
              },
            ),
            const SizedBox(height: 24),
            dashboardAsync.when(
              loading: SizedBox.shrink,
              error: (_, __) => const SizedBox.shrink(),
              data: (summary) {
                if (summary.recentSentences.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(text: 'Ostatnio dodane zdania'),
                    const SizedBox(height: 12),
                    ...summary.recentSentences.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Card(
                            child: ListTile(
                              title: Text(s.textHr,
                                  style: Theme.of(context).textTheme.bodyLarge),
                              subtitle: s.textPl != null
                                  ? Text(s.textPl!)
                                  : null,
                              trailing: Text('Pokój ${s.roomId}',
                                  style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 12)),
                            ),
                          ),
                        )),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Center(
              child: TextButton.icon(
                onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Wyloguj'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip({required this.username, this.avatar});

  final String username;
  final String? avatar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: theme.colorScheme.primary,
          child: Text(
            username.isNotEmpty ? username[0].toUpperCase() : '?',
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            username,
            style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.languageFlag, required this.title});

  final String languageFlag;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parts = title.split(' od podstaw');
    final head = parts.isNotEmpty && parts.first.isNotEmpty ? parts.first : title;
    return Column(
      children: [
        Text(
          '$languageFlag pałac pamięci',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            letterSpacing: 2,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(children: [
            TextSpan(text: '$head\n', style: theme.textTheme.headlineLarge),
            TextSpan(
              text: 'od podstaw',
              style: theme.textTheme.headlineLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontSize: 12,
            letterSpacing: 2,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
    );
  }
}

class _RoomsGrid extends StatelessWidget {
  const _RoomsGrid({required this.rooms, required this.lockedIds});

  final List<Room> rooms;
  final Set<int> lockedIds;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final crossAxisCount = constraints.maxWidth > 700 ? 3 : (constraints.maxWidth > 480 ? 2 : 1);
      return GridView.count(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.05,
        children: rooms.map((r) {
          final locked = lockedIds.contains(r.id);
          return RoomCard(
            room: r,
            locked: locked,
            onTap: () {
              if (locked) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🔒 Ukończ poprzedni pokój, żeby przejść dalej'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
              context.pushNamed(AppRoutes.room, pathParameters: {'roomId': '${r.id}'});
            },
          );
        }).toList(),
      );
    });
  }
}
