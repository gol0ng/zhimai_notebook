import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/stroke.dart';
import '../../domain/entities/stroke_style.dart';
import '../../data/repositories/note_repository_impl.dart';

enum DrawingTool { pen, highlighter, eraser }

class CanvasProvider extends ChangeNotifier {
  final NoteRepositoryImpl _repository;
  final Uuid _uuid = const Uuid();

  Color _currentColor = Colors.black;
  double _strokeWidth = AppConstants.defaultStrokeWidth;
  DrawingTool _currentTool = DrawingTool.pen;

  List<Stroke> _strokes = [];
  final List<List<Stroke>> _undoStack = [];
  final List<List<Stroke>> _redoStack = [];

  Stroke? _currentStroke;
  List<StrokePoint> _currentPoints = [];

  CanvasProvider(this._repository);

  Color get currentColor => _currentColor;
  double get strokeWidth => _strokeWidth;
  DrawingTool get currentTool => _currentTool;
  List<Stroke> get strokes => _strokes;
  Stroke? get currentStroke => _currentStroke;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void setColor(Color color) {
    _currentColor = color;
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    _strokeWidth = width;
    notifyListeners();
  }

  void setTool(DrawingTool tool) {
    _currentTool = tool;
    notifyListeners();
  }

  void loadStrokes(List<Stroke> strokes) {
    _strokes = List.from(strokes);
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }

  void startStroke(Offset position) {
    final isEraser = _currentTool == DrawingTool.eraser;
    final isHighlighter = _currentTool == DrawingTool.highlighter;

    _currentPoints = [
      StrokePoint(x: position.dx, y: position.dy),
    ];

    double width = _strokeWidth;
    double opacity = 1.0;

    if (isHighlighter) {
      width = _strokeWidth * 3;
      opacity = 0.4;
    } else if (isEraser) {
      width = _strokeWidth * 4;
    }

    _currentStroke = Stroke(
      id: _uuid.v4(),
      points: _currentPoints,
      style: StrokeStyle(
        color: isEraser ? Colors.white : _currentColor,
        strokeWidth: width,
        strokeCap: StrokeCap.round,
        isEraser: isEraser,
        opacity: opacity,
      ),
      createdAt: DateTime.now(),
    );

    notifyListeners();
  }

  void updateStroke(Offset position) {
    if (_currentStroke == null) return;

    _currentPoints = List.from(_currentPoints)
      ..add(StrokePoint(x: position.dx, y: position.dy));

    _currentStroke = _currentStroke!.copyWith(points: _currentPoints);
    notifyListeners();
  }

  Future<void> endStroke(String pageId) async {
    if (_currentStroke == null || _currentPoints.isEmpty) {
      _currentStroke = null;
      return;
    }

    _undoStack.add(List.from(_strokes));
    _redoStack.clear();

    if (_currentTool == DrawingTool.eraser) {
      _eraseStrokes();
      // 橡皮擦也需要同步到数据库
      await _syncToDatabase(pageId);
    } else {
      _strokes.add(_currentStroke!);
      await _repository.saveStroke(pageId, _currentStroke!);
    }

    _currentStroke = null;
    _currentPoints = [];
    notifyListeners();
  }

  void _eraseStrokes() {
    if (_currentStroke == null) return;

    final eraserPath = _currentStroke!.points;
    final eraserRadius = _currentStroke!.style.strokeWidth / 2;

    _strokes.removeWhere((stroke) {
      for (final eraserPoint in eraserPath) {
        for (final strokePoint in stroke.points) {
          final distance = (Offset(strokePoint.x, strokePoint.y) -
                  Offset(eraserPoint.x, eraserPoint.y))
              .distance;
          if (distance < eraserRadius + 5) {
            return true;
          }
        }
      }
      return false;
    });
  }

  Future<void> undo(String pageId) async {
    if (_undoStack.isEmpty) return;

    _redoStack.add(List.from(_strokes));
    _strokes = _undoStack.removeLast();

    await _syncToDatabase(pageId);
    notifyListeners();
  }

  Future<void> redo(String pageId) async {
    if (_redoStack.isEmpty) return;

    _undoStack.add(List.from(_strokes));
    _strokes = _redoStack.removeLast();

    await _syncToDatabase(pageId);
    notifyListeners();
  }

  Future<void> clearAll(String pageId) async {
    if (_strokes.isEmpty) return;

    _undoStack.add(List.from(_strokes));
    _redoStack.clear();
    _strokes = [];

    await _repository.deleteAllStrokes(pageId);
    notifyListeners();
  }

  Future<void> _syncToDatabase(String pageId) async {
    await _repository.deleteAllStrokes(pageId);
    for (final stroke in _strokes) {
      await _repository.saveStroke(pageId, stroke);
    }
  }
}
