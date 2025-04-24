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
              jsonKey: 'bitdepth',
              color: Colors.green,
              scaleStart: 0,
              scaleEnd: 5000,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'mechanical',
              value: '0'
            ),
            ParameterItem(
              name: 'WOB (klb)',
              jsonKey: 'woba',
              color: Colors.purple,
                scaleStart: 0,
                scaleEnd: 2000,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'mechanical',
                value: '0'
            ),
            ParameterItem(
              name: 'Torque (klb.ft)',
              jsonKey: 'torqa',
              color: Colors.blue,
                scaleStart: 0,
                scaleEnd: 2000,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'mechanical',
                value: '0'
            ),
            ParameterItem(
              name: 'RPM',
              jsonKey: 'rpm',
              color: Colors.red,
                scaleStart: 0,
                scaleEnd: 5000,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'mechanical',
                value: '0'
            ),
            ParameterItem(
              name: 'Hkld (klb)',
              jsonKey: 'hklda',
              color: Colors.teal,
                scaleStart: 0,
                scaleEnd: 2000,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'mechanical',
                value: '0'
            ),

            // Mud track parameters
            ParameterItem(
              name: 'MudFlowIn (gpm)',
              jsonKey: 'mudflowin',
              color: Colors.red,
                scaleStart: 0,
                scaleEnd: 1000,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'mud',
                value: '0'
            ),
            ParameterItem(
              name: 'MudFlowOutp (gpm)',
              jsonKey: 'mudflowoutp',
              color: Colors.blue,
                scaleStart: 0,
                scaleEnd: 2000,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'mud',
                value: '0'
            ),
            ParameterItem(
              name: 'MudCondIn (mmho)',
              jsonKey: 'mudcondin',
              color: Colors.green,
                scaleStart: 0,
                scaleEnd: 2000,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'mud',
                value: '0'
            ),
            ParameterItem(
              name: 'MudCondOut (mmho)',
              jsonKey: 'mudcondout',
              color: Colors.purple,
                scaleStart: 0,
                scaleEnd: 2000,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'mud',
                value: '0'
            ),
            ParameterItem(
              name: 'SpPress (Psi)',
              jsonKey: 'totspm',
              color: Colors.orange,
                scaleStart: 0,
                scaleEnd: 1000,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'mud',
                value: '0'
            ),
            ParameterItem(
              name: 'TankVolTot (bbl)',
              jsonKey: 'tankvoltot',
              color: Colors.brown,
                scaleStart: 0,
                scaleEnd: 2000,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'mud',
                value: '0'
            ),

            // Gas track parameters
            ParameterItem(
              name: 'H2S_1 (ppm)',
                jsonKey: 'h2s1',
                scaleStart: 0,
                scaleEnd: 2000,
              color: Colors.deepOrange,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'gas',
                value: '0'
            ),
            ParameterItem(
              name: 'CO2_1 (%)',
              jsonKey: 'co21',
              color: Colors.green,
                scaleStart: 0,
                scaleEnd: 100,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'gas',
                value: '0'
            ),
            ParameterItem(
              name: 'Gas (%)',
              jsonKey: 'gas',
              color: Colors.red,
                scaleStart: 0,
                scaleEnd: 100,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'gas',
                value: '0'
            ),

            // Temperature track parameters
            ParameterItem(
              name: 'MudTempIn (C)',
              jsonKey: 'mudtempin',
              color: Colors.blue,
                scaleStart: 0,
                scaleEnd: 400,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'temperature',
                value: '0'
            ),
            ParameterItem(
              name: 'MudTempOut (C)',
              jsonKey: 'mudtempout',
              color: Colors.red,
                scaleStart: 0,
                scaleEnd: 400,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'temperature',
                value: '0'
            ),
          ]
        );
      }
}