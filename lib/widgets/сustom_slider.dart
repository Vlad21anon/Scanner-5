import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:owl_tech_pdf_scaner/app/app_colors.dart';

class GradientSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final bool isActive;

  const GradientSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.isActive = false,
  });

  @override
  State<GradientSlider> createState() => _GradientSliderState();
}

class _GradientSliderState extends State<GradientSlider> {
  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 13.h,
        thumbShape: _CustomThumbShape(widget.isActive),
        trackShape: _GradientTrackShape(widget.isActive),
        overlayShape:  RoundSliderOverlayShape(overlayRadius: 20.r),
      ),
      child: Slider(
        value: widget.value,
        min: 8,
        max: 48,
        onChanged: widget.onChanged,
      ),
    );
  }
}

class _CustomThumbShape extends RoundSliderThumbShape {
  final bool isActive;
  const _CustomThumbShape(this.isActive);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Paint fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = isActive ? AppColors.blue : Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    context.canvas.drawCircle(center, 12.0, fillPaint);
    context.canvas.drawCircle(center, 12.0, borderPaint);
  }
}

class _GradientTrackShape extends RoundedRectSliderTrackShape {
  final bool isActive;
  const _GradientTrackShape(this.isActive);

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset, // Новый параметр
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final Paint activePaint = Paint()
      ..shader = LinearGradient(
        colors: isActive ? [Color(0xFF58B4FF), AppColors.blue] : [Color(0xFF676872), Color(0xFF19191E)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTRB(
        trackRect.left,
        trackRect.top,
        thumbCenter.dx,
        trackRect.bottom,
      ));

    final Paint inactivePaint = Paint()..color = Color(0xFFCECFD6);

    final Radius trackRadius = Radius.circular(trackRect.height / 2);

    context.canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        trackRect.left,
        trackRect.top,
        thumbCenter.dx,
        trackRect.bottom,
        topLeft: trackRadius,
        bottomLeft: trackRadius,
      ),
      activePaint,
    );

    context.canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        thumbCenter.dx,
        trackRect.top,
        trackRect.right,
        trackRect.bottom,
        topRight: trackRadius,
        bottomRight: trackRadius,
      ),
      inactivePaint,
    );
  }
}
