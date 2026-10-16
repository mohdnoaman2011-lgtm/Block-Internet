// Block Internet Access: complete Flutter app in ONE file (Material 3, dark/light).
// Put this as lib/main.dart. Requires Flutter 3.22+.

import 'package:flutter/material.dart';

// ===== theme.dart =====
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

// ===== models/app_item.dart =====
class AppItem {
  AppItem(this.name, this.colors, {this.blocked = false, this.system = false});
  final String name;
  final List<Color> colors;
  final bool system;
  bool blocked;
  String get letter => name[0];
}

// ===== services/block_service.dart =====
/// Hook for the native side (VpnService). Implement with a MethodChannel.
class BlockService {
  static Future<void> setBlocked(String app, bool blocked) async {}
  static Future<void> setMaster(bool on) async {}
  static Future<void> schedule(TimeOfDay start, TimeOfDay end, List<bool> days) async {}
}

// ===== widgets/common.dart =====
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

// ===== widgets/app_card.dart =====
class AppCard extends StatelessWidget {
  AppCard({super.key, required this.app, required this.onChanged});
  final AppItem app;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final on = app.blocked;
    return Container(
      height: 72,
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.fromLTRB(12, 0, 12, 0),
      decoration: BoxDecoration(
        color: AppColors.card,
        gradient: on
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.accent.withAlpha(40), AppColors.accent.withAlpha(10)],
              )
            : null,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: on ? AppColors.accent.withAlpha(96) : AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(colors: app.colors),
            ),
            child: Text(app.letter,
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600)),
                Text(on ? 'Blocked \u00b7 Wi-Fi & data' : 'Allowed',
                    style: TextStyle(
                        fontSize: 12, color: on ? Color(0xFFA6CFC6) : Color(0xFF7F8E8C))),
              ],
            ),
          ),
          Icon(Icons.expand_more, color: AppColors.muted),
          SizedBox(width: 6),
          AppSwitch(value: on, onChanged: onChanged),
        ],
      ),
    );
  }
}

// ===== screens/apps_page.dart =====
class AppsPage extends StatefulWidget {
  AppsPage({
    super.key,
    required this.title,
    required this.apps,
    required this.onlyBlocked,
    required this.masterOn,
    required this.onMaster,
    required this.onChanged,
  });
  final String title;
  final List<AppItem> apps;
  final bool onlyBlocked;
  final bool masterOn;
  final ValueChanged<bool> onMaster;
  final VoidCallback onChanged;

  @override
  State<AppsPage> createState() => _AppsPageState();
}

class _AppsPageState extends State<AppsPage> {
  String query = '';
  int chip = 0;
  static const chips = ['All', 'Blocked', 'Allowed', 'System'];

  @override
  Widget build(BuildContext context) {
    final blockedCount = widget.apps.where((a) => a.blocked).length;
    Iterable<AppItem> list =
        widget.apps.where((a) => a.name.toLowerCase().contains(query.toLowerCase()));
    if (widget.onlyBlocked) {
      list = list.where((a) => a.blocked);
    } else {
      if (chip == 1) list = list.where((a) => a.blocked);
      if (chip == 2) list = list.where((a) => !a.blocked);
      if (chip == 3) list = list.where((a) => a.system);
    }
    final items = list.toList();

    return Column(
      children: [
        PageHeader(
          widget.title,
          widget.onlyBlocked
              ? '$blockedCount apps can\u2019t reach the internet'
              : 'Protection ${widget.masterOn ? 'on' : 'off'} \u00b7 $blockedCount apps offline',
          actions: [
            IconButton.filledTonal(
              onPressed: () {},
              icon: Icon(Icons.timer_outlined),
              style: IconButton.styleFrom(backgroundColor: AppColors.tonal),
              tooltip: 'Timed block',
            ),
            SizedBox(width: 4),
            AppSwitch(value: widget.masterOn, onChanged: widget.onMaster),
          ],
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => query = v),
                  decoration: InputDecoration(
                    hintText: 'Search apps\u2026',
                    hintStyle: TextStyle(color: AppColors.muted),
                    prefixIcon: Icon(Icons.search, color: AppColors.accent),
                    filled: true,
                    fillColor: AppColors.card,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(Icons.filter_list_rounded),
              ),
            ],
          ),
        ),
        if (!widget.onlyBlocked)
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: chips.length,
              separatorBuilder: (_, __) => SizedBox(width: 8),
              itemBuilder: (_, i) => ChoiceChip(
                label: Text(chips[i]),
                selected: chip == i,
                showCheckmark: false,
                selectedColor: AppColors.accent,
                backgroundColor: AppColors.card,
                side: BorderSide(color: AppColors.border),
                labelStyle: TextStyle(
                  color: chip == i ? AppColors.onAccent : Color(0xFFB6C4C2),
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onSelected: (_) => setState(() => chip = i),
              ),
            ),
          )
        else
          SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 100),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final app = items[i];
              return AppCard(
                app: app,
                onChanged: (v) {
                  app.blocked = v;
                  BlockService.setBlocked(app.name, v);
                  widget.onChanged();
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ===== screens/schedule_page.dart =====
class SchedulePage extends StatefulWidget {
  SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  TimeOfDay start = const TimeOfDay(hour: 0, minute: 51);
  TimeOfDay end = const TimeOfDay(hour: 1, minute: 51);
  final days = [true, true, true, true, true, false, false];

  int get startMin => start.hour * 60 + start.minute;
  int get durMin => ((end.hour * 60 + end.minute) - startMin + 1440) % 1440;

  Future<void> pick(bool isStart) async {
    final t = await showTimePicker(context: context, initialTime: isStart ? start : end);
    if (t != null) setState(() => isStart ? start = t : end = t);
  }

  @override
  Widget build(BuildContext context) {
    final h = durMin ~/ 60, m = durMin % 60;
    final dur = h > 0 ? '$h h${m > 0 ? ' $m m' : ''}' : '$m m';
    return ListView(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 100),
      children: [
        PageHeader('Schedule', 'Auto-block by time of day').withoutSidePadding(),
        SizedBox(height: 10),
        Text(
          'Internet is blocked at the start time and restored at the end time. '
          'After a restart, tap Stop Blocking and reschedule.',
          style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFFA9B8B6)),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _TimeCard('Start', start, () => pick(true))),
            SizedBox(width: 12),
            Expanded(child: _TimeCard('End', end, () => pick(false))),
          ],
        ),
        SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < 7; i++)
              GestureDetector(
                onTap: () => setState(() => days[i] = !days[i]),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: days[i] ? AppColors.accent : AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: days[i] ? AppColors.accent : AppColors.border),
                  ),
                  child: Text('SMTWTFS'[i],
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: days[i] ? AppColors.onAccent : Color(0xFFB6C4C2))),
                ),
              ),
          ],
        ),
        SizedBox(height: 14),
        Box(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Blocks for $dur', style: TextStyle(fontWeight: FontWeight.w700)),
                  Text('Selected days', style: TextStyle(color: AppColors.muted)),
                ],
              ),
              SizedBox(height: 14),
              LayoutBuilder(
                builder: (_, c) => Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                          color: Color(0xFF232A2B), borderRadius: BorderRadius.circular(5)),
                    ),
                    Positioned(
                      left: c.maxWidth * startMin / 1440,
                      width: (c.maxWidth * durMin / 1440).clamp(6.0, c.maxWidth),
                      child: Container(
                        height: 10,
                        decoration:
                            BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(5)),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('12 AM', style: TextStyle(fontSize: 11, color: Color(0xFF6F7F7D))),
                  Text('12 PM', style: TextStyle(fontSize: 11, color: Color(0xFF6F7F7D))),
                  Text('12 AM', style: TextStyle(fontSize: 11, color: Color(0xFF6F7F7D))),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        Box(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Apply to blocked apps',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    Text('Tap to choose apps', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
        SizedBox(height: 16),
        SizedBox(
          height: 58,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.onAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(29)),
              textStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0.8),
            ),
            onPressed: () {
              BlockService.schedule(start, end, days);
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Schedule set')));
            },
            child: Text('SET SCHEDULE'),
          ),
        ),
      ],
    );
  }
}

extension on Widget {
  // The header already has its own padding; keep list padding from doubling.
  Widget withoutSidePadding() => Transform.translate(offset: Offset(-8, 0), child: this);
}

class _TimeCard extends StatelessWidget {
  _TimeCard(this.label, this.time, this.onTap);
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final h = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final txt = '${h.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: Box(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(color: AppColors.accent, fontSize: 14, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(txt,
                    style: TextStyle(
                        fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: -0.5)),
                SizedBox(width: 5),
                Text(time.period == DayPeriod.am ? 'AM' : 'PM',
                    style: TextStyle(fontSize: 14, color: AppColors.muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ===== screens/settings_page.dart =====
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

// ===== screens/splash_screen.dart =====
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

// ===== home_shell.dart =====
class HomeShell extends StatefulWidget {
  HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int tab = 0;
  bool masterOn = true;
  final apps = <AppItem>[
    AppItem('Browser Lite', [Color(0xFF7E7FB8), Color(0xFF7FB0BD)]),
    AppItem('Tunnel VPN', [Color(0xFF7A6A9A), Color(0xFFA98BB8)]),
    AppItem('Secure Link', [Color(0xFF2F3D5E), Color(0xFF2F3D5E)]),
    AppItem('PDF Reader', [Color(0xFFA55A52), Color(0xFFA55A52)], blocked: true),
    AppItem('Muslim Pattern', [Color(0xFF8E6F99), Color(0xFFC98FA3)], blocked: true),
    AppItem('Anime Rift Game', [Color(0xFF2B2B2E), Color(0xFF2B2B2E)]),
    AppItem('Watch Anime', [Color(0xFF1A1A1A), Color(0xFF1A1A1A)], blocked: true),
    AppItem('Remote Desk', [Color(0xFFC26B60), Color(0xFFC26B60)], blocked: true),
    AppItem('Phone Settings', [Color(0xFF3A4547), Color(0xFF3A4547)], system: true),
  ];

  void refresh() => setState(() {});

  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(refresh);
  }

  @override
  void dispose() {
    themeNotifier.removeListener(refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      AppsPage(
        title: 'Block Internet Access',
        apps: apps,
        onlyBlocked: false,
        masterOn: masterOn,
        onMaster: (v) {
          masterOn = v;
          BlockService.setMaster(v);
          refresh();
        },
        onChanged: refresh,
      ),
      AppsPage(
        title: 'Blocked Apps',
        apps: apps,
        onlyBlocked: true,
        masterOn: masterOn,
        onMaster: (v) {
          masterOn = v;
          BlockService.setMaster(v);
          refresh();
        },
        onChanged: refresh,
      ),
      SchedulePage(),
      SettingsPage(),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.9, -1.1),
                  radius: 1.0,
                  colors: [AppColors.accent.withAlpha(36), Colors.transparent],
                ),
              ),
            ),
          ),
          IndexedStack(index: tab, children: pages),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: EdgeInsets.fromLTRB(14, 0, 14, 12),
          decoration: BoxDecoration(
            color: AppColors.navBg,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.navBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: NavigationBar(
            height: 70,
            backgroundColor: Colors.transparent,
            indicatorColor: Color(0xFF2F4A47),
            selectedIndex: tab,
            onDestinationSelected: (i) => setState(() => tab = i),
            destinations: [
              NavigationDestination(icon: Icon(Icons.list_rounded), label: 'Apps'),
              NavigationDestination(icon: Icon(Icons.block), label: 'Blocked'),
              NavigationDestination(icon: Icon(Icons.timer_outlined), label: 'Schedule'),
              NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== main.dart =====
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
