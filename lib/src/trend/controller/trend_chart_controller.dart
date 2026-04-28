import 'dart:math';
import 'dart:ui';

import 'package:flux_kline/src/trend/config/trend_chart_config.dart';
import 'package:flux_kline/src/trend/model/trend_item.dart';
import 'package:intl/intl.dart';

class TrendChartController {
  final List<TrendItem> _list = <TrendItem>[];

  int _itemCount = 0;

  double _pointBetween = 1;
  double _selectX = 0;

  bool isSelected = false;

  int _startIndex = 0;
  int _stopIndex = 0;

  late double _displayWidth;
  late double _displayHeight;

  String _timeFormats = 'MM-dd HH:mm';

  double _maxYAxis = -double.maxFinite;
  double _minYAxis = double.maxFinite;

  double get pointBetween => _pointBetween;
  double get selectX => _selectX;
  int get startIndex => _startIndex;
  int get stopIndex => _stopIndex;
  int get itemCount => _itemCount;
  double get displayWidth => _displayWidth;
  double get displayHeight => _displayHeight;
  double get maxYAxis => _maxYAxis;
  double get minYAxis => _minYAxis;

  void calculateDisplay(Size size) {
    _displayWidth = size.width;
    _displayHeight = size.height - TrendChartConfig.topPadding - TrendChartConfig.marginBottom;
  }

  void calculateValue() {
    if (_list.isEmpty) return;
    _pointBetween = (_displayWidth - TrendChartConfig.leftPadding - TrendChartConfig.rightPadding) /
        (_itemCount - 1);
    _startIndex = 0;
    _stopIndex = _itemCount - 1;
    _resetMaxMinValue();
    for (var i = _startIndex; i <= _stopIndex; i++) {
      _getMaxMinValue(getTrendItem(i));
    }
  }

  void updateTrendChartData(List<TrendItem> list) {
    _list.clear();
    _list.addAll(list);
    _selectX = 0;
    isSelected = false;
    _itemCount = list.length;
    _calculateDateFormat();
  }

  void _getMaxMinValue(TrendItem item) {
    _maxYAxis = max(
      _maxYAxis,
      double.parse(item.price.toStringAsFixed(TrendChartConfig.tickSize)),
    );
    _minYAxis = min(
      _minYAxis,
      double.parse(item.price.toStringAsFixed(TrendChartConfig.tickSize)),
    );
  }

  void _resetMaxMinValue() {
    _maxYAxis = -double.maxFinite;
    _minYAxis = double.maxFinite;
  }

  void _calculateDateFormat() {
    if (_itemCount < 2) return;
    final firstTime = _list[0].time;
    final secondTime = _list[1].time;
    final time = secondTime - firstTime;
    if (time >= Duration.millisecondsPerDay * 28) {
      _timeFormats = 'yy-MM';
    } else if (time >= Duration.millisecondsPerDay * 7) {
      _timeFormats = 'MM-dd';
    } else if (time >= Duration.millisecondsPerDay) {
      _timeFormats = 'MM-dd';
    } else if (time >= Duration.millisecondsPerHour) {
      _timeFormats = 'MM-dd';
    } else {
      _timeFormats = 'HH:mm';
    }
  }

  String formatSelectedTime(int time) {
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

  double getX(int index) => index * _pointBetween + TrendChartConfig.leftPadding;

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

  bool isSelectX(double dx) {
    if (_selectX != dx) {
      _selectX = dx;
      return true;
    }
    return false;
  }

  int getSelectedXIndex() {
    return indexOfTranslateX(_selectX).clamp(_startIndex, _stopIndex);
  }

  TrendItem getTrendItem(int position) => _list[position];
}
