import 'package:flutter/material.dart';
import 'package:block_internet/screens/splash_screen.dart';
import 'package:block_internet/theme.dart';

void main() => runApp(const BlockerApp());

class BlockerApp extends StatelessWidget {
  const BlockerApp({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: themeNotifier,
        builder: (_, dark, __) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Block Internet Access',
          theme: buildTheme(dark),
          home: SplashScreen(),
        ),
      );
}
