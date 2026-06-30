import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/campaign_model.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class CampaignService {
  final http.Client _client = http.Client();
  final StorageService _storage = StorageService();

  Future<CampaignResponse> getCampaigns() async {
    try {
      // Buscar token do storage
      final token = await _storage.getToken();

      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      final url = Uri.parse('${Constants.baseUrl}/campaigns');

      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return CampaignResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Sessão expirada. Faça login novamente.');
      } else {
        throw Exception('Erro ao carregar campanhas');
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
