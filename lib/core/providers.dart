/// core/providers.dart — providers centrais do app (Dio, DataDragon, RiotApi)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../shared/data_dragon.dart';
import '../features/profile/data/riot_api.dart';

/// HTTP client (com token no header)
final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      headers: {'X-Riot-Token': const String.fromEnvironment('RIOT_API_KEY')},
    ),
  );
});

/// Cliente de assets/versões (Data Dragon)
final dataDragonProvider = Provider<DataDragon>((ref) {
  return DataDragon(ref.watch(dioProvider));
});

/// Cliente da Riot API (endpoints REST)
final riotApiProvider = Provider<RiotApi>((ref) {
  return RiotApi(ref.watch(dioProvider));
});
