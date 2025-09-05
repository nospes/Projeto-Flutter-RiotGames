import 'package:dio/dio.dart';
import 'riot_routes.dart';

class RiotApi {
  final Dio _dio;
  RiotApi(this._dio);

  Future<Map<String, dynamic>> getAccountByRiotId({
    required String gameName,
    required String tagLine,
    RegionHost region = RegionHost.americas,
  }) async {
    final url =
        '${regionBase(region)}/riot/account/v1/accounts/by-riot-id/$gameName/$tagLine';
    final res = await _dio.get(url);
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> getSummonerByPuuid({
    required String puuid,
    PlatformHost platform = PlatformHost.br1,
  }) async {
    final url =
        '${platformBase(platform)}/lol/summoner/v4/summoners/by-puuid/$puuid';
    final res = await _dio.get(url);
    return Map<String, dynamic>.from(res.data);
  }

  // Opcional: buscar só pelo nome (sem tag)
  Future<Map<String, dynamic>> getSummonerByName({
    required String name,
    PlatformHost platform = PlatformHost.br1,
  }) async {
    final url =
        '${platformBase(platform)}/lol/summoner/v4/summoners/by-name/$name';
    final res = await _dio.get(url);
    return Map<String, dynamic>.from(res.data);
  }

  Future<List<String>> getMatchIdsByPuuid({
    required String puuid,
    RegionHost region = RegionHost.americas,
    int start = 0,
    int count = 10,
  }) async {
    final url =
        '${regionBase(region)}/lol/match/v5/matches/by-puuid/$puuid/ids?start=$start&count=$count';
    final res = await _dio.get(url);
    return (res.data as List).cast<String>();
  }

  // 🔧 ESTE método precisa estar DENTRO da classe para usar _dio
  Future<Map<String, dynamic>> getMatchDetail({
    required String matchId,
    RegionHost region = RegionHost.americas,
  }) async {
    final url = '${regionBase(region)}/lol/match/v5/matches/$matchId';
    final res = await _dio.get(url);
    return Map<String, dynamic>.from(res.data);
  }
}
