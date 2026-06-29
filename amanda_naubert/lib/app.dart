import 'package:flutter/material.dart';

import 'screens/login/login_screen.dart';
import 'screens/main_shell.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

class AmandaNaubertApp extends StatelessWidget {
  const AmandaNaubertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amanda & Naubert',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isLoggedIn(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return const MainShell();
        }

        return const LoginScreen();
      },
    );
  }
}