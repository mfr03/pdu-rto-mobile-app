// lib/utils/client_id_service.dart (example)
import 'package:flutter/material.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show kDebugMode;


class ClientIdService {
  static const _clientIdKey = 'persistent_client_id';
  static final Uuid _uuid = Uuid();

  static Future<String> getPersistentClientId() async {
    final prefs = await SharedPreferences.getInstance();
    String? clientId = prefs.getString(_clientIdKey);
    if (clientId == null) {
      clientId = _uuid.v4();
      await prefs.setString(_clientIdKey, clientId);
        debugPrint('Generated and saved new persistent client ID: $clientId');
    }
    return clientId;
  }
}