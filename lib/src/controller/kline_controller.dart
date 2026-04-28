import 'dart:math';

import 'package:flux_kline/src/common/chart_theme.dart';
import 'package:flux_kline/src/common/constant.dart';
import 'package:flux_kline/src/common/data_util.dart';
import 'package:flux_kline/src/model/kline.dart';
import 'package:flux_kline/src/model/sub_chart.dart';
import 'package:flux_kline/src/model/trade_info.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

typedef OnLoadMore = void Function();

class KLineController {
  final List<KLineModel> _models = <KLineModel>[];

  final _positionList = <KLineTradeInfo>[];
  final _orderList = <KLineTradeInfo>[];

  int _itemCount = 0;

  double maxScrollX = 0;
  double _scaleX = 1;
  double _lastScaleX = 1;
  double _scrollX = 0;
  double _selectX = 0;
  double _selectY = 0;

  bool isLongPress = false;
  bool isTimeLine = false;
  bool isScaleLine = false;

  OnLoadMore? onLoadMore;

  final Set<MainChartIndicator> indicatorSet = {};
  final SubChartModel firstSubChart = SubChartModel();
  final SubChartModel secondSubChart = SubChartModel();

  int _startIndex = 0;
  int _stopIndex = 0;
  double _translateX = -double.maxFinite;

  late double _displayWidth;
  late double _displayHeight;

  Offset? _scrollOffset;

  double _marginRight = 0;

  double _mainMaxYAxis = -double.maxFinite;
  double _mainMinYAxis = double.maxFinite;
  int _mainMaxXIndex = 0;
  int _mainMinXIndex = 0;
  double _mainMaxValue = -double.maxFinite;
  double _mainMinValue = double.maxFinite;

  String _timeFormats = 'yyyy-MM-dd HH:mm';

  double _realTimeLeftX = 0;
  double _realTimeRightX = 0;
  double _realTimeTopY = 0;
  double _realTimeBottomY = 0;

  double get scaleX => _scaleX;
  double get scrollX => _scrollX;
  double get selectX => _selectX;
  double get selectY => _selectY;
  double get translateX => _translateX;
  int get startIndex => _startIndex;
  int get stopIndex => _stopIndex;
  double get displayWidth => _displayWidth;
  double get displayHeight => _displayHeight;
  double get marginRight => _marginRight;
  double get mainMaxYAxis => _mainMaxYAxis;
  double get mainMinYAxis => _mainMinYAxis;
  int get mainMaxXIndex => _mainMaxXIndex;
  int get mainMinXIndex => _mainMinXIndex;
  double get mainMaxValue => _mainMaxValue;
  double get mainMinValue => _mainMinValue;
  List<KLineTradeInfo> get orderList => _orderList;
  List<KLineTradeInfo> get positionList => _positionList;

  bool showMainChartIndicator(MainChartIndicator indicator) {
    if (indicatorSet.add(indicator)) {
      return true;
    } else {
      return !indicatorSet.remove(indicator);
    }
  }

  void changeSubChartType(SubChartType type) {
    if (firstSubChart.chartType == SubChartType.none) {
      firstSubChart.changeChartType(type);
    } else if (firstSubChart.chartType == type) {
      firstSubChart.changeChartType(secondSubChart.chartType);
      secondSubChart.changeChartType(SubChartType.none);
    } else if (secondSubChart.chartType == type) {
      secondSubChart.changeChartType(SubChartType.none);
    } else {
      secondSubChart.changeChartType(type);
    }
  }

  bool isOnlyMainChart() {
    return firstSubChart.chartType == SubChartType.none &&
        secondSubChart.chartType == SubChartType.none;
  }

  bool isOneSubChart() {
    return firstSubChart.chartType == SubChartType.none ||
        secondSubChart.chartType == SubChartType.none;
  }

  bool isFirstChartValid() => firstSubChart.isValidChart();
  bool isSecondChartValid() => secondSubChart.isValidChart();

  void onScaleUpdate(double scale) {
    _scaleX = _lastScaleX * scale;
    if (_scaleX < 0.5) {
      isScaleLine = true;
      _scaleX = _scaleX.clamp(0.3, 0.5);
    } else {
      isScaleLine = false;
      _scaleX = _scaleX.clamp(0.5, 2.2);
    }
  }

  void onScaleEnd() {
    _lastScaleX = _scaleX;
  }

  void setRealTimePriceClamp(double leftX, double rightX, double topY, double bottomY) {
    _realTimeLeftX = leftX;
    _realTimeRightX = rightX;
    _realTimeTopY = topY;
    _realTimeBottomY = bottomY;
  }

  bool isClickRealTimePrice(double dx, double dy) {
    return (dx >= _realTimeLeftX && dx <= _realTimeRightX) &&
        (dy >= _realTimeTopY && dy <= _realTimeBottomY);
  }

  bool isSelectX(double dx) {
    if (_selectX != dx) {
      _selectX = dx;
      return true;
    }
    return false;
  }

  void onSelectYUpdate(double dy) {
    _selectY = dy.clamp(ChartStyle.vCrossPadding, displayHeight + ChartStyle.chartTopPadding);
  }

  bool isFlingIn(double value) {
    if (value >= maxScrollX) {
      _scrollX = maxScrollX;
      onLoadMore?.call();
      return false;
    } else if (value <= 0) {
      _scrollX = 0;
      return false;
    }
    _scrollX = value;
    return true;
  }

  // ignore: use_setters_to_change_properties
  void onScrollOffsetStart(Offset offset) {
    _scrollOffset = offset;
  }

  void onScrollOffsetUpdate(Offset offset) {
    final deltaOffset = offset - (_scrollOffset ?? Offset.zero);
    _scrollOffset = offset;
    onScrollUpdate(deltaOffset.dx);
  }

  void onScrollUpdate(double? primaryDelta) {
    _scrollX = ((primaryDelta ?? 0) / _scaleX + _scrollX).clamp(0.0, maxScrollX);
  }

  void calculateDisplay(Size size) {
    _displayWidth = size.width;
    _displayHeight = size.height - ChartStyle.chartTopPadding - ChartStyle.bottomDateHeight;
    _marginRight = (_displayWidth / ChartStyle.gridColumns - ChartStyle.pointWidth) / _scaleX;
  }

  void calculateValue() {
    if (_models.isEmpty) return;
    maxScrollX = getMinTranslateX().abs();
    _translateX = _scrollX + getMinTranslateX();
    _startIndex = indexOfTranslateX(xToTranslateX(0));
    _stopIndex = indexOfTranslateX(xToTranslateX(_displayWidth));
    _resetMainMaxMinValue();
    _resetSubMaxMinValue();
    for (var i = _startIndex; i <= _stopIndex; i++) {
      final item = getKLineItem(i);
      _getMainMaxMinValue(item, i);
      _getSubMaxMinValue(item);
    }
  }

  void _resetMainMaxMinValue() {
    _mainMaxYAxis = -double.maxFinite;
    _mainMinYAxis = double.maxFinite;
    _mainMaxValue = -double.maxFinite;
    _mainMinValue = double.maxFinite;
  }

  void _getMainMaxMinValue(KLineModel item, int i) {
    if (isTimeLine || isScaleLine) {
      _mainMaxYAxis = max(_mainMaxYAxis, item.close);
      _mainMinYAxis = min(_mainMinYAxis, item.close);
    } else {
      var maxPrice = item.high;
      var minPrice = item.low;
      if (indicatorSet.contains(MainChartIndicator.ma)) {
        if (item.ma5 != 0) {
          maxPrice = max(maxPrice, item.ma5);
          minPrice = min(minPrice, item.ma5);
        }
        if (item.ma10 != 0) {
          maxPrice = max(maxPrice, item.ma10);
          minPrice = min(minPrice, item.ma10);
        }
        if (item.ma20 != 0) {
          maxPrice = max(maxPrice, item.ma20);
          minPrice = min(minPrice, item.ma20);
        }
      }
      if (indicatorSet.contains(MainChartIndicator.boll)) {
        if (item.up != 0) {
          maxPrice = max(item.up, item.high);
        }
        if (item.down != 0) {
          minPrice = min(item.down, item.low);
        }
      }
      _mainMaxYAxis = max(_mainMaxYAxis, maxPrice);
      _mainMinYAxis = min(_mainMinYAxis, minPrice);

      if (_mainMaxValue < item.high) {
        _mainMaxValue = item.high;
        _mainMaxXIndex = i;
      }
      if (_mainMinValue > item.low) {
        _mainMinValue = item.low;
        _mainMinXIndex = i;
      }
    }
  }

  void _resetSubMaxMinValue() {
    firstSubChart.resetMaxMinValue();
    secondSubChart.resetMaxMinValue();
  }

  void _getSubMaxMinValue(KLineModel item) {
    firstSubChart.getSubMaxMinValue(item);
    secondSubChart.getSubMaxMinValue(item);
  }

  double xToTranslateX(double x) => -_translateX + x / _scaleX;

  int indexOfTranslateX(double translateX) => _indexOfTranslateX(translateX, 0, _itemCount - 1);

  int _indexOfTranslateX(double translateX, int start, int end) {
    if (end == start || end == -1) return start;
    if (end - start == 1) {
      final startValue = getX(start);
      final endValue = getX(end);
      return (translateX - startValue).abs() < (translateX - endValue).abs() ? start : end;
    }
    final mid = start + (end - start) ~/ 2;
    final midValue = getX(mid);
    if (translateX < midValue) {
      return _indexOfTranslateX(translateX, start, mid);
    } else if (translateX > midValue) {
      return _indexOfTranslateX(translateX, mid, end);
    } else {
      return mid;
    }
  }

  double getMinTranslateX() {
    var x = displayWidth / scaleX - getX(_itemCount);
    if (x < 0) {
      x -= _marginRight;
    } else {
      if (x < _marginRight) {
        x = x - _marginRight;
      } else {
        _marginRight = displayWidth / scaleX - getX(_itemCount);
      }
    }
    return x >= 0 ? 0 : x;
  }

  double getRealTimePriceMaxWidth() =>
      (_translateX.abs() + _marginRight - getMinTranslateX().abs() + ChartStyle.pointWidth) *
      _scaleX;

  double getX(int index) =>
      index * ChartStyle.pointWidth +
      ChartStyle.pointWidth / 2 +
      _displayWidth / ChartStyle.gridColumns;

  double getStartX() => _startIndex * ChartStyle.pointWidth;

  double getStopX() => _stopIndex * ChartStyle.pointWidth + ChartStyle.pointWidth;

  int getSelectedXIndex() {
    var selectedIndex = indexOfTranslateX(xToTranslateX(_selectX));
    if (selectedIndex < _startIndex) selectedIndex = _startIndex;
    if (selectedIndex > _stopIndex) selectedIndex = _stopIndex;
    return selectedIndex;
  }

  double translateXtoX(int index) => (getX(index) + _translateX) * _scaleX;

  void updateAllKLineData(List<KLineModel> models) {
    _models.clear();
    _models.addAll(models);
    DataUtil.calculate(_models);
    _resetData();
    _calculateDataLength();
    _calculateDateFormat();
  }

  void updateKLineCandle(KLineModel model) {
    if (_models.isEmpty) return;
    if (_models.last.openTime == model.openTime) {
      _models.last.updateValue(model);
    } else if (model.openTime > _models.last.openTime) {
      addKLineData(model);
    }
  }

  void updateLastKLineData() {
    DataUtil.updateLastData(_models);
  }

  void updatePositionList(List<KLineTradeInfo> infoList) {
    _positionList.clear();
    _positionList.addAll(infoList);
  }

  void updateOrderList(List<KLineTradeInfo> infoList) {
    _orderList.clear();
    _orderList.addAll(infoList);
  }

  void addKLineData(KLineModel model) {
    _models.add(model);
    DataUtil.updateLastData(_models);
    _calculateDataLength();
  }

  void addMoreKLineData(List<KLineModel> models) {
    _models.insertAll(0, models);
    DataUtil.calculate(_models);
    _selectX = 0;
    _selectY = 0;
    isLongPress = false;
    _resetMainMaxMinValue();
    _resetSubMaxMinValue();
    _calculateDataLength();
    _calculateDateFormat();
  }

  void _resetData() {
    maxScrollX = 0;
    _scaleX = 1;
    _lastScaleX = 1;
    _scrollX = 0;
    _selectX = 0;
    _selectY = 0;
    isLongPress = false;
    _resetMainMaxMinValue();
    _resetSubMaxMinValue();
  }

  KLineModel getKLineItem(int position) => _models[position];

  KLineModel getLastKLineItem() => _models.last;

  bool isKLineDataEmpty() => _models.isEmpty;

  void _calculateDataLength() {
    _itemCount = _models.length;
  }

  void _calculateDateFormat() {
    if (_itemCount < 2) return;
    final firstTime = _models[0].openTime;
    final secondTime = _models[1].openTime;
    final time = secondTime - firstTime;
    if (time >= Duration.millisecondsPerDay * 28) {
      _timeFormats = 'yy-MM';
    } else if (time >= Duration.millisecondsPerDay * 7) {
      _timeFormats = 'yy-MM-dd';
    } else if (time >= Duration.millisecondsPerDay) {
      _timeFormats = 'MM-dd';
    } else if (time >= Duration.millisecondsPerHour) {
      _timeFormats = 'MM-dd HH:mm';
    } else {
      _timeFormats = 'HH:mm';
    }
  }

  String formatCrossLineTime(int time) {
    final date = DateTime.fromMillisecondsSinceEpoch(time);
    var formats = _timeFormats;
    if (!formats.contains('HH:mm')) {
      if (date.year == DateTime.now().year) {
        formats = 'MM-dd';
      } else {
        formats = 'yyyy-MM-dd';
      }
    }
    return DateFormat(formats).format(date);
  }

  String getDate(int date) =>
      DateFormat(_timeFormats).format(DateTime.fromMillisecondsSinceEpoch(date));
}
