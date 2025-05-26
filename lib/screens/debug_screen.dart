import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notes_provider.dart';
import '../models/note.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final TextEditingController _testTextController = TextEditingController();
  String _apiTestResult = '';
  bool _isTestingApi = false;

  @override
  void dispose() {
    _testTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug & Testing'),
        backgroundColor: Colors.orange.shade100,
      ),
      body: Consumer<NotesProvider>(
        builder: (context, notesProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Storage Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Storage Information',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(notesProvider.getStorageInfo()),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // API Testing Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'API Testing',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _testTextController,
                          decoration: const InputDecoration(
                            labelText: 'Test text for AI operation',
                            hintText: 'Enter some text to test AI functionality',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: AIOperationType.values.map((operation) {
                            return ElevatedButton(
                              onPressed: _isTestingApi ? null : () => _testAIOperation(notesProvider, operation),
                              child: Text('${operation.icon} ${operation.displayName}'),
                            );
                          }).toList(),
                        ),
                        if (_isTestingApi)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(width: 12),
                                Text('Testing API...'),
                              ],
                            ),
                          ),
                        if (_apiTestResult.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _apiTestResult.startsWith('Error') 
                                  ? Colors.red.shade50 
                                  : Colors.green.shade50,
                              border: Border.all(
                                color: _apiTestResult.startsWith('Error') 
                                    ? Colors.red 
                                    : Colors.green,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _apiTestResult,
                              style: TextStyle(
                                color: _apiTestResult.startsWith('Error') 
                                    ? Colors.red.shade700 
                                    : Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Database Testing Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Database Testing',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () => _createTestNote(notesProvider),
                              child: const Text('Create Test Note'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _clearAllData(notesProvider),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Clear All Data'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => _exportData(notesProvider),
                          child: const Text('Export Data (Debug)'),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Error Display
                if (notesProvider.error != null)
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Error',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            notesProvider.error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _testAIOperation(NotesProvider provider, AIOperationType operation) async {
    if (_testTextController.text.trim().isEmpty) {
      setState(() {
        _apiTestResult = 'Error: Please enter some test text';
      });
      return;
    }

    setState(() {
      _isTestingApi = true;
      _apiTestResult = '';
    });

    try {
      final result = await provider.performAIOperation(_testTextController.text, operation);
      setState(() {
        _apiTestResult = 'Success! Result:\n$result';
      });
    } catch (e) {
      setState(() {
        _apiTestResult = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isTestingApi = false;
      });
    }
  }

  Future<void> _createTestNote(NotesProvider provider) async {
    await provider.createNote(
      title: 'Test Note ${DateTime.now().millisecondsSinceEpoch}',
      content: 'This is a test note created at ${DateTime.now()}.\n\nIt contains some sample text to test the AI operations.',
      tags: ['test', 'debug'],
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test note created successfully!')),
      );
    }
  }

  Future<void> _clearAllData(NotesProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('This will delete all notes. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.clearAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared!')),
        );
      }
    }
  }

  Future<void> _exportData(NotesProvider provider) async {
    try {
      final data = await provider.exportNotes();
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exported Data'),
            content: SingleChildScrollView(
              child: SelectableText(data),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${e.toString()}')),
        );
      }
    }
  }
}
