import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';
import 'package:pdu_mobile_rto_app/features/home/widget/home_banner_card.dart';
import 'package:pdu_mobile_rto_app/features/home/widget/home_sensor_view.dart';

import '../charts/controller/chart_drilling_controller.dart';
import '../charts/model/parameter_item.dart';

class HomeScreenWidget extends StatelessWidget {
  final DrillingController controller;
  final Box<ParameterItem>? parameterBox;

  const HomeScreenWidget({
    super.key,
    required this.controller,
    required this.parameterBox,
  });



  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final dataList = controller.displayedData;
      final latest   = dataList.isNotEmpty ? dataList.last : null;
      final bitDepth = latest?.bitDepth ?? 0.0;

      final screenH  = MediaQuery.of(context).size.height;
      final bannerH  = screenH * 0.20;

      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeBannerCard(bannerH: bannerH, bitDepth: bitDepth),
              const SizedBox(height: 16),


              if (parameterBox != null)
                StreamBuilder<BoxEvent>(
                  stream: parameterBox!.watch(),
                  builder: (_, __) {
                    return HomeSensorView(
                      latest:       latest,
                      parameterBox: parameterBox!,
                    );
                  },
                )
              else
                HomeSensorView(
                  latest:       latest,
                  parameterBox: parameterBox,
                ),

              const SizedBox(height: 64),
            ],
          ),
        ),
      );
    });
  }
}
