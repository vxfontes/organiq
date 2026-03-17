import 'package:flutter/material.dart';
import 'package:inbota/shared/components/ib_lib/ib_text.dart';
import 'package:inbota/shared/theme/app_colors.dart';

enum IBAIResultType {
  task,
  event,
  reminder,
  shopping,
  routine,
  failed,
}

class IBAIResultCard extends StatefulWidget {
  const IBAIResultCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.onConfirm,
    required this.onEdit,
    this.onDismiss,
    this.confidence,
    this.isDeleting = false,
    this.isDeleted = false,
    this.isConfirmed = false,
    this.sourceText,
  });

  final String title;
  final String? subtitle;
  final IBAIResultType type;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;
  final VoidCallback? onDismiss;
  final double? confidence;
  final bool isDeleting;
  final bool isDeleted;
  final bool isConfirmed;
  final String? sourceText;

  @override
  State<IBAIResultCard> createState() => _IBAIResultCardState();
}

class _IBAIResultCardState extends State<IBAIResultCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _typeColor {
    switch (widget.type) {
      case IBAIResultType.task:
        return AppColors.primary600;
      case IBAIResultType.event:
        return AppColors.success600;
      case IBAIResultType.reminder:
        return AppColors.ai600;
      case IBAIResultType.shopping:
        return AppColors.warning500;
      case IBAIResultType.routine:
        return AppColors.primary700;
      case IBAIResultType.failed:
        return AppColors.danger600;
    }
  }

  IconData get _typeIcon {
    switch (widget.type) {
      case IBAIResultType.task:
        return Icons.check_circle_outline_rounded;
      case IBAIResultType.event:
        return Icons.event_rounded;
      case IBAIResultType.reminder:
        return Icons.notifications_rounded;
      case IBAIResultType.shopping:
        return Icons.shopping_cart_rounded;
      case IBAIResultType.routine:
        return Icons.repeat_rounded;
      case IBAIResultType.failed:
        return Icons.error_outline_rounded;
    }
  }

  String get _typeLabel {
    switch (widget.type) {
      case IBAIResultType.task:
        return 'Tarefa';
      case IBAIResultType.event:
        return 'Evento';
      case IBAIResultType.reminder:
        return 'Lembrete';
      case IBAIResultType.shopping:
        return 'Lista de compras';
      case IBAIResultType.routine:
        return 'Cronograma';
      case IBAIResultType.failed:
        return 'Falha';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isConfirmed) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: 1 - _fadeAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success600.withAlpha((0.08 * 255).round()),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.success600.withAlpha((0.25 * 255).round()),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  IBText(
                    'Item confirmado',
                    context: context,
                  ).caption.color(AppColors.success600).build(),
                ],
              ),
            ),
          );
        },
      );
    }

    if (widget.isDeleted) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: 1 - _fadeAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  IBText(
                    'Item removido',
                    context: context,
                  ).muted.build(),
                ],
              ),
            ),
          );
        },
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _typeColor.withAlpha((0.3 * 255).round()),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _typeColor.withAlpha((0.08 * 255).round()),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _typeColor.withAlpha((0.1 * 255).round()),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _typeIcon,
                      color: _typeColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IBText(
                              _typeLabel,
                              context: context,
                            ).caption.color(_typeColor).build(),
                            if (widget.confidence != null) ...[
                              const SizedBox(width: 8),
                              _ConfidenceBadge(confidence: widget.confidence!),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        IBText(
                          widget.title,
                          context: context,
                        ).label.weight(FontWeight.w700).build(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
                child: IBText(
                  widget.subtitle!,
                  context: context,
                ).caption.color(AppColors.textMuted).build(),
              ),
            ],
            if (widget.sourceText != null && widget.sourceText!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.format_quote_rounded,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: IBText(
                          widget.sourceText!,
                          context: context,
                        ).caption.build(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: widget.isDeleting
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            label: 'Confirmar',
                            icon: Icons.check_rounded,
                            color: _typeColor,
                            onTap: widget.onConfirm,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionButton(
                            label: 'Editar',
                            icon: Icons.edit_rounded,
                            color: AppColors.textMuted,
                            variant: _ActionButtonVariant.outlined,
                            onTap: widget.onEdit,
                          ),
                        ),
                        if (widget.onDismiss != null) ...[
                          const SizedBox(width: 8),
                          _ActionButton(
                            label: '',
                            icon: Icons.close_rounded,
                            color: AppColors.textMuted,
                            variant: _ActionButtonVariant.iconOnly,
                            onTap: widget.onDismiss!,
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.confidence});

  final double confidence;

  @override
  Widget build(BuildContext context) {
    final percentage = (confidence * 100).toInt();
    final color = confidence >= 0.8
        ? AppColors.success600
        : (confidence >= 0.5 ? AppColors.warning500 : AppColors.danger600);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.psychology_rounded,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

enum _ActionButtonVariant {
  filled,
  outlined,
  iconOnly,
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.variant = _ActionButtonVariant.filled,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final _ActionButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final isOutlined = variant == _ActionButtonVariant.outlined;
    final isIconOnly = variant == _ActionButtonVariant.iconOnly;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isIconOnly ? 8 : 12,
            vertical: isIconOnly ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: isOutlined
                ? Colors.transparent
                : (isIconOnly ? Colors.transparent : color),
            borderRadius: BorderRadius.circular(10),
            border: isOutlined
                ? Border.all(color: color, width: 1)
                : (isIconOnly ? Border.all(color: AppColors.border) : null),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: isIconOnly ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Icon(
                icon,
                size: isIconOnly ? 18 : 16,
                color: isOutlined || isIconOnly ? color : AppColors.surface,
              ),
              if (!isIconOnly) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isOutlined ? color : AppColors.surface,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
