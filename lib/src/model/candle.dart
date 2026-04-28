import 'package:flux_kline/src/model/boll.dart';
import 'package:flux_kline/src/model/ma.dart';

mixin CandleModel on MAModel, BollModel {
  late double open;
  late double close;
  late double high;
  late double low;
}
