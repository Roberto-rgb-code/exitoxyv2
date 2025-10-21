import 'package:flutter/material.dart';

class DelitoInfoWindow extends StatelessWidget {
  final String delito;
  final String fecha;
  final String hora;
  final String colonia;
  final String municipio;
  final String bienAfectado;

  const DelitoInfoWindow({
    super.key,
    required this.delito,
    required this.fecha,
    required this.hora,
    required this.colonia,
    required this.municipio,
    required this.bienAfectado,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.warning,
                color: Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Delito',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Tipo de delito
          Text(
            delito,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          
          // Fecha y hora
          Text(
            'Fecha: $fecha',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
          Text(
            'Hora: $hora',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          
          // Ubicación
          Text(
            'Colonia: $colonia',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
            ),
          ),
          Text(
            'Municipio: $municipio',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          
          // Bien afectado
          if (bienAfectado.isNotEmpty)
            Text(
              'Bien afectado: $bienAfectado',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }
}
