import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shoplancer_vendor/api/api_checker.dart';
import 'package:shoplancer_vendor/common/models/error_response.dart';
import 'package:shoplancer_vendor/util/app_constants.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' as foundation;
import 'package:shoplancer_vendor/api/api_logger.dart';

class ApiClient extends GetxService {
  final String appBaseUrl;
  final SharedPreferences sharedPreferences;
  static const String noInternetMessage =
      'Connection to API server failed due to internet connection';
  final int timeoutInSeconds = 30;

  String? token;
  String? type;
  late Map<String, String> _mainHeaders;
  static DateTime? _firstRequestAt;
  static int _requestSequence = 0;
  static int _activeRequests = 0;

  ApiClient({required this.appBaseUrl, required this.sharedPreferences}) {
    token = sharedPreferences.getString(AppConstants.token);
    type = sharedPreferences.getString(AppConstants.type);
    updateHeader(
      token,
      sharedPreferences.getString(AppConstants.languageCode),
      null,
      type,
    );
  }

  void updateHeader(
    String? token,
    String? languageCode,
    int? moduleID,
    String? type,
  ) {
    _mainHeaders = {
      'Content-Type': 'application/json; charset=UTF-8',
      AppConstants.localizationKey:
          languageCode ?? AppConstants.languages[0].languageCode!,
      AppConstants.moduleId: moduleID != null ? moduleID.toString() : '',
      'Authorization': 'Bearer $token',
      'vendorType': type ?? '',
    };
  }

  Future<Response> getData(
    String uri, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    bool handleError = true,
  }) async {
    final timing = _startTiming('GET', appBaseUrl + uri);
    try {
      ApiLogger.logRequest(
        method: 'GET',
        url: appBaseUrl + uri,
        headers: headers ?? _mainHeaders,
      );
      http.Response response = await http
          .get(Uri.parse(appBaseUrl + uri), headers: headers ?? _mainHeaders)
          .timeout(Duration(seconds: timeoutInSeconds));
      return handleResponse(response, uri, handleError, timing: timing);
    } catch (e) {
      _finishTiming(timing, label: 'ERROR', statusCode: 1);
      return const Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  Future<Response> postData(
    String uri,
    dynamic body, {
    Map<String, String>? headers,
    bool handleError = true,
  }) async {
    final timing = _startTiming('POST', appBaseUrl + uri);
    try {
      ApiLogger.logRequest(
        method: 'POST',
        url: appBaseUrl + uri,
        headers: headers ?? _mainHeaders,
        body: body,
      );
      http.Response response = await http
          .post(
            Uri.parse(appBaseUrl + uri),
            body: jsonEncode(body),
            headers: headers ?? _mainHeaders,
          )
          .timeout(Duration(seconds: timeoutInSeconds));
      return handleResponse(response, uri, handleError, timing: timing);
    } catch (e) {
      _finishTiming(timing, label: 'ERROR', statusCode: 1);
      return const Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  Future<Response> postMultipartData(
    String uri,
    Map<String, String> body,
    List<MultipartBody> multipartBody, {
    List<MultipartDocument>? multipartDocument,
    Map<String, String>? headers,
    bool handleError = true,
  }) async {
    final timing = _startTiming('POST (Multipart)', appBaseUrl + uri);
    try {
      ApiLogger.logRequest(
        method: 'POST (Multipart)',
        url: appBaseUrl + uri,
        headers: headers ?? _mainHeaders,
        body: body,
      );
      http.MultipartRequest request = http.MultipartRequest(
        'POST',
        Uri.parse(appBaseUrl + uri),
      );
      request.headers.addAll(headers ?? _mainHeaders);
      for (MultipartBody multipart in multipartBody) {
        if (multipart.file != null) {
          if (foundation.kIsWeb) {
            Uint8List list = await multipart.file!.readAsBytes();
            http.MultipartFile part = http.MultipartFile(
              multipart.key,
              multipart.file!.readAsBytes().asStream(),
              list.length,
              filename: basename(multipart.file!.path),
              contentType: MediaType('image', 'jpg'),
            );
            request.files.add(part);
          } else {
            File file = File(multipart.file!.path);
            request.files.add(
              http.MultipartFile(
                multipart.key,
                file.readAsBytes().asStream(),
                file.lengthSync(),
                filename: file.path.split('/').last,
              ),
            );
          }
        }
      }

      if (multipartDocument != null && multipartDocument.isNotEmpty) {
        for (MultipartDocument file in multipartDocument) {
          File other = File(file.file!.files.single.path!);
          Uint8List list0 = await other.readAsBytes();
          var part = http.MultipartFile(
            file.key,
            other.readAsBytes().asStream(),
            list0.length,
            filename: basename(other.path),
          );
          request.files.add(part);
        }
      }

      request.fields.addAll(body);
      http.Response response = await http.Response.fromStream(
        await request.send(),
      );
      return handleResponse(response, uri, handleError, timing: timing);
    } catch (e) {
      _finishTiming(timing, label: 'ERROR', statusCode: 1);
      return const Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  Future<Response> putData(
    String uri,
    dynamic body, {
    Map<String, String>? headers,
    bool handleError = true,
  }) async {
    final timing = _startTiming('PUT', appBaseUrl + uri);
    try {
      ApiLogger.logRequest(
        method: 'PUT',
        url: appBaseUrl + uri,
        headers: headers ?? _mainHeaders,
        body: body,
      );
      http.Response response = await http
          .put(
            Uri.parse(appBaseUrl + uri),
            body: jsonEncode(body),
            headers: headers ?? _mainHeaders,
          )
          .timeout(Duration(seconds: timeoutInSeconds));
      return handleResponse(response, uri, handleError, timing: timing);
    } catch (e) {
      _finishTiming(timing, label: 'ERROR', statusCode: 1);
      return const Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  Future<Response> putFormData(
    String uri,
    Map<String, String> body, {
    Map<String, String>? headers,
    bool handleError = true,
  }) async {
    final timing = _startTiming('PUT (Form)', appBaseUrl + uri);
    final Map<String, String> requestHeaders = {
      ..._mainHeaders,
      if (headers != null) ...headers,
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    try {
      ApiLogger.logRequest(
        method: 'PUT (Form)',
        url: appBaseUrl + uri,
        headers: requestHeaders,
        body: body,
      );
      http.Response response = await http
          .put(Uri.parse(appBaseUrl + uri), body: body, headers: requestHeaders)
          .timeout(Duration(seconds: timeoutInSeconds));
      return handleResponse(response, uri, handleError, timing: timing);
    } catch (e) {
      _finishTiming(timing, label: 'ERROR', statusCode: 1);
      return const Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  Future<Response> deleteData(
    String uri, {
    Map<String, String>? headers,
    dynamic body,
    bool handleError = true,
  }) async {
    final timing = _startTiming('DELETE', appBaseUrl + uri);
    try {
      ApiLogger.logRequest(
        method: 'DELETE',
        url: appBaseUrl + uri,
        headers: headers ?? _mainHeaders,
        body: body,
      );
      http.Response response = await http
          .delete(
            Uri.parse(appBaseUrl + uri),
            headers: headers ?? _mainHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(Duration(seconds: timeoutInSeconds));
      return handleResponse(response, uri, handleError, timing: timing);
    } catch (e) {
      _finishTiming(timing, label: 'ERROR', statusCode: 1);
      return const Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  Response handleResponse(
    http.Response response,
    String uri,
    bool handleError, {
    ApiRequestTiming? timing,
  }) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {}
    Response response0 = Response(
      body: body ?? response.body,
      bodyString: response.body.toString(),
      headers: response.headers,
      statusCode: response.statusCode,
      statusText: response.reasonPhrase,
    );
    bool isSuccess =
        response0.statusCode != null &&
        response0.statusCode! >= 200 &&
        response0.statusCode! < 300;

    if (!isSuccess && response0.body != null && response0.body is! String) {
      if (response0.body.toString().startsWith('{errors: [{code:')) {
        ErrorResponse errorResponse = ErrorResponse.fromJson(response0.body);
        response0 = Response(
          statusCode: response0.statusCode,
          body: response0.body,
          statusText: errorResponse.errors![0].message,
        );
      } else if (response0.body.toString().startsWith('{message')) {
        response0 = Response(
          statusCode: response0.statusCode,
          body: response0.body,
          statusText: response0.body['message'],
        );
      }
    } else if (!isSuccess && response0.body == null) {
      response0 = const Response(statusCode: 0, statusText: noInternetMessage);
    }
    _finishTiming(
      timing,
      label: 'DONE',
      statusCode: response0.statusCode,
      responseBytes: response.bodyBytes.length,
    );
    ApiLogger.logResponse(
      url: appBaseUrl + uri,
      statusCode: response0.statusCode!,
      body: response0.body,
      headers: response0.headers,
    );
    if (handleError) {
      if (isSuccess) {
        return response0;
      } else {
        ApiChecker.checkApi(response0);
        return const Response();
      }
    } else {
      return response0;
    }
  }

  ApiRequestTiming _startTiming(String method, String url) {
    if (!foundation.kDebugMode) {
      return ApiRequestTiming.empty();
    }

    _firstRequestAt ??= DateTime.now();
    _activeRequests++;
    final timing = ApiRequestTiming(
      id: ++_requestSequence,
      method: method,
      url: url,
      startedAt: DateTime.now(),
    );

    foundation.debugPrint(
      '[API-TIME] #${timing.id} START +${_sinceFirstRequest()}ms '
      'active=$_activeRequests $method ${_shortUrl(url)}',
    );
    return timing;
  }

  void _finishTiming(
    ApiRequestTiming? timing, {
    required String label,
    required int? statusCode,
    int? responseBytes,
  }) {
    if (!foundation.kDebugMode || timing == null || timing.isEmpty) return;

    _activeRequests = _activeRequests > 0 ? _activeRequests - 1 : 0;
    foundation.debugPrint(
      '[API-TIME] #${timing.id} $label +${_sinceFirstRequest()}ms '
      'duration=${DateTime.now().difference(timing.startedAt).inMilliseconds}ms '
      'active=$_activeRequests status=${statusCode ?? '-'} '
      'bytes=${responseBytes ?? '-'} '
      '${timing.method} ${_shortUrl(timing.url)}',
    );
  }

  static int _sinceFirstRequest() {
    final firstRequestAt = _firstRequestAt;
    if (firstRequestAt == null) return 0;
    return DateTime.now().difference(firstRequestAt).inMilliseconds;
  }

  static String _shortUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    final path = uri.path.isEmpty ? url : uri.path;
    return uri.query.isEmpty ? path : '$path?${uri.query}';
  }
}

class ApiRequestTiming {
  final int id;
  final String method;
  final String url;
  final DateTime startedAt;
  final bool isEmpty;

  ApiRequestTiming({
    required this.id,
    required this.method,
    required this.url,
    required this.startedAt,
  }) : isEmpty = false;

  ApiRequestTiming.empty()
    : id = 0,
      method = '',
      url = '',
      startedAt = DateTime.fromMillisecondsSinceEpoch(0),
      isEmpty = true;
}

class MultipartBody {
  String key;
  XFile? file;

  MultipartBody(this.key, this.file);
}

class MultipartDocument {
  String key;
  FilePickerResult? file;
  MultipartDocument(this.key, this.file);
}
