

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdu_mobile_rto_app/generated/l10n.dart';
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
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: colorScheme.error, size: 60),
              SizedBox(height: 20),
              Text(
                S.of(context).applicationInitializationFailed,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                errorMessage,
                style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              ElevatedButton.icon(
                icon: Icon(Icons.refresh, color: Colors.white),
                label: Text(S.of(context).retryInitialization, style: TextStyle(color: colorScheme.onPrimary)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15)
                ),
                onPressed: onRetry,
              ),
              SizedBox(height: 10),
              TextButton(
                child: Text(S.of(context).closeApp, style: TextStyle(color: colorScheme.onSurface.withAlpha(70))),
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