import 'package:flutter/material.dart';
import '../models/visit_model.dart';
import '../utils/app_colors.dart';
import '../screens/visit_detail_screen.dart';

class VisitCard extends StatelessWidget {
  final VisitModel visit;

  const VisitCard({super.key, required this.visit});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VisitDetailScreen(visitId: visit.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${visit.address.street}, ${visit.address.number}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _buildStatusChip(visit.status),
              ],
            ),
            const SizedBox(height: 4),
            // ✅ USAR fullAddress se disponível
            Text(
              visit.address.fullAddress != null &&
                      visit.address.fullAddress!.isNotEmpty
                  ? visit.address.fullAddress!
                  : '${visit.address.neighborhood} - ${visit.address.city}/${visit.address.state}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  _formatDate(visit.scheduledDate),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.person, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  visit.visitor.name,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            // ✅ OBSERVAÇÕES - usar observation se disponível
            if ((visit.observation != null && visit.observation!.isNotEmpty) ||
                (visit.notes != null && visit.notes!.isNotEmpty)) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  visit.observation ?? visit.notes!,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            // ✅ STATUS LABEL se disponível
            if (visit.statusLabel != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(visit.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      visit.statusLabel!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _getStatusColor(visit.status),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (visit.attemptLabel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        visit.attemptLabel!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                ],
              ),
            ],
            // ✅ DATA DE CONCLUSÃO
            if (visit.completedDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 14, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    'Concluída em: ${_formatDate(visit.completedDate!)}',
                    style: TextStyle(fontSize: 12, color: AppColors.success),
                  ),
                ],
              ),
            ],
            // ✅ INDICADOR DE CLIQUE
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'completed':
      case 'concluida':
        color = AppColors.success;
        label = 'Concluída';
        break;
      case 'pendente':
      case 'pending':
        color = AppColors.warning;
        label = 'Pendente';
        break;
      case 'em_andamento':
        color = AppColors.primary;
        label = 'Em Andamento';
        break;
      case 'nao_atendido':
        color = AppColors.error;
        label = 'Não Atendido';
        break;
      case 'imovel_abandonado':
        color = Colors.orange;
        label = 'Imóvel Abandonado';
        break;
      case 'canceled':
        color = AppColors.error;
        label = 'Cancelada';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'concluida':
        return AppColors.success;
      case 'pendente':
      case 'pending':
        return AppColors.warning;
      case 'em_andamento':
        return AppColors.primary;
      case 'nao_atendido':
        return AppColors.error;
      case 'imovel_abandonado':
        return Colors.orange;
      case 'canceled':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String date) {
    try {
      final parsed = DateTime.parse(date);
      return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return date;
    }
  }
}
