enum MainChartIndicator {
  ma('MA'),
  boll('BOLL');

  const MainChartIndicator(this.displayValue);

  final String displayValue;

  static List<MainChartIndicator> get indicators => const [
        ma,
        // boll,
      ];
}

enum SubChartType {
  none(''),
  volume('VOLUME'),
  macd('MACD'),
  kdj('KDJ'),
  rsi('RSI'),
  wr('WR');

  const SubChartType(this.displayValue);

  final String displayValue;

  static List<SubChartType> get chartTypes => const [
        macd,
        volume,
        kdj,
        rsi,
        // wr,
      ];
}
