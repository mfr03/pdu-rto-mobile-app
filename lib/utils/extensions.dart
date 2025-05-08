import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/drilling_data.dart';

extension DrillingDataExtension on DrillingData {
  num value(String key) {
    final val = rawData[key];
    return val == null ? 0.0 : double.tryParse(val.toString()) ?? 0.0;
  }
}