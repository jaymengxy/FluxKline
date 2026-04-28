# flux_kline

[![pub package](https://img.shields.io/pub/v/flux_kline.svg)](https://pub.dev/packages/flux_kline)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A high-performance, real-time K-line (candlestick) chart widget for Flutter, with 6 built-in technical indicators.

## Features

- Candlestick chart with smooth pan, pinch-to-zoom, and crosshair
- **6 technical indicators**: MA, BOLL, MACD, KDJ, RSI, WR
- Up to 2 sub-charts displayed simultaneously
- Real-time price line with auto-scroll-to-latest
- Trade overlay: draw position & order price lines on chart
- Load-more callback for infinite scroll with historical data
- Mini K-line sparkline widget
- Trend chart widget
- Fully customizable theming via `FluxKlineTheme`
- Zero platform-specific code — pure Dart/Flutter

## Quick Start

```yaml
dependencies:
  flux_kline: ^0.1.0
```

```dart
import 'package:flux_kline/flux_kline.dart';

// 1. Create controller & config
final controller = KLineController();
final config = SettingConfig(
  theme: FluxKlineTheme.dark(),
  tickSize: 2,
  titleList: ['Time', 'Open', 'High', 'Low', 'Close', 'Change', 'Change%'],
);

// 2. Load data
controller.updateAllKLineData(klineModels);

// 3. Use in widget tree
SizedBox(
  height: 400,
  child: KLineChart(
    kLineController: controller,
    settingConfig: config,
  ),
)
```

## Data Integration

### Loading Initial Data

`KLineModel` supports multiple JSON formats:

```dart
// REST API format: { "o": "40000", "h": "41000", "l": "39000", "c": "40500", "v": "100", "t": 1700000000000 }
final model = KLineModel.fromJson(json);

// WebSocket format: { "open": "40000", "high": "41000", "low": "39000", "close": "40500", "volume": "100", "start": 1700000000000 }
final model = KLineModel.fromWSJson(wsJson);

// Manual construction
final model = KLineModel(
  openTime: DateTime.now().millisecondsSinceEpoch,
  openPrice: 40000,
  highPrice: 41000,
  lowPrice: 39000,
  closePrice: 40500,
  volume: 100,
);
```

### Real-time WebSocket Updates

The typical pattern is to wrap `KLineChart` in a StatefulWidget that manages stream subscriptions:

```dart
class KLineWSChart extends StatefulWidget {
  const KLineWSChart({required this.controller, required this.config, super.key});
  final KLineController controller;
  final SettingConfig config;

  @override
  State<KLineWSChart> createState() => _KLineWSChartState();
}

class _KLineWSChartState extends State<KLineWSChart> {
  StreamSubscription? _candleSub;
  StreamSubscription? _loadMoreSub;

  @override
  void initState() {
    super.initState();
    // Subscribe to WebSocket candle stream
    _candleSub = wsClient.candleStream().listen((candle) {
      widget.controller.updateKLineCandle(KLineModel.fromWSJson(candle.toJson()));
      widget.controller.updateLastKLineData();
      setState(() {});
    });

    // Subscribe to load-more response stream
    _loadMoreSub = wsClient.historyStream().listen((list) {
      final models = list.map((e) => KLineModel.fromJson(e.toJson())).toList();
      models.sort((a, b) => a.openTime.compareTo(b.openTime));
      widget.controller.addMoreKLineData(models);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _candleSub?.cancel();
    _loadMoreSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KLineChart(
      kLineController: widget.controller
        ..onLoadMore = () {
          wsClient.loadMoreHistory();
        },
      settingConfig: widget.config,
    );
  }
}
```

### Load More (Infinite Scroll)

When the user scrolls to the left edge, `onLoadMore` fires:

```dart
controller.onLoadMore = () {
  // Fetch older historical data from your API
  api.fetchHistory(before: controller.getKLineItem(0).openTime).then((list) {
    controller.addMoreKLineData(list);
    setState(() {});
  });
};
```

## Configuration

### FluxKlineTheme

Use `FluxKlineTheme.dark()` or `FluxKlineTheme.light()` for presets, or create your own:

```dart
FluxKlineTheme(
  upColor: Colors.green,
  downColor: Colors.red,
  backgroundColor: Colors.black,
  // ... see FluxKlineTheme for all options
)
```

### SettingConfig

| Property | Type | Description |
|----------|------|-------------|
| `theme` | `FluxKlineTheme` | Color theme |
| `tickSize` | `int` | Decimal places for price display |
| `titleList` | `List<String>` | Info window labels (shown on long-press) |
| `isTrade` | `bool` | Trade mode (simplified horizontal-only gestures, hides overlays) |

## Technical Indicators

| Indicator | Type | Description |
|-----------|------|-------------|
| MA | Main | Moving Average (5, 10, 20) |
| BOLL | Main | Bollinger Bands (20, 2) |
| MACD | Sub | Moving Average Convergence Divergence (12, 26, 9) |
| KDJ | Sub | Stochastic Oscillator (9, 3, 3) |
| RSI | Sub | Relative Strength Index (6, 12, 24) |
| WR | Sub | Williams %R (14, 20) |

Toggle indicators programmatically:

```dart
// Main chart indicators
controller.showMainChartIndicator(MainChartIndicator.ma);

// Sub chart (up to 2 simultaneous)
controller.changeSubChartType(SubChartType.macd);
controller.changeSubChartType(SubChartType.volume);
```

Or use the built-in selector widgets:

```dart
KLineIndicator(
  settingConfig: config,
  onIndicatorSelected: (indicator) {
    controller.showMainChartIndicator(indicator);
    setState(() {});
  },
)

KLineSubChart(
  settingConfig: config,
  onChartTypeChanged: (type) {
    controller.changeSubChartType(type);
    setState(() {});
  },
)
```

## Trade Overlay

Draw position and order lines directly on the chart:

```dart
// Show active positions
controller.updatePositionList([
  KLineTradeInfo(
    info: 'Long +128.50',     // Label text (left side)
    amount: '0.5 BTC',        // Amount text (right side)
    price: 42000.0,           // Price level to draw line
    isPositive: true,         // true = up color, false = down color
  ),
]);

// Show pending orders
controller.updateOrderList([
  KLineTradeInfo(
    info: 'Limit',
    amount: '1.0 BTC',
    price: 41000.0,
    isPositive: true,
  ),
]);
```

> Note: Trade overlay is hidden when `isTrade: true` in SettingConfig.

## Trend Chart

A separate lightweight line chart for price trends:

```dart
final trendController = TrendChartController();
trendController.updateTrendChartData(trendItems);

FluxTrendChart(
  chartController: trendController,
  chartConfig: TrendChartConfig(theme: FluxKlineTheme.dark()),
)
```

## Mini Sparkline

A simple sparkline painter for use in lists or compact views:

```dart
CustomPaint(
  size: const Size(60, 24),
  painter: MiniKLinePainter(
    data: closePrices, // List<double>
    color: Colors.green,
  ),
)
```

## License

[MIT](https://github.com/jaymengxy/FluxKline/blob/main/LICENSE)
