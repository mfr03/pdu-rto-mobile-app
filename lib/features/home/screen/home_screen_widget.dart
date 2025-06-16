import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/well_active.dart';
import 'package:pdu_mobile_rto_app/features/charts/controller/chart_drilling_controller.dart';
import 'package:pdu_mobile_rto_app/features/charts/model/parameter_item.dart';
import 'package:pdu_mobile_rto_app/features/home/components/widget/home_banner_card.dart';
import 'package:pdu_mobile_rto_app/features/home/components/widget/home_sensor_view.dart';
import 'package:pdu_mobile_rto_app/utils/constants/colors.dart';
import 'package:pdu_mobile_rto_app/utils/well_utils.dart';

class HomeScreenWidget extends StatelessWidget {
  const HomeScreenWidget({
    super.key,
    required this.controller,
    required this.parameterBox,
    required this.depthParameterBox,
    required this.currentWell,
  });

  final DrillingController controller;
  final Box<ParameterItem>? parameterBox;
  final Box<ParameterItem>? depthParameterBox;
  final WellActive currentWell;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // PRIORITY 1: If the controller is loading ANY data for the home screen, show a spinner.
      if (controller.isHomeScreenLoading.isTrue) {
        return const Center(
          child: CircularProgressIndicator(color: CColors.primaryColor),
        );
      }

      // PRIORITY 2: If loading is finished and live data failed, show the button.
      if (controller.liveDataFetchFailed.isTrue) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history_toggle_off, size: 60, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  "Live Data Not Available",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Text(
                  "Would you like to load the latest historical data for this well?",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.download_for_offline_outlined, color: Colors.white),
                  label: const Text('Load Historical Data', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: CColors.primaryColor),
                  onPressed: () {
                    controller.loadHistoricalData(wellActive: currentWell);
                  },
                )
              ],
            ),
          ),
        );
      }

      // PRIORITY 3: If loading is finished and no data was found at all.
      if (controller.liveTimeData.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.layers_clear_outlined, size: 60, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  "No Data Available",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Text(
                  "We could not find any live or historical data for this well.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        );
      }

      // PRIORITY 4: If everything is fine, show the dashboard.
      return SingleChildScrollView(
        child: Column(
          children: [
            HomeBannerCard(
              well: currentWell,
              bannerH: 150,
              bitDepth: controller.latestLiveTimeDataPoint.value?.bitDepth ?? 0.0,
            ),
            const SizedBox(height: 16),
            HomeSensorView(
              controller: controller,
              timeParameterBox: parameterBox!,
              depthParameterBox: depthParameterBox!,
              // --- THIS IS THE FIX ---
              // The 'isWellLive' status now comes directly from the controller's state.
              isWellLive: controller.isTimeChartLive.value,
              currentWellApiToken: currentWell.isApiToken,
            ),
            const SizedBox(height: 80),
          ],
        ),
      );
    });
  }
}