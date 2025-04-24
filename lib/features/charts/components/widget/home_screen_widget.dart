import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/drilling_data.dart';

import '../../../../utils/constants/colors.dart';
import '../../controller/chart_drilling_controller.dart';
import '../../model/parameter_item.dart';

extension DrillingDataExtension on DrillingData {
  num value(String key) {
    final raw = rawData[key];
    if (raw == null) return 0.0;
    return double.tryParse(raw.toString()) ?? 0.0;
  }
}

class HomeScreenWidget extends StatelessWidget {
  final DrillingController controller;
  final Box<ParameterItem> parameterBox;

  const HomeScreenWidget({
    Key? key,
    required this.controller,
    required this.parameterBox,
  }) : super(key: key);


  static final Map<String, num Function(DrillingData)> _mechanical = {
    'BitDepth (m)':   (d) => d.bitDepth,
    'WOB (klb)':      (d) => d.wob,
    'Torque (klb.ft)':(d) => d.torque,
    'RPM':            (d) => d.rpm,
    'Hkld (klb)':     (d) => d.hkld,
  };
  static final Map<String, num Function(DrillingData)> _mud = {
    'MudFlowIn (gpm)':  (d) => d.mudFlowIn,
    'MudFlowOutp (gpm)':(d) => d.mudFlowOutp,
    'MudCondIn (mmho)': (d) => d.mudCondIn,
    'MudCondOut (mmho)':(d) => d.mudCondOut,
    'SpPress (Psi)':    (d) => d.spPress,
    'TankVolTot (bbl)': (d) => d.tankVolTot,
  };
  static final Map<String, num Function(DrillingData)> _gas = {
    'H2S_1 (ppm)': (d) => d.h2s_1,
    'CO2_1 (%)':   (d) => d.co2_1,
    'Gas (%)':     (d) => d.gas,
  };
  static final Map<String, num Function(DrillingData)> _temp = {
    'MudTempIn (C)':  (d) => d.mudTempIn,
    'MudTempOut (C)': (d) => d.mudTempOut,
  };

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final dataList = controller.displayedData;
      final latest   = dataList.isNotEmpty ? dataList.last : null;
      final bitDepth = latest?.bitDepth ?? 0.0;

      final screenH  = MediaQuery.of(context).size.height;
      final bannerH  = screenH * 0.20;


      final sensors = <String, num Function(DrillingData)>{}
        ..addAll(_mechanical)
        ..addAll(_mud)
        ..addAll(_gas)
        ..addAll(_temp)

        ..addEntries(parameterBox.values.map((p) =>
            MapEntry(p.name, (d) => d.value(p.name))
        ));

      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Container(
                height: bannerH,
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.95,
                        child: Image.asset(
                          'assets/images/image_home.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset('assets/images/bit_depth.svg', height: 64),
                          const SizedBox(width: 12),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bit Depth',
                                style: TextStyle(color: Colors.white, fontSize: 24),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${bitDepth.toStringAsFixed(2)} m',
                                style: const TextStyle(
                                  color: CColors.primaryColor,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ───── Title ───────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Text(
                    'Sensor Status',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: CColors.primaryColor,
                    ),
                  ),
                )
              ),
              const SizedBox(height: 8),

              // ───── Sensor Card ─────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: latest == null
                        ? const Center(
                      child: Text(
                        'No sensor data available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                        : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sensors.length,
                      itemBuilder: (ctx, i) {
                        final entry = sensors.entries.toList()[i];
                        final name  = entry.key;
                        final value = entry.value(latest);
                        String unit;

                        // if this is a user‑added parameter, use its stored unit:
                        final custom = parameterBox.values
                            .firstWhere(
                              (p) => p.name == name,
                          orElse: () => ParameterItem(
                            name: '',
                            jsonKey: '',
                            unit: null,
                            color: Colors.transparent,
                            scaleStart: 0,
                            scaleEnd: 0,
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                            trackType: '',
                            value: '',
                          ),
                        );
                        if (custom.name.isNotEmpty) {
                          unit = custom.unit ?? '';
                        } else {
                          // fallback static detection:
                          if (name.contains('(m)'))     unit = ' m';
                          else if (name.contains('klb')) unit = ' klb';
                          else if (name.contains('gpm')) unit = ' gpm';
                          else if (name.contains('mmho'))unit = ' mmho';
                          else if (name.contains('Psi')) unit = ' Psi';
                          else if (name.contains('%'))   unit = ' %';
                          else if (name.contains('(C)')) unit = ' °C';
                          else                           unit = '';
                        }

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.settings,
                              color: CColors.primaryColor),
                          title: Text(name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          trailing: Text(
                            '${value.toStringAsFixed(2)}$unit',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: CColors.primaryColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    });
  }
}
