// Block Internet Access: complete Flutter app in ONE file (Material 3, dark/light).
// Put this as lib/main.dart. Requires Flutter 3.22+ and the native Android code from main.yml.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  AppItem({
    required this.name,
    required this.package,
    this.icon,
    this.system = false,
    this.blocked = false,
  });

  final String name;
  final String package;
  Uint8List? icon;
  final bool system;
  bool blocked;

  String get letter => name.isEmpty ? '?' : name[0].toUpperCase();
}

// ===== services/block_service.dart =====
/// State kept by the native side (SharedPreferences) and read at startup.
class NativeState {
  NativeState({
    this.blocked = const <String>{},
    this.master = true,
    this.running = false,
    this.schedOn = false,
    this.start = 51,
    this.end = 111,
    this.days = 62,
    this.dark = true,
    this.boot = true,
    this.showSystem = false,
    this.timedUntil = 0,
    this.vpnGranted = false,
    this.error = '',
  });

  final Set<String> blocked;
  final bool master, running, schedOn, dark, boot, showSystem, vpnGranted;
  final int start, end, days, timedUntil;
  final String error;

  bool get timedActive => timedUntil > DateTime.now().millisecondsSinceEpoch;

  factory NativeState.fromMap(Map m) => NativeState(
        blocked: ((m['blocked'] as List?) ?? []).map((e) => e.toString()).toSet(),
        master: m['master'] as bool? ?? true,
        running: m['running'] as bool? ?? false,
        schedOn: m['schedOn'] as bool? ?? false,
        start: (m['start'] as num?)?.toInt() ?? 51,
        end: (m['end'] as num?)?.toInt() ?? 111,
        days: (m['days'] as num?)?.toInt() ?? 62,
        dark: m['dark'] as bool? ?? true,
        boot: m['boot'] as bool? ?? true,
        showSystem: m['showSystem'] as bool? ?? false,
        timedUntil: (m['timedUntil'] as num?)?.toInt() ?? 0,
        vpnGranted: m['vpnGranted'] as bool? ?? false,
        error: m['error'] as String? ?? '',
      );
}

/// Bridge to the Android side (PackageManager + local VpnService).
class BlockService {
  static const _ch = MethodChannel('blocker/native');
  static String lastError = '';

  static Future<T?> _call<T>(String method, [Object? args]) async {
    try {
      return await _ch.invokeMethod<T>(method, args);
    } catch (e) {
      lastError = e.toString();
      return null;
    }
  }

  static Future<NativeState> getState() async {
    final m = await _call<Map>('getState');
    return m == null ? NativeState() : NativeState.fromMap(m);
  }

  static List<AppItem> _parse(List l) => l.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return AppItem(
          name: m['name'] as String,
          package: m['package'] as String,
          system: m['system'] as bool? ?? false,
        );
      }).toList();

  /// Instant: the list saved by the previous run (empty on the very first launch).
  static Future<List<AppItem>> getCachedApps() async =>
      _parse(await _call<List>('getCachedApps') ?? []);

  /// Fresh list from the system: names + packages only (icons come later).
  static Future<List<AppItem>> getApps() async =>
      _parse(await _ch.invokeMethod<List>('getApps').timeout(Duration(seconds: 30)) ?? []);

  static Future<Map<String, Uint8List>> getIcons(List<String> packages) async {
    final m = await _call<Map>('getIcons', {'packages': packages});
    final out = <String, Uint8List>{};
    if (m != null) {
      m.forEach((k, v) {
        if (v is Uint8List) out[k as String] = v;
      });
    }
    return out;
  }

  /// Shows the system VPN permission dialog if needed. True when granted.
  static Future<bool> prepareVpn() async => await _call<bool>('prepareVpn') ?? false;

  static Future<void> setBlocked(Iterable<String> packages) =>
      _call('setBlocked', {'packages': packages.toList()});

  static Future<void> setMaster(bool on) => _call('setMaster', {'on': on});

  static Future<void> setSchedule(bool on, int start, int end, int days) =>
      _call('setSchedule', {'on': on, 'start': start, 'end': end, 'days': days});

  static Future<void> timedBlock(int minutes) => _call('timedBlock', {'minutes': minutes});

  static Future<void> setPref(String key, Object value) =>
      _call('setPref', {'key': key, 'value': value});

  static Future<void> openBatterySettings() => _call('openBatterySettings');

  static Future<void> openAppInfo(String package) => _call('openAppInfo', {'package': package});
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
class AppCard extends StatefulWidget {
  const AppCard({super.key, required this.app, required this.onChanged, required this.onInfo});
  final AppItem app;
  final ValueChanged<bool> onChanged;
  final VoidCallback onInfo;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool open = false;

  Widget _icon(AppItem a) => ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: a.icon != null
            ? Image.memory(a.icon!, width: 46, height: 46, gaplessPlayback: true)
            : Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                color: AppColors.tonal,
                child: Text(a.letter,
                    style: TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w600, color: AppColors.accent)),
              ),
      );

  @override
  Widget build(BuildContext context) {
    final a = widget.app;
    final on = a.blocked;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => open = !open),
      child: AnimatedSize(
        duration: Duration(milliseconds: 200),
        alignment: Alignment.topCenter,
        child: Container(
          margin: EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.fromLTRB(12, 12, 12, 12),
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
          child: Column(
            children: [
              Row(
                children: [
                  _icon(a),
                  SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600)),
                        Text(on ? 'Blocked \u00b7 Wi-Fi & data' : 'Allowed',
                            style: TextStyle(
                                fontSize: 12, color: on ? AppColors.accent2 : AppColors.sub)),
                      ],
                    ),
                  ),
                  Icon(open ? Icons.expand_less : Icons.expand_more, color: AppColors.muted),
                  SizedBox(width: 6),
                  AppSwitch(value: on, onChanged: widget.onChanged),
                ],
              ),
              if (open)
                Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(a.package,
                            style: TextStyle(fontSize: 12, color: AppColors.hint)),
                      ),
                      OutlinedButton.icon(
                        onPressed: widget.onInfo,
                        icon: Icon(Icons.info_outline, size: 18),
                        label: Text('App info'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== screens/apps_page.dart =====
class AppsPage extends StatefulWidget {
  const AppsPage({
    super.key,
    required this.title,
    required this.apps,
    required this.st,
    required this.onlyBlocked,
    required this.onToggle,
    required this.onMaster,
    required this.onTimer,
    required this.onInfo,
  });
  final String title;
  final List<AppItem> apps;
  final NativeState st;
  final bool onlyBlocked;
  final void Function(AppItem, bool) onToggle;
  final ValueChanged<bool> onMaster;
  final VoidCallback onTimer;
  final ValueChanged<AppItem> onInfo;

  @override
  State<AppsPage> createState() => _AppsPageState();
}

class _AppsPageState extends State<AppsPage> {
  String query = '';
  int chip = 0;
  bool blockedFirst = false;
  static const chips = ['All', 'Blocked', 'Allowed', 'System'];

  String subtitle(int n) {
    if (widget.onlyBlocked) return '$n apps in the block list';
    if (widget.st.running) return 'Protection on \u00b7 $n apps offline';
    if (n == 0) return 'Select apps to block';
    return 'Protection off \u00b7 $n apps selected';
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.apps.where((a) => a.blocked).length;
    var items = widget.apps
        .where((a) => a.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    if (widget.onlyBlocked) {
      items = items.where((a) => a.blocked).toList();
    } else if (chip == 1) {
      items = items.where((a) => a.blocked).toList();
    } else if (chip == 2) {
      items = items.where((a) => !a.blocked).toList();
    } else if (chip == 3) {
      items = items.where((a) => a.system).toList();
    } else if (!widget.st.showSystem) {
      items = items.where((a) => !a.system || a.blocked).toList();
    }
    if (blockedFirst) {
      items.sort((a, b) => (b.blocked ? 1 : 0) - (a.blocked ? 1 : 0));
    }

    return Column(
      children: [
        PageHeader(
          widget.title,
          subtitle(n),
          actions: [
            IconButton.filledTonal(
              onPressed: widget.onTimer,
              icon: Icon(Icons.timer_outlined),
              style: IconButton.styleFrom(backgroundColor: AppColors.tonal),
              tooltip: 'Timed block',
            ),
            SizedBox(width: 4),
            AppSwitch(value: widget.st.master, onChanged: widget.onMaster),
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
              PopupMenuButton<String>(
                tooltip: 'Sort',
                onSelected: (v) => setState(() => blockedFirst = v == 'blocked'),
                itemBuilder: (_) => [
                  CheckedPopupMenuItem(value: 'az', checked: !blockedFirst, child: Text('Sort A\u2013Z')),
                  CheckedPopupMenuItem(value: 'blocked', checked: blockedFirst, child: Text('Blocked first')),
                ],
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(Icons.filter_list_rounded),
                ),
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
                  color: chip == i ? AppColors.onAccent : AppColors.chipText,
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
          child: items.isEmpty
              ? Center(
                  child: Text(
                    widget.apps.isEmpty ? 'No apps found on this device' : 'No matching apps',
                    style: TextStyle(color: AppColors.muted),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final app = items[i];
                    return AppCard(
                      key: ValueKey(app.package),
                      app: app,
                      onChanged: (v) => widget.onToggle(app, v),
                      onInfo: () => widget.onInfo(app),
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
  const SchedulePage({super.key, required this.st, required this.onSchedule});
  final NativeState st;
  final Future<bool> Function(bool on, int start, int end, int days) onSchedule;

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  late int startMin = widget.st.start;
  late int endMin = widget.st.end;
  late bool on = widget.st.schedOn;
  late List<bool> days = List.generate(7, (i) => ((widget.st.days >> i) & 1) == 1);

  int get mask {
    var m = 0;
    for (var i = 0; i < 7; i++) {
      if (days[i]) m |= 1 << i;
    }
    return m;
  }

  int get durMin => ((endMin - startMin) % 1440 + 1440) % 1440;

  Future<void> pick(bool isStart) async {
    final cur = isStart ? startMin : endMin;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: cur ~/ 60, minute: cur % 60),
    );
    if (t == null) return;
    final v = t.hour * 60 + t.minute;
    setState(() => isStart ? startMin = v : endMin = v);
    if (on) widget.onSchedule(true, startMin, endMin, mask);
  }

  Future<void> toggle(bool v) async {
    final ok = await widget.onSchedule(v, startMin, endMin, mask);
    if (ok) setState(() => on = v);
  }

  Future<void> save() async {
    final ok = await widget.onSchedule(true, startMin, endMin, mask);
    if (ok) setState(() => on = true);
  }

  @override
  Widget build(BuildContext context) {
    final h = durMin ~/ 60, m = durMin % 60;
    final dur = h > 0 ? '$h h${m > 0 ? ' $m m' : ''}' : '$m m';
    final count = days.where((d) => d).length;
    return Column(
      children: [
        PageHeader('Schedule', 'Auto-block by time of day'),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 100),
            children: [
              Text(
                'Your selected apps lose internet at the start time and get it back at the end time.',
                style: TextStyle(fontSize: 14, height: 1.6, color: AppColors.muted),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _TimeCard('Start', startMin, () => pick(true))),
                  SizedBox(width: 12),
                  Expanded(child: _TimeCard('End', endMin, () => pick(false))),
                ],
              ),
              SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < 7; i++)
                    GestureDetector(
                      onTap: () {
                        setState(() => days[i] = !days[i]);
                        if (on) widget.onSchedule(true, startMin, endMin, mask);
                      },
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
                                color: days[i] ? AppColors.onAccent : AppColors.chipText)),
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
                        Text(count == 7 ? 'Every day' : '$count days a week',
                            style: TextStyle(color: AppColors.muted)),
                      ],
                    ),
                    SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (_, c) => Stack(
                        children: [
                          Container(
                            height: 10,
                            decoration: BoxDecoration(
                                color: AppColors.track, borderRadius: BorderRadius.circular(5)),
                          ),
                          Positioned(
                            left: c.maxWidth * startMin / 1440,
                            width: (c.maxWidth * durMin / 1440)
                                .clamp(6.0, c.maxWidth - c.maxWidth * startMin / 1440),
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(
                                  color: AppColors.accent, borderRadius: BorderRadius.circular(5)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('12 AM', style: TextStyle(fontSize: 11, color: AppColors.hint)),
                        Text('12 PM', style: TextStyle(fontSize: 11, color: AppColors.hint)),
                        Text('12 AM', style: TextStyle(fontSize: 11, color: AppColors.hint)),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Box(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Schedule enabled',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          Text('Applies to the apps you blocked',
                              style: TextStyle(fontSize: 12, color: AppColors.sub)),
                        ],
                      ),
                    ),
                    AppSwitch(value: on, onChanged: toggle),
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
                  onPressed: save,
                  child: Text('SET SCHEDULE'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimeCard extends StatelessWidget {
  _TimeCard(this.label, this.minutes, this.onTap);
  final String label;
  final int minutes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hour = minutes ~/ 60;
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    final txt = '${h12.toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
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
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: -0.5)),
                SizedBox(width: 5),
                Text(hour < 12 ? 'AM' : 'PM',
                    style: TextStyle(fontSize: 14, color: AppColors.muted)),
              ],
            ),
            SizedBox(height: 4),
            Text('Tap to change', style: TextStyle(fontSize: 11, color: AppColors.hint)),
          ],
        ),
      ),
    );
  }
}

// ===== screens/settings_page.dart =====
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.st, required this.onPref, required this.onVpn});
  final NativeState st;
  final void Function(String key, bool value) onPref;
  final Future<bool> Function() onVpn;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          PageHeader('Settings', 'Customize how blocking works'),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 100),
              children: [
                _label('Appearance'),
                Container(
                  padding: EdgeInsets.all(6),
                  margin: EdgeInsets.only(bottom: 16),
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
                _label('Behavior'),
                _group([
                  _tile(Icons.power_settings_new, 'Start on boot', 'Resume protection after restart',
                      sw: st.boot, on: (v) => onPref('boot', v)),
                  _tile(Icons.apps, 'Show system apps', 'Include system apps in the list',
                      sw: st.showSystem, on: (v) => onPref('showSystem', v)),
                ]),
                _label('General'),
                _group([
                  _tile(Icons.vpn_key_outlined, 'VPN permission',
                      'Needed to block apps (a key icon shows while active)',
                      trailing: st.vpnGranted ? 'Granted' : 'Request', onTap: onVpn),
                  _tile(Icons.shield_outlined, 'Protection status', 'Is the blocking VPN running now?',
                      trailing: st.running ? 'Active' : 'Stopped'),
                  _tile(Icons.battery_saver_outlined, 'Keep running in background',
                      'Allow unrestricted battery use (needed on some phones)',
                      trailing: 'Open', onTap: () => BlockService.openBatterySettings()),
                  _tile(Icons.info_outline, 'About', 'Version 1.0', onTap: () async {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Block Internet Access',
                      applicationVersion: '1.0',
                      children: [
                        Text('Blocks internet access for the apps you choose using a local VPN. '
                            'No traffic leaves your device and nothing is collected.'),
                      ],
                    );
                  }),
                ]),
              ],
            ),
          ),
        ],
      );

  Widget _label(String t) => Padding(
        padding: EdgeInsets.only(left: 4, bottom: 6),
        child: Text(t.toUpperCase(),
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: AppColors.accent)),
      );

  Widget _mode(String label, IconData icon, bool dark) {
    final sel = AppColors.dark == dark;
    final fg = sel ? AppColors.onAccent : AppColors.muted;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setDark(dark);
          BlockService.setPref('dark', dark);
        },
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

  Widget _group(List<Widget> rows) => Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) Divider(height: 1, color: AppColors.border),
              rows[i],
            ],
          ],
        ),
      );

  Widget _tile(IconData icon, String title, String sub,
      {bool? sw, ValueChanged<bool>? on, String? trailing, Future<dynamic> Function()? onTap}) {
    return InkWell(
      onTap: sw == null && onTap != null ? () => onTap() : null,
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration:
                    BoxDecoration(color: AppColors.tonal, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, size: 19, color: AppColors.accent2),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    if (sub.isNotEmpty)
                      Text(sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: AppColors.sub)),
                  ],
                ),
              ),
              if (sw != null)
                AppSwitch(value: sw, onChanged: on)
              else ...[
                if (trailing != null)
                  Text(trailing, style: TextStyle(fontSize: 13, color: AppColors.muted)),
                Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ],
          ),
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
    duration: Duration(milliseconds: 1600),
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
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int tab = 0;
  bool loading = true;
  List<AppItem> apps = [];
  NativeState st = NativeState();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    themeNotifier.addListener(refresh);
    load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    themeNotifier.removeListener(refresh);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) reloadState();
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  void say(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m), duration: Duration(seconds: 2)));
  }

  Future<void> reloadState() async {
    st = await BlockService.getState();
    refresh();
  }

  String? loadError;
  bool _iconsBusy = false;

  void _setApps(List<AppItem> list) {
    final old = {for (final a in apps) a.package: a.icon};
    for (final a in list) {
      a.blocked = st.blocked.contains(a.package);
      a.icon = old[a.package];
    }
    apps = list;
  }

  Future<void> load() async {
    loadError = null;
    if (apps.isEmpty) loading = true;
    refresh();
    st = await BlockService.getState();
    // 1) instant: the list saved by the previous run
    if (apps.isEmpty) {
      final cached = await BlockService.getCachedApps();
      if (cached.isNotEmpty) {
        _setApps(cached);
        loading = false;
        refresh();
      }
    }
    // 2) fresh list from the system
    try {
      _setApps(await BlockService.getApps());
    } catch (e) {
      if (apps.isEmpty) loadError = e.toString();
    }
    loading = false;
    refresh();
    loadIcons();
  }

  /// Icons arrive in batches so the list is usable immediately.
  Future<void> loadIcons() async {
    if (_iconsBusy) return;
    _iconsBusy = true;
    try {
      final todo = apps.where((a) => a.icon == null).map((a) => a.package).toList();
      for (var i = 0; i < todo.length && mounted; i += 30) {
        final end = i + 30 > todo.length ? todo.length : i + 30;
        final icons = await BlockService.getIcons(todo.sublist(i, end));
        for (final a in apps) {
          final ic = icons[a.package];
          if (ic != null) a.icon = ic;
        }
        refresh();
      }
    } finally {
      _iconsBusy = false;
    }
  }

  Future<bool> ensureVpn() async {
    final ok = await BlockService.prepareVpn();
    if (!ok) say('VPN permission is required to block apps');
    await reloadState();
    return ok;
  }

  /// After asking for blocking, check that the VPN really came up.
  Future<void> verifyRunning() async {
    await Future.delayed(Duration(milliseconds: 900));
    await reloadState();
    final wanted = st.blocked.isNotEmpty && (st.master || st.timedActive);
    if (wanted && !st.running) {
      final why = st.error.isNotEmpty ? st.error : BlockService.lastError;
      say('Blocking did not start${why.isEmpty ? '' : ': $why'}');
    }
  }

  Future<void> toggleApp(AppItem a, bool v) async {
    if (v && !await ensureVpn()) return;
    a.blocked = v;
    refresh();
    await BlockService.setBlocked(apps.where((x) => x.blocked).map((x) => x.package));
    if (v) {
      await verifyRunning();
    } else {
      await reloadState();
    }
  }

  Future<void> setMaster(bool v) async {
    if (v && !await ensureVpn()) return;
    await BlockService.setMaster(v);
    if (v) {
      await verifyRunning();
    } else {
      await reloadState();
    }
  }

  int _minsToMorning() {
    final n = DateTime.now();
    var t = DateTime(n.year, n.month, n.day, 7);
    if (!t.isAfter(n)) t = t.add(Duration(days: 1));
    return t.difference(n).inMinutes;
  }

  Future<void> timer() async {
    final opts = <List<Object>>[
      ['15 minutes', 15],
      ['1 hour', 60],
      ['4 hours', 240],
      ['Until tomorrow morning', _minsToMorning()],
    ];
    final pick = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Block selected apps for\u2026',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ),
            ),
            for (final o in opts)
              ListTile(
                leading: Icon(Icons.timer_outlined, color: AppColors.accent),
                title: Text(o[0] as String),
                onTap: () => Navigator.pop(ctx, o[1] as int),
              ),
            if (st.timedActive)
              ListTile(
                leading: Icon(Icons.close, color: AppColors.accent),
                title: Text('Cancel timed block'),
                onTap: () => Navigator.pop(ctx, -1),
              ),
          ],
        ),
      ),
    );
    if (pick == null) return;
    if (pick < 0) {
      await BlockService.timedBlock(0);
      await reloadState();
      say('Timed block cancelled');
      return;
    }
    if (!apps.any((a) => a.blocked)) {
      say('Select the apps to block first');
      return;
    }
    if (!await ensureVpn()) return;
    await BlockService.timedBlock(pick);
    await reloadState();
    say('Selected apps are blocked for ${o0(pick)}');
  }

  String o0(int m) => m < 60 ? '$m minutes' : '${(m / 60).toStringAsFixed(m % 60 == 0 ? 0 : 1)} hours';

  Future<bool> schedule(bool on, int s, int e, int d) async {
    if (on && !await ensureVpn()) return false;
    await BlockService.setSchedule(on, s, e, d);
    await reloadState();
    if (!on) {
      say('Schedule turned off');
    } else if (!apps.any((a) => a.blocked)) {
      say('Schedule saved. Select the apps to block');
    } else {
      say('Schedule saved');
    }
    return true;
  }

  Future<void> setPref(String key, bool v) async {
    await BlockService.setPref(key, v);
    await reloadState();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      AppsPage(
        title: 'Block Internet Access',
        apps: apps,
        st: st,
        onlyBlocked: false,
        onToggle: toggleApp,
        onMaster: setMaster,
        onTimer: timer,
        onInfo: (a) => BlockService.openAppInfo(a.package),
      ),
      AppsPage(
        title: 'Blocked Apps',
        apps: apps,
        st: st,
        onlyBlocked: true,
        onToggle: toggleApp,
        onMaster: setMaster,
        onTimer: timer,
        onInfo: (a) => BlockService.openAppInfo(a.package),
      ),
      SchedulePage(st: st, onSchedule: schedule),
      SettingsPage(st: st, onPref: setPref, onVpn: ensureVpn),
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
          SafeArea(
            bottom: false,
            child: loading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.accent),
                        SizedBox(height: 16),
                        Text('Loading apps\u2026', style: TextStyle(color: AppColors.muted)),
                      ],
                    ),
                  )
                : loadError != null
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Could not load the apps list',
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                              SizedBox(height: 8),
                              Text(loadError!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: AppColors.muted)),
                              SizedBox(height: 16),
                              FilledButton(onPressed: load, child: Text('Retry')),
                            ],
                          ),
                        ),
                      )
                    : IndexedStack(index: tab, children: pages),
          ),
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
            indicatorColor: AppColors.navActive,
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
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final st = await BlockService.getState();
  setDark(st.dark);
  runApp(const BlockerApp());
}

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

// Alias so the default test generated by `flutter create` (which uses MyApp) still compiles.
typedef MyApp = BlockerApp;
