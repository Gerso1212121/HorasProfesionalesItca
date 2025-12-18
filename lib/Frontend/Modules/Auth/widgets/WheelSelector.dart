import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WheelSelectorBottomSheet extends StatefulWidget {
  final List<String> items;
  final String? selectedValue;
  final String title;
  final Function(String) onConfirm;

  const WheelSelectorBottomSheet({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.title,
    required this.onConfirm,
  });

  @override
  State<WheelSelectorBottomSheet> createState() => _WheelSelectorBottomSheetState();
}

class _WheelSelectorBottomSheetState extends State<WheelSelectorBottomSheet> {
  late FixedExtentScrollController _controller;
  late String _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = widget.selectedValue ?? widget.items.first;
    _controller = FixedExtentScrollController(
      initialItem: widget.selectedValue != null
          ? widget.items.indexOf(widget.selectedValue!)
          : 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barra de agarre
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Título
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: GoogleFonts.itim(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.grey),
              ),
            ],
          ),
          
          const SizedBox(height: 10),
          
          // Selector tipo rueda
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Stack(
              children: [
                // Líneas guía
                Center(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey[300]!, width: 1),
                        bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                      ),
                    ),
                  ),
                ),
                
                // Selector
                ListWheelScrollView.useDelegate(
                  controller: _controller,
                  itemExtent: 40,
                  perspective: 0.002,
                  diameterRatio: 2.0,
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _tempSelected = widget.items[index];
                    });
                  },
                  physics: const FixedExtentScrollPhysics(),
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: widget.items.length,
                    builder: (context, index) {
                      final isSelected = widget.items[index] == _tempSelected;
                      return Center(
                        child: Text(
                          widget.items[index],
                          style: GoogleFonts.itim(
                            fontSize: isSelected ? 16 : 14,
                            color: isSelected ? const Color(0xFFF66B7D) : Colors.grey[700],
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),

          
          
          // Botón de confirmar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onConfirm(_tempSelected);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF66B7D),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    'Confirmar selección',
                    style: GoogleFonts.itim(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}