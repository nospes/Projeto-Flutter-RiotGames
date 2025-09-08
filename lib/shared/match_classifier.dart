//Classificação customizdas de desempenho
import 'dart:math' as math;

String classifyPlayerInMatch({
  required Map<String, dynamic> match,
  required Map<String, dynamic> me,
}) {
  //Carregamento dos dados
  final info =
      (match['info'] ?? const <String, dynamic>{}) as Map<String, dynamic>;
  final participants = List<Map<String, dynamic>>.from(
    (info['participants'] ?? const <dynamic>[]) as List,
  );
  final durationSec = (info['gameDuration'] is num)
      ? (info['gameDuration'] as num).toInt()
      : 0;
  final win = (me['win'] ?? false) as bool;

  int getInt(Map<String, dynamic> p, String key) =>
      (p[key] is num) ? (p[key] as num).toInt() : 0;
  double safeDiv(num a, num b) => b == 0 ? 0.0 : a / b;

  final myKills = getInt(me, 'kills');
  final myDeaths = math.max(0, getInt(me, 'deaths'));
  final myAssists = getInt(me, 'assists');
  final myKda = safeDiv(myKills + myAssists, math.max(1, myDeaths));

  final myCs =
      getInt(me, 'totalMinionsKilled') + getInt(me, 'neutralMinionsKilled');
  final myCspm = durationSec > 0 ? myCs / (durationSec / 60.0) : 0.0;

  final myDmg = getInt(me, 'totalDamageDealtToChampions');

  // time do jogador e somatória de kills do time para kill participation
  final myTeamId = getInt(me, 'teamId');
  final teamMates = participants
      .where((p) => getInt(p, 'teamId') == myTeamId)
      .toList();
  final teamKills = teamMates.fold<int>(
    0,
    (acc, p) => acc + getInt(p, 'kills'),
  );
  final myKP = safeDiv(myKills + myAssists, math.max(1, teamKills));

  // Participação de objetivos
  final myObjectives =
      getInt(me, 'dragonKills') +
      getInt(me, 'baronKills') +
      getInt(me, 'turretTakedowns') +
      getInt(me, 'inhibitorTakedowns');

  final allCspm = participants.map((p) {
    final cs =
        getInt(p, 'totalMinionsKilled') + getInt(p, 'neutralMinionsKilled');
    return durationSec > 0 ? cs / (durationSec / 60.0) : 0.0;
  });
  final allKda = participants.map((p) {
    final k = getInt(p, 'kills'),
        d = math.max(1, getInt(p, 'deaths')),
        a = getInt(p, 'assists');
    return (k + a) / d;
  });
  final allDmg = participants.map(
    (p) => getInt(p, 'totalDamageDealtToChampions'),
  );

  //Classificação

  final isTopCspm = myCspm >= (allCspm.isEmpty ? 0 : allCspm.reduce(math.max));
  final isTopKda = myKda >= (allKda.isEmpty ? 0 : allKda.reduce(math.max));
  final isTopDmg = myDmg >= (allDmg.isEmpty ? 0 : allDmg.reduce(math.max));

  if (win) {
    if ((myKda >= 4.5 && myKP >= 0.60 && (myObjectives >= 1 || isTopDmg)) ||
        (isTopDmg && myKP >= 0.55)) {
      return 'Protagonista';
    }
    if (isTopCspm && myCspm >= 7.0) {
      return 'Fazendeiro';
    }
    if (myKda >= 2.2 &&
        myKda <= 3.5 &&
        myKP >= 0.45 &&
        myKP <= 0.58 &&
        isTopDmg) {
      return 'Atrasado';
    }
    return 'Carregado';
  } else {
    if ((isTopDmg && myKda >= 3.0) || (isTopKda && myDmg > 0)) {
      return 'Vilão';
    }
    if (myKda >= 3.0 || myKP >= 0.60) {
      return 'Azarado';
    }
    if (myKda >= 1.7 && myKda <= 2.5 && myKP >= 0.35 && myKP <= 0.55) {
      return 'Apático';
    }
    return 'Inimigo';
  }
}
