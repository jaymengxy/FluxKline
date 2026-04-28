import 'package:flux_kline/src/model/boll.dart';
import 'package:flux_kline/src/model/candle.dart';
import 'package:flux_kline/src/model/kdj.dart';
import 'package:flux_kline/src/model/ma.dart';
import 'package:flux_kline/src/model/macd.dart';
import 'package:flux_kline/src/model/rsi.dart';
import 'package:flux_kline/src/model/volume.dart';
import 'package:flux_kline/src/model/wr.dart';

class KLineModel
    with MAModel, BollModel, CandleModel, VolumeModel, KDJModel, MACDModel, RSIModel, WRModel {
  KLineModel.fromJson(Map<String, dynamic> json) {
    open = double.parse(json['o']! as String);
    high = double.parse(json['h']! as String);
    low = double.parse(json['l']! as String);
    close = double.parse(json['c']! as String);
    vol = double.parse(json['v']! as String);
    openTime = json['t'] as int;
  }

  KLineModel.fromWSJson(Map<String, dynamic> json) {
    open = double.parse(json['open']! as String);
    high = double.parse(json['high']! as String);
    low = double.parse(json['low']! as String);
    close = double.parse(json['close']! as String);
    vol = double.parse(json['volume']! as String);
    openTime = json['start'] as int;
  }

  KLineModel({
    required this.openTime,
    required double openPrice,
    required double highPrice,
    required double lowPrice,
    required double closePrice,
    required double volume,
  }) {
    open = openPrice;
    high = highPrice;
    low = lowPrice;
    close = closePrice;
    vol = volume;
  }

  late int openTime;

  void updateValue(KLineModel model) {
    open = model.open;
    high = model.high;
    low = model.low;
    close = model.close;
    vol = model.vol;
    openTime = model.openTime;
  }
}
