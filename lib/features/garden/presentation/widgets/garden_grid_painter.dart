import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class GardenGridPainter extends CustomPainter {
  final double? width;
  final double? height;

  GardenGridPainter({this.width, this.height});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background outside of garden area if limits are set
    if (width != null && height != null) {
      // Since the canvas size is infinite/large (5000x5000), we only want to draw grid inside the garden area
      // OR we draw grid everywhere but darken the outside area.
      // Let's darken the outside area to focus on the garden.
      
      final paintOutside = Paint()
        ..color = Colors.black.withOpacity(0.05)
        ..style = PaintingStyle.fill;

      // Draw 4 rectangles around the central garden area
      // Actually simpler: fill everything then clear the garden rect? 
      // No, let's just draw the grid within the garden bounds if they exist, 
      // or draw the boundary line.
    }

    final paint = Paint()
      ..color = AppColors.gray.withOpacity(0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final boldPaint = Paint()
      ..color = AppColors.gray.withOpacity(0.4)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
      
    final borderPaint = Paint()
      ..color = Colors.green.withOpacity(0.5)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    // 1 unit = 1 cm.
    // Grid lines every 10 units (10cm).
    // Bold lines every 100 units (1m).

    const double gridSize = 10.0;
    const double boldGridSize = 100.0;
    
    // Determine draw bounds
    // If width/height provided, use those. Else use canvas size (which is 5000).
    final drawWidth = width ?? size.width;
    final drawHeight = height ?? size.height;

    for (double x = 0; x <= drawWidth; x += gridSize) {
      if (x % boldGridSize == 0) {
        canvas.drawLine(Offset(x, 0), Offset(x, drawHeight), boldPaint);
      } else {
        canvas.drawLine(Offset(x, 0), Offset(x, drawHeight), paint);
      }
    }

    for (double y = 0; y <= drawHeight; y += gridSize) {
      if (y % boldGridSize == 0) {
        canvas.drawLine(Offset(0, y), Offset(drawWidth, y), boldPaint);
      } else {
        canvas.drawLine(Offset(0, y), Offset(drawWidth, y), paint);
      }
    }
    
    // Draw boundary if limits exist
    if (width != null && height != null) {
      canvas.drawRect(Rect.fromLTWH(0, 0, width!, height!), borderPaint);
      
      // Optional: Draw label for size
      // ...
    }
  }

  @override
  bool shouldRepaint(covariant GardenGridPainter oldDelegate) {
    return oldDelegate.width != width || oldDelegate.height != height;
  }
}
