import 'dart:ui';

import 'package:flux_kline/src/common/decimal_util.dart';
import 'package:flux_kline/src/common/custom_gesture_recognizer.dart';
import 'package:flux_kline/src/config/settings_config.dart';
import 'package:flux_kline/src/controller/kline_controller.dart';
import 'package:flux_kline/src/model/info_window.dart';
import 'package:flux_kline/src/render/chart_painter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

class KLineChart extends StatefulWidget {
  const KLineChart({
    required this.kLineController,
    required this.settingConfig,
    super.key,
  });

  final KLineController kLineController;

  final SettingConfig settingConfig;

  @override
  State<StatefulWidget> createState() => _KLineChartState();
}

class _KLineChartState extends State<KLineChart> with TickerProviderStateMixin {
  AnimationController? _scrollXController;

  int _currentIndex = -1;

  BehaviorSubject<InfoWindow>? _infoWindowSubject;

  @override
  void initState() {
    super.initState();
    _infoWindowSubject = BehaviorSubject<InfoWindow>();
  }

  @override
  void dispose() {
    super.dispose();
    _scrollXController?.dispose();
    _infoWindowSubject?.close();
    _infoWindowSubject = null;
  }

  @override
  Widget build(BuildContext context) {
    return widget.settingConfig.isTrade ? _tradeWidget() : _normalWidget();
  }

  Widget _tradeWidget() {
    return GestureDetector(
      onHorizontalDragDown: (details) {
        _stopAnimation();
      },
      onHorizontalDragUpdate: (details) {
        widget.kLineController.onScrollUpdate(details.primaryDelta);
        setState(() {});
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        _fling(details.velocity.pixelsPerSecond.dx);
      },
      child: _getChartWidget(),
    );
  }

  Widget _normalWidget() {
    return RawGestureDetector(
      gestures: <Type, GestureRecognizerFactory>{
        KLineGestureRecognizer: GestureRecognizerFactoryWithHandlers<KLineGestureRecognizer>(
          () => KLineGestureRecognizer(debugOwner: this),
          (KLineGestureRecognizer instance) {
            instance
              ..enableVerDrag = false
              ..onStart = _onScaleStart
              ..onUpdate = _onScaleUpdate
              ..onEnd = _onScaleEnd;
          },
        ),
        TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          () => TapGestureRecognizer(debugOwner: this),
          (TapGestureRecognizer instance) {
            instance.onTapUp = _onTapUp;
          },
        ),
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
          () => LongPressGestureRecognizer(debugOwner: this),
          (LongPressGestureRecognizer instance) {
            instance
              ..onLongPressStart = _onLongPressStart
              ..onLongPressMoveUpdate = _onLongPressMoveUpdate;
          },
        ),
      },
      child: _getChartWidget(),
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    if (widget.kLineController.isLongPress) return;
    _stopAnimation();
    widget.kLineController.onScrollOffsetStart(details.localFocalPoint);
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (widget.kLineController.isLongPress) {
      _selectItem(details.localFocalPoint.dx, details.localFocalPoint.dy);
      return;
    }
    _updatePan(details.localFocalPoint);
    _scale(details.scale);
    setState(() {});
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (widget.kLineController.isLongPress) return;
    widget.kLineController.onScaleEnd();
    _fling(details.velocity.pixelsPerSecond.dx);
  }

  void _onTapUp(TapUpDetails details) {
    _stopAnimation();
    if (widget.kLineController.isLongPress) {
      widget.kLineController.isLongPress = false;
      _currentIndex = -1;
      setState(() {});
    } else {
      if (widget.kLineController.isClickRealTimePrice(
        details.globalPosition.dx,
        details.localPosition.dy,
      )) {
        _scrollToEnd();
        return;
      }
      widget.kLineController.isLongPress = true;
      _selectItem(details.globalPosition.dx, details.localPosition.dy);
    }
  }

  void _onLongPressStart(LongPressStartDetails details) {
    _stopAnimation();
    widget.kLineController.isLongPress = true;
    _selectItem(details.globalPosition.dx, details.localPosition.dy);
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    _selectItem(details.globalPosition.dx, details.localPosition.dy);
  }

  void _updatePan(Offset offset) {
    widget.kLineController.onScrollOffsetUpdate(offset);
  }

  void _scale(double scale) {
    _stopAnimation();
    widget.kLineController.onScaleUpdate(scale);
  }

  void _selectItem(double dx, double dy) {
    if (widget.kLineController.isSelectX(dx)) {
      if (_currentIndex != widget.kLineController.getSelectedXIndex()) {
        _currentIndex = widget.kLineController.getSelectedXIndex();
        HapticFeedback.lightImpact();
      }
    }
    widget.kLineController.onSelectYUpdate(dy);
    setState(() {});
  }

  void _scrollToEnd() {
    _scrollXController?.stop();
    _scrollXController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    final curve = CurvedAnimation(
      parent: _scrollXController!,
      curve: Curves.decelerate,
    );
    final scrollX = widget.kLineController.scrollX;
    final animation = Tween<double>(
      begin: scrollX,
      end: 0,
    ).animate(curve);
    animation.addListener(() {
      if (widget.kLineController.isFlingIn(animation.value)) {
        setState(() {});
      } else {
        _stopAnimation();
        setState(() {});
      }
    });
    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        setState(() {});
      }
    });
    _scrollXController!.forward();
  }

  Widget _getChartWidget() {
    return Stack(
      children: <Widget>[
        CustomPaint(
          size: Size.infinite,
          painter: ChartPainter(
            controller: widget.kLineController,
            config: widget.settingConfig,
            infoSubjectSubject: _infoWindowSubject,
          ),
        ),
        if (widget.kLineController.isLongPress) _buildInfoDialog(context),
      ],
    );
  }

  Widget _buildInfoDialog(BuildContext context) {
    final config = widget.settingConfig;
    return StreamBuilder<InfoWindow>(
      stream: _infoWindowSubject,
      builder: (context, snapshot) {
        if (!widget.kLineController.isLongPress ||
            widget.kLineController.isTimeLine ||
            snapshot.data?.kLineModel == null) {
          return const SizedBox.shrink();
        }
        final model = snapshot.data!.kLineModel;
        final change = model.close - model.open;
        final changeRate = change / model.open;

        final infoList = [
          DateFormat('yyyy-MM-dd HH:mm')
              .format(DateTime.fromMillisecondsSinceEpoch(model.openTime)),
          _formatData(model.open),
          _formatData(model.high),
          _formatData(model.low),
          _formatData(model.close),
          '${change > 0 ? '+' : ''}${_formatData(change)}',
          _formatRate(changeRate),
        ];
        return Align(
          alignment: snapshot.data!.layoutInLeft ? Alignment.topLeft : Alignment.topRight,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 3,
                  sigmaY: 3,
                ),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: config.infoWindowBgColor.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: config.infoWindowBorderColor,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: _buildItems(
                          textList: config.titleList,
                          isTitle: true,
                          config: config,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: _buildItems(textList: infoList, config: config),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatData(double value) {
    return value.formatPrice(
      maxDigits: widget.settingConfig.tickSize,
      minDigits: 2,
    );
  }

  String _formatRate(double changeRate) {
    var prefix = '';
    if (changeRate > 0) {
      prefix = '+';
    } else if (changeRate < 0) {
      prefix = '-';
    }
    return '$prefix${changeRate.abs().toPercent()}';
  }

  List<Widget> _buildItems({
    required List<String> textList,
    required SettingConfig config,
    bool isTitle = false,
  }) {
    final list = <Widget>[];
    for (var i = 0; i < textList.length; i++) {
      final text = textList[i];
      var color = isTitle ? config.infoTitleColor : config.infoPrimaryTextColor;
      if (text.startsWith('+')) {
        color = config.positiveColor;
      } else if (text.startsWith('-')) {
        color = config.negativeColor;
      }
      list.add(
        Text(
          text,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: color),
        ),
      );
      if (i < textList.length - 1) {
        list.add(const SizedBox(height: 4));
      }
    }
    return list;
  }

  void _fling(double dx) {
    _scrollXController?.stop();
    _scrollXController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    final curve = CurvedAnimation(
      parent: _scrollXController!,
      curve: Curves.decelerate,
    );
    final scrollX = widget.kLineController.scrollX;
    final animation = Tween<double>(
      begin: scrollX,
      end: dx * 0.5 + scrollX,
    ).animate(curve);
    animation.addListener(() {
      if (widget.kLineController.isFlingIn(animation.value)) {
        setState(() {});
      } else {
        _stopAnimation();
        setState(() {});
      }
    });
    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        setState(() {});
      }
    });
    _scrollXController!.forward();
  }

  void _stopAnimation() {
    _scrollXController?.stop();
  }
}
