import 'package:flutter/material.dart';
import 'package:block_internet/models/app_item.dart';
import 'package:block_internet/services/block_service.dart';
import 'package:block_internet/theme.dart';
import 'package:block_internet/widgets/app_card.dart';
import 'package:block_internet/widgets/common.dart';

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
