import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:eautoshop_mobile/providers/auth_provider.dart';
import 'package:eautoshop_mobile/screens/home_screen.dart';
import 'package:eautoshop_mobile/screens/login_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return MaterialApp(
          title: 'eAutoShop',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
          ),
          home: authProvider.isLoggedIn
              ? const HomeScreen()
              : const LoginScreen(),
        );
      },
    );
  }
}
