import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
  }

  @override
  void dispose() {
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
                    ),
                    child: Row(
                      children: [
                        Text(
                          'AI Tools:',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_selectedText != null && _selectedText!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_selectedText!.length} chars selected',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        ...AIOperationType.values.map((operation) =>
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: _buildAIOperationButton(operation),
                          ),
                        ),
                        const Spacer(),
                        // Test selection button for debugging
                        if (_selectedText != null && _selectedText!.isNotEmpty)
                          TextButton(
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
                            child: const Text('Test', style: TextStyle(fontSize: 10)),
                          ),
                        if (_isPerformingAI)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                  ),

                  // Content TextField
                  Expanded(
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
                        // Delay to allow selection to complete
                        Future.delayed(const Duration(milliseconds: 100), _updateSelectedText);
                      },
                      onChanged: (_) {
                        // Delay to allow selection to complete
                        Future.delayed(const Duration(milliseconds: 100), _updateSelectedText);
                      },
                      onSelectionChanged: (TextSelection selection, SelectionChangedCause? cause) {
                        // This is called when text selection changes
                        Future.delayed(const Duration(milliseconds: 50), _updateSelectedText);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
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
    final selection = _contentController.selection;
    if (selection.isValid && !selection.isCollapsed) {
      final selectedText = _contentController.text.substring(
        selection.start,
        selection.end,
      );
      if (selectedText.trim().isNotEmpty) {
        setState(() {
          _selectedText = selectedText;
        });
        return;
      }
    }
    setState(() {
      _selectedText = null;
    });
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
      print('[NoteEditor] Performing ${operation.displayName} on: "${_selectedText!.substring(0, _selectedText!.length > 50 ? 50 : _selectedText!.length)}..."');
      
      final notesProvider = context.read<NotesProvider>();
      final result = await notesProvider.performAIOperation(
        _selectedText!,
        operation,
      );

      print('[NoteEditor] AI operation successful. Result length: ${result.length}');

      // Show result dialog
      if (mounted) {
        _showAIResultDialog(operation, result);
      }
    } catch (e) {
      print('[NoteEditor] AI operation failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI operation failed: $e'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _performAIOperation(operation),
            ),
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
