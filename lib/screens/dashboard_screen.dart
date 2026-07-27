import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../controllers/login_controller.dart';
import '../services/campaign_service.dart';
import '../services/sync_service.dart'; // ✅ USADO AQUI
import '../database/database_helper.dart';
import '../models/campaign_model.dart';
import '../widgets/campaign_card.dart';
import '../widgets/connection_status.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;

  const DashboardScreen({super.key, required this.userName});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final CampaignService _campaignService = CampaignService();
  List<CampaignModel> _campaigns = [];
  bool _isLoading = true;
  bool _isOfflineMode = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  @override
  void dispose() {
    _campaignService.dispose();
    super.dispose();
  }

  Future<void> _loadCampaigns() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _isOfflineMode = false;
    });

    try {
      // ✅ VERIFICAR CONECTIVIDADE
      final syncService = context.read<SyncService>();

      if (syncService.isConnected) {
        // ✅ ONLINE: Buscar da API
        print('🌐 Carregando campanhas da API...');
        final response = await _campaignService.getCampaigns();
        setState(() {
          _campaigns = response.data;
          _isLoading = false;
        });
      } else {
        // ✅ OFFLINE: Buscar do cache local
        print('📴 Carregando campanhas do cache local...');
        await _loadFromLocalCache();
      }
    } catch (e) {
      // Se falhar, tentar carregar do cache local
      print('⚠️ Erro na API, tentando cache local...');
      await _loadFromLocalCache();
    }
  }

  Future<void> _loadFromLocalCache() async {
    try {
      final db = DatabaseHelper();
      final localData = await db.query('campaigns');

      if (localData.isNotEmpty) {
        final List<CampaignModel> campaigns = localData.map((item) {
          final data = jsonDecode(item['data']);
          return CampaignModel.fromJson(data);
        }).toList();

        setState(() {
          _campaigns = campaigns;
          _isLoading = false;
          _isOfflineMode = true;
          _error = null;
        });
        print('✅ ${campaigns.length} campanhas carregadas do cache');
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Sem conexão e nenhum dado disponível offline';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error =
            'Erro ao carregar dados offline: ${e.toString().replaceFirst('Exception: ', '')}';
      });
    }
  }

  // ✅ MÉTODO PARA FORÇAR SINCRONIZAÇÃO
  Future<void> _forceSync() async {
    final syncService = context.read<SyncService>();
    if (!syncService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sem conexão com a internet'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await syncService.syncAll();
      await _loadCampaigns();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sincronização concluída!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro na sincronização: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final visitorId = context.read<LoginController>().visitorId ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Dashboard'),
            if (_isOfflineMode) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'OFFLINE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // ✅ STATUS DE CONEXÃO
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: ConnectionStatus(isCompact: true),
          ),
          // ✅ BOTÃO DE SINCRONIZAÇÃO FORÇADA
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _forceSync,
            tooltip: 'Sincronizar',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCampaigns,
            tooltip: 'Recarregar',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: _buildBody(visitorId),
    );
  }

  Widget _buildBody(String visitorId) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_campaigns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _isOfflineMode
                  ? 'Nenhuma campanha disponível offline'
                  : 'Nenhuma campanha encontrada',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (_isOfflineMode) ...[
              const SizedBox(height: 8),
              Text(
                'Conecte-se à internet e sincronize',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCampaigns,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _campaigns.length,
        itemBuilder: (context, index) {
          return CampaignCard(
            campaign: _campaigns[index],
            visitorId: visitorId,
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Ops! Algo deu errado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _loadCampaigns,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Tentar novamente'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _forceSync,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Sincronizar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final controller = context.read<LoginController>();
      await controller.logout();

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}
