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

  // Snap to grid (10cm)
  double _snap(double value) {
    return (value / 10).round() * 10.0;
  }

  @override
  Widget build(BuildContext context) {
    final bed = widget.bed;
    final displayX = _dragX ?? bed.x;
    final displayY = _dragY ?? bed.y;
    final displayWidth = _dragWidth ?? bed.width;
    final displayHeight = _dragHeight ?? bed.height;

    // We offset the position to center the "workspace" if needed, 
    // but here we assume absolute positioning on the 5000x5000 canvas.
    // We might need to add an offset if we want (0,0) to be in the center,
    // but let's stick to positive coordinates for now.
    
    return Positioned(
      left: displayX,
      top: displayY,
      width: displayWidth,
      height: displayHeight,
      child: GestureDetector(
        onTap: () {
          if (!widget.isEditMode) {
            // Open Details
            _showDetails(context);
          }
        },
        onPanStart: widget.isEditMode ? (details) {
          setState(() {
            _dragX = bed.x;
            _dragY = bed.y;
          });
        } : null,
        onPanUpdate: widget.isEditMode ? (details) {
          setState(() {
            _dragX = (_dragX! + details.delta.dx);
            _dragY = (_dragY! + details.delta.dy);
          });
        } : null,
        onPanEnd: widget.isEditMode ? (details) {
          // Snap and save
          final newX = _snap(_dragX!);
          final newY = _snap(_dragY!);
          
          setState(() {
            _dragX = null;
            _dragY = null;
          });

          if (newX != bed.x || newY != bed.y) {
            ref.read(gardenControllerProvider.notifier).updateBed(
              bed.copyWith(x: newX, y: newY)
            );
          }
        } : null,
        child: Container(
          decoration: BoxDecoration(
            color: (bed.color != null ? Color(bed.color!) : AppColors.primaryPurple).withOpacity(0.8),
            border: Border.all(
              color: widget.isEditMode ? Colors.yellow : Colors.white,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              // Content
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      bed.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (bed.crops.isNotEmpty)
                      Text(
                        "${bed.crops.length} planter",
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                  ],
                ),
              ),

              // Resize Handle (Bottom Right)
              if (widget.isEditMode)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onPanStart: (details) {
                       setState(() {
                        _dragWidth = bed.width;
                        _dragHeight = bed.height;
                      });
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        _dragWidth = (_dragWidth! + details.delta.dx).clamp(20.0, 500.0);
                        _dragHeight = (_dragHeight! + details.delta.dy).clamp(20.0, 500.0);
                      });
                    },
                    onPanEnd: (details) {
                      final newW = _snap(_dragWidth!);
                      final newH = _snap(_dragHeight!);
                      
                      setState(() {
                        _dragWidth = null;
                        _dragHeight = null;
                      });

                      if (newW != bed.width || newH != bed.height) {
                         ref.read(gardenControllerProvider.notifier).updateBed(
                          bed.copyWith(width: newW, height: newH)
                        );
                      }
                    },
                    child: Container(
                      width: 20,
                      height: 20,
                      color: Colors.yellow.withOpacity(0.5),
                      child: const Icon(Icons.drag_handle, size: 12, color: Colors.black54),
                    ),
                  ),
                ),
            ],
          ),
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
