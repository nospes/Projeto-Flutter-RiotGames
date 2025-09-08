/// search_page.dart — tela inicial de busca por Riot ID
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../profile/data/riot_routes.dart';
import '../../../core/providers.dart';
import 'profile_page.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  // Mapeia o prefixo do matchId (ex.: "BR1_123") para PlatformHost
  PlatformHost? _platformFromMatchId(String matchId) {
    final prefix = matchId.split('_').first.toUpperCase();
    switch (prefix) {
      case 'BR1':
        return PlatformHost.br1;
      case 'NA1':
        return PlatformHost.na1;
      case 'LA1':
        return PlatformHost.la1;
      case 'LA2':
        return PlatformHost.la2;
      case 'EUW1':
        return PlatformHost.euw1;
      case 'EUN1':
        return PlatformHost.eun1;
      case 'KR':
        return PlatformHost.kr;
      case 'JP1':
        return PlatformHost.jp1;
      case 'TR1':
        return PlatformHost.tr1;
      case 'RU':
        return PlatformHost.ru;
      // Seu enum usa "oce"; o prefixo do match é "OC1"
      case 'OC1':
        return PlatformHost.oce;
    }
    return null;
  }

  // Tenta achar o account em cada região (americas/europe/asia)
  Future<(RegionHost, Map<String, dynamic>)> _findAccountRegion({
    required String gameName,
    required String tagLine,
  }) async {
    final api = ref.read(riotApiProvider);
    final regions = [RegionHost.americas, RegionHost.europe, RegionHost.asia];

    for (final r in regions) {
      try {
        final acc = await api.getAccountByRiotId(
          gameName: gameName,
          tagLine: tagLine,
          region: r,
        );
        return (r, acc);
      } on DioException catch (e) {
        // 404 nesta região -> tenta a próxima
        if (e.response?.statusCode == 404) continue;
        rethrow;
      }
    }
    throw ArgumentError('Riot ID não encontrado em nenhuma região.');
  }

  // Busca matchIds tentando a região “preferida” e, se vazio, outras regiões
  Future<(RegionHost, List<String>)> _findMatchesInAnyRegion({
    required String puuid,
    required RegionHost preferred,
    int count = 10,
  }) async {
    final api = ref.read(riotApiProvider);
    final ordered = [
      preferred,
      ...[
        RegionHost.americas,
        RegionHost.europe,
        RegionHost.asia,
      ].where((r) => r != preferred),
    ];

    for (final r in ordered) {
      try {
        final ids = await api.getMatchIdsByPuuid(
          puuid: puuid,
          region: r,
          count: count,
        );
        if (ids.isNotEmpty) return (r, ids);
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) continue;
        rethrow;
      }
    }
    // Nenhuma região retornou partidas; devolve a preferida com lista vazia
    return (preferred, const <String>[]);
  }

  // Se não conseguir inferir a plataforma pelo matchId (sem partidas),
  // tenta todas as plataformas até achar o summoner por PUUID.
  Future<(PlatformHost, Map<String, dynamic>)> _findSummonerAnyPlatform({
    required String puuid,
  }) async {
    final api = ref.read(riotApiProvider);
    for (final p in PlatformHost.values) {
      try {
        final s = await api.getSummonerByPuuid(puuid: puuid, platform: p);
        return (p, s);
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) continue;
        rethrow;
      }
    }
    throw ArgumentError('Summoner não encontrado em nenhuma plataforma.');
  }

  Future<void> _onSearch() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final riotId = _ctrl.text.trim();

      // valida formato "Nome#TAG"
      if (!riotId.contains('#')) {
        throw ArgumentError(
          'Use o formato Riot ID: gameName#tagLine (ex.: João#BR1)',
        );
      }
      final parts = riotId.split('#');
      if (parts.length != 2) {
        throw ArgumentError('Riot ID inválido. Tente "Nome#TAG".');
      }
      final gameName = parts[0];
      final tagLine = parts[1];

      // 1) Descobre a região correta do account (sem assumir nada da TAG)
      final (accountRegion, account) = await _findAccountRegion(
        gameName: gameName,
        tagLine: tagLine,
      );
      final puuid = account['puuid'] as String;

      // 2) Busca matchIds e, se possível, infere a plataforma pelo prefixo do matchId
      final (matchesRegion, matchIds) = await _findMatchesInAnyRegion(
        puuid: puuid,
        preferred: accountRegion,
        count: 10,
      );

      PlatformHost? platform;
      if (matchIds.isNotEmpty) {
        platform = _platformFromMatchId(matchIds.first);
      }

      // 3) Com a plataforma, busca o Summoner; se não deu pra inferir, tenta todas
      Map<String, dynamic> summoner;
      if (platform != null) {
        summoner = await ref
            .read(riotApiProvider)
            .getSummonerByPuuid(puuid: puuid, platform: platform);
      } else {
        final (pf, s) = await _findSummonerAnyPlatform(puuid: puuid);
        platform = pf;
        summoner = s;
      }

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProfilePage(
            riotId: riotId,
            account: account,
            summoner: summoner,
            matchIds: matchIds,
          ),
        ),
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      String msg;
      if (code == 404) {
        msg =
            'Riot ID não encontrado. Verifique o nome e a tag (ex.: Nome#BR1).';
      } else if (code == 403) {
        msg = 'Acesso negado à Riot API. Verifique sua RIOT_API_KEY.';
      } else if (code == 429) {
        msg = 'Muitas requisições. Aguarde e tente novamente.';
      } else {
        msg = 'Falha ao buscar dados. Tente novamente.';
      }
      if (mounted) {
        setState(() => _error = msg);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } on ArgumentError catch (e) {
      final msg = e.message.toString();
      if (mounted) {
        setState(() => _error = msg);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (_) {
      const msg = 'Erro inesperado. Tente novamente.';
      if (mounted) {
        setState(() => _error = msg);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSearch = _ctrl.text.trim().contains('#');

    return Scaffold(
      appBar: AppBar(title: const Text('Riot Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                labelText: 'Riot ID (ex.: SeuNome#BR1)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => canSearch ? _onSearch() : null,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (_loading || !canSearch) ? null : _onSearch,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: const Text('Buscar'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const Spacer(),
            const Text(
              'Na versão Web pode haver CORS com a Riot.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
