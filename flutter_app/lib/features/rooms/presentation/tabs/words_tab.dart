import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../data/words_repository.dart';
import '../widgets/word_tile.dart';

class WordsTab extends ConsumerStatefulWidget {
  const WordsTab({super.key, required this.roomId});

  final int roomId;

  @override
  ConsumerState<WordsTab> createState() => _WordsTabState();
}

class _WordsTabState extends ConsumerState<WordsTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _category = 'wszystkie';
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
    final wordsAsync = ref.watch(wordsProvider(
      (roomId: widget.roomId, q: _query.isEmpty ? null : _query, category: _category),
    ));
    final catsAsync = ref.watch(wordCategoriesProvider(widget.roomId));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              hintText: 'Szukaj słowa…',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
            onChanged: _onSearch,
          ),
        ),
        catsAsync.when(
          loading: () => const SizedBox(height: 40),
          error: (_, __) => const SizedBox(height: 40),
          data: (cats) => cats.isEmpty
              ? const SizedBox.shrink()
              : SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: ['wszystkie', ...cats].map((c) {
                      final active = c == _category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(c),
                          selected: active,
                          onSelected: (_) => setState(() => _category = c),
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ),
        Expanded(
          child: wordsAsync.when(
            loading: () => const LoadingView(),
            error: (e, _) => AppErrorView(
              message: e is Failure ? e.message : e.toString(),
              onRetry: () => ref.invalidate(wordsProvider),
            ),
            data: (words) {
              if (words.isEmpty) {
                return const EmptyView(
                  icon: Icons.menu_book_outlined,
                  message: 'Brak słów spełniających kryteria.',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                itemCount: words.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: WordTile(word: words[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
