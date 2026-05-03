import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

// 10.0.2.2 is the Android emulator's alias for the host machine's localhost.
// Web, iOS simulator, and desktop all reach the host as plain localhost.
String get apiHost {
  if (kIsWeb) return 'localhost:8080';
  if (defaultTargetPlatform == TargetPlatform.android) return '10.0.2.2:8080';
  return 'localhost:8080';
}

// Python FastAPI RAG backend (uvicorn default port 8000).
// Note: start uvicorn with --host 0.0.0.0 for the Android emulator to reach it.
String get ragHost {
  // if (kIsWeb) return 'localhost:8000';
  // if (defaultTargetPlatform == TargetPlatform.android) return '10.0.2.2:8000';
  return '13.51.158.100:8000';
}
