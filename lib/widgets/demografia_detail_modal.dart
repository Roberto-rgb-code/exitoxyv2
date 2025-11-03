import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/censo_ageb.dart';

class DemografiaDetailModal extends StatelessWidget {
  final CensoAgeb ageb;

  const DemografiaDetailModal({
    super.key,
    required this.ageb,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[700]!, Colors.blue[600]!],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ageb.nombre ?? 'Área Geoestadística',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (ageb.muns != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          ageb.muns!,
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection('Información General', [
                    _InfoRow('Código Postal', ageb.cp?.toString()),
                    _InfoRow('Población Total', _formatNumber(ageb.pobtot)),
                    _InfoRow('Población Femenina', _formatNumber(ageb.pobfem)),
                    _InfoRow('Población Masculina', _formatNumber(ageb.pobmas)),
                  ]),
                  _buildInfoSection('Educación', [
                    _InfoRow('Grado Promedio de Escolaridad', ageb.graproes?.toStringAsFixed(2)),
                  ]),
                  _buildInfoSection('Ocupación', [
                    _InfoRow('Población Económicamente Activa', _formatNumber(ageb.pea)),
                    _InfoRow('Población Ocupada', _formatNumber(ageb.pocupada)),
                    _InfoRow('Población Desocupada', _formatNumber(ageb.pdesocup)),
                  ]),
                  _buildInfoSection('Vivienda', [
                    _InfoRow('Total de Viviendas', _formatNumber(ageb.vvtot)),
                    _InfoRow('Viviendas Habitadas', _formatNumber(ageb.tvivhab)),
                    _InfoRow('Promedio de Ocupantes', ageb.promOcup?.toStringAsFixed(2)),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<_InfoRow> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 8),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
        ),
        ...rows.map((row) => row.build()),
      ],
    );
  }

  String _formatNumber(int? number) {
    if (number == null) return 'N/A';
    return number.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }
}

class _InfoRow {
  final String label;
  final String? value;

  _InfoRow(this.label, this.value);

  Widget build() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

