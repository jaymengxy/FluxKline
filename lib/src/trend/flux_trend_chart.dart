import 'package:flux_kline/src/trend/config/trend_chart_config.dart';
import 'package:flux_kline/src/trend/controller/trend_chart_controller.dart';
import 'package:flux_kline/src/trend/painter/trend_chart_painter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class FluxTrendChart extends StatefulWidget {
  const FluxTrendChart({
    required this.chartController,
    required this.chartConfig,
    super.key,
  });

  final TrendChartController chartController;
  final TrendChartConfig chartConfig;

  @override
  State<StatefulWidget> createState() => _FluxTrendChartState();
}

class _FluxTrendChartState extends State<FluxTrendChart> {
  int _currentIndex = -1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: _onTapUp,
      onHorizontalDragUpdate: _onDragUpdate,
      onLongPressStart: _onLongPressStart,
      onLongPressMoveUpdate: _onLongPressMoveUpdate,
      child: _getChartWidget(),
    );
  }

  Widget _getChartWidget() {
    return Stack(
      children: <Widget>[
        CustomPaint(
          size: Size.infinite,
          painter: TrendChartPainter(
            controller: widget.chartController,
            config: widget.chartConfig,
          ),
        ),
      ],
    );
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.chartController.isSelected) {
      widget.chartController.isSelected = false;
      _currentIndex = -1;
      setState(() {});
    } else {
      widget.chartController.isSelected = true;
      _selectItem(details.localPosition.dx);
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _selectItem(details.localPosition.dx);
  }

  void _onLongPressStart(LongPressStartDetails details) {
    widget.chartController.isSelected = true;
    _selectItem(details.localPosition.dx);
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    _selectItem(details.localPosition.dx);
  }

  void _selectItem(double dx) {
    if (widget.chartController.isSelectX(dx)) {
      if (_currentIndex != widget.chartController.getSelectedXIndex()) {
        _currentIndex = widget.chartController.getSelectedXIndex();
        HapticFeedback.lightImpact();
      }
    }
    setState(() {});
  }
}
