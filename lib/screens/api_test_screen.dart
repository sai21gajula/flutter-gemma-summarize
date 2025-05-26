import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notes_provider.dart';
import '../services/gemma_service.dart';
import '../models/note.dart';
import '../config/api_config.dart';

class APITestScreen extends StatefulWidget {
  const APITestScreen({super.key});

  @override
  State<APITestScreen> createState() => _APITestScreenState();
}

class _APITestScreenState extends State<APITestScreen> {
  final TextEditingController _testController = TextEditingController();
  String _result = '';
  bool _isLoading = false;
  String _debugInfo = '';
  Map<String, dynamic>? _connectionTestResult;

  @override
  void initState() {
    super.initState();
    _testController.text = 'This is a test text for AI processing.';
    _updateDebugInfo();
    _testConnectionOnInit();
  }

  void _updateDebugInfo() {
    setState(() {
      _debugInfo = '''
DEBUG INFO:
- Platform: Web
- Storage: SharedPreferences (Browser LocalStorage)
- API Key configured: ${ApiConfig.isApiKeyConfigured}
- API Key length: ${ApiConfig.gemmaApiKey.length} characters
- API Endpoint: ${ApiConfig.baseUrl}
- Model: ${ApiConfig.modelName}
- Connect Timeout: ${ApiConfig.connectTimeout.inSeconds}s
- Receive Timeout: ${ApiConfig.receiveTimeout.inSeconds}s
''';
    });
  }

  Future<void> _testConnectionOnInit() async {
    final gemmaService = GemmaService();
    final result = await gemmaService.testConnection();
    setState(() {
      _connectionTestResult = result;
    });
  }

  Future<void> _testAPI(AIOperationType operation) async {
    setState(() {
      _isLoading = true;
      _result = 'Testing ${operation.displayName}...';
    });

    try {
      final gemmaService = GemmaService();
      final result = await gemmaService.performAIOperation(_testController.text, operation);
      
      setState(() {
        _result = '''
✅ SUCCESS!
Operation: ${operation.displayName}
Result: $result
''';
      });
    } catch (e) {
      setState(() {
        _result = '''
❌ ERROR!
Operation: ${operation.displayName}
Error: $e
''';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing connection...';
    });

    try {
      final gemmaService = GemmaService();
      final result = await gemmaService.testConnection();
      
      setState(() {
        _connectionTestResult = result;
        if (result['success']) {
          _result = '✅ API Connection successful!\n\nDetails:\n${result['details']}';
        } else {
          _result = '❌ API Connection failed!\n\nError: ${result['message']}\n\nDetails:\n${result['details']}';
        }
      });
    } catch (e) {
      setState(() {
        _result = '❌ Connection test error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testStorage() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing storage...';
    });

    try {
      final notesProvider = context.read<NotesProvider>();
      
      // Test creating a note
      await notesProvider.createNote(
        title: 'Test Note',
        content: 'This is a test note to verify storage is working.',
        tags: ['test'],
      );
      
      // Test loading notes
      await notesProvider.loadNotes();
      
      setState(() {
        _result = '''
✅ Storage test successful!
Notes count: ${notesProvider.notes.length}
Storage info: ${notesProvider.getStorageInfo()}
''';
      });
    } catch (e) {
      setState(() {
        _result = '❌ Storage test failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API & Storage Test'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Debug Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _debugInfo,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            
            // Connection Status
            if (_connectionTestResult != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _connectionTestResult!['success'] 
                    ? Colors.green[50] 
                    : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _connectionTestResult!['success'] 
                      ? Colors.green 
                      : Colors.red,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _connectionTestResult!['success'] 
                            ? Icons.check_circle 
                            : Icons.error,
                          color: _connectionTestResult!['success'] 
                            ? Colors.green 
                            : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _connectionTestResult!['success'] 
                            ? 'API Connected' 
                            : 'API Connection Failed',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _connectionTestResult!['success'] 
                              ? Colors.green[800] 
                              : Colors.red[800],
                          ),
                        ),
                      ],
                    ),
                    if (!_connectionTestResult!['success']) ...[
                      const SizedBox(height: 8),
                      Text(
                        _connectionTestResult!['message'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[700],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 16),
            
            // Test Input
            TextField(
              controller: _testController,
              decoration: const InputDecoration(
                labelText: 'Test Text',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            // Test Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _testConnection,
                  child: const Text('Test Connection'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testStorage,
                  child: const Text('Test Storage'),
                ),
                ...AIOperationType.values.map((operation) =>
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _testAPI(operation),
                    child: Text('Test ${operation.displayName}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Results
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Text(
                        _result.isEmpty ? 'Click a test button to start...' : _result,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _testController.dispose();
    super.dispose();
  }
}
