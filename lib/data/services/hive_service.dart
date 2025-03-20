import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

class HiveService {
      static Future<void> initializeHive() async {
      Hive
          .init(Directory.current.path)
      ;
  }
}