import 'package:flutter/material.dart';
import 'package:organiq/modules/suggestions/data/models/suggestion_block.dart';
import 'package:organiq/modules/suggestions/data/models/suggestion_conversation_output.dart';
import 'package:organiq/presentation/screens/create_module/components/create_mode_selector.dart';
import 'package:organiq/presentation/screens/create_module/components/create_page_header.dart';
import 'package:organiq/presentation/screens/create_module/components/suggestion_message_bubble.dart';
import 'package:organiq/shared/components/oq_lib/index.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class SuggestionChatView extends StatefulWidget {
  const SuggestionChatView({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.messages,
    required this.loading,
    required this.inputController,
    required this.acceptedBlockIds,
    required this.acceptingBlockIds,
    required this.onSendMessage,
    required this.onResetConversation,
    required this.onAcceptBlock,
  });

  final int mode;
  final ValueChanged<int> onModeChanged;
  final List<SuggestionConversationMessageOutput> messages;
  final bool loading;
  final TextEditingController inputController;
  final Set<String> acceptedBlockIds;
  final Set<String> acceptingBlockIds;
  final Future<bool> Function() onSendMessage;
  final VoidCallback onResetConversation;
  final ValueChanged<SuggestionBlock> onAcceptBlock;

  @override
  State<SuggestionChatView> createState() => _SuggestionChatViewState();
}

class _SuggestionChatViewState extends State<SuggestionChatView> {
  final ScrollController _scrollController = ScrollController();
  int _lastMessageCount = 0;

  @override
  void didUpdateWidget(covariant SuggestionChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != _lastMessageCount) {
      _lastMessageCount = widget.messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            children: [
              const CreatePageHeader(
                subtitle:
                    'Converse com a IA para receber sugestões com base no seu horário.',
              ),
              const SizedBox(height: 14),
              CreateModeSelector(
                mode: widget.mode,
                onModeChanged: widget.onModeChanged,
                enabled: !widget.loading,
              ),
              const SizedBox(height: 14),
              if (widget.messages.isEmpty)
                _WelcomeCard(onResetConversation: widget.onResetConversation)
              else
                ...widget.messages.map(
                  (message) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SuggestionMessageBubble(
                      message: message,
                      acceptedBlockIds: widget.acceptedBlockIds,
                      acceptingBlockIds: widget.acceptingBlockIds,
                      onAcceptBlock: (block) => widget.onAcceptBlock(block),
                    ),
                  ),
                ),
              if (widget.loading)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: OQAIPulseIndicator(message: 'IA está pensando...'),
                  ),
                ),
            ],
          ),
        ),
        _OQChatInputArea(
          controller: widget.inputController,
          loading: widget.loading,
          onSendMessage: widget.onSendMessage,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Welcome card
// ---------------------------------------------------------------------------

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.onResetConversation});

  final VoidCallback onResetConversation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAi,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ai200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OQText(
            'Oi! Sou sua assistente de planejamento.',
            context: context,
          ).subtitulo.build(),
          const SizedBox(height: 6),
          OQText(
            'Me conte sobre horários livres, metas ou prioridades.',
            context: context,
          ).body.color(AppColors.textMuted).build(),
          const SizedBox(height: 8),
          OQText(
            'Exemplos:',
            context: context,
          ).caption.color(AppColors.textMuted).build(),
          const SizedBox(height: 4),
          OQText(
            '• Tenho 2h livres amanhã de tarde\n'
            '• Quero um plano de estudos para a semana\n'
            '• O que priorizo hoje?',
            context: context,
          ).caption.color(AppColors.textMuted).build(),
          const SizedBox(height: 10),
          OQButton(
            label: 'Limpar conversa',
            variant: OQButtonVariant.ghostAi,
            onPressed: onResetConversation,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chat input — mesmo DNA visual do OQAIInputArea, adaptado para chat
// ---------------------------------------------------------------------------

class _OQChatInputArea extends StatefulWidget {
  const _OQChatInputArea({
    required this.controller,
    required this.loading,
    required this.onSendMessage,
  });

  final TextEditingController controller;
  final bool loading;
  final Future<bool> Function() onSendMessage;

  @override
  State<_OQChatInputArea> createState() => _OQChatInputAreaState();
}

class _OQChatInputAreaState extends State<_OQChatInputArea>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  late final Animation<double> _pulseAnimation = Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

  bool _hasText = false;

  @override
  void initState() {
    super.initState();
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
  void didUpdateWidget(covariant _OQChatInputArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.loading && !oldWidget.loading) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.loading && oldWidget.loading) {
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
    if (widget.loading || _hasText) return AppColors.ai600;
    return AppColors.ai200;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, _) {
            final glowOpacity = widget.loading
                ? 0.25 + (_pulseAnimation.value * 0.15)
                : 0.0;

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: widget.loading
                    ? [
                        BoxShadow(
                          color: AppColors.ai600.withAlpha(
                            (glowOpacity * 255).round(),
                          ),
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
                    width: widget.loading ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        enabled: !widget.loading,
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        onTapOutside: (_) =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                        keyboardType: TextInputType.multiline,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 15,
                          height: 1.55,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Escreva sua mensagem...',
                          hintStyle: TextStyle(
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
                          contentPadding: EdgeInsets.fromLTRB(16, 12, 8, 12),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 8, 10, 10),
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: widget.controller,
                        builder: (context, value, _) {
                          final canSend =
                              !widget.loading &&
                              value.text.trim().isNotEmpty;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: canSend
                                  ? AppColors.ai600
                                  : AppColors.ai200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: canSend
                                    ? widget.onSendMessage
                                    : null,
                                borderRadius: BorderRadius.circular(12),
                                child: Center(
                                  child: widget.loading
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppColors.surface,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.send_rounded,
                                              color: AppColors.surface,
                                              size: 18,
                                            ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
