import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/constants/app_theme.dart';
import 'features/splash/presentation/page/splash_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'দাঁড়িপাল্লা',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const SplashPage(),
    );
  }
}
