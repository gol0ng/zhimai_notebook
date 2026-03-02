import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../../providers/canvas_provider.dart';

class PaintingCanvas extends StatefulWidget {
  final String pageId;
  final Color backgroundColor;

  const PaintingCanvas({
    super.key,
    required this.pageId,
    this.backgroundColor = Colors.white,
  });

  @override
  State<PaintingCanvas> createState() => _PaintingCanvasState();
}

class _PaintingCanvasState extends State<PaintingCanvas> {
  final Map<int, Offset> _activePointers = {};
  bool _isDrawing = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<CanvasProvider>(
      builder: (context, canvasProvider, child) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (event) {
            // 只处理手写笔(stylus)
            if (event.kind != PointerDeviceKind.stylus &&
                event.kind != PointerDeviceKind.mouse) {
              return;
            }
            _isDrawing = true;
            _activePointers[event.pointer] = event.localPosition;
            canvasProvider.startStroke(event.localPosition);
          },
          onPointerMove: (event) {
            if (_isDrawing && _activePointers.containsKey(event.pointer)) {
              canvasProvider.updateStroke(event.localPosition);
            }
          },
          onPointerUp: (event) {
            if (!_isDrawing || !_activePointers.containsKey(event.pointer)) return;
            _activePointers.remove(event.pointer);
            canvasProvider.endStroke(widget.pageId);
            _isDrawing = false;
          },
          onPointerCancel: (event) {
            if (!_isDrawing || !_activePointers.containsKey(event.pointer)) return;
            _activePointers.remove(event.pointer);
            canvasProvider.endStroke(widget.pageId);
            _isDrawing = false;
          },
          child: ClipRect(
            child: CustomPaint(
              painter: _CanvasPainter(
                strokes: canvasProvider.strokes,
                currentStroke: canvasProvider.currentStroke,
              ),
              child: Container(
                color: widget.backgroundColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final List<dynamic> strokes;
  final dynamic currentStroke;

  _CanvasPainter({
    required this.strokes,
    this.currentStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke);
    }
  }

  void _drawStroke(Canvas canvas, dynamic stroke) {
    if (stroke.points.isEmpty) return;

    final isEraser = stroke.style.isEraser;

    if (isEraser) {
      final paint = Paint()
        ..blendMode = BlendMode.clear
        ..strokeWidth = stroke.style.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      _drawPath(canvas, stroke.points, paint);
    } else {
      final paint = Paint()
        ..color = stroke.style.color.withOpacity(stroke.style.opacity)
        ..strokeWidth = stroke.style.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      _drawPath(canvas, stroke.points, paint);
    }
  }

  void _drawPath(Canvas canvas, List<dynamic> points, Paint paint) {
    if (points.length == 1) {
      final point = points.first;
      canvas.drawCircle(
        Offset(point.x, point.y),
        paint.strokeWidth / 2,
        paint..style = PaintingStyle.fill,
      );
    } else {
      final path = Path();
      path.moveTo(points.first.x, points.first.y);

      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].x, points[i].y);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) {
    return strokes != oldDelegate.strokes ||
        currentStroke != oldDelegate.currentStroke;
  }
}
