// lib/widgets/glossary_tooltip.dart
/// Helper global para agregar tooltips de glosario a cualquier texto técnico
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/glossary_service.dart';

// Re-exportar GlossaryPage y GlossaryTermWidget para uso conveniente
export 'glossary_term_widget.dart' show GlossaryPage, GlossaryTermWidget, GlossaryFAB;

/// Widget simple para mostrar un término con icono de ayuda
class GlossaryTooltip extends StatelessWidget {
  final String text;
  final String termKey;
  final TextStyle? style;
  final Color? iconColor;
  final double iconSize;
  final MainAxisAlignment alignment;

  const GlossaryTooltip({
    super.key,
    required this.text,
    required this.termKey,
    this.style,
    this.iconColor,
    this.iconSize = 14,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: [
        Text(text, style: style),
        const SizedBox(width: 4),
        GlossaryHelpIcon(
          termKey: termKey,
          color: iconColor ?? style?.color,
          size: iconSize,
        ),
      ],
    );
  }
}

/// Solo el icono de ayuda para glosario
class GlossaryHelpIcon extends StatelessWidget {
  final String termKey;
  final Color? color;
  final double size;

  const GlossaryHelpIcon({
    super.key,
    required this.termKey,
    this.color,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    final term = GlossaryService.getTerm(termKey);
    if (term == null) return const SizedBox.shrink();

    return Tooltip(
      message: term.definition,
      preferBelow: false,
      showDuration: const Duration(seconds: 4),
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      child: GestureDetector(
        onTap: () => showGlossaryModal(context, termKey),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: (color ?? Colors.grey[600])!.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: (color ?? Colors.grey[600])!.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.help_outline_rounded,
            size: size * 0.7,
            color: color ?? Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

/// Muestra el modal con la definición completa del término
void showGlossaryModal(BuildContext context, String termKey) {
  final term = GlossaryService.getTerm(termKey);
  if (term == null) return;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(term.category).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(term.category),
                    color: _getCategoryColor(term.category),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        term.term,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (term.fullName != term.term)
                        Text(
                          term.fullName,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Badge categoría
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(term.category).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    term.category,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getCategoryColor(term.category),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Definición
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: _getCategoryColor(term.category)),
                      const SizedBox(width: 8),
                      Text(
                        'Definición',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _getCategoryColor(term.category),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    term.definition,
                    style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          
          // Ejemplo
          if (term.example != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ejemplo',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            term.example!,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Color _getCategoryColor(String category) {
  switch (category) {
    case 'Análisis de Mercado':
      return Colors.blue[700]!;
    case 'Elasticidades':
      return Colors.green[700]!;
    case 'Modelos Económicos':
      return Colors.purple[700]!;
    case 'Demografía':
      return Colors.orange[700]!;
    case 'Indicadores':
      return Colors.teal[700]!;
    case 'Análisis Espacial':
      return Colors.indigo[700]!;
    default:
      return Colors.grey[700]!;
  }
}

IconData _getCategoryIcon(String category) {
  switch (category) {
    case 'Análisis de Mercado':
      return Icons.analytics;
    case 'Elasticidades':
      return Icons.trending_up;
    case 'Modelos Económicos':
      return Icons.functions;
    case 'Demografía':
      return Icons.people;
    case 'Indicadores':
      return Icons.insert_chart;
    case 'Análisis Espacial':
      return Icons.map;
    default:
      return Icons.help_outline;
  }
}

