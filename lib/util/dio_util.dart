import "dart:convert";
import "dart:io";

import "package:dio/dio.dart";
import "package:dio/io.dart";
import "package:dio_cookie_manager/dio_cookie_manager.dart";
import "package:cookie_jar/cookie_jar.dart";

Dio? _dio;
var cookieJar = CookieJar();

class DioUtil {
  static Dio getDio() {
    if (_dio == null) {
      _dio = Dio();
      if (_dio!.httpClientAdapter is IOHttpClientAdapter) {
        (_dio!.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate =
            (final client) {
          client.badCertificateCallback = (final cert, final host, final port) {
            return true;
          };
          return null;
        };
      }

      // _dio!.options.connectTimeout = Duration(minutes: 1);
      // _dio!.options.receiveTimeout = Duration(minutes: 1);
      _dio!.options.headers["user-agent"] =
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.88 Safari/537.36";
      _dio!.options.headers["accept-encoding"] = "gzip";
      final CookieManager cookieManager = CookieManager(cookieJar);
      _dio!.interceptors.add(cookieManager);
    }
    return _dio!;
  }

  static setCookie(final String link, final String key, final String value) {
    cookieJar.saveFromResponse(Uri.parse(link), [Cookie(key, value)]);
  }

  static Future<Map<String, dynamic>?> get(final String link,
      [final Map<String, dynamic>? queryParameters,
      final Map<String, String>? header]) async {
    final dio = getDio();
    if (header != null) {
      dio.options.headers.addAll(header);
    }
    final Response resp = await dio.get(link, queryParameters: queryParameters);
    if (resp.statusCode == 200) {
      if (resp.data is String) {
        return json.decode(resp.data);
      }
      return resp.data;
    } else {
      return null;
    }
  }

  static Future<String?> getStr(final String link,
      [final Map<String, dynamic>? queryParameters,
      final Map<String, String>? header]) async {
    final dio = getDio();
    if (header != null) {
      dio.options.headers.addAll(header);
    }
    final Response resp =
        await dio.get<String>(link, queryParameters: queryParameters);
    if (resp.statusCode == 200) {
      return resp.data;
    } else {
      return null;
    }
  }

  static Future<Map<String, dynamic>> post(
      final String link, final Map<String, dynamic> parameters,
      [final Map<String, String>? header]) async {
    final dio = getDio();
    if (header != null) {
      dio.options.headers.addAll(header);
    }
    final Response resp = await dio.post(link, data: parameters);
    return resp.data;
  }
}
