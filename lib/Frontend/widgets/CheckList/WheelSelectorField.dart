import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Frontend/widgets/CheckList/WheelSelector.dart';

class WheelSelectorField extends StatelessWidget {
  final List<String> items;
  final String label;
  final String? selectedValue;
  final Function(String) onSelected;
  final String? Function(String?)? validator;

  const WheelSelectorField({
    super.key,
    required this.items,
    required this.label,
    required this.selectedValue,
    required this.onSelected,
    this.validator,
  });

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return WheelSelectorBottomSheet(
            items: items,
            selectedValue: selectedValue,
            title: label,
            onConfirm: (value) => onSelected(value),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.itim(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        
        const SizedBox(height: 8),
        
        InkWell(
          onTap: () => _showBottomSheet(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectedValue == null ? Colors.grey[300]! : const Color(0xFFF66B7D),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedValue ?? 'Seleccionar...',
                        style: GoogleFonts.itim(
                          fontSize: selectedValue == null ? 16 : 17,
                          color: selectedValue == null ? Colors.grey[500] : Colors.black87,
                          fontWeight: selectedValue == null ? FontWeight.normal : FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (selectedValue != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Toca para cambiar',
                            style: GoogleFonts.itim(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: selectedValue == null ? Colors.grey[100] : const Color(0xFFF66B7D).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_drop_down_rounded,
                    color: selectedValue == null ? Colors.grey[400] : const Color(0xFFF66B7D),
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Validator message
        if (validator != null && validator!(selectedValue) != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              validator!(selectedValue)!,
              style: GoogleFonts.itim(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ),
      ],
    );
  }
}