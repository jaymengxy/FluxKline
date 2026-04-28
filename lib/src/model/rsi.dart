mixin RSIModel {
  late double rsi6;
  late double rsi12;
  late double rsi24;

  void setRSIValue(int n, double value) {
    if (n == 6) {
      rsi6 = value;
    } else if (n == 12) {
      rsi12 = value;
    } else if (n == 24) {
      rsi24 = value;
    }
  }
}
