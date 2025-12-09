import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class CalendarSkeleton extends StatelessWidget {
  const CalendarSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
      child: Column(
        children: [
          // Calendario principal skeleton
          Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(179, 255, 255, 255),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(5),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[200]!,
              highlightColor: Colors.grey[100]!,
              child: const SizedBox(
                height: 345,
                width: double.infinity,
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Leyenda skeleton
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Shimmer.fromColors(
              baseColor: const Color.fromARGB(179, 255, 255, 255),
              highlightColor: const Color.fromARGB(179, 255, 255, 255),
              child: const SizedBox(
                height: 20,
                width: double.infinity,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
