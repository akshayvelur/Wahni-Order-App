import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'core/constants/app_constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WahniOrderApp());
}

class WahniOrderApp extends StatelessWidget {
  const WahniOrderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const Scaffold(
        body: Center(child: Text('Wahni Order App - Initial Setup')),
      ),
    );
  }
}
