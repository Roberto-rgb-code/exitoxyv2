import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MarketplaceSearchFilters extends StatefulWidget {
  final void Function({
    required String type,
    required String keyword,
    required double minPrice,
    required double maxPrice,
    required double radius,
  }) onSearchChanged;

  const MarketplaceSearchFilters({
    super.key,
    required this.onSearchChanged,
  });

  @override
  State<MarketplaceSearchFilters> createState() => _MarketplaceSearchFiltersState();
}

class _MarketplaceSearchFiltersState extends State<MarketplaceSearchFilters> {
  String _selectedType = 'real_estate_agency';
  String _selectedKeyword = 'renta venta inmobiliaria';
  RangeValues _priceRange = const RangeValues(5000, 20000);
  double _radius = 5000;

  final List<Map<String, String>> _searchTypes = [
    {'value': 'real_estate_agency', 'label': 'Agencias Inmobiliarias'},
    {'value': 'lodging', 'label': 'Hospedaje'},
    {'value': 'establishment', 'label': 'Establecimientos'},
  ];

  final List<Map<String, String>> _keywords = [
    {'value': 'renta venta inmobiliaria', 'label': 'Inmobiliarias'},
    {'value': 'renta mensual departamento', 'label': 'Departamentos'},
    {'value': 'renta casa departamento', 'label': 'Casas y Departamentos'},
    {'value': 'inmueble renta', 'label': 'Inmuebles en Renta'},
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.filter_list,
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Filtros de Búsqueda',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Tipo de búsqueda
          Text(
            'Tipo de Establecimiento',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _searchTypes.map((type) {
              return DropdownMenuItem<String>(
                value: type['value'],
                child: Text(
                  type['label']!,
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedType = value!;
              });
              _triggerSearch();
            },
          ),
          const SizedBox(height: 16),

          // Palabra clave
          Text(
            'Palabra Clave',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedKeyword,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _keywords.map((keyword) {
              return DropdownMenuItem<String>(
                value: keyword['value'],
                child: Text(
                  keyword['label']!,
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedKeyword = value!;
              });
              _triggerSearch();
            },
          ),
          const SizedBox(height: 16),

          // Rango de precios
          Text(
            'Rango de Precios: \$${_priceRange.start.round()} - \$${_priceRange.end.round()}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          RangeSlider(
            values: _priceRange,
            min: 3000,
            max: 30000,
            divisions: 27,
            labels: RangeLabels(
              '\$${_priceRange.start.round()}',
              '\$${_priceRange.end.round()}',
            ),
            onChanged: (values) {
              setState(() {
                _priceRange = values;
              });
            },
            onChangeEnd: (values) {
              _triggerSearch();
            },
          ),
          const SizedBox(height: 16),

          // Radio de búsqueda
          Text(
            'Radio de Búsqueda: ${(_radius / 1000).toStringAsFixed(1)} km',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _radius,
            min: 1000,
            max: 10000,
            divisions: 9,
            label: '${(_radius / 1000).toStringAsFixed(1)} km',
            onChanged: (value) {
              setState(() {
                _radius = value;
              });
            },
            onChangeEnd: (value) {
              _triggerSearch();
            },
          ),
          const SizedBox(height: 20),

          // Botón de búsqueda manual
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _triggerSearch,
              icon: const Icon(Icons.search),
              label: const Text('Buscar Propiedades'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _triggerSearch() {
    widget.onSearchChanged(
      type: _selectedType,
      keyword: _selectedKeyword,
      minPrice: _priceRange.start,
      maxPrice: _priceRange.end,
      radius: _radius,
    );
  }
}
