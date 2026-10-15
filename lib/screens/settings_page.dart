import 'package:flutter/material.dart';
import 'package:block_internet/theme.dart';
import 'package:block_internet/widgets/common.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool wifi = true, data = true, roam = false, boot = true, notif = true, newApps = false;

  @override
  Widget build(BuildContext context) => ListView(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 100),
        children: [
          PageHeader('Settings', 'Customize how blocking works'),
          SizedBox(height: 14),
          _appearance(),
          _group('Blocking', [
            _tile(Icons.wifi, 'Block Wi-Fi', 'Cut Wi-Fi for blocked apps', sw: wifi, on: (v) => wifi = v),
            _tile(Icons.signal_cellular_alt, 'Block mobile data', 'Cut cellular for blocked apps',
                sw: data, on: (v) => data = v),
            _tile(Icons.public, 'Block roaming', 'Only while abroad', sw: roam, on: (v) => roam = v),
          ]),
          _group('Behavior', [
            _tile(Icons.power_settings_new, 'Start on boot', 'Resume protection after restart',
                sw: boot, on: (v) => boot = v),
            _tile(Icons.notifications_none, 'Show notification', 'Status in the notification bar',
                sw: notif, on: (v) => notif = v),
            _tile(Icons.add_box_outlined, 'Block new apps', 'Auto-block newly installed apps',
                sw: newApps, on: (v) => newApps = v),
          ]),
          _group('General', [
            _tile(Icons.lock_outline, 'App lock', 'PIN or fingerprint', trailing: 'Off'),
            _tile(Icons.dark_mode_outlined, 'Theme', 'Match the system', trailing: 'Dark'),
            _tile(Icons.translate, 'Language', '', trailing: 'English'),
            _tile(Icons.info_outline, 'About', 'Version 1.0', trailing: ''),
          ]),
        ],
      );

  Widget _appearance() => Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 4, bottom: 6),
              child: Text('APPEARANCE',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: AppColors.accent)),
            ),
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  _mode('Dark', Icons.dark_mode_outlined, true),
                  SizedBox(width: 6),
                  _mode('Light', Icons.light_mode_outlined, false),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _mode(String label, IconData icon, bool dark) {
    final sel = AppColors.dark == dark;
    final fg = sel ? AppColors.onAccent : AppColors.muted;
    return Expanded(
      child: GestureDetector(
        onTap: () => setDark(dark),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          height: 46,
          decoration: BoxDecoration(
            color: sel ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: fg),
              SizedBox(width: 8),
              Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: fg)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _group(String label, List<Widget> rows) => Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 4, bottom: 6),
              child: Text(label.toUpperCase(),
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: AppColors.accent)),
            ),
            Box(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: AppColors.border),
                    rows[i],
                  ],
                ],
              ),
            ),
          ],
        ),
      );

  Widget _tile(IconData icon, String title, String sub,
      {bool? sw, ValueChanged<bool>? on, String? trailing}) {
    return SizedBox(
      height: 62,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration:
                  BoxDecoration(color: AppColors.tonal, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 19, color: Color(0xFFA6CFC6)),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  if (sub.isNotEmpty)
                    Text(sub, style: TextStyle(fontSize: 12, color: Color(0xFF7F8E8C))),
                ],
              ),
            ),
            if (sw != null)
              AppSwitch(value: sw, onChanged: (v) => setState(() => on!(v)))
            else ...[
              if (trailing != null && trailing.isNotEmpty)
                Text(trailing, style: TextStyle(fontSize: 13, color: AppColors.muted)),
              Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ],
        ),
      ),
    );
  }
}
