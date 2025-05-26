class ApiConfig {
  // Google AI Studio API key for Gemma models
  // Get your free API key from: https://aistudio.google.com/app/apikey
  // IMPORTANT: Replace this with your actual API key or use environment variables
  static const String gemmaApiKey = 'AIzaSyDtE857DLjHT7WRyWInBuauJ0sml1KfYDo';
  
  // Google AI Studio base URL for Gemma models (uses same infrastructure as Gemini)
  static const String baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  
  // Using Gemini models which are available in Google AI Studio
  // Available models: 
  // - gemini-1.5-flash (fast and efficient for text operations)
  // - gemini-1.5-pro (higher quality)
  // - gemma-3n-E2B-it (new efficient Gemma 3n model - 2B effective params)
  // - gemma-3n-E4B-it (new efficient Gemma 3n model - 4B effective params, good for summarization)
  static const String modelName = 'gemma-3n-e4b-it'; // Updated to new Gemma 3n model
  
  // Proxy server configuration (for web to bypass CORS)
  // Ensure your proxy server is running on this address and port
  static const String proxyBaseUrl = 'http://localhost:3001'; 
  static const String proxyEndpoint = '/api/gemma'; // The endpoint on your proxy

  // Request timeout settings
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
  
  // Validate if API key is configured
  static bool get isApiKeyConfigured => 
      gemmaApiKey.isNotEmpty && gemmaApiKey != 'AIzaSyDvGoDCplHBspV785xlh-2lBVi1_KaMWCg';
}