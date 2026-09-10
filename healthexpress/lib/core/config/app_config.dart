class AppConfig {
  // Backend API URL (Hostinger Production PHP REST API with Live MySQL)
  static const String apiBaseUrl = 'https://vedvaidyam.com/healthexpress/api';

  // Mapbox Access Token
  static const String mapboxAccessToken =
      'pk.eyJ1IjoicGF2YW5rdW1hcnN3YW15IiwiYSI6ImNtNnc1c3ZpdTBkdGgyanM5b25rN2ZqcncifQ.Ls1e2W6rx3apoBsStWa5Ow';

  // Razorpay Live Credentials
  static const String razorpayKeyId = 'rzp_live_StBUehIpeULYuL';
  static const String razorpayKeySecret = 'M76UWnmNsVE7hU5QrkriZuor';

  // Agora WebRTC Credentials
  static const String agoraAppId = '7c9641fb497543d2b01fe6fe5fe0af15';
  static const String agoraPrimaryCertificate = '29afb318421747818086445f230f3c61';

  // Firebase Configuration (Web & Mobile)
  static const String firebaseApiKey = 'AIzaSyCU7Psyt8Rl5kQScIDAavvleuyNjkhVFxo';
  static const String firebaseAuthDomain = 'healthexpress-1.firebaseapp.com';
  static const String firebaseProjectId = 'healthexpress-1';
  static const String firebaseStorageBucket = 'healthexpress-1.firebasestorage.app';
  static const String firebaseMessagingSenderId = '575738669292';
  static const String firebaseAppId = '1:575738669292:web:305a1fce4415b605c3ddc9';
  static const String firebaseMeasurementId = 'G-11RHHGM6T0';

  // NVIDIA NIM API (OpenAI-compatible)
  static const String nvidiaApiBaseUrl = 'https://integrate.api.nvidia.com/v1';
  static const String nvidiaApiKey =
      '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';
  static const String nvidiaModel = 'openai/gpt-oss-20b';

  // Sarvam AI (Live Speech-to-Text, Multilingual Indian Voice & LLM)
  static const String sarvamApiKey = 'sk_n4tzuy3c_JIUK6l5ExNHHGoiiAGwvroYh';
  static const String sarvamFallbackApiKey = 'sk_hr3tv6ew_UBzXjEc9RqZLGuMpzyctBUQC';
  static const List<String> sarvamApiKeys = [
    sarvamApiKey,
    sarvamFallbackApiKey,
  ];
  static const String sarvamSttEndpoint = 'https://api.sarvam.ai/speech-to-text';
  static const String sarvamSttModel = 'saaras:v3';
  static const String sarvamChatEndpoint = 'https://api.sarvam.ai/v1/chat/completions';
  static const String sarvamChatModel = 'sarvam-105b-conversations';
}
