import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/well_active.dart';
import 'package:pdu_mobile_rto_app/utils/formatters/formatter.dart';

bool isWellCompleted({required WellActive wellActive})
{
  final DateTime? endDate = CFormatter.formatStringToDateTime(wellActive.endDate);
  if (endDate == null) {
    return false;
  }
  final now = DateTime.now();
  return endDate.isBefore(DateTime(now.year, now.month, now.day));
}
