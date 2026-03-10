import 'package:flutter/material.dart';
import 'package:inbota/modules/inbox/data/models/inbox_create_line_result.dart';
import 'package:inbota/presentation/routes/app_navigation.dart';
import 'package:inbota/presentation/screens/create_module/components/create_result_line_tile.dart';
import 'package:inbota/presentation/screens/home_module/controller/home_controller.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';

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
          IBSnackBar.error(
            context,
            failure.message ?? 'Erro ao excluir item.',
          );
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
    return IBBottomSheet(
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
