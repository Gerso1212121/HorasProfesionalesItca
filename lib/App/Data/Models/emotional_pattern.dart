class EmotionalPattern {
  final String userEmotion;
  final String context;
  final List<String> userExamples;
  final List<String> assistantResponses;
  double effectiveness;
  int usageCount;

  EmotionalPattern({
    required this.userEmotion,
    required String userMessage,
    required String assistantResponse,
    required this.context,
    required this.effectiveness,
  })  : userExamples = [userMessage],
        assistantResponses = [assistantResponse],
        usageCount = 1;

  void updateEffectiveness(double newEffectiveness) {
    effectiveness =
        (effectiveness * usageCount + newEffectiveness) / (usageCount + 1);
    usageCount++;
  }

  void addExample(String userMessage, String assistantResponse) {
    userExamples.add(userMessage);
    assistantResponses.add(assistantResponse);

    if (userExamples.length > 5) {
      userExamples.removeAt(0);
      assistantResponses.removeAt(0);
    }
  }

  List<String> getTopResponses() {
    return assistantResponses.take(2).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'userEmotion': userEmotion,
      'context': context,
      'userExamples': userExamples,
      'assistantResponses': assistantResponses,
      'effectiveness': effectiveness,
      'usageCount': usageCount,
    };
  }

  factory EmotionalPattern.fromJson(Map<String, dynamic> json) {
    return EmotionalPattern(
      userEmotion: json['userEmotion'] ?? '',
      userMessage: json['userExamples']?.isNotEmpty == true
          ? json['userExamples'][0]
          : '',
      assistantResponse: json['assistantResponses']?.isNotEmpty == true
          ? json['assistantResponses'][0]
          : '',
      context: json['context'] ?? '',
      effectiveness: (json['effectiveness'] ?? 0.5).toDouble(),
    )..usageCount = json['usageCount'] ?? 1;
  }
}
