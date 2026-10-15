import 'package:flutter/material.dart';

/// Dark / light switch. Call [setDark] to change the whole app.
final ValueNotifier<bool> themeNotifier = ValueNotifier<bool>(true);

void setDark(bool value) {
  AppColors.dark = value;
  themeNotifier.value = value;
}

class AppColors {
  static bool dark = true;
  static Color _p(int d, int l) => Color(dark ? d : l);

  static Color get bg => _p(0xFF12161A, 0xFFF3F6F5);
  static Color get card => _p(0xFF161A1B, 0xFFFFFFFF);
  static Color get border => _p(0xFF242B2C, 0xFFDCE4E2);
  static Color get muted => _p(0xFF8FA3A1, 0xFF5F7270);
  static Color get accent => _p(0xFF8FBFB5, 0xFF3F7D72);
  static Color get accent2 => _p(0xFFA6CFC6, 0xFF3F7D72);
  static Color get onAccent => _p(0xFF10231F, 0xFFFFFFFF);
  static Color get tonal => _p(0xFF212A2B, 0xFFE3EEEB);
  static Color get chipText => _p(0xFFB6C4C2, 0xFF5F7270);
  static Color get sub => _p(0xFF7F8E8C, 0xFF6B7C7A);
  static Color get hint => _p(0xFF6F7F7D, 0xFF7F908E);
  static Color get track => _p(0xFF232A2B, 0xFFE3EEEB);
  static Color get navActive => _p(0xFF2F4A47, 0xFFD3E8E3);
  static Color get navBg => _p(0xE01B2627, 0xF0FFFFFF);
  static Color get navBorder => _p(0x17FFFFFF, 0xFFDCE4E2);
  static Color get knobOff => _p(0xFF8A9796, 0xFF7F908E);
  static Color get switchOff => _p(0xFF1B2021, 0xFFEEF3F2);
  static Color get switchOutline => _p(0xFF5F6B6A, 0xFF8FA09E);
  static Color get logoA => _p(0xFF26363A, 0xFFFFFFFF);
  static Color get logoB => _p(0xFF182523, 0xFFE3EEEB);
}

ThemeData buildTheme(bool dark) => ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: dark ? Brightness.dark : Brightness.light,
        surface: AppColors.bg,
      ),
      // Add the Rubik font (google_fonts or assets) for the exact look.
    );
