import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/auth_utils.dart';
import 'package:http/http.dart' as http;
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';

class ApiService {
  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final CookieJar _cookieJar = CookieJar();

  String? _sessionCookie;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  // Helper to get token from storage
  Future<String?> _getToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, String>? customHeaders,
  }) async {
    final authKey = AuthUtils.generateAuthKey();
    final token = await _getToken();
    final headers = <String, String>{
      'authKey': authKey,
      'Content-Type': 'application/json',
      'accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      print('🔑 Token added to POST $path');
    } else {
      print('⚠️ No token for POST $path');
    }

    if (customHeaders != null) {
      headers.addAll(customHeaders);
      print('📤 Custom headers added');
    }

    print('📤 Body: $data');

    final fullUrl = _dio.options.baseUrl + path;
    print('🌐 FULL URL: $fullUrl');
    print('📤 FINAL HEADERS: $headers');

    return await _dio.post(
      path,
      data: data,
      options: Options(headers: headers),
    );
  }

  Future<Response> postForLogin(String path, Map<String, dynamic> data) async {
    final authKey = AuthUtils.generateAuthKey();
    final url = Uri.parse(_dio.options.baseUrl + path);
    final headers = <String, String>{
      'authKey': authKey,
      'Content-Type': 'application/json',
      'accept': 'application/json',
    };
    // No token needed for login
    print('📤 POST Login URL: $url');
    print('📤 POST Login Headers: $headers');
    print('📤 POST Login Body: $data');

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(data),
    );

    print('📥 Login response status: ${response.statusCode}');
    print('📥 Login response body: ${response.body}');

    // Try to parse JSON, fallback to raw string
    dynamic jsonData;
    try {
      jsonData = jsonDecode(response.body);
    } catch (_) {
      jsonData = {'raw': response.body};
    }

    return Response(
      data: jsonData,
      statusCode: response.statusCode,
      requestOptions: RequestOptions(path: path),
    );
  }

  Future<Response> postWithBodyNative(String path, dynamic body) async {
    final authKey = AuthUtils.generateAuthKey();
    final token = await _getToken();
    final url = Uri.parse(_dio.options.baseUrl + path);
    final headers = <String, String>{
      'authKey': authKey,
      'Content-Type': 'application/json',
      'accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    print('📥 Native response status: ${response.statusCode}');
    print('📥 Native response body: ${response.body}');

    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      // If the response is not JSON, store it as raw string.
      data = {'raw': response.body};
      print('⚠️ Response is not valid JSON: ${response.body}');
    }

    return Response(
      data: data,
      statusCode: response.statusCode,
      requestOptions: RequestOptions(path: path),
    );
  }

  Future<Response> postWithoutBody(String path) async {
    final authKey = AuthUtils.generateAuthKey();
    final token = await _getToken();
    final headers = <String, String>{
      'authKey': authKey,
      'accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      print('🔑 Token added to POST (no body) $path');
    } else {
      print('⚠️ No token for POST (no body) $path');
    }
    print('📤 Headers: $headers');

    return await _dio.post(
      path,
      options: Options(headers: headers, contentType: null),
    );
  }

  Future<Response> postWithoutBodyNative(String path) async {
    final authKey = AuthUtils.generateAuthKey();
    final token = await _getToken();
    final url = Uri.parse(_dio.options.baseUrl + path);
    final headers = <String, String>{
      'authKey': authKey,
      'accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    // Add stored cookie if available
    if (_sessionCookie != null) {
      headers['Cookie'] = _sessionCookie!;
    }
    print('📤 Headers: $headers');
    print('🌐 URL: $url');

    final client = http.Client();
    final request = http.Request('POST', url)..headers.addAll(headers);
    final streamedResponse = await client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    client.close();

    // Capture Set-Cookie from the response
    final setCookie = response.headers['set-cookie'];
    if (setCookie != null) {
      _sessionCookie = setCookie;
      print('🍪 Captured cookie: $_sessionCookie');
    }

    print('📥 Native response status: ${response.statusCode}');
    print('📥 Native response body: ${response.body}');

    return Response(
      data: jsonDecode(response.body),
      statusCode: response.statusCode,
      requestOptions: RequestOptions(path: path),
    );
  }

  Future<Response> postWithFormData(
    String path,
    Map<String, dynamic> data,
  ) async {
    final authKey = AuthUtils.generateAuthKey();
    final token = await _getToken();
    final url = Uri.parse(_dio.options.baseUrl + path);
    final headers = <String, String>{
      'authKey': authKey,
      'accept': 'application/json',
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    // Build form data
    final formData = <String, String>{};
    data.forEach((key, value) {
      if (value != null) formData[key] = value.toString();
    });
    final body = formData.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
    print('📤 POST Form URL: $url');
    print('📤 POST Form Headers: $headers');
    print('📤 POST Form Body: $body');
    final response = await http.post(url, headers: headers, body: body);
    print('📥 Form data response status: ${response.statusCode}');
    print('📥 Form data response body: ${response.body}');
    dynamic jsonData;
    try {
      jsonData = jsonDecode(response.body);
    } catch (_) {
      jsonData = {'raw': response.body};
    }
    return Response(
      data: jsonData,
      statusCode: response.statusCode,
      requestOptions: RequestOptions(path: path),
    );
  }

  Future<Response> postFormData(String path, Map<String, String> data) async {
    final authKey = AuthUtils.generateAuthKey();
    final token = await _getToken();
    final url = Uri.parse(_dio.options.baseUrl + path);
    final headers = <String, String>{
      'authKey': authKey,
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    final body = data.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
    final response = await http.post(url, headers: headers, body: body);
    return Response(
      data: jsonDecode(response.body),
      statusCode: response.statusCode,
      requestOptions: RequestOptions(path: path),
    );
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? customHeaders,
  }) async {
    final authKey = AuthUtils.generateAuthKey();
    final headers = <String, String>{
      'authKey': authKey,
      'accept': 'application/json',
    };

    // Retrieve token from storage (if not already in customHeaders)
    String? token;
    if (customHeaders != null && customHeaders.containsKey('Authorization')) {
      token = customHeaders['Authorization']!.replaceFirst('Bearer ', '');
    } else {
      token = await _getToken();
    }

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      print('🔑 Token added to GET $path');
    } else {
      print('⚠️ No token for GET $path');
    }

    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    print('🔥 GET final headers: $headers');
    print('🔥 GET URL: ${_dio.options.baseUrl}$path');
    print('🔥 GET query: $queryParameters');

    return await _dio.get(
      path,
      queryParameters: queryParameters,
      options: Options(headers: headers),
    );
  }

  Future<Response> getNative(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? customHeaders,
  }) async {
    final authKey = AuthUtils.generateAuthKey();
    final token = await _getToken();
    final uri = Uri.parse(
      _dio.options.baseUrl + path,
    ).replace(queryParameters: queryParameters);
    final headers = <String, String>{
      'authKey': authKey,
      'accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (customHeaders != null) headers.addAll(customHeaders);
    if (_sessionCookie != null) {
      headers['Cookie'] = _sessionCookie!;
    }
    print('🌐 GET Native URL: $uri');
    print('📤 GET Native Headers: $headers');

    final client = http.Client();
    final request = http.Request('GET', uri)..headers.addAll(headers);
    final streamedResponse = await client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    client.close();

    final setCookie = response.headers['set-cookie'];
    if (setCookie != null) {
      _sessionCookie = setCookie;
      print('🍪 Captured cookie (GET): $_sessionCookie');
    }

    print('📥 GET Native response status: ${response.statusCode}');
    print('📥 GET Native response body: ${response.body}');

    return Response(
      data: jsonDecode(response.body),
      statusCode: response.statusCode,
      requestOptions: RequestOptions(path: path),
    );
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }

  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }
}
