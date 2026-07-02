import 'package:flutter/material.dart';
import '../models/campaign_model.dart';
import '../models/visit_model.dart';
import '../services/visit_service.dart';
import '../services/storage_service.dart';
import '../utils/app_colors.dart';
import '../widgets/visit_card.dart'; // ✅ ADICIONAR O IMPORT

class CampaignVisitsScreen extends StatefulWidget {
  final CampaignModel campaign;
  final String visitorId;

  const CampaignVisitsScreen({
    super.key,
    required this.campaign,
    required this.visitorId,
  });

  @override
  State<CampaignVisitsScreen> createState() => _CampaignVisitsScreenState();
}

class _CampaignVisitsScreenState extends State<CampaignVisitsScreen> {
  final VisitService _visitService = VisitService();
  final StorageService _storage = StorageService();

  List<VisitModel> _visits = [];
  bool _isLoading = true;
  String? _error;

  // Filtros
  String? _selectedStatus;
  String? _searchQuery;
  int _currentPage = 1;
  int _totalPages = 1;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _loadVisits();
  }

  @override
  void dispose() {
    _visitService.dispose();
    super.dispose();
  }

  Future<void> _loadVisits({bool resetPage = true}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      if (resetPage) _currentPage = 1;
    });

    try {
      print('🔵 Carregando visitas...');
      print('🔵 campaignId: ${widget.campaign.id}');
      print('🔵 visitorId: ${widget.visitorId}');

      final response = await _visitService.getVisits(
        campaignId: widget.campaign.id,
        visitorId: widget.visitorId,
        status: _selectedStatus,
        search: _searchQuery,
        page: _currentPage,
        limit: _limit,
      );

      print('✅ Visitas carregadas: ${response.data.length}');
      print('✅ Total: ${response.total}');

      setState(() {
        if (resetPage) {
          _visits = response.data;
        } else {
          _visits.addAll(response.data);
        }

        if (response.total > 0 && response.limit > 0) {
          _totalPages = (response.total / response.limit).ceil();
        } else {
          _totalPages = 1;
        }

        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erro ao carregar visitas: $e');
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _loadMore() {
    if (_currentPage < _totalPages && !_isLoading) {
      setState(() {
        _currentPage++;
      });
      _loadVisits(resetPage: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.campaign.name),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadVisits(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Buscar visitas...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery != null && _searchQuery!.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchQuery = null;
                    });
                    _loadVisits();
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.isEmpty ? null : value;
          });
          _loadVisits();
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _visits.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_visits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhuma visita encontrada',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Esta campanha ainda não tem visitas.',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVisits,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _visits.length + (_currentPage < _totalPages ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _visits.length) {
            return _buildLoadMoreButton();
          }
          // ✅ Usar o VisitCard importado
          return VisitCard(visit: _visits[index]);
        },
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: ElevatedButton(
          onPressed: _loadMore,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Carregar mais'),
        ),
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
            ElevatedButton(
              onPressed: _loadVisits,
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
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar visitas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Todos')),
                DropdownMenuItem(value: 'pendente', child: Text('Pendente')),
                DropdownMenuItem(
                  value: 'em_andamento',
                  child: Text('Em Andamento'),
                ),
                DropdownMenuItem(value: 'concluida', child: Text('Concluída')),
                DropdownMenuItem(
                  value: 'nao_atendido',
                  child: Text('Não Atendido'),
                ),
                DropdownMenuItem(
                  value: 'imovel_abandonado',
                  child: Text('Imóvel Abandonado'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedStatus = null;
              });
              Navigator.pop(context);
              _loadVisits();
            },
            child: const Text('Limpar filtros'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadVisits();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }
}
