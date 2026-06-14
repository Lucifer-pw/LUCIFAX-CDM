import 'package:flutter/material.dart';
import 'package:lucifax_cdm/core/router/app_router.dart';
import 'package:lucifax_cdm/core/theme/app_theme.dart';

class LucifaxApp extends StatelessWidget {
  const LucifaxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Lucifax CDM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
