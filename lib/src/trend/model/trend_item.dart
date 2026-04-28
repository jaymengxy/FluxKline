class TrendItem {
  TrendItem.fromJson(Map<String, dynamic> json) {
    price = double.parse(json['price'] as String);
    time = json['timeStamp'] as int;
  }

  TrendItem({required this.price, required this.time});

  late double price;
  late int time;
}
