import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Make sure .env is loaded before accessing these

  static String? get googleApiKey {
    return dotenv.env['GOOGLE_API_KEY'];
  }

  // You can add other keys here if needed
  // static String? get anotherApiKey {
  //   return dotenv.env['ANOTHER_API_KEY'];
  // }

  static void ensureEnvLoaded() {
    if (dotenv.env.isEmpty) {
        // This is a fallback, ideally main.dart ensures it's loaded.
        // Or throw an error if critical keys are missing.
        print("Warning: .env file doesn't seem to be loaded properly or is empty.");
    }
    if (googleApiKey == null) {
        print("Warning: GOOGLE_PLACES_API_KEY is not found in .env. Features requiring it may fail.");
        // Consider throwing an error if this key is absolutely critical for app function
        // throw Exception("CRITICAL: GOOGLE_PLACES_API_KEY not found!");
    }
  }
}