class ApiConfig {
  // Google AI Studio API key for Gemma models
  // Get your free API key from: https://aistudio.google.com/app/apikey
  // IMPORTANT: Replace this with your actual API key or use environment variables
  static const String gemmaApiKey = 'AIzaSyDvGoDCplHBspV785xlh-2lBVi1_KaMWCg';
  
  // Google AI Studio base URL for Gemma models (uses same infrastructure as Gemini)
  static const String baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  
  // Using Gemini models which are available in Google AI Studio
  // Available models: gemini-1.5-flash, gemini-1.5-pro, gemini-pro
  static const String modelName = 'gemini-1.5-flash'; // Fast and efficient for text operations
  
  // Request timeout settings
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
  
  // Validate if API key is configured
  static bool get isApiKeyConfigured => 
      gemmaApiKey.isNotEmpty && gemmaApiKey != 'YOUR_GEMMA_API_KEY_HERE';
}