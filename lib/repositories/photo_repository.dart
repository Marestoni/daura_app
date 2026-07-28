import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../database/database_helper.dart';
import '../services/photo_service.dart';

/// Repositório de fotos com estratégia OFFLINE-FIRST:
/// salva o arquivo no dispositivo e registra localmente; tenta enviar na hora
/// e, se falhar, enfileira para sincronização posterior (sem perder a foto).
class PhotoRepository {
  final PhotoService _photoService = PhotoService();
  final DatabaseHelper _db = DatabaseHelper();

  /// Adiciona uma foto à visita a partir de um arquivo de origem (câmera/galeria).
  /// Retorna um mapa com os dados locais da foto (para exibição imediata).
  Future<Map<String, dynamic>> addPhoto({
    required String visitId,
    required String sourcePath,
  }) async {
    // 1. Copiar o arquivo para um diretório permanente do app.
    final docsDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(docsDir.path, 'photos', visitId));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    final photoId = DateTime.now().millisecondsSinceEpoch.toString();
    final ext = p.extension(sourcePath).isNotEmpty
        ? p.extension(sourcePath)
        : '.jpg';
    final filename = '$photoId$ext';
    final destPath = p.join(photosDir.path, filename);
    await File(sourcePath).copy(destPath);
    final size = await File(destPath).length();
    final mimeType = _mimeFromExt(ext);

    // 2. Registrar no banco local (offline-first).
    await _db.insertLocalPhoto(
      id: photoId,
      visitId: visitId,
      filename: filename,
      path: destPath,
      mimeType: mimeType,
      size: size,
    );

    // 3. Tentar enviar imediatamente; se falhar, enfileirar para sync.
    try {
      final server = await _photoService.uploadPhoto(
        visitId: visitId,
        filePath: destPath,
      );
      await _db.markPhotoSynced(photoId, server['id']?.toString());
      print('✅ Foto $photoId enviada imediatamente.');
    } catch (e) {
      print('📴 Envio imediato da foto falhou, enfileirando: $e');
      await _db.addToSyncQueue(
        operation: 'CREATE',
        entity: 'photo',
        entityId: photoId,
        data: {
          'visitId': visitId,
          'path': destPath,
          'filename': filename,
          'mimeType': mimeType,
        },
      );
    }

    return {
      'id': photoId,
      'path': destPath,
      'filename': filename,
      'isLocal': true,
    };
  }

  /// Remove uma foto local (arquivo + registro). Se já estiver no servidor,
  /// também tenta removê-la remotamente.
  Future<void> deletePhoto(String photoId) async {
    final photo = await _db.getPhotoById(photoId);
    if (photo == null) return;

    // Remove o arquivo físico, se existir.
    final path = photo['path'] as String?;
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }

    // Se já foi sincronizada, tenta remover do servidor (best-effort).
    final serverId = photo['serverId'] as String?;
    if ((photo['synced'] as int?) == 1 && serverId != null) {
      try {
        await _photoService.deletePhoto(serverId);
      } catch (e) {
        print('⚠️ Não foi possível remover a foto no servidor: $e');
      }
    }

    await _db.deleteLocalPhoto(photoId);
  }

  /// Lista TODAS as fotos locais de uma visita (sincronizadas ou não).
  /// O arquivo permanece no disco mesmo após o envio, então continuam exibíveis.
  Future<List<Map<String, dynamic>>> getLocalPhotos(String visitId) async {
    final rows = await _db.getPhotosByVisit(visitId);
    return rows
        .map(
          (r) => {
            'id': r['id'],
            'path': r['path'],
            'filename': r['filename'],
            'serverId': r['serverId'],
            'synced': (r['synced'] as int?) == 1,
            'isLocal': true,
          },
        )
        .toList();
  }

  String _mimeFromExt(String ext) {
    switch (ext.toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  void dispose() {
    _photoService.dispose();
  }
}
