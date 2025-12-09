// HomeScreen/widget/screenWidgets/frase_skeleton.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class FraseMotivacionalSkeleton extends StatelessWidget {
  const FraseMotivacionalSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
           
          // Texto de la frase skeleton
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}