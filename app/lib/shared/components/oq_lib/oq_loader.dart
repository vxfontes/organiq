import 'package:flutter/material.dart';
import 'package:organiq/shared/components/oq_lib/oq_text.dart';

class OQLoader extends StatelessWidget {
  const OQLoader({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        if (label != null) ...[
          const SizedBox(height: 12),
          OQText(label!, context: context).body.build(),
        ],
      ],
    );
  }
}
