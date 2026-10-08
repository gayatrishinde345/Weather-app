import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient(this.client);
  final http.Client client;
  Future<Map<String, dynamic>> get(Uri uri) async {
    final response = await client.get(uri).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw ApiException(switch (response.statusCode) {
        401 => 'The weather API key is invalid or not activated.',
        403 => 'This API key does not have access to the requested service.',
        429 => 'Weather request limit reached. Please try again later.',
        _ =>
          'Weather service unavailable (${response.statusCode}). Please retry.',
      });
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
