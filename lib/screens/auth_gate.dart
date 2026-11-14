import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_state.dart';
import '../widgets/loading_view.dart';
import 'main_shell.dart';
import 'welcome_screen.dart';

/// Signed out -> log in. Signed in -> home. Driven by authStateChanges
/// through AuthState, so it also reacts to logout from anywhere.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (!auth.initialised) return const Scaffold(body: LoadingView());
    return auth.isSignedIn ? const MainShell() : const WelcomeScreen();
  }
}
