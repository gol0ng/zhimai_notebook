import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/constants/app_constants.dart';

class DatabaseManager {
  static Database? _database;
  static final DatabaseManager instance = DatabaseManager._internal();

  DatabaseManager._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        background_image TEXT,
        is_pdf_imported INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE pages (
        id TEXT PRIMARY KEY,
        note_id TEXT NOT NULL,
        page_number INTEGER NOT NULL,
        pdf_page_path TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (note_id) REFERENCES notes (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE strokes (
        id TEXT PRIMARY KEY,
        page_id TEXT NOT NULL,
        points_json TEXT NOT NULL,
        color INTEGER NOT NULL,
        stroke_width REAL NOT NULL,
        stroke_cap INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (page_id) REFERENCES pages (id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_pages_note_id ON pages (note_id)'
    );
    await db.execute(
      'CREATE INDEX idx_strokes_page_id ON strokes (page_id)'
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here in the future
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
