// Block Internet Access: complete Flutter app in ONE file (Material 3, Indigo design, dark/light, English/Arabic).
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

// ===== i18n.dart =====
/// Current UI language: 'en' or 'ar' (Arabic is laid out right-to-left).
class L {
  static String code = 'en';
  static bool get rtl => code == 'ar';
}

/// Sets the language ('en', 'ar', or anything else to follow the phone) and rebuilds the app.
void applyLang(String code) {
  var c = code;
  if (c != 'en' && c != 'ar') {
    c = WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'ar' ? 'ar' : 'en';
  }
  L.code = c;
  themeNotifier.value++;
}

/// Translates an English UI text. Placeholders like {n} are filled from [args].
String tr(String en, [Map<String, Object>? args]) {
  var s = L.code == 'ar' ? (_ar[en] ?? en) : en;
  if (args != null) {
    args.forEach((k, v) {
      s = s.replaceAll('{$k}', '$v');
    });
  }
  return s;
}

/// First letter of each weekday, Sunday first.
String dayLetter(int i) => L.rtl ? 'حنثرخجس'[i] : 'SMTWTFS'[i];

const Map<String, String> _ar = {
  'Home': 'الرئيسية',
  'Apps': 'التطبيقات',
  'Schedule': 'الجدولة',
  'Settings': 'الإعدادات',
  'Block Internet Access': 'حظر الإنترنت',
  'Block Internet': 'حظر الإنترنت',
  'Block Internet\nAccess': 'حظر الإنترنت\nللتطبيقات',
  'Good morning': 'صباح الخير',
  'Good afternoon': 'طاب يومك',
  'Good evening': 'مساء الخير',
  'More': 'المزيد',
  'Timed block\u2026': 'حظر مؤقت…',
  'Refresh apps': 'تحديث التطبيقات',
  'Protected': 'محمي',
  'Paused': 'متوقف مؤقتاً',
  'Tap the orb to resume': 'اضغط على الكرة للاستئناف',
  'No apps selected': 'لم تختر أي تطبيق',
  'Open Apps and choose what to block': 'افتح التطبيقات واختر ما تريد حظره',
  'Starting\u2026': 'جارٍ التشغيل…',
  'Waiting for the VPN': 'بانتظار الـ VPN',
  'No schedule': 'بلا جدولة',
  'VPN active': 'VPN يعمل',
  'VPN stopped': 'VPN متوقف',
  'Timer': 'المؤقت',
  'TAP TO PAUSE': 'اضغط للإيقاف',
  'TAP TO START': 'اضغط للتشغيل',
  '{n} of {t} apps are offline': '{n} من {t} تطبيقاً بلا إنترنت',
  'Timer until {time}': 'المؤقت حتى {time}',
  'on': 'مفعّلة',
  'off': 'متوقفة',
  'AM': 'ص',
  'PM': 'م',
  'All': 'الكل',
  'Blocked': 'محظور',
  'Allowed': 'مسموح',
  'Social': 'التواصل',
  'Games': 'الألعاب',
  'Media': 'الوسائط',
  'News': 'الأخبار',
  'Work': 'العمل',
  'Maps': 'الخرائط',
  'Other': 'أخرى',
  'Search {n} apps\u2026': 'ابحث في {n} تطبيقاً…',
  '{b} of {t} blocked': '{b} من {t} محظور',
  '{n} apps': '{n} تطبيقاً',
  'No apps found on this device': 'لا توجد تطبيقات على هذا الجهاز',
  'No matching apps': 'لا توجد تطبيقات مطابقة',
  'Blocked \u00b7 always': 'محظور · دائماً',
  'Selected \u00b7 protection paused': 'محدد · الحماية متوقفة',
  'BLOCKED': 'محظور',
  'App info': 'معلومات التطبيق',
  'Allow VPN connection': 'السماح باتصال VPN',
  'Block Internet uses a local VPN to cut internet for the apps you choose. No data leaves your device.': 'يستخدم التطبيق VPN محلياً لقطع الإنترنت عن التطبيقات التي تختارها. لا تغادر أي بيانات جهازك.',
  'Only the apps you pick lose internet': 'التطبيقات التي تختارها فقط تفقد الإنترنت',
  'Everything stays on your phone': 'كل شيء يبقى على هاتفك',
  'You can turn it off anytime': 'يمكنك إيقافه في أي وقت',
  'CONTINUE': 'متابعة',
  'Not now': 'ليس الآن',
  'Android will ask you to confirm': 'سيطلب منك أندرويد التأكيد',
  'Every day': 'كل يوم',
  '{n} days a week': '{n} أيام في الأسبوع',
  'OFFLINE FOR': 'بلا إنترنت لمدة',
  '{h} h': '{h} س',
  '{h} h {m} m': '{h} س {m} د',
  'Drag the white handles or tap a time': 'اسحب المقبضين الأبيضين أو اضغط على الوقت',
  'Start': 'البداية',
  'End': 'النهاية',
  'Schedule enabled': 'تفعيل الجدولة',
  'Applies to the apps you blocked': 'تُطبَّق على التطبيقات التي حظرتها',
  'SAVE SCHEDULE': 'حفظ الجدولة',
  'Customize how blocking works': 'خصّص طريقة الحظر',
  'Appearance': 'المظهر',
  'Language': 'اللغة',
  'Protection': 'الحماية',
  'Block automatically by time of day': 'حظر تلقائي حسب وقت اليوم',
  'Off': 'متوقف',
  'On': 'يعمل',
  'Timed block': 'حظر مؤقت',
  'Block for a fixed period': 'حظر لمدة محددة',
  'Until {time}': 'حتى {time}',
  'Behavior': 'السلوك',
  'Start on boot': 'التشغيل عند إقلاع الجهاز',
  'Resume protection after restart': 'استئناف الحماية بعد إعادة التشغيل',
  'Show system apps': 'إظهار تطبيقات النظام',
  'Include system apps in the list': 'تضمين تطبيقات النظام في القائمة',
  'Block list': 'قائمة الحظر',
  'Copy block list': 'نسخ قائمة الحظر',
  'Copy the blocked apps to the clipboard': 'نسخ التطبيقات المحظورة إلى الحافظة',
  'Paste block list': 'لصق قائمة الحظر',
  'Block the apps found in the clipboard': 'حظر التطبيقات الموجودة في الحافظة',
  'Unblock all apps': 'إلغاء حظر كل التطبيقات',
  'Give every app its internet back': 'إعادة الإنترنت لكل التطبيقات',
  'General': 'عام',
  'VPN permission': 'إذن VPN',
  'Needed to block apps': 'مطلوب لحظر التطبيقات',
  'Granted': 'ممنوح',
  'Request': 'طلب',
  'Run in background': 'العمل في الخلفية',
  'Allow unrestricted battery use': 'السماح باستخدام البطارية دون قيود',
  'Open': 'فتح',
  'How it works': 'كيف يعمل',
  'What this app does and does not do': 'ما يفعله التطبيق وما لا يفعله',
  'About': 'حول التطبيق',
  'Version 1.0': 'الإصدار 1.0',
  'Permission needed': 'مطلوب إذن',
  'Protection active': 'الحماية تعمل',
  'Protection idle': 'الحماية متوقفة',
  'Allow the VPN so blocking can work': 'اسمح بالـ VPN ليعمل الحظر',
  '{n} apps in the block list': 'عدد التطبيقات في قائمة الحظر: {n}',
  'Grant VPN permission': 'منح إذن VPN',
  'Diagnostics': 'التشخيص',
  'Battery': 'البطارية',
  'The app creates a local VPN that carries only the apps you block and drops their traffic, so they have no internet. All other apps work normally. Nothing is sent anywhere and nothing is collected.\n\nAndroid allows only one VPN at a time, so starting another VPN app pauses this one.': 'ينشئ التطبيق VPN محلياً يمرّر التطبيقات التي تحظرها فقط ويُسقط حركة بياناتها، فلا يصلها الإنترنت. أما بقية التطبيقات فتعمل بشكل طبيعي. لا يُرسل شيء إلى أي مكان ولا تُجمع أي بيانات.\n\nيسمح أندرويد بـ VPN واحد فقط في كل وقت، لذلك يتوقف هذا التطبيق مؤقتاً عند تشغيل تطبيق VPN آخر.',
  'OK': 'حسناً',
  'Missing': 'غير ممنوح',
  'Blocking service': 'خدمة الحظر',
  'Running': 'تعمل',
  'Stopped': 'متوقفة',
  'Apps in block list': 'التطبيقات في قائمة الحظر',
  'Main switch': 'المفتاح الرئيسي',
  'Active': 'نشط',
  'None': 'لا يوجد',
  'Last error': 'آخر خطأ',
  'Close': 'إغلاق',
  'System': 'النظام',
  'Dark': 'داكن',
  'Light': 'فاتح',
  'Accent color': 'لون التطبيق',
  'Unblock all apps?': 'إلغاء حظر كل التطبيقات؟',
  'Every app will get its internet access back.': 'سيعود الإنترنت لكل التطبيقات.',
  'Unblock all': 'إلغاء حظر الكل',
  'Cancel': 'إلغاء',
  'Blocks internet access for the apps you choose using a local VPN. No traffic leaves your device and nothing is collected.': 'يحظر الإنترنت عن التطبيقات التي تختارها باستخدام VPN محلي. لا تغادر أي بيانات جهازك ولا يُجمع شيء.',
  'Indigo': 'نيلي',
  'Sage': 'مريمي',
  'Ocean': 'محيطي',
  'Lavender': 'لافندر',
  'Sand': 'رملي',
  'Rose': 'وردي',
  'Take control of every app\u2019s connection': 'تحكّم باتصال كل تطبيق',
  'Securing your connections\u2026': 'جارٍ تأمين اتصالاتك…',
  'VPN permission is required to block apps': 'إذن VPN مطلوب لحظر التطبيقات',
  'Blocking did not start': 'لم يبدأ الحظر',
  'Select the apps to block first': 'اختر التطبيقات المراد حظرها أولاً',
  'Selected apps are blocked for {d}': 'الحظر مفعّل على التطبيقات المحددة لمدة {d}',
  '15 minutes': '15 دقيقة',
  '1 hour': 'ساعة واحدة',
  '4 hours': '4 ساعات',
  'Until tomorrow morning': 'حتى صباح الغد',
  '{m} minutes': '{m} دقيقة',
  '{h} hours': '{h} ساعة',
  'Block selected apps for\u2026': 'حظر التطبيقات المحددة لمدة…',
  '{n} apps will lose internet until the timer ends.': 'عدد التطبيقات التي ستفقد الإنترنت حتى ينتهي المؤقت: {n}',
  'START TIMER': 'بدء المؤقت',
  'Cancel timed block': 'إلغاء الحظر المؤقت',
  'Timed block cancelled': 'أُلغي الحظر المؤقت',
  'Schedule turned off': 'أُوقفت الجدولة',
  'Schedule saved. Select the apps to block': 'حُفظت الجدولة. اختر التطبيقات المراد حظرها',
  'Schedule saved': 'حُفظت الجدولة',
  'The block list is empty': 'قائمة الحظر فارغة',
  'Copied {n} apps to the clipboard': 'نُسخ {n} تطبيقاً إلى الحافظة',
  'No matching apps found in the clipboard': 'لم يُعثر على تطبيقات مطابقة في الحافظة',
  'Blocked {n} apps': 'تم حظر {n} تطبيقاً',
  'Block list cleared': 'تم مسح قائمة الحظر',
  'Loading apps\u2026': 'جارٍ تحميل التطبيقات…',
  'Could not load the apps list': 'تعذّر تحميل قائمة التطبيقات',
  'Retry': 'إعادة المحاولة',
};

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
    this.lang = '',
  });

  final Set<String> blocked;
  final bool master, running, schedOn, dark, boot, showSystem, vpnGranted;
  final int start, end, days, timedUntil;
  final String error;
  final int themeMode, accent;
  final String lang;

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
        lang: m['lang'] as String? ?? '',
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
          padding: EdgeInsetsDirectional.fromSTEB(20, 14, 14, 14),
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
  final EdgeInsetsGeometry padding;

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
    final sub = on ? (widget.running ? tr('Blocked \u00b7 always') : tr('Selected \u00b7 protection paused')) : tr('Allowed');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => open = !open),
      child: AnimatedSize(
        duration: Duration(milliseconds: 200),
        alignment: Alignment.topCenter,
        child: Container(
          margin: EdgeInsets.only(bottom: 8),
          padding: EdgeInsetsDirectional.fromSTEB(10, 11, 14, 11),
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
                                margin: EdgeInsetsDirectional.only(start: 8),
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.coral.withAlpha(40),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(tr('BLOCKED'),
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
                  padding: EdgeInsetsDirectional.only(top: 12, start: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(a.package, style: TextStyle(fontSize: 12, color: AppColors.hint)),
                      ),
                      OutlinedButton.icon(
                        onPressed: widget.onInfo,
                        icon: Icon(Icons.info_outline, size: 18),
                        label: Text(tr('App info')),
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
        padding: EdgeInsetsDirectional.fromSTEB(16, 6, 16, 0),
        child: TextField(
          onChanged: (v) => setState(() => query = v),
          decoration: InputDecoration(
            hintText: tr('Search {n} apps\u2026', {'n': widget.apps.length}),
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
        margin: EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
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
                    child: Text(tr(segs[i]),
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
      padding: EdgeInsetsDirectional.fromSTEB(20, 18, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(tr(name).toUpperCase(),
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.accent2)),
                SizedBox(width: 8),
                Text(tr('{b} of {t} blocked', {'b': b, 't': list.length}), style: TextStyle(fontSize: 12, color: AppColors.muted)),
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
        SliverToBoxAdapter(child: PageHeader(tr('Apps'), tr('{n} apps', {'n': widget.apps.length}))),
        SliverToBoxAdapter(child: _search()),
        SliverToBoxAdapter(child: _segments()),
        if (items.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(
                child: Text(
                  widget.apps.isEmpty ? tr('No apps found on this device') : tr('No matching apps'),
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
    return h < 12 ? tr('Good morning') : (h < 18 ? tr('Good afternoon') : tr('Good evening'));
  }

  String _time(int m) {
    final h = (m ~/ 60) % 24;
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:${(m % 60).toString().padLeft(2, '0')} ${h < 12 ? tr('AM') : tr('PM')}';
  }

  String _clock(int millis) {
    final d = DateTime.fromMillisecondsSinceEpoch(millis);
    return _time(d.hour * 60 + d.minute);
  }

  Widget _top(BuildContext context) => Padding(
        padding: EdgeInsetsDirectional.fromSTEB(22, 14, 14, 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_greeting(),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.muted)),
                  Text(tr('Block Internet'),
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.6)),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: tr('More'),
              onSelected: (v) {
                if (v == 'timer') onTimer();
                if (v == 'refresh') onRefresh();
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'timer', child: Text(tr('Timed block\u2026'))),
                PopupMenuItem(value: 'refresh', child: Text(tr('Refresh apps'))),
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
      title = tr('Protected');
      sub = '$n of ${apps.length} apps are offline';
    } else if (!st.master) {
      title = tr('Paused');
      sub = tr('Tap the orb to resume');
    } else if (n == 0) {
      title = tr('No apps selected');
      sub = tr('Open Apps and choose what to block');
    } else {
      title = tr('Starting\u2026');
      sub = tr('Waiting for the VPN');
    }
    final second = st.timedActive
        ? tr('Timer until {time}', {'time': _clock(st.timedUntil)})
        : (st.schedOn ? '${_time(st.start)} \u2013 ${_time(st.end)}' : tr('No schedule'));

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
            _pill(Icons.shield_outlined, on ? tr('VPN active') : tr('VPN stopped'), on ? AppColors.accent2 : AppColors.muted),
            _pill(Icons.schedule, second, AppColors.muted),
          ],
        ),
        SizedBox(height: 18),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _quick(Icons.timer_outlined, tr('Timer'), AppColors.coral, onTimer),
              _quick(Icons.event_outlined, tr('Schedule'), AppColors.accent2, () => onGoTab(2)),
              _quick(Icons.apps_rounded, tr('Apps'), AppColors.accent2, () => onGoTab(1)),
              _quick(Icons.settings_outlined, tr('Settings'), AppColors.accent2, () => onGoTab(3)),
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
                    Text(tr('Schedule'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    Text('${_time(st.start)} \u2013 ${_time(st.end)} \u00b7 ${st.schedOn ? tr('on') : tr('off')}',
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
                      Text(on ? tr('TAP TO PAUSE') : tr('TAP TO START'),
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
    return '$h12:${(m % 60).toString().padLeft(2, '0')} ${h < 12 ? tr('AM') : tr('PM')}';
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
        PageHeader(tr('Schedule'), count == 7 ? tr('Every day') : tr('{n} days a week', {'n': count})),
        Expanded(
          child: ListView(
            physics: _drag != null ? NeverScrollableScrollPhysics() : null,
            padding: EdgeInsetsDirectional.fromSTEB(16, 4, 16, 100),
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
                              Text(tr('OFFLINE FOR'),
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                      color: AppColors.muted)),
                              Text(m == 0 ? tr('{h} h', {'h': h}) : tr('{h} h {m} m', {'h': h, 'm': m}),
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
                child: Text(tr('Drag the white handles or tap a time'),
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
                        child: Text(dayLetter(i),
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
                  _timeTile(Icons.nightlight_round, tr('Start'), startMin, AppColors.accent2, true),
                  SizedBox(width: 10),
                  _timeTile(Icons.wb_sunny_outlined, tr('End'), endMin, AppColors.coral, false),
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
                          Text(tr('Schedule enabled'),
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          Text(tr('Applies to the apps you blocked'),
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
                  child: Text(tr('SAVE SCHEDULE'),
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
    final marks = {0: '12 ${tr('AM')}', 6: '6 ${tr('AM')}', 12: '12 ${tr('PM')}', 18: '6 ${tr('PM')}'};
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
          PageHeader(tr('Settings'), tr('Customize how blocking works')),
          Expanded(
            child: ListView(
              padding: EdgeInsetsDirectional.fromSTEB(16, 0, 16, 100),
              children: [
                _status(context),
                _label(tr('Appearance')),
                _themeSwitch(),
                SizedBox(height: 10),
                _accentRow(),
                SizedBox(height: 18),
                _label(tr('Language')),
                _langSwitch(),
                _label(tr('Protection')),
                _group([
                  _tile(Icons.event_outlined, tr('Schedule'), tr('Block automatically by time of day'),
                      trailing: st.schedOn ? '${_time(st.start)} \u2013 ${_time(st.end)}' : tr('Off'),
                      onTap: onOpenSchedule),
                  _tile(Icons.timer_outlined, tr('Timed block'), tr('Block for a fixed period'),
                      trailing: st.timedActive ? tr('Until {time}', {'time': _clock(st.timedUntil)}) : tr('Off'),
                      onTap: onTimer),
                ]),
                _label(tr('Behavior')),
                _group([
                  _tile(Icons.power_settings_new, tr('Start on boot'), tr('Resume protection after restart'),
                      sw: st.boot, on: (v) => onPref('boot', v)),
                  _tile(Icons.apps, tr('Show system apps'), tr('Include system apps in the list'),
                      sw: st.showSystem, on: (v) => onPref('showSystem', v)),
                ]),
                _label(tr('Block list')),
                _group([
                  _tile(Icons.copy_outlined, tr('Copy block list'), tr('Copy the blocked apps to the clipboard'),
                      onTap: onCopy),
                  _tile(Icons.content_paste_outlined, tr('Paste block list'),
                      tr('Block the apps found in the clipboard'),
                      onTap: onPaste),
                  _tile(Icons.delete_sweep_outlined, tr('Unblock all apps'), tr('Give every app its internet back'),
                      onTap: () => _confirmClear(context)),
                ]),
                _label(tr('General')),
                _group([
                  _tile(Icons.vpn_key_outlined, tr('VPN permission'), tr('Needed to block apps'),
                      trailing: st.vpnGranted ? tr('Granted') : tr('Request'), onTap: () => onVpn()),
                  _tile(Icons.battery_saver_outlined, tr('Run in background'), tr('Allow unrestricted battery use'),
                      trailing: tr('Open'), onTap: () => BlockService.openBatterySettings()),
                  _tile(Icons.help_outline, tr('How it works'), tr('What this app does and does not do'),
                      onTap: () => _howItWorks(context)),
                  _tile(Icons.info_outline, tr('About'), tr('Version 1.0'), onTap: () => _about(context)),
                ]),
              ],
            ),
          ),
        ],
      );

  // ---------------------------------------------------------------- status

  Widget _status(BuildContext context) {
    final ok = st.vpnGranted;
    final title = !ok ? tr('Permission needed') : (st.running ? tr('Protection active') : tr('Protection idle'));
    final sub = !ok ? tr('Allow the VPN so blocking can work') : tr('{n} apps in the block list', {'n': st.blocked.length});
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
                child: Text(tr('Grant VPN permission')),
              ),
            )
          else
            Row(
              children: [
                _pill(tr('Diagnostics'), Icons.fact_check_outlined, () => _diagnostics(context)),
                SizedBox(width: 8),
                _pill(tr('Battery'), Icons.battery_saver_outlined, () => BlockService.openBatterySettings()),
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
    return '$h12:${(m % 60).toString().padLeft(2, '0')} ${h < 12 ? tr('AM') : tr('PM')}';
  }

  String _clock(int millis) {
    final d = DateTime.fromMillisecondsSinceEpoch(millis);
    return _time(d.hour * 60 + d.minute);
  }

  void _howItWorks(BuildContext context) => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(tr('How it works')),
          content: Text(
              tr('The app creates a local VPN that carries only the apps you block and drops their traffic, so they have no internet. All other apps work normally. Nothing is sent anywhere and nothing is collected.\n\nAndroid allows only one VPN at a time, so starting another VPN app pauses this one.')),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('OK')))],
        ),
      );

  void _diagnostics(BuildContext context) {
    final rows = <List<String>>[
      [tr('VPN permission'), st.vpnGranted ? tr('Granted') : tr('Missing')],
      [tr('Blocking service'), st.running ? tr('Running') : tr('Stopped')],
      [tr('Apps in block list'), '${st.blocked.length}'],
      [tr('Main switch'), st.master ? tr('On') : tr('Off')],
      [tr('Timed block'), st.timedActive ? tr('Active') : tr('None')],
      [tr('Schedule'), st.schedOn ? '${_time(st.start)} \u2013 ${_time(st.end)}' : tr('Off')],
      [tr('Last error'), st.error.isEmpty ? tr('None') : st.error],
    ];
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Diagnostics')),
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
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Close')))],
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
          opt(tr('System'), Icons.brightness_auto_outlined, 0),
          opt(tr('Dark'), Icons.dark_mode_outlined, 1),
          opt(tr('Light'), Icons.light_mode_outlined, 2),
        ],
      ),
    );
  }

  Widget _accentRow() => Container(
        padding: EdgeInsetsDirectional.fromSTEB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('Accent color'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
                        Text(tr(AppColors.accentNames[i]), style: TextStyle(fontSize: 11, color: AppColors.muted)),
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
        title: Text(tr('Unblock all apps?')),
        content: Text(tr('Every app will get its internet access back.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Unblock all'))),
        ],
      ),
    );
    if (ok == true) onClear();
  }

  void _about(BuildContext context) => showAboutDialog(
        context: context,
        applicationName: tr('Block Internet Access'),
        applicationVersion: '1.0',
        children: [
          Text(tr('Blocks internet access for the apps you choose using a local VPN. No traffic leaves your device and nothing is collected.')),
        ],
      );

  Widget _langSwitch() => Container(
        padding: EdgeInsets.all(6),
        margin: EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            for (final o in [['en', 'English'], ['ar', '\u0627\u0644\u0639\u0631\u0628\u064a\u0629']])
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    applyLang(o[0]);
                    BlockService.setPref('lang', o[0]);
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: L.code == o[0] ? AppColors.accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(o[1],
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: L.code == o[0] ? AppColors.onAccent : AppColors.muted)),
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _label(String t) => Padding(
        padding: EdgeInsetsDirectional.only(start: 4, bottom: 6),
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
                        tr('Block Internet\nAccess'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: -0.4),
                      ),
                      SizedBox(height: 8),
                      Text(tr('Take control of every app\u2019s connection'),
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
                Text(tr('Securing your connections\u2026'),
                    style: TextStyle(fontSize: 12, color: AppColors.muted)),
                SizedBox(height: 18),
                Text(tr('Version 1.0'), style: TextStyle(fontSize: 11, color: Color(0xFF5F6F6D))),
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
              padding: EdgeInsetsDirectional.fromSTEB(28, 56, 28, 24),
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
                  Text(tr('Allow VPN connection'),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
                  SizedBox(height: 8),
                  Text(
                    tr('Block Internet uses a local VPN to cut internet for the apps you choose. No data leaves your device.'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14.5, height: 1.6, color: AppColors.muted),
                  ),
                  SizedBox(height: 22),
                  _point(Icons.check, tr('Only the apps you pick lose internet')),
                  _point(Icons.lock_outline, tr('Everything stays on your phone')),
                  _point(Icons.check, tr('You can turn it off anytime')),
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
                      child: Text(tr('CONTINUE')),
                    ),
                  ),
                  SizedBox(height: 6),
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(tr('Not now'), style: TextStyle(color: AppColors.muted, fontSize: 14)),
                  ),
                  Text(tr('Android will ask you to confirm'),
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
        say(tr('VPN permission is required to block apps'));
        return false;
      }
    }
    final ok = await BlockService.prepareVpn();
    if (!ok) say(tr('VPN permission is required to block apps'));
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
      say(tr('Blocking did not start') + (why.isEmpty ? '' : ': $why'));
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
      say(tr('Select the apps to block first'));
      return;
    }
    if (!await ensureVpn()) return;
    await BlockService.timedBlock(minutes);
    await verifyRunning();
    say(tr('Selected apps are blocked for {d}', {'d': o0(minutes)}));
  }

  Future<void> timer() async {
    final opts = <List<Object>>[
      [tr('15 minutes'), 15],
      [tr('1 hour'), 60],
      [tr('4 hours'), 240],
      [tr('Until tomorrow morning'), _minsToMorning()],
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
              padding: EdgeInsetsDirectional.fromSTEB(20, 12, 20, 16),
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
                  Text(tr('Block selected apps for\u2026'),
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text(tr('{n} apps will lose internet until the timer ends.', {'n': count}),
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
                      child: Text(tr('START TIMER')),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(tr('Cancel'), style: TextStyle(color: AppColors.muted)),
                    ),
                  ),
                  if (st.timedActive)
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, -1),
                        child: Text(tr('Cancel timed block')),
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
      say(tr('Timed block cancelled'));
      return;
    }
    await startTimed(pick);
  }

  String o0(int m) => m < 60
      ? tr('{m} minutes', {'m': m})
      : tr('{h} hours', {'h': (m / 60).toStringAsFixed(m % 60 == 0 ? 0 : 1)});

  Future<bool> schedule(bool on, int s, int e, int d) async {
    if (on && !await ensureVpn()) return false;
    await BlockService.setSchedule(on, s, e, d);
    await reloadState();
    if (!on) {
      say(tr('Schedule turned off'));
    } else if (!apps.any((a) => a.blocked)) {
      say(tr('Schedule saved. Select the apps to block'));
    } else {
      say(tr('Schedule saved'));
    }
    return true;
  }

  Future<void> copyList() async {
    final names = apps.where((a) => a.blocked).map((a) => a.package).toList();
    if (names.isEmpty) {
      say(tr('The block list is empty'));
      return;
    }
    await Clipboard.setData(ClipboardData(text: names.join('\n')));
    say(tr('Copied {n} apps to the clipboard', {'n': names.length}));
  }

  Future<void> pasteList() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final wanted = (data?.text ?? '').split(RegExp(r'[\s,;]+')).where((e) => e.contains('.')).toSet();
    final known = apps.where((a) => wanted.contains(a.package)).toList();
    if (known.isEmpty) {
      say(tr('No matching apps found in the clipboard'));
      return;
    }
    if (!await ensureVpn()) return;
    for (final a in known) {
      a.blocked = true;
    }
    refresh();
    await BlockService.setBlocked(apps.where((x) => x.blocked).map((x) => x.package));
    await verifyRunning();
    say(tr('Blocked {n} apps', {'n': known.length}));
  }

  Future<void> clearList() async {
    for (final a in apps) {
      a.blocked = false;
    }
    refresh();
    await BlockService.setBlocked(<String>[]);
    await reloadState();
    say(tr('Block list cleared'));
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
                        Text(tr('Loading apps\u2026'), style: TextStyle(color: AppColors.muted)),
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
                              Text(tr('Could not load the apps list'),
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                              SizedBox(height: 8),
                              Text(loadError!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: AppColors.muted)),
                              SizedBox(height: 16),
                              FilledButton(onPressed: load, child: Text(tr('Retry'))),
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
          margin: EdgeInsetsDirectional.fromSTEB(14, 0, 14, 12),
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
              NavigationDestination(icon: Icon(Icons.home_rounded), label: tr('Home')),
              NavigationDestination(icon: Icon(Icons.apps_rounded), label: tr('Apps')),
              NavigationDestination(icon: Icon(Icons.timer_outlined), label: tr('Schedule')),
              NavigationDestination(icon: Icon(Icons.settings_outlined), label: tr('Settings')),
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
  applyLang(st.lang);
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
          title: tr('Block Internet Access'),
          theme: buildTheme(AppColors.dark),
          builder: (context, child) => Directionality(
            textDirection: L.rtl ? TextDirection.rtl : TextDirection.ltr,
            child: child!,
          ),
          home: SplashScreen(),
        ),
      );
}

// Alias so the default test generated by `flutter create` (which uses MyApp) still compiles.
typedef MyApp = BlockerApp;
