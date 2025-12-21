import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class GardenGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gray.withOpacity(0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final boldPaint = Paint()
      ..color = AppColors.gray.withOpacity(0.4)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // 1 unit = 1 cm.
    // Grid lines every 10 units (10cm).
    // Bold lines every 100 units (1m).

    const double gridSize = 10.0;
    const double boldGridSize = 100.0;

    for (double x = 0; x <= size.width; x += gridSize) {
      if (x % boldGridSize == 0) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), boldPaint);
      } else {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
    }

    for (double y = 0; y <= size.height; y += gridSize) {
      if (y % boldGridSize == 0) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), boldPaint);
      } else {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
