import 'package:flutter/material.dart';
import 'package:block_internet/models/app_item.dart';
import 'package:block_internet/theme.dart';
import 'package:block_internet/widgets/common.dart';

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
