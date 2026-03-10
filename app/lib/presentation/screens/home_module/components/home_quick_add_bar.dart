import 'package:flutter/material.dart';
import 'package:inbota/modules/inbox/data/models/inbox_create_line_result.dart';
import 'package:inbota/presentation/screens/home_module/components/home_quick_add_result_sheet.dart';
import 'package:inbota/presentation/screens/home_module/controller/home_controller.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class HomeQuickAddBar extends StatefulWidget {
  const HomeQuickAddBar({super.key, required this.controller});

  final HomeController controller;

  @override
  State<HomeQuickAddBar> createState() => _HomeQuickAddBarState();
}

class _HomeQuickAddBarState extends State<HomeQuickAddBar> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _textController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() => _isLoading = true);
    _focusNode.unfocus();

    final result = await widget.controller.quickAdd(text);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.isRight()) {
          _textController.clear();
        }
      });

      result.fold(
        (error) => IBSnackBar.error(context, error),
        (lineResult) => _showResultBottomSheet(lineResult),
      );
    }
  }

  void _showResultBottomSheet(CreateLineResult initialResult) {
    IBBottomSheet.show(
      context: context,
      isFitWithContent: true,
      child: QuickAddResultSheet(
        initialResult: initialResult,
        controller: widget.controller,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 14),
            child: IBIcon(
              IBIcon.autoAwesomeRounded,
              size: 18,
              color: AppColors.primary700,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                hintText: 'O que você quer organizar hoje?',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 13),
                filled: false,
              ),
            ),
          ),
          if (_hasText || _isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary700,
                      ),
                    )
                  : IconButton(
                      onPressed: _submit,
                      icon: const IBIcon(
                        IBIcon.arrowForwardRounded,
                        color: AppColors.primary700,
                        size: 20,
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}
