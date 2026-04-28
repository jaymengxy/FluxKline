import 'package:flutter/material.dart';
import 'package:flux_kline/flux_kline.dart';
import '../data/mock_data.dart';

class BasicKLinePage extends StatefulWidget {
  const BasicKLinePage({super.key});

  @override
  State<BasicKLinePage> createState() => _BasicKLinePageState();
}

class _BasicKLinePageState extends State<BasicKLinePage> {
  final _controller = KLineController();
  late final SettingConfig _config;

  @override
  void initState() {
    super.initState();
    _config = SettingConfig(
      theme: FluxKlineTheme.dark(),
      tickSize: 2,
      titleList: ['Time', 'Open', 'High', 'Low', 'Close', 'Change', 'Change%'],
    );
    _controller.updateAllKLineData(MockData.generateKLineData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131722),
      appBar: AppBar(
        title: const Text('Basic K-Line'),
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
