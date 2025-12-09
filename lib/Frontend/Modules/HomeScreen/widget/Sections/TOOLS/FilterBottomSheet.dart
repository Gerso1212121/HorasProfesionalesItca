import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FilterBottomSheet extends StatelessWidget {
  final String selectedCategory;
  final String sortBy;
  final List<String> categories;
  final Function(String) onCategoryChanged;
  final Function(String) onSortByChanged;
  final VoidCallback onResetFilters;
  final VoidCallback onApplyFilters;

  const FilterBottomSheet({
    super.key,
    required this.selectedCategory,
    required this.sortBy,
    required this.categories,
    required this.onCategoryChanged,
    required this.onSortByChanged,
    required this.onResetFilters,
    required this.onApplyFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Categorías
          _buildFilterSection(
            'Categorías',
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((category) {
                final isSelected = selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) => onCategoryChanged(category),
                  selectedColor: const Color(0xFF3B82F6),
                  labelStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Ordenar por
          _buildFilterSection(
            'Ordenar por',
            Column(
              children: [
                _buildSortOption('Relevancia', 'relevancia'),
                _buildSortOption('Nombre (A-Z)', 'nombre'),
                _buildSortOption('Más recientes', 'reciente'),
                _buildSortOption('Más populares', 'popular'),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Botones de acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onResetFilters,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    'Limpiar filtros',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onApplyFilters,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF3B82F6),
                  ),
                  child: Text(
                    'Aplicar',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildSortOption(String label, String value) {
    final isSelected = sortBy == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSortByChanged(value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected 
              ? const Color(0xFF3B82F6).withOpacity(0.1)
              : Colors.transparent,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? const Color(0xFF3B82F6) : Colors.grey[700],
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: const Color(0xFF3B82F6),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}