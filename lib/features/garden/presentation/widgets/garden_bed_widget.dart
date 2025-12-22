import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/garden_bed_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/garden_providers.dart';
import 'bed_details_sheet.dart';

class GardenBedWidget extends ConsumerStatefulWidget {
  final GardenBed bed;
  final bool isEditMode;

  const GardenBedWidget({
    super.key,
    required this.bed,
    required this.isEditMode,
  });

  @override
  ConsumerState<GardenBedWidget> createState() => _GardenBedWidgetState();
}

class _GardenBedWidgetState extends ConsumerState<GardenBedWidget> {
  // Temporary state for dragging
  double? _dragX;
  double? _dragY;
  double? _dragWidth;
  double? _dragHeight;

  // Limits
  static const double _minSize = 20.0;
  static const double _maxSize = 1000.0;

  // Snap to grid (10cm)
  double _snap(double value) {
    return (value / 10).round() * 10.0;
  }

  void _initDrag() {
    setState(() {
      _dragX = widget.bed.x;
      _dragY = widget.bed.y;
      _dragWidth = widget.bed.width;
      _dragHeight = widget.bed.height;
    });
  }

  void _endDrag() {
    final newX = _snap(_dragX!);
    final newY = _snap(_dragY!);
    final newW = _snap(_dragWidth!);
    final newH = _snap(_dragHeight!);

    setState(() {
      _dragX = null;
      _dragY = null;
      _dragWidth = null;
      _dragHeight = null;
    });

    if (newX != widget.bed.x || newY != widget.bed.y || 
        newW != widget.bed.width || newH != widget.bed.height) {
      ref.read(gardenControllerProvider.notifier).updateBed(
        widget.bed.copyWith(
          x: newX,
          y: newY,
          width: newW,
          height: newH,
        )
      );
    }
  }

  // Contrast calculator
  Color _getContrastColor(Color color) {
    return color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final bed = widget.bed;
    final displayX = _dragX ?? bed.x;
    final displayY = _dragY ?? bed.y;
    final displayWidth = _dragWidth ?? bed.width;
    final displayHeight = _dragHeight ?? bed.height;
    
    final bedColor = bed.color != null ? Color(bed.color!) : AppColors.primaryPurple;
    final textColor = _getContrastColor(bedColor);
    final borderColor = widget.isEditMode ? Colors.yellow : Colors.white.withOpacity(0.5);

    return Positioned(
      left: displayX,
      top: displayY,
      width: displayWidth,
      height: displayHeight,
      child: GestureDetector(
        onTap: () {
          if (!widget.isEditMode) {
            _showDetails(context);
          }
        },
        onPanStart: widget.isEditMode ? (details) => _initDrag() : null,
        onPanUpdate: widget.isEditMode ? (details) {
          setState(() {
            _dragX = (_dragX! + details.delta.dx);
            _dragY = (_dragY! + details.delta.dy);
          });
        } : null,
        onPanEnd: widget.isEditMode ? (details) => _endDrag() : null,
        child: Container(
          decoration: BoxDecoration(
            color: bedColor.withOpacity(0.9), // Slightly higher opacity for better color visibility
            border: Border.all(
              color: borderColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Content
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      bed.name,
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (bed.crops.isNotEmpty)
                      Text(
                        "${bed.crops.length} planter",
                        style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 10),
                      ),
                  ],
                ),
              ),

              if (widget.isEditMode) ...[
                // Top Left
                _buildHandle(
                  top: -10, left: -10,
                  icon: Icons.north_west,
                  onUpdate: (delta) {
                    final newW = (_dragWidth! - delta.dx);
                    final newH = (_dragHeight! - delta.dy);
                    if (newW >= _minSize && newW <= _maxSize) {
                      _dragX = _dragX! + delta.dx;
                      _dragWidth = newW;
                    }
                    if (newH >= _minSize && newH <= _maxSize) {
                      _dragY = _dragY! + delta.dy;
                      _dragHeight = newH;
                    }
                  },
                ),
                // Top Right
                _buildHandle(
                  top: -10, right: -10,
                  icon: Icons.north_east,
                  onUpdate: (delta) {
                    final newW = (_dragWidth! + delta.dx);
                    final newH = (_dragHeight! - delta.dy);
                    if (newW >= _minSize && newW <= _maxSize) {
                      _dragWidth = newW;
                    }
                    if (newH >= _minSize && newH <= _maxSize) {
                      _dragY = _dragY! + delta.dy;
                      _dragHeight = newH;
                    }
                  },
                ),
                // Bottom Left
                _buildHandle(
                  bottom: -10, left: -10,
                  icon: Icons.south_west,
                  onUpdate: (delta) {
                    final newW = (_dragWidth! - delta.dx);
                    final newH = (_dragHeight! + delta.dy);
                    if (newW >= _minSize && newW <= _maxSize) {
                      _dragX = _dragX! + delta.dx;
                      _dragWidth = newW;
                    }
                    if (newH >= _minSize && newH <= _maxSize) {
                      _dragHeight = newH;
                    }
                  },
                ),
                // Bottom Right
                _buildHandle(
                  bottom: -10, right: -10,
                  icon: Icons.south_east,
                  onUpdate: (delta) {
                    final newW = (_dragWidth! + delta.dx);
                    final newH = (_dragHeight! + delta.dy);
                    if (newW >= _minSize && newW <= _maxSize) {
                      _dragWidth = newW;
                    }
                    if (newH >= _minSize && newH <= _maxSize) {
                      _dragHeight = newH;
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required IconData icon,
    required Function(Offset) onUpdate,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: GestureDetector(
        onPanStart: (details) => _initDrag(),
        onPanUpdate: (details) {
          setState(() {
            onUpdate(details.delta);
          });
        },
        onPanEnd: (details) => _endDrag(),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.yellow,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 2,
              )
            ],
          ),
          child: Icon(icon, size: 16, color: Colors.black87),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BedDetailsSheet(bed: widget.bed),
    );
  }
}
