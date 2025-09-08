import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/time_format.dart';
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
  Map<String, dynamic>? _match; // payload completo do match
  Map<String, dynamic>? _me; // participante correspondente ao viewer
  String? _champIcon; // ícone do campeão
  String? _spell1Icon, _spell2Icon; // ícones dos feitiços
  List<String?> _itemIcons = const []; // ícones dos itens (0..6)
  String? _error;
  // --- Players section (expand/collapse) ---
  bool _showPlayers = false;
  List<_PlayerBrief> _blueRoster = const [];
  List<_PlayerBrief> _redRoster = const [];

  Future<void> _loadPlayersIfNeeded() async {
    if (_match == null) return;
    if (_blueRoster.isNotEmpty || _redRoster.isNotEmpty) return;

    final dd = ref.read(dataDragonProvider);
    final info = _match!['info'] as Map<String, dynamic>;
    final participants = List<Map<String, dynamic>>.from(
      info['participants'] as List,
    );

    Future<_PlayerBrief> buildBrief(Map<String, dynamic> p) async {
      final champName = (p['championName'] ?? '').toString();
      final champIcon = await dd.championSquareUrl(champName);
      final itemIds = List<int>.generate(7, (i) => (p['item$i'] ?? 0) as int);
      final itemIcons = await Future.wait(itemIds.map((id) => dd.itemIcon(id)));
      final game = (p['riotIdGameName'] ?? '').toString().trim();
      final tag = (p['riotIdTagline'] ?? '').toString().trim();
      final fallback = (p['summonerName'] ?? '').toString().trim();
      final display = (game.isNotEmpty && tag.isNotEmpty)
          ? '$game#$tag'
          : (fallback.isNotEmpty ? fallback : '—');
      return _PlayerBrief(
        name: display,
        championName: champName,
        champIcon: champIcon,
        items: itemIcons,
        teamId: (p['teamId'] ?? 0) as int,
      );
    }

    final briefs = await Future.wait(participants.map(buildBrief));
    _blueRoster = briefs.where((b) => b.teamId == 100).toList(growable: false);
    _redRoster = briefs.where((b) => b.teamId == 200).toList(growable: false);

    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(riotApiProvider);
      final dd = ref.read(dataDragonProvider);

      final m = await api.getMatchDetail(
        matchId: widget.matchId,
        region: RegionHost.americas,
      );

      final info = m['info'] as Map<String, dynamic>;
      final participants = (info['participants'] as List)
          .cast<Map<String, dynamic>>();
      final me = participants.firstWhere(
        (p) => p['puuid'] == widget.viewerPuuid,
      );

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
      final itemIds = List.generate(
        7,
        (i) => (me['item$i'] as num?)?.toInt() ?? 0,
      );
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
    final cs =
        (me['totalMinionsKilled'] ?? 0) + (me['neutralMinionsKilled'] ?? 0);
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
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
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
                    backgroundImage: _champIcon != null
                        ? NetworkImage(_champIcon!)
                        : null,
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
                        Text(
                          champ,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
                  Text(
                    'Duração: ${formatDurationMmSs((info['gameDuration'] is int ? info['gameDuration'] as int : (info['gameDuration'] as num?)?.toInt() ?? 0))}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Toggle players section
          Align(
            alignment: Alignment.centerLeft,
            child: ActionChip(
              label: Text(
                _showPlayers ? 'Esconder jogadores' : 'Mostrar jogadores',
              ),
              onPressed: () async {
                setState(() => _showPlayers = !_showPlayers);
                if (_showPlayers) {
                  await _loadPlayersIfNeeded();
                }
              },
            ),
          ),
          if (_showPlayers) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Time Azul',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    for (final p in _blueRoster) _PlayerRow(player: p),
                    const Divider(height: 24),
                    const Text(
                      'Time Vermelho',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    for (final p in _redRoster) _PlayerRow(player: p),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlayerBrief {
  _PlayerBrief({
    required this.name,
    required this.championName,
    required this.champIcon,
    required this.items,
    required this.teamId,
  });

  final String name;
  final String championName;
  final String? champIcon;
  final List<String?> items;
  final int teamId; // 100 (azul) / 200 (vermelho)
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

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.player});
  final _PlayerBrief player;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: player.champIcon != null
                ? NetworkImage(player.champIcon!)
                : null,
            child: player.champIcon == null
                ? const Icon(Icons.person, size: 18)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final url in player.items) _ItemIcon(url: url),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
