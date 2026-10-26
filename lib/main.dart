// Block Internet Access: complete Flutter app in ONE file (Material 3, Indigo design, dark/light).
// Put this as lib/main.dart. Requires Flutter 3.22+ and the native Android code from main.yml.

import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ===== theme.dart =====
/// Bumped on every theme change so the whole app rebuilds.
final ValueNotifier<int> themeNotifier = ValueNotifier<int>(0);

/// mode: 0 = follow the system, 1 = dark, 2 = light. accent: index in [AppColors.accentNames].
void applyTheme({int? mode, int? accent}) {
  if (mode != null) AppColors.mode = mode;
  if (accent != null) AppColors.accentIndex = accent.clamp(0, AppColors.accentNames.length - 1).toInt();
  final sys = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  AppColors.dark = AppColors.mode == 1 || (AppColors.mode == 0 && sys);
  themeNotifier.value++;
}

class AppColors {
  static bool dark = true;
  static int mode = 0;
  static int accentIndex = 0;
  static Color _p(int d, int l) => Color(dark ? d : l);

  static const accentNames = ['Indigo', 'Sage', 'Ocean', 'Lavender', 'Sand', 'Rose'];
  static const _accents = [
    [0xFF8B7CFF, 0xFF5B4BD6],
    [0xFF8FBFB5, 0xFF3F7D72],
    [0xFF8BB8E8, 0xFF2F6EA8],
    [0xFFB4A7E6, 0xFF6B58B8],
    [0xFFE0C48A, 0xFF9A7A2E],
    [0xFFE8A0B0, 0xFFB04A62],
  ];
  static Color accentFor(int i, bool d) => Color(_accents[i][d ? 0 : 1]);

  static Color get bg => _p(0xFF0B0D1A, 0xFFF4F5FD);
  static Color get card => _p(0xFF14172B, 0xFFFFFFFF);
  static Color get border => _p(0xFF23274A, 0xFFDDE0F3);
  static Color get muted => _p(0xFF8B90B3, 0xFF6A6F93);
  static Color get accent => accentFor(accentIndex, dark);
  static Color get coral => _p(0xFFFF8A7A, 0xFFD9604F);
  static Color get accent2 => dark ? Color.lerp(accent, Colors.white, 0.22)! : accent;
  static Color get onAccent => accent.computeLuminance() > 0.45 ? Color(0xFF0E0B2B) : Colors.white;
  static Color get tonal => _p(0xFF1C2040, 0xFFE8EAFB);
  static Color get chipText => _p(0xFFB4B8DA, 0xFF5A5F86);
  static Color get sub => _p(0xFF7E83A8, 0xFF6F7498);
  static Color get hint => _p(0xFF6B7096, 0xFF8A8FB0);
  static Color get track => _p(0xFF1C2040, 0xFFE8EAFB);
  static Color get navActive => Color.lerp(bg, accent, dark ? 0.28 : 0.22)!;
  static Color get navBg => _p(0xE614172B, 0xF0FFFFFF);
  static Color get navBorder => _p(0x12FFFFFF, 0xFFDDE0F3);
  static Color get knobOff => _p(0xFF5C628F, 0xFF9AA0C4);
  static Color get switchOff => _p(0xFF1C2040, 0xFFEEF0FC);
  static Color get switchOutline => _p(0xFF3A4075, 0xFF9AA0C4);
  static Color get logoA => _p(0xFF1B1F45, 0xFFFFFFFF);
  static Color get logoB => _p(0xFF0F1230, 0xFFE8EAFB);
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
    this.category = 'Other',
  });

  final String name;
  final String package;
  Uint8List? icon;
  final bool system;
  final String category;
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
    this.themeMode = 0,
    this.accent = 0,
  });

  final Set<String> blocked;
  final bool master, running, schedOn, dark, boot, showSystem, vpnGranted;
  final int start, end, days, timedUntil;
  final String error;
  final int themeMode, accent;

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
        themeMode: (m['themeMode'] as num?)?.toInt() ?? 0,
        accent: (m['accent'] as num?)?.toInt() ?? 0,
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
          category: m['cat'] as String? ?? 'Other',
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
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => sel(s) ? Colors.white : AppColors.knobOff,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => sel(s) ? AppColors.accent : AppColors.switchOff,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => sel(s) ? AppColors.accent : AppColors.switchOutline,
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
          padding: EdgeInsets.fromLTRB(20, 14, 14, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.muted)),
                    Text(title,
                        style: TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
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
  const AppCard({
    super.key,
    required this.app,
    required this.running,
    required this.onChanged,
    required this.onInfo,
  });
  final AppItem app;
  final bool running;
  final ValueChanged<bool> onChanged;
  final VoidCallback onInfo;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool open = false;

  Widget _icon(AppItem a) => ClipRRect(
        borderRadius: BorderRadius.circular(16),
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
    final sub = on ? (widget.running ? 'Blocked \u00b7 always' : 'Selected \u00b7 protection paused') : 'Allowed';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => open = !open),
      child: AnimatedSize(
        duration: Duration(milliseconds: 200),
        alignment: Alignment.topCenter,
        child: Container(
          margin: EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.fromLTRB(10, 11, 14, 11),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: on ? AppColors.accent : AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _icon(a),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(a.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600)),
                            ),
                            if (on)
                              Container(
                                margin: EdgeInsets.only(left: 8),
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.coral.withAlpha(40),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('BLOCKED',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                        color: AppColors.coral)),
                              ),
                          ],
                        ),
                        Text(sub, style: TextStyle(fontSize: 12, color: AppColors.muted)),
                      ],
                    ),
                  ),
                  Icon(open ? Icons.expand_less : Icons.expand_more, color: AppColors.muted, size: 22),
                  SizedBox(width: 4),
                  AppSwitch(value: on, onChanged: widget.onChanged),
                ],
              ),
              if (open)
                Padding(
                  padding: EdgeInsets.only(top: 12, left: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(a.package, style: TextStyle(fontSize: 12, color: AppColors.hint)),
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
    required this.apps,
    required this.st,
    required this.onToggle,
    required this.onGroup,
    required this.onInfo,
  });
  final List<AppItem> apps;
  final NativeState st;
  final void Function(AppItem, bool) onToggle;
  final void Function(List<AppItem>, bool) onGroup;
  final ValueChanged<AppItem> onInfo;

  @override
  State<AppsPage> createState() => _AppsPageState();
}

class _AppsPageState extends State<AppsPage> {
  String query = '';
  int seg = 0;
  static const segs = ['All', 'Blocked', 'Allowed'];
  static const order = ['Social', 'Games', 'Media', 'News', 'Work', 'Maps', 'Other'];

  Widget _search() => Padding(
        padding: EdgeInsets.fromLTRB(16, 6, 16, 0),
        child: TextField(
          onChanged: (v) => setState(() => query = v),
          decoration: InputDecoration(
            hintText: 'Search ${widget.apps.length} apps\u2026',
            hintStyle: TextStyle(color: AppColors.muted),
            prefixIcon: Icon(Icons.search, color: AppColors.muted),
            filled: true,
            fillColor: AppColors.card,
            contentPadding: EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(27),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(27),
              borderSide: BorderSide(color: AppColors.border),
            ),
          ),
        ),
      );

  Widget _segments() => Container(
        margin: EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            for (var i = 0; i < segs.length; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => seg = i),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 180),
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: seg == i ? AppColors.accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(segs[i],
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: seg == i ? AppColors.onAccent : AppColors.muted)),
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _groupHeader(String name, List<AppItem> list) {
    final b = list.where((a) => a.blocked).length;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(name.toUpperCase(),
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.accent2)),
                SizedBox(width: 8),
                Text('$b of ${list.length} blocked', style: TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          AppSwitch(value: b == list.length && list.isNotEmpty, onChanged: (v) => widget.onGroup(list, v)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var items = widget.apps.where((a) => a.name.toLowerCase().contains(query.toLowerCase())).toList();
    if (!widget.st.showSystem) items = items.where((a) => !a.system || a.blocked).toList();
    if (seg == 1) items = items.where((a) => a.blocked).toList();
    if (seg == 2) items = items.where((a) => !a.blocked).toList();

    final groups = <String, List<AppItem>>{};
    for (final a in items) {
      groups.putIfAbsent(a.category, () => []).add(a);
    }
    final names = groups.keys.toList()
      ..sort((a, b) {
        final ia = order.indexOf(a), ib = order.indexOf(b);
        return (ia < 0 ? 99 : ia) - (ib < 0 ? 99 : ib);
      });

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: PageHeader('Apps', '${widget.apps.length} apps')),
        SliverToBoxAdapter(child: _search()),
        SliverToBoxAdapter(child: _segments()),
        if (items.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(
                child: Text(
                  widget.apps.isEmpty ? 'No apps found on this device' : 'No matching apps',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            ),
          )
        else
          for (final g in names) ...[
            SliverToBoxAdapter(child: _groupHeader(g, groups[g]!)),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final app = groups[g]![i];
                    return AppCard(
                      key: ValueKey(app.package),
                      app: app,
                      running: widget.st.running,
                      onChanged: (v) => widget.onToggle(app, v),
                      onInfo: () => widget.onInfo(app),
                    );
                  },
                  childCount: groups[g]!.length,
                ),
              ),
            ),
          ],
        SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// ===== screens/home_page.dart =====
class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.apps,
    required this.st,
    required this.onMaster,
    required this.onTimer,
    required this.onGoTab,
    required this.onRefresh,
    required this.onScheduleToggle,
  });
  final List<AppItem> apps;
  final NativeState st;
  final ValueChanged<bool> onMaster;
  final VoidCallback onTimer;
  final ValueChanged<int> onGoTab;
  final VoidCallback onRefresh;
  final ValueChanged<bool> onScheduleToggle;

  String _greeting() {
    final h = DateTime.now().hour;
    return h < 12 ? 'Good morning' : (h < 18 ? 'Good afternoon' : 'Good evening');
  }

  String _time(int m) {
    final h = (m ~/ 60) % 24;
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:${(m % 60).toString().padLeft(2, '0')} ${h < 12 ? 'AM' : 'PM'}';
  }

  String _clock(int millis) {
    final d = DateTime.fromMillisecondsSinceEpoch(millis);
    return _time(d.hour * 60 + d.minute);
  }

  Widget _top(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(22, 14, 14, 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_greeting(),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.muted)),
                  Text('Block Internet',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.6)),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'More',
              onSelected: (v) {
                if (v == 'timer') onTimer();
                if (v == 'refresh') onRefresh();
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'timer', child: Text('Timed block\u2026')),
                PopupMenuItem(value: 'refresh', child: Text('Refresh apps')),
              ],
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(Icons.more_vert, size: 22),
              ),
            ),
          ],
        ),
      );

  Widget _pill(IconData icon, String text, Color color) => Container(
        height: 34,
        padding: EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            SizedBox(width: 7),
            Text(text, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      );

  Widget _quick(IconData icon, String label, Color color, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, size: 26, color: color),
            ),
            SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final n = apps.where((a) => a.blocked).length;
    final on = st.running;
    String title, sub;
    if (on) {
      title = 'Protected';
      sub = '$n of ${apps.length} apps are offline';
    } else if (!st.master) {
      title = 'Paused';
      sub = 'Tap the orb to resume';
    } else if (n == 0) {
      title = 'No apps selected';
      sub = 'Open Apps and choose what to block';
    } else {
      title = 'Starting\u2026';
      sub = 'Waiting for the VPN';
    }
    final second = st.timedActive
        ? 'Timer until ${_clock(st.timedUntil)}'
        : (st.schedOn ? '${_time(st.start)} \u2013 ${_time(st.end)}' : 'No schedule');

    return ListView(
      padding: EdgeInsets.only(bottom: 100),
      children: [
        _top(context),
        SizedBox(height: 6),
        Center(
          child: _Orb(
            on: on,
            onTap: () => (n == 0 && !on) ? onGoTab(1) : onMaster(!st.master),
          ),
        ),
        SizedBox(height: 8),
        Center(child: Text(title, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -0.8))),
        SizedBox(height: 2),
        Center(child: Text(sub, style: TextStyle(fontSize: 13.5, color: AppColors.muted))),
        SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _pill(Icons.shield_outlined, on ? 'VPN active' : 'VPN stopped', on ? AppColors.accent2 : AppColors.muted),
            _pill(Icons.schedule, second, AppColors.muted),
          ],
        ),
        SizedBox(height: 18),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _quick(Icons.timer_outlined, 'Timer', AppColors.coral, onTimer),
              _quick(Icons.event_outlined, 'Schedule', AppColors.accent2, () => onGoTab(2)),
              _quick(Icons.apps_rounded, 'Apps', AppColors.accent2, () => onGoTab(1)),
              _quick(Icons.settings_outlined, 'Settings', AppColors.accent2, () => onGoTab(3)),
            ],
          ),
        ),
        SizedBox(height: 18),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(40),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.nightlight_round, color: AppColors.accent2, size: 24),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Schedule', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    Text('${_time(st.start)} \u2013 ${_time(st.end)} \u00b7 ${st.schedOn ? 'on' : 'off'}',
                        style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  ],
                ),
              ),
              AppSwitch(value: st.schedOn, onChanged: onScheduleToggle),
            ],
          ),
        ),
      ],
    );
  }
}

/// Big tappable power orb: glowing gradient ring when protection is on.
class _Orb extends StatelessWidget {
  _Orb({required this.on, required this.onTap});
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 260,
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accent.withAlpha(on ? 40 : 18)),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(26),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accent.withAlpha(on ? 70 : 24)),
                    gradient: RadialGradient(
                      colors: [AppColors.accent.withAlpha(on ? 70 : 0), Colors.transparent],
                    ),
                  ),
                ),
              ),
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                width: 170,
                height: 170,
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: on ? null : AppColors.border,
                  gradient: on
                      ? SweepGradient(colors: [AppColors.accent, AppColors.coral, AppColors.accent])
                      : null,
                  boxShadow: on ? [BoxShadow(color: AppColors.accent.withAlpha(110), blurRadius: 60)] : [],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.logoA, AppColors.logoB],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.power_settings_new,
                          size: 46, color: on ? AppColors.accent2 : AppColors.muted),
                      SizedBox(height: 6),
                      Text(on ? 'TAP TO PAUSE' : 'TAP TO START',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
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
  int? _drag; // 0 = start handle, 1 = end handle

  static const double _size = 300;
  static const double _r = 108;

  int get mask {
    var m = 0;
    for (var i = 0; i < 7; i++) {
      if (days[i]) m |= 1 << i;
    }
    return m;
  }

  int get durMin => ((endMin - startMin) % 1440 + 1440) % 1440;

  String _t(int m) {
    final h = (m ~/ 60) % 24;
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:${(m % 60).toString().padLeft(2, '0')} ${h < 12 ? 'AM' : 'PM'}';
  }

  Offset _handle(int minutes) {
    final a = minutes / 1440 * 2 * math.pi - math.pi / 2;
    return Offset(_size / 2 + _r * math.cos(a), _size / 2 + _r * math.sin(a));
  }

  int _minutesAt(Offset p) {
    final a = math.atan2(p.dy - _size / 2, p.dx - _size / 2) + math.pi / 2;
    var f = a / (2 * math.pi);
    f = f - f.floorToDouble();
    return ((f * 1440 / 5).round() * 5) % 1440;
  }

  void _panDown(DragDownDetails d) {
    final p = d.localPosition;
    final ds = (p - _handle(startMin)).distance;
    final de = (p - _handle(endMin)).distance;
    setState(() => _drag = (ds < 42 || de < 42) ? (ds <= de ? 0 : 1) : null);
  }

  void _panUpdate(DragUpdateDetails d) {
    if (_drag == null) return;
    final v = _minutesAt(d.localPosition);
    setState(() {
      if (_drag == 0) {
        startMin = v;
      } else {
        endMin = v;
      }
    });
  }

  void _panEnd() {
    if (_drag != null && on) widget.onSchedule(true, startMin, endMin, mask);
    setState(() => _drag = null);
  }

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

  Widget _timeTile(IconData icon, String label, int minutes, Color color, bool isStart) => Expanded(
        child: GestureDetector(
          onTap: () => pick(isStart),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(icon, size: 24, color: color),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 12, color: AppColors.muted)),
                    Text(_t(minutes), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final h = durMin ~/ 60, m = durMin % 60;
    final count = days.where((d) => d).length;
    return Column(
      children: [
        PageHeader('Schedule', count == 7 ? 'Every day' : '$count days a week'),
        Expanded(
          child: ListView(
            physics: _drag != null ? NeverScrollableScrollPhysics() : null,
            padding: EdgeInsets.fromLTRB(16, 4, 16, 100),
            children: [
              Center(
                child: GestureDetector(
                  onPanDown: _panDown,
                  onPanUpdate: _panUpdate,
                  onPanEnd: (_) => _panEnd(),
                  onPanCancel: _panEnd,
                  child: SizedBox(
                    width: _size,
                    height: _size,
                    child: Stack(
                      children: [
                        CustomPaint(
                          size: Size(_size, _size),
                          painter: _DialPainter(
                            start: startMin,
                            end: endMin,
                            accent: AppColors.accent,
                            coral: AppColors.coral,
                            track: AppColors.tonal,
                            label: AppColors.muted,
                          ),
                        ),
                        Positioned.fill(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('OFFLINE FOR',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                      color: AppColors.muted)),
                              Text(m == 0 ? '$h h' : '$h h $m m',
                                  style: TextStyle(fontSize: 38, fontWeight: FontWeight.w700, letterSpacing: -1.4)),
                              Text('${_t(startMin)} \u2192 ${_t(endMin)}',
                                  style: TextStyle(
                                      fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.accent2)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 6),
              Center(
                child: Text('Drag the white handles or tap a time',
                    style: TextStyle(fontSize: 12, color: AppColors.hint)),
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
                          shape: BoxShape.circle,
                          color: days[i] ? AppColors.accent : AppColors.card,
                          border: Border.all(color: days[i] ? AppColors.accent : AppColors.border),
                        ),
                        child: Text('SMTWTFS'[i],
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: days[i] ? AppColors.onAccent : AppColors.muted)),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 14),
              Row(
                children: [
                  _timeTile(Icons.nightlight_round, 'Start', startMin, AppColors.accent2, true),
                  SizedBox(width: 10),
                  _timeTile(Icons.wb_sunny_outlined, 'End', endMin, AppColors.coral, false),
                ],
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: AppColors.border),
                ),
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
              GestureDetector(
                onTap: save,
                child: Container(
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(29),
                    gradient: LinearGradient(colors: [AppColors.accent, AppColors.accent2]),
                    boxShadow: [
                      BoxShadow(color: AppColors.accent.withAlpha(90), blurRadius: 30, offset: Offset(0, 10)),
                    ],
                  ),
                  child: Text('SAVE SCHEDULE',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.onAccent)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 24-hour dial: the blocked window is a gradient arc with two draggable handles.
class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.start,
    required this.end,
    required this.accent,
    required this.coral,
    required this.track,
    required this.label,
  });
  final int start, end;
  final Color accent, coral, track, label;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    const r = 108.0;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26
        ..color = track,
    );
    final startAngle = start / 1440 * 2 * math.pi - math.pi / 2;
    final dur = ((end - start) % 1440 + 1440) % 1440;
    final sweep = dur / 1440 * 2 * math.pi;
    if (sweep > 0) {
      canvas.drawArc(
        rect,
        startAngle,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 26
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            startAngle: 0,
            endAngle: sweep,
            colors: [accent, coral],
            transform: GradientRotation(startAngle),
          ).createShader(rect),
      );
    }
    for (final m in [start, end]) {
      final a = m / 1440 * 2 * math.pi - math.pi / 2;
      final p = c + Offset(r * math.cos(a), r * math.sin(a));
      canvas.drawCircle(p + Offset(0, 2), 10, Paint()..color = Color(0x55000000));
      canvas.drawCircle(p, 9, Paint()..color = Colors.white);
    }
    const marks = {0: '12 AM', 6: '6 AM', 12: '12 PM', 18: '6 PM'};
    marks.forEach((h, text) {
      final a = h / 24 * 2 * math.pi - math.pi / 2;
      final p = c + Offset(142 * math.cos(a), 142 * math.sin(a));
      final tp = TextPainter(
        text: TextSpan(text: text, style: TextStyle(fontSize: 11, color: label)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    });
  }

  @override
  bool shouldRepaint(_DialPainter o) =>
      o.start != start || o.end != end || o.accent != accent || o.coral != coral || o.track != track;
}

// ===== screens/settings_page.dart =====
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.st,
    required this.onPref,
    required this.onVpn,
    required this.onCopy,
    required this.onPaste,
    required this.onClear,
    required this.onOpenSchedule,
    required this.onTimer,
  });
  final NativeState st;
  final void Function(String key, bool value) onPref;
  final Future<bool> Function() onVpn;
  final VoidCallback onCopy;
  final VoidCallback onPaste;
  final VoidCallback onClear;
  final VoidCallback onOpenSchedule;
  final VoidCallback onTimer;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          PageHeader('Settings', 'Customize how blocking works'),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 100),
              children: [
                _status(context),
                _label('Appearance'),
                _themeSwitch(),
                SizedBox(height: 10),
                _accentRow(),
                SizedBox(height: 18),
                _label('Protection'),
                _group([
                  _tile(Icons.event_outlined, 'Schedule', 'Block automatically by time of day',
                      trailing: st.schedOn ? '${_time(st.start)} \u2013 ${_time(st.end)}' : 'Off',
                      onTap: onOpenSchedule),
                  _tile(Icons.timer_outlined, 'Timed block', 'Block for a fixed period',
                      trailing: st.timedActive ? 'Until ${_clock(st.timedUntil)}' : 'Off',
                      onTap: onTimer),
                ]),
                _label('Behavior'),
                _group([
                  _tile(Icons.power_settings_new, 'Start on boot', 'Resume protection after restart',
                      sw: st.boot, on: (v) => onPref('boot', v)),
                  _tile(Icons.apps, 'Show system apps', 'Include system apps in the list',
                      sw: st.showSystem, on: (v) => onPref('showSystem', v)),
                ]),
                _label('Block list'),
                _group([
                  _tile(Icons.copy_outlined, 'Copy block list', 'Copy the blocked apps to the clipboard',
                      onTap: onCopy),
                  _tile(Icons.content_paste_outlined, 'Paste block list',
                      'Block the apps found in the clipboard',
                      onTap: onPaste),
                  _tile(Icons.delete_sweep_outlined, 'Unblock all apps', 'Give every app its internet back',
                      onTap: () => _confirmClear(context)),
                ]),
                _label('General'),
                _group([
                  _tile(Icons.vpn_key_outlined, 'VPN permission', 'Needed to block apps',
                      trailing: st.vpnGranted ? 'Granted' : 'Request', onTap: () => onVpn()),
                  _tile(Icons.battery_saver_outlined, 'Run in background', 'Allow unrestricted battery use',
                      trailing: 'Open', onTap: () => BlockService.openBatterySettings()),
                  _tile(Icons.help_outline, 'How it works', 'What this app does and does not do',
                      onTap: () => _howItWorks(context)),
                  _tile(Icons.info_outline, 'About', 'Version 1.0', onTap: () => _about(context)),
                ]),
              ],
            ),
          ),
        ],
      );

  // ---------------------------------------------------------------- status

  Widget _status(BuildContext context) {
    final ok = st.vpnGranted;
    final title = !ok ? 'Permission needed' : (st.running ? 'Protection active' : 'Protection idle');
    final sub = !ok ? 'Allow the VPN so blocking can work' : '${st.blocked.length} apps in the block list';
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent.withAlpha(44), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.accent.withAlpha(st.running ? 190 : 90)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(18)),
                child: Icon(st.running ? Icons.shield : Icons.shield_outlined,
                    size: 26, color: AppColors.onAccent),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                    SizedBox(height: 2),
                    Text(sub, style: TextStyle(fontSize: 13, color: AppColors.muted)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          if (!ok)
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.onAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: TextStyle(fontWeight: FontWeight.w700),
                ),
                onPressed: () => onVpn(),
                child: Text('Grant VPN permission'),
              ),
            )
          else
            Row(
              children: [
                _pill('Diagnostics', Icons.fact_check_outlined, () => _diagnostics(context)),
                SizedBox(width: 8),
                _pill('Battery', Icons.battery_saver_outlined, () => BlockService.openBatterySettings()),
              ],
            ),
        ],
      ),
    );
  }

  Widget _pill(String label, IconData icon, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 42,
            decoration: BoxDecoration(color: AppColors.tonal, borderRadius: BorderRadius.circular(14)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 17),
                SizedBox(width: 7),
                Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );

  String _time(int m) {
    final h = m ~/ 60;
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:${(m % 60).toString().padLeft(2, '0')} ${h < 12 ? 'AM' : 'PM'}';
  }

  String _clock(int millis) {
    final d = DateTime.fromMillisecondsSinceEpoch(millis);
    return _time(d.hour * 60 + d.minute);
  }

  void _howItWorks(BuildContext context) => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('How it works'),
          content: Text(
              'The app creates a local VPN that carries only the apps you block and drops '
              'their traffic, so they have no internet. All other apps work normally. '
              'Nothing is sent anywhere and nothing is collected.\n\n'
              'Android allows only one VPN at a time, so starting another VPN app pauses this one.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('OK'))],
        ),
      );

  void _diagnostics(BuildContext context) {
    final rows = <List<String>>[
      ['VPN permission', st.vpnGranted ? 'Granted' : 'Missing'],
      ['Blocking service', st.running ? 'Running' : 'Stopped'],
      ['Apps in block list', '${st.blocked.length}'],
      ['Main switch', st.master ? 'On' : 'Off'],
      ['Timed block', st.timedActive ? 'Active' : 'None'],
      ['Schedule', st.schedOn ? '${_time(st.start)} \u2013 ${_time(st.end)}' : 'Off'],
      ['Last error', st.error.isEmpty ? 'None' : st.error],
    ];
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Diagnostics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final r in rows)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(r[0], style: TextStyle(color: AppColors.muted))),
                    SizedBox(width: 12),
                    Flexible(
                      child: Text(r[1], textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close'))],
      ),
    );
  }

  // ------------------------------------------------------------ appearance

  Widget _themeSwitch() {
    Widget opt(String label, IconData icon, int mode) {
      final sel = AppColors.mode == mode;
      final fg = sel ? AppColors.onAccent : AppColors.muted;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            applyTheme(mode: mode);
            BlockService.setPref('themeMode', mode);
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
                SizedBox(width: 6),
                Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          opt('System', Icons.brightness_auto_outlined, 0),
          opt('Dark', Icons.dark_mode_outlined, 1),
          opt('Light', Icons.light_mode_outlined, 2),
        ],
      ),
    );
  }

  Widget _accentRow() => Container(
        padding: EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Accent color', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < AppColors.accentNames.length; i++)
                  GestureDetector(
                    onTap: () {
                      applyTheme(accent: i);
                      BlockService.setPref('accent', i);
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accentFor(i, AppColors.dark),
                            border: Border.all(
                              color: AppColors.accentIndex == i ? AppColors.muted : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                          child: AppColors.accentIndex == i
                              ? Icon(Icons.check, size: 22, color: AppColors.dark ? Color(0xFF0F1A18) : Colors.white)
                              : null,
                        ),
                        SizedBox(height: 6),
                        Text(AppColors.accentNames[i], style: TextStyle(fontSize: 11, color: AppColors.muted)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      );

  // --------------------------------------------------------------- helpers

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Unblock all apps?'),
        content: Text('Every app will get its internet access back.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Unblock all')),
        ],
      ),
    );
    if (ok == true) onClear();
  }

  void _about(BuildContext context) => showAboutDialog(
        context: context,
        applicationName: 'Block Internet Access',
        applicationVersion: '1.0',
        children: [
          Text('Blocks internet access for the apps you choose using a local VPN. '
              'No traffic leaves your device and nothing is collected.'),
        ],
      );

  Widget _label(String t) => Padding(
        padding: EdgeInsets.only(left: 4, bottom: 6),
        child: Text(t.toUpperCase(),
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: AppColors.accent)),
      );

  Widget _group(List<Widget> rows) => Container(
        margin: EdgeInsets.only(bottom: 18),
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
      {bool? sw, ValueChanged<bool>? on, String? trailing, VoidCallback? onTap}) {
    return InkWell(
      onTap: sw == null ? onTap : null,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: 64),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: AppColors.tonal, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, size: 19, color: AppColors.accent2),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    if (sub.isNotEmpty) Text(sub, style: TextStyle(fontSize: 12, color: AppColors.sub)),
                  ],
                ),
              ),
              if (sw != null)
                AppSwitch(value: sw, onChanged: on)
              else ...[
                if (trailing != null && trailing.isNotEmpty)
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

// ===== screens/permission_page.dart =====
/// Friendly explanation shown before Android's own VPN confirmation dialog.
class PermissionPage extends StatelessWidget {
  const PermissionPage({super.key});

  Widget _point(IconData icon, String text) => Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: AppColors.tonal, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 19, color: AppColors.accent),
            ),
            SizedBox(width: 14),
            Expanded(child: Text(text, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.9, -1.1),
              radius: 1.1,
              colors: [AppColors.accent.withAlpha(46), Colors.transparent],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(28, 56, 28, 24),
              child: Column(
                children: [
                  Container(
                    width: 168,
                    height: 168,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [AppColors.accent.withAlpha(50), Colors.transparent]),
                    ),
                    child: Center(
                      child: Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.card, AppColors.tonal],
                          ),
                          border: Border.all(color: AppColors.accent),
                        ),
                        child: Icon(Icons.shield_outlined, size: 52, color: AppColors.accent),
                      ),
                    ),
                  ),
                  SizedBox(height: 22),
                  Text('Allow VPN connection',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
                  SizedBox(height: 8),
                  Text(
                    'Block Internet uses a local VPN to cut internet for the apps you choose. '
                    'No data leaves your device.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14.5, height: 1.6, color: AppColors.muted),
                  ),
                  SizedBox(height: 22),
                  _point(Icons.check, 'Only the apps you pick lose internet'),
                  _point(Icons.lock_outline, 'Everything stays on your phone'),
                  _point(Icons.check, 'You can turn it off anytime'),
                  SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.onAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(29)),
                        textStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0.6),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('CONTINUE'),
                    ),
                  ),
                  SizedBox(height: 6),
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Not now', style: TextStyle(color: AppColors.muted, fontSize: 14)),
                  ),
                  Text('Android will ask you to confirm',
                      style: TextStyle(fontSize: 11.5, color: AppColors.sub)),
                ],
              ),
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
    await reloadState();
    if (!st.vpnGranted && mounted) {
      final go = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => PermissionPage(), fullscreenDialog: true),
      );
      if (go != true) {
        say('VPN permission is required to block apps');
        return false;
      }
    }
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

  Future<void> toggleGroup(List<AppItem> list, bool v) async {
    if (v && !await ensureVpn()) return;
    for (final a in list) {
      a.blocked = v;
    }
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

  Future<void> startTimed(int minutes) async {
    if (!apps.any((a) => a.blocked)) {
      say('Select the apps to block first');
      return;
    }
    if (!await ensureVpn()) return;
    await BlockService.timedBlock(minutes);
    await verifyRunning();
    say('Selected apps are blocked for ${o0(minutes)}');
  }

  Future<void> timer() async {
    final opts = <List<Object>>[
      ['15 minutes', 15],
      ['1 hour', 60],
      ['4 hours', 240],
      ['Until tomorrow morning', _minsToMorning()],
    ];
    final count = apps.where((a) => a.blocked).length;
    final pick = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) {
        var sel = 1;
        return StatefulBuilder(
          builder: (ctx, setS) => SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: AppColors.switchOutline, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  SizedBox(height: 18),
                  Text('Block selected apps for\u2026',
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text('$count apps will lose internet until the timer ends.',
                      style: TextStyle(fontSize: 13, color: AppColors.muted)),
                  SizedBox(height: 16),
                  for (var i = 0; i < opts.length; i++)
                    GestureDetector(
                      onTap: () => setS(() => sel = i),
                      child: Container(
                        height: 56,
                        margin: EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: sel == i ? AppColors.tonal : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: sel == i ? AppColors.accent : AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.timer_outlined, color: AppColors.accent),
                            SizedBox(width: 14),
                            Expanded(
                              child: Text(opts[i][0] as String,
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: sel == i ? FontWeight.w600 : FontWeight.w500)),
                            ),
                            Icon(sel == i ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                color: sel == i ? AppColors.accent : AppColors.switchOutline),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.onAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.6),
                      ),
                      onPressed: () => Navigator.pop(ctx, opts[sel][1] as int),
                      child: Text('START TIMER'),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Cancel', style: TextStyle(color: AppColors.muted)),
                    ),
                  ),
                  if (st.timedActive)
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, -1),
                        child: Text('Cancel timed block'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (pick == null) return;
    if (pick < 0) {
      await BlockService.timedBlock(0);
      await reloadState();
      say('Timed block cancelled');
      return;
    }
    await startTimed(pick);
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

  Future<void> copyList() async {
    final names = apps.where((a) => a.blocked).map((a) => a.package).toList();
    if (names.isEmpty) {
      say('The block list is empty');
      return;
    }
    await Clipboard.setData(ClipboardData(text: names.join('\n')));
    say('Copied ${names.length} apps to the clipboard');
  }

  Future<void> pasteList() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final wanted = (data?.text ?? '').split(RegExp(r'[\s,;]+')).where((e) => e.contains('.')).toSet();
    final known = apps.where((a) => wanted.contains(a.package)).toList();
    if (known.isEmpty) {
      say('No matching apps found in the clipboard');
      return;
    }
    if (!await ensureVpn()) return;
    for (final a in known) {
      a.blocked = true;
    }
    refresh();
    await BlockService.setBlocked(apps.where((x) => x.blocked).map((x) => x.package));
    await verifyRunning();
    say('Blocked ${known.length} apps');
  }

  Future<void> clearList() async {
    for (final a in apps) {
      a.blocked = false;
    }
    refresh();
    await BlockService.setBlocked(<String>[]);
    await reloadState();
    say('Block list cleared');
  }

  Future<void> setPref(String key, bool v) async {
    await BlockService.setPref(key, v);
    await reloadState();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(
        apps: apps,
        st: st,
        onMaster: setMaster,
        onTimer: timer,
        onGoTab: (i) => setState(() => tab = i),
        onRefresh: load,
        onScheduleToggle: (v) => schedule(v, st.start, st.end, st.days),
      ),
      AppsPage(
        apps: apps,
        st: st,
        onToggle: toggleApp,
        onGroup: toggleGroup,
        onInfo: (a) => BlockService.openAppInfo(a.package),
      ),
      SchedulePage(st: st, onSchedule: schedule),
      SettingsPage(
        st: st,
        onPref: setPref,
        onVpn: ensureVpn,
        onCopy: copyList,
        onPaste: pasteList,
        onClear: clearList,
        onOpenSchedule: () => setState(() => tab = 2),
        onTimer: timer,
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-1.1, 0.9),
                  radius: 0.9,
                  colors: [AppColors.coral.withAlpha(26), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.9, -1.1),
                  radius: 1.0,
                  colors: [AppColors.accent.withAlpha(60), Colors.transparent],
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
            borderRadius: BorderRadius.circular(35),
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
              NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.apps_rounded), label: 'Apps'),
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
  applyTheme(mode: st.themeMode, accent: st.accent);
  runApp(const BlockerApp());
}

class BlockerApp extends StatefulWidget {
  const BlockerApp({super.key});

  @override
  State<BlockerApp> createState() => _BlockerAppState();
}

class _BlockerAppState extends State<BlockerApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    if (AppColors.mode == 0) applyTheme();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
        valueListenable: themeNotifier,
        builder: (_, __, ___) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Block Internet Access',
          theme: buildTheme(AppColors.dark),
          home: SplashScreen(),
        ),
      );
}

// Alias so the default test generated by `flutter create` (which uses MyApp) still compiles.
typedef MyApp = BlockerApp;
