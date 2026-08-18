import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage.dart';
import 'api_endpoints.dart';

/// Dio-based HTTP client with JWT token injection and refresh interceptor.
class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 90),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(_AuthInterceptor());
    _dio.interceptors.add(_FallbackUrlInterceptor());
    _dio.interceptors.add(_LoggingInterceptor());
  }

  Dio get dio => _dio;

  // ─── GET ────────────────────────────────────────────────
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return _dio.get(path, queryParameters: queryParameters);
  }

  // ─── POST ───────────────────────────────────────────────
  Future<Response> post(String path, {dynamic data}) async {
    return _dio.post(path, data: data);
  }

  // ─── PUT ────────────────────────────────────────────────
  Future<Response> put(String path, {dynamic data}) async {
    return _dio.put(path, data: data);
  }

  // ─── PATCH ──────────────────────────────────────────────
  Future<Response> patch(String path, {dynamic data}) async {
    return _dio.patch(path, data: data);
  }

  // ─── DELETE ─────────────────────────────────────────────
  Future<Response> delete(String path) async {
    return _dio.delete(path);
  }
}

/// Intercepts requests to inject the JWT access token.
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await SecureStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Attempt token refresh
      try {
        final refreshToken = await SecureStorage.getRefreshToken();
        if (refreshToken == null) {
          return handler.next(err);
        }

        final refreshDio = Dio(BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ));
        final response = await refreshDio.post(
          ApiEndpoints.authRefresh,
          data: {'refreshToken': refreshToken},
        );

        final newAccessToken = response.data['data']['accessToken'] as String;
        final newRefreshToken = response.data['data']['refreshToken'] as String;

        await SecureStorage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        // Retry the original request
        err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await Dio().fetch(err.requestOptions);
        return handler.resolve(retryResponse);
      } catch (e) {
        await SecureStorage.clearAll();
        return handler.next(err);
      }
    }
    handler.next(err);
  }
}

/// Fallback interceptor to retry requests on host PC Wi-Fi IP / ADB localhost seamlessly.
class _FallbackUrlInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.type == DioExceptionType.connectionError || err.type == DioExceptionType.connectionTimeout) {
      final currentUrl = err.requestOptions.baseUrl;
      String? fallbackUrl;

      if (currentUrl.contains('172.20.129.223')) {
        fallbackUrl = currentUrl.replaceAll('172.20.129.223', '127.0.0.1');
      } else if (currentUrl.contains('127.0.0.1')) {
        fallbackUrl = currentUrl.replaceAll('127.0.0.1', '172.20.129.223');
      }

      if (fallbackUrl != null) {
        try {
          if (kDebugMode) {
            debugPrint('[API FALLBACK] Retrying ${err.requestOptions.path} on: $fallbackUrl');
          }
          err.requestOptions.baseUrl = fallbackUrl;
          final retryResponse = await Dio().fetch(err.requestOptions);
          return handler.resolve(retryResponse);
        } catch (_) {
          // Pass through
        }
      }
    }
    handler.next(err);
  }
}

/// Logs requests and responses in debug mode.
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[API] ${options.method} ${options.path}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[API] ${response.statusCode} ${response.requestOptions.path}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[API ERROR] ${err.response?.statusCode} ${err.requestOptions.path}: ${err.message}');
    }
    handler.next(err);
  }
}

/// Global Riverpod provider for ApiClient.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
