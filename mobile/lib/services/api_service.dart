import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';

class ApiService {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(String endpoint, {Map<String, String>? queryParams}) async {
    Uri url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      url = url.replace(queryParameters: queryParams);
    }
    final headers = await getHeaders();
    return http.get(url, headers: headers);
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await getHeaders();
    return http.post(url, headers: headers, body: jsonEncode(body));
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await getHeaders();
    return http.put(url, headers: headers, body: jsonEncode(body));
  }

  static Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await getHeaders();
    return http.delete(url, headers: headers);
  }

  /// Multipart upload for submitting assignment with file or event media
  static Future<http.Response> uploadMultipart(
    String endpoint, {
    Map<String, String>? fields,
    File? file,
    String fileField = 'file',
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final token = await getToken();
    final request = http.MultipartRequest('POST', url);

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    if (fields != null) {
      request.fields.addAll(fields);
    }

    if (file != null) {
      final multipartFile = await http.MultipartFile.fromPath(fileField, file.path);
      request.files.add(multipartFile);
    }

    final streamedResponse = await request.send();
    return http.Response.fromStream(streamedResponse);
  }
}
