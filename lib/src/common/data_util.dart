import 'dart:math';

import 'package:flux_kline/src/model/kline.dart';

class DataUtil {
  static void calculate(List<KLineModel> dataList) {
    _calcMA(dataList);
    _calcBOLL(dataList);
    _calcVolumeMA(dataList);
    _calcKDJ(dataList);
    _calcMACD(dataList);
    _calcRSI(dataList);
  }

  static void _calcMA(List<KLineModel> dataList, {bool isUpdate = false}) {
    var ma5 = 0.0;
    var ma10 = 0.0;
    var ma20 = 0.0;

    var i = 0;
    if (isUpdate && dataList.length > 30) {
      i = dataList.length - 1;
      final data = dataList[dataList.length - 2];
      ma5 = data.ma5 * 5;
      ma10 = data.ma10 * 10;
      ma20 = data.ma20 * 20;
    }
    for (; i < dataList.length; i++) {
      final entity = dataList[i];
      final closePrice = entity.close;
      ma5 += closePrice;
      ma10 += closePrice;
      ma20 += closePrice;

      if (i == 4) {
        entity.ma5 = ma5 / 5;
      } else if (i >= 5) {
        ma5 -= dataList[i - 5].close;
        entity.ma5 = ma5 / 5;
      } else {
        entity.ma5 = 0;
      }
      if (i == 9) {
        entity.ma10 = ma10 / 10;
      } else if (i >= 10) {
        ma10 -= dataList[i - 10].close;
        entity.ma10 = ma10 / 10;
      } else {
        entity.ma10 = 0;
      }
      if (i == 19) {
        entity.ma20 = ma20 / 20;
      } else if (i >= 20) {
        ma20 -= dataList[i - 20].close;
        entity.ma20 = ma20 / 20;
      } else {
        entity.ma20 = 0;
      }
    }
  }

  static void _calcBOLL(List<KLineModel> dataList, {bool isUpdate = false}) {
    var i = 0;
    if (isUpdate && dataList.length > 1) {
      i = dataList.length - 1;
    }
    for (; i < dataList.length; i++) {
      final entity = dataList[i];
      if (i < 19) {
        entity.mid = 0;
        entity.up = 0;
        entity.down = 0;
      } else {
        const n = 20;
        var md = 0.0;
        for (var j = i - n + 1; j <= i; j++) {
          final c = dataList[j].close;
          final m = entity.ma20;
          final value = c - m;
          md += value * value;
        }
        md = md / (n - 1);
        md = sqrt(md);
        entity.mid = entity.ma20;
        entity.up = entity.mid + 2.0 * md;
        entity.down = entity.mid - 2.0 * md;
      }
    }
  }

  static void _calcMACD(List<KLineModel> dataList, {bool isUpdate = false}) {
    var ema12 = 0.0;
    var ema26 = 0.0;
    var dif = 0.0;
    var dea = 0.0;
    var macd = 0.0;

    var i = 0;
    if (isUpdate && dataList.length > 1) {
      i = dataList.length - 1;
      final data = dataList[dataList.length - 2];
      dif = data.dif;
      dea = data.dea;
      macd = data.macd;
      ema12 = data.ema12;
      ema26 = data.ema26;
    }

    for (; i < dataList.length; i++) {
      final entity = dataList[i];
      final closePrice = entity.close;
      if (i == 0) {
        ema12 = closePrice;
        ema26 = closePrice;
      } else {
        ema12 = ema12 * 11 / 13 + closePrice * 2 / 13;
        ema26 = ema26 * 25 / 27 + closePrice * 2 / 27;
      }
      dif = ema12 - ema26;
      dea = dea * 8 / 10 + dif * 2 / 10;
      macd = (dif - dea) * 2;
      entity.dif = dif;
      entity.dea = dea;
      entity.macd = macd;
      entity.ema12 = ema12;
      entity.ema26 = ema26;
    }
  }

  static void _calcVolumeMA(List<KLineModel> dataList, {bool isUpdate = false}) {
    var volumeMa5 = 0.0;
    var volumeMa10 = 0.0;

    var i = 0;
    if (isUpdate && dataList.length > 10) {
      i = dataList.length - 1;
      final data = dataList[dataList.length - 2];
      volumeMa5 = data.ma5Volume * 5;
      volumeMa10 = data.ma10Volume * 10;
    }

    for (; i < dataList.length; i++) {
      final entry = dataList[i];

      volumeMa5 += entry.vol;
      volumeMa10 += entry.vol;

      if (i == 4) {
        entry.ma5Volume = volumeMa5 / 5;
      } else if (i > 4) {
        volumeMa5 -= dataList[i - 5].vol;
        entry.ma5Volume = volumeMa5 / 5;
      } else {
        entry.ma5Volume = 0;
      }

      if (i == 9) {
        entry.ma10Volume = volumeMa10 / 10;
      } else if (i > 9) {
        volumeMa10 -= dataList[i - 10].vol;
        entry.ma10Volume = volumeMa10 / 10;
      } else {
        entry.ma10Volume = 0;
      }
    }
  }

  static void _calcRSI(List<KLineModel> dataList) {
    _calcRSIWithN(dataList, 6);
    _calcRSIWithN(dataList, 12);
    _calcRSIWithN(dataList, 24);
  }

  static void _calcRSIWithN(List<KLineModel> dataList, int n) {
    var sumUp = 0.0;
    var sumDn = 0.0;
    var preClose = 0.0;
    var averageUp = 0.0;
    var averageDn = 0.0;
    for (var i = 0; i < dataList.length; i++) {
      final klineModel = dataList[i];

      if (i == 0) {
        preClose = klineModel.close;
        klineModel.setRSIValue(n, 0);
        continue;
      }

      if (klineModel.close > preClose) {
        sumUp += klineModel.close - preClose;
      } else {
        sumDn += preClose - klineModel.close;
      }

      var value = 0.0;
      if (i == n) {
        averageUp = sumUp / n;
        averageDn = sumDn / n;
        value = averageUp + averageDn == 0 ? 0.0 : averageUp / (averageUp + averageDn) * 100.0;
      } else if (i > n) {
        if (klineModel.close > preClose) {
          averageUp = (averageUp * (n - 1) + (klineModel.close - preClose)) / n;
          averageDn = averageDn * (n - 1) / n;
        } else {
          averageDn = (averageDn * (n - 1) + (preClose - klineModel.close)) / n;
          averageUp = averageUp * (n - 1) / n;
        }
        value = averageUp + averageDn == 0 ? 0.0 : averageUp / (averageUp + averageDn) * 100.0;
      }
      klineModel.setRSIValue(n, value);
      preClose = klineModel.close;
    }
  }

  static void _calcKDJ(List<KLineModel> dataList, {bool isUpdate = false}) {
    var k = 0.0;
    var d = 0.0;
    const n = 9;

    var i = 0;
    if (isUpdate && dataList.length > 1) {
      i = dataList.length - 1;
      final data = dataList[dataList.length - 2];
      k = data.k;
      d = data.d;
    }

    for (; i < dataList.length; i++) {
      final entity = dataList[i];
      final closePrice = entity.close;
      var startIndex = i - n - 1;
      if (startIndex < 0) {
        startIndex = 0;
      }
      var high = -double.maxFinite;
      var low = double.maxFinite;
      for (var index = startIndex; index <= i; index++) {
        high = max(high, dataList[index].high);
        low = min(low, dataList[index].low);
      }
      var rsv = 0.0;
      if (high != low) {
        rsv = 100 * (closePrice - low) / (high - low);
      }
      if (i == 0) {
        k = 50;
        d = 50;
      } else {
        k = (rsv + 2 * k) / 3;
        d = (k + 2 * d) / 3;
      }
      if (i < n - 1) {
        entity.k = 0;
        entity.d = 0;
        entity.j = 0;
      } else if (i == n - 1 || i == n) {
        entity.k = k;
        entity.d = 0;
        entity.j = 0;
      } else {
        entity.k = k;
        entity.d = d;
        entity.j = 3 * k - 2 * d;
      }
    }
  }

  static void updateLastData(List<KLineModel> dataList) {
    _calcMA(dataList, isUpdate: true);
    _calcBOLL(dataList, isUpdate: true);
    _calcVolumeMA(dataList, isUpdate: true);
    _calcKDJ(dataList, isUpdate: true);
    _calcMACD(dataList, isUpdate: true);
    _calcRSI(dataList);
  }
}
