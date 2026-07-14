import 'package:flutter/material.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/role_message_screen.dart';
import '../navigation/app_shell.dart';
import 'auth_state.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    if (auth.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = auth.currentUser;

    if (user == null) {
      return const LoginScreen();
    }

    if (user.isPetOwner) {
      return const AppShell();
    }

    return RoleMessageScreen(user: user);
  }
}
