import 'package:flutter/material.dart';

import 'package:inbota/shared/components/ib_lib/ib_icon.dart';
import 'package:inbota/shared/components/ib_lib/ib_text.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class IBTodoItemData {
  const IBTodoItemData({
    this.id,
    required this.title,
    this.subtitle,
    this.done = false,
  });

  final String? id;
  final String title;
  final String? subtitle;
  final bool done;
}

class IBTodoList extends StatefulWidget {
  const IBTodoList({
    super.key,
    required this.items,
    this.title,
    this.subtitle,
    this.onToggle,
    this.onDelete,
    this.action,
    this.emptyLabel,
  });

  final String? title;
  final String? subtitle;
  final List<IBTodoItemData> items;
  final void Function(int index, bool done)? onToggle;
  final Future<bool> Function(int index)? onDelete;
  final Widget? action;
  final String? emptyLabel;

  @override
  State<IBTodoList> createState() => _IBTodoListState();
}

class _IBTodoListState extends State<IBTodoList> {
  late List<bool> _done;

  @override
  void initState() {
    super.initState();
    _done = widget.items.map((item) => item.done).toList();
  }

  @override
  void didUpdateWidget(covariant IBTodoList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      _done = widget.items.map((item) => item.done).toList();
      return;
    }
    for (var i = 0; i < widget.items.length; i++) {
      if (oldWidget.items[i].done != widget.items[i].done) {
        _done[i] = widget.items[i].done;
      }
    }
  }

  void _toggle(int index) {
    setState(() {
      _done[index] = !_done[index];
    });
    widget.onToggle?.call(index, _done[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withAlpha((0.05 * 255).round()),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title != null) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IBText(widget.title!, context: context).subtitulo.build(),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 4),
                      IBText(widget.subtitle!, context: context).muted.build(),
                    ],
                  ],
                ),
                if (widget.action != null) ...[widget.action!],
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (widget.items.isEmpty && widget.emptyLabel != null) ...[
            SizedBox(
              width: double.infinity,
              child: IBText(widget.emptyLabel!, context: context).muted.build(),
            ),
            const SizedBox(height: 8),
          ],
          for (var i = 0; i < widget.items.length; i++) ...[
            _buildRow(i),
            if (i != widget.items.length - 1)
              const Divider(height: 16, color: AppColors.border),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(int index) {
    final row = _IBTodoRow(
      item: widget.items[index],
      done: _done[index],
      onTap: () => _toggle(index),
    );

    if (widget.onDelete == null) return row;

    final item = widget.items[index];
    final keyBase = item.id?.trim().isNotEmpty == true
        ? item.id!.trim()
        : '${item.title}-$index';

    return Dismissible(
      key: ValueKey('todo-item-$keyBase'),
      direction: DismissDirection.endToStart,
      background: _buildDeleteBackground(),
      confirmDismiss: (_) => widget.onDelete!.call(index),
      child: row,
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.danger600,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const IBIcon(
        IBIcon.deleteOutlineRounded,
        color: AppColors.surface,
        size: 20,
      ),
    );
  }
}

class _IBTodoRow extends StatelessWidget {
  const _IBTodoRow({
    required this.item,
    required this.done,
    required this.onTap,
  });

  final IBTodoItemData item;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: done ? AppColors.textMuted : AppColors.text,
      decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
      decorationColor: AppColors.textMuted,
    );
    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: done ? AppColors.textMuted : AppColors.textMuted,
      decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
      decorationColor: AppColors.textMuted,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppColors.primary600 : AppColors.surface,
                border: Border.all(
                  color: done ? AppColors.primary600 : AppColors.borderStrong,
                  width: 1.4,
                ),
                boxShadow: done
                    ? [
                        BoxShadow(
                          color: AppColors.primary600.withAlpha(
                            (0.25 * 255).round(),
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : [],
              ),
              child: done
                  ? const IBIcon(
                      IBIcon.checkRounded,
                      size: 16,
                      color: AppColors.surface,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: titleStyle),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(item.subtitle!, style: subtitleStyle),
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
