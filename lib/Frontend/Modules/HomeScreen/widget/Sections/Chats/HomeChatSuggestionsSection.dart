// HomeScreen/widgets/home_sections/home_chat_suggestions.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/ViewModels/HomeViewModel.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/widget/Sections/Chats/Cards/ConversationSparkCard.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/widget/Skeleton/PsychologySectionSkeleton.dart';

class HomeChatSuggestionsSection extends StatelessWidget {
  final HomeViewModel viewModel;

  const HomeChatSuggestionsSection({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(
            'Sugerencias de chat',
            style: GoogleFonts.itim(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 320,
          child: viewModel.isLoadingSuggestions
              ? const ChatSuggestionsSkeleton()
              : _buildChatSuggestionsList(),
        ),
      ],
    );
  }

  Widget _buildChatSuggestionsList() {
    final todaysSuggestions = viewModel.todaySuggestions;
    if (todaysSuggestions.isEmpty) {
      return const Center(
        child: Text(
          'No hay sugerencias disponibles',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: todaysSuggestions.length,
      itemBuilder: (context, index) {
        final sug = todaysSuggestions[index];
        return Padding(
          padding: EdgeInsets.only(
            left: index == 0 ? 15 : 0,
            right: index == todaysSuggestions.length - 1 ? 0 : 0,
          ),
          child: ConversationSparkCard(
            title: sug.topic,
            description: sug.summary,
            cardColor: sug.backgroundColor,
            symbol: sug.emojiIcon,
            iconAsset: sug.customIcon,
            conversationStarter: sug.prompt,
            onSelect: () {
              // TODO: Implementar navegación al chat con el prompt
            },
          ),
        );
      },
    );
  }
}