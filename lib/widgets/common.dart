import 'package:flutter/material.dart';
import 'package:block_internet/theme.dart';

class AppSwitch extends StatelessWidget {
  AppSwitch({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    bool sel(Set<WidgetState> s) => s.contains(WidgetState.selected);
    return Switch(
      value: value,
      onChanged: onChanged,
      thumbIcon: WidgetStateProperty.resolveWith(
        (s) => sel(s) ? Icon(Icons.check, color: AppColors.accent) : null,
      ),
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => sel(s) ? AppColors.onAccent : Color(0xFF8A9796),
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => sel(s) ? AppColors.accent : Color(0xFF1B2021),
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => sel(s) ? AppColors.accent : Color(0xFF5F6B6A),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  PageHeader(this.title, this.subtitle, {super.key, this.actions = const []});
  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 14, 12, 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                    SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 13, color: AppColors.muted)),
                  ],
                ),
              ),
              ...actions,
            ],
          ),
        ),
      );
}

class Box extends StatelessWidget {
  Box({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );
}
