class ApiConfig {
  // Google AI Studio API key for Gemma models
  // Get your free API key from: https://aistudio.google.com/app/apikey
  static const String gemmaApiKey = 'AIzaSyDtE857DLjHT7WRyWInBuauJ0sml1KfYDo';
  
  // Google AI Studio base URL for Gemma models (uses same infrastructure as Gemini)
  static const String baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  
  // Gemma 3 model - available in multiple sizes
  // Available Gemma 3 models: gemma-3-1b-it, gemma-3-4b-it, gemma-3-12b-it, gemma-3-27b-it
  static const String modelName = 'gemma-3-4b-it'; // Good balance of performance and speed for text summarization
  
  // Request timeout settings
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
  
  // Validate if API key is configured
  static bool get isApiKeyConfigured => 
      gemmaApiKey.isNotEmpty && gemmaApiKey != 'YOUR_GEMMA_API_KEY_HERE';
}