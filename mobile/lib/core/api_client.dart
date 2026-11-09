import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.errors = const {}});

  final String message;
  final int? statusCode;
  final Map<String, List<String>> errors;

  /// First validation error if there is one, otherwise the main message.
  String get displayMessage =>
      errors.values.expand((e) => e).firstOrNull ?? message;

  @override
  String toString() => displayMessage;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? token;

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final params = query?.map((k, v) => MapEntry(k, v.toString()));
    return Uri.parse('$apiBaseUrl$path').replace(queryParameters: params);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _client.get(_uri(path, query), headers: _headers));

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) => _send(
        () => _client.post(_uri(path),
            headers: _headers, body: jsonEncode(body ?? {})),
      );

  Future<dynamic> put(String path, Map<String, dynamic> body) => _send(
        () => _client.put(_uri(path), headers: _headers, body: jsonEncode(body)),
      );

  Future<dynamic> patch(String path, Map<String, dynamic> body) => _send(
        () => _client.patch(_uri(path), headers: _headers, body: jsonEncode(body)),
      );

  Future<dynamic> delete(String path) =>
      _send(() => _client.delete(_uri(path), headers: _headers));

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request().timeout(const Duration(seconds: 20));
    } catch (_) {
      throw ApiException('Could not reach the server. Check your connection.');
    }

    final body = response.body.isEmpty ? null : jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final map = body is Map<String, dynamic> ? body : <String, dynamic>{};
    final rawErrors = map['errors'];
    final errors = <String, List<String>>{};
    if (rawErrors is Map) {
      rawErrors.forEach((key, value) {
        errors[key.toString()] =
            (value as List).map((e) => e.toString()).toList();
      });
    }

    throw ApiException(
      map['message']?.toString() ?? 'Something went wrong (${response.statusCode}).',
      statusCode: response.statusCode,
      errors: errors,
    );
  }
}
