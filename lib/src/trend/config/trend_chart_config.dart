import 'dart:ui';

import 'package:flux_kline/src/config/flux_kline_theme.dart';

class TrendChartConfig {
  TrendChartConfig({
    required this.theme,
  });

  final FluxKlineTheme theme;

  static const int rows = 4;
  static const int columns = 4;
  static const int tickSize = 6;

  static const double lineWidth = 2;
  static const double dividerWidth = 1;
  static const double selectedPointWidth = 2;
  static const double leftPadding = 14;
  static const double rightPadding = 48;
  static const double topPadding = 12;
  static const double marginBottom = 20;
  static const double dateHeight = 24;

  Color get lineColor => theme.brandColor;

  List<Color> get lineShadowColor {
    return [theme.brandColor.withValues(alpha: 0.3), theme.brandColor.withValues(alpha: 0)];
  }

  Color get dividerColor => theme.cardColor;

  Color get textColor => theme.tertiaryTextColor;

  Color get selectedPointColor => theme.brandColor;

  Color get selectedLineColor => theme.tertiaryTextColor;

  Color get selectedTextColor => theme.titleTextColor;
}
