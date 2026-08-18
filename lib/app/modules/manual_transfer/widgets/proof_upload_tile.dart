import 'dart:io';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';

/// Reusable "tap to add a receipt/screenshot" tile — dashed placeholder when
/// empty, thumbnail + remove/replace affordance once a file is picked.
/// Deliberately rectangular (a receipt, not an avatar) so it doesn't reuse
/// `PhotoCircleUploader`.
class ProofUploadTile extends StatelessWidget {
  final File? file;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const ProofUploadTile({super.key, required this.file, required this.onTap, this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (file == null) {
      return GestureDetector(
        onTap: onTap,
        child: DottedBorderBox(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: BaseSpacing.xl),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.add_a_photo_outlined, size: 28, color: AppColors.primaryColor),
                SizedBox(height: BaseSpacing.xs),
                CustomText(
                  text: 'Upload screenshot or receipt',
                  color: AppColors.black2,
                  fontSize: AppFontSize.verySmall,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: BaseSpacing.xxs / 2),
                CustomText(
                  text: 'Tap to take a photo or choose from gallery',
                  color: AppColors.gray600,
                  fontSize: AppFontSize.tiny,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(BaseRadius.lg),
            child: Image.file(file!, width: double.infinity, height: 180, fit: BoxFit.cover),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: BaseSpacing.xs,
            right: BaseSpacing.xs,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: EdgeInsets.all(BaseSpacing.xxs),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

/// Lightweight dashed-border container — this app has no existing dashed-box
/// primitive to reuse (`PhotoCircleUploader`'s dashed state is circular and
/// private to that widget), so this is a small standalone `CustomPainter`.
class DottedBorderBox extends StatelessWidget {
  final Widget child;
  const DottedBorderBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: AppColors.primaryColor.withOpacity(0.4), radius: BaseRadius.lg),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  const _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    const dashWidth = 6.0;
    const dashGap = 4.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next.clamp(0, metric.length)), paint);
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
