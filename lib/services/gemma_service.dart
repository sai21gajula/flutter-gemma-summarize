import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/note.dart';

class GemmaService {
  final Dio _dio = Dio();
  
  // Using Google AI Studio API for Gemini models
  // Get your free API key from: https://aistudio.google.com/app/apikey
  
  GemmaService() {
    _dio.options.baseUrl = ApiConfig.baseUrl;
    _dio.options.connectTimeout = ApiConfig.connectTimeout;
    _dio.options.receiveTimeout = ApiConfig.receiveTimeout;
    _dio.options.headers = {
      'Content-Type': 'application/json',
    };
    
    // Add interceptor for debugging
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: kDebugMode,
        responseBody: kDebugMode,
        logPrint: (obj) {
          if (kDebugMode) {
            print('[GemmaService] $obj');
          }
        },
      ),
    );
  }

  Future<String> summarizeText(String text) async {
    return await performAIOperation(text, AIOperationType.summarize);
  }

  Future<String> performAIOperation(String text, AIOperationType operationType) async {
    // Check if API key is configured
    if (!ApiConfig.isApiKeyConfigured) {
      throw Exception('API key not configured. Please add your API key in lib/config/api_config.dart');
    }

    try {
      // Create the prompt based on operation type
      final prompt = '${operationType.prompt}\n\n$text';
      
      // Adjust generation config based on operation type
      final generationConfig = _getGenerationConfig(operationType);
      
      if (kDebugMode) {
        print('[GemmaService] Making API request to: ${ApiConfig.baseUrl}/models/${ApiConfig.modelName}:generateContent');
        print('[GemmaService] Prompt: $prompt');
      }
      
      // Using Google AI Studio Gemini API
      final response = await _dio.post(
        '/models/${ApiConfig.modelName}:generateContent?key=${ApiConfig.gemmaApiKey}',
        data: {
          'contents': [
            {
              'parts': [
                {
                  'text': prompt
                }
              ]
            }
          ],
          'generationConfig': generationConfig,
        },
      );
      
      if (kDebugMode) {
        print('[GemmaService] Response status: ${response.statusCode}');
        print('[GemmaService] Response data: ${response.data}');
      }
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final content = data['candidates'][0]['content']['parts'][0]['text'];
          return content.trim();
        } else {
          throw Exception('No ${operationType.displayName.toLowerCase()} generated. Response: ${data.toString()}');
        }
      } else {
        throw Exception('API request failed: ${response.statusMessage} (${response.statusCode})');
      }
      
    } on DioException catch (e) {
      if (kDebugMode) {
        print('[GemmaService] DioException: ${e.toString()}');
        print('[GemmaService] Response data: ${e.response?.data}');
      }
      
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Request timeout. Please try again.');
      } else if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData != null && errorData['error'] != null) {
          throw Exception('Invalid request: ${errorData['error']['message']}');
        }
        throw Exception('Invalid request. Please check your input text.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Invalid API key or quota exceeded. Please check your API key.');
      } else if (e.response?.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please try again later.');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Model not found. The model "${ApiConfig.modelName}" might not be available.');
      } else {
        final errorMessage = e.response?.data?['error']?['message'] ?? e.message;
        throw Exception('Network error: $errorMessage');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[GemmaService] Unexpected error: ${e.toString()}');
      }
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }
    }
  }

  Map<String, dynamic> _getGenerationConfig(AIOperationType operationType) {
    switch (operationType) {
      case AIOperationType.summarize:
        return {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 200,
        };
      case AIOperationType.rewrite:
        return {
          'temperature': 0.8,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 500,
        };
      case AIOperationType.paraphrase:
        return {
          'temperature': 0.9,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 400,
        };
      case AIOperationType.expand:
        return {
          'temperature': 0.8,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 800,
        };
      case AIOperationType.simplify:
        return {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 300,
        };
    }
  }

  // Method to test connection with the API
  Future<Map<String, dynamic>> testConnection() async {
    final result = <String, dynamic>{
      'success': false,
      'message': '',
      'details': {},
    };
    
    if (!ApiConfig.isApiKeyConfigured) {
      result['message'] = 'API key not configured';
      return result;
    }
    
    try {
      if (kDebugMode) {
        print('[GemmaService] Testing connection...');
      }
      
      // Test with a simple short text
      final response = await performAIOperation("Hello", AIOperationType.summarize);
      result['success'] = true;
      result['message'] = 'Connection successful';
      result['details'] = {
        'model': ApiConfig.modelName,
        'baseUrl': ApiConfig.baseUrl,
        'response': response.substring(0, response.length < 100 ? response.length : 100),
      };
      
      if (kDebugMode) {
        print('[GemmaService] Connection test successful');
      }
      
    } catch (e) {
      result['message'] = e.toString();
      result['details'] = {
        'model': ApiConfig.modelName,
        'baseUrl': ApiConfig.baseUrl,
        'apiKeyLength': ApiConfig.gemmaApiKey.length,
      };
      
      if (kDebugMode) {
        print('[GemmaService] Connection test failed: $e');
      }
    }
    
    return result;
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
