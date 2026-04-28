import 'dart:math';
import 'package:flux_kline/flux_kline.dart';

class MockData {
  static List<KLineModel> generateKLineData({
    int count = 500,
    double startPrice = 40000,
    int intervalMs = Duration.millisecondsPerHour,
  }) {
    final random = Random(42);
    final list = <KLineModel>[];
    var price = startPrice;
    final now = DateTime.now().millisecondsSinceEpoch;
    final startTime = now - count * intervalMs;

    for (var i = 0; i < count; i++) {
      final change = (random.nextDouble() - 0.48) * price * 0.03;
      final open = price;
      final close = price + change;
      final high = max(open, close) + random.nextDouble() * price * 0.01;
      final low = min(open, close) - random.nextDouble() * price * 0.01;
      final vol = 100 + random.nextDouble() * 900;

      list.add(KLineModel(
        openTime: startTime + i * intervalMs,
        openPrice: open,
        highPrice: high,
        lowPrice: low,
        closePrice: close,
        volume: vol,
      ));

      price = close;
    }
    return list;
  }

  static List<TrendItem> generateTrendData({
    int count = 100,
    double startPrice = 40000,
    int intervalMs = Duration.millisecondsPerHour,
  }) {
    final random = Random(42);
    final list = <TrendItem>[];
    var price = startPrice;
    final now = DateTime.now().millisecondsSinceEpoch;
    final startTime = now - count * intervalMs;

    for (var i = 0; i < count; i++) {
      price += (random.nextDouble() - 0.48) * price * 0.005;
      list.add(TrendItem(
        price: price,
        time: startTime + i * intervalMs,
      ));
    }
    return list;
  }
}
