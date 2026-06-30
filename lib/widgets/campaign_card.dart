import 'package:flutter/material.dart';
import '../models/campaign_model.dart';
import '../utils/app_colors.dart';
import '../screens/campaign_visits_screen.dart';

class CampaignCard extends StatelessWidget {
  final CampaignModel campaign;
  final String visitorId; // ✅ NOVO PARÂMETRO

  const CampaignCard({
    super.key,
    required this.campaign,
    required this.visitorId, // ✅ NOVO
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: visitorId.isNotEmpty
          ? () {
              print('🔵 Clicou na campanha: ${campaign.name}');
              print('🔵 Campaign ID: ${campaign.id}');
              print('🔵 Visitor ID: $visitorId');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CampaignVisitsScreen(
                    campaign: campaign,
                    visitorId: visitorId,
                  ),
                ),
              );
            }
          : null, // Se não tiver visitorId, não faz nada
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho com status
            Row(
              children: [
                Expanded(
                  child: Text(
                    campaign.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _buildStatusChip(campaign.status),
              ],
            ),
            const SizedBox(height: 8),
            // Descrição
            Text(
              campaign.description,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            // Datas
            Row(
              children: [
                _buildInfoItem(
                  icon: Icons.calendar_today,
                  label: 'Início',
                  value: _formatDate(campaign.startDate),
                ),
                const SizedBox(width: 16),
                _buildInfoItem(
                  icon: Icons.calendar_today,
                  label: 'Fim',
                  value: _formatDate(campaign.endDate),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progresso
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progresso',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    Text(
                      '${campaign.progress}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: campaign.progress / 100,
                    backgroundColor: Colors.grey[200],
                    color: _getProgressColor(campaign.progress),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Estatísticas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  label: 'Total',
                  value: campaign.totalVisits.toString(),
                  color: AppColors.primary,
                ),
                _buildStatItem(
                  label: 'Concluídas',
                  value: campaign.completedVisits.toString(),
                  color: AppColors.success,
                ),
                _buildStatItem(
                  label: 'Pendentes',
                  value: campaign.pendingVisits.toString(),
                  color: AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Criado por
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Criado por: ${campaign.createdBy.name}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
            // Indicador de clique
            if (visitorId.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'ativo':
      case 'active':
        color = AppColors.success;
        label = 'Ativo';
        break;
      case 'rascunho':
      case 'draft':
        color = Colors.grey;
        label = 'Rascunho';
        break;
      case 'concluído':
      case 'completed':
        color = AppColors.primary;
        label = 'Concluído';
        break;
      case 'pausado':
      case 'paused':
        color = AppColors.warning;
        label = 'Pausado';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }

  String _formatDate(String date) {
    try {
      final parts = date.split('-');
      if (parts.length >= 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
      return date;
    } catch (e) {
      return date;
    }
  }

  Color _getProgressColor(int progress) {
    if (progress >= 80) return AppColors.success;
    if (progress >= 50) return AppColors.primary;
    if (progress >= 20) return AppColors.warning;
    return Colors.grey;
  }
}
