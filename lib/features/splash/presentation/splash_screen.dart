import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          context.go(AppRoutes.onboarding);
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0E05),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            color: const Color(0xFF1A0E05),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1. Frame / Room background
                  SizedBox(
                    width: double.infinity,
                    child: Image.asset(
                      'assets/images/splash/frame .png',
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                  // 2. Family sitting on couch
                  SizedBox(
                    width: double.infinity,
                    child: Image.asset(
                      'assets/images/splash/family.png',
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                  // 3. Logo on TV screen
                  SizedBox(
                    width: double.infinity,
                    child: Image.asset(
                      'assets/images/splash/logo2.png',
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                  // 4. Popcorn in front
                  SizedBox(
                    width: double.infinity,
                    child: Image.asset(
                      'assets/images/splash/popcorn.png',
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
