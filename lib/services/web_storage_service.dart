import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';

class WebStorageService {
  static final WebStorageService _instance = WebStorageService._internal();
  factory WebStorageService() => _instance;
  WebStorageService._internal();

  static const String _notesKey = 'flutter_gemma_notes';
  static const String _nextIdKey = 'flutter_gemma_notes_next_id';

  // Create a new note
  Future<int> createNote(Note note) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get next ID
    int nextId = prefs.getInt(_nextIdKey) ?? 1;
    
    // Get existing notes
    List<Note> notes = await getAllNotes();
    
    // Create note with ID
    final noteWithId = note.copyWith(id: nextId);
    notes.insert(0, noteWithId);
    
    // Save to localStorage
    await _saveNotes(notes);
    
    // Update next ID
    await prefs.setInt(_nextIdKey, nextId + 1);
    
    return nextId;
  }

  // Get all notes
  Future<List<Note>> getAllNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getStringList(_notesKey) ?? [];
    
    return notesJson.map((json) => Note.fromMap(jsonDecode(json))).toList();
  }

  // Get a note by ID
  Future<Note?> getNoteById(int id) async {
    final notes = await getAllNotes();
    try {
      return notes.firstWhere((note) => note.id == id);
    } catch (e) {
      return null;
    }
  }

  // Update a note
  Future<int> updateNote(Note note) async {
    final notes = await getAllNotes();
    final index = notes.indexWhere((n) => n.id == note.id);
    
    if (index != -1) {
      notes[index] = note;
      await _saveNotes(notes);
      return 1; // Success
    }
    return 0; // Not found
  }

  // Delete a note
  Future<int> deleteNote(int id) async {
    final notes = await getAllNotes();
    final initialLength = notes.length;
    notes.removeWhere((note) => note.id == id);
    
    if (notes.length != initialLength) {
      await _saveNotes(notes);
      return 1; // Success
    }
    return 0; // Not found
  }

  // Search notes by title or content
  Future<List<Note>> searchNotes(String query) async {
    final notes = await getAllNotes();
    final lowercaseQuery = query.toLowerCase();
    
    return notes.where((note) =>
        note.title.toLowerCase().contains(lowercaseQuery) ||
        note.content.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  // Get notes by tag
  Future<List<Note>> getNotesByTag(String tag) async {
    final notes = await getAllNotes();
    return notes.where((note) => note.tags.contains(tag)).toList();
  }

  // Private helper to save notes
  Future<void> _saveNotes(List<Note> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = notes.map((note) => jsonEncode(note.toMap())).toList();
    await prefs.setStringList(_notesKey, notesJson);
  }

  // Clear all data (for testing/reset)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notesKey);
    await prefs.remove(_nextIdKey);
  }

  // Export notes as JSON (for backup)
  Future<String> exportNotes() async {
    final notes = await getAllNotes();
    return jsonEncode(notes.map((note) => note.toMap()).toList());
  }

  // Import notes from JSON (for restore)
  Future<void> importNotes(String jsonData) async {
    try {
      final List<dynamic> notesData = jsonDecode(jsonData);
      final notes = notesData.map((data) => Note.fromMap(data)).toList();
      await _saveNotes(notes);
    } catch (e) {
      throw Exception('Failed to import notes: ${e.toString()}');
    }
  }
}
