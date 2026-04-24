import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Tylko do sesji debug (NDJSON do serwera lokalnego). Bez PII: nie loguj pełnych numerów/tokenów.
// #region agent log
void debugAgentLog(
  String hypothesisId,
  String location,
  String message, [
  Map<String, Object?>? data,
]) {
  if (kIsWeb) {
    debugPrint(
      jsonEncode({
        'sessionId': 'd16aa6',
        'hypothesisId': hypothesisId,
        'location': location,
        'message': message,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }),
    );
    return;
  }
  final payload = <String, Object?>{
    'sessionId': 'd16aa6',
    'hypothesisId': hypothesisId,
    'location': location,
    'message': message,
    'data': data ?? <String, Object?>{},
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };
  final line = jsonEncode(payload);
  Future<void> send() async {
    try {
      final c = HttpClient();
      final req = await c.postUrl(
        Uri.parse('http://127.0.0.1:7494/ingest/2f6b422f-aec9-49a4-a825-f40a0cec71ea'),
      );
      req.headers.set('Content-Type', 'application/json');
      req.headers.set('X-Debug-Session-Id', 'd16aa6');
      req.write(line);
      await req.close();
    } catch (e) {
      debugPrint('[debugAgentLog fallback] $line err=$e');
    }
  }

  // ignore: unawaited_futures
  send();
}
// #endregion
