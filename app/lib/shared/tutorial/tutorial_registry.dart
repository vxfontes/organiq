import 'package:organiq/presentation/routes/app_navigation.dart';
import 'package:organiq/presentation/routes/app_routes.dart';

import 'tutorial_keys.dart';
import 'tutorial_step.dart';

class TutorialRegistry {
  TutorialRegistry._();

  static List<TutorialStep> build() {
    return [
      // 1. Welcome
      const TutorialStep(
        id: 'welcome',
        groupId: 'intro',
        kind: TutorialStepKind.fullScreen,
        tabTarget: TutorialTabTarget.home,
        title: 'Bem-vindo ao Organiq',
        body: 'Seu assistente de produtividade com IA. Em dois minutos você vai conhecer tudo que ele pode fazer por você.',
        heroCta: null, // handled via Próximo button with special label "Começar"
      ),

      // 2. Home overview
      const TutorialStep(
        id: 'home_overview',
        groupId: 'home',
        kind: TutorialStepKind.fullScreen,
        tabTarget: TutorialTabTarget.home,
        title: 'O seu painel',
        body: 'Esta é a Home — o resumo inteligente do seu dia. Tudo que você criou aparece aqui organizado.',
      ),

      // 3. Quick add bar
      TutorialStep(
        id: 'home_quick_add',
        groupId: 'home',
        kind: TutorialStepKind.coachMark,
        tabTarget: TutorialTabTarget.home,
        targetKey: TutorialKeys.homeQuickAddBar,
        bubblePosition: BubblePosition.below,
        title: 'Adicione qualquer coisa',
        body: 'Digite ou fale qualquer coisa aqui. A IA categoriza para você: tarefa, lembrete, evento...',
      ),

      // 4. Carousel
      TutorialStep(
        id: 'home_carousel',
        groupId: 'home',
        kind: TutorialStepKind.coachMark,
        tabTarget: TutorialTabTarget.home,
        targetKey: TutorialKeys.homeCarousel,
        bubblePosition: BubblePosition.below,
        title: 'A seguir',
        body: 'Aqui ficam suas próximas ações do dia — eventos, tarefas e lembretes ordenados por horário.',
      ),

      // 5. Bento row
      TutorialStep(
        id: 'home_bento',
        groupId: 'home',
        kind: TutorialStepKind.coachMark,
        tabTarget: TutorialTabTarget.home,
        targetKey: TutorialKeys.homeBentoRow,
        bubblePosition: BubblePosition.above,
        title: 'Visão geral do dia',
        body: 'O anel de progresso mostra quanto do seu dia você já cumpriu. Ao lado tem seu painel de compras e um insight gerado pela IA.',
      ),

      // 6. Create tab nav button
      TutorialStep(
        id: 'create_tab',
        groupId: 'create',
        kind: TutorialStepKind.coachMark,
        tabTarget: TutorialTabTarget.home,
        targetKey: TutorialKeys.navCreate,
        bubblePosition: BubblePosition.above,
        highlightShape: HighlightShape.circle,
        title: 'O coração do Organiq',
        body: 'Toque aqui para ir à tela de criação com IA — o lugar onde você joga tudo que está na cabeça.',
      ),

      // 7. Create text area
      TutorialStep(
        id: 'create_text_area',
        groupId: 'create',
        kind: TutorialStepKind.coachMark,
        tabTarget: TutorialTabTarget.create,
        targetKey: TutorialKeys.createTextArea,
        bubblePosition: BubblePosition.below,
        title: 'Sua mente digital',
        body: 'Escreva tudo que está na sua cabeça, sem formato, sem ordem. A IA entende linguagem natural.',
      ),

      // 8. Mode selector
      TutorialStep(
        id: 'create_mode',
        groupId: 'create',
        kind: TutorialStepKind.coachMark,
        tabTarget: TutorialTabTarget.create,
        targetKey: TutorialKeys.createModeSelector,
        bubblePosition: BubblePosition.below,
        title: 'Organizar ou Sugerir?',
        body: '"Organizar" classifica o que você escreveu em tarefas, eventos e lembretes. "Sugerir" é um chat — a IA te ajuda a planejar conversando.',
      ),

      // 9. Voice button
      TutorialStep(
        id: 'create_voice',
        groupId: 'create',
        kind: TutorialStepKind.coachMark,
        tabTarget: TutorialTabTarget.create,
        targetKey: TutorialKeys.createVoiceButton,
        bubblePosition: BubblePosition.above,
        highlightShape: HighlightShape.circle,
        title: 'Prefere falar?',
        body: 'Toque no microfone e dite o que está pensando. O texto é transcrito automaticamente.',
      ),

      // 10. Create review explanation
      const TutorialStep(
        id: 'create_review',
        groupId: 'create',
        kind: TutorialStepKind.fullScreen,
        tabTarget: TutorialTabTarget.create,
        title: 'Revise as sugestões',
        body: 'Depois de processar, a IA mostra cada item que vai criar. Você pode editar, remover ou aceitar um por um.',
      ),

      // 11. Confirm all
      const TutorialStep(
        id: 'create_confirm_all',
        groupId: 'create',
        kind: TutorialStepKind.fullScreen,
        tabTarget: TutorialTabTarget.create,
        title: 'Confirmar todos',
        body: 'Quando estiver satisfeito, "Confirmar todos" salva tudo de uma vez — tarefas, eventos e lembretes nos lugares certos.',
      ),

      // 12. Events calendar strip
      TutorialStep(
        id: 'events_strip',
        groupId: 'events',
        kind: TutorialStepKind.coachMark,
        tabTarget: TutorialTabTarget.events,
        targetKey: TutorialKeys.eventsCalendarStrip,
        bubblePosition: BubblePosition.below,
        title: 'Sua agenda unificada',
        body: 'Deslize a tira de datas para navegar. Todos os seus eventos, tarefas com data e lembretes ficam aqui reunidos.',
      ),

      // 13. Events filters
      TutorialStep(
        id: 'events_filters',
        groupId: 'events',
        kind: TutorialStepKind.coachMark,
        tabTarget: TutorialTabTarget.events,
        targetKey: TutorialKeys.eventsFilters,
        bubblePosition: BubblePosition.below,
        title: 'Filtre por tipo',
        body: 'Use os filtros para ver só Eventos, só Tarefas ou só Lembretes — ou todos juntos.',
      ),

      // 14. Schedule overview
      const TutorialStep(
        id: 'schedule_overview',
        groupId: 'schedule',
        kind: TutorialStepKind.fullScreen,
        tabTarget: TutorialTabTarget.schedule,
        title: 'Rotinas semanais',
        body: 'No Cronograma você gerencia hábitos e rotinas recorrentes. Escolha o dia da semana e veja o que acontece.',
      ),

      // 15. Schedule swipe
      TutorialStep(
        id: 'schedule_swipe',
        groupId: 'schedule',
        kind: TutorialStepKind.coachMark,
        tabTarget: TutorialTabTarget.schedule,
        targetKey: TutorialKeys.scheduleRoutineCard,
        bubblePosition: BubblePosition.above,
        title: 'Deslize para agir',
        body: 'Arraste para a esquerda para excluir a rotina. Arraste para a direita para pular só hoje, sem perder a recorrência.',
      ),

      // 16. Shopping overview
      TutorialStep(
        id: 'shopping_overview',
        groupId: 'shopping',
        kind: TutorialStepKind.coachMark,
        tabTarget: TutorialTabTarget.shopping,
        targetKey: TutorialKeys.shoppingHeader,
        bubblePosition: BubblePosition.below,
        title: 'Listas de compras',
        body: 'Aqui ficam suas listas de compras. Você pode criar novas ou deixar a IA organizar enquanto usa o inbox.',
      ),

      // 17. Shopping add
      const TutorialStep(
        id: 'shopping_add',
        groupId: 'shopping',
        kind: TutorialStepKind.fullScreen,
        tabTarget: TutorialTabTarget.shopping,
        title: 'Adicionar itens',
        body: 'Toque no "+" de uma lista para adicionar itens. Ou simplesmente diga "comprar leite e café" no inbox — a IA coloca na lista certa.',
      ),

      // 18. Reminders section — uses pushRoute (pushNamed) so HomeModule stays
      // alive. Extra frames in the controller give the API time to resolve
      // before the coach mark is painted.
      TutorialStep(
        id: 'reminders_sections',
        groupId: 'reminders',
        kind: TutorialStepKind.coachMark,
        tabTarget: TutorialTabTarget.home,
        pushRoute: AppRoutes.rootReminders,
        targetKey: TutorialKeys.remindersSection,
        bubblePosition: BubblePosition.above,
        title: 'Lembretes e Tarefas',
        body: 'Esta tela separa o que vence hoje do que vem nos próximos 7 dias. Toque em qualquer item para editar.',
      ),

      // 19. Settings icon
      TutorialStep(
        id: 'settings_icon',
        groupId: 'settings',
        kind: TutorialStepKind.coachMark,
        tabTarget: TutorialTabTarget.home,
        targetKey: TutorialKeys.appBarSettings,
        bubblePosition: BubblePosition.below,
        highlightShape: HighlightShape.circle,
        title: 'Configurações',
        body: 'A engrenagem no canto superior abre as configurações. Lá você personaliza notificações, horários e muito mais.',
      ),

      // 20. Settings contexts
      const TutorialStep(
        id: 'settings_contexts',
        groupId: 'settings',
        kind: TutorialStepKind.fullScreen,
        tabTarget: TutorialTabTarget.home,
        title: 'Contextos e Flags',
        body: 'Nos Contextos você define as áreas da sua vida — Trabalho, Pessoal, Saúde. A IA usa isso para classificar seus itens com mais precisão.',
      ),

      // 21. Settings notifications
      const TutorialStep(
        id: 'settings_notifications',
        groupId: 'settings',
        kind: TutorialStepKind.fullScreen,
        tabTarget: TutorialTabTarget.home,
        title: 'Notificações inteligentes',
        body: 'Configure os horários de silêncio para não ser interrompido em momentos errados. O Organiq respeita seus limites.',
      ),

      // 22. Conclusion
      TutorialStep(
        id: 'conclusion',
        groupId: 'intro',
        kind: TutorialStepKind.fullScreen,
        tabTarget: TutorialTabTarget.home,
        title: 'Pronto! Você conhece o Organiq',
        body: 'Comece agora criando o seu primeiro item. Escreva qualquer coisa no inbox e a IA cuida do resto.',
        heroCta: TutorialHeroCta(
          label: 'Criar meu primeiro item',
          onTap: () => AppNavigation.navigate(AppRoutes.rootCreate),
        ),
      ),
    ];
  }
}
