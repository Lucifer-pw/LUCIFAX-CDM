import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucifax_cdm/app.dart';
import 'package:lucifax_cdm/core/services/background_service.dart';
import 'package:lucifax_cdm/core/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase service
  await FirebaseService().initialize();

  // Initialize Background service configurations
  await BackgroundServiceManager.initialize();

  runApp(
    const ProviderScope(
      child: LucifaxApp(),
    ),
  );
}
