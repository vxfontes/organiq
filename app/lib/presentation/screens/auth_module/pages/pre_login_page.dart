import 'package:flutter/material.dart';

import 'package:organiq/presentation/routes/app_navigation.dart';
import 'package:organiq/presentation/routes/app_routes.dart';
import 'package:organiq/presentation/screens/auth_module/components/auth_background.dart';
import 'package:organiq/shared/components/ib_lib/ib_button.dart';
import 'package:organiq/shared/components/ib_lib/ib_icon.dart';
import 'package:organiq/shared/components/ib_lib/ib_text.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class PreLoginPage extends StatelessWidget {
  const PreLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 750),
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
                          child: _HeroCard(constraints: constraints),
                        ),
                        const SizedBox(height: 24),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 600),
                          curve: const Interval(0.12, 1, curve: Curves.easeOutCubic),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, (1 - value) * 16),
                                child: child,
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              IBText('Sua rotina mais leve', context: context)
                                  .titulo
                                  .align(TextAlign.center)
                                  .build(),
                              const SizedBox(height: 12),
                              IBText(
                                'Organize tarefas, lembretes, listas de compras e projetos em um só lugar.',
                                context: context,
                              ).muted.align(TextAlign.center).build(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 560),
                          curve: const Interval(0.2, 1, curve: Curves.easeOutCubic),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, (1 - value) * 12),
                                child: child,
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              IBButton(
                                label: 'Começar',
                                onPressed: () => AppNavigation.push(AppRoutes.signup),
                              ),
                              const SizedBox(height: 12),
                              IBButton(
                                label: 'Já tenho conta',
                                onPressed: () => AppNavigation.push(AppRoutes.login),
                                variant: IBButtonVariant.ghost,
                              ),
                            ],
                          ),
                        ),
                      ],
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.constraints});

  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final height = (constraints.maxHeight * 0.48).clamp(320.0, 420.0);
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surface,
              AppColors.primary50,
              AppColors.ai50,
            ],
            stops: [0.0, 0.55, 1.0],
          ),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.text.withAlpha((0.08 * 255).round()),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: AppColors.surface.withAlpha((0.9 * 255).round()),
              blurRadius: 12,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              const Positioned(
                top: -40,
                left: -30,
                child: _HeroGlow(color: AppColors.primary200, size: 150),
              ),
              const Positioned(
                bottom: -50,
                right: -40,
                child: _HeroGlow(color: AppColors.ai100, size: 180),
              ),
              const Positioned(
                top: 26,
                left: 22,
                child: _MiniCard(
                  icon: IBIcon.autoAwesomeRounded,
                  title: 'Ações inteligentes',
                  subtitle: 'Rotinas rápidas',
                  accent: AppColors.ai600,
                ),
              ),
              const Positioned(
                bottom: 28,
                right: 18,
                child: _MiniCard(
                  icon: IBIcon.taskAltRounded,
                  title: 'Listas claras',
                  subtitle: 'Tudo em ordem',
                  accent: AppColors.success600,
                ),
              ),
              const Positioned(
                bottom: 80,
                left: 18,
                child: _MiniCard(
                  icon: IBIcon.notificationsActiveRounded,
                  title: 'Lembretes',
                  subtitle: 'Na hora certa',
                  accent: AppColors.warning500,
                ),
              ),
              Center(
                child: _LogoOrb(
                  child: Image.asset(
                    'assets/app_icon.png',
                    width: 120,
                    height: 120,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoOrb extends StatelessWidget {
  const _LogoOrb({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary100,
            AppColors.primary50,
            AppColors.surface,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary600.withAlpha((0.2 * 255).round()),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Center(child: child),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha((0.92 * 255).round()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withAlpha((0.08 * 255).round()),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withAlpha((0.14 * 255).round()),
              shape: BoxShape.circle,
            ),
            child: IBIcon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IBText(title, context: context).label.build(),
              IBText(subtitle, context: context).caption.build(),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroGlow extends StatelessWidget {
  const _HeroGlow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final glowColor = color.withAlpha((0.26 * 255).round());
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: glowColor,
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: size * 0.6,
            spreadRadius: size * 0.1,
          ),
        ],
      ),
    );
  }
}
