import 'package:flux_kline/src/common/constant.dart';
import 'package:flux_kline/src/config/settings_config.dart';
import 'package:flutter/material.dart';

class KLineSubChart extends StatefulWidget {
  const KLineSubChart({
    super.key,
    required this.onChartTypeChanged,
    required this.settingConfig,
  });

  final ValueChanged<SubChartType> onChartTypeChanged;
  final SettingConfig settingConfig;

  @override
  State<StatefulWidget> createState() => _KLineSubChart();
}

class _KLineSubChart extends State<KLineSubChart> {
  final _charts = [SubChartType.none, SubChartType.none];

  bool _isSelectedType(SubChartType type) {
    return _charts.contains(type);
  }

  @override
  Widget build(BuildContext context) {
    final types = SubChartType.chartTypes;
    final config = widget.settingConfig;
    return SizedBox(
      height: 40,
      child: Row(
        children: types
            .map(
              (type) => InkWell(
                onTap: () {
                  _onChartTypeChanged(type);
                },
                child: Container(
                  height: 20,
                  margin: const EdgeInsets.only(top: 10, bottom: 10, left: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _isSelectedType(type)
                          ? config.selectedIndicatorColor
                          : config.unselectedIndicatorBorderColor,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    type.displayValue,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: _isSelectedType(type)
                          ? config.selectedIndicatorColor
                          : config.unselectedIndicatorTextColor,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  void _onChartTypeChanged(SubChartType type) {
    widget.onChartTypeChanged(type);
    if (_charts.first == type) {
      _charts.first = _charts.last;
      _charts.last = SubChartType.none;
    } else if (_charts.last == type) {
      _charts.last = SubChartType.none;
    } else if (_charts.first == SubChartType.none) {
      _charts.first = type;
    } else {
      _charts.last = type;
    }
    setState(() {});
  }
}
