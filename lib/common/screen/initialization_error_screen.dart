

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdu_mobile_rto_app/utils/constants/colors.dart';


class InitializationErrorScreen extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const InitializationErrorScreen({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 60),
              SizedBox(height: 20),
              Text(
                'Application Initialization Failed',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                errorMessage,
                style: TextStyle(fontSize: 14, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              ElevatedButton.icon(
                icon: Icon(Icons.refresh, color: Colors.white),
                label: Text('Retry Initialization', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: CColors.primaryColor,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15)
                ),
                onPressed: onRetry,
              ),
              SizedBox(height: 10),
              TextButton(
                child: Text('Close App', style: TextStyle(color: Colors.grey[700])),
                onPressed: () {
                  // This will attempt to close the app.
                  // Note: SystemChannels.platform.invokeMethod('SystemNavigator.pop') is more forceful.
                  // For critical init errors, a more direct exit might be needed if retry fails repeatedly.
                  SystemNavigator.pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}