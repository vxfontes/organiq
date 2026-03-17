import 'package:flutter/material.dart';

import 'package:organiq/shared/components/ib_lib/ib_button.dart';
import 'package:organiq/shared/components/ib_lib/ib_text.dart';
import 'package:organiq/shared/theme/app_colors.dart';
import 'package:organiq/shared/utils/infos_device.dart';

class IBBottomSheet extends StatelessWidget {
  const IBBottomSheet({
    super.key,
    this.title,
    this.child,
    this.subtitle,
    this.primaryLabel,
    this.onPrimaryPressed,
    this.primaryEnabled = true,
    this.primaryLoading = false,
    this.secondaryLabel,
    this.onSecondaryPressed,
    this.secondaryEnabled = true,
    this.secondaryLoading = false,
    this.padding,
    this.showHandle = true,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = true,
    bool isDismissible = true,
    bool smallBottomSheet = true,
    bool isAdaptive = false,
    double paddingTop = 160.0,
    bool isFitWithContent = false,
    bool nativeButtonBackIsEnabled = true,
    bool useRootNavigator = false,
    VoidCallback? onThen,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: AppColors.transparent,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      useRootNavigator: useRootNavigator,
      builder: (sheetContext) {
        return PopScope(
          canPop: nativeButtonBackIsEnabled,
          child: SafeArea(
            top: !InfosDevice.isIOS,
            bottom: !InfosDevice.isIOS,
            child: isAdaptive
                ? _buildAdaptiveBody(sheetContext, child)
                : _buildFixedHeightBody(
                    sheetContext,
                    child,
                    smallBottomSheet: smallBottomSheet,
                    paddingTop: paddingTop,
                    isFitWithContent: isFitWithContent,
                  ),
          ),
        );
      },
    ).then((value) {
      if (onThen != null) onThen();
      return value;
    });
  }

  static Future<T?> showFuture<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = true,
    bool isDismissible = true,
    bool smallBottomSheet = false,
    bool isAdaptive = false,
    double paddingTop = 160.0,
    bool isFitWithContent = false,
    bool nativeButtonBackIsEnabled = true,
    bool useRootNavigator = false,
    VoidCallback? onThen,
  }) async {
    return show<T>(
      context: context,
      child: child,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      smallBottomSheet: smallBottomSheet,
      isAdaptive: isAdaptive,
      paddingTop: paddingTop,
      isFitWithContent: isFitWithContent,
      nativeButtonBackIsEnabled: nativeButtonBackIsEnabled,
      useRootNavigator: useRootNavigator,
      onThen: onThen,
    );
  }

  final String? title;
  final String? subtitle;
  final Widget? child;
  final String? primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final bool primaryEnabled;
  final bool primaryLoading;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;
  final bool secondaryEnabled;
  final bool secondaryLoading;
  final EdgeInsetsGeometry? padding;
  final bool showHandle;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final resolvedPadding =
        padding ??
        EdgeInsets.only(
          left: 20,
          right: 20,
          top: showHandle ? 12 : 20,
          bottom: 20 + bottomInset,
        );
    final hasTitle = title != null && title!.trim().isNotEmpty;
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;
    final hasPrimary = primaryLabel != null && primaryLabel!.trim().isNotEmpty;
    final hasSecondary =
        secondaryLabel != null && secondaryLabel!.trim().isNotEmpty;
    final hasActions = hasPrimary || hasSecondary;

    return SingleChildScrollView(
      padding: resolvedPadding,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHandle) ...[
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (hasTitle) IBText(title!, context: context).subtitulo.build(),
          if (hasSubtitle) ...[
            if (hasTitle) const SizedBox(height: 6),
            IBText(subtitle!, context: context).muted.build(),
          ],
          if (child != null) ...[
            if (hasTitle || hasSubtitle) const SizedBox(height: 12),
            child!,
          ],
          if (hasActions) ...[
            const SizedBox(height: 16),
            if (hasPrimary)
              IBButton(
                label: primaryLabel!,
                loading: primaryLoading,
                onPressed: primaryEnabled ? onPrimaryPressed : null,
                variant: IBButtonVariant.primary,
              ),
            if (hasSecondary) ...[
              const SizedBox(height: 8),
              IBButton(
                label: secondaryLabel!,
                loading: secondaryLoading,
                onPressed: secondaryEnabled ? onSecondaryPressed : null,
                variant: IBButtonVariant.secondary,
              ),
            ],
          ],
        ],
      ),
    );
  }

  static Widget _buildAdaptiveBody(BuildContext context, Widget child) {
    return Stack(
      children: [
        Container(color: AppColors.transparent),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Wrap(
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height * 0.50,
                    ),
                    child: child,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildFixedHeightBody(
    BuildContext context,
    Widget child, {
    required bool smallBottomSheet,
    required double paddingTop,
    required bool isFitWithContent,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final fixedHeight = (screenHeight * 0.8 - paddingTop).clamp(
      220.0,
      screenHeight * 0.8,
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: isFitWithContent
            ? child
            : SizedBox(
                height: smallBottomSheet ? screenHeight * 0.5 : fixedHeight,
                child: child,
              ),
      ),
    );
  }
}
