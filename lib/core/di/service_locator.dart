import 'package:get_it/get_it.dart';
import 'package:pdu_mobile_rto_app/data/services/hive/hive_service.dart';
import 'package:pdu_mobile_rto_app/data/services/notification_api/api_client.dart';
import 'package:pdu_mobile_rto_app/data/services/notification_api/fcm_service.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/pdu_api.dart';
import 'package:pdu_mobile_rto_app/features/authentication/services/auth_service.dart';
import 'package:pdu_mobile_rto_app/features/charts/controller/chart_drilling_controller.dart';

final locator = GetIt.instance;

void dependencyInjectionSetup() {

    locator.registerSingleton(() => HiveService());
    locator.registerLazySingleton(() => DrillingController());
    locator.registerLazySingleton(() => PduApi());
    locator.registerLazySingleton(() => AuthService());
    locator.registerLazySingleton(() => ApiClient());
    locator.registerLazySingleton(() => FcmService());
}