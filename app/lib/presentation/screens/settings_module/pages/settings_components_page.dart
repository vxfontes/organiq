import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:organiq/shared/components/ib_lib/index.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class SettingsComponentsPage extends StatelessWidget {
  const SettingsComponentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const IBLightAppBar(title: 'Componentes'),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          IBText('Componentes IB (demo)', context: context).titulo.build(),
          const SizedBox(height: 12),
          IBText(
            'Exemplo rápido com todos os componentes compartilhados.',
            context: context,
          ).body.build(),
          const SizedBox(height: 20),
          const IBTextField(label: 'Texto rápido', hint: 'Escreva aqui...'),
          const SizedBox(height: 16),
          IBText('Buttons', context: context).subtitulo.build(),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              IBButton(label: 'Primário', onPressed: () {}),
              IBButton(
                label: 'Secundário',
                variant: IBButtonVariant.secondary,
                onPressed: () {},
              ),
              IBButton(
                label: 'Ghost',
                variant: IBButtonVariant.ghost,
                onPressed: () {},
              ),
              const IBButton(label: 'Loading', loading: true, onPressed: null),
            ],
          ),
          const SizedBox(height: 24),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              IBChip(label: 'PROCESSING', color: AppColors.ai600),
              IBChip(label: 'NEEDS_REVIEW', color: AppColors.warning500),
              IBChip(label: 'CONFIRMED', color: AppColors.success600),
              IBChip(label: 'ERROR', color: AppColors.danger600),
            ],
          ),
          const SizedBox(height: 24),
          IBCard(
            child: IBText(
              'IBCard com padding padrão.',
              context: context,
            ).body.build(),
          ),
          const SizedBox(height: 24),
          const IBEmptyState(
            title: 'Nada por aqui',
            subtitle: 'Quando tiver itens, eles vão aparecer aqui.',
          ),
          const SizedBox(height: 24),
          const Center(child: IBLoader(label: 'Carregando...')),
          const SizedBox(height: 24),
          IBText('Menu Card', context: context).subtitulo.build(),
          const SizedBox(height: 12),
          const IBMenuCard(
            items: [
              IBMenuItem(
                title: 'Cartão',
                subtitle: 'Gerenciar cartões',
                icon: IBIcon.creditCard,
              ),
              IBMenuItem(
                title: 'Seguros',
                subtitle: 'Proteção e coberturas',
                icon: IBIcon.verifiedUserOutlined,
              ),
            ],
          ),
          const SizedBox(height: 24),
          IBText('Icons', context: context).subtitulo.build(),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              IBIcon(IBIcon.alarmOutlined, color: AppColors.primary700),
              IBIcon(
                IBIcon.eventAvailableOutlined,
                color: AppColors.success600,
              ),
              IBIcon(IBIcon.shoppingBagOutlined, color: AppColors.warning500),
              IBIcon(IBIcon.stickyNote2Outlined, color: AppColors.ai600),
              IBIcon(
                IBIcon.starRounded,
                color: AppColors.surface,
                backgroundColor: AppColors.primary600,
                padding: EdgeInsets.all(6),
                borderRadius: BorderRadius.all(Radius.circular(999)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          IBText('Todos', context: context).subtitulo.build(),
          const SizedBox(height: 12),
          const IBTodoList(
            title: 'Tarefas críticas',
            subtitle: 'Resolva estas primeiro para liberar o restante do dia.',
            items: [
              IBTodoItemData(
                title: 'Revisar sugestões da IA do inbox',
                subtitle: '4 itens aguardando confirmação',
              ),
              IBTodoItemData(
                title: 'Enviar proposta para cliente Alpha',
                subtitle: 'Prazo hoje 17:00',
              ),
              IBTodoItemData(
                title: 'Comprar itens da semana',
                subtitle: 'Lista Casa com 8 itens',
                done: true,
              ),
            ],
          ),
          const SizedBox(height: 24),
          IBText('Cards de overview', context: context).subtitulo.build(),
          const SizedBox(height: 12),
          const IBOverviewCard(
            title: 'Inbox agora',
            subtitle: '12 itens aguardando, 3 em processamento pela IA.',
            chips: [
              IBChip(label: 'PROCESSING 3', color: AppColors.ai600),
              IBChip(label: 'NEEDS_REVIEW 4', color: AppColors.warning500),
              IBChip(label: 'CONFIRMED 5', color: AppColors.success600),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: IBStatCard(
                  title: 'Lembretes',
                  value: '4 hoje',
                  subtitle: '9 próximos',
                  color: AppColors.primary700,
                  icon: IBIcon.alarmOutlined,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: IBStatCard(
                  title: 'Eventos',
                  value: '3 na semana',
                  subtitle: '1 amanhã',
                  color: AppColors.success600,
                  icon: IBIcon.eventAvailableOutlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          IBText('Inbox item', context: context).subtitulo.build(),
          const SizedBox(height: 12),
          const IBInboxItemCard(
            title: 'Pagar internet dia 12',
            subtitle: 'Sugestão: Lembrete · 12/02 09:00',
            statusLabel: 'NEEDS_REVIEW',
            statusColor: AppColors.warning500,
            tags: ['Finanças', 'Casa'],
          ),
          const SizedBox(height: 24),
          IBText('Tags e lembretes', context: context).subtitulo.build(),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              IBTagChip(label: 'Trabalho'),
              IBTagChip(label: 'Projeto QQPAG'),
              IBTagChip(label: 'Finanças', color: AppColors.warning500),
            ],
          ),
          const SizedBox(height: 16),
          const IBCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IBReminderRow(
                  title: 'Enviar documentos do TCC',
                  time: 'Hoje 18:00',
                  color: AppColors.primary700,
                ),
                Divider(height: 20, color: AppColors.border),
                IBReminderRow(
                  title: 'Pagar fatura do cartão',
                  time: 'Amanhã 09:00',
                  color: AppColors.warning500,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          IBText('Variações de IBText', context: context).subtitulo.build(),
          const SizedBox(height: 12),
          IBText('Título', context: context).titulo.build(),
          const SizedBox(height: 6),
          IBText('Subtítulo', context: context).subtitulo.build(),
          const SizedBox(height: 6),
          IBText('Body padrão', context: context).body.build(),
          const SizedBox(height: 6),
          IBText('Muted', context: context).muted.build(),
          const SizedBox(height: 6),
          IBText('Caption', context: context).caption.build(),
          const SizedBox(height: 6),
          IBText('Label', context: context).label.build(),
          const SizedBox(height: 12),
          IBText(
            'Centralizado',
            context: context,
          ).body.align(TextAlign.center).build(),
          const SizedBox(height: 24),
          IBText('App Bar', context: context).subtitulo.build(),
          const SizedBox(height: 12),
          SizedBox(
            height: kToolbarHeight + 16,
            child: IBAppBar(
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
          IBText('App Bar Light', context: context).subtitulo.build(),
          const SizedBox(height: 12),
          const SizedBox(
            height: kToolbarHeight + 16,
            child: IBLightAppBar(title: 'blabla'),
          ),
          const SizedBox(height: 24),
          IBText('Bottom Bar', context: context).subtitulo.build(),
          const SizedBox(height: 12),
          IBBottomNav(currentIndex: 0, onTap: (_) {}),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
