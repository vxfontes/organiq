import 'package:flutter/material.dart';
import 'package:inbota/shared/components/ib_lib/ib_text.dart';

import 'package:inbota/shared/theme/app_colors.dart';

enum IBAIInputState {
  idle,
  typing,
  ready,
  processing,
}

class IBAIInputArea extends StatefulWidget {
  const IBAIInputArea({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.onVoicePressed,
    this.onSend,
    this.onClear,
    this.onTextChanged,
    this.inputState = IBAIInputState.idle,
    this.isListening = false,
    this.isVoiceAvailable = true,
    this.isLocked = false,
    this.isSending = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final VoidCallback onVoicePressed;
  final VoidCallback? onSend;
  final VoidCallback? onClear;
  final ValueChanged<String>? onTextChanged;
  final IBAIInputState inputState;
  final bool isListening;
  final bool isVoiceAvailable;
  final bool isLocked;
  final bool isSending;

  @override
  State<IBAIInputArea> createState() => _IBAIInputAreaState();
}

class _IBAIInputAreaState extends State<IBAIInputArea>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    widget.controller.addListener(_onTextChanged);
    _hasText = widget.controller.text.trim().isNotEmpty;
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void didUpdateWidget(IBAIInputArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.inputState == IBAIInputState.processing &&
        oldWidget.inputState != IBAIInputState.processing) {
      _pulseController.repeat(reverse: true);
    } else if (widget.inputState != IBAIInputState.processing &&
        oldWidget.inputState == IBAIInputState.processing) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  Color get _borderColor {
    if (widget.isListening) return AppColors.danger600;
    switch (widget.inputState) {
      case IBAIInputState.idle:
        return AppColors.ai200;
      case IBAIInputState.typing:
        return AppColors.ai300;
      case IBAIInputState.ready:
        return AppColors.ai600;
      case IBAIInputState.processing:
        return AppColors.ai600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final isProcessing = widget.inputState == IBAIInputState.processing;
        final glowOpacity =
            isProcessing ? 0.25 + (_pulseAnimation.value * 0.15) : 0.0;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: isProcessing
                ? [
                    BoxShadow(
                      color: AppColors.ai600
                          .withAlpha((glowOpacity * 255).round()),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _borderColor,
                width: isProcessing || widget.isListening ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.label.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 16,
                          color: AppColors.ai600,
                        ),
                        const SizedBox(width: 6),
                        IBText(widget.label, context: context)
                            .label
                            .color(AppColors.ai700)
                            .build(),
                      ],
                    ),
                  ),
                TextField(
                  controller: widget.controller,
                  enabled: !widget.isLocked,
                  readOnly: widget.isLocked,
                  onChanged: widget.onTextChanged,
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  minLines: 5,
                  maxLines: 8,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    height: 1.55,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                      height: 1.55,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.fromLTRB(
                      16,
                      widget.label.isNotEmpty ? 8 : 14,
                      16,
                      8,
                    ),
                  ),
                ),
                _buildVoiceButton(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVoiceButton(BuildContext context) {
    final isActive = widget.isListening;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.danger600.withAlpha((0.1 * 255).round())
            : AppColors.ai600.withAlpha((0.07 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? AppColors.danger600.withAlpha((0.3 * 255).round())
              : AppColors.ai200,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isLocked ? null : widget.onVoicePressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isActive ? Icons.stop_circle_rounded : Icons.mic_rounded,
                    key: ValueKey(isActive),
                    color: isActive
                        ? AppColors.danger600
                        : (widget.isVoiceAvailable
                            ? AppColors.ai600
                            : AppColors.textMuted),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                IBText(
                  isActive
                      ? 'Parar transcrição'
                      : (widget.isVoiceAvailable
                          ? 'Usar microfone'
                          : 'Microfone indisponível'),
                  context: context,
                )
                    .caption
                    .color(
                      isActive
                          ? AppColors.danger600
                          : (widget.isVoiceAvailable
                              ? AppColors.ai600
                              : AppColors.textMuted),
                    )
                    .build(),
                if (isActive) ...[
                  const SizedBox(width: 8),
                  const _PulsingDot(color: AppColors.danger600),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});

  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: widget.color.withAlpha(
              ((0.5 + (_controller.value * 0.5)) * 255).round(),
            ),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
