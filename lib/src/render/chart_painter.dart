import 'package:flux_kline/src/common/chart_theme.dart';
import 'package:flux_kline/src/common/decimal_util.dart';
import 'package:flux_kline/src/config/settings_config.dart';
import 'package:flux_kline/src/controller/kline_controller.dart';
import 'package:flux_kline/src/model/candle.dart';
import 'package:flux_kline/src/model/info_window.dart';
import 'package:flux_kline/src/model/kline.dart';
import 'package:flux_kline/src/model/trade_info.dart';
import 'package:flux_kline/src/render/base_render.dart';
import 'package:flux_kline/src/render/main_chart_render.dart';
import 'package:flux_kline/src/render/sub_chart_render.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class ChartPainter extends CustomPainter {
  ChartPainter({
    required this.controller,
    required this.config,
    this.infoSubjectSubject,
  });

  final KLineController controller;
  final SettingConfig config;
  BehaviorSubject<InfoWindow>? infoSubjectSubject;

  late Rect _mainRect;

  Rect? _firstSubRect;
  Rect? _secondSubRect;
  late BaseRender<CandleModel> _mainRender;
  BaseRender<CandleModel>? _firstSubRender;
  BaseRender<CandleModel>? _secondSubRender;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTRB(0, 0, size.width, size.height));
    controller.calculateDisplay(size);
    _initRect(size);
    controller.calculateValue();
    _initChartRender();
    canvas.save();
    canvas.scale(1, 1);
    _drawGrid(canvas);
    if (!controller.isKLineDataEmpty()) {
      _drawChart(canvas, size);
      _drawYAxis(canvas);
      _drawMaxAndMin(canvas);
      _drawRealTimePrice(canvas, size);
      _drawDate(canvas, size);
      _drawSelfTradeInfo(canvas);
      if (controller.isLongPress) {
        _drawCrossLineText(canvas, size);
      }
      _drawText(canvas, controller.getLastKLineItem(), 5);
    }
    canvas.restore();
  }

  void _drawText(Canvas canvas, KLineModel last, double x) {
    var data = last;
    if (controller.isLongPress) {
      final index = controller.getSelectedXIndex();
      data = controller.getKLineItem(index);
    }
    _mainRender.drawText(canvas, data, x);
    _firstSubRender?.drawText(canvas, data, x);
    _secondSubRender?.drawText(canvas, data, x);
  }

  void _drawDate(Canvas canvas, Size size) {
    final gap = (7 / controller.scaleX).clamp(5, 14).toInt();
    for (var i = controller.startIndex; i <= controller.stopIndex; i++) {
      if (i % gap == 0) {
        final curPoint = controller.getKLineItem(i);
        final tp = _getTextPainter(controller.getDate(curPoint.openTime));
        final y = size.height - (ChartStyle.bottomDateHeight - tp.height) / 2 - tp.height;
        tp.paint(
          canvas,
          Offset(controller.translateXtoX(i) - tp.width / 2, y),
        );
      }
    }
  }

  TextPainter _getTextPainter(String text, {Color? color}) {
    final span = TextSpan(text: text, style: _getTextStyle(color ??= config.defaultTextColor));
    final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    return tp;
  }

  TextStyle _getTextStyle(Color color) =>
      TextStyle(fontSize: ChartStyle.defaultTextSize, color: color);

  final Paint _realTimePaint = Paint()
    ..strokeWidth = 1.0
    ..isAntiAlias = true;

  void _drawRealTimePrice(Canvas canvas, Size size) {
    if (config.isTrade || controller.marginRight == 0 || controller.isKLineDataEmpty()) {
      return;
    }
    final point = controller.getLastKLineItem();
    var tp = _getTextPainter(_formatData(point.close), color: config.realTimeTextColor);
    var y = _getMainRenderY(point.close);
    final max = controller.getRealTimePriceMaxWidth();
    var x = controller.displayWidth - max;
    if (!controller.isTimeLine) {
      x += ChartStyle.pointWidth / 2;
    }
    const dashWidth = 4;
    const dashSpace = 1;
    var startX = 0.0;
    const space = dashSpace + dashWidth;
    final textBgColor = point.close > point.open ? config.upColor : config.downColor;
    if (tp.width < max) {
      while (startX < max) {
        canvas.drawLine(
          Offset(x + startX, y),
          Offset(x + startX + dashWidth, y),
          _realTimePaint..color = config.realTimeLineColor,
        );
        startX += space;
      }
      final left = controller.displayWidth - tp.width - dashWidth;
      final top = y - tp.height / 2;
      canvas.drawRRect(
        RRect.fromLTRBR(
          left - dashWidth * 1.5,
          top - 1,
          left + tp.width + dashWidth,
          top + tp.height + 1,
          const Radius.circular(2),
        ),
        _realTimePaint..color = textBgColor,
      );
      tp.paint(canvas, Offset(left, top));
    } else {
      startX = 0;
      if (point.close > controller.mainMaxYAxis) {
        y = _getMainRenderY(controller.mainMaxYAxis);
      } else if (point.close < controller.mainMinYAxis) {
        y = _getMainRenderY(controller.mainMinYAxis);
      }
      while (startX < controller.displayWidth) {
        canvas.drawLine(
          Offset(startX, y),
          Offset(startX + dashWidth, y),
          _realTimePaint..color = config.realTimeLineColor,
        );
        startX += space;
      }

      const padding = 3.0;
      const triangleHeight = 8.0;
      const triangleWidth = 5.0;

      final left = controller.displayWidth -
          controller.displayWidth / ChartStyle.gridColumns -
          tp.width / 2 -
          padding * 2;
      final top = y - tp.height / 2 - padding;
      final right = left + tp.width + padding * 2 + triangleWidth + padding;
      final bottom = top + tp.height + padding * 2;
      final radius = (bottom - top) / 2;
      final rectBg = RRect.fromLTRBR(
        left - padding * 2,
        top,
        right,
        bottom,
        Radius.circular(radius),
      );
      controller.setRealTimePriceClamp(left - padding * 2, right, top, bottom);
      canvas.drawRRect(rectBg, _realTimePaint..color = config.realTimeBgColor);
      tp = _getTextPainter(_formatData(point.close), color: config.realTimeInLineTextColor);
      final textOffset = Offset(left, y - tp.height / 2 + 0.5);
      tp.paint(canvas, textOffset);
      final path = Path();
      final dx = tp.width + textOffset.dx + padding;
      final dy = top + (bottom - top - triangleHeight) / 2;
      path.moveTo(dx, dy);
      path.lineTo(dx + triangleWidth, dy + triangleHeight / 2);
      path.lineTo(dx, dy + triangleHeight);
      path.close();
      canvas.drawPath(
        path,
        _realTimePaint
          ..color = config.realTimeInLineTextColor
          ..shader = null,
      );
    }
  }

  void _drawSelfTradeInfo(Canvas canvas) {
    if (config.isTrade) return;
    for (final info in controller.positionList) {
      _drawTradeInfoLine(canvas, info);
    }
    for (final info in controller.orderList) {
      _drawTradeInfoLine(canvas, info);
    }
  }

  void _drawTradeInfoLine(Canvas canvas, KLineTradeInfo info) {
    var tp = _getTextPainter(_formatData(info.price), color: config.realTimeTextColor);
    var y = _getMainRenderY(info.price);

    final infoColor = info.isPositive ? config.upColor : config.downColor;
    const dashWidth = 4;
    const dashSpace = 1;
    const space = dashSpace + dashWidth;
    var startX = 0.0;
    if (info.price > controller.mainMaxYAxis) {
      y = _getMainRenderY(controller.mainMaxYAxis);
    } else if (info.price < controller.mainMinYAxis) {
      y = _getMainRenderY(controller.mainMinYAxis);
    }
    while (startX < controller.displayWidth) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(startX + dashWidth, y),
        _realTimePaint..color = infoColor,
      );
      startX += space;
    }
    final left = controller.displayWidth - tp.width - dashWidth;
    final top = y - tp.height / 2;
    canvas.drawRRect(
      RRect.fromLTRBR(
        left - dashWidth * 1.5,
        top - 1,
        left + tp.width + dashWidth,
        top + tp.height + 1,
        const Radius.circular(2),
      ),
      _realTimePaint..color = infoColor,
    );
    tp.paint(canvas, Offset(left, top));

    tp = _getTextPainter(info.info, color: infoColor);
    final textHeight = tp.height / 2;
    const hPadding = 4;
    const vPadding = 1;
    final r = textHeight + vPadding;
    var leftX = 1.0;
    final topY = y - r;
    var rightX = tp.width + 2 * hPadding;
    final bottomY = y + r;
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        leftX - 1,
        topY - 1,
        rightX + 1,
        bottomY + 1,
        topLeft: const Radius.circular(2),
        bottomLeft: const Radius.circular(2),
      ),
      _realTimePaint..color = Colors.grey.shade700,
    );
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        leftX,
        topY,
        rightX,
        bottomY,
        topLeft: const Radius.circular(1),
        bottomLeft: const Radius.circular(1),
      ),
      _realTimePaint..color = Colors.black,
    );
    tp.paint(
      canvas,
      Offset(
        leftX + hPadding,
        y - textHeight < top ? topY - 0.5 : y - textHeight + 0.5,
      ),
    );
    tp = _getTextPainter(info.amount, color: config.realTimeTextColor);
    leftX = rightX + 1;
    rightX = leftX + tp.width + dashWidth;
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        leftX,
        topY - 1,
        rightX,
        bottomY + 1,
        topRight: const Radius.circular(2),
        bottomRight: const Radius.circular(2),
      ),
      _realTimePaint..color = infoColor,
    );
    tp.paint(canvas, Offset(leftX + dashWidth / 2, top + 0.5));
  }

  void _drawYAxis(Canvas canvas) {
    final textStyle = _getTextStyle(config.defaultTextColor);
    _mainRender.drawYAxis(canvas, textStyle, ChartStyle.gridRows);
    _firstSubRender?.drawYAxis(canvas, textStyle, ChartStyle.gridRows);
    _secondSubRender?.drawYAxis(canvas, textStyle, ChartStyle.gridRows);
  }

  void _drawMaxAndMin(Canvas canvas) {
    if (controller.isTimeLine || controller.isScaleLine || config.isTrade) return;
    var x = controller.translateXtoX(controller.mainMinXIndex);
    var y = _getMainRenderY(controller.mainMinValue);
    if (x < controller.displayWidth / 2) {
      final tp = _getTextPainter('── ${_formatData(controller.mainMinValue)}');
      tp.paint(canvas, Offset(x, y - tp.height / 2));
    } else {
      final tp = _getTextPainter('${_formatData(controller.mainMinValue)} ──');
      tp.paint(canvas, Offset(x - tp.width, y - tp.height / 2));
    }
    x = controller.translateXtoX(controller.mainMaxXIndex);
    y = _getMainRenderY(controller.mainMaxValue);
    if (x < controller.displayWidth / 2) {
      final tp = _getTextPainter('── ${_formatData(controller.mainMaxValue)}');
      tp.paint(canvas, Offset(x, y - tp.height / 2));
    } else {
      final tp = _getTextPainter('${_formatData(controller.mainMaxValue)} ──');
      tp.paint(canvas, Offset(x - tp.width, y - tp.height / 2));
    }
  }

  void _drawChart(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(controller.translateX * controller.scaleX, 0);
    canvas.scale(controller.scaleX, 1);
    for (var i = controller.startIndex; i <= controller.stopIndex; i++) {
      final curPoint = controller.getKLineItem(i);
      final lastPoint = i == 0 ? curPoint : controller.getKLineItem(i - 1);
      final curX = controller.getX(i);
      final lastX = i == 0 ? curX : controller.getX(i - 1);

      _mainRender.drawChart(lastPoint, curPoint, lastX, curX, size, canvas);
      _firstSubRender?.drawChart(lastPoint, curPoint, lastX, curX, size, canvas);
      _secondSubRender?.drawChart(lastPoint, curPoint, lastX, curX, size, canvas);
    }

    if (controller.isLongPress) {
      _drawCrossLine(canvas, size);
    }
    canvas.restore();
  }

  void _drawCrossLine(Canvas canvas, Size size) {
    if (config.isTrade) return;
    final index = controller.getSelectedXIndex();
    final paintY = Paint()
      ..color = config.vCrossLineColor
      ..strokeWidth = ChartStyle.vCrossWidth
      ..isAntiAlias = true;
    final x = controller.getX(index);
    final y = controller.selectY;
    canvas.drawLine(
      Offset(x, ChartStyle.vCrossPadding),
      Offset(x, size.height - ChartStyle.bottomDateHeight),
      paintY,
    );

    final paintX = Paint()
      ..color = config.hCrossLineColor
      ..strokeWidth = ChartStyle.hCrossWidth
      ..isAntiAlias = true;
    canvas.drawLine(
      Offset(-controller.translateX, y),
      Offset(
        -controller.translateX + controller.displayWidth / controller.scaleX,
        y,
      ),
      paintX,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y), height: 12 * controller.scaleX, width: 12),
      paintY..color = config.crossLinePointColor.withValues(alpha: 0.5),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y), height: 4 * controller.scaleX, width: 4),
      paintY..color = config.crossLinePointColor,
    );
  }

  final Paint _selectPointPaint = Paint()
    ..isAntiAlias = true
    ..strokeWidth = 0.5
    ..color = Colors.grey.shade700;

  void _drawCrossLineText(Canvas canvas, Size size) {
    if (config.isTrade) return;
    final index = controller.getSelectedXIndex();
    final point = controller.getKLineItem(index);

    var y = controller.selectY;

    final text = _formatData(_getRenderDisplayValueY(y));
    final tp = _getTextPainter(text, color: config.crossLineTextColor);
    final textHeight = tp.height;
    var textWidth = tp.width;

    const hPadding = 5;
    const vPadding = 1;
    var r = textHeight / 2 + vPadding;
    double x;
    var layoutInLeft = false;
    if (controller.translateXtoX(index) > controller.displayWidth / 2) {
      layoutInLeft = true;
      x = controller.displayWidth - textWidth - 2 * hPadding;
      canvas.drawRRect(
        RRect.fromLTRBR(
          x,
          y - r,
          controller.displayWidth,
          y + r,
          const Radius.circular(2),
        ),
        _selectPointPaint,
      );
      tp.paint(canvas, Offset(x + hPadding + vPadding, y - textHeight / 2));
    } else {
      layoutInLeft = false;
      x = 1;
      canvas.drawRRect(
        RRect.fromLTRBR(
          x,
          y - r,
          textWidth + 2 * hPadding,
          y + r,
          const Radius.circular(2),
        ),
        _selectPointPaint,
      );
      tp.paint(canvas, Offset(x + hPadding, y - textHeight / 2));
    }

    final dateTp = _getTextPainter(
      controller.formatCrossLineTime(point.openTime),
      color: config.crossLineTextColor,
    );
    textWidth = dateTp.width;
    r = textHeight / 2;
    x = controller.translateXtoX(index);
    y = size.height - ChartStyle.bottomDateHeight + vPadding;

    if (x < textWidth + 2 * hPadding) {
      x = 1 + textWidth / 2 + hPadding;
    } else if (controller.displayWidth - x < textWidth + 2 * hPadding) {
      x = controller.displayWidth - 1 - textWidth / 2 - hPadding;
    }
    final baseLine = textHeight / 2;
    canvas.drawRRect(
      RRect.fromLTRBR(
        x - textWidth / 2 - hPadding,
        y,
        x + textWidth / 2 + hPadding,
        y + baseLine + r,
        const Radius.circular(2),
      ),
      _selectPointPaint,
    );

    dateTp.paint(canvas, Offset(x - textWidth / 2, y));
    infoSubjectSubject?.add(InfoWindow(kLineModel: point, layoutInLeft: layoutInLeft));
  }

  double _getMainRenderY(double y) => _mainRender.getY(y);

  double _getRenderDisplayValueY(double dy) {
    final mainChartBottom = _mainRect.height + ChartStyle.chartTopPadding;
    final subChartHeight = controller.displayHeight * 0.2;
    if (dy <= mainChartBottom) {
      return _mainRender.getDisplayValueY(dy);
    } else if (dy <= mainChartBottom + subChartHeight) {
      return _firstSubRender?.getDisplayValueY(dy) ?? _mainRender.getDisplayValueY(dy);
    } else if (dy <= mainChartBottom + subChartHeight * 2) {
      return _secondSubRender?.getDisplayValueY(dy) ?? _mainRender.getDisplayValueY(dy);
    }
    return _mainRender.getDisplayValueY(dy);
  }

  void _drawGrid(Canvas canvas) {
    _mainRender.drawGrid(canvas);
    _firstSubRender?.drawGrid(canvas);
    _secondSubRender?.drawGrid(canvas);
  }

  void _initChartRender() {
    _mainRender = MainChartRender(
      chartRect: _mainRect,
      maxValue: controller.mainMaxYAxis,
      minValue: controller.mainMinYAxis,
      scaleX: controller.scaleX,
      settingConfig: config,
      marginRight: controller.marginRight,
      indicators: controller.indicatorSet,
      isTimeLine: controller.isTimeLine || controller.isScaleLine,
    );
    if (_firstSubRect != null) {
      _firstSubRender ??= SubChartRender(
        chartRect: _firstSubRect!,
        maxValue: controller.firstSubChart.maxValue,
        minValue: controller.firstSubChart.minValue,
        scaleX: controller.scaleX,
        settingConfig: config,
        marginRight: controller.marginRight,
        chartType: controller.firstSubChart.chartType,
      );
    }
    if (_secondSubRect != null) {
      _secondSubRender ??= SubChartRender(
        chartRect: _secondSubRect!,
        maxValue: controller.secondSubChart.maxValue,
        minValue: controller.secondSubChart.minValue,
        scaleX: controller.scaleX,
        settingConfig: config,
        marginRight: controller.marginRight,
        chartType: controller.secondSubChart.chartType,
      );
    }
  }

  void _initRect(Size size) {
    var mainHeight = controller.displayHeight;
    final subHeight = controller.displayHeight * 0.2;
    if (controller.isOnlyMainChart()) {
      mainHeight = controller.displayHeight;
    } else if (controller.isOneSubChart()) {
      mainHeight = controller.displayHeight * 0.8;
    } else {
      mainHeight = controller.displayHeight * 0.6;
    }
    _mainRect = Rect.fromLTRB(
      0,
      ChartStyle.chartTopPadding,
      controller.displayWidth,
      ChartStyle.chartTopPadding + mainHeight,
    );
    if (controller.isFirstChartValid()) {
      _firstSubRect = Rect.fromLTRB(
        0,
        _mainRect.bottom + ChartStyle.chartTopPadding,
        controller.displayWidth,
        _mainRect.bottom + subHeight,
      );
    }
    if (controller.isSecondChartValid()) {
      _secondSubRect = Rect.fromLTRB(
        0,
        (_firstSubRect?.bottom ?? _mainRect.bottom) + ChartStyle.chartTopPadding,
        controller.displayWidth,
        (_firstSubRect?.bottom ?? _mainRect.bottom) + subHeight,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  String _formatData(double v) =>
      v.formatPrice(maxDigits: config.tickSize, minDigits: 2);
}
