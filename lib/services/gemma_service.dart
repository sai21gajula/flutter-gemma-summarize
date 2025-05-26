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
    if (!ApiConfig.isApiKeyConfigured) {
      throw Exception('API key not configured. Please add your API key in lib/config/api_config.dart');
    }

    try {
      final prompt = '${operationType.prompt}\n\n$text';
      final generationConfig = _getGenerationConfig(operationType);
      final isWeb = kIsWeb;
      
      if (kDebugMode) {
        print('[GemmaService] Making API request');
        print('[GemmaService] Platform: ${isWeb ? 'Web' : 'Native'}');
        print('[GemmaService] Using model: ${ApiConfig.modelName}');
        print('[GemmaService] Operation: ${operationType.name}');
        print('[GemmaService] Text length: ${text.length}');
      }

      Response response;
      
      if (isWeb) {
        // For web, attempt direct API call (will demonstrate CORS issue)
        // Commenting out proxy server code for testing
        // final proxyUrl = 'http://localhost:3001/api/gemma';
        
        // try {
        //   response = await Dio().post(
        //     proxyUrl,
        //     data: {
        //       'apiKey': ApiConfig.gemmaApiKey,
        //       'model': ApiConfig.modelName,
        //       'contents': [
        //         {
        //           'parts': [
        //             {'text': prompt}
        //           ]
        //         }
        //       ],
        //       'generationConfig': generationConfig,
        //     },
        //     options: Options(
        //       headers: {
        //         'Content-Type': 'application/json',
        //       },
        //     ),
        //   );
        // } catch (e) {
        //   throw Exception('Web platform detected. Please start the proxy server with "npm start" in the project directory. Error: ${e.toString()}');
        // }

        // Direct API call for web (will likely cause CORS error)
        final endpoint = '/models/${ApiConfig.modelName}:generateContent?key=${ApiConfig.gemmaApiKey}';
        
        if (kDebugMode) {
          print('[GemmaService] Attempting DIRECT API call from Web to: ${ApiConfig.baseUrl}$endpoint');
        }
        
        response = await _dio.post(
          endpoint,
          data: {
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': generationConfig,
          },
          options: Options(
            headers: {
              'Content-Type': 'application/json',
            },
          ),
        );
      } else {
        // For native platforms, use direct API call
        final endpoint = '/models/${ApiConfig.modelName}:generateContent?key=${ApiConfig.gemmaApiKey}';
        
        response = await _dio.post(
          endpoint,
          data: {
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': generationConfig,
          },
          options: Options(
            headers: {
              'Content-Type': 'application/json',
            },
          ),
        );
      }

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final content = data['candidates'][0]['content'];
          if (content != null && content['parts'] != null && content['parts'].isNotEmpty) {
            final result = content['parts'][0]['text'] ?? 'No response generated';
            
            if (kDebugMode) {
              print('[GemmaService] API response success: ${result.substring(0, result.length < 100 ? result.length : 100)}...');
            }
            
            return result;
          }
        }
        throw Exception('Invalid response format from API');
      } else {
        throw Exception('API request failed: ${response.statusMessage} (${response.statusCode})');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('[GemmaService] DioException: ${e.message}');
        print('[GemmaService] Error type: ${e.type}');
      }
      throw Exception('Network/API error: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        print('[GemmaService] Unexpected error: ${e.toString()}');
      }
      throw Exception('Unexpected error: ${e.toString()}');
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
