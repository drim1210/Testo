import 'package:flutter/material.dart';
import 'core/config/app_router.dart';
import 'core/theme/app_theme.dart';

class TestoApp extends StatelessWidget {
  const TestoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Testo',
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
