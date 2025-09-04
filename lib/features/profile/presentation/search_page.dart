import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../profile/data/riot_api.dart';
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

  Future<void> _onSearch() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final riotId = _ctrl.text.trim();
      if (!riotId.contains('#')) {
        throw ArgumentError('Use o formato Riot ID: gameName#tagLine (ex.: João#BR1)');
      }
      final parts = riotId.split('#');
      if (parts.length != 2) {
        throw ArgumentError('Riot ID inválido. Tente "Nome#TAG".');
      }
      final gameName = parts[0];
      final tagLine = parts[1];

      final api = ref.read(riotApiProvider);

      // Riot ID -> account (PUUID)
      final account = await api.getAccountByRiotId(
        gameName: gameName,
        tagLine: tagLine,
        region: RegionHost.americas,
      );
      final puuid = account['puuid'] as String;

      // PUUID -> Summoner (via plataforma BR)
      final summoner = await api.getSummonerByPuuid(
        puuid: puuid,
        platform: PlatformHost.br1,
      );

      // Partidas (IDs) – deixamos pronto para próxima etapa
      final matchIds = await api.getMatchIdsByPuuid(
        puuid: puuid,
        region: RegionHost.americas,
        count: 10,
      );

      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ProfilePage(
          riotId: riotId,
          account: account,
          summoner: summoner,
          matchIds: matchIds,
        ),
      ));
    } catch (e) {
      setState(() => _error = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_error!)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSearch = _ctrl.text.trim().contains('#');

    return Scaffold(
      appBar: AppBar(title: const Text('Riot Profile (BR)')),
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
                onPressed: _loading || !canSearch ? null : _onSearch,
                icon: _loading
                    ? const SizedBox(
                        width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
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
              'Dica: Primeiro valide no emulador/celular.\nNo Web pode haver CORS com a Riot.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
