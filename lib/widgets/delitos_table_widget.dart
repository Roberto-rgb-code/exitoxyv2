import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/delito_model.dart';
import 'delito_detail_modal.dart';

class DelitosTableWidget extends StatelessWidget {
  final List<DelitoModel> delitos;

  const DelitosTableWidget({
    Key? key,
    required this.delitos,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (delitos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron delitos en esta área',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(
          colorScheme.primary.withOpacity(0.1),
        ),
        columns: [
          DataColumn(
            label: Text(
              'Fecha',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Delito',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Hora',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Colonia',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Municipio',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Bien Afectado',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
        rows: delitos.take(50).map((delito) {
          return DataRow(
            onSelectChanged: (selected) {
              if (selected == true) {
                _showDelitoModal(context, delito);
              }
            },
            cells: [
              DataCell(
                Text(
                  _formatDate(delito.fecha),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCrimeColor(delito.delito).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    delito.delito,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _getCrimeColor(delito.delito),
                    ),
                  ),
                ),
              ),
              DataCell(
                Text(
                  _formatTime(delito.hora),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              DataCell(
                Text(
                  delito.colonia,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              DataCell(
                Text(
                  delito.municipio,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              DataCell(
                Text(
                  delito.bienAfectado,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _formatDate(String fecha) {
    try {
      final parts = fecha.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
      return fecha;
    } catch (e) {
      return fecha;
    }
  }

  String _formatTime(String hora) {
    try {
      final hour = double.parse(hora);
      final hours = hour.floor();
      final minutes = ((hour - hours) * 60).round();
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    } catch (e) {
      return hora;
    }
  }

  Color _getCrimeColor(String delito) {
    final lowerDelito = delito.toLowerCase();
    if (lowerDelito.contains('homicidio')) {
      return Colors.red;
    } else if (lowerDelito.contains('robo')) {
      return Colors.orange;
    } else if (lowerDelito.contains('violencia')) {
      return Colors.purple;
    } else if (lowerDelito.contains('lesiones')) {
      return Colors.amber;
    } else {
      return Colors.grey;
    }
  }

  void _showDelitoModal(BuildContext context, DelitoModel delito) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DelitoDetailModal(delito: delito),
    );
  }
}
