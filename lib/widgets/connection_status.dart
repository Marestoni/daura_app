import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import '../utils/app_colors.dart';

class ConnectionStatus extends StatelessWidget {
  final bool showLabel;
  final bool isCompact; // ✅ Mudar de 'compact' para 'isCompact'

  const ConnectionStatus({
    super.key,
    this.showLabel = true,
    this.isCompact = false, // ✅ Agora existe
  });

  @override
  Widget build(BuildContext context) {
    final connectivity = context.watch<ConnectivityService>();
    final syncService = context.read<SyncService>();

    return FutureBuilder<int>(
      future: syncService.getPendingCount(),
      builder: (context, snapshot) {
        final pendingCount = snapshot.data ?? 0;

        if (isCompact) {
          // ✅ Usar isCompact
          return _buildCompact(connectivity, pendingCount);
        }

        return _buildFull(connectivity, pendingCount);
      },
    );
  }

  Widget _buildFull(ConnectivityService connectivity, int pendingCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: connectivity.isConnected ? AppColors.success : AppColors.error,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            connectivity.isConnected ? Icons.wifi : Icons.wifi_off,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            connectivity.isConnected
                ? 'Online${pendingCount > 0 ? " · $pendingCount pendente(s)" : ""}'
                : 'Offline · $pendingCount pendente(s)',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (pendingCount > 0 && connectivity.isConnected) ...[
            const SizedBox(width: 8),
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompact(ConnectivityService connectivity, int pendingCount) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: connectivity.isConnected ? AppColors.success : AppColors.error,
        shape: BoxShape.circle,
      ),
      child: Tooltip(
        message: connectivity.isConnected
            ? 'Online${pendingCount > 0 ? " - $pendingCount pendente(s)" : ""}'
            : 'Offline - $pendingCount pendente(s)',
        child: Icon(
          connectivity.isConnected ? Icons.wifi : Icons.wifi_off,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}
