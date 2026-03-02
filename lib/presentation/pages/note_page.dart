import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../domain/entities/note.dart';
import '../../domain/entities/note_page.dart';
import '../../services/log_service.dart';
import '../providers/note_provider.dart';
import '../providers/canvas_provider.dart';
import '../widgets/canvas/painting_canvas.dart';
import '../widgets/canvas/drawing_toolbar.dart';

class NotePageScreen extends StatefulWidget {
  final String noteId;

  const NotePageScreen({super.key, required this.noteId});

  @override
  State<NotePageScreen> createState() => _NotePageScreenState();
}

class _NotePageScreenState extends State<NotePageScreen> {
  int _currentPageIndex = 0;
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  bool _showPdf = false;
  String? _pdfPath;
  CanvasProvider? _canvasProvider;
  final PdfViewerController _pdfController = PdfViewerController();
  int _pdfPageCount = 0;
  bool _showPageIndicator = false;

  @override
  void initState() {
    super.initState();
    LogService.instance.info('笔记页面初始化: ${widget.noteId}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNote();
    });
  }

  void _loadNote() async {
    final noteProvider = context.read<NoteProvider>();
    await noteProvider.loadNote(widget.noteId);

    final note = noteProvider.currentNote;
    if (note != null && note.isPdfImported && note.backgroundImage != null) {
      setState(() {
        _pdfPath = note.backgroundImage;
        _showPdf = true;
      });
    }

    _initCanvasProvider();
  }

  void _initCanvasProvider() {
    final noteProvider = context.read<NoteProvider>();
    final note = noteProvider.currentNote;

    if (note != null && note.pages.isNotEmpty) {
      _canvasProvider = context.read<CanvasProvider>();
      _canvasProvider!.loadStrokes(note.pages[_currentPageIndex].strokes);
      LogService.instance.info('加载页面 ${_currentPageIndex + 1}，笔画数: ${note.pages[_currentPageIndex].strokes.length}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteProvider>(
      builder: (context, noteProvider, child) {
        final note = noteProvider.currentNote;

        if (noteProvider.isLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('加载中...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (note == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('笔记未找到')),
            body: const Center(child: Text('笔记未找到')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(note.title),
            backgroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: () => _importPdf(note),
                tooltip: '导入PDF',
              ),
            ],
          ),
          body: Column(
            children: [
              DrawingToolbar(
                onUndo: () => _undo(note.pages[_currentPageIndex].id),
                onRedo: () => _redo(note.pages[_currentPageIndex].id),
                onClear: () => _clearCanvas(note.pages[_currentPageIndex].id),
              ),
              Expanded(
                child: _buildCanvasArea(note),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCanvasArea(Note note) {
    if (note.pages.isEmpty) {
      return const Center(child: Text('没有页面'));
    }

    final currentPage = note.pages[_currentPageIndex];

    // 有PDF时：PDF处理缩放和翻页，绘画层在手写笔
    if (_showPdf) {
      return Stack(
        children: [
          // PDF viewer在底层（处理缩放和翻页滚动）
          if (_showPdf && _pdfPath != null)
            Positioned.fill(
              child: SfPdfViewer.file(
                File(_pdfPath!),
                controller: _pdfController,
                key: _pdfViewerKey,
                canShowScrollHead: false,
                canShowScrollStatus: false,
                pageLayoutMode: PdfPageLayoutMode.single,
                enableDoubleTapZooming: true,
                onDocumentLoaded: (details) {
                  setState(() {
                    _pdfPageCount = details.document.pages.count;
                  });
                  LogService.instance.info('PDF加载完成，共 $_pdfPageCount 页');
                },
                onPageChanged: (details) {
                  final newIndex = details.newPageNumber - 1;
                  if (newIndex != _currentPageIndex && newIndex >= 0 && newIndex < note.pages.length) {
                    setState(() {
                      _currentPageIndex = newIndex;
                      _loadPageStrokes(note.pages[newIndex]);
                    });
                  }
                },
              ),
            ),
          // 绘画层在最上面（允许手写笔写字）
          Positioned.fill(
            child: PaintingCanvas(
              pageId: currentPage.id,
              backgroundColor: Colors.transparent,
            ),
          ),
          // 右侧页码显示
          Positioned(
            right: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${_currentPageIndex + 1}/${note.pages.length} (PDF:$_pdfPageCount页)',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      );
    }

    // 没有PDF时使用手势翻页
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta != null && details.primaryDelta! > 5) {
          if (!_showPageIndicator) {
            setState(() => _showPageIndicator = true);
          }
        }
      },
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity == null) return;

        if (details.primaryVelocity! < -200) {
          setState(() => _showPageIndicator = false);
          if (_currentPageIndex == note.pages.length - 1) {
            _addPage(note.id);
          } else if (_currentPageIndex < note.pages.length - 1) {
            _goToPage(_currentPageIndex + 1, note);
          }
        } else if (details.primaryVelocity! > 200) {
          if (_currentPageIndex > 0) {
            _goToPage(_currentPageIndex - 1, note);
          }
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _showPageIndicator = false);
          });
        } else {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _showPageIndicator = false);
          });
        }
      },
      child: Stack(
        children: [
          // 绘画层
          Positioned.fill(
            child: PaintingCanvas(
              pageId: currentPage.id,
              backgroundColor: Colors.white,
            ),
          ),
          // 页码指示器
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            right: _showPageIndicator ? 16 : -100,
            top: 16,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _showPageIndicator ? 1.0 : 0.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '< ${_currentPageIndex + 1}/${note.pages.length} >',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
          // 添加页面按钮
          if (_currentPageIndex == note.pages.length - 1)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.small(
                heroTag: 'addPage',
                onPressed: () => _addPage(note.id),
                child: const Icon(Icons.add),
              ),
            ),
        ],
      ),
    );
  }

  void _loadPageStrokes(NotePage page) {
    if (_canvasProvider != null) {
      _canvasProvider!.loadStrokes(page.strokes);
      LogService.instance.info('切换到页面 ${page.pageNumber}，加载 ${page.strokes.length} 个笔画');
    }
  }

  void _goToPage(int index, Note note) {
    setState(() {
      _currentPageIndex = index;
    });
    if (_showPdf && _pdfPageCount > 0) {
      _pdfController.jumpToPage(index + 1);
    }
    _loadPageStrokes(note.pages[index]);
  }

  Future<void> _importPdf(Note note) async {
    LogService.instance.info('开始导入PDF');
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final sourcePath = result.files.single.path!;
        LogService.instance.info('选择PDF: $sourcePath');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('正在导入PDF...'), duration: Duration(seconds: 1)),
          );
        }

        final appDir = await getApplicationDocumentsDirectory();
        final pdfDir = Directory('${appDir.path}/pdfs');
        if (!await pdfDir.exists()) {
          await pdfDir.create(recursive: true);
        }

        final fileName = '${widget.noteId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final destPath = p.join(pdfDir.path, fileName);

        await File(sourcePath).copy(destPath);
        LogService.instance.info('PDF复制到: $destPath');

        final noteProvider = context.read<NoteProvider>();
        await noteProvider.updateNotePdfInfo(note.id, destPath, true);
        await noteProvider.loadNote(widget.noteId);

        setState(() {
          _pdfPath = destPath;
          _showPdf = true;
          _currentPageIndex = 0;
        });

        LogService.instance.info('PDF导入成功');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF导入成功')),
          );
        }
      }
    } catch (e, stackTrace) {
      LogService.instance.error('导入PDF错误', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入PDF错误: $e')),
        );
      }
    }
  }

  void _addPage(String noteId) async {
    LogService.instance.info('添加新页面: $noteId');
    final noteProvider = context.read<NoteProvider>();
    await noteProvider.addPage(noteId);

    setState(() {
      _currentPageIndex = noteProvider.currentNote!.pages.length - 1;
    });
    _loadPageStrokes(noteProvider.currentNote!.pages[_currentPageIndex]);
  }

  void _undo(String pageId) {
    if (_canvasProvider != null) {
      _canvasProvider!.undo(pageId);
    }
  }

  void _redo(String pageId) {
    if (_canvasProvider != null) {
      _canvasProvider!.redo(pageId);
    }
  }

  void _clearCanvas(String pageId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空画布'),
        content: const Text('确定要清空所有笔画吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('清空'),
          ),
        ],
      ),
    );

    if (confirmed == true && _canvasProvider != null) {
      await _canvasProvider!.clearAll(pageId);
    }
  }
}
