/// data_dragon.dart — resolução de versões e ícones (campeão/feitiço/item)
import 'package:dio/dio.dart';

/// Cliente Data Dragon (usa Dio)
class DataDragon {
  final Dio dio;
  String? _cachedVersion;
  Map<String, dynamic>? _spellsJson;

  DataDragon(this.dio);

  /// Última versão disponível
  Future<String> latestVersion() async {
    if (_cachedVersion != null) return _cachedVersion!;
    final res = await dio.get(
      'https://ddragon.leagueoflegends.com/api/versions.json',
    );
    final versions = (res.data as List).map((e) => e.toString()).toList();
    _cachedVersion = versions.first;
    return _cachedVersion!;
  }

  String _sanitizeChampion(String name) =>
      name.replaceAll(" ", "").replaceAll("'", "");

  /// Ícone quadrado do campeão
  Future<String> championSquareUrl(String championName) async {
    final v = await latestVersion();
    return 'https://ddragon.leagueoflegends.com/cdn/$v/img/champion/${_sanitizeChampion(championName)}.png';
  }

  // Posição do feitiço
  Future<Map<String, String>> spellKeyToAssetId() async {
    if (_spellsJson == null) {
      final v = await latestVersion();
      final res = await dio.get(
        'https://ddragon.leagueoflegends.com/cdn/$v/data/en_US/summoner.json',
      );
      _spellsJson = res.data as Map<String, dynamic>;
    }
    final data = (_spellsJson!['data'] as Map<String, dynamic>);
    final map = <String, String>{};
    for (final e in data.entries) {
      final id = e.key; // "SummonerFlash"
      final key = e.value['key'].toString(); // "4"
      map[key] = id;
    }
    return map;
  }

  /// Ícone do feitiço
  Future<String?> spellIconFromNumericKey(int key) async {
    final m = await spellKeyToAssetId();
    final id = m[key.toString()];
    if (id == null) return null;
    final v = await latestVersion();
    return 'https://ddragon.leagueoflegends.com/cdn/$v/img/spell/$id.png';
  }

  /// Ícone do item
  Future<String?> itemIcon(int itemId) async {
    if (itemId == 0) return null;
    final v = await latestVersion();
    return 'https://ddragon.leagueoflegends.com/cdn/$v/img/item/$itemId.png';
  }
}
