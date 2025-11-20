import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/denue_repository.dart';

class DenueDetailModal extends StatelessWidget {
  final MarketEntry entry;

  const DenueDetailModal({
    super.key,
    required this.entry,
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
              color: Colors.blue.withOpacity(0.1),
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
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.business,
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
                        entry.name,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.activity,
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
                    title: 'Información del Negocio',
                    children: [
                      _buildInfoRow('Nombre', entry.name),
                      _buildInfoRow('Empresa', entry.firm),
                      _buildInfoRow('Actividad', entry.activity),
                      _buildInfoRow('Descripción', entry.description ?? 'Sin descripción'),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Ubicación
                  _buildInfoSection(
                    title: 'Ubicación',
                    children: [
                      if (entry.direccion != null && entry.direccion!.isNotEmpty)
                        _buildInfoRow('Dirección', entry.direccion!),
                      if (entry.municipio != null || entry.estado != null)
                        _buildInfoRow('Ubicación', '${entry.municipio ?? ''}${entry.municipio != null && entry.estado != null ? ', ' : ''}${entry.estado ?? ''}'),
                      _buildInfoRow('Coordenadas', '${entry.position.latitude.toStringAsFixed(6)}, ${entry.position.longitude.toStringAsFixed(6)}'),
                      _buildInfoRow('Código postal', entry.postalCode ?? 'No disponible'),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Categoría
                  _buildCategoryCard(),
                  
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
              value.isEmpty ? 'No disponible' : value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: value.isEmpty ? Colors.grey[500] : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard() {
    final category = _getCategoryFromActivity(entry.activity);
    final color = _getCategoryColor(category);
    
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
            _getCategoryIcon(category),
            color: color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Categoría',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category,
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
              // Aquí podrías implementar llamada telefónica
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.phone, size: 18),
            label: const Text('Llamar'),
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

  String _getCategoryFromActivity(String activity) {
    final activityLower = activity.toLowerCase();
    
    if (activityLower.contains('restaurante') || activityLower.contains('comida')) {
      return 'Gastronomía';
    } else if (activityLower.contains('tienda') || activityLower.contains('comercio')) {
      return 'Comercio';
    } else if (activityLower.contains('servicio') || activityLower.contains('profesional')) {
      return 'Servicios';
    } else if (activityLower.contains('salud') || activityLower.contains('médico')) {
      return 'Salud';
    } else if (activityLower.contains('educación') || activityLower.contains('escuela')) {
      return 'Educación';
    } else if (activityLower.contains('transporte') || activityLower.contains('vehículo')) {
      return 'Transporte';
    } else {
      return 'Otros';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Gastronomía':
        return Colors.orange[600]!;
      case 'Comercio':
        return Colors.green[600]!;
      case 'Servicios':
        return Colors.blue[600]!;
      case 'Salud':
        return Colors.red[600]!;
      case 'Educación':
        return Colors.purple[600]!;
      case 'Transporte':
        return Colors.amber[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Gastronomía':
        return Icons.restaurant;
      case 'Comercio':
        return Icons.store;
      case 'Servicios':
        return Icons.build;
      case 'Salud':
        return Icons.local_hospital;
      case 'Educación':
        return Icons.school;
      case 'Transporte':
        return Icons.directions_car;
      default:
        return Icons.business;
    }
  }
}
