import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/visit_model.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class VisitService {
  final http.Client _client = http.Client();
  final StorageService _storage = StorageService();

  Future<VisitResponse> getVisits({
    required String campaignId,
    required String visitorId,
    String? status,
    String? startDate,
    String? endDate,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final token = await _storage.getToken();

      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      // Construir query params
      final queryParams = <String, String>{
        'visitorId': visitorId,
        'campaignId': campaignId,
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['startDate'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['endDate'] = endDate;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse(
        '${Constants.baseUrl}/visits',
      ).replace(queryParameters: queryParams);

      print('📡 GET: $uri');

      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return VisitResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Sessão expirada. Faça login novamente.');
      } else {
        throw Exception('Erro ao carregar visitas');
      }
    } on http.ClientException catch (e) {
      print('❌ Erro de conexão: $e');
      throw Exception('Erro de conexão com o servidor');
    } catch (e) {
      print('❌ Erro geral: $e');
      rethrow;
    }
  }

  void dispose() {
    _client.close();
  }
}
