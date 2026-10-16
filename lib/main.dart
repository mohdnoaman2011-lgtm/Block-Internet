import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

part 'p2.dart';
part 'p3.dart';
part 'p4.dart';
part 'p5.dart';

// ───────────────────────── النصوص / Strings ─────────────────────────

const Map<String, Map<String, String>> _tr = {
  'ar': {
    'app': 'جدولي',
    'tagline': 'جدولك الجامعي وتذكيرات محاضراتك وواجباتك واختباراتك في مكان واحد',
    'start': 'ابدأ الآن',
    'skip': 'تخطي',
    'next': 'التالي',
    'back': 'رجوع',
    'ob1t': 'أسبوعك الجامعي في مكان واحد',
    'ob1d': 'أضف محاضراتك مرة واحدة ويتكرر جدولك كل أسبوع من السبت إلى الخميس.',
    'ob2t': 'تنبيه لا يفوتك',
    'ob2d': 'نغمة من هاتفك وتنبيه مستمر حتى تضغط إيقاف، حتى لا تفوتك محاضرة.',
    'ob3t': 'واجباتك واختباراتك تحت السيطرة',
    'ob3d': 'سجّل الواجبات والاختبارات ويذكّرك التطبيق قبل الموعد بالوقت الذي تختاره.',
    'getStarted': 'هيا نبدأ',
    'permT': 'اسمح بالتنبيهات',
    'permD': 'لكي يعمل التذكير بدقة حتى والتطبيق مغلق نحتاج هذه الأذونات.',
    'p1t': 'الإشعارات',
    'p1d': 'لإرسال تذكيرات المحاضرات والواجبات',
    'p2t': 'المنبّهات الدقيقة',
    'p2d': 'لتشغيل التنبيه في الدقيقة المحددة',
    'allow': 'السماح',
    'allowed': 'مسموح',
    'allowAll': 'السماح للكل',
    'later': 'لاحقًا',
    'home': 'الرئيسية',
    'schedule': 'الجدول الأسبوعي',
    'reminders': 'التذكيرات',
    'settings': 'الإعدادات',
    'greet': 'صباح الخير',
    'todayTitle': 'الرئيسية',
    'upcomingLec': 'محاضرات الأيام القادمة',
    'breakT': 'استراحة',
    'durT': 'المدة',
    'daySummary': 'ملخص اليوم',
    'lecturesN': 'محاضرات',
    'nextLecture': 'المحاضرة القادمة',
    'details': 'التفاصيل',
    'alertOn': 'التنبيه مفعّل',
    'alertOff': 'التنبيه متوقف',
    'todayLec': 'محاضرات اليوم',
    'viewWeek': 'عرض الأسبوع',
    'lecCount': 'محاضرات اليوم',
    'remCount': 'تذكيرات معلّقة',
    'stDone': 'انتهت',
    'stNow': 'جارية',
    'stUp': 'قادمة',
    'allDone': 'أنهيت محاضرات اليوم',
    'allDoneD': 'استمتع ببقية يومك.',
    'noToday': 'لا محاضرات اليوم',
    'nextDue': 'أقرب موعد تسليم',
    'hall': 'قاعة',
    'emptyT': 'لا يوجد شيء هنا بعد',
    'emptyD': 'أضف أول محاضرة وسيذكّرك جدولي بها كل أسبوع.',
    'addFirst': 'إضافة أول محاضرة',
    'weekTitle': 'الجدول الأسبوعي',
    'addOnDay': 'إضافة محاضرة يوم',
    'noDay': 'لا محاضرات في هذا اليوم',
    'nowLbl': 'الآن',
    'remTitle': 'التذكيرات',
    'upcoming': 'القادمة',
    'completed': 'المكتملة',
    'fAll': 'الكل',
    'fAssign': 'الواجبات',
    'fExam': 'الاختبارات',
    'dueToday': 'يستحق اليوم',
    'noRem': 'لا توجد تذكيرات',
    'noRemD': 'ستظهر هنا الواجبات والاختبارات التي تضيفها.',
    'noneDone': 'لم تُكمل أي تذكير بعد',
    'markDone': 'تحديد كمكتمل',
    'markUndone': 'إعادة فتح التذكير',
    'today': 'اليوم',
    'tomorrow': 'غداً',
    'newT': 'إضافة جديدة',
    'editLecT': 'تعديل المحاضرة',
    'editRemT': 'تعديل التذكير',
    'lecture': 'محاضرة',
    'assignment': 'واجب',
    'exam': 'اختبار',
    'final': 'امتحان',
    'fFinal': 'الامتحانات',
    'title': 'العنوان',
    'titleHint': 'مثال: تسليم التقرير',
    'subject': 'المادة',
    'pickSubject': 'اختر المادة',
    'addSubject': 'إضافة مادة جديدة',
    'room': 'القاعة',
    'roomHint': 'مثال: A12',
    'day': 'اليوم',
    'date': 'التاريخ',
    'time': 'الوقت',
    'startTime': 'البداية',
    'endTime': 'النهاية',
    'endAfter': 'وقت النهاية يجب أن يكون بعد البداية',
    'remindBefore': 'التذكير قبل',
    'soundRow': 'نغمة التنبيه',
    'save': 'حفظ',
    'saved': 'تم الحفظ',
    'deleted': 'تم الحذف',
    'required': 'مطلوب',
    'needTitle': 'اكتب عنوانًا أولًا',
    'delete': 'حذف',
    'edit': 'تعديل',
    'cancel': 'إلغاء',
    'keep': 'إبقاء',
    'yesDelete': 'نعم، احذف',
    'delLecQ': 'حذف هذه المحاضرة؟',
    'delRemQ': 'حذف هذا التذكير؟',
    'delD': 'لا يمكن التراجع عن هذا الإجراء.',
    'openDetails': 'فتح التفاصيل',
    'when': 'الموعد',
    'repeat': 'التكرار',
    'weekly': 'كل أسبوع',
    'type': 'النوع',
    'due': 'موعد التسليم',
    'alertEnabled': 'التنبيه مفعّل',
    'soundTitle': 'نغمة التنبيه',
    'phoneDefault': 'نغمة الهاتف الافتراضية',
    'phoneDefaultSub': 'تستخدم النغمة المحددة في إعدادات هاتفك',
    'pickFromPhone': 'اختيار نغمة من الهاتف',
    'pickFromPhoneSub': 'من نغمات جهازك',
    'chooseTone': 'استعراض',
    'continuous': 'تنبيه مستمر',
    'continuousSub': 'يتكرر الرنين حتى تضغط إيقاف',
    'repeatFor': 'مدة التكرار',
    'untilStop': 'حتى الإيقاف',
    'min1': 'دقيقة',
    'min5': '5 دقائق',
    'min10': '10 دقائق',
    'vibrate': 'الاهتزاز',
    'preview': 'تجربة التنبيه',
    'appearance': 'المظهر',
    'light': 'فاتح',
    'dark': 'داكن',
    'system': 'النظام',
    'language': 'اللغة',
    'timeFormat': 'نظام الوقت',
    'h12': '12 ساعة',
    'h24': '24 ساعة',
    'alerts': 'التنبيهات',
    'defBefore': 'التذكير الافتراضي قبل المحاضرة',
    'data': 'البيانات',
    'subjects': 'المواد الدراسية',
    'clearAll': 'مسح كل البيانات',
    'clearQ': 'مسح كل المحاضرات والتذكيرات؟',
    'clearD': 'ستبقى المواد والإعدادات كما هي.',
    'yesClear': 'نعم، امسح الكل',
    'cleared': 'تم مسح البيانات',
    'about': 'حول التطبيق',
    'version': 'الإصدار 1.0',
    'subjNew': 'اسم مادة جديدة',
    'subjAdd': 'إضافة',
    'subjUsed': 'لا يمكن حذف مادة لها محاضرات',
    'lecN': 'محاضرة',
    'alarmBadge': 'جدولي',
    'alarmIn': 'تبدأ المحاضرة قريبًا',
    'stop': 'إيقاف',
    'snooze': 'غفوة 5 دقائق',
    'previewBody': 'هذه معاينة لنغمة التنبيه',
    'min': 'د',
  },
  'en': {
    'app': 'Jadwali',
    'tagline': 'Your university schedule, with reminders for lectures, assignments and exams in one place',
    'start': 'Get started',
    'skip': 'Skip',
    'next': 'Next',
    'back': 'Back',
    'ob1t': 'Your whole week in one place',
    'ob1d': 'Add your lectures once and your timetable repeats every week, Saturday to Thursday.',
    'ob2t': 'Alerts you will not miss',
    'ob2d': 'Pick a tone from your phone and let it ring until you press stop, so no lecture slips by.',
    'ob3t': 'Assignments and exams under control',
    'ob3d': 'Log assignments and exams and get reminded ahead of time, as early as you choose.',
    'getStarted': "Let's go",
    'permT': 'Allow alerts',
    'permD': 'To remind you on time, even when the app is closed, Jadwali needs these permissions.',
    'p1t': 'Notifications',
    'p1d': 'To send lecture and assignment reminders',
    'p2t': 'Exact alarms',
    'p2d': 'To ring at the exact minute you set',
    'allow': 'Allow',
    'allowed': 'Allowed',
    'allowAll': 'Allow all',
    'later': 'Later',
    'home': 'Home',
    'schedule': 'Weekly schedule',
    'reminders': 'Reminders',
    'settings': 'Settings',
    'greet': 'Good morning',
    'todayTitle': 'Home',
    'upcomingLec': 'Upcoming days',
    'breakT': 'Break',
    'durT': 'Duration',
    'daySummary': 'Day summary',
    'lecturesN': 'lectures',
    'nextLecture': 'Next lecture',
    'details': 'Details',
    'alertOn': 'Alert on',
    'alertOff': 'Alert off',
    'todayLec': "Today's lectures",
    'viewWeek': 'View week',
    'lecCount': 'Lectures today',
    'remCount': 'Pending reminders',
    'stDone': 'Finished',
    'stNow': 'Now',
    'stUp': 'Upcoming',
    'allDone': "You're done for today",
    'allDoneD': 'Enjoy the rest of your day.',
    'noToday': 'No lectures today',
    'nextDue': 'Next due',
    'hall': 'Hall',
    'emptyT': 'Nothing here yet',
    'emptyD': 'Add your first lecture and Jadwali will remind you every week.',
    'addFirst': 'Add first lecture',
    'weekTitle': 'Weekly schedule',
    'addOnDay': 'Add lecture on',
    'noDay': 'No lectures on this day',
    'nowLbl': 'Now',
    'remTitle': 'Reminders',
    'upcoming': 'Upcoming',
    'completed': 'Completed',
    'fAll': 'All',
    'fAssign': 'Assignments',
    'fExam': 'Exams',
    'dueToday': 'Due today',
    'noRem': 'No reminders',
    'noRemD': 'Assignments and exams you add will show up here.',
    'noneDone': 'Nothing completed yet',
    'markDone': 'Mark as done',
    'markUndone': 'Reopen reminder',
    'today': 'Today',
    'tomorrow': 'Tomorrow',
    'newT': 'New',
    'editLecT': 'Edit lecture',
    'editRemT': 'Edit reminder',
    'lecture': 'Lecture',
    'assignment': 'Assignment',
    'exam': 'Quiz',
    'final': 'Final exam',
    'fFinal': 'Finals',
    'title': 'Title',
    'titleHint': 'e.g. Report due',
    'subject': 'Subject',
    'pickSubject': 'Choose subject',
    'addSubject': 'Add new subject',
    'room': 'Hall',
    'roomHint': 'e.g. A12',
    'day': 'Day',
    'date': 'Date',
    'time': 'Time',
    'startTime': 'Starts',
    'endTime': 'Ends',
    'endAfter': 'End time must be after the start',
    'remindBefore': 'Remind me before',
    'soundRow': 'Alert sound',
    'save': 'Save',
    'saved': 'Saved',
    'deleted': 'Deleted',
    'required': 'Required',
    'needTitle': 'Enter a title first',
    'delete': 'Delete',
    'edit': 'Edit',
    'cancel': 'Cancel',
    'keep': 'Keep',
    'yesDelete': 'Yes, delete',
    'delLecQ': 'Delete this lecture?',
    'delRemQ': 'Delete this reminder?',
    'delD': 'This cannot be undone.',
    'openDetails': 'Open details',
    'when': 'When',
    'repeat': 'Repeats',
    'weekly': 'Every week',
    'type': 'Type',
    'due': 'Due',
    'alertEnabled': 'Alert enabled',
    'soundTitle': 'Alert sound',
    'phoneDefault': 'Phone default ringtone',
    'phoneDefaultSub': 'Uses the ringtone set in your phone settings',
    'pickFromPhone': 'Choose a tone from phone',
    'pickFromPhoneSub': 'From your device tones',
    'chooseTone': 'Browse',
    'continuous': 'Continuous alert',
    'continuousSub': 'Keeps ringing until you press stop',
    'repeatFor': 'Repeat for',
    'untilStop': 'Until stopped',
    'min1': '1 min',
    'min5': '5 min',
    'min10': '10 min',
    'vibrate': 'Vibration',
    'preview': 'Test alert',
    'appearance': 'Appearance',
    'light': 'Light',
    'dark': 'Dark',
    'system': 'System',
    'language': 'Language',
    'timeFormat': 'Time format',
    'h12': '12-hour',
    'h24': '24-hour',
    'alerts': 'Alerts',
    'defBefore': 'Default reminder before lecture',
    'data': 'Data',
    'subjects': 'Subjects',
    'clearAll': 'Clear all data',
    'clearQ': 'Clear all lectures and reminders?',
    'clearD': 'Subjects and settings stay as they are.',
    'yesClear': 'Yes, clear all',
    'cleared': 'Data cleared',
    'about': 'About',
    'version': 'Version 1.0',
    'subjNew': 'New subject name',
    'subjAdd': 'Add',
    'subjUsed': 'Cannot delete a subject that has lectures',
    'lecN': 'lectures',
    'alarmBadge': 'Jadwali',
    'alarmIn': 'Your lecture starts soon',
    'stop': 'Stop',
    'snooze': 'Snooze 5 min',
    'previewBody': 'This is a preview of your alert sound',
    'min': 'min',
  },
};

const _daysAr = ['', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
const _daysEn = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _monthsAr = ['', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
const _monthsEn = ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

// أيام الأسبوع الدراسي: السبت إلى الخميس (DateTime.weekday: الإثنين=1 ... الأحد=7)
const List<int> kWeekdays = [6, 7, 1, 2, 3, 4];

const List<Color> kSubjectColors = [
  Color(0xFF2F6BFF),
  Color(0xFF17A673),
  Color(0xFFF08A24),
  Color(0xFF8B5CF6),
  Color(0xFFE0457B),
  Color(0xFF0EA5B7),
  Color(0xFFC99A12),
];

// ───────────────────────── النماذج / Models ─────────────────────────

class Subject {
  Subject({required this.name, required this.color});
  String name;
  int color; // فهرس في kSubjectColors

  Map<String, dynamic> toJson() => {'name': name, 'color': color};
  factory Subject.fromJson(Map<String, dynamic> j) => Subject(name: j['name'] as String, color: (j['color'] ?? 0) as int);
}

class Lecture {
  Lecture({
    required this.id,
    required this.subject,
    required this.weekday,
    required this.start,
    required this.end,
    this.room = '',
    this.before = 10,
    this.on = true,
  });

  int id;
  String subject;
  int weekday; // 1..7
  int start; // دقائق من منتصف الليل
  int end;
  String room;
  int before; // دقائق
  bool on;

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'weekday': weekday,
        'start': start,
        'end': end,
        'room': room,
        'before': before,
        'on': on,
      };

  factory Lecture.fromJson(Map<String, dynamic> j) => Lecture(
        id: j['id'] as int,
        subject: j['subject'] as String,
        weekday: j['weekday'] as int,
        start: j['start'] as int,
        end: j['end'] as int,
        room: (j['room'] ?? '') as String,
        before: (j['before'] ?? 10) as int,
        on: (j['on'] ?? true) as bool,
      );
}

class Reminder {
  Reminder({
    required this.id,
    required this.title,
    required this.kind,
    required this.subject,
    required this.when,
    required this.before,
    this.done = false,
  });

  int id;
  String title;
  String kind; // assignment | exam
  String subject;
  DateTime when;
  int before;
  bool done;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'kind': kind,
        'subject': subject,
        'when': when.millisecondsSinceEpoch,
        'before': before,
        'done': done,
      };

  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
        id: j['id'] as int,
        title: j['title'] as String,
        kind: j['kind'] as String,
        subject: (j['subject'] ?? '') as String,
        when: DateTime.fromMillisecondsSinceEpoch(j['when'] as int),
        before: j['before'] as int,
        done: (j['done'] ?? false) as bool,
      );
}

// ───────────────────────── حالة التطبيق / App state ─────────────────────────

class AppState extends ChangeNotifier {
  late SharedPreferences _p;

  bool onboarded = false;
  String lang = 'ar';
  ThemeMode themeMode = ThemeMode.light;
  bool use24 = false;
  int defBefore = 10;

  String soundMode = 'default'; // default | custom
  String toneUri = '';
  String toneTitle = '';
  bool continuous = true;
  int repeatMin = 0; // 0 = حتى أوقفه
  bool vibrate = true;

  List<Subject> subjects = [];
  List<Lecture> lectures = [];
  List<Reminder> reminders = [];
  int _nextId = 1;

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    onboarded = _p.getBool('onboarded') ?? false;
    lang = _p.getString('lang') ?? 'ar';
    final tm = _p.getString('theme');
    themeMode = ThemeMode.values.firstWhere((m) => m.name == tm, orElse: () => ThemeMode.light);
    use24 = _p.getBool('use24') ?? false;
    defBefore = _p.getInt('defBefore') ?? 10;
    soundMode = _p.getString('soundMode') ?? 'default';
    toneUri = _p.getString('toneUri') ?? '';
    toneTitle = _p.getString('toneTitle') ?? '';
    continuous = _p.getBool('continuous') ?? true;
    repeatMin = _p.getInt('repeatMin') ?? 0;
    vibrate = _p.getBool('vibrate') ?? true;
    final raw = _p.getString('data');
    if (raw != null) {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      lectures = (j['lectures'] as List).map((e) => Lecture.fromJson(e as Map<String, dynamic>)).toList();
      reminders = (j['reminders'] as List).map((e) => Reminder.fromJson(e as Map<String, dynamic>)).toList();
      if (j['subjects'] != null) {
        subjects = (j['subjects'] as List).map((e) => Subject.fromJson(e as Map<String, dynamic>)).toList();
      }
      _nextId = (j['nextId'] ?? 1) as int;
    }
    // مواد المحاضرات القديمة التي لا توجد في القائمة
    for (final l in lectures) {
      if (l.subject.isNotEmpty && !subjects.any((s) => s.name == l.subject)) {
        subjects.add(Subject(name: l.subject, color: subjects.length % kSubjectColors.length));
      }
    }
  }

  Future<void> save() async {
    await _p.setBool('onboarded', onboarded);
    await _p.setString('lang', lang);
    await _p.setString('theme', themeMode.name);
    await _p.setBool('use24', use24);
    await _p.setInt('defBefore', defBefore);
    await _p.setString('soundMode', soundMode);
    await _p.setString('toneUri', toneUri);
    await _p.setString('toneTitle', toneTitle);
    await _p.setBool('continuous', continuous);
    await _p.setInt('repeatMin', repeatMin);
    await _p.setBool('vibrate', vibrate);
    await _p.setString(
      'data',
      jsonEncode({
        'lectures': lectures.map((e) => e.toJson()).toList(),
        'reminders': reminders.map((e) => e.toJson()).toList(),
        'subjects': subjects.map((e) => e.toJson()).toList(),
        'nextId': _nextId,
      }),
    );
  }

  /// يغيّر الحالة ثم يحفظها ويحدّث الواجهة.
  Future<void> update(VoidCallback change) async {
    change();
    notifyListeners();
    await save();
  }

  int newId() => _nextId++;

  bool get ar => lang == 'ar';
  String t(String k) => _tr[lang]![k] ?? k;
  String dayName(int weekday) => ar ? _daysAr[weekday] : _daysEn[weekday];
  String shortDay(int weekday) {
    final n = dayName(weekday);
    return ar ? n : n.substring(0, 3);
  }

  Color colorOf(String subject) {
    for (final s in subjects) {
      if (s.name == subject) return kSubjectColors[s.color % kSubjectColors.length];
    }
    return const Color(0xFF8A94AD);
  }

  String fmtMin(int m) {
    final h = (m ~/ 60) % 24;
    final mm = (m % 60).toString().padLeft(2, '0');
    if (use24) return '${h.toString().padLeft(2, '0')}:$mm';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    final suffix = h < 12 ? (ar ? 'ص' : 'AM') : (ar ? 'م' : 'PM');
    return '$h12:$mm $suffix';
  }

  String fmtDateTime(DateTime d) => fmtMin(d.hour * 60 + d.minute);

  String longDate(DateTime d) {
    final month = ar ? _monthsAr[d.month] : _monthsEn[d.month];
    return ar ? '${dayName(d.weekday)}، ${d.day} $month' : '${dayName(d.weekday)}, $month ${d.day}';
  }

  String shortDate(DateTime d) {
    final month = ar ? _monthsAr[d.month] : _monthsEn[d.month];
    return ar ? '${d.day} $month' : '$month ${d.day}';
  }

  String dayLabel(DateTime d) {
    final now = DateTime.now();
    final a = DateTime(now.year, now.month, now.day);
    final b = DateTime(d.year, d.month, d.day);
    final diff = b.difference(a).inDays;
    if (diff == 0) return t('today');
    if (diff == 1) return t('tomorrow');
    return longDate(d);
  }

  String minLabel(int m) {
    if (m % 1440 == 0) {
      final d = m ~/ 1440;
      if (ar) return d == 1 ? 'يوم' : (d == 2 ? 'يومان' : '$d أيام');
      return d == 1 ? '1 day' : '$d days';
    }
    if (m % 60 == 0) {
      final h = m ~/ 60;
      if (ar) return h == 1 ? 'ساعة' : (h == 2 ? 'ساعتان' : '$h ساعات');
      return '$h h';
    }
    if (ar) return m <= 10 ? '$m دقائق' : '$m دقيقة';
    return '$m min';
  }

  String inText(Duration d) {
    final m = d.inMinutes;
    if (m < 1) return ar ? 'الآن' : 'now';
    if (m < 60) return ar ? 'بعد ${minLabel(m)}' : 'in $m min';
    if (m < 1440) {
      final h = m ~/ 60;
      final r = m % 60;
      if (ar) return 'بعد ${minLabel(h * 60)}${r > 0 ? ' و${minLabel(r)}' : ''}';
      return 'in $h h${r > 0 ? ' $r min' : ''}';
    }
    final days = m ~/ 1440;
    return ar ? 'بعد ${minLabel(days * 1440)}' : 'in $days d';
  }

  String get toneName => soundMode == 'default' || toneTitle.isEmpty ? t('phoneDefault') : toneTitle;
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState app, required super.child}) : super(notifier: app);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

// ───────────────────────── أدوات مساعدة / Helpers ─────────────────────────

DateTime nextOccurrence(int weekday, int minutes, DateTime from) {
  var d = DateTime(from.year, from.month, from.day, minutes ~/ 60, minutes % 60);
  for (var i = 0; i < 9; i++) {
    if (d.weekday == weekday && !d.isBefore(from)) return d;
    d = DateTime(d.year, d.month, d.day + 1, minutes ~/ 60, minutes % 60);
  }
  return d;
}

/// تاريخ يوم الدراسة داخل الأسبوع الحالي (يبدأ السبت).
DateTime weekDate(int weekday) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final sinceSat = (now.weekday - 6) % 7;
  final sat = today.subtract(Duration(days: sinceSat));
  final idx = kWeekdays.indexOf(weekday);
  return DateTime(sat.year, sat.month, sat.day + (idx < 0 ? 0 : idx));
}

// ───────────────────────── الإشعارات / Notifications ─────────────────────────

final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> msgKey = GlobalKey<ScaffoldMessengerState>();
const MethodChannel _ringtoneChannel = MethodChannel('jadwali/ringtone');

/// إلغاء إشعار بأمان: لا يعلق ولا يرمي خطأ مهما حدث.
Future<void> safeCancel(int id) async {
  try {
    await plugin.cancel(id).timeout(const Duration(seconds: 3));
  } catch (_) {}
}

String kindKey(String k) => (k == 'exam' || k == 'final') ? k : 'assignment';

String _payload(int id, String title, String sub) => jsonEncode({'id': id, 'title': title, 'sub': sub});

void openAlarm(String? payload) {
  if (payload == null) return;
  try {
    final j = jsonDecode(payload) as Map<String, dynamic>;
    navKey.currentState?.push(MaterialPageRoute<void>(
      builder: (_) => AlarmPage(id: j['id'] as int, title: j['title'] as String, sub: j['sub'] as String),
    ));
  } catch (_) {}
}

Future<void> initNotifications() async {
  tzdata.initializeTimeZones();
  try {
    final name = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(name));
  } catch (_) {}

  await plugin.initialize(
    const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
    onDidReceiveNotificationResponse: (r) => openAlarm(r.payload),
  );

  final launch = await plugin.getNotificationAppLaunchDetails();
  if (launch?.didNotificationLaunchApp ?? false) {
    final payload = launch!.notificationResponse?.payload;
    WidgetsBinding.instance.addPostFrameCallback((_) => openAlarm(payload));
  }
}

AndroidFlutterLocalNotificationsPlugin? get _android =>
    plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

Future<bool> askNotificationsPermission() async {
  try {
    return (await _android?.requestNotificationsPermission()) ?? false;
  } catch (_) {
    return false;
  }
}

Future<bool> askExactAlarmsPermission() async {
  try {
    return (await _android?.requestExactAlarmsPermission()) ?? false;
  } catch (_) {
    return false;
  }
}

NotificationDetails _details(AppState a) {
  final custom = a.soundMode == 'custom' && a.toneUri.isNotEmpty;
  var h = 0;
  if (custom) {
    for (final c in a.toneUri.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
  }
  // القناة في أندرويد لا تتغير بعد إنشائها، لذلك يتغير معرّفها مع الإعدادات.
  final channelId = 'jadwali_${h}_${a.continuous ? 1 : 0}_${a.vibrate ? 1 : 0}';
  return NotificationDetails(
    android: AndroidNotificationDetails(
      channelId,
      'Jadwali alerts',
      channelDescription: 'Lecture, assignment and exam alerts',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      playSound: true,
      sound: custom ? UriAndroidNotificationSound(a.toneUri) : null,
      enableVibration: a.vibrate,
      fullScreenIntent: true,
      autoCancel: true,
      timeoutAfter: (a.continuous && a.repeatMin > 0) ? a.repeatMin * 60000 : null,
      // FLAG_INSISTENT = 4: يكرر الصوت حتى يتم إغلاق الإشعار
      additionalFlags: a.continuous ? Int32List.fromList(<int>[4]) : null,
    ),
  );
}

Future<void> _schedule(
  int id,
  String title,
  String body,
  DateTime at,
  AppState a, {
  DateTimeComponents? repeat,
}) async {
  final when = tz.TZDateTime.from(at, tz.local);
  Future<void> go(AndroidScheduleMode mode) => plugin.zonedSchedule(
        id,
        title,
        body,
        when,
        _details(a),
        payload: _payload(id, title, body),
        androidScheduleMode: mode,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: repeat,
      );
  try {
    await go(AndroidScheduleMode.exactAllowWhileIdle);
  } catch (_) {
    try {
      await go(AndroidScheduleMode.inexactAllowWhileIdle);
    } catch (_) {}
  }
}

Future<void> scheduleReminder(AppState a, Reminder r) async {
  await safeCancel(r.id);
  if (r.done) return;
  final at = r.when.subtract(Duration(minutes: r.before));
  if (at.isBefore(DateTime.now())) return;
  final kindLbl = a.t(kindKey(r.kind));
  final body = r.subject.isEmpty ? kindLbl : '${r.subject} · $kindLbl';
  await _schedule(r.id, r.title, body, at, a);
}

Future<void> scheduleLecture(AppState a, Lecture l) async {
  await safeCancel(l.id);
  if (!l.on) return;
  final now = DateTime.now();
  var start = nextOccurrence(l.weekday, l.start, now);
  var at = start.subtract(Duration(minutes: l.before));
  while (at.isBefore(now)) {
    start = DateTime(start.year, start.month, start.day + 7, l.start ~/ 60, l.start % 60);
    at = start.subtract(Duration(minutes: l.before));
  }
  final body = l.room.isEmpty ? a.fmtMin(l.start) : '${a.fmtMin(l.start)} · ${a.t('hall')} ${l.room}';
  await _schedule(l.id, l.subject, body, at, a, repeat: DateTimeComponents.dayOfWeekAndTime);
}

/// يعيد جدولة كل شيء (بعد تغيير إعدادات النغمة أو اللغة أو نظام الوقت).
Future<void> rescheduleAll(AppState a) async {
  for (final l in a.lectures) {
    await scheduleLecture(a, l);
  }
  for (final r in a.reminders) {
    await scheduleReminder(a, r);
  }
}

Future<void> previewAlert(AppState a) async {
  const id = 2147483000;
  final payload = _payload(id, a.t('soundTitle'), a.t('previewBody'));
  await plugin.show(id, a.t('soundTitle'), a.t('previewBody'), _details(a), payload: payload);
  openAlarm(payload);
}

Future<void> pickRingtone(AppState a) async {
  try {
    final res = await _ringtoneChannel.invokeMethod<Map<dynamic, dynamic>>('pick', {'current': a.toneUri});
    if (res != null) {
      final uri = (res['uri'] ?? '') as String;
      final title = (res['title'] ?? '') as String;
      if (uri.isNotEmpty) {
        await a.update(() {
          a.toneUri = uri;
          a.toneTitle = title;
          a.soundMode = 'custom';
        });
      }
    }
  } catch (_) {}
}

// ───────────────────────── التطبيق / App ─────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final app = AppState();
  await app.load();
  await initNotifications();
  runApp(JadwaliApp(app: app));
}

/// ألوان التصميم (مطابقة للمخطط) حسب السمة الحالية.
class Pal {
  const Pal({
    required this.bg,
    required this.card,
    required this.text,
    required this.muted,
    required this.line,
    required this.soft,
    required this.pri,
    required this.onPri,
    required this.grn,
    required this.grnSoft,
    required this.red,
    required this.redSoft,
    required this.amber,
    required this.amberText,
    required this.sw,
  });

  final Color bg, card, text, muted, line, soft, pri, onPri, grn, grnSoft, red, redSoft, amber, amberText, sw;

  static const light = Pal(
    bg: Color(0xFFF3F5FB),
    card: Color(0xFFFFFFFF),
    text: Color(0xFF0E1A3D),
    muted: Color(0xFF55627F),
    line: Color(0xFFE2E7F1),
    soft: Color(0xFFEAEEF8),
    pri: Color(0xFF0F2A6B),
    onPri: Color(0xFFFFFFFF),
    grn: Color(0xFF12805C),
    grnSoft: Color(0xFFDDF3EA),
    red: Color(0xFFC62F3E),
    redSoft: Color(0xFFFBE4E7),
    amber: Color(0xFFFFF1D6),
    amberText: Color(0xFF6B4300),
    sw: Color(0xFFC3CCE0),
  );

  static const dark = Pal(
    bg: Color(0xFF080D1E),
    card: Color(0xFF121A33),
    text: Color(0xFFEEF2FF),
    muted: Color(0xFF9DA9CB),
    line: Color(0xFF222D50),
    soft: Color(0xFF1A2444),
    pri: Color(0xFF7EA3FF),
    onPri: Color(0xFF08133A),
    grn: Color(0xFF34D399),
    grnSoft: Color(0xFF103A2E),
    red: Color(0xFFFF8A94),
    redSoft: Color(0xFF3C1A22),
    amber: Color(0xFF3A2E12),
    amberText: Color(0xFFFFD98A),
    sw: Color(0xFF34406A),
  );

  static Pal of(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? dark : light;
}

ThemeData _theme(Brightness b) {
  final p = b == Brightness.dark ? Pal.dark : Pal.light;
  final base = ThemeData(
    useMaterial3: true,
    brightness: b,
    scaffoldBackgroundColor: p.bg,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E5BD8), brightness: b).copyWith(
      primary: p.pri,
      onPrimary: p.onPri,
      surface: p.bg,
      onSurface: p.text,
    ),
  );
  return base.copyWith(
    textTheme: GoogleFonts.ibmPlexSansArabicTextTheme(base.textTheme).apply(bodyColor: p.text, displayColor: p.text),
    appBarTheme: AppBarTheme(backgroundColor: p.bg, foregroundColor: p.text, elevation: 0, scrolledUnderElevation: 0),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.grn : p.sw),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
  );
}

class JadwaliApp extends StatelessWidget {
  const JadwaliApp({super.key, required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      app: app,
      child: Builder(builder: (context) {
        final a = AppScope.of(context);
        return MaterialApp(
          navigatorKey: navKey,
          scaffoldMessengerKey: msgKey,
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(textScaler: mq.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.15)),
              child: child!,
            );
          },
          debugShowCheckedModeBanner: false,
          title: a.t('app'),
          locale: Locale(a.lang),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          themeMode: a.themeMode,
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          home: a.onboarded ? const ShellPage() : const SplashPage(),
        );
      }),
    );
  }
}

// END OF FILE
