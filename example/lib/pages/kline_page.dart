import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flux_kline/flux_kline.dart';

import '../data/mock_data.dart';

/// Demonstrates indicators and real-time candle updates on one K-line chart.
///
/// In production, replace the timer with a subscription to a WebSocket candle
/// stream and pass each candle to [KLineController.updateKLineCandle].
class KLinePage extends StatefulWidget {
  const KLinePage({super.key});

  @override
  State<KLinePage> createState() => _KLinePageState();
}

class _KLinePageState extends State<KLinePage> {
  final _controller = KLineController();
  final _random = Random();
  late final SettingConfig _config;
  Timer? _timer;
  int _updateCount = 0;

  @override
  void initState() {
    super.initState();
    _config = SettingConfig(
      theme: FluxKlineTheme.dark(),
      tickSize: 2,
      titleList: ['Time', 'Open', 'High', 'Low', 'Close', 'Change', 'Change%'],
    );
    _controller
      ..updateAllKLineData(MockData.generateKLineData())
      ..onLoadMore = _onLoadMore;
    _updateTradeInfo();
    _startRealtimeUpdates();
  }

  void _onLoadMore() {
    debugPrint('Load more triggered - fetch older candles here');
  }

  void _startRealtimeUpdates() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final last = _controller.getLastKLineItem();
      final isNewCandle = ++_updateCount % 60 == 0;
      final change = (_random.nextDouble() - 0.5) * last.close * 0.002;
      final newClose = last.close + change;

      final model = KLineModel(
        openTime:
            isNewCandle
                ? last.openTime + Duration.millisecondsPerHour
                : last.openTime,
        openPrice: isNewCandle ? last.close : last.open,
        highPrice: max(last.high, newClose),
        lowPrice: min(last.low, newClose),
        closePrice: newClose,
        volume:
            isNewCandle
                ? _random.nextDouble() * 100
                : last.vol + _random.nextDouble() * 10,
      );

      _controller
        ..updateKLineCandle(model)
        ..updateLastKLineData();
      setState(() {});
    });
  }

  void _updateTradeInfo() {
    final last = _controller.getLastKLineItem();
    _controller
      ..updatePositionList([
        KLineTradeInfo(
          info: 'Long +128.50',
          amount: '0.5 BTC',
          price: last.close * 0.98,
          isPositive: true,
        ),
      ])
      ..updateOrderList([
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
        title: const Text('K-Line'),
        backgroundColor: const Color(0xFF1E222D),
      ),
      body: Column(
        children: [
          Expanded(
            child: KLineChart(
              kLineController: _controller,
              settingConfig: _config,
            ),
          ),
          KLineIndicator(
            settingConfig: _config,
            onIndicatorSelected: (indicator) {
              _controller.showMainChartIndicator(indicator);
              setState(() {});
            },
          ),
          KLineSubChart(
            settingConfig: _config,
            onChartTypeChanged: (type) {
              _controller.changeSubChartType(type);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
