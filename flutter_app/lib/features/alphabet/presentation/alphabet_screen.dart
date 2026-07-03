import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

/// Alfabet chorwacki — lekcja fonetyki. Audio (assets/audio/hr/alphabet/*.mp3)
/// dołączasz osobno; jeśli plik nie istnieje, gracz cicho ignoruje błąd.
class AlphabetScreen extends StatefulWidget {
  const AlphabetScreen({super.key});

  @override
  State<AlphabetScreen> createState() => _AlphabetScreenState();
}

class _AlphabetScreenState extends State<AlphabetScreen> {
  final _player = AudioPlayer();

  static const _letters = <_Letter>[
    _Letter('A', 'a', 'a — auto', 'a'),
    _Letter('B', 'b', 'b — brat', 'b'),
    _Letter('C', 'c', 'c — cesta', 'c'),
    _Letter('Č', 'č', 'cz — čaj', 'c-caron'),
    _Letter('Ć', 'ć', 'miękkie ć — kuća', 'c-acute'),
    _Letter('D', 'd', 'd — dan', 'd'),
    _Letter('Dž', 'dž', 'dż — džep', 'dz'),
    _Letter('Đ', 'đ', 'dź/dż — dođem', 'd-stroke'),
    _Letter('E', 'e', 'e — euro', 'e'),
    _Letter('F', 'f', 'f — film', 'f'),
    _Letter('G', 'g', 'g — grad', 'g'),
    _Letter('H', 'h', 'h — hotel', 'h'),
    _Letter('I', 'i', 'i — ime', 'i'),
    _Letter('J', 'j', 'j — ja', 'j'),
    _Letter('K', 'k', 'k — kava', 'k'),
    _Letter('L', 'l', 'l — ljubav', 'l'),
    _Letter('Lj', 'lj', 'lj — ljudi', 'lj'),
    _Letter('M', 'm', 'm — more', 'm'),
    _Letter('N', 'n', 'n — noć', 'n'),
    _Letter('Nj', 'nj', 'ń — konj', 'nj'),
    _Letter('O', 'o', 'o — otac', 'o'),
    _Letter('P', 'p', 'p — posao', 'p'),
    _Letter('R', 'r', 'r — ruka', 'r'),
    _Letter('S', 's', 's — soba', 's'),
    _Letter('Š', 'š', 'sz — škola', 's-caron'),
    _Letter('T', 't', 't — tjedan', 't'),
    _Letter('U', 'u', 'u — ulica', 'u'),
    _Letter('V', 'v', 'w — voda', 'v'),
    _Letter('Z', 'z', 'z — zima', 'z'),
    _Letter('Ž', 'ž', 'ż/rz — žena', 'z-caron'),
  ];

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _play(String code) async {
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/hr/alphabet/$code.mp3'));
    } on Object {
      // audio nie musi istnieć — nic nie robimy
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Alfabet chorwacki')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Chorwacki jest bardzo fonetyczny — prawie zawsze czytasz tak, jak jest napisane.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.6,
            ),
            itemCount: _letters.length,
            itemBuilder: (context, i) {
              final l = _letters[i];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _play(l.audioCode),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${l.upper} ${l.lower}',
                            style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.primary)),
                        const SizedBox(height: 4),
                        Text(l.hint,
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                        const SizedBox(height: 4),
                        const Icon(Icons.volume_up, size: 16),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Zasady wymowy', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  const _Rule(
                    number: '1',
                    title: 'Czytasz tak jak widzisz',
                    body: 'Chorwacki jest fonetyczny — prawie każda litera ma jeden dźwięk.',
                  ),
                  const _Rule(
                    number: '2',
                    title: 'C, Č, Ć',
                    body: 'C=„c”, Č=„cz” (čaj), Ć=miękkie „ć” (kuća).',
                  ),
                  const _Rule(
                    number: '3',
                    title: 'Š, Ž, Dž',
                    body: 'Š=sz (škola), Ž=ż/rz (žena), Dž=dż (džep).',
                  ),
                  const _Rule(
                    number: '4',
                    title: 'Lj i Nj to pojedyncze dźwięki',
                    body: 'ljubav = „lubav”, konj = „koń”.',
                  ),
                  const _Rule(
                    number: '5',
                    title: 'Akcent',
                    body: 'Zwykle pada na pierwszą sylabę (DO-bar, KU-ća).',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.number, required this.title, required this.body});

  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(top: 2, right: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Text(number,
                style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimary, fontSize: 12)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(body,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Letter {
  const _Letter(this.upper, this.lower, this.hint, this.audioCode);
  final String upper;
  final String lower;
  final String hint;
  final String audioCode;
}
