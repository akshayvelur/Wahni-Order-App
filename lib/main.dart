import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/product/product_bloc.dart';
import 'bloc/product/product_event.dart';
import 'core/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'data/datasources/local_database.dart';
import 'screens/product_list/product_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDatabase.init();
  runApp(const WahniOrderApp());
}

class WahniOrderApp extends StatelessWidget {
  const WahniOrderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductBloc()..add(const LoadProducts()),
      child: MaterialApp(
        title: AppConstants.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const ProductListScreen(),
      ),
    );
  }
}
