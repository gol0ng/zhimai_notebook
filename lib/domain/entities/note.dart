import 'note_page.dart';

class Note {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<NotePage> pages;
  final String? backgroundImage;
  final bool isPdfImported;

  const Note({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.pages,
    this.backgroundImage,
    this.isPdfImported = false,
  });

  Note copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<NotePage>? pages,
    String? backgroundImage,
    bool? isPdfImported,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pages: pages ?? this.pages,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      isPdfImported: isPdfImported ?? this.isPdfImported,
    );
  }
}
