import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_colors.dart';

/// Loading dots animation
class LoadingDots extends StatelessWidget {
  final Color color;
  final double size;

  const LoadingDots({
    super.key,
    this.color = AppColors.primaryPurple,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: size / 4),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        )
            .animate(
              onPlay: (controller) => controller.repeat(),
            )
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(0.6, 0.6),
              duration: 600.ms,
              delay: (index * 200).ms,
            )
            .then()
            .scale(
              begin: const Offset(0.6, 0.6),
              end: const Offset(1, 1),
              duration: 600.ms,
            );
      }),
    );
  }
}

/// Circular loading spinner with gradient
class GradientSpinner extends StatelessWidget {
  final double size;

  const GradientSpinner({
    super.key,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
      ),
    ).animate(onPlay: (c) => c.repeat()).rotate(duration: 1.seconds);
  }
}
