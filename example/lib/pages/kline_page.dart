import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flux_kline/flux_kline.dart';

import '../data/mock_data.dart';

const _background = Color(0xFF111111);
const _dialog = Color(0xFF1F1F1F);
const _card = Color(0x1FFFFFFF);
const _divider = Color(0x40FFFFFF);
const _primaryText = Colors.white;
const _secondaryText = Color(0xA6FFFFFF);
const _tertiaryText = Color(0x73FFFFFF);
const _brand = Color(0xFFFED702);
const _up = Color(0xFF79D900);
const _down = Color(0xFFFF007A);

const _fluxKlineChartTheme = FluxKlineTheme(
  upColor: _up,
  downColor: _down,
  backgroundColor: _background,
  dialogColor: _dialog,
  cardColor: _card,
  primaryTextColor: _primaryText,
  secondaryTextColor: _secondaryText,
  tertiaryTextColor: _tertiaryText,
  titleTextColor: Color(0xD9FFFFFF),
  disableTextColor: Color(0x40FFFFFF),
  blackColor: Colors.black,
  dividerColor: _divider,
  brandColor: _brand,
);

enum _ChartInterval {
  timeline('Time', Duration.millisecondsPerMinute),
  oneMinute('1m', Duration.millisecondsPerMinute),
  fiveMinutes('5m', Duration.millisecondsPerMinute * 5),
  fifteenMinutes('15m', Duration.millisecondsPerMinute * 15),
  oneHour('1H', Duration.millisecondsPerHour),
  fourHours('4H', Duration.millisecondsPerHour * 4),
  oneDay('1D', Duration.millisecondsPerDay),
  oneWeek('1W', Duration.millisecondsPerDay * 7),
  oneMonth('1M', Duration.millisecondsPerDay * 30);

  const _ChartInterval(this.label, this.milliseconds);

  final String label;
  final int milliseconds;
}

/// Demonstrates a complete market-detail K-line integration.
///
/// Replace [_replaceCandles], [_updateRealtimeCandle], and [_loadOlderCandles]
/// with REST/WebSocket callbacks in an application. The chart-facing API stays
/// the same: one [KLineController] receives full, real-time, and older data.
class KLinePage extends StatefulWidget {
  const KLinePage({super.key});

  @override
  State<KLinePage> createState() => _KLinePageState();
}

class _KLinePageState extends State<KLinePage> {
  static const _primaryIntervals = [
    _ChartInterval.timeline,
    _ChartInterval.oneMinute,
    _ChartInterval.fiveMinutes,
    _ChartInterval.fifteenMinutes,
    _ChartInterval.oneHour,
  ];

  final _controller = KLineController();
  final _random = Random();
  late final SettingConfig _config;
  Timer? _realtimeTimer;
  _ChartInterval _interval = _ChartInterval.oneHour;
  bool _isLoadingHistory = false;
  int _updateCount = 0;

  @override
  void initState() {
    super.initState();
    _config = SettingConfig(
      theme: _fluxKlineChartTheme,
      tickSize: 2,
      titleList: const [
        'Time',
        'Open',
        'High',
        'Low',
        'Close',
        'Change',
        'Change%',
      ],
    );
    _controller.onLoadMore = _loadOlderCandles;
    _replaceCandles(_interval);
    _updateTradeInfo();
    _startRealtimeUpdates();
  }

  void _replaceCandles(_ChartInterval interval) {
    final candles = MockData.generateKLineData(
      count: 300,
      startPrice: 41120,
      intervalMs: interval.milliseconds,
    )..sort((a, b) => a.openTime.compareTo(b.openTime));
    _controller
      ..updateAllKLineData(candles)
      ..isTimeLine = interval == _ChartInterval.timeline;
  }

  Future<void> _loadOlderCandles() async {
    if (_isLoadingHistory || _controller.isKLineDataEmpty()) return;
    _isLoadingHistory = true;
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    final first = _controller.getKLineItem(0);
    final older = MockData.generateKLineData(
      count: 100,
      startPrice: first.open,
      intervalMs: _interval.milliseconds,
      endTime: first.openTime - _interval.milliseconds,
    )..sort((a, b) => a.openTime.compareTo(b.openTime));
    _controller.addMoreKLineData(older);
    _isLoadingHistory = false;
    setState(() {});
  }

  void _startRealtimeUpdates() {
    _realtimeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_controller.isKLineDataEmpty()) return;
      final last = _controller.getLastKLineItem();
      final isNewCandle = ++_updateCount % 12 == 0;
      final change = (_random.nextDouble() - 0.5) * last.close * 0.0015;
      final close = last.close + change;
      final open = isNewCandle ? last.close : last.open;

      _updateRealtimeCandle(
        KLineModel(
          openTime:
              isNewCandle
                  ? last.openTime + _interval.milliseconds
                  : last.openTime,
          openPrice: open,
          highPrice: isNewCandle ? max(open, close) : max(last.high, close),
          lowPrice: isNewCandle ? min(open, close) : min(last.low, close),
          closePrice: close,
          volume:
              isNewCandle
                  ? 10 + _random.nextDouble() * 30
                  : last.vol + _random.nextDouble() * 8,
        ),
      );
    });
  }

  void _updateRealtimeCandle(KLineModel candle) {
    _controller
      ..updateKLineCandle(candle)
      ..updateLastKLineData();
    if (mounted) setState(() {});
  }

  void _updateTradeInfo() {
    final last = _controller.getLastKLineItem();
    _controller
      ..updatePositionList([
        KLineTradeInfo(
          info: 'Position +128.50',
          amount: '0.50 BTC',
          price: last.close * 0.98,
          isPositive: true,
        ),
      ])
      ..updateOrderList([
        KLineTradeInfo(
          info: 'Limit Order',
          amount: '1.00 BTC',
          price: last.close * 0.95,
          isPositive: true,
        ),
        KLineTradeInfo(
          info: 'Limit Order',
          amount: '0.30 BTC',
          price: last.close * 1.03,
          isPositive: false,
        ),
      ]);
  }

  void _selectInterval(_ChartInterval interval) {
    if (_interval == interval) return;
    setState(() {
      _interval = interval;
      _updateCount = 0;
      _replaceCandles(interval);
      _updateTradeInfo();
    });
  }

  Future<void> _showMoreIntervals() async {
    final selected = await showModalBottomSheet<_ChartInterval>(
      context: context,
      backgroundColor: _dialog,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chart interval',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.1,
                  physics: const NeverScrollableScrollPhysics(),
                  children:
                      _ChartInterval.values.map((interval) {
                        final isSelected = interval == _interval;
                        return InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: () => Navigator.pop(context, interval),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? _brand.withValues(alpha: 0.12)
                                      : _card,
                              borderRadius: BorderRadius.circular(4),
                              border:
                                  isSelected ? Border.all(color: _brand) : null,
                            ),
                            child: Center(
                              child: Text(
                                interval.label,
                                style: TextStyle(
                                  color: isSelected ? _brand : _secondaryText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (selected != null) _selectInterval(selected);
  }

  @override
  void dispose() {
    _realtimeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _controller.getLastKLineItem();
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        centerTitle: true,
        titleSpacing: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _divider),
                color: _dialog,
              ),
              child: const Icon(Icons.swap_horiz, size: 16),
            ),
            const SizedBox(width: 8),
            const Text(
              'BTC-USDC',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            Container(
              height: 20,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                border: Border.all(color: _up),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.arrow_upward, size: 10, color: _up),
                  SizedBox(width: 2),
                  Text('+2.42%', style: TextStyle(fontSize: 10, color: _up)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _MarketSummary(price: last.close),
                    _IntervalBar(
                      selected: _interval,
                      primaryIntervals: _primaryIntervals,
                      onSelected: _selectInterval,
                      onMore: _showMoreIntervals,
                    ),
                    SizedBox(
                      height: 342,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const IgnorePointer(
                            child: Opacity(
                              opacity: 0.08,
                              child: Text(
                                'FLUX',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 8,
                                ),
                              ),
                            ),
                          ),
                          KLineChart(
                            kLineController: _controller,
                            settingConfig: _config,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    DecoratedBox(
                      decoration: const BoxDecoration(
                        border: Border.symmetric(
                          horizontal: BorderSide(color: _divider),
                        ),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
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
                      ),
                    ),
                    const _MarketTabs(),
                  ],
                ),
              ),
            ),
            const _TradeActions(),
          ],
        ),
      ),
    );
  }
}

class _MarketSummary extends StatelessWidget {
  const _MarketSummary({required this.price});

  final double price;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: _card)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  price.toStringAsFixed(2),
                  style: const TextStyle(
                    color: _primaryText,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PriceLabel(
                      label: 'Oracle Price',
                      value: '41,236.42',
                      accent: true,
                    ),
                    SizedBox(height: 6),
                    _PriceLabel(label: 'Index Price', value: '41,241.08'),
                  ],
                ),
              ],
            ),
          ),
          const _StatLabels(),
          const SizedBox(width: 16),
          const _StatValues(),
        ],
      ),
    );
  }
}

class _PriceLabel extends StatelessWidget {
  const _PriceLabel({
    required this.label,
    required this.value,
    this.accent = false,
  });

  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: _secondaryText, fontSize: 10),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: accent ? _brand : _primaryText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StatLabels extends StatelessWidget {
  const _StatLabels();

  @override
  Widget build(BuildContext context) {
    return const _StatColumn(
      alignment: CrossAxisAlignment.start,
      color: _secondaryText,
      values: ['24h High', '24h Low', '24h Turnover', 'Open Interest'],
    );
  }
}

class _StatValues extends StatelessWidget {
  const _StatValues();

  @override
  Widget build(BuildContext context) {
    return const _StatColumn(
      alignment: CrossAxisAlignment.end,
      color: _primaryText,
      values: ['42,190.35', '39,846.20', '128.46M', '52.18M'],
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.alignment,
    required this.color,
    required this.values,
  });

  final CrossAxisAlignment alignment;
  final Color color;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children:
          values
              .map(
                (value) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    value,
                    style: TextStyle(color: color, fontSize: 11),
                  ),
                ),
              )
              .toList(),
    );
  }
}

class _IntervalBar extends StatelessWidget {
  const _IntervalBar({
    required this.selected,
    required this.primaryIntervals,
    required this.onSelected,
    required this.onMore,
  });

  final _ChartInterval selected;
  final List<_ChartInterval> primaryIntervals;
  final ValueChanged<_ChartInterval> onSelected;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final selectedIsMore = !primaryIntervals.contains(selected);
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 14),
              child: Container(
                height: 26,
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: _dialog,
                  border: Border.all(color: _divider),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    ...primaryIntervals.map(
                      (interval) => _IntervalChip(
                        label: interval.label,
                        selected: interval == selected,
                        onTap: () => onSelected(interval),
                      ),
                    ),
                    _IntervalChip(
                      label: selectedIsMore ? selected.label : 'More',
                      selected: selectedIsMore,
                      onTap: onMore,
                      showArrow: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text(
              'Depth',
              style: TextStyle(color: _secondaryText, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntervalChip extends StatelessWidget {
  const _IntervalChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.showArrow = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: selected ? _background : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: selected ? Border.all(color: _secondaryText) : null,
          boxShadow:
              selected
                  ? const [BoxShadow(color: _divider, offset: Offset(0, 1))]
                  : null,
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? _primaryText : _tertiaryText,
                fontSize: 10,
              ),
            ),
            if (showArrow) ...[
              const SizedBox(width: 3),
              const Icon(Icons.arrow_drop_down, color: _tertiaryText, size: 13),
            ],
          ],
        ),
      ),
    );
  }
}

class _MarketTabs extends StatelessWidget {
  const _MarketTabs();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: _brand,
              labelColor: _primaryText,
              unselectedLabelColor: _tertiaryText,
              labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              tabs: [
                Tab(text: 'Order Book'),
                Tab(text: 'Trades'),
                Tab(text: 'Funding Rate'),
              ],
            ),
          ),
          SizedBox(
            height: 190,
            child: TabBarView(
              children: [
                _OrderBook(),
                _PlaceholderPanel(
                  icon: Icons.swap_vert,
                  title: 'Live trades',
                  subtitle: 'Connect your trade stream here.',
                ),
                _PlaceholderPanel(
                  icon: Icons.schedule,
                  title: '0.0100% / 03:24:18',
                  subtitle: 'Estimated funding rate and countdown.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderBook extends StatelessWidget {
  const _OrderBook();

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('41,248.20', '0.183', _down),
      ('41,245.60', '0.427', _down),
      ('41,239.10', '1.052', _up),
      ('41,235.80', '0.764', _up),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Price (USDC)',
                  style: TextStyle(color: _tertiaryText, fontSize: 11),
                ),
              ),
              Text(
                'Size (BTC)',
                style: TextStyle(color: _tertiaryText, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.$1,
                      style: TextStyle(color: row.$3, fontSize: 12),
                    ),
                  ),
                  Text(
                    row.$2,
                    style: const TextStyle(color: _primaryText, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderPanel extends StatelessWidget {
  const _PlaceholderPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _tertiaryText),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(color: _primaryText, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: _tertiaryText, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _TradeActions extends StatelessWidget {
  const _TradeActions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: const BoxDecoration(
        color: _background,
        border: Border(top: BorderSide(color: _divider)),
      ),
      child: const Row(
        children: [
          Expanded(child: _TradeButton(label: 'Buy / Long', color: _up)),
          SizedBox(width: 8),
          Expanded(child: _TradeButton(label: 'Sell / Short', color: _down)),
        ],
      ),
    );
  }
}

class _TradeButton extends StatelessWidget {
  const _TradeButton({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: FilledButton(
        onPressed: () {},
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
