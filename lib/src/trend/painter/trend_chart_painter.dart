import 'package:flux_kline/src/common/decimal_util.dart';
import 'package:flux_kline/src/trend/config/trend_chart_config.dart';
import 'package:flux_kline/src/trend/controller/trend_chart_controller.dart';
import 'package:flutter/material.dart';

class TrendChartPainter extends CustomPainter {
  TrendChartPainter({
    required this.controller,
    required this.config,
  });

  final TrendChartController controller;
  final TrendChartConfig config;

  late Rect _rect;
  late Path _linePath;
  late Shader _lineFillShader;

  double maxValue = -double.maxFinite;
  double minValue = double.maxFinite;
  double _scaleY = 1;
  double _rowHeight = 0;

  final Paint _linePaint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.high
    ..style = PaintingStyle.stroke
    ..strokeWidth = TrendChartConfig.lineWidth;

  final Paint _lineFillPaint = Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  final Paint _dividerPaint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.high
    ..style = PaintingStyle.stroke
    ..strokeWidth = TrendChartConfig.dividerWidth;

  final Paint _selectedYPaint = Paint()
    ..isAntiAlias = true
    ..strokeWidth = TrendChartConfig.selectedPointWidth;

  final Paint _selectedXPaint = Paint()
    ..isAntiAlias = true
    ..strokeWidth = TrendChartConfig.dividerWidth;

  final Paint _selectedTextBgPaint = Paint()
    ..isAntiAlias = true
    ..strokeWidth = 0.5
    ..color = Colors.grey.shade700;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTRB(0, 0, size.width, size.height));
    controller.calculateDisplay(size);
    controller.calculateValue();
    _rect = Rect.fromLTRB(0, 0, controller.displayWidth, controller.displayHeight);
    _calculateRect();
    canvas.save();
    canvas.scale(1, 1);
    _drawDivider(canvas);
    _drawTrendLine(canvas, size);
    _drawYAxis(canvas);
    _drawDate(canvas, size);
    if (controller.isSelected) {
      _drawSelectedText(canvas, size);
    }
    canvas.restore();
  }

  void _calculateRect() {
    maxValue = controller.maxYAxis;
    minValue = controller.minYAxis;
    if (maxValue == minValue) {
      maxValue *= 1.5;
      minValue /= 2;
    }
    _scaleY = _rect.height / (maxValue - minValue);
    _rowHeight = _rect.height / TrendChartConfig.rows;
    final height = maxValue - minValue;
    final newScaleY = (_rect.height - _rowHeight * 2) / height;
    final newHeight = _rect.height / newScaleY;
    final value = (newHeight - height) / 2;
    if (newHeight > height) {
      _scaleY = newScaleY;
      maxValue += value * 2;
      minValue -= value * 2;
    }
  }

  void _drawTrendLine(Canvas canvas, Size size) {
    canvas.save();
    _linePath = Path();

    final startIndex = controller.startIndex;
    final startPoint = controller.getTrendItem(controller.startIndex);
    final startX = controller.getX(startIndex);
    _linePath.moveTo(startX, getY(startPoint.price));

    for (var i = controller.startIndex; i <= controller.stopIndex; i++) {
      final curPoint = controller.getTrendItem(i);
      final curX = controller.getX(i);
      final curPrice = curPoint.price;
      _linePath.lineTo(curX, getY(curPrice));
    }
    canvas.drawPath(_linePath, _linePaint..color = config.lineColor);

    _linePath.lineTo(controller.getX(controller.stopIndex), _rect.height);
    _linePath.lineTo(startX, _rect.height);
    _linePath.lineTo(startX, getY(startPoint.price));

    _lineFillShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: config.lineShadowColor,
      stops: const [0, 1],
    ).createShader(Rect.fromLTRB(_rect.left, _rect.top, _rect.right, _rect.bottom));
    canvas.drawPath(_linePath, _lineFillPaint..shader = _lineFillShader);

    if (controller.isSelected) {
      _drawSelectedLine(canvas, size);
    }
    canvas.restore();
  }

  void _drawDivider(Canvas canvas) {
    for (var i = 0; i < TrendChartConfig.rows; i++) {
      canvas.drawLine(
        Offset(0, _rowHeight * (i + 1) + TrendChartConfig.topPadding),
        Offset(_rect.width, _rowHeight * (i + 1) + TrendChartConfig.topPadding),
        _dividerPaint..color = config.dividerColor,
      );
    }
  }

  void _drawYAxis(Canvas canvas) {
    for (var i = 0; i <= TrendChartConfig.rows; i++) {
      final value = (TrendChartConfig.rows - i) * _rowHeight / _scaleY + minValue;
      final tp =
          _getTextPainter(_formatData(value: value < 0 ? 0 : value), color: config.textColor);
      tp.layout();
      tp.paint(canvas, Offset(_rect.width - tp.width, getY(value) - tp.height));
    }
  }

  void _drawDate(Canvas canvas, Size size) {
    var column = TrendChartConfig.columns;
    var space = 1;
    if (controller.itemCount <= TrendChartConfig.columns) {
      column = controller.itemCount;
    } else {
      space = controller.itemCount ~/ TrendChartConfig.columns;
    }
    var y = 0.0;
    for (var i = 0; i < column; i++) {
      final index = i * space;
      final translateX = controller.getX(index);
      final tp = _getTextPainter(
        controller.getDate(controller.getTrendItem(index).time),
        color: config.textColor,
      );
      y = size.height - TrendChartConfig.dateHeight + TrendChartConfig.topPadding;
      tp.paint(
        canvas,
        Offset(
          (translateX - tp.width / 2).clamp(0, size.width - tp.width),
          y,
        ),
      );
    }
  }

  void _drawSelectedLine(Canvas canvas, Size size) {
    final index = controller.getSelectedXIndex();
    final selectedItem = controller.getTrendItem(index);
    final selectX = controller.getX(index);
    final selectY = getY(selectedItem.price);
    final y = size.height - TrendChartConfig.dateHeight + TrendChartConfig.topPadding;
    canvas.drawLine(
      Offset(selectX, 0),
      Offset(selectX, y),
      _selectedYPaint..color = config.selectedLineColor,
    );
    canvas.drawLine(
      Offset(0, selectY),
      Offset(controller.displayWidth, selectY),
      _selectedXPaint..color = config.selectedLineColor,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(selectX, selectY), height: 6, width: 6),
      _selectedYPaint..color = config.selectedPointColor.withValues(alpha: 0.5),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(selectX, selectY), height: 2, width: 2),
      _selectedYPaint..color = config.selectedPointColor,
    );
  }

  void _drawSelectedText(Canvas canvas, Size size) {
    final index = controller.getSelectedXIndex();
    final selectedItem = controller.getTrendItem(index);

    var y = getY(selectedItem.price);
    final text = _formatData(value: selectedItem.price, tickSize: TrendChartConfig.tickSize + 1);
    final tp = _getTextPainter(text, color: config.selectedTextColor);
    final textHeight = tp.height;
    var textWidth = tp.width;

    const hPadding = 5;
    const vPadding = 1;

    var r = textHeight / 2 + vPadding;
    double x;
    if (controller.getX(index) < controller.displayWidth / 2) {
      x = controller.displayWidth - textWidth - 2 * hPadding;
      canvas.drawRRect(
        RRect.fromLTRBR(
          x,
          y - r,
          controller.displayWidth,
          y + r,
          const Radius.circular(2),
        ),
        _selectedTextBgPaint,
      );
      tp.paint(canvas, Offset(x + hPadding + vPadding, y - textHeight / 2));
    } else {
      x = 1;
      canvas.drawRRect(
        RRect.fromLTRBR(
          x,
          y - r,
          textWidth + 2 * hPadding,
          y + r,
          const Radius.circular(2),
        ),
        _selectedTextBgPaint,
      );
      tp.paint(canvas, Offset(x + hPadding, y - textHeight / 2));
    }

    final dateTp = _getTextPainter(
      controller.formatSelectedTime(selectedItem.time),
      color: config.selectedTextColor,
    );
    textWidth = dateTp.width;
    r = textHeight / 2;
    x = controller
        .getX(index)
        .clamp(textWidth / 2 + hPadding, controller.displayWidth - textWidth / 2 - hPadding);
    y = size.height - TrendChartConfig.dateHeight + TrendChartConfig.topPadding;
    final baseLine = textHeight / 2;
    canvas.drawRRect(
      RRect.fromLTRBR(
        x - textWidth / 2 - hPadding,
        y,
        x + textWidth / 2 + hPadding,
        y + baseLine + r,
        const Radius.circular(2),
      ),
      _selectedTextBgPaint,
    );
    dateTp.paint(canvas, Offset(x - textWidth / 2, y));
  }

  double getY(double y) =>
      (maxValue - y) * _scaleY + _rect.top - _rowHeight + TrendChartConfig.topPadding;

  double getDisplayValueY(double dy) {
    return maxValue - (dy - _rect.top - TrendChartConfig.topPadding) / _scaleY;
  }

  TextPainter _getTextPainter(String text, {Color color = Colors.white38}) {
    final span = TextSpan(
      text: text,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: color),
    );
    final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    return tp;
  }

  String _formatData({required double value, int? tickSize}) =>
      value.formatFixed(tickSize ?? TrendChartConfig.tickSize);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
