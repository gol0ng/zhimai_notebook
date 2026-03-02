import 'package:flutter/material.dart';
import '../../domain/entities/note.dart';
import '../../data/repositories/note_repository_impl.dart';

class NoteProvider extends ChangeNotifier {
  final NoteRepositoryImpl _repository;
  List<Note> _notes = [];
  Note? _currentNote;
  bool _isLoading = false;
  String? _error;

  NoteProvider(this._repository);

  List<Note> get notes => _notes;
  Note? get currentNote => _currentNote;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadNotes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notes = await _repository.getAllNotes();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNote(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentNote = await _repository.getNoteById(id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Note?> createNote(String title) async {
    try {
      final note = await _repository.createNote(title);
      _notes.insert(0, note);
      notifyListeners();
      return note;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> updateNoteTitle(String noteId, String title) async {
    try {
      final index = _notes.indexWhere((n) => n.id == noteId);
      if (index != -1) {
        final updatedNote = _notes[index].copyWith(
          title: title,
          updatedAt: DateTime.now(),
        );
        await _repository.updateNote(updatedNote);
        _notes[index] = updatedNote;
        if (_currentNote?.id == noteId) {
          _currentNote = updatedNote;
        }
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      await _repository.deleteNote(id);
      _notes.removeWhere((n) => n.id == id);
      if (_currentNote?.id == id) {
        _currentNote = null;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addPage(String noteId) async {
    try {
      await _repository.addPage(noteId);
      await loadNote(noteId);
      await loadNotes();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deletePage(String noteId, String pageId) async {
    try {
      await _repository.deletePage(pageId);
      await loadNote(noteId);
      await loadNotes();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateNotePdfInfo(String noteId, String? pdfPath, bool isPdfImported) async {
    try {
      await _repository.updateNotePdfInfo(noteId, pdfPath, isPdfImported);
      await loadNote(noteId);
      await loadNotes();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void setCurrentNote(Note? note) {
    _currentNote = note;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
