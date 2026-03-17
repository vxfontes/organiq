import 'package:flutter/material.dart';
import 'package:organiq/shared/components/ib_lib/ib_text.dart';

class IBLoader extends StatelessWidget {
  const IBLoader({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        if (label != null) ...[
          const SizedBox(height: 12),
          IBText(label!, context: context).body.build(),
        ],
      ],
    );
  }
}
