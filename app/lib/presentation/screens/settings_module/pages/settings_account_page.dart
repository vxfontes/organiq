import 'package:flutter/material.dart';
import 'package:inbota/modules/auth/data/models/auth_user_model.dart';
import 'package:inbota/presentation/screens/settings_module/controller/settings_account_controller.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/state/ib_state.dart';

class SettingsAccountPage extends StatefulWidget {
  const SettingsAccountPage({super.key});

  @override
  State<SettingsAccountPage> createState() => _SettingsAccountPageState();
}

class _SettingsAccountPageState extends IBState<SettingsAccountPage, SettingsAccountController> {
  @override
  void initState() {
    super.initState();
    controller.load();
    controller.error.addListener(_onErrorChanged);
  }

  @override
  void dispose() {
    controller.error.removeListener(_onErrorChanged);
    super.dispose();
  }

  void _onErrorChanged() {
    final error = controller.error.value;
    if (error != null && error.isNotEmpty && mounted) {
      IBSnackBar.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const IBLightAppBar(title: 'Minha conta'),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          controller.loading,
          controller.user,
        ]),
        builder: (context, _) {
          final loading = controller.loading.value;
          final user = controller.user.value;

          if (loading && user == null) {
            return const Center(
              child: IBLoader(label: 'Carregando conta...'),
            );
          }

          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              children: [
                IBText('Minha conta', context: context).subtitulo.build(),
                const SizedBox(height: 6),
                IBText(
                  'Revise seus dados cadastrados.',
                  context: context,
                ).muted.build(),
                const SizedBox(height: 16),
                _buildProfileCard(context, user),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, AuthUserModel? user) {
    return IBCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IBText('Dados do perfil', context: context).subtitulo.build(),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            label: 'Nome',
            value: _resolveValue(user?.displayName),
          ),
          const Divider(height: 24),
          _buildInfoRow(
            context,
            label: 'Email',
            value: _resolveValue(user?.email),
          ),
          const Divider(height: 24),
          _buildInfoRow(
            context,
            label: 'Idioma',
            value: _resolveValue(user?.locale),
          ),
          const Divider(height: 24),
          _buildInfoRow(
            context,
            label: 'Fuso horario',
            value: _resolveValue(user?.timezone),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IBText(label, context: context).caption.build(),
        const SizedBox(height: 6),
        IBText(value, context: context).body.build(),
      ],
    );
  }

  String _resolveValue(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return '-';
    return trimmed;
  }
}
