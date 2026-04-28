import 'package:flutter/material.dart';

class ChartColors {
  static const Color grid = Color(0x14ffffff);
  static const Color timeLine = Colors.blue;
  static const List<Color> timeLineShadow = [Color(0x802196F3), Color(0x00000000)];
  static const Color ma5 = Colors.red;
  static const Color ma10 = Colors.blue;
  static const Color ma20 = Colors.green;
  static const Color bollUp = Colors.purple;
  static const Color bollMid = Colors.orange;
  static const Color bollDown = Colors.purple;
  static const Color vol = Colors.purple;
  static const Color volMa5 = Colors.red;
  static const Color volMa10 = Colors.blue;
  static const Color ema7 = Colors.red;
  static const Color ema30 = Colors.blue;
  static const Color macd = Colors.purple;
  static const Color dea = Colors.red;
  static const Color dif = Colors.blue;
  static const Color rsi6 = Color(0xFFFFFFFF);
  static const Color rsi12 = Color(0xFFEDB943);
  static const Color rsi24 = Color(0xFFC159D3);
  static const Color wr14 = Colors.red;
  static const Color wr20 = Colors.blue;
  static const Color k = Color(0xFFE7BB41);
  static const Color d = Color(0xFFD64EB1);
  static const Color j = Color(0xFF8569BE);
}

class ChartStyle {
  static const int gridRows = 3;
  static const int gridColumns = 4;
  static const double pointWidth = 10;
  static const double candleWidth = 8;
  static const double candleLineWidth = 1;
  static const double volWidth = 8;
  static const double macdWidth = 6;
  static const double hCrossWidth = 1;
  static const double vCrossWidth = 1;
  static const double vCrossPadding = 8;
  static const double chartTopPadding = 15;
  static const double contentPadding = 12;
  static const double bottomDateHeight = 20;
  static const double defaultTextSize = 10;
}
