import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/notes_provider.dart';
import '../models/note.dart';
import '../services/gemma_service.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagsController;
  bool _hasChanges = false;
  String? _selectedText;
  bool _isPerformingAI = false;
  Timer? _selectionCheckTimer;
  bool _isPointerDown = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _tagsController = TextEditingController(
      text: widget.note?.tags.join(', ') ?? '',
    );

    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
    _tagsController.addListener(_onTextChanged);
    
    // Start periodic selection checking for web platform
    if (kIsWeb) {
      _startSelectionPolling();
    }
  }

  @override
  void dispose() {
    _selectionCheckTimer?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  void _startSelectionPolling() {
    _selectionCheckTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _updateSelectedText(),
    );
  }

  void _onPointerDown() {
    _isPointerDown = true;
  }

  void _onPointerUp() {
    _isPointerDown = false;
    // Check selection after pointer up with a delay
    Future.delayed(const Duration(milliseconds: 100), () {
      _updateSelectedText();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isNewNote = widget.note == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNewNote ? 'New Note' : 'Edit Note'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saveNote,
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Title Input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _titleController,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                hintText: 'Note title...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              maxLines: null,
            ),
          ),

          // Tags Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _tagsController,
              decoration: InputDecoration(
                hintText: 'Tags (comma separated)...',
                prefixIcon: const Icon(Icons.tag),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),

          const SizedBox(height: 16),

          // Content Input with AI Tools
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // AI Operations Toolbar
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          'AI Tools',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (_selectedText != null && _selectedText!.isNotEmpty)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${_selectedText!.length} chars selected',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        const SizedBox(width: 12),
                        ...AIOperationType.values.map((operation) =>
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: _buildAIOperationButton(operation),
                          ),
                        ),
                        const Spacer(),
                        if (_selectedText != null && _selectedText!.isNotEmpty)
                          Tooltip(
                            message: 'Show selected text',
                            child: IconButton(
                              icon: const Icon(Icons.visibility, size: 18),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Selected Text'),
                                    content: Text('Selected: "${_selectedText!}"'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        Tooltip(
                          message: 'Help with text selection',
                          child: IconButton(
                            icon: const Icon(Icons.help_outline, size: 18),
                            onPressed: _showSelectionHelp,
                          ),
                        ),
                        if (_isPerformingAI)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                  ),

                  // Content TextField
                  Expanded(
                    child: Listener(
                      onPointerDown: (_) => _onPointerDown(),
                      onPointerUp: (_) => _onPointerUp(),
                      child: TextField(
                        controller: _contentController,
                        decoration: const InputDecoration(
                          hintText: 'Start writing your note...\n\nSelect text and use AI tools above to enhance your content.',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                        style: Theme.of(context).textTheme.bodyLarge,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        onTap: () {
                          // Multiple selection check attempts for web compatibility
                          Future.delayed(const Duration(milliseconds: 50), _updateSelectedText);
                          Future.delayed(const Duration(milliseconds: 200), _updateSelectedText);
                          Future.delayed(const Duration(milliseconds: 500), _updateSelectedText);
                        },
                        onChanged: (_) {
                          // Check selection after text changes
                          Future.delayed(const Duration(milliseconds: 100), _updateSelectedText);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
      floatingActionButton: kIsWeb && kDebugMode
          ? FloatingActionButton.small(
              onPressed: () {
                _updateSelectedText();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_selectedText != null
                        ? 'Selected: "${_selectedText!.substring(0, _selectedText!.length > 30 ? 30 : _selectedText!.length)}..."'
                        : 'No text selected'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: const Icon(Icons.refresh),
              tooltip: 'Check Selection',
            )
          : null,
    );
  }

  Widget _buildAIOperationButton(AIOperationType operation) {
    final isEnabled = _selectedText != null && _selectedText!.trim().isNotEmpty;
    
    return Tooltip(
      message: operation.displayName,
      child: InkWell(
        onTap: isEnabled && !_isPerformingAI
            ? () => _performAIOperation(operation)
            : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isEnabled
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            operation.icon,
            style: TextStyle(
              fontSize: 16,
              color: isEnabled
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  void _updateSelectedText() {
    if (!mounted) return;
    
    try {
      final selection = _contentController.selection;
      
      // Debug: Print selection info
      if (kDebugMode && kIsWeb) {
        print('Selection: start=${selection.start}, end=${selection.end}, isValid=${selection.isValid}, isCollapsed=${selection.isCollapsed}');
      }
      
      if (selection.isValid && !selection.isCollapsed) {
        final selectedText = _contentController.text.substring(
          selection.start,
          selection.end,
        );
        
        if (selectedText.trim().isNotEmpty) {
          if (_selectedText != selectedText) {
            setState(() {
              _selectedText = selectedText;
            });
            if (kDebugMode) {
              print('Selected text updated: "${selectedText.substring(0, selectedText.length > 50 ? 50 : selectedText.length)}..."');
            }
          }
          return;
        }
      }
      
      // Clear selection if no valid selection found
      if (_selectedText != null) {
        setState(() {
          _selectedText = null;
        });
        if (kDebugMode) {
          print('Selection cleared');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating selected text: $e');
      }
    }
  }

  void _showSelectionHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline),
            SizedBox(width: 8),
            Text('Text Selection Help'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'How to select text for AI operations:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (kIsWeb) ...[
                const Text('🌐 Web Browser:'),
                const SizedBox(height: 4),
                const Text('• Click and drag to select text\n• Double-click to select a word\n• Triple-click to select a line'),
                const SizedBox(height: 12),
                const Text(
                  'Note: Text selection detection on web may take a moment. The selection indicator will appear when text is detected.',
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                ),
              ] else ...[
                const Text('📱 Mobile/Desktop:'),
                const SizedBox(height: 4),
                const Text('• Tap and drag to select text\n• Double-tap to select a word\n• Use selection handles to adjust'),
              ],
              const SizedBox(height: 16),
              const Text(
                'Once text is selected:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text('• AI tool buttons will become enabled\n• Click any AI tool (📝 ✨ 📖 📈 💡) to process the selected text\n• Choose to replace the original text or insert the result after it'),
              if (_selectedText != null && _selectedText!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Currently selected: "${_selectedText!.length > 50 ? '${_selectedText!.substring(0, 50)}...' : _selectedText!}"',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Future<void> _performAIOperation(AIOperationType operation) async {
    if (_selectedText == null || _selectedText!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select text first. Tap and drag to select text in the note content.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    setState(() {
      _isPerformingAI = true;
    });
    try {
      final notesProvider = context.read<NotesProvider>();
      final result = await notesProvider.performAIOperation(
        _selectedText!,
        operation,
      );
      if (mounted) {
        _showAIResultDialog(operation, result);
      }
    } catch (e) {
      // Show a more user-friendly error for web/proxy issues
      final isWeb = identical(0, 0.0);
      final errorMsg = e.toString().contains('proxy')
        ? 'AI tools require a proxy server for web. Please see the README.'
        : e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI operation failed: $errorMsg'),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPerformingAI = false;
        });
      }
    }
  }

  void _showAIResultDialog(AIOperationType operation, String result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(operation.icon),
            const SizedBox(width: 8),
            Text(operation.displayName),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Original:',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(_selectedText!),
              ),
              const SizedBox(height: 16),
              Text(
                'AI Result:',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(result),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _replaceSelectedText(result);
              Navigator.of(context).pop();
            },
            child: const Text('Replace'),
          ),
          TextButton(
            onPressed: () {
              _insertAfterSelection(result);
              Navigator.of(context).pop();
            },
            child: const Text('Insert After'),
          ),
        ],
      ),
    );
  }

  void _replaceSelectedText(String newText) {
    final selection = _contentController.selection;
    if (selection.isValid && !selection.isCollapsed) {
      final text = _contentController.text;
      final newContent = text.replaceRange(selection.start, selection.end, newText);
      _contentController.text = newContent;
      _contentController.selection = TextSelection.collapsed(
        offset: selection.start + newText.length,
      );
    }
  }

  void _insertAfterSelection(String newText) {
    final selection = _contentController.selection;
    if (selection.isValid) {
      final text = _contentController.text;
      final insertPosition = selection.isCollapsed ? selection.start : selection.end;
      final newContent = text.replaceRange(
        insertPosition,
        insertPosition,
        '\n\n$newText',
      );
      _contentController.text = newContent;
      _contentController.selection = TextSelection.collapsed(
        offset: insertPosition + newText.length + 2,
      );
    }
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a title or content')),
      );
      return;
    }

    final finalTitle = title.isEmpty ? 'Untitled' : title;
    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    try {
      final notesProvider = context.read<NotesProvider>();

      if (widget.note == null) {
        // Create new note
        await notesProvider.createNote(
          title: finalTitle,
          content: content,
          tags: tags,
        );
      } else {
        // Update existing note
        final updatedNote = widget.note!.copyWith(
          title: finalTitle,
          content: content,
          tags: tags,
        );
        await notesProvider.updateNote(updatedNote);
      }

      setState(() {
        _hasChanges = false;
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.note == null ? 'Note created' : 'Note updated'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save note: $e')),
        );
      }
    }
  }
}
