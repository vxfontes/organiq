import 'package:flutter/material.dart';

import 'package:organiq/shared/components/oq_lib/oq_text.dart';
import 'package:organiq/shared/theme/app_colors.dart';
import 'auth_background.dart';

class AuthFormScaffold extends StatelessWidget {
  const AuthFormScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.primaryAction,
    this.secondaryAction,
    this.header,
    this.footer,
  });

  final String title;
  final String subtitle;
  final List<Widget> fields;
  final Widget primaryAction;
  final Widget? secondaryAction;
  final Widget? header;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha((0.97 * 255).round()),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withAlpha((0.08 * 255).round()),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: AppColors.surface.withAlpha((0.9 * 255).round()),
            blurRadius: 12,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) ...[
            Center(child: header!),
            const SizedBox(height: 20),
          ],
          OQText(title, context: context).titulo.build(),
          const SizedBox(height: 8),
          OQText(subtitle, context: context).muted.build(),
          const SizedBox(height: 20),
          ...fields,
          const SizedBox(height: 24),
          primaryAction,
          if (secondaryAction != null) ...[
            const SizedBox(height: 8),
            Center(child: secondaryAction!),
          ],
        ],
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AuthBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 720),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, (1 - value) * 24),
                                child: child,
                              ),
                            );
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              card,
                              if (footer != null) ...[
                                const SizedBox(height: 16),
                                Center(child: footer!),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
