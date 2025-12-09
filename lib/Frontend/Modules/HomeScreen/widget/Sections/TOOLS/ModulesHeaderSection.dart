import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ModulesHeaderSection extends StatelessWidget {
  final int modulesCount;
  final String selectedCategory;
  final Function(String) onCategoryRemoved;
  final TextEditingController searchController;

  const ModulesHeaderSection({
    super.key,
    required this.modulesCount,
    required this.selectedCategory,
    required this.onCategoryRemoved,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Barra de búsqueda
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por título, contenido...',
                hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: GoogleFonts.inter(fontSize: 15),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Info y filtros activos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$modulesCount módulos',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              if (selectedCategory != 'Todas')
                Chip(
                  label: Text(
                    selectedCategory,
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                  onDeleted: () => onCategoryRemoved(selectedCategory),
                ),
            ],
          ),
        ],
      ),
    );
  }
}