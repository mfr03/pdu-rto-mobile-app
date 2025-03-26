import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:pdu_mobile_rto_app/features/charts/model/parameter_item.dart';
import 'package:pdu_mobile_rto_app/data/services/hive/hive_registrar.g.dart';
import 'package:path_provider/path_provider.dart';

class HiveService {
      static Future<void> initializeHive() async {
        final appDocumentDir = await getApplicationDocumentsDirectory();
        Hive
          ..init(appDocumentDir.path)
          ..registerAdapters();

    }

      static Future<Box<ParameterItem>> openParameterBox() async {
        return await Hive.openBox<ParameterItem>('user_parameters');
      }

      static Future<void> initializeDefaultData(Box<ParameterItem> box) async {
        await box.addAll(
          [
            // Mechanical track parameters
            ParameterItem(
              name: 'BitDepth (m)',
              color: Colors.green,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'mechanical',
              value: '0'
            ),
            ParameterItem(
              name: 'WOB (klb)',
              color: Colors.purple,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'mechanical',
                value: '0'
            ),
            ParameterItem(
              name: 'Torque (klb.ft)',
              color: Colors.blue,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'mechanical',
                value: '0'
            ),
            ParameterItem(
              name: 'RPM',
              color: Colors.red,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'mechanical',
                value: '0'
            ),
            ParameterItem(
              name: 'Hkld (klb)',
              color: Colors.teal,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'mechanical',
                value: '0'
            ),

            // Mud track parameters
            ParameterItem(
              name: 'MudFlowIn (gpm)',
              color: Colors.red,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'mud',
                value: '0'
            ),
            ParameterItem(
              name: 'MudFlowOutp (gpm)',
              color: Colors.blue,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'mud',
                value: '0'
            ),
            ParameterItem(
              name: 'MudCondIn (mmho)',
              color: Colors.green,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'mud',
                value: '0'
            ),
            ParameterItem(
              name: 'MudCondOut (mmho)',
              color: Colors.purple,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'mud',
                value: '0'
            ),
            ParameterItem(
              name: 'SpPress (Psi)',
              color: Colors.orange,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'mud',
                value: '0'
            ),
            ParameterItem(
              name: 'TankVolTot (bbl)',
              color: Colors.brown,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'mud',
                value: '0'
            ),

            // Gas track parameters
            ParameterItem(
              name: 'H2S_1 (ppm)',
              color: Colors.deepOrange,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'gas',
                value: '0'
            ),
            ParameterItem(
              name: 'CO2_1 (%)',
              color: Colors.green,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'gas',
                value: '0'
            ),
            ParameterItem(
              name: 'Gas (%)',
              color: Colors.red,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'gas',
                value: '0'
            ),

            // Temperature track parameters
            ParameterItem(
              name: 'MudTempIn (C)',
              color: Colors.blue,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'temperature',
                value: '0'
            ),
            ParameterItem(
              name: 'MudTempOut (C)',
              color: Colors.red,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'temperature',
                value: '0'
            ),
          ]
        );
      }
}