import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

/// Screen 1: first thing a signed-out user sees.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, AppColors.accentSoft],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 24),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset('assets/images/logo.png',
                          width: 100, height: 100),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Bidly',
                    textAlign: TextAlign.center, style: text.headlineLarge),
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Text(
                      'BIDLY LIVE AUCTIONS • VERIFIED MARKETPLACE',
                      textAlign: TextAlign.center,
                      style: text.labelSmall
                          ?.copyWith(color: AppColors.secondary),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Live bidding, transparent auctions, and peer-to-peer deals you can trust.',
                  textAlign: TextAlign.center,
                  style: text.bodyMedium,
                ),
                const SizedBox(height: 24),
                const _FeatureCard(
                  icon: Icons.bolt,
                  title: 'Live Bids',
                  badge: 'INSTANT',
                  body:
                      'Instant real-time bidding, transparent counters, and instant outbid alerts.',
                ),
                const SizedBox(height: 12),
                const _FeatureCard(
                  icon: Icons.shield,
                  title: 'Buyer & Seller Protection',
                  badge: 'ZERO FEES',
                  body:
                      'Secure escrow protection and verified payments on every lot.',
                ),
                const SizedBox(height: 12),
                const _FeatureCard(
                  icon: Icons.verified_user,
                  title: 'Verified Member Network',
                  badge: '100% VERIFIED',
                  dark: true,
                  body:
                      'Identity-verified buyers & sellers with trusted community ratings.',
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'Get Started',
                  icon: Icons.arrow_forward,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SignUpScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: const Text('Log in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.badge,
    required this.body,
    this.dark = false,
  });

  final IconData icon;
  final String title;
  final String badge;
  final String body;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: dark ? AppColors.primary : AppColors.neutral,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon,
                  color: dark ? Colors.white : AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(title, style: text.titleMedium)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: dark ? AppColors.primary : AppColors.neutral,
                          borderRadius:
                              BorderRadius.circular(AppRadii.pill),
                        ),
                        child: Text(badge,
                            style: text.labelSmall?.copyWith(
                                color: dark
                                    ? Colors.white
                                    : AppColors.secondary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(body, style: text.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
