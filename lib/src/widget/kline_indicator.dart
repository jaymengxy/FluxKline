import 'package:flux_kline/src/common/constant.dart';
import 'package:flux_kline/src/config/settings_config.dart';
import 'package:flutter/material.dart';

class KLineIndicator extends StatefulWidget {
  const KLineIndicator({
    super.key,
    required this.onIndicatorSelected,
    required this.settingConfig,
  });

  final ValueChanged<MainChartIndicator> onIndicatorSelected;
  final SettingConfig settingConfig;

  @override
  State<StatefulWidget> createState() => _KLineIndicator();
}

class _KLineIndicator extends State<KLineIndicator> {
  final Set<MainChartIndicator> _indicatorSet = {};

  @override
  Widget build(BuildContext context) {
    final indicators = MainChartIndicator.indicators;
    final config = widget.settingConfig;
    return SizedBox(
      height: 40,
      child: Row(
        children: indicators.map(
          (indicator) {
            final isSelected = _indicatorSet.contains(indicator);
            return InkWell(
              onTap: () {
                _onIndicatorSelected(indicator);
              },
              child: Container(
                height: 20,
                margin: const EdgeInsets.only(top: 10, bottom: 10, left: 14),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? config.selectedIndicatorColor
                        : config.unselectedIndicatorBorderColor,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  indicator.displayValue,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: isSelected
                        ? config.selectedIndicatorColor
                        : config.unselectedIndicatorTextColor,
                  ),
                ),
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  void _onIndicatorSelected(MainChartIndicator indicator) {
    widget.onIndicatorSelected(indicator);
    if (_indicatorSet.contains(indicator)) {
      _indicatorSet.remove(indicator);
    } else {
      _indicatorSet.add(indicator);
    }
    setState(() {});
  }
}
