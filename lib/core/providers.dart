// lib/core/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../shared/data_dragon.dart';
import '../features/profile/data/riot_api.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    headers: {'X-Riot-Token': const String.fromEnvironment('RIOT_API_KEY')},
  ));
});

final dataDragonProvider = Provider<DataDragon>((ref) {
  return DataDragon(ref.watch(dioProvider));
});

final riotApiProvider = Provider<RiotApi>((ref) {
  return RiotApi(ref.watch(dioProvider));
});
