import 'package:url_launcher/url_launcher.dart';
import '../models/visit_model.dart';

/// Abre o app de mapas nativo no modo DIREÇÕES até o endereço da visita.
/// Usa a coordenada (precisa) quando disponível; senão, o endereço em texto.
/// Retorna `false` se não conseguiu abrir.
Future<bool> openDirections(Address address) async {
  final hasCoords = address.latitude != null && address.longitude != null;

  final String destination;
  if (hasCoords) {
    destination = '${address.latitude},${address.longitude}';
  } else {
    final parts = <String>[
      '${address.street}, ${address.number}',
      address.neighborhood,
      address.city,
      address.state,
    ].where((e) => e.trim().isNotEmpty).toList();
    destination = parts.join(', ');
  }

  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination='
    '${Uri.encodeComponent(destination)}&travelmode=driving',
  );

  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
