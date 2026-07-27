import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/database_helper.dart';
import '../services/auth_service.dart';
import '../services/campaign_service.dart';
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

  bool _isConnected = false;
  bool _isSyncing = false;
  Timer? _syncTimer;

  // ✅ GETTER PÚBLICO
  bool get isConnected => _isConnected;

  void startMonitoring() {
    print('🔄 Iniciando monitoramento de conectividade...');
    _checkConnectivity();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkConnectivity();
    });
  }

  void stopMonitoring() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final wasConnected = _isConnected;
      _isConnected = connectivityResult != ConnectivityResult.none;

      print(
        '🌐 Status de conexão: ${_isConnected ? "Conectado" : "Desconectado"}',
      );

      if (_isConnected && !wasConnected) {
        print('🔄 Internet reconectada! Iniciando sincronização...');
        await syncAll();
      } else if (_isConnected) {
        print('🌐 Internet disponível, verificando pendências...');
        await syncAll();
      } else {
        print('📴 Sem internet. Dados serão salvos localmente.');
      }
    } catch (e) {
      print('❌ Erro ao verificar conectividade: $e');
      _isConnected = false;
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
      print('📸 Sincronizando foto $photoId...');
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

      for (var campaign in campaigns.data) {
        try {
          final campaignJson = campaign.toJson();

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
            'data': jsonEncode(campaignJson),
            'updatedAt': DateTime.now().toIso8601String(),
          });
          print('✅ Campanha salva/atualizada: ${campaign.name}');
        } catch (e) {
          print('❌ Erro ao salvar campanha ${campaign.id}: $e');
        }
      }
      print('✅ ${campaigns.data.length} campanhas sincronizadas com sucesso!');
    } catch (e) {
      print('❌ Erro ao baixar dados do servidor: $e');
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
        'isFinished': visitData['isFinished'] ? 1 : 0,
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
