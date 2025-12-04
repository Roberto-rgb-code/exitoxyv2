// lib/widgets/glossary_term_widget.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/glossary_service.dart';

/// Widget que muestra un término con icono de ayuda (?) y tooltip con definición
class GlossaryTermWidget extends StatelessWidget {
  final String termKey;
  final String? displayText;
  final TextStyle? textStyle;
  final Color? iconColor;
  final double iconSize;
  final bool showFullName;

  const GlossaryTermWidget({
    super.key,
    required this.termKey,
    this.displayText,
    this.textStyle,
    this.iconColor,
    this.iconSize = 16,
    this.showFullName = false,
  });

  @override
  Widget build(BuildContext context) {
    final term = GlossaryService.getTerm(termKey);
    
    if (term == null) {
      return Text(
        displayText ?? termKey,
        style: textStyle,
      );
    }

    return GestureDetector(
      onTap: () => _showDetailedDefinition(context, term),
      child: Tooltip(
        message: term.definition,
        preferBelow: false,
        showDuration: const Duration(seconds: 5),
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[900]?.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        textStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 12,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayText ?? (showFullName ? term.fullName : term.term),
              style: textStyle,
            ),
            const SizedBox(width: 4),
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: (iconColor ?? Theme.of(context).colorScheme.primary).withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: (iconColor ?? Theme.of(context).colorScheme.primary).withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.help_outline_rounded,
                size: iconSize * 0.7,
                color: iconColor ?? Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailedDefinition(BuildContext context, GlossaryTerm term) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _DefinitionModal(term: term),
    );
  }
}

/// Modal con definición detallada del término
class _DefinitionModal extends StatelessWidget {
  final GlossaryTerm term;

  const _DefinitionModal({required this.term});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
          Container(
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
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (term.fullName != term.term)
                        Text(
                          term.fullName,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: colorScheme.onSurface.withOpacity(0.7),
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
          
          // Categoría badge
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Definición',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    term.definition,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: colorScheme.onSurface,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Ejemplo
          if (term.example != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 18,
                          color: Colors.amber[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ejemplo',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      term.example!,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: colorScheme.onSurface.withOpacity(0.8),
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 24),
        ],
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
}

/// Widget para mostrar el glosario completo
class GlossaryPage extends StatefulWidget {
  const GlossaryPage({super.key});

  @override
  State<GlossaryPage> createState() => _GlossaryPageState();
}

class _GlossaryPageState extends State<GlossaryPage> {
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final categories = GlossaryService.getCategories();
    
    List<GlossaryTerm> terms;
    if (_searchQuery.isNotEmpty) {
      terms = GlossaryService.search(_searchQuery);
    } else if (_selectedCategory != null) {
      terms = GlossaryService.getTermsByCategory(_selectedCategory!);
    } else {
      terms = GlossaryService.getAllTerms();
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.menu_book_rounded),
            const SizedBox(width: 12),
            Text(
              'Glosario',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header con búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Barra de búsqueda
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Buscar término...',
                      prefixIcon: const Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      hintStyle: GoogleFonts.poppins(color: Colors.grey),
                    ),
                    style: GoogleFonts.poppins(),
                  ),
                ),
                const SizedBox(height: 12),
                // Chips de categorías
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _CategoryChip(
                        label: 'Todos',
                        isSelected: _selectedCategory == null && _searchQuery.isEmpty,
                        onTap: () => setState(() {
                          _selectedCategory = null;
                          _searchQuery = '';
                        }),
                      ),
                      ...categories.map((cat) => _CategoryChip(
                        label: cat,
                        isSelected: _selectedCategory == cat,
                        onTap: () => setState(() => _selectedCategory = cat),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Contador de resultados
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  '${terms.length} términos',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de términos
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: terms.length,
              itemBuilder: (context, index) {
                final term = terms[index];
                return _TermCard(term: term);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _TermCard extends StatelessWidget {
  final GlossaryTerm term;

  const _TermCard({required this.term});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showDetail(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          term.term,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (term.fullName != term.term)
                          Text(
                            term.fullName,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                term.definition,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCategoryColor(term.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  term.category,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getCategoryColor(term.category),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _DefinitionModal(term: term),
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
}

/// Botón flotante para acceder al glosario
class GlossaryFAB extends StatelessWidget {
  const GlossaryFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const GlossaryPage()),
      ),
      icon: const Icon(Icons.menu_book_rounded),
      label: const Text('Glosario'),
      backgroundColor: Colors.indigo[600],
      foregroundColor: Colors.white,
    );
  }
}

