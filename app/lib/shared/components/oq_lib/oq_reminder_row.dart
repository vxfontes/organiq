import 'package:flutter/material.dart';

import 'package:organiq/shared/components/oq_lib/oq_text.dart';

class OQReminderRow extends StatelessWidget {
  const OQReminderRow({
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
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(child: OQText(title, context: context).body.build()),
        OQText(time, context: context).caption.build(),
      ],
    );
  }
}
