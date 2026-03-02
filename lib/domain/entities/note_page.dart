import 'stroke.dart';

class NotePage {
  final String id;
  final String noteId;
  final int pageNumber;
  final List<Stroke> strokes;
  final String? pdfPagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotePage({
    required this.id,
    required this.noteId,
    required this.pageNumber,
    required this.strokes,
    this.pdfPagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  NotePage copyWith({
    String? id,
    String? noteId,
    int? pageNumber,
    List<Stroke>? strokes,
    String? pdfPagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotePage(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      pageNumber: pageNumber ?? this.pageNumber,
      strokes: strokes ?? this.strokes,
      pdfPagePath: pdfPagePath ?? this.pdfPagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
