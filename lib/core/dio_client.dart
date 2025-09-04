import 'package:dio/dio.dart';
import 'env.dart';

Dio buildDio() {
  ensureApiKey();
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (opts, handler) {
      opts.headers['X-Riot-Token'] = riotApiKey; // cabeçalho correto
      handler.next(opts);
    },
    onError: (e, handler) async {
      // tratamento simples para 429 (rate limit)
      if (e.response?.statusCode == 429) {
        final retryAfter =
            int.tryParse(e.response?.headers.value('Retry-After') ?? '1') ?? 1;
        await Future.delayed(Duration(seconds: retryAfter));
        try {
          final clone = await dio.fetch(e.requestOptions);
          return handler.resolve(clone);
        } catch (_) {
          // cai no fluxo padrão abaixo
        }
      }
      handler.next(e);
    },
  ));

  return dio;
}
