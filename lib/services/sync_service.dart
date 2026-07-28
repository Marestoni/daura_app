import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/database_helper.dart';
import '../models/campaign_model.dart';
import '../services/auth_service.dart';
import '../services/campaign_service.dart';
import '../services/photo_service.dart';
import '../services/visit_service.dart';

class SyncService {
  // ✅ SINGLETON
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DatabaseHelper _db = DatabaseHelper();
  final AuthService _authService = AuthService();
  final CampaignService _campaignService = CampaignService();
  final VisitService _visitService = VisitService();
  final PhotoService _photoService = PhotoService();

  bool _isConnected = false;
  bool _isSyncing = false;
  Timer? _syncTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  // ✅ GETTER PÚBLICO
  bool get isConnected => _isConnected;

  void startMonitoring() {
    print('🔄 Iniciando monitoramento de conectividade...');

    // Estado inicial
    _checkConnectivity();

    // ✅ Sincroniza de forma EVENTO-DIRIGIDA: reage a mudanças reais de rede
    // (ex.: voltou a ter internet) em vez de fazer polling a cada 30s.
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      _handleConnectivityChange(_resultsToConnected(results));
    });

    // ✅ Rede de segurança: periodicamente ENVIA apenas as pendências
    // (não baixa tudo do servidor) e somente se houver pendências.
    _syncTimer = Timer.periodic(const Duration(minutes: 2), (_) async {
      if (_isConnected && await getPendingCount() > 0) {
        await _pushPending();
      }
    });
  }

  void stopMonitoring() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  /// Converte o resultado do connectivity_plus 6.x (`List<ConnectivityResult>`)
  /// em um booleano de "está conectado".
  bool _resultsToConnected(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  Future<void> _checkConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _handleConnectivityChange(_resultsToConnected(results));
    } catch (e) {
      print('❌ Erro ao verificar conectividade: $e');
      _isConnected = false;
    }
  }

  /// Aplica a mudança de conectividade e dispara sync completa apenas na
  /// TRANSIÇÃO offline -> online (evita martelar servidor/bateria).
  void _handleConnectivityChange(bool nowConnected) {
    final wasConnected = _isConnected;
    _isConnected = nowConnected;

    print('🌐 Status de conexão: ${nowConnected ? "Conectado" : "Desconectado"}');

    if (nowConnected && !wasConnected) {
      print('🔄 Internet reconectada! Iniciando sincronização...');
      syncAll();
    } else if (!nowConnected) {
      print('📴 Sem internet. Dados serão salvos localmente.');
    }
  }

  /// Envia apenas as pendências acumuladas (sem baixar dados do servidor).
  Future<void> _pushPending() async {
    if (_isSyncing || !_isConnected) return;
    try {
      _isSyncing = true;
      await _syncPendingToServer();
    } catch (e) {
      print('❌ Erro ao enviar pendências: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> syncAll() async {
    if (_isSyncing) {
      print('⏳ Sincronização já em andamento...');
      return;
    }

    if (!_isConnected) {
      print('📴 Sem internet, não é possível sincronizar.');
      return;
    }

    try {
      _isSyncing = true;
      print('🔄 Iniciando sincronização...');

      await _syncPendingToServer();
      await _syncFromServer();

      print('✅ Sincronização concluída!');
    } catch (e) {
      print('❌ Erro na sincronização: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncPendingToServer() async {
    final pendings = await _db.getPendingSync();

    if (pendings.isEmpty) {
      print('📭 Nenhuma pendência para sincronizar.');
      return;
    }

    print('📤 Sincronizando ${pendings.length} pendências...');

    for (var pending in pendings) {
      try {
        final id = pending['id'] as int;
        final operation = pending['operation'] as String;
        final entity = pending['entity'] as String;
        final entityId = pending['entityId'] as String;
        final data = jsonDecode(pending['data'] as String);

        print('📤 Processando: $operation $entity $entityId');

        bool success = false;

        switch (entity) {
          case 'visit':
            success = await _syncVisit(operation, entityId, data);
            break;
          case 'photo':
            success = await _syncPhoto(operation, entityId, data);
            break;
          default:
            print('⚠️ Entidade desconhecida: $entity');
        }

        if (success) {
          await _db.markSyncProcessed(id);
          print('✅ Pendência $id processada com sucesso!');
        } else {
          await _db.markSyncError(id, 'Erro ao processar');
          print('❌ Pendência $id falhou');
        }
      } catch (e) {
        print('❌ Erro ao processar pendência: $e');
      }
    }

    await _db.cleanProcessedSync();
  }

  Future<bool> _syncVisit(
    String operation,
    String visitId,
    Map<String, dynamic> data,
  ) async {
    try {
      switch (operation) {
        case 'CREATE':
        case 'UPDATE':
          await _visitService.updateVisit(
            visitId: visitId,
            addressId: data['addressId'] ?? '',
            visitorId: data['visitorId'] ?? '',
            campaignId: data['campaignId'] ?? '',
            scheduledDate: data['scheduledDate'],
            status: data['status'] ?? 'pendente',
            attempt: data['attempt'],
            observation: data['observation'],
            visitOrder: data['visitOrder'],
            attendedBy: data['attendedBy'],
            situation: data['situation'],
            formData: data['formData'],
            answers: data['answers'],
          );
          return true;
        case 'DELETE':
          return true;
        default:
          return false;
      }
    } catch (e) {
      print('❌ Erro ao sincronizar visita $visitId: $e');
      return false;
    }
  }

  Future<bool> _syncPhoto(
    String operation,
    String photoId,
    Map<String, dynamic> data,
  ) async {
    try {
      if (operation == 'DELETE') {
        // Exclusão já tratada localmente/best-effort no repositório.
        return true;
      }

      final visitId = data['visitId'] as String?;
      final path = data['path'] as String?;
      if (visitId == null || path == null) {
        print('⚠️ Dados da foto $photoId incompletos: $data');
        return false;
      }

      final file = File(path);
      if (!await file.exists()) {
        // Arquivo removido; não há o que enviar — evita retentar para sempre.
        print('⚠️ Arquivo da foto $photoId não existe mais ($path).');
        return true;
      }

      print('📸 Enviando foto $photoId da visita $visitId...');
      final server = await _photoService.uploadPhoto(
        visitId: visitId,
        filePath: path,
      );
      await _db.markPhotoSynced(photoId, server['id']?.toString());
      print('✅ Foto $photoId sincronizada.');
      return true;
    } catch (e) {
      print('❌ Erro ao sincronizar foto $photoId: $e');
      return false;
    }
  }

  Future<void> _syncFromServer() async {
    try {
      print('📥 Baixando dados do servidor...');

      final campaigns = await _campaignService.getCampaigns();
      print('📥 ${campaigns.data.length} campanhas recebidas da API');

      await cacheCampaigns(campaigns.data);
      print('✅ ${campaigns.data.length} campanhas sincronizadas com sucesso!');
    } catch (e) {
      print('❌ Erro ao baixar dados do servidor: $e');
    }
  }

  /// Grava/atualiza campanhas no cache local (SQLite).
  /// Reutilizado pela sincronização E pelo dashboard, garantindo que as
  /// campanhas fiquem disponíveis offline assim que são vistas online.
  Future<void> cacheCampaigns(List<CampaignModel> campaigns) async {
    for (final campaign in campaigns) {
      try {
        await _db.upsert('campaigns', {
          'id': campaign.id,
          'name': campaign.name,
          'description': campaign.description,
          'objective': campaign.objective,
          'startDate': campaign.startDate,
          'endDate': campaign.endDate,
          'status': campaign.status,
          'progress': campaign.progress,
          'totalVisits': campaign.totalVisits,
          'completedVisits': campaign.completedVisits,
          'pendingVisits': campaign.pendingVisits,
          'createdBy': jsonEncode(campaign.createdBy.toJson()),
          'data': jsonEncode(campaign.toJson()),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        print('❌ Erro ao salvar campanha ${campaign.id} no cache: $e');
      }
    }
  }

  Future<void> saveVisitOffline(Map<String, dynamic> visitData) async {
    try {
      final visitId =
          visitData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();

      await _db.upsert('visits', {
        'id': visitId,
        'campaignId': visitData['campaignId'] ?? '',
        'visitorId': visitData['visitorId'] ?? '',
        'addressId': visitData['addressId'] ?? '',
        'status': visitData['status'] ?? 'pendente',
        'scheduledDate': visitData['scheduledDate'],
        'completedDate': visitData['completedDate'],
        'attempt': visitData['attempt'],
        'startedAt': visitData['startedAt'],
        'completedAt': visitData['completedAt'],
        'observation': visitData['observation'],
        'attendedBy': visitData['attendedBy'],
        'situation': visitData['situation'],
        'visitOrder': visitData['visitOrder'],
        'isFinished': (visitData['isFinished'] == true) ? 1 : 0,
        'data': jsonEncode(visitData),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      await _db.addToSyncQueue(
        operation: 'UPDATE',
        entity: 'visit',
        entityId: visitId,
        data: visitData,
      );

      print('💾 Visita salva localmente: $visitId');
    } catch (e) {
      print('❌ Erro ao salvar visita localmente: $e');
    }
  }

  Future<int> getPendingCount() async {
    final pendings = await _db.getPendingSync();
    return pendings.length;
  }

  void dispose() {
    stopMonitoring();
    _visitService.dispose();
  }
}
