import 'package:flutter/material.dart';

import '../screens/main_shell.dart';
import '../screens/login_screen.dart';
import '../screens/role_selection_screen.dart';
import '../screens/wait_for_approval_screen.dart';
import 'auth_service.dart';
import 'models.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Widget screenFor(Session s) {
  switch (s.nextScreen) {
    case 'dashboard':
      return MainShell(session: s);
    case 'wait_for_approval':
      return WaitForApprovalScreen(session: s);
    case 'role_selection':
      return RoleSelectionScreen(session: s);
    default:
      return const LoginScreen();
  }
}

void goToSession(BuildContext context, Session s) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => screenFor(s)),
    (route) => false,
  );
}

void goToLogin(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}

Future<void> logoutAndGoToLogin(BuildContext context) async {
  await AuthService.logout();
  if (!context.mounted) return;
  goToLogin(context);
}