import 'package:get_it/get_it.dart';
import 'package:pdu_mobile_rto_app/data/services/hive_service.dart';
import 'package:pdu_mobile_rto_app/features/charts/controller/chart_drilling_controller.dart';

final locator = GetIt.instance;

void dependencyInjectionSetup() {

    locator.registerSingleton(() => HiveService());
    locator.registerLazySingleton(() => DrillingController());

}