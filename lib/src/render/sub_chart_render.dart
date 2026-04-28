import 'package:flux_kline/src/common/chart_theme.dart';
import 'package:flux_kline/src/common/constant.dart';
import 'package:flux_kline/src/model/kline.dart';
import 'package:flux_kline/src/render/base_render.dart';
import 'package:flutter/material.dart';

class SubChartRender extends BaseRender<KLineModel> {
  SubChartRender({
    required super.chartRect,
    required super.maxValue,
    required super.minValue,
    required super.scaleX,
    required super.settingConfig,
    required super.marginRight,
    required this.chartType,
    super.topPadding = ChartStyle.chartTopPadding,
  });

  SubChartType chartType;

  @override
  void drawChart(
    KLineModel lastPoint,
    KLineModel curPoint,
    double lastX,
    double curX,
    Size size,
    Canvas canvas,
  ) {
    switch (chartType) {
      case SubChartType.macd:
        final macdY = getY(curPoint.macd);
        const r = ChartStyle.macdWidth / 2;
        final zeroY = getY(0);
        if (curPoint.macd > 0) {
          canvas.drawRRect(
            RRect.fromLTRBR(curX - r, macdY, curX + r, zeroY, const Radius.circular(0.5)),
            chartPaint..color = settingConfig.upColor,
          );
        } else {
          canvas.drawRRect(
            RRect.fromLTRBR(curX - r, zeroY, curX + r, macdY, const Radius.circular(0.5)),
            chartPaint..color = settingConfig.downColor,
          );
        }
        if (lastPoint.dif != 0) {
          drawLine(lastPoint.dif, curPoint.dif, canvas, lastX, curX, ChartColors.dif);
        }
        if (lastPoint.dea != 0) {
          drawLine(lastPoint.dea, curPoint.dea, canvas, lastX, curX, ChartColors.dea);
        }
        break;
      case SubChartType.kdj:
        if (lastPoint.k != 0) {
          drawLine(lastPoint.k, curPoint.k, canvas, lastX, curX, ChartColors.k);
        }
        if (lastPoint.d != 0) {
          drawLine(lastPoint.d, curPoint.d, canvas, lastX, curX, ChartColors.d);
        }
        if (lastPoint.j != 0) {
          drawLine(lastPoint.j, curPoint.j, canvas, lastX, curX, ChartColors.j);
        }
        break;
      case SubChartType.rsi:
        if (lastPoint.rsi6 != 0) {
          drawLine(lastPoint.rsi6, curPoint.rsi6, canvas, lastX, curX, ChartColors.rsi6);
        }
        if (lastPoint.rsi12 != 0) {
          drawLine(lastPoint.rsi12, curPoint.rsi12, canvas, lastX, curX, ChartColors.rsi12);
        }
        if (lastPoint.rsi24 != 0) {
          drawLine(lastPoint.rsi24, curPoint.rsi24, canvas, lastX, curX, ChartColors.rsi24);
        }
        break;
      case SubChartType.wr:
        if (lastPoint.wr14 != 0) {
          drawLine(lastPoint.wr14, curPoint.wr14, canvas, lastX, curX, ChartColors.wr14);
        }
        if (lastPoint.wr20 != 0) {
          drawLine(lastPoint.wr20, curPoint.wr20, canvas, lastX, curX, ChartColors.wr20);
        }
        break;
      case SubChartType.volume:
        const r = ChartStyle.volWidth / 2;
        final top = getY(curPoint.vol);
        final bottom = chartRect.bottom;
        canvas.drawRRect(
          RRect.fromLTRBR(curX - r, top, curX + r, bottom, const Radius.circular(0.5)),
          chartPaint
            ..color =
                curPoint.close >= curPoint.open ? settingConfig.upColor : settingConfig.downColor,
        );

        if (lastPoint.ma5Volume != 0) {
          drawLine(
            lastPoint.ma5Volume,
            curPoint.ma5Volume,
            canvas,
            lastX,
            curX,
            ChartColors.ma5,
          );
        }

        if (lastPoint.ma10Volume != 0) {
          drawLine(
            lastPoint.ma10Volume,
            curPoint.ma10Volume,
            canvas,
            lastX,
            curX,
            ChartColors.ma10,
          );
        }
        break;
      default:
        break;
    }
  }

  @override
  double getY(double y) {
    if (chartType == SubChartType.volume) {
      if (maxValue == 0) return chartRect.bottom;
      return (maxValue - y) * (chartRect.height / maxValue) + chartRect.top;
    }
    return super.getY(y);
  }

  @override
  void drawText(Canvas canvas, KLineModel data, double x) {
    List<TextSpan> children;
    switch (chartType) {
      case SubChartType.macd:
        children = [
          TextSpan(text: 'MACD(12,26,9)    ', style: getTextStyle(Colors.grey)),
          if (data.macd != 0)
            TextSpan(text: 'MACD: ${format(data.macd)}    ', style: getTextStyle(ChartColors.macd)),
          if (data.dif != 0)
            TextSpan(text: 'DIF: ${format(data.dif)}    ', style: getTextStyle(ChartColors.dif)),
          if (data.dea != 0)
            TextSpan(text: 'DEA: ${format(data.dea)}    ', style: getTextStyle(ChartColors.dea)),
        ];
        break;
      case SubChartType.kdj:
        children = [
          TextSpan(text: 'KDJ(9,3,3)    ', style: getTextStyle(Colors.grey)),
          if (data.macd != 0)
            TextSpan(text: 'K: ${format(data.k)}    ', style: getTextStyle(ChartColors.k)),
          if (data.dif != 0)
            TextSpan(text: 'D: ${format(data.d)}    ', style: getTextStyle(ChartColors.d)),
          if (data.dea != 0)
            TextSpan(text: 'J: ${format(data.j)}    ', style: getTextStyle(ChartColors.j)),
        ];
        break;
      case SubChartType.rsi:
        children = [
          if (data.rsi6 != 0)
            TextSpan(
                text: 'RSI6: ${format(data.rsi6)}    ', style: getTextStyle(ChartColors.rsi6)),
          if (data.rsi12 != 0)
            TextSpan(
                text: 'RSI12: ${format(data.rsi12)}    ', style: getTextStyle(ChartColors.rsi12)),
          if (data.rsi24 != 0)
            TextSpan(
                text: 'RSI24: ${format(data.rsi24)}    ', style: getTextStyle(ChartColors.rsi24)),
        ];
        break;
      case SubChartType.wr:
        children = [
          if (data.wr14 != 0)
            TextSpan(
                text: 'WR14: ${format(data.wr14)}    ', style: getTextStyle(ChartColors.wr14)),
          if (data.wr20 != 0)
            TextSpan(
                text: 'WR20: ${format(data.wr20)}    ', style: getTextStyle(ChartColors.wr20)),
        ];
        break;
      case SubChartType.volume:
        children = [
          TextSpan(text: 'VOL: ${format(data.vol)}    ', style: getTextStyle(ChartColors.vol)),
          TextSpan(
              text: 'MA5: ${format(data.ma5Volume)}    ', style: getTextStyle(ChartColors.ma5)),
          TextSpan(
              text: 'MA10: ${format(data.ma10Volume)}    ', style: getTextStyle(ChartColors.ma10)),
        ];
        break;
      default:
        children = <TextSpan>[];
        break;
    }
    final tp = TextPainter(text: TextSpan(children: children), textDirection: TextDirection.ltr);
    tp.layout(minWidth: chartRect.left, maxWidth: chartRect.width - marginRight);
    tp.paint(canvas, Offset(x, chartRect.top - topPadding));
  }

  @override
  void drawYAxis(Canvas canvas, TextStyle textStyle, int gridRows) {
    final maxTp = TextPainter(
      text: TextSpan(text: format(maxValue), style: textStyle),
      textDirection: TextDirection.ltr,
    );
    maxTp.layout();
    maxTp.paint(
      canvas,
      Offset(chartRect.width - maxTp.width, chartRect.top - topPadding + maxTp.height / 1.2),
    );

    final minTp = TextPainter(
      text: TextSpan(text: format(minValue), style: textStyle),
      textDirection: TextDirection.ltr,
    );
    minTp.layout();
    minTp.paint(canvas, Offset(chartRect.width - minTp.width, chartRect.bottom - minTp.height / 2));
  }

  @override
  void drawGrid(Canvas canvas) {
    canvas.drawLine(
      Offset(0, chartRect.bottom),
      Offset(chartRect.width, chartRect.bottom),
      gridPaint,
    );
    final columnSpace = chartRect.width / ChartStyle.gridColumns;
    for (var i = 0; i <= columnSpace; i++) {
      canvas.drawLine(
        Offset(columnSpace * i, chartRect.top - topPadding),
        Offset(columnSpace * i, chartRect.bottom),
        gridPaint,
      );
    }
  }
}
