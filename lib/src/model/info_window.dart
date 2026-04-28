import 'package:flux_kline/src/model/kline.dart';

class InfoWindow {
  InfoWindow({
    required this.kLineModel,
    this.layoutInLeft = false,
  });

  KLineModel kLineModel;
  bool layoutInLeft;
}
