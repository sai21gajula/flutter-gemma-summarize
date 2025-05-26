import 'package:dio/dio.dart';

void main() async {
  print('Testing Google AI Studio API connectivity...');
  
  final dio = Dio();
  const apiKey = 'AIzaSyDvGoDCplHBspV785xlh-2lBVi1_KaMWCg';
  const baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  const modelName = 'gemini-1.5-flash';
  
  try {
    print('Making request to: $baseUrl/models/$modelName:generateContent');
    
    final response = await dio.post(
      '$baseUrl/models/$modelName:generateContent?key=$apiKey',
      data: {
        'contents': [
          {
            'parts': [
              {
                'text': 'Summarize this text briefly: Hello world, this is a test message for API connectivity.'
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
      options: Options(
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );
    
    print('Response Status: ${response.statusCode}');
    print('Response Data: ${response.data}');
    
    if (response.statusCode == 200) {
      final data = response.data;
      if (data['candidates'] != null && data['candidates'].isNotEmpty) {
        final content = data['candidates'][0]['content']['parts'][0]['text'];
        print('SUCCESS! Generated content: $content');
      }
    }
    
  } catch (e) {
    print('ERROR: $e');
    if (e is DioException && e.response != null) {
      print('Response Status: ${e.response!.statusCode}');
      print('Response Data: ${e.response!.data}');
    }
  }
}
