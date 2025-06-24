import 'package:pdu_mobile_rto_app/data/services/hive/hive_service.dart';
import 'package:pdu_mobile_rto_app/data/services/notification_api/api_client.dart';
import 'package:pdu_mobile_rto_app/data/services/notification_api/fcm_service.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/pdu_api.dart';
import 'package:pdu_mobile_rto_app/features/authentication/services/auth_service.dart';
import 'package:pdu_mobile_rto_app/features/charts/controller/chart_drilling_controller.dart';
import 'package:pdu_mobile_rto_app/features/charts/controller/depth_chart_drilling_controller.dart';
import 'package:get/get.dart';

void dependencyInjectionSetup() {

    Get.put(() => HiveService());
    Get.lazyPut(() => DrillingController(), fenix: true);
    Get.lazyPut(() => DepthDrillingController(), fenix: true);
    Get.lazyPut(() => PduApi(), fenix: true);
    Get.lazyPut(() => AuthService(), fenix: true);
    Get.lazyPut(() => ApiClient(), fenix: true);
    Get.lazyPut(() => FcmService(), fenix: true);

}