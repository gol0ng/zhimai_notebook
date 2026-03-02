import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/note_page.dart';
import '../../domain/entities/stroke.dart';
import '../../domain/entities/stroke_style.dart';
import '../../domain/repositories/note_repository.dart';
import '../database/database_manager.dart';

class NoteRepositoryImpl implements NoteRepository {
  final DatabaseManager _dbManager;
  final Uuid _uuid = const Uuid();

  NoteRepositoryImpl(this._dbManager);

  @override
  Future<List<Note>> getAllNotes() async {
    final db = await _dbManager.database;
    final notesData = await db.query(
      'notes',
      orderBy: 'updated_at DESC',
    );

    final notes = <Note>[];
    for (final noteData in notesData) {
      final note = await _buildNoteFromData(noteData);
      notes.add(note);
    }
    return notes;
  }

  @override
  Future<Note?> getNoteById(String id) async {
    final db = await _dbManager.database;
    final notesData = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (notesData.isEmpty) return null;
    return await _buildNoteFromData(notesData.first);
  }

  @override
  Future<Note> createNote(String title) async {
    final db = await _dbManager.database;
    final now = DateTime.now();
    final noteId = _uuid.v4();
    final pageId = _uuid.v4();

    await db.insert('notes', {
      'id': noteId,
      'title': title,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'background_image': null,
      'is_pdf_imported': 0,
    });

    await db.insert('pages', {
      'id': pageId,
      'note_id': noteId,
      'page_number': 1,
      'pdf_page_path': null,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });

    return Note(
      id: noteId,
      title: title,
      createdAt: now,
      updatedAt: now,
      pages: [
        NotePage(
          id: pageId,
          noteId: noteId,
          pageNumber: 1,
          strokes: const [],
          pdfPagePath: null,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      isPdfImported: false,
    );
  }

  @override
  Future<Note> updateNote(Note note) async {
    final db = await _dbManager.database;
    final now = DateTime.now();

    await db.update(
      'notes',
      {
        'title': note.title,
        'updated_at': now.toIso8601String(),
        'background_image': note.backgroundImage,
        'is_pdf_imported': note.isPdfImported ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [note.id],
    );

    return note.copyWith(updatedAt: now);
  }

  @override
  Future<void> deleteNote(String id) async {
    final db = await _dbManager.database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> addPage(String noteId) async {
    final db = await _dbManager.database;
    final now = DateTime.now();

    final pagesCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM pages WHERE note_id = ?',
      [noteId],
    );
    final newPageNumber = (pagesCount.first['count'] as int) + 1;
    final pageId = _uuid.v4();

    await db.insert('pages', {
      'id': pageId,
      'note_id': noteId,
      'page_number': newPageNumber,
      'pdf_page_path': null,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });

    await db.update(
      'notes',
      {'updated_at': now.toIso8601String()},
      where: 'id = ?',
      whereArgs: [noteId],
    );
  }

  @override
  Future<void> deletePage(String pageId) async {
    final db = await _dbManager.database;
    await db.delete('pages', where: 'id = ?', whereArgs: [pageId]);
  }

  Future<Note> _buildNoteFromData(Map<String, dynamic> noteData) async {
    final db = await _dbManager.database;
    final noteId = noteData['id'] as String;

    final pagesData = await db.query(
      'pages',
      where: 'note_id = ?',
      whereArgs: [noteId],
      orderBy: 'page_number ASC',
    );

    final pages = <NotePage>[];
    for (final pageData in pagesData) {
      final page = await _buildPageFromData(pageData);
      pages.add(page);
    }

    return Note(
      id: noteData['id'] as String,
      title: noteData['title'] as String,
      createdAt: DateTime.parse(noteData['created_at'] as String),
      updatedAt: DateTime.parse(noteData['updated_at'] as String),
      pages: pages,
      backgroundImage: noteData['background_image'] as String?,
      isPdfImported: (noteData['is_pdf_imported'] as int) == 1,
    );
  }

  Future<NotePage> _buildPageFromData(Map<String, dynamic> pageData) async {
    final db = await _dbManager.database;
    final pageId = pageData['id'] as String;

    final strokesData = await db.query(
      'strokes',
      where: 'page_id = ?',
      whereArgs: [pageId],
      orderBy: 'created_at ASC',
    );

    final strokes = strokesData.map((strokeData) {
      final pointsJson = jsonDecode(strokeData['points_json'] as String) as List;
      final points = pointsJson
          .map((p) => StrokePoint.fromJson(p as Map<String, dynamic>))
          .toList();

      return Stroke(
        id: strokeData['id'] as String,
        points: points,
        style: StrokeStyle(
          color: Color(strokeData['color'] as int),
          strokeWidth: (strokeData['stroke_width'] as num).toDouble(),
          strokeCap: StrokeCap.values[strokeData['stroke_cap'] as int],
        ),
        createdAt: DateTime.parse(strokeData['created_at'] as String),
      );
    }).toList();

    return NotePage(
      id: pageData['id'] as String,
      noteId: pageData['note_id'] as String,
      pageNumber: pageData['page_number'] as int,
      strokes: strokes,
      pdfPagePath: pageData['pdf_page_path'] as String?,
      createdAt: DateTime.parse(pageData['created_at'] as String),
      updatedAt: DateTime.parse(pageData['updated_at'] as String),
    );
  }

  // Stroke operations
  Future<void> saveStroke(String pageId, Stroke stroke) async {
    final db = await _dbManager.database;
    final now = DateTime.now();

    await db.insert('strokes', {
      'id': stroke.id,
      'page_id': pageId,
      'points_json': jsonEncode(stroke.points.map((p) => p.toJson()).toList()),
      'color': stroke.style.color.value,
      'stroke_width': stroke.style.strokeWidth,
      'stroke_cap': stroke.style.strokeCap.index,
      'created_at': now.toIso8601String(),
    });

    await db.update(
      'pages',
      {'updated_at': now.toIso8601String()},
      where: 'id = ?',
      whereArgs: [pageId],
    );

    final pageData = await db.query('pages', where: 'id = ?', whereArgs: [pageId]);
    if (pageData.isNotEmpty) {
      await db.update(
        'notes',
        {'updated_at': now.toIso8601String()},
        where: 'id = ?',
        whereArgs: [pageData.first['note_id']],
      );
    }
  }

  Future<void> deleteStroke(String strokeId) async {
    final db = await _dbManager.database;
    final now = DateTime.now();

    final strokeData = await db.query(
      'strokes',
      where: 'id = ?',
      whereArgs: [strokeId],
    );

    if (strokeData.isNotEmpty) {
      final pageId = strokeData.first['page_id'];
      await db.delete('strokes', where: 'id = ?', whereArgs: [strokeId]);

      await db.update(
        'pages',
        {'updated_at': now.toIso8601String()},
        where: 'id = ?',
        whereArgs: [pageId],
      );
    }
  }

  Future<void> deleteAllStrokes(String pageId) async {
    final db = await _dbManager.database;
    final now = DateTime.now();

    await db.delete('strokes', where: 'page_id = ?', whereArgs: [pageId]);

    await db.update(
      'pages',
      {'updated_at': now.toIso8601String()},
      where: 'id = ?',
      whereArgs: [pageId],
    );
  }

  Future<void> updateNotePdfInfo(String noteId, String? pdfPath, bool isPdfImported) async {
    final db = await _dbManager.database;
    await db.update(
      'notes',
      {
        'background_image': pdfPath,
        'is_pdf_imported': isPdfImported ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [noteId],
    );
  }
}
