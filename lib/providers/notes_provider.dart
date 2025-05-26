import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import '../models/note.dart';
import '../services/database_service.dart';
import '../services/web_storage_service.dart';
import '../services/gemma_service.dart';

class NotesProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final WebStorageService _webStorageService = WebStorageService();
  final GemmaService _gemmaService = GemmaService();

  // Use web storage for web platform, SQLite for mobile/desktop
  bool get _isWeb => kIsWeb;
  
  dynamic get _storageService => _isWeb ? _webStorageService : _databaseService;

  List<Note> _notes = [];
  Note? _currentNote;
  bool _isLoading = false;
  String? _error;
  String? _searchQuery;

  // Getters
  List<Note> get notes => _searchQuery?.isEmpty ?? true 
      ? _notes 
      : _notes.where((note) => 
          note.title.toLowerCase().contains(_searchQuery!.toLowerCase()) ||
          note.content.toLowerCase().contains(_searchQuery!.toLowerCase())
        ).toList();
  
  Note? get currentNote => _currentNote;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get searchQuery => _searchQuery;

  // Initialize and load notes
  Future<void> initialize() async {
    await loadNotes();
  }

  // Load all notes from database
  Future<void> loadNotes() async {
    _setLoading(true);
    try {
      _notes = await _storageService.getAllNotes();
      _clearError();
    } catch (e) {
      _setError('Failed to load notes: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Create a new note
  Future<void> createNote({
    required String title,
    required String content,
    List<String> tags = const [],
  }) async {
    _setLoading(true);
    try {
      final now = DateTime.now();
      final note = Note(
        title: title,
        content: content,
        createdAt: now,
        updatedAt: now,
        tags: tags,
      );

      final id = await _storageService.createNote(note);
      final createdNote = note.copyWith(id: id);
      
      _notes.insert(0, createdNote);
      _currentNote = createdNote;
      _clearError();
    } catch (e) {
      _setError('Failed to create note: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Update an existing note
  Future<void> updateNote(Note note) async {
    _setLoading(true);
    try {
      final updatedNote = note.copyWith(updatedAt: DateTime.now());
      await _storageService.updateNote(updatedNote);
      
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = updatedNote;
        _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      }
      
      if (_currentNote?.id == note.id) {
        _currentNote = updatedNote;
      }
      
      _clearError();
    } catch (e) {
      _setError('Failed to update note: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Delete a note
  Future<void> deleteNote(int noteId) async {
    _setLoading(true);
    try {
      await _storageService.deleteNote(noteId);
      _notes.removeWhere((note) => note.id == noteId);
      
      if (_currentNote?.id == noteId) {
        _currentNote = null;
      }
      
      _clearError();
    } catch (e) {
      _setError('Failed to delete note: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Set current note
  void setCurrentNote(Note? note) {
    _currentNote = note;
    notifyListeners();
  }

  // Search notes
  void searchNotes(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Clear search
  void clearSearch() {
    _searchQuery = null;
    notifyListeners();
  }

  // Perform AI operation on selected text
  Future<String> performAIOperation(String selectedText, AIOperationType operationType) async {
    _setLoading(true);
    try {
      final result = await _gemmaService.performAIOperation(selectedText, operationType);
      _clearError();
      return result;
    } catch (e) {
      _setError('AI operation failed: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Test API connection
  Future<bool> testApiConnection() async {
    try {
      return await _gemmaService.testConnection();
    } catch (e) {
      _setError('Connection test failed: ${e.toString()}');
      return false;
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Get note by ID
  Note? getNoteById(int id) {
    try {
      return _notes.firstWhere((note) => note.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get notes by tag
  List<Note> getNotesByTag(String tag) {
    return _notes.where((note) => note.tags.contains(tag)).toList();
  }

  // Get all unique tags
  List<String> getAllTags() {
    final Set<String> tagSet = {};
    for (final note in _notes) {
      tagSet.addAll(note.tags);
    }
    return tagSet.toList()..sort();
  }

  // Debug: Get storage info
  String getStorageInfo() {
    return 'Platform: ${_isWeb ? 'Web (localStorage)' : 'Native (SQLite)'}\n'
           'Notes count: ${_notes.length}\n'
           'API configured: ${_gemmaService.testConnection}';
  }

  // Export notes (for backup/debugging)
  Future<String> exportNotes() async {
    if (_isWeb) {
      return await _webStorageService.exportNotes();
    } else {
      // For SQLite, we'd need to implement export
      return 'Export not implemented for SQLite yet';
    }
  }

  // Clear all data (for testing)
  Future<void> clearAllData() async {
    _setLoading(true);
    try {
      if (_isWeb) {
        await _webStorageService.clearAll();
      } else {
        // For SQLite, we'd need to implement clear
      }
      _notes.clear();
      _currentNote = null;
      _clearError();
    } catch (e) {
      _setError('Failed to clear data: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
}
