const riotApiKey = String.fromEnvironment('RIOT_API_KEY');

void ensureApiKey() {
  if (riotApiKey.isEmpty) {
    throw StateError(
      'RIOT_API_KEY não foi definida. Rode com --dart-define=RIOT_API_KEY=...'
    );
  }
}
