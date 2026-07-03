import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../data/words_repository.dart';
import '../widgets/verb_tile.dart';

class VerbsTab extends ConsumerStatefulWidget {
  const VerbsTab({super.key, required this.roomId});

  final int roomId;

  @override
  ConsumerState<VerbsTab> createState() => _VerbsTabState();
}

class _VerbsTabState extends ConsumerState<VerbsTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _query = v.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(verbsProvider(
      (roomId: widget.roomId, q: _query.isEmpty ? null : _query),
    ));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              hintText: 'Szukaj czasownika…',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
            onChanged: _onSearch,
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const LoadingView(),
            error: (e, _) => AppErrorView(
              message: e is Failure ? e.message : e.toString(),
              onRetry: () => ref.invalidate(verbsProvider),
            ),
            data: (verbs) {
              if (verbs.isEmpty) {
                return const EmptyView(
                  icon: Icons.record_voice_over_outlined,
                  message: 'Brak czasowników.',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                itemCount: verbs.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: VerbTile(verb: verbs[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
