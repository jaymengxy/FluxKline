import 'dart:math';

import 'package:flux_kline/src/common/constant.dart';
import 'package:flux_kline/src/model/kline.dart';

class SubChartModel {
  SubChartType _chartType = SubChartType.none;
  double _maxValue = -double.maxFinite;
  double _minValue = double.maxFinite;

  SubChartType get chartType => _chartType;

  double get maxValue => _maxValue;

  double get minValue => _minValue;

  void changeChartType(SubChartType type) {
    _chartType = type;
    resetMaxMinValue();
  }

  bool isValidChart() {
    return _chartType != SubChartType.none;
  }

  void resetMaxMinValue() {
    _maxValue = -double.maxFinite;
    _minValue = double.maxFinite;
  }

  void getSubMaxMinValue(KLineModel item) {
    switch (_chartType) {
      case SubChartType.volume:
        _maxValue = max(_maxValue, max(item.vol, max(item.ma5Volume, item.ma10Volume)));
        _minValue = min(_minValue, min(item.vol, min(item.ma5Volume, item.ma10Volume)));
        break;
      case SubChartType.macd:
        _maxValue = max(_maxValue, max(item.macd, max(item.dif, item.dea)));
        _minValue = min(_minValue, min(item.macd, min(item.dif, item.dea)));
        break;
      case SubChartType.kdj:
        _maxValue = max(_maxValue, max(item.k, max(item.d, item.j)));
        _minValue = min(_minValue, min(item.k, min(item.d, item.j)));
        break;
      case SubChartType.rsi:
        _maxValue = max(_maxValue, max(item.rsi6, max(item.rsi12, item.rsi24)));
        _minValue = min(_minValue, min(item.rsi6, min(item.rsi12, item.rsi24)));
        break;
      case SubChartType.wr:
        _maxValue = max(_maxValue, max(item.wr14, item.wr20));
        _minValue = min(_minValue, min(item.wr14, item.wr20));
        break;
      default:
        break;
    }
  }
}
