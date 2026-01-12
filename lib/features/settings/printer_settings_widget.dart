import 'package:flutter/material.dart';

// Conditional imports
import 'printer_settings_stub.dart'
    if (dart.library.io) 'printer_settings_desktop.dart'
    if (dart.library.html) 'printer_settings_web.dart' as printer_settings;

/// Platform-aware printer settings card
/// Loads desktop or web implementation based on platform
class PrinterSettingsCard extends StatelessWidget {
  const PrinterSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return printer_settings.buildPrinterSettingsCard(context);
  }
}
