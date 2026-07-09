import 'dart:convert';
import 'package:flutter/foundation.dart';

class ApiLogger {
  static void logRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    dynamic body,
  }) {
    if (kDebugMode) {
      print('╔════════════════════════════════════════════════════════════════════════════');
      print('║ 🚀 Request: $method');
      print('║ 🔗 URL: $url');
      if (headers != null && headers.isNotEmpty) {
        print('║ 📄 Headers:');
        headers.forEach((key, value) {
          print('║    $key: $value');
        });
      }
      if (body != null) {
        print('║ 📦 Body:');
        _logJson(body);
      }
      print('╚════════════════════════════════════════════════════════════════════════════');
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
      print('╔════════════════════════════════════════════════════════════════════════════');
      print('║ $statusIcon Response: $statusCode');
      print('║ 🔗 URL: $url');
      if (headers != null && headers.isNotEmpty) {
        print('║ 📄 Headers:');
        headers.forEach((key, value) {
          print('║    $key: $value');
        });
      }
      if (body != null) {
        print('║ 📦 Body:');
        _logJson(body);
      }
      print('╚════════════════════════════════════════════════════════════════════════════');
    }
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
