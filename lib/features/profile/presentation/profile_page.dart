/// profile_page.dart — visão geral do perfil e partidas recentes

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../profile/data/riot_routes.dart';
import '../../../shared/queues.dart';
import '../../../shared/time_format.dart';
import 'match_detail_page.dart';

/// Props: riotId, account, summoner, matchIds
class ProfilePage extends ConsumerStatefulWidget {
  final String riotId;
  final Map<String, dynamic> account;
  final Map<String, dynamic> summoner;
  final List<String> matchIds;

  const ProfilePage({
    super.key,
    required this.riotId,
    required this.account,
    required this.summoner,
    required this.matchIds,
  });

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  // estado: loading/erro/resumo de partidas
  // carregamento inicial (_load)
  bool _loading = true;
  String? _error;
  List<_MatchSummary> _summaries = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _summaries = const [];
    });

    try {
      final api = ref.read(riotApiProvider);
      final dd = ref.read(dataDragonProvider);

      final puuid = (widget.account['puuid'] ?? widget.summoner['puuid'])
          .toString();

      // Busca detalhes básicos de cada partida em paralelo
      final results = await Future.wait(
        widget.matchIds.map((id) async {
          try {
            final m = await api.getMatchDetail(
              matchId: id,
              region: RegionHost.americas,
            );

            final info = m['info'] as Map<String, dynamic>;
            final parts = (info['participants'] as List)
                .cast<Map<String, dynamic>>();
            // Encontra o seu participante (fallback pro primeiro se não achar)
            final me = parts.cast<Map<String, dynamic>?>().firstWhere(
              (p) => p?['puuid'] == puuid,
              orElse: () => parts.first,
            );

            final champName = (me?['championName'] ?? '').toString();
            final champIcon = champName.isNotEmpty
                ? await dd.championSquareUrl(champName)
                : null;

            final kills = (me?['kills'] as num?)?.toInt() ?? 0;
            final deaths = (me?['deaths'] as num?)?.toInt() ?? 0;
            final assists = (me?['assists'] as num?)?.toInt() ?? 0;
            final win = (me?['win'] == true);
            final durationSec = (info['gameDuration'] as num?)?.toInt() ?? 0;
            final queueId = info['queueId'] as int?;
            final endMs = (info['gameEndTimestamp'] as num?)?.toInt();
            final startMs = (info['gameCreation'] as num?)?.toInt();
            final tsMs = endMs ?? startMs ?? 0;

            return _MatchSummary(
              id: id,
              champion: champName,
              championIcon: champIcon,
              kills: kills,
              deaths: deaths,
              assists: assists,
              win: win,
              durationSec: durationSec,
              queueId: queueId,
              timestampMs: tsMs,
              puuid: puuid,
            );
          } catch (_) {
            // Em caso de erro individual, devolve um resumo mínimo (a lista segue)
            return _MatchSummary(
              id: id,
              champion: '',
              championIcon: null,
              kills: 0,
              deaths: 0,
              assists: 0,
              win: false,
              durationSec: 0,
              queueId: null,
              timestampMs: 0,
              puuid: puuid,
            );
          }
        }),
      );

      // Ordena por data (desc)
      results.sort((a, b) => (b.timestampMs).compareTo(a.timestampMs));

      if (!mounted) return;
      setState(() {
        _summaries = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // cabeçalho do perfil + lista/resumo de partidas
    final level = widget.summoner['summonerLevel'];
    final name = widget.summoner['name'];

    return Scaffold(
      appBar: AppBar(title: Text(widget.riotId)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Cabeçalho do perfil
                  Card(
                    child: ListTile(
                      title: Text(
                        name?.toString() ?? '—',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('Level: ${level ?? "—"}'),
                      trailing: Text(
                        'PUUID:\n${((widget.account['puuid'] ?? widget.summoner['puuid']).toString()).substring(0, 10)}...',
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'Últimas partidas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),

                  for (final s in _summaries) _MatchCard(summary: s),
                ],
              ),
            ),
    );
  }
}

// --------- MODELO LOCAL ---------
class _MatchSummary {
  final String id;
  final String puuid;
  final String champion;
  final String? championIcon;
  final int kills, deaths, assists;
  final bool win;
  final int durationSec;
  final int? queueId;
  final int timestampMs;

  const _MatchSummary({
    required this.id,
    required this.puuid,
    required this.champion,
    required this.championIcon,
    required this.kills,
    required this.deaths,
    required this.assists,
    required this.win,
    required this.durationSec,
    required this.queueId,
    required this.timestampMs,
  });
}

// --------- CARD DA PARTIDA ---------
/// Cartão/resumo de partida (widget privado)
class _MatchCard extends StatelessWidget {
  final _MatchSummary summary;
  const _MatchCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final kda = summary.deaths == 0
        ? (summary.kills + summary.assists).toDouble()
        : (summary.kills + summary.assists) / summary.deaths;

    final queue = queueLabel(summary.queueId);
    final duration = formatDurationMmSs(summary.durationSec);
    final badgeColor = summary.win
        ? Colors.green.shade600
        : Colors.red.shade600;

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MatchDetailPage(
                matchId: summary.id,
                viewerPuuid: summary.puuid,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // ícone do campeão
              CircleAvatar(
                radius: 26,
                backgroundImage: summary.championIcon != null
                    ? NetworkImage(summary.championIcon!)
                    : null,
                child: summary.championIcon == null
                    ? const Icon(Icons.sports_esports)
                    : null,
              ),
              const SizedBox(width: 12),

              // infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Campeão + badge de resultado
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            summary.champion.isEmpty ? '—' : summary.champion,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            summary.win ? 'Vitória' : 'Derrota',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // chips de KDA / fila / duração
                    Wrap(
                      spacing: 8,
                      runSpacing: -8,
                      children: [
                        _Chip(
                          text:
                              'K/D/A ${summary.kills}/${summary.deaths}/${summary.assists}',
                        ),
                        _Chip(text: 'KDA ${kda.toStringAsFixed(2)}'),
                        _Chip(text: queue),
                        _Chip(text: duration),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip de status/labels (widget privado)
class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});
  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(text),
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      shape: StadiumBorder(
        side: BorderSide(color: Colors.black.withOpacity(0.08)),
      ),
    );
  }
}
