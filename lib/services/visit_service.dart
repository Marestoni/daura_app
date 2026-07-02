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

  // ✅ NOVO MÉTODO: Buscar visita por ID
  Future<VisitModel> getVisitById(String visitId) async {
    try {
      final token = await _storage.getToken();

      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      final uri = Uri.parse('${Constants.baseUrl}/visits/$visitId');

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
        return VisitModel.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Sessão expirada. Faça login novamente.');
      } else if (response.statusCode == 404) {
        throw Exception('Visita não encontrada');
      } else {
        throw Exception('Erro ao carregar detalhes da visita');
      }
    } on http.ClientException catch (e) {
      print('❌ Erro de conexão: $e');
      throw Exception('Erro de conexão com o servidor');
    } catch (e) {
      print('❌ Erro geral: $e');
      rethrow;
    }
  }

  // ✅ NOVO MÉTODO: Atualizar visita (PUT)
  Future<VisitModel> updateVisit({
    required String visitId,
    required String addressId,
    required String visitorId,
    required String campaignId,
    String? scheduledDate,
    required String status,
    String? attempt,
    String? observation,
    int? visitOrder,
    String? attendedBy,
    String? situation,
    Map<String, dynamic>? formData,
    Map<String, dynamic>? answers,
  }) async {
    try {
      final token = await _storage.getToken();

      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      final uri = Uri.parse('${Constants.baseUrl}/visits/$visitId');
      print('scheduledDate: $scheduledDate');
      // ✅ Construir o body da requisição
      final body = {
        'addressId': addressId,
        'visitorId': visitorId,
        'campaignId': campaignId,
        if (scheduledDate != null && scheduledDate.isNotEmpty)
          'scheduledDate': scheduledDate,
        'status': status,
        if (attempt != null) 'attempt': attempt,
        if (observation != null && observation.isNotEmpty)
          'observation': observation,
        if (visitOrder != null) 'visitOrder': visitOrder,
        if (attendedBy != null && attendedBy.isNotEmpty)
          'attendedBy': attendedBy,
        if (situation != null && situation.isNotEmpty) 'situation': situation,
        if (formData != null) 'formData': formData,
        if (answers != null) 'answers': answers,
      };

      print('📡 PUT: $uri');
      print('📡 Body: $body');

      final response = await _client.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return VisitModel.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Sessão expirada. Faça login novamente.');
      } else if (response.statusCode == 404) {
        throw Exception('Visita não encontrada');
      } else {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? 'Erro ao atualizar visita';
        throw Exception(message);
      }
    } on http.ClientException catch (e) {
      print('❌ Erro de conexão: $e');
      throw Exception('Erro de conexão com o servidor');
    } catch (e) {
      print('❌ Erro geral: $e');
      rethrow;
    }
  }

  // ✅ NOVO MÉTODO: Iniciar visita (POST /visits/{id}/start)
  Future<VisitModel> startVisit(String visitId) async {
    try {
      final token = await _storage.getToken();

      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      final uri = Uri.parse('${Constants.baseUrl}/visits/$visitId/start');

      print('📡 POST: $uri');

      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Status: ${response.statusCode}');
      print('📡 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return VisitModel.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Sessão expirada. Faça login novamente.');
      } else if (response.statusCode == 404) {
        throw Exception('Visita não encontrada');
      } else {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? 'Erro ao iniciar visita';
        throw Exception(message);
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
