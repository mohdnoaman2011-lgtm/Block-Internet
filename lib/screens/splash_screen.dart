import 'package:flutter/material.dart';
import 'package:block_internet/home_shell.dart';
import 'package:block_internet/theme.dart';

class SplashScreen extends StatefulWidget {
  SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 2600),
  );
  late final Animation<double> _scale = CurvedAnimation(
    parent: _c,
    curve: Interval(0, 0.4, curve: Curves.easeOutBack),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _c,
    curve: Interval(0, 0.4, curve: Curves.easeOut),
  );
  late final Animation<double> _text = CurvedAnimation(
    parent: _c,
    curve: Interval(0.25, 0.6, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: Duration(milliseconds: 500),
            pageBuilder: (_, __, ___) => HomeShell(),
            transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
          ),
        );
      }
    });
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.9, -1.1),
              radius: 1.1,
              colors: [AppColors.accent.withAlpha(36), Colors.transparent],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Spacer(flex: 3),
                FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(36),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF26363A), Color(0xFF182523)],
                        ),
                        border: Border.all(color: AppColors.accent.withAlpha(96)),
                        boxShadow: [BoxShadow(color: AppColors.accent.withAlpha(46), blurRadius: 50)],
                      ),
                      child: Icon(Icons.wifi_off_rounded, size: 62, color: AppColors.accent),
                    ),
                  ),
                ),
                SizedBox(height: 28),
                FadeTransition(
                  opacity: _text,
                  child: Column(
                    children: [
                      Text(
                        'Block Internet\nAccess',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: -0.4),
                      ),
                      SizedBox(height: 8),
                      Text('Take control of every app\u2019s connection',
                          style: TextStyle(fontSize: 14, color: AppColors.muted)),
                    ],
                  ),
                ),
                Spacer(flex: 3),
                AnimatedBuilder(
                  animation: _c,
                  builder: (_, __) => SizedBox(
                    width: 140,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: _c.value,
                        minHeight: 4,
                        color: AppColors.accent,
                        backgroundColor: AppColors.tonal,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Text('Securing your connections\u2026',
                    style: TextStyle(fontSize: 12, color: AppColors.muted)),
                SizedBox(height: 18),
                Text('Version 1.0', style: TextStyle(fontSize: 11, color: Color(0xFF5F6F6D))),
                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      );
}
