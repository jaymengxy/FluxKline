import 'package:flutter/material.dart';
import 'package:flux_kline/flux_kline.dart';
import '../data/mock_data.dart';

class TrendChartPage extends StatefulWidget {
  const TrendChartPage({super.key});

  @override
  State<TrendChartPage> createState() => _TrendChartPageState();
}

class _TrendChartPageState extends State<TrendChartPage> {
  final _controller = TrendChartController();
  late final TrendChartConfig _config;

  @override
  void initState() {
    super.initState();
    _config = TrendChartConfig(theme: FluxKlineTheme.dark());
    _controller.updateTrendChartData(MockData.generateTrendData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131722),
      appBar: AppBar(
        title: const Text('Trend Chart'),
        backgroundColor: const Color(0xFF1E222D),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 300,
            child: FluxTrendChart(
              chartController: _controller,
              chartConfig: _config,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Tap or long-press to see crosshair',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
