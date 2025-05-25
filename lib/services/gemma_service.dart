import 'package:dio/dio.dart';
import '../config/api_config.dart';

class GemmaService {
  final Dio _dio = Dio();
  
  // Using Google AI Studio API for Gemma/Gemini models
  // Get your free API key from: https://makersuite.google.com/app/apikey
  
  GemmaService() {
    _dio.options.baseUrl = ApiConfig.baseUrl;
    _dio.options.connectTimeout = ApiConfig.connectTimeout;
    _dio.options.receiveTimeout = ApiConfig.receiveTimeout;
    _dio.options.headers = {
      'Content-Type': 'application/json',
    };
  }

  Future<String> summarizeText(String text) async {
    // Check if API key is configured
    if (!ApiConfig.isApiKeyConfigured) {
      throw Exception('API key not configured. Please add your Gemma API key in lib/config/api_config.dart');
    }

    try {
      // Using Google AI Studio Gemini API with latest model
      final response = await _dio.post(
        '/models/${ApiConfig.modelName}:generateContent?key=${ApiConfig.gemmaApiKey}',
        data: {
          'contents': [
            {
              'parts': [
                {
                  'text': 'Please provide a concise summary of the following text. Focus on the main points and key information:\n\n$text'
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 200,
          },
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final content = data['candidates'][0]['content']['parts'][0]['text'];
          return content.trim();
        } else {
          throw Exception('No summary generated');
        }
      } else {
        throw Exception('API request failed: ${response.statusMessage}');
      }
      
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Request timeout. Please try again.');
      } else if (e.response?.statusCode == 400) {
        throw Exception('Invalid request. Please check your input text.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Invalid API key or quota exceeded. Please check your API key.');
      } else if (e.response?.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please try again later.');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }

  // Method to test connection with the API
  Future<bool> testConnection() async {
    if (!ApiConfig.isApiKeyConfigured) {
      return false;
    }
    
    try {
      // Test with a simple short text
      await summarizeText("Test connection to Gemma API.");
      return true;
    } catch (e) {
      return false;
    }
  }

  // Method to get available models (optional)
  Future<List<String>> getAvailableModels() async {
    if (!ApiConfig.isApiKeyConfigured) {
      throw Exception('API key not configured');
    }

    try {
      final response = await _dio.get(
        '/models?key=${ApiConfig.gemmaApiKey}',
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        final models = <String>[];
        for (final model in data['models']) {
          models.add(model['name']);
        }
        return models;
      } else {
        throw Exception('Failed to fetch models');
      }
    } catch (e) {
      throw Exception('Error fetching models: ${e.toString()}');
    }
  }
}
