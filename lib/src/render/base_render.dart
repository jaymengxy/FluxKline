import 'package:flux_kline/src/common/chart_theme.dart';
import 'package:flux_kline/src/common/decimal_util.dart';
import 'package:flux_kline/src/config/settings_config.dart';
import 'package:flutter/material.dart';

abstract class BaseRender<T> {
  BaseRender({
    required this.chartRect,
    required this.maxValue,
    required this.minValue,
    required this.scaleX,
    required this.settingConfig,
    required this.marginRight,
    required this.topPadding,
  }) {
    if (maxValue == minValue) {
      maxValue *= 1.5;
      minValue /= 2;
    }
    final scaleHeight = maxValue - minValue;
    if (scaleHeight > 0) {
      scaleY = chartRect.height / scaleHeight;
    } else {
      scaleY = 1;
    }
  }

  final SettingConfig settingConfig;
  final double topPadding;
  final double marginRight;
  double maxValue;
  double minValue;
  late double scaleX;
  late double scaleY;
  Rect chartRect;
  final Paint chartPaint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.high
    ..strokeWidth = 1.0;
  final Paint gridPaint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.high
    ..strokeWidth = 0.5
    ..color = ChartColors.grid;

  double getY(double y) => (maxValue - y) * scaleY + chartRect.top;

  double getDisplayValueY(double dy) {
    return maxValue - (dy - chartRect.top) / scaleY;
  }

  String format(double n) {
    return n.formatPrice(maxDigits: settingConfig.tickSize, minDigits: 2);
  }

  void drawGrid(Canvas canvas);

  void drawText(Canvas canvas, T data, double x);

  void drawYAxis(Canvas canvas, TextStyle textStyle, int gridRows);

  void drawChart(T lastPoint, T curPoint, double lastX, double curX, Size size, Canvas canvas);

  void drawLine(
    double lastPrice,
    double curPrice,
    Canvas canvas,
    double lastX,
    double curX,
    Color color,
  ) {
    final lastY = getY(lastPrice);
    final curY = getY(curPrice);
    canvas.drawLine(Offset(lastX, lastY), Offset(curX, curY), chartPaint..color = color);
  }

  TextStyle getTextStyle(Color color) {
    return TextStyle(fontSize: ChartStyle.defaultTextSize, color: color);
  }
}
