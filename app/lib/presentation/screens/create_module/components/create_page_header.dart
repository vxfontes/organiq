import 'package:flutter/widgets.dart';
import 'package:organiq/shared/components/ib_lib/index.dart';

class CreatePageHeader extends StatelessWidget {
  const CreatePageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IBText('Criar', context: context).titulo.build(),
        const SizedBox(height: 6),
        IBText(
          'Transforme texto em itens organizados: tarefas, lembretes, eventos e compras.',
          context: context,
        ).muted.build(),
      ],
    );
  }
}
