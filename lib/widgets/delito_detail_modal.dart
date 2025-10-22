import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/delito_model.dart';

class DelitoDetailModal extends StatelessWidget {
  final DelitoModel delito;

  const DelitoDetailModal({
    super.key,
    required this.delito,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _getCrimeColor(delito.delito).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getCrimeColor(delito.delito),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.warning,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        delito.delito,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fecha: ${delito.fecha}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información básica
                  _buildInfoSection(
                    title: 'Información del Delito',
                    children: [
                      _buildInfoRow('Tipo de delito', delito.delito),
                      _buildInfoRow('Fecha', delito.fecha),
                      _buildInfoRow('Hora', delito.hora),
                      _buildInfoRow('Colonia', delito.colonia),
                      _buildInfoRow('Municipio', delito.municipio),
                      _buildInfoRow('Bien afectado', delito.bienAfectado),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Ubicación
                  _buildInfoSection(
                    title: 'Ubicación',
                    children: [
                      _buildInfoRow('Coordenadas', '${delito.y}, ${delito.x}'),
                      _buildInfoRow('Colonia', delito.colonia),
                      _buildInfoRow('Municipio', delito.municipio),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Severidad
                  _buildSeverityCard(),
                  
                  const SizedBox(height: 24),
                  
                  // Acciones
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityCard() {
    final severity = _getSeverityLevel(delito.delito);
    final color = _getSeverityColor(severity);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _getSeverityIcon(severity),
            color: color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nivel de Severidad',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  severity,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Aquí podrías implementar navegación al mapa
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.location_on, size: 18),
            label: const Text('Ver en Mapa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // Aquí podrías implementar compartir
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Compartir'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getSeverityLevel(String crimeType) {
    switch (crimeType.toLowerCase()) {
      case 'homicidio doloso':
        return 'CRÍTICO';
      case 'robo a casa habitación':
        return 'ALTO';
      case 'robo a negocio':
        return 'MEDIO';
      case 'robo a persona':
        return 'MEDIO';
      case 'robo de vehículo':
        return 'BAJO';
      case 'violencia familiar':
        return 'ALTO';
      default:
        return 'DESCONOCIDO';
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'CRÍTICO':
        return Colors.red[900]!;
      case 'ALTO':
        return Colors.red[700]!;
      case 'MEDIO':
        return Colors.orange[600]!;
      case 'BAJO':
        return Colors.amber[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity) {
      case 'CRÍTICO':
        return Icons.dangerous;
      case 'ALTO':
        return Icons.warning;
      case 'MEDIO':
        return Icons.info;
      case 'BAJO':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  Color _getCrimeColor(String crimeType) {
    switch (crimeType.toLowerCase()) {
      case 'homicidio doloso':
        return Colors.red[900]!;
      case 'robo a casa habitación':
        return Colors.red[700]!;
      case 'robo a negocio':
        return Colors.orange[700]!;
      case 'robo a persona':
        return Colors.orange[600]!;
      case 'robo de vehículo':
        return Colors.amber[700]!;
      case 'violencia familiar':
        return Colors.purple[600]!;
      default:
        return Colors.grey[600]!;
    }
  }
}
