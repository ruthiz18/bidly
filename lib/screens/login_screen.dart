import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_state.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import 'signup_screen.dart';

final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hide = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthState>();
    final ok = await auth.logIn(email: _email.text, password: _password.text);
    if (!mounted) return;
    if (ok) {
      // Pop any pushed screens so the auth gate's Home is what shows.
      Navigator.of(context).popUntil((r) => r.isFirst);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(auth.error ?? 'Login failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthState>().busy;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: Navigator.of(context).canPop() ? AppBar() : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset('assets/images/logo.png',
                        width: 92, height: 92),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Welcome Back!',
                    textAlign: TextAlign.center, style: text.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Sign in to monitor your active bids, item watchlists, and saved lots on Bidly.',
                  textAlign: TextAlign.center,
                  style: text.bodyMedium,
                ),
                const SizedBox(height: 28),
                Text('Email Address', style: text.titleMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    hintText: 'email@example.com',
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return 'Enter your email.';
                    if (!_emailRe.hasMatch(s)) return 'Enter a valid email.';
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                Text('Password', style: text.titleMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _password,
                  obscureText: _hide,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    hintText: 'Your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_hide
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _hide = !_hide),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter your password.' : null,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Log In',
                  icon: Icons.arrow_forward,
                  loading: busy,
                  onPressed: _submit,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? ", style: text.bodyMedium),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const SignUpScreen()),
                      ),
                      child: Text('Sign Up',
                          style: text.titleMedium
                              ?.copyWith(color: AppColors.secondary)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
