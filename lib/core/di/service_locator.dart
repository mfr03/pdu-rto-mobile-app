import 'package:get_it/get_it.dart';
import '../../common/app_service.dart';
import '../../features/charts/controller/chart_controller.dart';

final locator = GetIt.instance;

void setup() {

    locator.registerLazySingleton(() => ChartController());


}