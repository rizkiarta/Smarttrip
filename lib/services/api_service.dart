import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';

import 'package:flutter/foundation.dart';
import 'auth_storage.dart';
import 'push_notification_service.dart';

class ApiService {
  static final ApiService instance = ApiService._internal();
  ApiService._internal() {
    _initDio();
  }

  static const String productionBaseUrl = 'https://andika-porto.my.id/api/v1/';

  // Base URL backend Laravel (Di-set langsung ke domain produksi)
  static String baseUrl = productionBaseUrl;

  late final Dio _dio;
  String? _token;

  String? get token => _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  static const Duration _timeout = Duration(seconds: 10);

  static String _ensureTrailingSlash(String url) {
    final trimmed = url.trim();
    return trimmed.endsWith('/') ? trimmed : '$trimmed/';
  }

  static String _cleanEndpoint(String endpoint) {
    final trimmed = endpoint.trim();
    return trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
  }

  void _initDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _ensureTrailingSlash(baseUrl),
        connectTimeout: _timeout,
        receiveTimeout: _timeout,
        sendTimeout: _timeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Interceptor for logging & dynamic Authorization header insertion
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.baseUrl = _ensureTrailingSlash(baseUrl);
          if (_token != null && _token!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          debugPrint('🌐 [DIO ${options.method}] => ${options.uri}');
          if (options.data != null && options.data is! FormData) {
            debugPrint('   Payload: ${options.data}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('📩 [DIO Response] [${response.requestOptions.method} ${response.requestOptions.path}] Status: ${response.statusCode}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          debugPrint('⚠️ [DIO Error] [${e.requestOptions.method} ${e.requestOptions.path}] Type: ${e.type} | Message: ${e.message}');
          return handler.next(e);
        },
      ),
    );
  }

  static void setBaseUrl(String newUrl) {
    baseUrl = _ensureTrailingSlash(newUrl);
    instance._dio.options.baseUrl = baseUrl;
    debugPrint('🌐 [BASE URL CHANGED] => $baseUrl');
  }

  void setToken(String? token) {
    _token = token;
    if (token != null && token.isNotEmpty) {
      AuthStorage.saveToken(token);
      PushNotificationService.instance.registerFcmToken();
    } else {
      AuthStorage.clearToken();
    }
    debugPrint('🔑 [API TOKEN UPDATED] => ${token != null ? "${token.substring(0, min(15, token.length))}..." : "null"}');
  }


  // ============================================================
  // DIO HTTP METHODS
  // ============================================================

  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    final path = _cleanEndpoint(endpoint);
    try {
      final response = await _dio.get(path, queryParameters: queryParams);
      return response.data;
    } on DioException catch (e) {
      _handleDioError('GET', path, e);
    } catch (e) {
      _logGeneralException('GET', path, e);
    }
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    final path = _cleanEndpoint(endpoint);
    try {
      final response = await _dio.post(path, data: body);
      return response.data;
    } on DioException catch (e) {
      _handleDioError('POST', path, e);
    } catch (e) {
      _logGeneralException('POST', path, e);
    }
  }

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    final path = _cleanEndpoint(endpoint);
    try {
      final response = await _dio.put(path, data: body);
      return response.data;
    } on DioException catch (e) {
      _handleDioError('PUT', path, e);
    } catch (e) {
      _logGeneralException('PUT', path, e);
    }
  }

  Future<dynamic> patch(String endpoint, {Map<String, dynamic>? body}) async {
    final path = _cleanEndpoint(endpoint);
    try {
      final response = await _dio.patch(path, data: body);
      return response.data;
    } on DioException catch (e) {
      _handleDioError('PATCH', path, e);
    } catch (e) {
      _logGeneralException('PATCH', path, e);
    }
  }

  Future<dynamic> delete(String endpoint) async {
    final path = _cleanEndpoint(endpoint);
    try {
      final response = await _dio.delete(path);
      return response.data;
    } on DioException catch (e) {
      _handleDioError('DELETE', path, e);
    } catch (e) {
      _logGeneralException('DELETE', path, e);
    }
  }

  // Multipart upload optimized with Dio FormData
  Future<dynamic> multipartPost(
    String endpoint, {
    Map<String, String>? fields,
    String? fileField,
    File? file,
    List<File>? files,
  }) async {
    final path = _cleanEndpoint(endpoint);
    final formData = FormData();

    if (fields != null) {
      fields.forEach((k, v) => formData.fields.add(MapEntry(k, v)));
    }

    if (fileField != null && file != null) {
      formData.files.add(MapEntry(
        fileField,
        await MultipartFile.fromFile(
          file.path,
          filename: file.path.split(Platform.pathSeparator).last,
        ),
      ));
    }

    if (files != null && files.isNotEmpty) {
      for (final f in files) {
        formData.files.add(MapEntry(
          'photos[]',
          await MultipartFile.fromFile(
            f.path,
            filename: f.path.split(Platform.pathSeparator).last,
          ),
        ));
      }
    }

    try {
      final response = await _dio.post(path, data: formData);
      return response.data;
    } on DioException catch (e) {
      _handleDioError('MULTIPART', path, e);
    } catch (e) {
      _logGeneralException('MULTIPART', path, e);
    }
  }

  // ============================================================
  // ERROR HANDLING & PARSING
  // ============================================================

  Never _handleDioError(String method, String endpoint, DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      debugPrint('⏳ [DIO TIMEOUT] [$method $endpoint]');
      throw ApiException('Koneksi tidak stabil. Silakan periksa jaringan Anda dan coba lagi.');
    }

    if (e.type == DioExceptionType.connectionError || e.error is SocketException) {
      debugPrint('🔌 [DIO CONNECTION ERROR] [$method $endpoint]: ${e.message}');
      throw ApiException('Tidak dapat terhubung ke layanan. Silakan periksa koneksi internet Anda atau coba beberapa saat lagi.');
    }

    if (e.response != null) {
      final response = e.response!;
      final statusCode = response.statusCode ?? 400;
      final data = response.data;

      String message = statusCode >= 500
          ? 'Terjadi kendala pada server. Silakan coba beberapa saat lagi.'
          : 'Permintaan gagal diproses ($statusCode)';

      if (data is Map<String, dynamic>) {
        if (data['errors'] != null && data['errors'] is Map) {
          final Map errors = data['errors'];
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            message = firstError.first.toString();
          } else if (firstError is String) {
            message = firstError;
          }
        } else {
          message = data['message'] ?? data['error'] ?? message;
        }
      }

      if (statusCode == 429 || message.toLowerCase().contains('too many attempts')) {
        message = 'Permintaan pembuatan rencana perjalanan sedang padat. Silakan coba beberapa saat lagi.';
      } else if (message == 'validation.unique') {
        message = 'Email atau username sudah terdaftar. Silakan gunakan email lain atau langsung masuk.';
      } else if (message.toLowerCase().contains('invalid credentials') ||
          message.toLowerCase().contains('unauthorized')) {
        message = 'Email/Username atau kata sandi tidak sesuai.';
      }

      debugPrint('⚠️ [DIO Response Error] [$method $endpoint] Code: $statusCode | Msg: $message');
      throw ApiException(message, statusCode, data);
    }

    debugPrint('❌ [DIO Unknown Exception] [$method $endpoint]: ${e.message}');
    throw ApiException('Terjadi kendala pada layanan. Silakan coba beberapa saat lagi.');
  }

  Never _logGeneralException(String method, String endpoint, Object e) {
    if (e is ApiException) throw e;
    debugPrint('❌ [API General Exception] [$method $endpoint]: $e');
    throw ApiException('Terjadi kendala pada layanan. Silakan coba beberapa saat lagi.');
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final dynamic body;

  ApiException(this.message, [this.statusCode = 400, this.body]);

  @override
  String toString() => message;
}
