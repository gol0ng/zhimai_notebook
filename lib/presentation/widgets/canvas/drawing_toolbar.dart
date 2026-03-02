import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/canvas_provider.dart';

class DrawingToolbar extends StatelessWidget {
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onClear;

  const DrawingToolbar({
    super.key,
    this.onUndo,
    this.onRedo,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CanvasProvider>(
      builder: (context, canvasProvider, child) {
        return Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                // 画笔
                _ToolIcon(
                  icon: Icons.edit,
                  label: '画笔',
                  isSelected: canvasProvider.currentTool == DrawingTool.pen,
                  onTap: () => canvasProvider.setTool(DrawingTool.pen),
                ),
                // 荧光笔
                _ToolIcon(
                  icon: Icons.brush,
                  label: '荧光',
                  isSelected: canvasProvider.currentTool == DrawingTool.highlighter,
                  onTap: () => canvasProvider.setTool(DrawingTool.highlighter),
                ),
                // 橡皮
                _ToolIcon(
                  icon: Icons.auto_fix_high,
                  label: '橡皮',
                  isSelected: canvasProvider.currentTool == DrawingTool.eraser,
                  onTap: () => canvasProvider.setTool(DrawingTool.eraser),
                ),

                const VerticalDivider(width: 24),

                // 颜色选择
                ..._buildColors(context, canvasProvider),

                const Spacer(),

                // 粗细
                _WidthSelector(
                  width: canvasProvider.strokeWidth,
                  onChanged: canvasProvider.currentTool != DrawingTool.eraser
                      ? (w) => canvasProvider.setStrokeWidth(w)
                      : null,
                ),

                const SizedBox(width: 8),

                // 撤销
                IconButton(
                  onPressed: canvasProvider.canUndo ? onUndo : null,
                  icon: Icon(Icons.undo, size: 22),
                  color: canvasProvider.canUndo ? Colors.black87 : Colors.grey,
                ),
                // 重做
                IconButton(
                  onPressed: canvasProvider.canRedo ? onRedo : null,
                  icon: Icon(Icons.redo, size: 22),
                  color: canvasProvider.canRedo ? Colors.black87 : Colors.grey,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildColors(BuildContext context, CanvasProvider provider) {
    if (provider.currentTool == DrawingTool.eraser) {
      return [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text('橡皮模式', style: TextStyle(color: Colors.grey)),
        ),
      ];
    }

    final colors = provider.currentTool == DrawingTool.highlighter
        ? AppConstants.highlighterColors
        : AppConstants.penColors;

    return colors.take(5).map((color) {
      final isSelected = color == provider.currentColor;
      return GestureDetector(
        onTap: () => provider.setColor(color),
        child: Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: provider.currentTool == DrawingTool.highlighter
                ? color.withOpacity(0.5)
                : color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
        ),
      );
    }).toList();
  }
}

class _ToolIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToolIcon({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.blue : Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.blue : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WidthSelector extends StatelessWidget {
  final double width;
  final ValueChanged<double>? onChanged;

  const _WidthSelector({required this.width, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged != null
          ? () {
              // 切换粗细：2 -> 5 -> 10 -> 15 -> 2
              double newWidth;
              if (width < 4) newWidth = 5;
              else if (width < 8) newWidth = 10;
              else if (width < 13) newWidth = 15;
              else newWidth = 2;
              onChanged!(newWidth);
            }
          : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Container(
            width: width.clamp(4, 20),
            height: width.clamp(4, 20),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(width / 2),
            ),
          ),
        ),
      ),
    );
  }
}
