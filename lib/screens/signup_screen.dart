import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_state.dart';
import '../widgets/primary_button.dart';

final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String _role = 'buyer';
  bool _hide = true;
  bool _agreed = false;
  bool _showAgreeError = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState!.validate();
    setState(() => _showAgreeError = !_agreed);
    if (!valid || !_agreed) return;

    final auth = context.read<AuthState>();
    final ok = await auth.signUp(
      name: _name.text,
      email: _email.text,
      password: _password.text,
      role: _role,
    );
    if (!mounted) return;
    if (ok) {
      // Signed in now: pop back to the root so the auth gate shows Home.
      Navigator.of(context).popUntil((r) => r.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.error ?? 'Sign up failed')));
    }
  }

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(s, style: Theme.of(context).textTheme.titleMedium),
      );

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthState>().busy;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Join Bidly', style: text.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Bid, win, and sell unique items with thousands of verified community members.',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: 24),
                _label('Full Name'),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return 'Enter your name.';
                    if (s.length < 2) return 'Name is too short.';
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                _label('Email Address'),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'email@example.com',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return 'Enter your email.';
                    if (!_emailRe.hasMatch(s)) return 'Enter a valid email.';
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                _label('Primary Role'),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.badge_outlined)),
                  items: const [
                    DropdownMenuItem(
                        value: 'buyer', child: Text('Buyer / Bidder')),
                    DropdownMenuItem(value: 'seller', child: Text('Seller')),
                  ],
                  onChanged: (v) => setState(() => _role = v ?? 'buyer'),
                ),
                const SizedBox(height: 18),
                _label('Password'),
                TextFormField(
                  controller: _password,
                  obscureText: _hide,
                  decoration: InputDecoration(
                    hintText: 'Create a password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_hide
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _hide = !_hide),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Create a password.';
                    if (v.length < 6) return 'Use at least 6 characters.';
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                _label('Confirm Password'),
                TextFormField(
                  controller: _confirm,
                  obscureText: _hide,
                  decoration: const InputDecoration(
                    hintText: 'Re-enter password',
                    prefixIcon: Icon(Icons.lock_reset),
                  ),
                  validator: (v) =>
                      v != _password.text ? 'Passwords do not match.' : null,
                ),
                const SizedBox(height: 14),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _agreed,
                  onChanged: (v) => setState(() {
                    _agreed = v ?? false;
                    _showAgreeError = false;
                  }),
                  title: const Text(
                      'I agree to the Bidly Terms of Service, Privacy Policy, and Marketplace Bidding Rules.'),
                  subtitle: _showAgreeError
                      ? Text('You must agree to continue.',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error))
                      : null,
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Create Account',
                  icon: Icons.arrow_forward,
                  loading: busy,
                  onPressed: _submit,
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Already have an account? Log In'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
