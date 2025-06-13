import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/well_active.dart';
import 'package:pdu_mobile_rto_app/utils/formatters/formatter.dart';

bool isWellCompleted({required WellActive wellActive})
{
  return wellActive.wellActiveStatus.toLowerCase() != 'yes';
}
