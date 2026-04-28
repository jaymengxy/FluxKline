import 'dart:ui' as ui show Gradient;

import 'package:flutter/material.dart';

class MiniKLinePainter extends CustomPainter {
  MiniKLinePainter({
    required this.data,
    required this.color,
    this.shadowColor,
    this.max = 0,
    this.min = 0,
    this.base,
    this.paintingStyle = PaintingStyle.fill,
    this.smooth = true,
    this.strokeWidth = 2,
  });

  bool smooth;
  double max;
  double min;
  double? base;
  final List<double> data;
  final PaintingStyle paintingStyle;
  final Color color;
  Color? shadowColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 3) return;
    shadowColor ??= color;
    if (smooth) {
      cubit(canvas, size);
    } else {
      line(canvas, size);
    }
  }

  void cubit(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;

    final path = Path();
    for (final v in data) {
      if (max < v) {
        max = v;
      } else if (min > v) {
        min = v;
      }
    }
    final yMin = min;
    final yMax = max;
    final yHeight = yMax - yMin;
    final xAxisStep = size.width / data.length;
    final height = size.height - 2;
    var xValue = 0.0;
    for (var i = 0; i < data.length; i++) {
      final value = data[i];
      final yValue = yHeight == 0 ? (0.5 * height) : ((yMax - value) / yHeight) * height;
      if (xValue == 0) {
        path.moveTo(xValue, yValue);
      } else {
        final previousValue = data[i - 1];
        final xPrevious = xValue - xAxisStep;
        final yPrevious =
            yHeight == 0 ? (0.5 * height) : ((yMax - previousValue) / yHeight) * height;
        final cX = xPrevious + (xValue - xPrevious) / 2;
        path.cubicTo(cX, yPrevious, cX, yValue, xValue, yValue);
      }
      xValue += xAxisStep;
    }
    canvas.drawPath(path, paint);
    if (paintingStyle == PaintingStyle.fill) {
      path.lineTo(size.width * (data.length - 1.0) / data.length, size.height);
      path.lineTo(0, size.height);
      path.lineTo(0, (data.first - min) / (max - min) * height);
      final paint1 = Paint();
      paint1.shader = ui.Gradient.linear(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        [
          shadowColor!.withValues(alpha: 0.5),
          shadowColor!.withValues(alpha: 0),
        ],
        [0, 1],
      );
      paint1.style = PaintingStyle.fill;
      canvas.drawPath(path, paint1);
    }
  }

  void line(Canvas canvas, Size size) {
    if (data.length < 2) return;

    for (final v in data) {
      if (max < v) {
        max = v;
      } else if (min > v) {
        min = v;
      }
    }
    final yMin = min;
    final yMax = max;
    final yHeight = yMax - yMin;
    final xAxisStep = size.width / (data.length - 1);
    final height = size.height;

    if (size.width < 2) return;
    final paint = Paint();

    paint.strokeWidth = strokeWidth;
    paint.style = PaintingStyle.stroke;
    paint.color = color;
    final path = Path();

    path.moveTo(0, ((yMax - data.first) / yHeight) * height);
    for (var i = 1; i < data.length; i++) {
      path.lineTo(xAxisStep * i, ((yMax - data[i]) / yHeight) * height);
    }
    canvas.drawPath(path, paint);

    if (paintingStyle == PaintingStyle.fill) {
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.lineTo(0, (yMax - data.first) / yHeight * height);
      final paint1 = Paint();
      paint1.shader = ui.Gradient.linear(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        [
          shadowColor!.withValues(alpha: 0.5),
          shadowColor!.withValues(alpha: 0),
        ],
        [0, 1],
      );
      paint1.style = PaintingStyle.fill;
      canvas.drawPath(path, paint1);
    }
  }

  @override
  bool shouldRepaint(MiniKLinePainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.color != color ||
        oldDelegate.max != max ||
        oldDelegate.min != min;
  }

  @override
  bool shouldRebuildSemantics(MiniKLinePainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.color != color ||
        oldDelegate.max != max ||
        oldDelegate.min != min;
  }
}
