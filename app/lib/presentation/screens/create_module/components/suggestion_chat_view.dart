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
              const CreatePageHeader(),
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
        _ChatInputBar(
          controller: widget.inputController,
          loading: widget.loading,
          onSendMessage: widget.onSendMessage,
        ),
      ],
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.onResetConversation});

  final VoidCallback onResetConversation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
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
          ).label.color(AppColors.textMuted).build(),
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
          TextButton(
            onPressed: onResetConversation,
            child: OQText(
              'Limpar conversa',
              context: context,
            ).caption.color(AppColors.ai600).build(),
          ),
        ],
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.loading,
    required this.onSendMessage,
  });

  final TextEditingController controller;
  final bool loading;
  final Future<bool> Function() onSendMessage;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Escreva sua mensagem...',
                  filled: true,
                  fillColor: AppColors.surfaceSoft,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.ai300),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const IconButton(
              tooltip: 'Microfone (em breve)',
              onPressed: null,
              icon: Icon(Icons.mic_rounded, color: AppColors.textMuted),
            ),
            const SizedBox(width: 4),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final canSend = !loading && value.text.trim().isNotEmpty;
                return IconButton.filled(
                  onPressed: canSend ? onSendMessage : null,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.ai600,
                    disabledBackgroundColor: AppColors.ai200,
                  ),
                  icon: loading
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
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
