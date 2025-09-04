import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/data/riot_routes.dart';
import '../../../core/providers.dart';
import '../../../shared/queues.dart';

class MatchDetailPage extends ConsumerStatefulWidget {
  final String matchId;
  final String viewerPuuid;

  const MatchDetailPage({
    super.key,
    required this.matchId,
    required this.viewerPuuid,
  });

  @override
  ConsumerState<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends ConsumerState<MatchDetailPage> {
  Map<String, dynamic>? _match;       // payload completo do match
  Map<String, dynamic>? _me;          // participante correspondente ao viewer
  String? _champIcon;                 // ícone do campeão
  String? _spell1Icon, _spell2Icon;   // ícones dos feitiços
  List<String?> _itemIcons = const []; // ícones dos itens (0..6)
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(riotApiProvider);
      final dd  = ref.read(dataDragonProvider);

      final m = await api.getMatchDetail(
        matchId: widget.matchId,
        region: RegionHost.americas,
      );

      final info = m['info'] as Map<String, dynamic>;
      final participants =
          (info['participants'] as List).cast<Map<String, dynamic>>();
      final me =
          participants.firstWhere((p) => p['puuid'] == widget.viewerPuuid);

      // Campeão
      final championName = (me['championName'] ?? '').toString();
      final champIcon = championName.isNotEmpty
          ? await dd.championSquareUrl(championName)
          : null;

      // Feitiços (converte num -> int com segurança)
      final s1Key = (me['summoner1Id'] as num?)?.toInt() ?? 0;
      final s2Key = (me['summoner2Id'] as num?)?.toInt() ?? 0;
      final s1 = await dd.spellIconFromNumericKey(s1Key);
      final s2 = await dd.spellIconFromNumericKey(s2Key);

      // Itens (0..6; 6 = trinket/ward)
      final itemIds =
          List.generate(7, (i) => (me['item$i'] as num?)?.toInt() ?? 0);
      final itemIcons = <String?>[];
      for (final id in itemIds) {
        itemIcons.add(await dd.itemIcon(id));
      }

      if (!mounted) return;
      setState(() {
        _match = m;
        _me = me;
        _champIcon = champIcon;
        _spell1Icon = s1;
        _spell2Icon = s2;
        _itemIcons = itemIcons;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.matchId)),
        body: Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (_match == null || _me == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.matchId)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final info = _match!['info'] as Map<String, dynamic>;
    final me = _me!;
    final queue = queueLabel(info['queueId'] as int?);

    final win = (me['win'] == true);
    final kills = me['kills'] ?? 0;
    final deaths = me['deaths'] ?? 0;
    final assists = me['assists'] ?? 0;
    final kda = deaths == 0
        ? (kills + assists).toDouble()
        : (kills + assists) / deaths;
    final pos = (me['teamPosition'] ?? '').toString().toUpperCase();
    final cs = (me['totalMinionsKilled'] ?? 0) + (me['neutralMinionsKilled'] ?? 0);
    final gold = me['goldEarned'] ?? 0;
    final champ = (me['championName'] ?? '').toString();

    final badgeColor = win ? Colors.green.shade600 : Colors.red.shade600;

    return Scaffold(
      appBar: AppBar(
        title: Text(queue),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              win ? 'Vitória' : 'Derrota',
              style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Cabeçalho: campeão + feitiços + chips
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage:
                        _champIcon != null ? NetworkImage(_champIcon!) : null,
                    child: _champIcon == null
                        ? const Icon(Icons.sports_esports)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      _SpellIcon(url: _spell1Icon),
                      const SizedBox(height: 6),
                      _SpellIcon(url: _spell2Icon),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(champ,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            )),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: -8,
                          children: [
                            _Chip(text: 'K/D/A $kills/$deaths/$assists'),
                            _Chip(text: 'KDA ${kda.toStringAsFixed(2)}'),
                            if (pos.isNotEmpty) _Chip(text: pos),
                            _Chip(text: 'CS $cs'),
                            _Chip(text: 'Gold $gold'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          Text('Itens', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                children: _itemIcons.map((u) => _ItemIcon(url: u)).toList(),
              ),
            ),
          ),

          const SizedBox(height: 12),
          Text('Resumo', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fila: $queue'),
                  Text('Patch: ${info['gameVersion'] ?? "—"}'),
                  Text('Duração: ${(info['gameDuration'] ?? 0)} s'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ----- widgets auxiliares -----

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});
  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(text),
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      shape: StadiumBorder(
        side: BorderSide(color: Colors.black.withOpacity(0.1)),
      ),
    );
  }
}

class _SpellIcon extends StatelessWidget {
  final String? url;
  const _SpellIcon({this.url});
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 14,
      backgroundImage: (url != null) ? NetworkImage(url!) : null,
      child: (url == null) ? const Icon(Icons.flash_on, size: 16) : null,
    );
  }
}

class _ItemIcon extends StatelessWidget {
  final String? url;
  const _ItemIcon({this.url});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withOpacity(0.1)),
        image: url != null
            ? DecorationImage(image: NetworkImage(url!), fit: BoxFit.cover)
            : null,
        color: url == null ? Colors.black12 : null,
      ),
      child: url == null ? const Icon(Icons.block, size: 18) : null,
    );
  }
}
