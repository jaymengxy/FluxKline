class KLineTradeInfo {
  KLineTradeInfo({
    required this.info,
    required this.amount,
    required this.price,
    required this.isPositive,
  });

  final String info;
  final String amount;
  final double price;
  final bool isPositive;
}
