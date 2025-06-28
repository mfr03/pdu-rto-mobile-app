import 'package:get/get.dart';

import 'model/well_active.dart';
import 'pdu_api.dart';

class ParameterService {
  /// Fetches the first record's keys and filters numeric fields
  static Future<List<String>> fetchAvailableParameters({required WellActive wellActive}) async {
    // Use existing API to get initial data; each DrillingData retains rawData map
    final PduApi api = Get.find<PduApi>();
    final records = await api.fetchRealtimeDataIncrement(wellActive: wellActive);
    if (records.isEmpty) return [];
    // rawData is the original JSON map stored on the first element
    final record = records.first.rawDataOriginal;
    return record.keys.where((key) {
      final val = record[key];
      return val != null && double.tryParse(val.toString()) != null;
    }).toList();
  }
}