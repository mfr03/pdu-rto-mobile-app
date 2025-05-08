import 'package:hive_ce/hive.dart';
import 'package:flutter/material.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/well_active.dart';
import 'package:pdu_mobile_rto_app/features/charts/model/parameter_item.dart';

part 'hive_adapters.g.dart';

@GenerateAdapters([
  AdapterSpec<ParameterItem>(),
  AdapterSpec<Color>(),
  AdapterSpec<WellActive>()
])

void _() {}