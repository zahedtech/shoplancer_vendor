import 'dart:convert';
import 'package:flutter/foundation.dart';

class ApiLogger {
  // Header names whose values must never be printed in full (auth/session secrets).
  static const Set<String> _sensitiveHeaderKeys = {'cookie', 'set-cookie'};

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
      print(
        '╔════════════════════════════════════════════════════════════════════════════',
      );
      print('║ 🚀 Request: $method');
      print('║ 🔗 URL: $url');
      if (headers != null && headers.isNotEmpty) {
        print('║ 📄 Headers:');
        headers.forEach((key, value) {
          print('║    $key: ${_redactHeader(key, value)}');
        });
      }
      if (body != null) {
        print('║ 📦 Body:');
        _logJson(_redactBody(body));
      }
      print(
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
      print(
        '╔════════════════════════════════════════════════════════════════════════════',
      );
      print('║ $statusIcon Response: $statusCode');
      print('║ 🔗 URL: $url');
      if (headers != null && headers.isNotEmpty) {
        print('║ 📄 Headers:');
        headers.forEach((key, value) {
          print('║    $key: ${_redactHeader(key, value)}');
        });
      }
      if (body != null) {
        print('║ 📦 Body:');
        _logJson(_redactBody(body));
      }
      print(
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
        print('║    $line');
      }
    } catch (e) {
      print('║    $json');
    }
  }
}
