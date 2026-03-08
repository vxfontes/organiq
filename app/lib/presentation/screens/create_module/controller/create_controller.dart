import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart';
import 'package:inbota/modules/events/domain/usecases/delete_event_usecase.dart';
import 'package:inbota/modules/inbox/data/models/inbox_confirm_input.dart';
import 'package:inbota/modules/inbox/data/models/inbox_confirm_output.dart';
import 'package:inbota/modules/inbox/data/models/inbox_create_batch_result.dart';
import 'package:inbota/modules/inbox/data/models/inbox_create_input.dart';
import 'package:inbota/modules/inbox/data/models/inbox_create_line_result.dart';
import 'package:inbota/modules/inbox/data/models/inbox_item_output.dart';
import 'package:inbota/modules/inbox/domain/usecases/confirm_inbox_item_usecase.dart';
import 'package:inbota/modules/inbox/domain/usecases/create_inbox_item_usecase.dart';
import 'package:inbota/modules/inbox/domain/usecases/reprocess_inbox_item_usecase.dart';
import 'package:inbota/modules/reminders/domain/usecases/delete_reminder_usecase.dart';
import 'package:inbota/modules/routines/domain/usecases/delete_routine_usecase.dart';
import 'package:inbota/modules/shopping/domain/usecases/delete_shopping_list_usecase.dart';
import 'package:inbota/modules/tasks/domain/usecases/delete_task_usecase.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/services/speech/speech_transcription_service.dart';
import 'package:inbota/shared/state/ib_state.dart';

class CreateController implements IBController {
  CreateController(
    this._createInboxItemUsecase,
    this._reprocessInboxItemUsecase,
    this._confirmInboxItemUsecase,
    this._speechTranscriptionService,
    this._deleteTaskUsecase,
    this._deleteReminderUsecase,
    this._deleteEventUsecase,
    this._deleteShoppingListUsecase,
    this._deleteRoutineUsecase,
  );

  final CreateInboxItemUsecase _createInboxItemUsecase;
  final ReprocessInboxItemUsecase _reprocessInboxItemUsecase;
  final ConfirmInboxItemUsecase _confirmInboxItemUsecase;
  final ISpeechTranscriptionService _speechTranscriptionService;
  final DeleteTaskUsecase _deleteTaskUsecase;
  final DeleteReminderUsecase _deleteReminderUsecase;
  final DeleteEventUsecase _deleteEventUsecase;
  final DeleteShoppingListUsecase _deleteShoppingListUsecase;
  final DeleteRoutineUsecase _deleteRoutineUsecase;

  final TextEditingController inputController = TextEditingController();
  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<bool> listening = ValueNotifier(false);
  final ValueNotifier<bool> voiceProcessing = ValueNotifier(false);
  final ValueNotifier<bool> voiceAvailable = ValueNotifier(true);
  final ValueNotifier<int> recordingSeconds = ValueNotifier(0);
  final ValueNotifier<String?> error = ValueNotifier(null);
  final ValueNotifier<CreateBatchResult?> batchResult = ValueNotifier(null);

  String? _voiceBaseText;
  String _latestRecognizedText = '';
  String _finalRecognizedText = '';
  Completer<void>? _voiceResultCompleter;
  Timer? _recordingTimer;
  bool _finalizingVoice = false;

  @override
  void dispose() {
    unawaited(_speechTranscriptionService.cancelListening());
    _recordingTimer?.cancel();
    inputController.dispose();
    loading.dispose();
    listening.dispose();
    voiceProcessing.dispose();
    voiceAvailable.dispose();
    recordingSeconds.dispose();
    error.dispose();
    batchResult.dispose();
  }

  void clearInput() {
    if (loading.value || voiceProcessing.value) return;
    if (listening.value) {
      unawaited(stopVoiceInput());
      return;
    }
    inputController.clear();
    error.value = null;
  }

  Future<void> toggleVoiceInput() async {
    if (loading.value || voiceProcessing.value) return;

    if (listening.value) {
      await stopVoiceInput();
      return;
    }

    await _startVoiceInput();
  }

  Future<void> stopVoiceInput() async {
    if (_finalizingVoice) return;
    await _speechTranscriptionService.stopListening();
    await _finalizeVoiceInput();
  }

  Future<void> _startVoiceInput() async {
    error.value = null;

    final ready = await _speechTranscriptionService.ensureInitialized(
      onStatus: _onSpeechStatus,
      onError: _onSpeechError,
    );
    voiceAvailable.value = ready;
    if (!ready) {
      error.value =
          'Não foi possível acessar o microfone. Verifique as permissões do app.';
      return;
    }

    _voiceBaseText = inputController.text.trimRight();
    FocusManager.instance.primaryFocus?.unfocus();
    _latestRecognizedText = '';
    _finalRecognizedText = '';
    _voiceResultCompleter = Completer<void>();
    recordingSeconds.value = 0;
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      recordingSeconds.value += 1;
    });

    final started = await _speechTranscriptionService.startListening(
      onResult: _onSpeechResult,
    );
    if (!started) {
      listening.value = false;
      _recordingTimer?.cancel();
      error.value = 'Não foi possível iniciar a transcrição por voz.';
      return;
    }

    listening.value = true;
  }

  void _onSpeechResult(String recognizedWords, {required bool isFinal}) {
    final spokenText = recognizedWords.trim();
    if (spokenText.isEmpty) return;

    _latestRecognizedText = spokenText;

    if (isFinal) {
      _finalRecognizedText = spokenText;
      if (_voiceResultCompleter?.isCompleted == false) {
        _voiceResultCompleter?.complete();
      }
    }
  }

  void _onSpeechStatus(String status) {
    final normalized = status.trim().toLowerCase();
    if (normalized == 'listening') {
      listening.value = true;
      return;
    }

    if (normalized == 'notlistening' || normalized == 'done') {
      if (listening.value && !_finalizingVoice) {
        unawaited(_finalizeVoiceInput());
        return;
      }
      listening.value = false;
      _recordingTimer?.cancel();
    }
  }

  void _onSpeechError(String message) {
    listening.value = false;
    _recordingTimer?.cancel();
    if (_voiceResultCompleter?.isCompleted == false) {
      _voiceResultCompleter?.complete();
    }
    if (!_finalizingVoice) {
      voiceProcessing.value = false;
      _clearVoiceSessionState();
    }

    if (_latestRecognizedText.trim().isNotEmpty ||
        _finalRecognizedText.trim().isNotEmpty) {
      return;
    }

    error.value = message.isNotEmpty
        ? 'Transcrição de voz: $message'
        : 'Falha na transcrição por voz.';
  }

  Future<void> _finalizeVoiceInput() async {
    if (_finalizingVoice) return;
    _finalizingVoice = true;

    listening.value = false;
    _recordingTimer?.cancel();
    voiceProcessing.value = true;

    final transcript = await _resolveTranscript();
    if (transcript.isNotEmpty) {
      final baseText = (_voiceBaseText ?? '').trimRight();
      final nextText = baseText.isEmpty ? transcript : '$baseText\n$transcript';
      inputController.value = TextEditingValue(
        text: nextText,
        selection: TextSelection.collapsed(offset: nextText.length),
      );
    } else if (error.value == null || error.value!.trim().isEmpty) {
      error.value = 'Não foi possível transcrever o audio.';
    }

    _clearVoiceSessionState();
    voiceProcessing.value = false;
    _finalizingVoice = false;
  }

  Future<String> _resolveTranscript() async {
    final directFinal = _finalRecognizedText.trim();
    if (directFinal.isNotEmpty) return directFinal;

    final completer = _voiceResultCompleter;
    if (completer != null && !completer.isCompleted) {
      await Future.any([
        completer.future,
        Future<void>.delayed(const Duration(milliseconds: 900)),
      ]);
    }

    final finalized = _finalRecognizedText.trim();
    if (finalized.isNotEmpty) return finalized;
    return _latestRecognizedText.trim();
  }

  void _clearVoiceSessionState({bool resetTimer = true}) {
    _voiceBaseText = null;
    _latestRecognizedText = '';
    _finalRecognizedText = '';
    _voiceResultCompleter = null;
    if (resetTimer) {
      recordingSeconds.value = 0;
    }
  }

  Future<bool> processText() async {
    if (loading.value || voiceProcessing.value) return false;
    if (listening.value) {
      await stopVoiceInput();
    }

    final rawText = inputController.text;
    final lines = _extractLines(rawText);
    if (lines.isEmpty) {
      error.value = 'Digite algo para processar com IA.';
      return false;
    }

    loading.value = true;
    error.value = null;

    var success = 0;
    var failed = 0;
    var tasks = 0;
    var reminders = 0;
    var events = 0;
    var shoppingLists = 0;
    var shoppingItems = 0;
    var routines = 0;

    final lineResults = <CreateLineResult>[];

    for (final line in lines) {
      final processing = await _processSingleLine(line);

      processing.fold(
        (failureMessage) {
          failed++;
          lineResults.add(
            CreateLineResult(
              sourceText: line,
              status: CreateLineStatus.failed,
              message: failureMessage,
            ),
          );
        },
        (output) {
          success++;

          final type = output.type.trim().toLowerCase();
          switch (type) {
            case 'task':
              tasks++;
              break;
            case 'reminder':
              reminders++;
              break;
            case 'event':
              events++;
              break;
            case 'routine':
              routines++;
              break;
            case 'shopping':
              if (output.shoppingList != null) {
                shoppingLists++;
              }
              shoppingItems += output.shoppingItems.length;
              break;
          }

          final entityLabel = _entityLabel(type);
          final entityRef = _resolveEntityRef(output);
          lineResults.add(
            CreateLineResult(
              sourceText: line,
              status: CreateLineStatus.success,
              message: '$entityLabel criado com sucesso.',
              entityType: entityRef.$1,
              entityId: entityRef.$2,
            ),
          );
        },
      );
    }

    batchResult.value = CreateBatchResult(
      totalInputs: lines.length,
      successCount: success,
      failedCount: failed,
      tasksCount: tasks,
      remindersCount: reminders,
      eventsCount: events,
      shoppingListsCount: shoppingLists,
      shoppingItemsCount: shoppingItems,
      routinesCount: routines,
      lines: lineResults,
    );

    loading.value = false;

    if (failed > 0 && success == 0) {
      error.value = 'Não foi possível processar os textos enviados.';
      return false;
    }

    return true;
  }

  Future<Either<String, InboxConfirmOutput>> _processSingleLine(
    String line,
  ) async {
    final createResult = await _createInboxItemUsecase.call(
      InboxCreateInput(source: 'manual', rawText: line),
    );

    final createdItem = createResult.fold<InboxItemOutput?>(
      (failure) {
        return null;
      },
      (item) {
        return item;
      },
    );

    if (createdItem == null) {
      return Left(_failureMessage(createResult));
    }

    final reprocessResult = await _reprocessInboxItemUsecase.call(
      createdItem.id,
    );
    final processedItem = reprocessResult.fold<InboxItemOutput?>(
      (failure) {
        return null;
      },
      (item) {
        return item;
      },
    );

    if (processedItem == null) {
      return Left(_failureMessage(reprocessResult));
    }

    final confirmInput = InboxConfirmInput.fromSuggestion(
      processedItem,
      fallbackTitle: line,
    );

    if (!confirmInput.isValidForConfirm) {
      return const Left('A IA não retornou dados suficientes para confirmar.');
    }

    final confirmResult = await _confirmInboxItemUsecase.call(confirmInput);
    return confirmResult.fold(
      (failure) => Left(
        (failure.message?.trim().isNotEmpty ?? false)
            ? failure.message!.trim()
            : 'Falha ao confirmar item processado.',
      ),
      Right.new,
    );
  }

  Future<bool> deleteLineResult(CreateLineResult line) async {
    if (!line.canDelete || batchResult.value == null) return false;

    _updateLine(line, (current) => current.copyWith(deleting: true));

    final deleteResult = await _deleteByEntity(
      line.entityType,
      line.entityId ?? '',
    );

    return deleteResult.fold(
      (failure) {
        _updateLine(line, (current) => current.copyWith(deleting: false));
        final message = failure.message?.trim();
        error.value = (message != null && message.isNotEmpty)
            ? message
            : 'Não foi possível excluir item criado.';
        return false;
      },
      (_) {
        _updateLine(
          line,
          (current) => current.copyWith(
            deleting: false,
            deleted: true,
            message: 'Item excluido com sucesso.',
          ),
        );
        return true;
      },
    );
  }

  void _updateLine(
    CreateLineResult line,
    CreateLineResult Function(CreateLineResult current) updater,
  ) {
    final currentBatch = batchResult.value;
    if (currentBatch == null) return;

    final index = currentBatch.lines.indexWhere((entry) {
      return entry.sourceText == line.sourceText &&
          entry.entityId == line.entityId &&
          entry.entityType == line.entityType;
    });
    if (index == -1) return;

    final nextLines = List<CreateLineResult>.from(currentBatch.lines);
    nextLines[index] = updater(nextLines[index]);

    batchResult.value = CreateBatchResult(
      totalInputs: currentBatch.totalInputs,
      successCount: currentBatch.successCount,
      failedCount: currentBatch.failedCount,
      tasksCount: currentBatch.tasksCount,
      remindersCount: currentBatch.remindersCount,
      eventsCount: currentBatch.eventsCount,
      shoppingListsCount: currentBatch.shoppingListsCount,
      shoppingItemsCount: currentBatch.shoppingItemsCount,
      routinesCount: currentBatch.routinesCount,
      lines: nextLines,
    );
  }

  Future<Either<Failure, Unit>> _deleteByEntity(
    CreateEntityType type,
    String id,
  ) {
    switch (type) {
      case CreateEntityType.task:
        return _deleteTaskUsecase.call(id);
      case CreateEntityType.reminder:
        return _deleteReminderUsecase.call(id);
      case CreateEntityType.event:
        return _deleteEventUsecase.call(id);
      case CreateEntityType.shoppingList:
        return _deleteShoppingListUsecase.call(id);
      case CreateEntityType.routine:
        return _deleteRoutineUsecase.call(id);
      case CreateEntityType.unknown:
        return Future.value(
          Left(
            DeleteFailure(message: 'Tipo de item não suportado para exclusao.'),
          ),
        );
    }
  }

  (CreateEntityType, String?) _resolveEntityRef(InboxConfirmOutput output) {
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

  String _failureMessage(Either<Failure, dynamic> either) {
    return either.fold((failure) {
      final message = failure.message?.trim();
      if (message != null && message.isNotEmpty) return message;
      return 'Falha no processamento.';
    }, (_) => 'Falha no processamento.');
  }

  List<String> _extractLines(String rawText) {
    final normalized = rawText.replaceAll('\r\n', '\n').trim();
    if (normalized.isEmpty) return const [];

    final candidateLines = normalized.split('\n');
    final lines = <String>[];

    for (final candidate in candidateLines) {
      final cleaned = _normalizeLine(candidate);
      if (cleaned.isNotEmpty) {
        lines.addAll(_splitIntoAtomicInputs(cleaned));
      }
    }

    if (lines.isNotEmpty) return lines;

    final fallback = _normalizeLine(normalized);
    if (fallback.isEmpty) return const [];
    return _splitIntoAtomicInputs(fallback);
  }

  String _normalizeLine(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';

    final withoutBullet = trimmed.replaceFirst(RegExp(r'^[-*•\d\.)\s]+'), '');
    final withoutConnector = withoutBullet.replaceFirst(
      RegExp(r'^(e|tambem|também)\s+', caseSensitive: false),
      '',
    );
    final withoutPunctuation = withoutConnector.replaceAll(
      RegExp(r'^[,;:\s]+|[,;:\s]+$'),
      '',
    );

    return withoutPunctuation.trim();
  }

  List<String> _splitIntoAtomicInputs(String text) {
    if (text.trim().isEmpty) return const [];

    final firstPass = text
        .split(RegExp(r'[;\n]+'))
        .expand(_splitCommaClauses)
        .toList();

    final secondPass = firstPass
        .expand(_splitByActionConnector)
        .map(_normalizeLine)
        .where((line) => line.isNotEmpty)
        .toList();

    final unique = <String>{};
    final ordered = <String>[];
    for (final value in secondPass) {
      final key = value.toLowerCase();
      if (unique.add(key)) {
        ordered.add(value);
      }
    }

    return ordered;
  }

  List<String> _splitCommaClauses(String text) {
    final parts = text.split(',');
    final output = <String>[];
    for (final part in parts) {
      final cleaned = _normalizeLine(part);
      if (cleaned.isNotEmpty) {
        output.add(cleaned);
      }
    }
    return output;
  }

  List<String> _splitByActionConnector(String text) {
    final pieces = text.split(
      RegExp(
        r'\s+e\s+(?=(?:me\s+l[eê]mbre|preciso|tenho|quero|devo|comprar|pagar|agendar|marcar|fazer|ligar|enviar|trocar|resolver|buscar|ir|reuni[aã]o|consulta|evento)\b)',
        caseSensitive: false,
      ),
    );
    if (pieces.length <= 1) return [text];
    return pieces;
  }

  String _entityLabel(String type) {
    switch (type) {
      case 'task':
        return 'To-do';
      case 'reminder':
        return 'Lembrete';
      case 'event':
        return 'Evento';
      case 'shopping':
        return 'Lista de compras';
      case 'routine':
        return 'Cronograma';
      default:
        return 'Item';
    }
  }
}
