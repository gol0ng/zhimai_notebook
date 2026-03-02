import '../entities/note.dart';

abstract class NoteRepository {
  Future<List<Note>> getAllNotes();
  Future<Note?> getNoteById(String id);
  Future<Note> createNote(String title);
  Future<Note> updateNote(Note note);
  Future<void> deleteNote(String id);
  Future<void> addPage(String noteId);
  Future<void> deletePage(String pageId);
}
