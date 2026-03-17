import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:organiq/shared/components/oq_lib/index.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class SettingsComponentsPage extends StatelessWidget {
  const SettingsComponentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OQLightAppBar(title: 'Componentes'),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          OQText('Componentes OQ (demo)', context: context).titulo.build(),
          const SizedBox(height: 12),
          OQText(
            'Exemplo rápido com todos os componentes compartilhados.',
            context: context,
          ).body.build(),
          const SizedBox(height: 20),
          const OQTextField(label: 'Texto rápido', hint: 'Escreva aqui...'),
          const SizedBox(height: 16),
          OQText('Buttons', context: context).subtitulo.build(),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OQButton(label: 'Primário', onPressed: () {}),
              OQButton(
                label: 'Secundário',
                variant: OQButtonVariant.secondary,
                onPressed: () {},
              ),
              OQButton(
                label: 'Ghost',
                variant: OQButtonVariant.ghost,
                onPressed: () {},
              ),
              const OQButton(label: 'Loading', loading: true, onPressed: null),
            ],
          ),
          const SizedBox(height: 24),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OQChip(label: 'PROCESSING', color: AppColors.ai600),
              OQChip(label: 'NEEDS_REVIEW', color: AppColors.warning500),
              OQChip(label: 'CONFIRMED', color: AppColors.success600),
              OQChip(label: 'ERROR', color: AppColors.danger600),
            ],
          ),
          const SizedBox(height: 24),
          OQCard(
            child: OQText(
              'OQCard com padding padrão.',
              context: context,
            ).body.build(),
          ),
          const SizedBox(height: 24),
          const OQEmptyState(
            title: 'Nada por aqui',
            subtitle: 'Quando tiver itens, eles vão aparecer aqui.',
          ),
          const SizedBox(height: 24),
          const Center(child: OQLoader(label: 'Carregando...')),
          const SizedBox(height: 24),
          OQText('Menu Card', context: context).subtitulo.build(),
          const SizedBox(height: 12),
          const OQMenuCard(
            items: [
              OQMenuItem(
                title: 'Cartão',
                subtitle: 'Gerenciar cartões',
                icon: OQIcon.creditCard,
              ),
              OQMenuItem(
                title: 'Seguros',
                subtitle: 'Proteção e coberturas',
                icon: OQIcon.verifiedUserOutlined,
              ),
            ],
          ),
          const SizedBox(height: 24),
          OQText('Icons', context: context).subtitulo.build(),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OQIcon(OQIcon.alarmOutlined, color: AppColors.primary700),
              OQIcon(
                OQIcon.eventAvailableOutlined,
                color: AppColors.success600,
              ),
              OQIcon(OQIcon.shoppingBagOutlined, color: AppColors.warning500),
              OQIcon(OQIcon.stickyNote2Outlined, color: AppColors.ai600),
              OQIcon(
                OQIcon.starRounded,
                color: AppColors.surface,
                backgroundColor: AppColors.primary600,
                padding: EdgeInsets.all(6),
                borderRadius: BorderRadius.all(Radius.circular(999)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          OQText('Todos', context: context).subtitulo.build(),
          const SizedBox(height: 12),
          const OQTodoList(
            title: 'Tarefas críticas',
            subtitle: 'Resolva estas primeiro para liberar o restante do dia.',
            items: [
              OQTodoItemData(
                title: 'Revisar sugestões da IA do inbox',
                subtitle: '4 itens aguardando confirmação',
              ),
              OQTodoItemData(
                title: 'Enviar proposta para cliente Alpha',
                subtitle: 'Prazo hoje 17:00',
              ),
              OQTodoItemData(
                title: 'Comprar itens da semana',
                subtitle: 'Lista Casa com 8 itens',
                done: true,
              ),
            ],
          ),
          const SizedBox(height: 24),
          OQText('Cards de overview', context: context).subtitulo.build(),
          const SizedBox(height: 12),
          const OQOverviewCard(
            title: 'Inbox agora',
            subtitle: '12 itens aguardando, 3 em processamento pela IA.',
            chips: [
              OQChip(label: 'PROCESSING 3', color: AppColors.ai600),
              OQChip(label: 'NEEDS_REVIEW 4', color: AppColors.warning500),
              OQChip(label: 'CONFIRMED 5', color: AppColors.success600),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: OQStatCard(
                  title: 'Lembretes',
                  value: '4 hoje',
                  subtitle: '9 próximos',
                  color: AppColors.primary700,
                  icon: OQIcon.alarmOutlined,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: OQStatCard(
                  title: 'Eventos',
                  value: '3 na semana',
                  subtitle: '1 amanhã',
                  color: AppColors.success600,
                  icon: OQIcon.eventAvailableOutlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          OQText('Inbox item', context: context).subtitulo.build(),
          const SizedBox(height: 12),
          const OQInboxItemCard(
            title: 'Pagar internet dia 12',
            subtitle: 'Sugestão: Lembrete · 12/02 09:00',
            statusLabel: 'NEEDS_REVIEW',
            statusColor: AppColors.warning500,
            tags: ['Finanças', 'Casa'],
          ),
          const SizedBox(height: 24),
          OQText('Tags e lembretes', context: context).subtitulo.build(),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OQTagChip(label: 'Trabalho'),
              OQTagChip(label: 'Projeto QQPAG'),
              OQTagChip(label: 'Finanças', color: AppColors.warning500),
            ],
          ),
          const SizedBox(height: 16),
          const OQCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OQReminderRow(
                  title: 'Enviar documentos do TCC',
                  time: 'Hoje 18:00',
                  color: AppColors.primary700,
                ),
                Divider(height: 20, color: AppColors.border),
                OQReminderRow(
                  title: 'Pagar fatura do cartão',
                  time: 'Amanhã 09:00',
                  color: AppColors.warning500,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OQText('Variações de OQText', context: context).subtitulo.build(),
          const SizedBox(height: 12),
          OQText('Título', context: context).titulo.build(),
          const SizedBox(height: 6),
          OQText('Subtítulo', context: context).subtitulo.build(),
          const SizedBox(height: 6),
          OQText('Body padrão', context: context).body.build(),
          const SizedBox(height: 6),
          OQText('Muted', context: context).muted.build(),
          const SizedBox(height: 6),
          OQText('Caption', context: context).caption.build(),
          const SizedBox(height: 6),
          OQText('Label', context: context).label.build(),
          const SizedBox(height: 12),
          OQText(
            'Centralizado',
            context: context,
          ).body.align(TextAlign.center).build(),
          const SizedBox(height: 24),
          OQText('App Bar', context: context).subtitulo.build(),
          const SizedBox(height: 12),
          SizedBox(
            height: kToolbarHeight + 16,
            child: OQAppBar(
              title: 'titulo',
              subtitle: 'subtitulo',
              padding: const EdgeInsets.only(left: 12, right: 12),
              actions: [
                IconButton(
                  onPressed: () {},
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedSettings01,
                    color: AppColors.surface,
                    size: 22,
                    strokeWidth: 1.8,
                  ),
                ),
              ],
            ),
          ),
          OQText('App Bar Light', context: context).subtitulo.build(),
          const SizedBox(height: 12),
          const SizedBox(
            height: kToolbarHeight + 16,
            child: OQLightAppBar(title: 'blabla'),
          ),
          const SizedBox(height: 24),
          OQText('Bottom Bar', context: context).subtitulo.build(),
          const SizedBox(height: 12),
          OQBottomNav(currentIndex: 0, onTap: (_) {}),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
