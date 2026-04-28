import 'package:flux_kline/src/common/chart_theme.dart';
import 'package:flux_kline/src/common/constant.dart';
import 'package:flux_kline/src/model/candle.dart';
import 'package:flux_kline/src/render/base_render.dart';
import 'package:flutter/material.dart';

class MainChartRender extends BaseRender<CandleModel> {
  MainChartRender({
    required super.chartRect,
    required super.maxValue,
    required super.minValue,
    required super.scaleX,
    required super.settingConfig,
    required super.marginRight,
    required this.indicators,
    required this.isTimeLine,
    super.topPadding = ChartStyle.chartTopPadding,
  }) {
    final height = maxValue - minValue;
    if (height > 0) {
      final newScaleY = (chartRect.height - ChartStyle.contentPadding) / height;
      final newHeight = chartRect.height / newScaleY;
      final value = (newHeight - height) / 2;
      if (newHeight > height) {
        scaleY = newScaleY;
        maxValue += value;
        minValue -= value;
      }
    }
  }

  Set<MainChartIndicator> indicators;
  bool isTimeLine;

  late Shader _timeLineFillShader;
  late Path _timeLinePath;
  late Path _timeLineFillPath;
  final double _timeLineStrokeWidth = 1;
  final Paint _timeLinePaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..color = ChartColors.timeLine;
  final Paint _timeLineFillPaint = Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  @override
  void drawText(Canvas canvas, CandleModel data, double x) {
    if (isTimeLine) return;
    TextSpan? span;
    if (indicators.isNotEmpty) {
      span = TextSpan(
        children: [
          if (indicators.contains(MainChartIndicator.ma)) ...[
            if (data.ma5 != 0)
              TextSpan(
                text: 'MA5:${format(data.ma5)}    ',
                style: getTextStyle(ChartColors.ma5),
              ),
            if (data.ma10 != 0)
              TextSpan(
                text: 'MA10:${format(data.ma10)}    ',
                style: getTextStyle(ChartColors.ma10),
              ),
            if (data.ma20 != 0)
              TextSpan(
                text: 'MA20:${format(data.ma20)}    ',
                style: getTextStyle(ChartColors.ma20),
              ),
          ],
          if (indicators.contains(MainChartIndicator.boll)) ...[
            if (data.mid != 0)
              TextSpan(
                text: 'BOLL:${format(data.mid)}    ',
                style: getTextStyle(ChartColors.bollMid),
              ),
            if (data.up != 0)
              TextSpan(
                text: 'UP:${format(data.up)}    ',
                style: getTextStyle(ChartColors.bollUp),
              ),
            if (data.down != 0)
              TextSpan(
                text: 'LB:${format(data.down)}    ',
                style: getTextStyle(ChartColors.bollDown),
              ),
          ]
        ],
      );
    }
    if (span == null) return;
    final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout(minWidth: chartRect.left, maxWidth: chartRect.width - marginRight);
    tp.paint(canvas, Offset(x, chartRect.top - topPadding));
  }

  @override
  void drawChart(
    CandleModel lastPoint,
    CandleModel curPoint,
    double lastX,
    double curX,
    Size size,
    Canvas canvas,
  ) {
    if (isTimeLine) {
      _drawTimeLine(lastPoint.close, curPoint.close, canvas, lastX, curX);
    } else {
      _drawCandle(curPoint, canvas, curX);
      if (indicators.contains(MainChartIndicator.ma)) {
        _drawMaLine(lastPoint, curPoint, canvas, lastX, curX);
      }
      if (indicators.contains(MainChartIndicator.boll)) {
        _drawBollLine(lastPoint, curPoint, canvas, lastX, curX);
      }
    }
  }

  void _drawTimeLine(double lastPrice, double curPrice, Canvas canvas, double lastX, double curX) {
    _timeLinePath = Path();

    final x = lastX == curX ? 0.0 : lastX;

    _timeLinePath.moveTo(x, getY(lastPrice));
    _timeLinePath.cubicTo(
      (x + curX) / 2,
      getY(lastPrice),
      (x + curX) / 2,
      getY(curPrice),
      curX,
      getY(curPrice),
    );

    _timeLineFillShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: ChartColors.timeLineShadow,
    ).createShader(Rect.fromLTRB(chartRect.left, chartRect.top, chartRect.right, chartRect.bottom));
    _timeLineFillPaint.shader = _timeLineFillShader;

    _timeLineFillPath = Path();

    _timeLineFillPath.moveTo(x, chartRect.height + chartRect.top);
    _timeLineFillPath.lineTo(x, getY(lastPrice));
    _timeLineFillPath.cubicTo(
      (x + curX) / 2,
      getY(lastPrice),
      (x + curX) / 2,
      getY(curPrice),
      curX,
      getY(curPrice),
    );
    _timeLineFillPath.lineTo(curX, chartRect.height + chartRect.top);
    _timeLineFillPath.close();

    canvas.drawPath(_timeLineFillPath, _timeLineFillPaint);
    _timeLineFillPath.reset();

    canvas.drawPath(
      _timeLinePath,
      _timeLinePaint..strokeWidth = (_timeLineStrokeWidth / scaleX).clamp(0.3, 1.0),
    );
    _timeLinePath.reset();
  }

  void _drawMaLine(
    CandleModel lastPoint,
    CandleModel curPoint,
    Canvas canvas,
    double lastX,
    double curX,
  ) {
    if (lastPoint.ma5 != 0) {
      drawLine(lastPoint.ma5, curPoint.ma5, canvas, lastX, curX, ChartColors.ma5);
    }
    if (lastPoint.ma10 != 0) {
      drawLine(lastPoint.ma10, curPoint.ma10, canvas, lastX, curX, ChartColors.ma10);
    }
    if (lastPoint.ma20 != 0) {
      drawLine(lastPoint.ma20, curPoint.ma20, canvas, lastX, curX, ChartColors.ma20);
    }
  }

  void _drawBollLine(
    CandleModel lastPoint,
    CandleModel curPoint,
    Canvas canvas,
    double lastX,
    double curX,
  ) {
    if (lastPoint.up != 0) {
      drawLine(lastPoint.up, curPoint.up, canvas, lastX, curX, ChartColors.bollUp);
    }
    if (lastPoint.mid != 0) {
      drawLine(lastPoint.mid, curPoint.mid, canvas, lastX, curX, ChartColors.bollMid);
    }
    if (lastPoint.down != 0) {
      drawLine(lastPoint.down, curPoint.down, canvas, lastX, curX, ChartColors.bollDown);
    }
  }

  void _drawCandle(CandleModel curPoint, Canvas canvas, double curX) {
    final high = getY(curPoint.high);
    final low = getY(curPoint.low);
    final open = getY(curPoint.open);
    var close = getY(curPoint.close);
    const r = ChartStyle.candleWidth / 2;
    const lineR = ChartStyle.candleLineWidth / 2;

    if ((close - open).abs() < ChartStyle.candleLineWidth) {
      if (close >= open) {
        close = open + ChartStyle.candleLineWidth;
      } else {
        close = open - ChartStyle.candleLineWidth;
      }
    }

    if (open >= close) {
      chartPaint.color = settingConfig.upColor;
      canvas.drawRRect(
        RRect.fromLTRBR(curX - r, close, curX + r, open, const Radius.circular(0.5)),
        chartPaint,
      );
    } else {
      chartPaint.color = settingConfig.downColor;
      canvas.drawRRect(
        RRect.fromLTRBR(curX - r, open, curX + r, close, const Radius.circular(0.5)),
        chartPaint,
      );
    }
    canvas.drawRRect(
      RRect.fromLTRBR(curX - lineR, high, curX + lineR, low, const Radius.circular(0.5)),
      chartPaint,
    );
  }

  @override
  void drawYAxis(Canvas canvas, TextStyle textStyle, int gridRows) {
    final rowSpace = chartRect.height / gridRows;
    for (var i = 0; i <= gridRows; i++) {
      final value = (gridRows - i) * rowSpace / scaleY + minValue;
      final span = TextSpan(text: format(value), style: textStyle);
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout();
      final dx = chartRect.width - tp.width;
      final dy = getY(value) - tp.height;
      if (!dx.isNaN && !dy.isNaN) {
        tp.paint(canvas, Offset(dx, dy));
      }
    }
  }

  @override
  void drawGrid(Canvas canvas) {
    final rowSpace = chartRect.height / ChartStyle.gridRows;
    for (var i = 0; i <= ChartStyle.gridRows; i++) {
      canvas.drawLine(
        Offset(0, rowSpace * i + topPadding),
        Offset(chartRect.width, rowSpace * i + topPadding),
        gridPaint,
      );
    }
  }
}
