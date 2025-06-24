import 'package:flutter/material.dart';
import 'package:ramstech/auth/login_page.dart';
import 'package:ramstech/pages/home_page.dart';
import 'package:ramstech/pages/onboarding_page.dart';
import 'package:ramstech/services/firebase_auth_service.dart';
import 'package:ramstech/services/preferences_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _opacity = 1.0;
      });
    }
    await Future.delayed(const Duration(seconds: 5));

    final isLoggedIn = await FirebaseAuthMethod.isUserLoggedIn();
    final hasSeenOnboarding = await PreferencesService.hasSeenOnboarding();

    if (mounted) {
      if (isLoggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else if (!hasSeenOnboarding) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OnboardingPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(seconds: 2),
          child: Image.asset(
            Theme.of(context).brightness == Brightness.dark
                ? 'assets/logo/dark-logo-transparent.png'
                : 'assets/logo/logo-transparent.png',
            width: MediaQuery.sizeOf(context).width *
                0.7, // Adjust the size as needed
          ),
        ),
      ),
    );
  }
}
