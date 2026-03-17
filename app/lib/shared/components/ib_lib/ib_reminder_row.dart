import 'package:flutter/material.dart';

import 'package:organiq/shared/components/ib_lib/ib_text.dart';

class IBReminderRow extends StatelessWidget {
  const IBReminderRow({
    super.key,
    required this.title,
    required this.time,
    required this.color,
  });

  final String title;
  final String time;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: IBText(title, context: context).body.build(),
        ),
        IBText(time, context: context).caption.build(),
      ],
    );
  }
}
