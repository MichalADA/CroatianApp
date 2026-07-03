import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/failure.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../sentences/presentation/sentences_tab.dart';
import '../../learning/presentation/learning_tab.dart';
import '../../learning/presentation/review_tab.dart';
import '../../games/presentation/games_tab.dart';
import '../data/rooms_repository.dart';
import 'tabs/verbs_tab.dart';
import 'tabs/words_tab.dart';

class RoomScreen extends ConsumerStatefulWidget {
  const RoomScreen({super.key, required this.roomId});

  final int roomId;

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends ConsumerState<RoomScreen> {
  int _current = 0;

  static const _labels = ['Nauka', 'Słownik', 'Czasowniki', 'Powtórki', 'Zdania', 'Gry'];
  static const _icons = [
    Icons.school_outlined,
    Icons.menu_book_outlined,
    Icons.g_translate,
    Icons.replay_circle_filled_outlined,
    Icons.edit_note_outlined,
    Icons.videogame_asset_outlined,
  ];

  Widget _bodyFor(int i) {
    switch (i) {
      case 0:
        return LearningTab(roomId: widget.roomId);
      case 1:
        return WordsTab(roomId: widget.roomId);
      case 2:
        return VerbsTab(roomId: widget.roomId);
      case 3:
        return ReviewTab(roomId: widget.roomId);
      case 4:
        return SentencesTab(roomId: widget.roomId);
      case 5:
        return GamesTab(roomId: widget.roomId);
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomByIdProvider(widget.roomId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: roomAsync.when(
          loading: () => const Text('Pokój'),
          error: (_, __) => Text('Pokój #${widget.roomId}'),
          data: (r) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(r.emoji ?? '🚪', style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Flexible(child: Text(r.name, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
        actions: [
          if (widget.roomId == 1)
            IconButton(
              icon: const Icon(Icons.abc),
              tooltip: 'Alfabet',
              onPressed: () => context.pushNamed(AppRoutes.alphabet,
                  pathParameters: {'roomId': '${widget.roomId}'}),
            ),
        ],
      ),
      body: roomAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => AppErrorView(
          message: e is Failure ? e.message : e.toString(),
          onRetry: () => ref.invalidate(roomByIdProvider(widget.roomId)),
        ),
        data: (_) => _bodyFor(_current),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _current,
        onDestinationSelected: (i) => setState(() => _current = i),
        destinations: [
          for (var i = 0; i < _labels.length; i++)
            NavigationDestination(
              icon: Icon(_icons[i]),
              label: _labels[i],
            ),
        ],
      ),
    );
  }
}
