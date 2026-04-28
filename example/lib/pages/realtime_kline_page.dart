import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flux_kline/flux_kline.dart';
import '../data/mock_data.dart';

/// Demonstrates how to integrate with a real-time data source (e.g. WebSocket).
///
/// In production, you would replace the Timer with a StreamSubscription
/// listening to your WebSocket candle stream. See the pattern:
///
/// ```dart
/// StreamSubscription<CandleData>? _candleSub;
/// _candleSub = wsClient.candleStream().listen((candle) {
///   controller.updateKLineCandle(KLineModel.fromWSJson(candle.toJson()));
///   controller.updateLastKLineData();
///   setState(() {});
/// });
/// ```
class RealtimeKLinePage extends StatefulWidget {
  const RealtimeKLinePage({super.key});

  @override
  State<RealtimeKLinePage> createState() => _RealtimeKLinePageState();
}

class _RealtimeKLinePageState extends State<RealtimeKLinePage> {
  final _controller = KLineController();
  late final SettingConfig _config;
  Timer? _timer;
  final _random = Random();
  int _updateCount = 0;

  @override
  void initState() {
    super.initState();
    _config = SettingConfig(
      theme: FluxKlineTheme.dark(),
      tickSize: 2,
      titleList: ['Time', 'Open', 'High', 'Low', 'Close', 'Change', 'Change%'],
    );

    // Load initial K-line data (like REST API fetch)
    _controller.updateAllKLineData(MockData.generateKLineData());

    // Set up onLoadMore callback for infinite scroll
    _controller.onLoadMore = _onLoadMore;

    // Simulate WebSocket stream
    _startRealtimeUpdates();

    // Add mock trade overlay
    _updateTradeInfo();
  }

  void _onLoadMore() {
    // In production: fetch older historical data from REST API
    // then call controller.addMoreKLineData(olderModels);
    debugPrint('Load more triggered - fetch older candles here');
  }

  void _startRealtimeUpdates() {
    // Simulate WebSocket candle push every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final last = _controller.getLastKLineItem();
      final change = (_random.nextDouble() - 0.5) * last.close * 0.002;
      final newClose = last.close + change;
      _updateCount++;

      // Every 60 ticks, simulate a new candle (new time period)
      final openTime = _updateCount % 60 == 0
          ? last.openTime + Duration.millisecondsPerHour
          : last.openTime;

      final model = KLineModel(
        openTime: openTime,
        openPrice: _updateCount % 60 == 0 ? last.close : last.open,
        highPrice: max(last.high, newClose),
        lowPrice: min(last.low, newClose),
        closePrice: newClose,
        volume: _updateCount % 60 == 0
            ? _random.nextDouble() * 100
            : last.vol + _random.nextDouble() * 10,
      );

      // This is the key pattern: updateKLineCandle handles both
      // updating the current candle and adding a new one
      _controller.updateKLineCandle(model);
      _controller.updateLastKLineData();
      setState(() {});
    });
  }

  void _updateTradeInfo() {
    final last = _controller.getLastKLineItem();
    // Simulate position overlay
    _controller.updatePositionList([
      KLineTradeInfo(
        info: 'Long +128.50',
        amount: '0.5 BTC',
        price: last.close * 0.98,
        isPositive: true,
      ),
    ]);
    // Simulate order overlay
    _controller.updateOrderList([
      KLineTradeInfo(
        info: 'Limit',
        amount: '1.0 BTC',
        price: last.close * 0.95,
        isPositive: true,
      ),
      KLineTradeInfo(
        info: 'Limit',
        amount: '0.3 BTC',
        price: last.close * 1.03,
        isPositive: false,
      ),
    ]);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131722),
      appBar: AppBar(
        title: const Text('Realtime + Trade Overlay'),
        backgroundColor: const Color(0xFF1E222D),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 400,
            child: KLineChart(
              kLineController: _controller,
              settingConfig: _config,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Simulated WebSocket: candle updates every 1s',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Position & order lines are overlaid on the chart',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Scroll to the left edge to trigger onLoadMore',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
