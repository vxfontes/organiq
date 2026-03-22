import 'package:flutter/widgets.dart';
import 'package:organiq/shared/components/oq_lib/index.dart';

class CreatePageHeader extends StatelessWidget {
  const CreatePageHeader({super.key, this.subtitle});

  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OQText('Criar', context: context).titulo.build(),
        const SizedBox(height: 6),
        OQText(
          subtitle ??
              'Transforme texto em itens organizados: tarefas, lembretes, eventos e compras.',
          context: context,
        ).muted.build(),
      ],
    );
  }
}
