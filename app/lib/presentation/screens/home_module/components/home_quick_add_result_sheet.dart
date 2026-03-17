import 'package:flutter/material.dart';
import 'package:organiq/modules/inbox/data/models/inbox_create_line_result.dart';
import 'package:organiq/presentation/routes/app_navigation.dart';
import 'package:organiq/presentation/screens/create_module/components/create_result_line_tile.dart';
import 'package:organiq/presentation/screens/home_module/controller/home_controller.dart';
import 'package:organiq/shared/components/oq_lib/index.dart';

class QuickAddResultSheet extends StatefulWidget {
  const QuickAddResultSheet({
    super.key,
    required this.initialResult,
    required this.controller,
  });

  final CreateLineResult initialResult;
  final HomeController controller;

  @override
  State<QuickAddResultSheet> createState() => QuickAddResultSheetState();
}

class QuickAddResultSheetState extends State<QuickAddResultSheet> {
  late CreateLineResult _result;

  @override
  void initState() {
    super.initState();
    _result = widget.initialResult;
  }

  Future<bool> _onDelete(CreateLineResult result) async {
    setState(() => _result = _result.copyWith(deleting: true));

    final deleteResult = await widget.controller.deleteQuickAddResult(result);

    if (mounted) {
      deleteResult.fold(
        (failure) {
          setState(() => _result = _result.copyWith(deleting: false));
          OQSnackBar.error(context, failure.message ?? 'Erro ao excluir item.');
        },
        (_) {
          setState(
            () => _result = _result.copyWith(
              deleting: false,
              deleted: true,
              message: 'Item excluído com sucesso.',
            ),
          );
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) AppNavigation.pop(null, context);
          });
        },
      );
    }
    return deleteResult.isRight();
  }

  @override
  Widget build(BuildContext context) {
    return OQBottomSheet(
      title: 'Item processado',
      child: Column(
        children: [
          CreateResultLineTile(
            result: _result,
            onDelete: _result.deleted ? null : _onDelete,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
