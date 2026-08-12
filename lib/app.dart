import 'package:flutter/material.dart';

import 'pages/splash/splash_page.dart';
import 'theme/app_theme.dart';
import 'utils/app_feedback.dart';

class BullCareApp extends StatelessWidget {
  const BullCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: AppFeedback.messengerKey,
      debugShowCheckedModeBanner: false,
      title: 'BullCare',
      theme: AppTheme.lightTheme,
      home: const SplashPage(),
    );
  }
}
