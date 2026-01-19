import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIConfig {
  static String get apiKey {
    return dotenv.env['OPENAI_API_KEY'] ?? '';
  }

  static String get baseUrl {
    return dotenv.env['OPENAI_BASE_URL'] ?? 'https://api.openai.com/v1';
  }

  static String get model {
    return dotenv.env['OPENAI_MODEL'] ?? 'gpt-3.5-turbo';
  }

  static int get maxTokens {
    return int.tryParse(dotenv.env['OPENAI_MAX_TOKENS'] ?? '1000') ?? 1000;
  }

  static double get temperature {
    return double.tryParse(dotenv.env['OPENAI_TEMPERATURE'] ?? '0.7') ?? 0.7;
  }

  static bool get isConfigured {
    return apiKey.isNotEmpty;
  }
}
