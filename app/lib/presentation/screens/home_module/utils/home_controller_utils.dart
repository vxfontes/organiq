import 'package:dartz/dartz.dart';
import 'package:inbota/modules/inbox/data/models/inbox_confirm_output.dart';
import 'package:inbota/modules/inbox/data/models/inbox_create_line_result.dart';
import 'package:inbota/presentation/screens/home_module/components/timeline_item.dart';
import 'package:inbota/shared/errors/failures.dart';

class HomeControllerUtils {
  HomeControllerUtils._();

  static TimelineItemType? timelineTypeFromRaw(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'event':
        return TimelineItemType.event;
      case 'task':
        return TimelineItemType.task;
      case 'reminder':
        return TimelineItemType.reminder;
      case 'routine':
        return TimelineItemType.routine;
      default:
        return null;
    }
  }

  static (CreateEntityType, String?) resolveEntityRef(
    InboxConfirmOutput output,
  ) {
    final type = output.type.trim().toLowerCase();

    switch (type) {
      case 'task':
        return (CreateEntityType.task, output.task?.id);
      case 'reminder':
        return (CreateEntityType.reminder, output.reminder?.id);
      case 'event':
        return (CreateEntityType.event, output.event?.id);
      case 'shopping':
        return (CreateEntityType.shoppingList, output.shoppingList?.id);
      case 'routine':
        return (CreateEntityType.routine, output.routine?.id);
      default:
        return (CreateEntityType.unknown, null);
    }
  }

  static String failureMessage(Either<Failure, dynamic> either) {
    return either.fold((failure) {
      final message = failure.message?.trim();
      if (message != null && message.isNotEmpty) return message;
      return 'Falha no processamento.';
    }, (_) => 'Falha no processamento.');
  }

  static String successMessage(CreateEntityType type) {
    switch (type) {
      case CreateEntityType.task:
        return 'To-do criado com sucesso!';
      case CreateEntityType.reminder:
        return 'Lembrete criado com sucesso!';
      case CreateEntityType.event:
        return 'Evento criado com sucesso!';
      case CreateEntityType.shoppingList:
        return 'Lista de compras criada com sucesso!';
      case CreateEntityType.routine:
        return 'Item de cronograma criado!';
      default:
        return 'Item criado com sucesso!';
    }
  }
}
