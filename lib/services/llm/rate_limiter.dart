import 'dart:async';

class RateLimitExceeded implements Exception {
  final String message;
  final Duration retryAfter;

  const RateLimitExceeded(this.message, this.retryAfter);

  @override
  String toString() => message;
}

class RateLimiter {
  final int maxRequestsPerMinute;
  final int maxTokensPerMinute;

  int _requestsThisMinute = 0;
  int _tokensThisMinute = 0;
  DateTime _windowStart = DateTime.now();

  final List<DateTime> _requestTimestamps = [];

  RateLimiter({
    this.maxRequestsPerMinute = 30,
    this.maxTokensPerMinute = 90000,
  });

  Future<void> waitIfNeeded({int estimatedTokens = 0}) async {
    _resetWindowIfNeeded();

    if (_requestsThisMinute >= maxRequestsPerMinute) {
      final retryAfter = Duration(
        milliseconds: DateTime.now()
            .difference(_windowStart)
            .inMilliseconds +
            60000,
      );
      throw RateLimitExceeded(
        'Límite de solicitudes alcanzado ($maxRequestsPerMinute/min). '
        'Espera unos segundos.',
        retryAfter,
      );
    }

    final tokensAfter = _tokensThisMinute + estimatedTokens;
    if (tokensAfter > maxTokensPerMinute) {
      final retryAfter = Duration(
        milliseconds: DateTime.now()
            .difference(_windowStart)
            .inMilliseconds +
            60000,
      );
      throw RateLimitExceeded(
        'Límite de tokens alcanzado ($maxTokensPerMinute/min). '
        'Reduce el tamaño del mensaje.',
        retryAfter,
      );
    }

    _enforceMinInterval();

    _requestsThisMinute++;
    _tokensThisMinute += estimatedTokens;
    _requestTimestamps.add(DateTime.now());
  }

  void _resetWindowIfNeeded() {
    final now = DateTime.now();
    if (now.difference(_windowStart).inMinutes >= 1) {
      _windowStart = now;
      _requestsThisMinute = 0;
      _tokensThisMinute = 0;
    }
  }

  void _enforceMinInterval() {
    final now = DateTime.now();
    _requestTimestamps.removeWhere(
      (t) => now.difference(t).inSeconds > 60,
    );

    if (_requestTimestamps.length >= 3) {
      final oldest = _requestTimestamps.first;
      final elapsed = now.difference(oldest);
      if (elapsed.inMilliseconds < 2000) {
        final wait = Duration(milliseconds: 2000 - elapsed.inMilliseconds);
        // No bloqueamos, solo registramos — el rate limiting real
        // ocurre en el chequeo de maxRequestsPerMinute
      }
    }
  }

  void reset() {
    _requestsThisMinute = 0;
    _tokensThisMinute = 0;
    _windowStart = DateTime.now();
    _requestTimestamps.clear();
  }
}
