import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onComplete});

  final Future<void> Function() onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _finishing = false;
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..addStatusListener(_onProgressStatus);

  @override
  void initState() {
    super.initState();
    _progress.forward();
  }

  Future<void> _onProgressStatus(AnimationStatus status) async {
    if (status != AnimationStatus.completed || !mounted || _finishing) return;
    _finishing = true;
    await widget.onComplete();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, _) => const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _progress
      ..removeStatusListener(_onProgressStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = Theme.of(context).colorScheme.onSurface;
    final secondary = Theme.of(context).colorScheme.onSurfaceVariant;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: dark
                    ? const [
                        Color(0xFF0D1624),
                        Color(0xFF111B2A),
                        Color(0xFF151A25),
                      ]
                    : const [
                        Color(0xFFFAFCFF),
                        Color(0xFFF0F6FF),
                        Color(0xFFEAF3FA),
                      ],
              ),
            ),
          ),
          const _SplashGlow(
            alignment: Alignment(1.1, -.95),
            color: Color(0xFF8CC4FF),
          ),
          const _SplashGlow(
            alignment: Alignment(-1, .9),
            color: Color(0xFF9FE9DE),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 116,
                        height: 116,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.blue.withValues(alpha: .24),
                              blurRadius: 36,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.asset(
                            'assets/app_icon/appicon.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      Text(
                        'PhoneCheck',
                        style: TextStyle(
                          color: foreground,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A clearer way to inspect your iPhone',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: secondary, fontSize: 14),
                      ),
                      const SizedBox(height: 52),
                      AnimatedBuilder(
                        animation: _progress,
                        builder: (context, _) => Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: LinearProgressIndicator(
                                value: _progress.value,
                                minHeight: 8,
                                backgroundColor: dark
                                    ? Colors.white.withValues(alpha: .12)
                                    : Colors.white.withValues(alpha: .72),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.blue,
                                ),
                              ),
                            ),
                            const SizedBox(height: 13),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Preparing your inspection',
                                    style: TextStyle(
                                      color: secondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${(_progress.value * 100).round()}%',
                                  style: TextStyle(
                                    color: foreground,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashGlow extends StatelessWidget {
  const _SplashGlow({required this.alignment, required this.color});

  final Alignment alignment;
  final Color color;

  @override
  Widget build(BuildContext context) => Align(
    alignment: alignment,
    child: Container(
      width: 440,
      height: 440,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: .32), color.withValues(alpha: 0)],
        ),
      ),
    ),
  );
}
