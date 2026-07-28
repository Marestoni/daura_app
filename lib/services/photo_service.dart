import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'storage_service.dart';

/// Serviço HTTP para envio/exclusão de fotos de visita na API.
class PhotoService {
  final http.Client _client = http.Client();
  final StorageService _storage = StorageService();

  /// Envia uma foto (multipart) para POST /visits/{visitId}/photos.
  /// Retorna os dados da foto criada no servidor.
  Future<Map<String, dynamic>> uploadPhoto({
    required String visitId,
    required String filePath,
  }) async {
    final token = await _storage.getToken();
    if (token == null) {
      throw Exception('Usuário não autenticado');
    }

    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Arquivo da foto não encontrado: $filePath');
    }

    final uri = Uri.parse('${Constants.baseUrl}/visits/$visitId/photos');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'application/json'
      // O campo DEVE se chamar 'photo' (FileInterceptor('photo') na API).
      ..files.add(await http.MultipartFile.fromPath('photo', filePath));

    print('📡 POST (multipart): $uri');

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 401) {
      throw Exception('Sessão expirada. Faça login novamente.');
    } else {
      throw Exception('Erro ao enviar foto (HTTP ${response.statusCode})');
    }
  }

  /// Remove uma foto do servidor (DELETE /visits/photos/{photoId}).
  Future<void> deletePhoto(String serverPhotoId) async {
    final token = await _storage.getToken();
    if (token == null) {
      throw Exception('Usuário não autenticado');
    }

    final uri = Uri.parse('${Constants.baseUrl}/visits/photos/$serverPhotoId');
    final response = await _client.delete(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 ||
        response.statusCode == 204 ||
        response.statusCode == 404) {
      // 404 = já não existe no servidor; tratamos como sucesso idempotente.
      return;
    } else if (response.statusCode == 401) {
      throw Exception('Sessão expirada. Faça login novamente.');
    } else {
      throw Exception('Erro ao remover foto (HTTP ${response.statusCode})');
    }
  }

  void dispose() {
    _client.close();
  }
}
