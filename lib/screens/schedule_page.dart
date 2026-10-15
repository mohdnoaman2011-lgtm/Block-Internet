import 'package:flutter/material.dart';
import 'package:block_internet/services/block_service.dart';
import 'package:block_internet/theme.dart';
import 'package:block_internet/widgets/common.dart';

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
