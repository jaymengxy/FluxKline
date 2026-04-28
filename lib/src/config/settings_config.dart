import 'package:flutter/material.dart';
import 'package:flux_kline/src/config/flux_kline_theme.dart';

class SettingConfig {
  SettingConfig({
    required this.theme,
    required this.tickSize,
    this.titleList = const [],
    this.isTrade = false,
  });

  final FluxKlineTheme theme;
  final bool isTrade;
  final int tickSize;
  final List<String> titleList;

  Color get upColor => theme.upColor;

  Color get downColor => theme.downColor;

  Color get bgColor => isTrade ? theme.dialogColor : theme.backgroundColor;

  Color get defaultTextColor => theme.tertiaryTextColor;

  Color get realTimeTextColor => theme.blackColor;

  Color get realTimeInLineTextColor => theme.primaryTextColor;

  Color get realTimeLineColor => theme.titleTextColor;

  Color get realTimeBgColor => theme.dialogColor;

  Color get crossLineTextColor => theme.titleTextColor;

  Color get hCrossLineColor => theme.disableTextColor;

  Color get vCrossLineColor => theme.disableTextColor;

  Color get crossLinePointColor => theme.brandColor;

  // Colors used by info window
  Color get infoWindowBgColor => theme.dialogColor;

  Color get infoWindowBorderColor => theme.cardColor;

  Color get infoTitleColor => theme.secondaryTextColor;

  Color get infoPrimaryTextColor => theme.primaryTextColor;

  Color get positiveColor => theme.upColor;

  Color get negativeColor => theme.downColor;

  // Colors used by indicator/sub chart selectors
  Color get selectedIndicatorColor => theme.brandColor;

  Color get unselectedIndicatorBorderColor => theme.dividerColor;

  Color get unselectedIndicatorTextColor => theme.tertiaryTextColor;
}
