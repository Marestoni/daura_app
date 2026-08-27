import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/visit_model.dart';
import '../services/visit_service.dart';
import '../services/sync_service.dart';
import '../database/database_helper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class VisitRepository {
  final VisitService _visitService = VisitService();
  final DatabaseHelper _db = DatabaseHelper();

  // ✅ MÉTODO PARA OBTER O SYNC SERVICE DO CONTEXT
  SyncService? _getSyncService(BuildContext? context) {
    if (context == null) return null;
    try {
      return Provider.of<SyncService>(context, listen: false);
    } catch (e) {
      print('⚠️ SyncService não encontrado no contexto: $e');
      return null;
    }
  }

  // ✅ VERIFICAR CONECTIVIDADE DIRETAMENTE
  Future<bool> _checkConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      final isConnected = results.any((r) => r != ConnectivityResult.none);
      print(
        '🌐 VisitRepository - Verificação direta: ${isConnected ? "Online" : "Offline"}',
      );
      return isConnected;
    } catch (e) {
      print('❌ Erro ao verificar conectividade: $e');
      return false;
    }
  }

  // ============================================
  // BUSCAR VISITAS POR CAMPANHA
  // ============================================

  Future<List<VisitModel>> getVisitsByCampaign({
    BuildContext? context,
    required String campaignId,
    required String visitorId,
    String? status,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      // ✅ OFFLINE-FIRST: sempre TENTA a API primeiro. Se a rede falhar, o
      // catch abaixo cai para o cache local. Não dependemos do connectivity_plus
      // (pouco confiável em emulador) para decidir se busca online.
      print('🌐 Buscando visitas da API...');
      print('🔍 campaignId: $campaignId');
      print('🔍 visitorId: $visitorId');

      final response = await _visitService.getVisits(
        campaignId: campaignId,
        visitorId: visitorId,
        status: status,
        search: search,
        page: page,
        limit: limit,
      );

      print('✅ ${response.data.length} visitas recebidas da API');

      // ✅ Salvar no cache local
      await _saveVisitsToCache(response.data);

      return response.data;
    } catch (e) {
      print('⚠️ Erro ao buscar visitas: $e');

      // ✅ Fallback: tentar cache local
      print('📴 Fallback - Buscando visitas do cache local...');
      final cachedVisits = await _getVisitsFromCache(
        campaignId: campaignId,
        visitorId: visitorId,
        status: status,
        search: search,
      );

      if (cachedVisits.isNotEmpty) {
        print(
          '✅ ${cachedVisits.length} visitas encontradas no cache (fallback)',
        );
        return cachedVisits;
      }

      print('⚠️ Nenhuma visita disponível');
      return [];
    }
  }

  // ============================================
  // BUSCAR VISITA POR ID
  // ============================================

  Future<VisitModel?> getVisitById({
    BuildContext? context,
    required String visitId,
  }) async {
    try {
      // ✅ OFFLINE-FIRST: tenta a API; em caso de falha de rede, cai no cache.
      print('🌐 Buscando visita da API: $visitId');
      final visit = await _visitService.getVisitById(visitId);

      if (visit != null) {
        await _saveVisitToCache(visit);
      }

      return visit;
    } catch (e) {
      print('⚠️ Erro ao buscar visita $visitId: $e');
      return await _getVisitFromCache(visitId);
    }
  }

  // ============================================
  // ATUALIZAR VISITA (OFFLINE-FIRST)
  // ============================================

  Future<VisitModel> updateVisit({
    BuildContext? context,
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
    final visitData = {
      'id': visitId,
      'addressId': addressId,
      'visitorId': visitorId,
      'campaignId': campaignId,
      'scheduledDate': scheduledDate,
      'status': status,
      'attempt': attempt,
      'observation': observation,
      'visitOrder': visitOrder,
      'attendedBy': attendedBy,
      'situation': situation,
      'formData': formData,
      'answers': answers,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    // ✅ Salvar localmente primeiro (offline-first), preservando o objeto
    // completo no cache. localVisit já vem COMPLETO (com endereço/IDs).
    final localVisit = await _applyChangesToCachedVisit(visitId, visitData);

    // ✅ Tenta enviar imediatamente. Só enfileira se o envio falhar — assim
    // evita o envio duplicado (fila + envio imediato) que sobrescrevia dados.
    try {
      print('🌐 Enviando atualização para API...');
      final updatedVisit = await _visitService.updateVisit(
        visitId: visitId,
        addressId: addressId,
        visitorId: visitorId,
        campaignId: campaignId,
        scheduledDate: scheduledDate,
        status: status,
        attempt: attempt,
        observation: observation,
        visitOrder: visitOrder,
        attendedBy: attendedBy,
        situation: situation,
        formData: formData,
        answers: answers,
      );

      // ✅ Atualizar cache com dados da API
      await _saveVisitToCache(updatedVisit);

      return updatedVisit;
    } catch (e) {
      print('📴 Envio imediato falhou, enfileirando para sync: $e');
      await _db.addToSyncQueue(
        operation: 'UPDATE',
        entity: 'visit',
        entityId: visitId,
        data: visitData,
      );
      return localVisit;
    }
  }

  // ============================================
  // INICIAR VISITA (OFFLINE-FIRST)
  // ============================================

  Future<VisitModel> startVisit({
    BuildContext? context,
    required String visitId,
  }) async {
    final isOnline = await _checkConnectivity();

    if (isOnline) {
      try {
        print('🌐 Iniciando visita na API...');
        final visit = await _visitService.startVisit(visitId);
        await _saveVisitToCache(visit);
        return visit;
      } catch (e) {
        print('⚠️ Erro ao iniciar visita na API: $e');
      }
    }

    // ✅ Offline: aplicar a mudança preservando o objeto completo do cache.
    print('📴 Iniciando visita offline...');
    final now = DateTime.now().toIso8601String();

    final currentVisit = await _getVisitFromCache(visitId);
    if (currentVisit == null) {
      throw Exception('Visita não encontrada');
    }

    final updatedData = {
      'id': visitId,
      'addressId': currentVisit.addressId,
      'visitorId': currentVisit.visitorId,
      'campaignId': currentVisit.campaignId,
      'scheduledDate': currentVisit.scheduledDate,
      'status': 'em_andamento',
      'attempt': currentVisit.attempt ?? '1a_tentativa',
      'startedAt': now,
      'observation': currentVisit.observation,
      'visitOrder': currentVisit.visitOrder,
      'updatedAt': now,
    };

    final localVisit = await _applyChangesToCachedVisit(visitId, updatedData);

    await _db.addToSyncQueue(
      operation: 'UPDATE',
      entity: 'visit',
      entityId: visitId,
      data: updatedData,
    );

    return localVisit;
  }

  // ============================================
  // FINALIZAR VISITA (OFFLINE-FIRST)
  // ============================================

  Future<VisitModel> finishVisit({
    BuildContext? context,
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
    final now = DateTime.now().toIso8601String();

    final visitData = {
      'id': visitId,
      'addressId': addressId,
      'visitorId': visitorId,
      'campaignId': campaignId,
      'scheduledDate': scheduledDate,
      'status': status,
      'attempt': attempt,
      'observation': observation,
      'visitOrder': visitOrder,
      'attendedBy': attendedBy,
      'situation': situation,
      'formData': formData,
      'answers': answers,
      'completedAt': now,
      'isFinished': true,
      'updatedAt': now,
    };

    // ✅ Salvar localmente primeiro, preservando o objeto completo no cache.
    final localVisit = await _applyChangesToCachedVisit(visitId, visitData);

    // ✅ Tenta enviar imediatamente. Só enfileira se falhar (evita envio duplicado).
    try {
      print('🌐 Finalizando visita na API...');
      final updatedVisit = await _visitService.updateVisit(
        visitId: visitId,
        addressId: addressId,
        visitorId: visitorId,
        campaignId: campaignId,
        scheduledDate: scheduledDate,
        status: status,
        attempt: attempt,
        observation: observation,
        visitOrder: visitOrder,
        attendedBy: attendedBy,
        situation: situation,
        formData: formData,
        answers: answers,
      );

      await _saveVisitToCache(updatedVisit);
      return updatedVisit;
    } catch (e) {
      print('📴 Envio imediato falhou, enfileirando para sync: $e');
      await _db.addToSyncQueue(
        operation: 'UPDATE',
        entity: 'visit',
        entityId: visitId,
        data: visitData,
      );
      return localVisit;
    }
  }

  // ============================================
  // MÉTODOS DE CACHE LOCAL
  // ============================================

  Future<void> _saveVisitsToCache(List<VisitModel> visits) async {
    try {
      for (var visit in visits) {
        await _saveVisitToCache(visit);
      }
      print('💾 ${visits.length} visitas salvas no cache');
    } catch (e) {
      print('❌ Erro ao salvar visitas no cache: $e');
    }
  }

  Future<void> _saveVisitToCache(VisitModel visit) async {
    try {
      await _db.upsert('visits', {
        'id': visit.id,
        'campaignId': visit.campaignId,
        'visitorId': visit.visitorId,
        'addressId': visit.addressId,
        'status': visit.status,
        'scheduledDate': visit.scheduledDate,
        'completedDate': visit.completedDate,
        'attempt': visit.attempt,
        'startedAt': visit.startedAt,
        'completedAt': visit.completedAt,
        'observation': visit.observation,
        'attendedBy': visit.attendedBy,
        'situation': visit.situation,
        'visitOrder': visit.visitOrder,
        'isFinished': visit.isFinished ? 1 : 0,
        'data': jsonEncode(visit.toJson()),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ Erro ao salvar visita ${visit.id} no cache: $e');
    }
  }

  Future<List<VisitModel>> _getVisitsFromCache({
    required String campaignId,
    required String visitorId,
    String? status,
    String? search,
  }) async {
    try {
      final results = await _db.query(
        'visits',
        where: 'campaignId = ? AND visitorId = ?',
        whereArgs: [campaignId, visitorId],
        orderBy: 'updatedAt DESC',
      );

      if (results.isEmpty) {
        return [];
      }

      final visits = results
          .map((item) {
            try {
              final data = jsonDecode(item['data']);
              return VisitModel.fromJson(data);
            } catch (e) {
              print('⚠️ Erro ao parsear visita do cache: $e');
              return null;
            }
          })
          .whereType<VisitModel>()
          .toList();

      var filtered = visits;

      if (status != null && status.isNotEmpty) {
        filtered = filtered.where((v) => v.status == status).toList();
      }

      if (search != null && search.isNotEmpty) {
        filtered = filtered
            .where(
              (v) =>
                  v.address.street.toLowerCase().contains(
                    search.toLowerCase(),
                  ) ||
                  v.address.city.toLowerCase().contains(search.toLowerCase()) ||
                  v.address.neighborhood.toLowerCase().contains(
                    search.toLowerCase(),
                  ),
            )
            .toList();
      }

      return filtered;
    } catch (e) {
      print('❌ Erro ao buscar visitas do cache: $e');
      return [];
    }
  }

  Future<VisitModel?> _getVisitFromCache(String visitId) async {
    try {
      final results = await _db.query(
        'visits',
        where: 'id = ?',
        whereArgs: [visitId],
      );

      if (results.isEmpty) {
        return null;
      }

      try {
        final data = jsonDecode(results.first['data']);
        return VisitModel.fromJson(data);
      } catch (e) {
        print('⚠️ Erro ao parsear visita $visitId do cache: $e');
        return null;
      }
    } catch (e) {
      print('❌ Erro ao buscar visita $visitId do cache: $e');
      return null;
    }
  }

  /// Aplica um conjunto de mudanças (campos planos) SOBRE a visita completa que
  /// já está no cache, preservando os objetos aninhados (address/campaign/visitor).
  /// Salva o resultado no cache e devolve um [VisitModel] COMPLETO — evitando o
  /// "modelo magro" que zerava o endereço/IDs após uma ação offline.
  Future<VisitModel> _applyChangesToCachedVisit(
    String visitId,
    Map<String, dynamic> changes,
  ) async {
    final current = await _getVisitFromCache(visitId);
    final Map<String, dynamic> merged = current != null
        ? current.toJson()
        : <String, dynamic>{};

    merged['id'] = visitId;
    changes.forEach((key, value) {
      if (value != null) merged[key] = value;
    });

    final visit = VisitModel.fromJson(merged);
    await _saveVisitToCache(visit);
    return visit;
  }

  // ============================================
  // MÉTODO PARA DISPOSE
  // ============================================

  void dispose() {
    _visitService.dispose();
  }
}
