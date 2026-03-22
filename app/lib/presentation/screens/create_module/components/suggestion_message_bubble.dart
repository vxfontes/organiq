import 'package:flutter/material.dart';
import 'package:organiq/modules/suggestions/data/models/suggestion_block.dart';
import 'package:organiq/modules/suggestions/data/models/suggestion_conversation_output.dart';
import 'package:organiq/presentation/screens/create_module/components/suggestion_block_card.dart';
import 'package:organiq/shared/components/oq_lib/index.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class SuggestionMessageBubble extends StatelessWidget {
  const SuggestionMessageBubble({
    super.key,
    required this.message,
    required this.acceptedBlockIds,
    required this.acceptingBlockIds,
    required this.onAcceptBlock,
  });

  final SuggestionConversationMessageOutput message;
  final Set<String> acceptedBlockIds;
  final Set<String> acceptingBlockIds;
  final ValueChanged<SuggestionBlock> onAcceptBlock;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isUser ? AppColors.primary100 : AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(14),
            border: isUser ? null : Border.all(color: AppColors.ai200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.content.trim().isNotEmpty)
                OQText(
                  message.content.trim(),
                  context: context,
                ).label.color(AppColors.text).build(),
              if (!isUser && message.blocks.isNotEmpty) ...[
                if (message.content.trim().isNotEmpty)
                  const SizedBox(height: 10),
                ...message.blocks.map((block) {
                  final blockId = block.id.trim();
                  final accepted = acceptedBlockIds.contains(blockId);
                  final loading = acceptingBlockIds.contains(blockId);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SuggestionBlockCard(
                      block: block,
                      accepted: accepted,
                      loading: loading,
                      onAccept: () => onAcceptBlock(block),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
