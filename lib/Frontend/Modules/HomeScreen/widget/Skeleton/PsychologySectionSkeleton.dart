// HomeScreen/widgets/home_sections/home_skeletons.dart
import 'package:flutter/material.dart';

class PsychologySectionSkeleton extends StatelessWidget {
  const PsychologySectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(
            left: index == 0 ? 22 : 22,
            right: index == 0 ? 0 : 8,
          ),
          child: _buildPsychologyCardSkeleton(),
        );
      },
    );
  }

  Widget _buildPsychologyCardSkeleton() {
    return Container(
      width: 300,
      height: 160,
      margin: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(207, 255, 255, 255), // Color base más claro
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 100,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 231, 231, 231), // Gris medio claro
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 231, 231, 231), // Gris medio claro
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Título skeleton
            Container(
              width: 190,
              height: 35,
              decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 231, 231, 231), // Gris medio claro
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            // Descripción skeleton
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                     color: const Color(0xFFECECEC), // Gris muy claro
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                     color: const Color(0xFFECECEC), // Gris muy claro
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 220,
                    height: 14,
                    decoration: BoxDecoration(
                     color: const Color(0xFFECECEC), // Gris muy claro
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Footer skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 90,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDDDDD), // Gris medio
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Container(
                  width: 100,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D1D1), // Gris medio-oscuro
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ChatSuggestionsSkeleton extends StatelessWidget {
  const ChatSuggestionsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 2,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(
            left: index == 0 ? 20 : 16,
            right: index == 1 ? 20 : 0,
          ),
          child: _buildChatSuggestionCardSkeleton(),
        );
      },
    );
  }

  Widget _buildChatSuggestionCardSkeleton() {
    return Container(
      width: 280,
      height: 320,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5), // Color base claro
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0), // Gris medio
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCFCFCF), // Gris más oscuro
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: 200,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFDBDBDB), // Gris intermedio
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0), // Gris muy claro
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDEDED), // Gris claro
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 250,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F3F3), // Gris más claro
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 220,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAEAEA), // Gris medio-claro
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFD4D4D4), // Gris medio
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}