import 'package:flutter/material.dart';
import '../models/visit_model.dart';
import '../services/visit_service.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';

class VisitDetailScreen extends StatefulWidget {
  final String visitId;

  const VisitDetailScreen({super.key, required this.visitId});

  @override
  State<VisitDetailScreen> createState() => _VisitDetailScreenState();
}

class _VisitDetailScreenState extends State<VisitDetailScreen> {
  final VisitService _visitService = VisitService();
  VisitModel? _visit;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  // ✅ Controladores do formulário
  final TextEditingController _observationController = TextEditingController();
  String? _selectedAttendedBy;
  String? _selectedSituation;
  String? _selectedPresence;
  DateTime? _startTime;
  DateTime? _endTime;
  bool _isFinished = false;

  // ✅ Lista de fotos (simulada localmente)
  List<Map<String, dynamic>> _localPhotos = [];

  // ✅ Mapeamento de status
  final Map<String, String> _statusMap = {
    'sim': 'concluida',
    'nao': 'nao_atendido',
  };

  @override
  void initState() {
    super.initState();
    _loadVisit();
  }

  @override
  void dispose() {
    _observationController.dispose();
    _visitService.dispose();
    super.dispose();
  }

  Future<void> _loadVisit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final visit = await _visitService.getVisitById(widget.visitId);

      setState(() {
        _visit = visit;
        _isLoading = false;
        _isFinished = visit.isFinished;
        _observationController.text = visit.observation ?? '';
        _selectedAttendedBy = visit.attendedBy;
        _selectedSituation = visit.situation;
        _startTime = visit.startedAt != null
            ? DateTime.parse(visit.startedAt!)
            : null;
        _endTime = visit.completedAt != null
            ? DateTime.parse(visit.completedAt!)
            : null;
        _localPhotos = visit.photos
            .map(
              (p) => {
                'id': p.id,
                'path': p.path,
                'filename': p.filename,
                'isLocal': false,
              },
            )
            .toList();
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // ============================================
  // 24. AÇÃO: INICIAR VISITA (POST /visits/{id}/start)
  // ============================================
  Future<void> _startVisit() async {
    // ✅ Validar se já foi finalizada
    if (_isFinished) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Visita já finalizada'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // ✅ Verificar se já foi iniciada e está em andamento
    if (_startTime != null && _visit!.status.toLowerCase() == 'em_andamento') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Visita já está em andamento'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // ✅ Calcular a próxima tentativa (se for não_atendido)
    String? nextAttempt;
    bool isNewAttempt = false;

    if (_visit!.status.toLowerCase() == 'nao_atendido') {
      nextAttempt = _getNextAttempt(_visit!.attempt);
      isNewAttempt = true;

      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Nova Tentativa'),
          content: Text(
            'Esta visita já foi registrada como "Não Atendido".\n\n'
            'Deseja iniciar a ${_getAttemptLabel(_visit!.attempt)}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text('Iniciar ${_getAttemptLabel(_visit!.attempt)}'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      VisitModel updatedVisit;

      // ✅ Se for nova tentativa, fazer PUT apenas do attempt e status
      if (isNewAttempt && nextAttempt != null) {
        print('🔵 Nova tentativa: $nextAttempt');

        updatedVisit = await _visitService.updateVisit(
          visitId: widget.visitId,
          addressId: _visit!.addressId,
          visitorId: _visit!.visitorId,
          campaignId: _visit!.campaignId,
          scheduledDate: _visit!.scheduledDate.isEmpty
              ? null
              : _visit!.scheduledDate,
          status: 'em_andamento', // ✅ Muda status para em_andamento
          attempt: nextAttempt, // ✅ Atualiza apenas o attempt
          // ✅ NÃO ENVIA OS OUTROS CAMPOS (mantém o que já está salvo)
          observation: null,
          visitOrder: null,
          attendedBy: null,
          situation: null,
          formData: null,
          answers: null,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔄 ${_getAttemptLabel(nextAttempt)} iniciada!'),
            backgroundColor: AppColors.primary,
          ),
        );
      } else {
        // ✅ Primeira tentativa: POST normal /start
        updatedVisit = await _visitService.startVisit(widget.visitId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visita iniciada!'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      setState(() {
        _visit = updatedVisit;
        _startTime = updatedVisit.startedAt != null
            ? DateTime.parse(updatedVisit.startedAt!)
            : DateTime.now();
        _isSaving = false;
        _isFinished = updatedVisit.isFinished;
      });

      if (!mounted) return;
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao iniciar visita: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ✅ Método para calcular a próxima tentativa
  String _getNextAttempt(String? currentAttempt) {
    // Se não tem tentativa atual, é a primeira
    if (currentAttempt == null || currentAttempt.isEmpty) {
      return '1a_tentativa';
    }

    switch (currentAttempt) {
      case '1a_tentativa':
        return '2a_tentativa';
      case '2a_tentativa':
        return '3a_tentativa';
      case '3a_tentativa':
        return '4a_tentativa';
      case '4a_tentativa':
        return '5a_tentativa';
      default:
        // Se for um valor desconhecido, começa do 1
        return '1a_tentativa';
    }
  }

  // ✅ Método auxiliar para gerar label da tentativa
  String _getAttemptLabel(String? attempt) {
    if (attempt == null) return '1ª tentativa';

    switch (attempt) {
      case '1a_tentativa':
        return '2ª tentativa';
      case '2a_tentativa':
        return '3ª tentativa';
      case '3a_tentativa':
        return '4ª tentativa';
      default:
        return 'próxima tentativa';
    }
  }

  // ============================================
  // 25. AÇÃO: SALVAR FORMULÁRIO (PUT)
  // ============================================
  Future<void> _saveForm() async {
    if (_visit == null) return;

    print('🔍 Salvando formulário para visita ID: ${_visit}');

    // ✅ Validar campos obrigatórios
    if (_selectedPresence == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, informe se alguém está Presente no imóvel'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // ✅ Determinar status baseado na presença
      final status = _statusMap[_selectedPresence] ?? 'pendente';

      // ✅ Determinar tentativa (usar a atual ou incrementar)
      final attempt = _visit!.attempt ?? '1a_tentativa';

      // ✅ Construir formData e answers
      final formData = {
        'presenca': _selectedPresence,
        'quem_atendeu': _selectedAttendedBy,
        'situacao': _selectedSituation,
        'observacoes': _observationController.text,
      };

      final answers = {
        'presenca': _selectedPresence,
        'quem_atendeu': _selectedAttendedBy,
        'situacao': _selectedSituation,
      };

      String? scheduledDate = _visit!.scheduledDate;
      if (scheduledDate.isEmpty) {
        scheduledDate = null; // ✅ Envia null para a API
      }

      // ✅ CORRIGIDO: Usar os valores do _visit
      final updatedVisit = await _visitService.updateVisit(
        visitId: widget.visitId,
        addressId: _visit!.addressId, // ✅ Pega do _visit
        visitorId: _visit!.visitorId, // ✅ Pega do _visit
        campaignId: _visit!.campaignId, // ✅ Pega do _visit
        scheduledDate: scheduledDate,
        status: status,
        attempt: attempt,
        observation: _observationController.text.isNotEmpty
            ? _observationController.text
            : null,
        visitOrder: _visit!.visitOrder ?? 1,
        attendedBy: _selectedAttendedBy,
        situation: _selectedSituation,
        formData: formData,
        answers: answers,
      );

      setState(() {
        _visit = updatedVisit;
        _isSaving = false;
        _isFinished = updatedVisit.isFinished;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Formulário salvo com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao salvar: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ============================================
  // 27. AÇÃO: FINALIZAR VISITA
  // ============================================
  Future<void> _finishVisit() async {
    if (_visit == null) return;

    // ✅ Validar se a visita foi iniciada
    if (_startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inicie a visita antes de finalizar'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // ✅ Validar presença
    if (_selectedPresence == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, informe se alguém está Presente no imóvel'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar Visita'),
        content: const Text(
          'Tem certeza que deseja finalizar esta visita?\n\n'
          'Ao finalizar:\n'
          '• Horário de término será registrado\n'
          '• Status será atualizado\n'
          '• Dados serão salvos no servidor',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _confirmFinish();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmFinish() async {
    if (_visit == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // ✅ 27.1 Registrar horário de término
      _endTime = DateTime.now();

      // ✅ Determinar status baseado na presença
      final status = _statusMap[_selectedPresence] ?? 'concluida';

      // ✅ Construir formData e answers
      final formData = {
        'presenca': _selectedPresence,
        'quem_atendeu': _selectedAttendedBy,
        'situacao': _selectedSituation,
        'observacoes': _observationController.text,
        'hora_inicio': _startTime?.toIso8601String(),
        'hora_termino': _endTime?.toIso8601String(),
      };

      final answers = {
        'presenca': _selectedPresence,
        'quem_atendeu': _selectedAttendedBy,
        'situacao': _selectedSituation,
      };

      String? scheduledDate = _visit!.scheduledDate;
      if (scheduledDate.isEmpty) {
        scheduledDate = null; // ✅ Envia null para a API
      }

      // ✅ 27.2 Atualizar status da visita via PUT
      final updatedVisit = await _visitService.updateVisit(
        visitId: widget.visitId,
        addressId: _visit!.addressId,
        visitorId: _visit!.visitorId,
        campaignId: _visit!.campaignId,
        scheduledDate: scheduledDate,
        status: status,
        attempt: _visit!.attempt ?? '1a_tentativa',
        observation: _observationController.text.isNotEmpty
            ? _observationController.text
            : null,
        visitOrder: _visit!.visitOrder ?? 1,
        attendedBy: _selectedAttendedBy,
        situation: _selectedSituation,
        formData: formData,
        answers: answers,
      );

      setState(() {
        _visit = updatedVisit;
        _isFinished = true;
        _isSaving = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Visita finalizada com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao finalizar visita: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ============================================
  // 26. AÇÃO: FOTOS
  // ============================================
  void _takePhoto() {
    // TODO: Implementar câmera
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Função de câmera em desenvolvimento')),
    );
  }

  void _pickPhoto() {
    // TODO: Implementar galeria
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Função de galeria em desenvolvimento')),
    );
  }

  void _deletePhoto(int index) {
    setState(() {
      _localPhotos.removeAt(index);
    });
  }

  void _viewPhoto(int index) {
    final baseUrl = Constants.baseUrl.replaceAll('/api', '');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.infinity,
          height: 400,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              Center(
                child: Image.network(
                  '$baseUrl${_localPhotos[index]['path']}',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // BUILD
  // ============================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Formulário de Visita'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isLoading && _visit != null) ...[
            // ✅ Iniciar visita (agora com loading)
            if (!_isFinished && _startTime == null)
              IconButton(
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.play_arrow),
                onPressed: _isSaving ? null : _startVisit,
                tooltip: 'Iniciar Visita',
              ),
            // Salvar
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveForm,
              tooltip: 'Salvar',
            ),
            // Finalizar
            if (!_isFinished)
              IconButton(
                icon: const Icon(Icons.check_circle),
                onPressed: _finishVisit,
                tooltip: 'Finalizar Visita',
              ),
          ],
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadVisit),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_visit == null) {
      return const Center(child: Text('Visita não encontrada'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIdentificationSection(),
          const SizedBox(height: 24),
          _buildVisitStatusSection(),
          const SizedBox(height: 24),
          _buildAttendanceControlSection(),
          const SizedBox(height: 24),
          _buildPresenceSection(),
          const SizedBox(height: 24),
          _buildAttendedBySection(),
          const SizedBox(height: 24),
          _buildSituationSection(),
          const SizedBox(height: 24),
          _buildObservationsSection(),
          const SizedBox(height: 24),
          _buildPhotosSection(),
          const SizedBox(height: 32),
          _buildFinishButton(),
        ],
      ),
    );
  }

  // ============================================
  // 25.1 IDENTIFICAÇÃO
  // ============================================
  Widget _buildIdentificationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Identificação',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow(
              'Proprietário',
              _visit!.address.residentName ?? 'Não informado',
            ),
            _buildInfoRow(
              'Endereço',
              _visit!.address.fullAddress ??
                  '${_visit!.address.street}, ${_visit!.address.number}',
            ),
            _buildInfoRow('Bairro', _visit!.address.neighborhood),
            _buildInfoRow(
              'Cidade/UF',
              '${_visit!.address.city}/${_visit!.address.state}',
            ),
            _buildInfoRow('Telefone', _visit!.address.phone ?? 'Não informado'),
            _buildInfoRow('Status', _visit!.statusLabel ?? _visit!.status),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitStatusSection() {
    // ✅ Mapeamento de status para cores e ícones
    final Map<String, dynamic> statusConfig = _getStatusConfig(_visit!.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status da Visita',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Divider(),
            Row(
              children: [
                // ✅ Ícone dinâmico baseado no status
                Icon(
                  statusConfig['icon'],
                  color: statusConfig['color'],
                  size: 28,
                ),
                const SizedBox(width: 12),
                // ✅ Status com label
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusConfig['label'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: statusConfig['color'],
                        ),
                      ),
                      if (_visit!.statusLabel != null &&
                          _visit!.statusLabel != statusConfig['label'])
                        Text(
                          _visit!.statusLabel!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                // ✅ Tentativa
                if (_visit!.attemptLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _visit!.attemptLabel!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            // ✅ Status adicional (se houver)
            if (_visit!.statusLabel != null &&
                _visit!.statusLabel != statusConfig['label']) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusConfig['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: statusConfig['color'].withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: statusConfig['color'],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Status: ${_visit!.statusLabel}',
                      style: TextStyle(
                        fontSize: 12,
                        color: statusConfig['color'],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ✅ Método auxiliar para configurar status
  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'concluida':
      case 'completed':
        return {
          'label': 'Concluída',
          'color': AppColors.success,
          'icon': Icons.check_circle,
        };
      case 'em_andamento':
      case 'in_progress':
        return {
          'label': 'Em Andamento',
          'color': AppColors.primary,
          'icon': Icons.hourglass_top,
        };
      case 'pendente':
      case 'pending':
        return {
          'label': 'Pendente',
          'color': AppColors.warning,
          'icon': Icons.pending,
        };
      case 'nao_atendido':
      case 'not_attended':
        return {
          'label': 'Não Atendido',
          'color': AppColors.error,
          'icon': Icons.person_off,
        };
      case 'imovel_abandonado':
      case 'abandoned':
        return {
          'label': 'Imóvel Abandonado',
          'color': Colors.orange,
          'icon': Icons.house_outlined,
        };
      case 'cancelada':
      case 'canceled':
        return {
          'label': 'Cancelada',
          'color': Colors.red.shade700,
          'icon': Icons.cancel,
        };
      case 'rascunho':
      case 'draft':
        return {
          'label': 'Rascunho',
          'color': Colors.grey,
          'icon': Icons.note, // ✅ Substituído Icons.draft por Icons.note
        };
      default:
        return {
          'label': status,
          'color': Colors.grey,
          'icon': Icons.help_outline,
        };
    }
  }

  Widget _buildAttendanceControlSection() {
    // ✅ Verificar se pode iniciar (não finalizada E (não em andamento OU status não_atendido))
    final bool canStart =
        !_isFinished &&
        (_startTime == null || _visit!.status.toLowerCase() == 'nao_atendido');

    // ✅ Calcular label da tentativa
    String startButtonLabel = 'Iniciar Visita';
    if (_visit!.status.toLowerCase() == 'nao_atendido' &&
        _visit!.attempt != null) {
      final nextAttempt = _getAttemptLabel(_visit!.attempt);
      startButtonLabel = 'Iniciar $nextAttempt';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Controle de Atendimento',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hora de Início',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(_startTime),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hora de Término',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(_endTime),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // ✅ Botão de iniciar (mostra sempre que possível)
            if (canStart) ...[
              const SizedBox(height: 8),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _startVisit,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.play_arrow, size: 18),
                  label: Text(_isSaving ? 'Iniciando...' : startButtonLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
            // ✅ Mensagem quando não pode iniciar
            if (!canStart && !_isFinished) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Visita já está em andamento. Finalize ou salve para continuar.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_isFinished)
              const Text(
                'Visita finalizada',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            // ✅ Indicador de tentativa atual
            if (_visit!.attemptLabel != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Tentativa atual: ${_visit!.attemptLabel}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPresenceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Presença',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Sim'),
                    leading: Radio<String>(
                      value: 'sim',
                      groupValue: _selectedPresence,
                      onChanged: _isFinished
                          ? null
                          : (value) {
                              setState(() {
                                _selectedPresence = value;
                              });
                            },
                    ),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('Não'),
                    leading: Radio<String>(
                      value: 'nao',
                      groupValue: _selectedPresence,
                      onChanged: _isFinished
                          ? null
                          : (value) {
                              setState(() {
                                _selectedPresence = value;
                              });
                            },
                    ),
                  ),
                ),
              ],
            ),
            if (_isFinished)
              const Text(
                'Visita já finalizada. Não é possível alterar.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendedBySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quem atendeu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Divider(),
            DropdownButtonFormField<String>(
              value: _selectedAttendedBy,
              decoration: const InputDecoration(
                labelText: 'Selecione quem atendeu',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              items: const [
                DropdownMenuItem(value: 'dono', child: Text('Dono')),
                DropdownMenuItem(value: 'filho', child: Text('Filho')),
                DropdownMenuItem(value: 'parente', child: Text('Parente')),
                DropdownMenuItem(value: 'esposo(a)', child: Text('Esposo(a)')),
                DropdownMenuItem(value: 'outro', child: Text('Outro')),
              ],
              onChanged: _isFinished
                  ? null
                  : (value) {
                      setState(() {
                        _selectedAttendedBy = value;
                      });
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSituationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Situação da Visita',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Divider(),
            DropdownButtonFormField<String>(
              value: _selectedSituation,
              decoration: const InputDecoration(
                labelText: 'Selecione a situação',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'sem_ocorrencia',
                  child: Text('Sem ocorrência'),
                ),
                DropdownMenuItem(
                  value: 'ninguem_no_imovel',
                  child: Text('Ninguém no imóvel'),
                ),
                DropdownMenuItem(
                  value: 'imovel_abandonado',
                  child: Text('Imóvel abandonado'),
                ),
                DropdownMenuItem(
                  value: 'outro',
                  child: Text('Outro status aplicável'),
                ),
              ],
              onChanged: _isFinished
                  ? null
                  : (value) {
                      setState(() {
                        _selectedSituation = value;
                      });
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObservationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Observações',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Divider(),
            TextField(
              controller: _observationController,
              maxLines: 4,
              enabled: !_isFinished,
              decoration: const InputDecoration(
                hintText: 'Digite suas observações...',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Fotos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (!_isFinished)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.camera_alt),
                        onPressed: _takePhoto,
                        tooltip: 'Tirar foto',
                        color: AppColors.primary,
                      ),
                      IconButton(
                        icon: const Icon(Icons.photo_library),
                        onPressed: _pickPhoto,
                        tooltip: 'Selecionar da galeria',
                        color: AppColors.primary,
                      ),
                    ],
                  ),
              ],
            ),
            const Divider(),
            if (_localPhotos.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Nenhuma foto anexada',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              )
            else
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _localPhotos.length,
                  itemBuilder: (context, index) {
                    final photo = _localPhotos[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: () => _viewPhoto(index),
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: NetworkImage(
                                    'http://localhost:3000${photo['path']}',
                                  ),
                                  fit: BoxFit.cover,
                                  onError: (_, __) =>
                                      const Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                          ),
                          if (!_isFinished)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _deletePhoto(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          if (!_isFinished)
                            Positioned(
                              bottom: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${index + 1}/${_localPhotos.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinishButton() {
    if (_isFinished) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(width: 8),
            Text(
              'Visita finalizada em ${_formatTime(_endTime)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSaving || _startTime == null ? null : _finishVisit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _startTime == null
                  ? Colors.grey
                  : AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    _startTime == null
                        ? 'Inicie a visita primeiro'
                        : 'Finalizar Visita',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        if (_selectedPresence == null && !_isFinished) ...[
          const SizedBox(height: 8),
          const Text(
            '⚠️ Selecione se alguém está no imóvel para finalizar',
            style: TextStyle(fontSize: 12, color: Colors.orange),
          ),
        ],
      ],
    );
  }

  // ============================================
  // WIDGETS AUXILIARES
  // ============================================
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
              onPressed: _loadVisit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'Não iniciado';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
