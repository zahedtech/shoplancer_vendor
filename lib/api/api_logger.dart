import 'dart:convert';
import 'package:flutter/foundation.dart';

class ApiLogger {
  static const bool _logBodies = bool.fromEnvironment(
    'API_LOG_BODY',
    defaultValue: false,
  );

  // Header names whose values must never be printed in full (auth/session secrets).
  static const Set<String> _sensitiveHeaderKeys = {
    'authorization',
    'cookie',
    'set-cookie',
  };

  // Body field names that carry secrets and should be redacted from logs.
  static const Set<String> _sensitiveBodyKeys = {
    'password',
    'confirm_password',
    'old_password',
    'token',
    'access_token',
    'refresh_token',
    'card_number',
    'cvv',
    'pin',
  };

  static void logRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    dynamic body,
  }) {
    if (kDebugMode) {
      debugPrint(
        '╔════════════════════════════════════════════════════════════════════════════',
      );
      debugPrint('║ 🚀 Request: $method');
      debugPrint('║ 🔗 URL: $url');
      if (headers != null && headers.isNotEmpty) {
        debugPrint('║ 📄 Headers:');
        headers.forEach((key, value) {
          debugPrint('║    $key: ${_redactHeader(key, value)}');
        });
      }
      if (_logBodies && body != null) {
        debugPrint('║ 📦 Body:');
        _logJson(_redactBody(body));
      }
      debugPrint(
        '╚════════════════════════════════════════════════════════════════════════════',
      );
    }
  }

  static void logResponse({
    required String url,
    required int statusCode,
    Map<String, String>? headers,
    dynamic body,
  }) {
    if (kDebugMode) {
      String statusIcon = statusCode >= 200 && statusCode < 300 ? '✅' : '❌';
      debugPrint(
        '╔════════════════════════════════════════════════════════════════════════════',
      );
      debugPrint('║ $statusIcon Response: $statusCode');
      debugPrint('║ 🔗 URL: $url');
      if (headers != null && headers.isNotEmpty) {
        debugPrint('║ 📄 Headers:');
        headers.forEach((key, value) {
          debugPrint('║    $key: ${_redactHeader(key, value)}');
        });
      }
      if (_logBodies && body != null) {
        debugPrint('║ 📦 Body:');
        _logJson(_redactBody(body));
      }
      debugPrint(
        '╚════════════════════════════════════════════════════════════════════════════',
      );
    }
  }

  static String _redactHeader(String key, String value) {
    return _sensitiveHeaderKeys.contains(key.toLowerCase())
        ? '***redacted***'
        : value;
  }

  /// Returns a deep copy of [body] with sensitive keys masked so secrets
  /// (passwords, tokens, card data...) never hit the console/log output.
  static dynamic _redactBody(dynamic body) {
    if (body is Map) {
      return body.map((key, value) {
        final String keyStr = key.toString();
        if (_sensitiveBodyKeys.contains(keyStr.toLowerCase())) {
          return MapEntry(keyStr, '***redacted***');
        }
        return MapEntry(keyStr, _redactBody(value));
      });
    }
    if (body is List) {
      return body.map(_redactBody).toList();
    }
    return body;
  }

  static void _logJson(dynamic json) {
    try {
      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      String prettyJson = encoder.convert(json);
      List<String> lines = prettyJson.split('\n');
      for (String line in lines) {
        debugPrint('║    $line');
      }
    } catch (e) {
      debugPrint('║    $json');
    }
  }
}
