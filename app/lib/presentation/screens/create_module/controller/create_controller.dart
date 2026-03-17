import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:organiq/modules/events/domain/usecases/delete_event_usecase.dart';
import 'package:organiq/modules/inbox/data/models/create_processing_line.dart';
import 'package:organiq/modules/inbox/data/models/create_suggestion_item.dart';
import 'package:organiq/modules/inbox/data/models/inbox_confirm_output.dart';
import 'package:organiq/modules/inbox/data/models/inbox_create_batch_result.dart';
import 'package:organiq/modules/inbox/data/models/inbox_create_input.dart';
import 'package:organiq/modules/inbox/data/models/inbox_create_line_result.dart';
import 'package:organiq/modules/inbox/data/models/inbox_item_output.dart';
import 'package:organiq/modules/inbox/data/models/inbox_line_process_success.dart';
import 'package:organiq/modules/inbox/data/models/inbox_suggestion_output.dart';
import 'package:organiq/modules/inbox/domain/usecases/confirm_inbox_item_usecase.dart';
import 'package:organiq/modules/inbox/domain/usecases/create_inbox_item_usecase.dart';
import 'package:organiq/modules/inbox/domain/usecases/reprocess_inbox_item_usecase.dart';
import 'package:organiq/modules/reminders/domain/usecases/delete_reminder_usecase.dart';
import 'package:organiq/modules/routines/domain/usecases/delete_routine_usecase.dart';
import 'package:organiq/modules/shopping/domain/usecases/delete_shopping_list_usecase.dart';
import 'package:organiq/modules/tasks/domain/usecases/delete_task_usecase.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/services/speech/speech_transcription_service.dart';
import 'package:organiq/shared/state/oq_state.dart';

enum CreatePhase { input, processing, review, confirming, done }

class _LineReviewOutcome {
  const _LineReviewOutcome._({
    this.failureMessage,
    this.autoConfirmed,
    this.reviewSuggestions = const <CreateSuggestionItem>[],
  });

  const _LineReviewOutcome.failed(String message)
    : this._(failureMessage: message);

  const _LineReviewOutcome.autoConfirmed(LineProcessSuccess result)
    : this._(autoConfirmed: result);

  const _LineReviewOutcome.review(List<CreateSuggestionItem> suggestions)
    : this._(reviewSuggestions: suggestions);

  final String? failureMessage;
  final LineProcessSuccess? autoConfirmed;
  final List<CreateSuggestionItem> reviewSuggestions;

  bool get isFailed => failureMessage != null;
  bool get isAutoConfirmed => autoConfirmed != null;
}

class CreateController implements OQController {
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
  final ValueNotifier<CreatePhase> phase = ValueNotifier(CreatePhase.input);
  final ValueNotifier<List<CreateProcessingLine>> processingLines =
      ValueNotifier(const <CreateProcessingLine>[]);
  final ValueNotifier<List<CreateSuggestionItem>> suggestions = ValueNotifier(
    const <CreateSuggestionItem>[],
  );

  String? _voiceBaseText;
  String _latestRecognizedText = '';
  String _finalRecognizedText = '';
  Completer<void>? _voiceResultCompleter;
  Timer? _recordingTimer;
  bool _finalizingVoice = false;
  int _lastTotalInputs = 0;
  int _processingFailedLines = 0;
  int _baseTasks = 0;
  int _baseReminders = 0;
  int _baseEvents = 0;
  int _baseShoppingLists = 0;
  int _baseShoppingItems = 0;
  int _baseRoutines = 0;
  final List<CreateLineResult> _baseLineResults = <CreateLineResult>[];

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
    phase.dispose();
    processingLines.dispose();
    suggestions.dispose();
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

    _resetFlowState(keepInput: true);
    _lastTotalInputs = lines.length;
    phase.value = CreatePhase.processing;
    loading.value = true;
    error.value = null;

    processingLines.value = lines
        .map(
          (line) => CreateProcessingLine(
            text: line,
            status: LineProcessingStatus.pending,
          ),
        )
        .toList();

    final reviewSuggestions = <CreateSuggestionItem>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      _updateProcessingLine(i, status: LineProcessingStatus.processing);

      final outcome = await _processSingleLineForReview(line);
      if (outcome.isFailed) {
        _processingFailedLines += 1;
        _baseLineResults.add(
          CreateLineResult(
            sourceText: line,
            status: CreateLineStatus.failed,
            message: outcome.failureMessage!,
          ),
        );
        _updateProcessingLine(
          i,
          status: LineProcessingStatus.failed,
          message: outcome.failureMessage,
        );
        continue;
      }

      if (outcome.isAutoConfirmed) {
        final auto = outcome.autoConfirmed!;
        _baseTasks += auto.tasksCount;
        _baseReminders += auto.remindersCount;
        _baseEvents += auto.eventsCount;
        _baseRoutines += auto.routinesCount;
        _baseShoppingLists += auto.shoppingListsCount;
        _baseShoppingItems += auto.shoppingItemsCount;
        _baseLineResults.addAll(auto.lineResults);
        _updateProcessingLine(
          i,
          status: LineProcessingStatus.done,
          message: 'Confirmado automaticamente.',
        );
        continue;
      }

      reviewSuggestions.addAll(outcome.reviewSuggestions);
      _updateProcessingLine(
        i,
        status: LineProcessingStatus.done,
        suggestions: outcome.reviewSuggestions
            .map((entry) => entry.suggestion)
            .toList(),
        inboxItemId: outcome.reviewSuggestions.isEmpty
            ? null
            : outcome.reviewSuggestions.first.inboxItemId,
      );
    }

    suggestions.value = reviewSuggestions;
    loading.value = false;

    if (reviewSuggestions.isNotEmpty) {
      return true;
    }

    _finalizeBatchResult(
      confirmedLines: const <CreateLineResult>[],
      tasks: 0,
      reminders: 0,
      events: 0,
      routines: 0,
      shoppingLists: 0,
      shoppingItems: 0,
      confirmFailures: 0,
    );
    phase.value = CreatePhase.done;

    if (_processingFailedLines > 0 &&
        _baseLineResults.length == _processingFailedLines) {
      error.value = 'Não foi possível processar os textos enviados.';
      return false;
    }

    return true;
  }

  void goToReview() {
    if (loading.value || suggestions.value.isEmpty) return;
    phase.value = CreatePhase.review;
  }

  Future<bool> confirmAll() async {
    if (loading.value) return false;

    final activeSuggestions = suggestions.value
        .where((entry) => !entry.removed)
        .toList();

    phase.value = CreatePhase.confirming;
    loading.value = true;
    error.value = null;

    var tasks = 0;
    var reminders = 0;
    var events = 0;
    var routines = 0;
    var shoppingLists = 0;
    var shoppingItems = 0;
    var confirmFailures = 0;
    final confirmedLines = <CreateLineResult>[];

    for (final suggestion in activeSuggestions) {
      final confirmInput = suggestion.toConfirmInput();
      if (!confirmInput.isValidForConfirm) {
        confirmFailures += 1;
        confirmedLines.add(
          CreateLineResult(
            sourceText: suggestion.sourceText,
            status: CreateLineStatus.failed,
            message: 'A sugestão não possui dados válidos para confirmação.',
          ),
        );
        continue;
      }

      final confirmResult = await _confirmInboxItemUsecase.call(confirmInput);
      confirmResult.fold(
        (failure) {
          confirmFailures += 1;
          final message = (failure.message?.trim().isNotEmpty ?? false)
              ? failure.message!.trim()
              : 'Falha ao confirmar sugestão.';
          confirmedLines.add(
            CreateLineResult(
              sourceText: suggestion.sourceText,
              status: CreateLineStatus.failed,
              message: message,
            ),
          );
        },
        (output) {
          final success = _buildManualConfirmedSuccess(
            output,
            sourceText: suggestion.sourceText,
          );
          tasks += success.tasksCount;
          reminders += success.remindersCount;
          events += success.eventsCount;
          routines += success.routinesCount;
          shoppingLists += success.shoppingListsCount;
          shoppingItems += success.shoppingItemsCount;
          confirmedLines.addAll(success.lineResults);
        },
      );
    }

    _finalizeBatchResult(
      confirmedLines: confirmedLines,
      tasks: tasks,
      reminders: reminders,
      events: events,
      routines: routines,
      shoppingLists: shoppingLists,
      shoppingItems: shoppingItems,
      confirmFailures: confirmFailures,
    );

    loading.value = false;
    phase.value = CreatePhase.done;

    if (confirmFailures > 0) {
      error.value = 'Algumas sugestões não puderam ser confirmadas.';
      return false;
    }

    return true;
  }

  void editSuggestion(int index, CreateSuggestionItem edited) {
    final list = List<CreateSuggestionItem>.from(suggestions.value);
    if (index < 0 || index >= list.length) return;
    list[index] = edited;
    suggestions.value = list;
  }

  void toggleRemoveSuggestion(int index) {
    final list = List<CreateSuggestionItem>.from(suggestions.value);
    if (index < 0 || index >= list.length) return;
    list[index] = list[index].copyWith(removed: !list[index].removed);
    suggestions.value = list;
  }

  void goBackToInput() {
    phase.value = CreatePhase.input;
    processingLines.value = const <CreateProcessingLine>[];
    suggestions.value = const <CreateSuggestionItem>[];
    batchResult.value = null;
    error.value = null;
    _resetBaseResultState();
  }

  void resetAll() {
    if (loading.value || listening.value || voiceProcessing.value) return;
    inputController.clear();
    goBackToInput();
  }

  Future<_LineReviewOutcome> _processSingleLineForReview(String line) async {
    final createResult = await _createInboxItemUsecase.call(
      InboxCreateInput(source: 'manual', rawText: line),
    );

    final createdItem = createResult.fold<InboxItemOutput?>(
      (failure) => null,
      (item) => item,
    );

    if (createdItem == null) {
      return _LineReviewOutcome.failed(_failureMessage(createResult));
    }

    final reprocessResult = await _reprocessInboxItemUsecase.call(
      createdItem.id,
    );
    final processedItem = reprocessResult.fold<InboxItemOutput?>(
      (failure) => null,
      (item) => item,
    );

    if (processedItem == null) {
      return _LineReviewOutcome.failed(_failureMessage(reprocessResult));
    }

    if (processedItem.status.trim().toUpperCase() == 'CONFIRMED') {
      return _LineReviewOutcome.autoConfirmed(
        _buildAutoConfirmedSuccess(processedItem, sourceText: line),
      );
    }

    final resolvedSuggestions = _resolvedSuggestions(processedItem);
    if (resolvedSuggestions.isEmpty) {
      final lastError = processedItem.lastError?.trim();
      return _LineReviewOutcome.failed(
        (lastError != null && lastError.isNotEmpty)
            ? lastError
            : 'A IA não retornou sugestões para revisão.',
      );
    }

    final items = resolvedSuggestions
        .map(
          (suggestion) => CreateSuggestionItem(
            sourceText: line,
            inboxItemId: processedItem.id,
            suggestion: suggestion,
          ),
        )
        .toList();

    return _LineReviewOutcome.review(items);
  }

  void _updateProcessingLine(
    int index, {
    required LineProcessingStatus status,
    String? message,
    List<InboxSuggestionOutput>? suggestions,
    String? inboxItemId,
  }) {
    final list = List<CreateProcessingLine>.from(processingLines.value);
    if (index < 0 || index >= list.length) return;
    list[index] = list[index].copyWith(
      status: status,
      message: message,
      suggestions: suggestions,
      inboxItemId: inboxItemId,
    );
    processingLines.value = list;
  }

  void _finalizeBatchResult({
    required List<CreateLineResult> confirmedLines,
    required int tasks,
    required int reminders,
    required int events,
    required int routines,
    required int shoppingLists,
    required int shoppingItems,
    required int confirmFailures,
  }) {
    final successCount = (_lastTotalInputs - _processingFailedLines).clamp(
      0,
      _lastTotalInputs,
    );

    batchResult.value = CreateBatchResult(
      totalInputs: _lastTotalInputs,
      successCount: successCount,
      failedCount: _processingFailedLines + confirmFailures,
      tasksCount: _baseTasks + tasks,
      remindersCount: _baseReminders + reminders,
      eventsCount: _baseEvents + events,
      shoppingListsCount: _baseShoppingLists + shoppingLists,
      shoppingItemsCount: _baseShoppingItems + shoppingItems,
      routinesCount: _baseRoutines + routines,
      lines: <CreateLineResult>[..._baseLineResults, ...confirmedLines],
    );
  }

  void _resetFlowState({required bool keepInput}) {
    batchResult.value = null;
    error.value = null;
    phase.value = CreatePhase.input;
    processingLines.value = const <CreateProcessingLine>[];
    suggestions.value = const <CreateSuggestionItem>[];
    _resetBaseResultState();
    if (!keepInput) {
      inputController.clear();
    }
  }

  void _resetBaseResultState() {
    _lastTotalInputs = 0;
    _processingFailedLines = 0;
    _baseTasks = 0;
    _baseReminders = 0;
    _baseEvents = 0;
    _baseShoppingLists = 0;
    _baseShoppingItems = 0;
    _baseRoutines = 0;
    _baseLineResults.clear();
  }

  LineProcessSuccess _buildAutoConfirmedSuccess(
    InboxItemOutput item, {
    required String sourceText,
  }) {
    if (item.confirmed.isNotEmpty) {
      var tasks = 0;
      var reminders = 0;
      var events = 0;
      var routines = 0;
      var shoppingLists = 0;
      var shoppingItems = 0;

      final lineItems = item.confirmed.map((confirmed) {
        final type = confirmed.type.trim().toLowerCase();
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
            if (confirmed.shoppingList != null) {
              shoppingLists++;
            }
            shoppingItems += confirmed.shoppingItems.length;
            break;
        }

        final title = _titleFromConfirmedOutput(confirmed);
        final label = _entityLabel(type);
        final message = title.isEmpty
            ? '$label criado automaticamente.'
            : '$label: $title';
        final entityRef = _resolveEntityRef(confirmed);

        return CreateLineResult(
          sourceText: sourceText,
          status: CreateLineStatus.success,
          message: message,
          entityType: entityRef.$1,
          entityId: entityRef.$2,
        );
      }).toList();

      return LineProcessSuccess(
        lineResults: lineItems,
        tasksCount: tasks,
        remindersCount: reminders,
        eventsCount: events,
        routinesCount: routines,
        shoppingListsCount: shoppingLists,
        shoppingItemsCount: shoppingItems,
      );
    }

    final suggestions = _resolvedSuggestions(item);
    if (suggestions.isEmpty) {
      return LineProcessSuccess(
        lineResults: <CreateLineResult>[
          CreateLineResult(
            sourceText: sourceText,
            status: CreateLineStatus.success,
            message: 'Item criado automaticamente pela IA.',
          ),
        ],
      );
    }

    var tasks = 0;
    var reminders = 0;
    var events = 0;
    var routines = 0;
    var shoppingLists = 0;
    var shoppingItems = 0;

    for (final suggestion in suggestions) {
      final type = suggestion.type.trim().toLowerCase();
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
          shoppingLists++;
          shoppingItems += _shoppingItemsFromSuggestion(suggestion);
          break;
      }
    }

    final lineItems = suggestions.map((suggestion) {
      final type = suggestion.type.trim().toLowerCase();
      final title = suggestion.title.trim();
      final label = _entityLabel(type);
      final message = title.isEmpty
          ? '$label criado automaticamente.'
          : '$label: $title';

      return CreateLineResult(
        sourceText: sourceText,
        status: CreateLineStatus.success,
        message: message,
      );
    }).toList();

    return LineProcessSuccess(
      lineResults: lineItems,
      tasksCount: tasks,
      remindersCount: reminders,
      eventsCount: events,
      routinesCount: routines,
      shoppingListsCount: shoppingLists,
      shoppingItemsCount: shoppingItems,
    );
  }

  LineProcessSuccess _buildManualConfirmedSuccess(
    InboxConfirmOutput output, {
    required String sourceText,
  }) {
    var tasks = 0;
    var reminders = 0;
    var events = 0;
    var routines = 0;
    var shoppingLists = 0;
    var shoppingItems = 0;

    final type = output.type.trim().toLowerCase();
    switch (type) {
      case 'task':
        tasks = 1;
        break;
      case 'reminder':
        reminders = 1;
        break;
      case 'event':
        events = 1;
        break;
      case 'routine':
        routines = 1;
        break;
      case 'shopping':
        if (output.shoppingList != null) {
          shoppingLists = 1;
        }
        shoppingItems = output.shoppingItems.length;
        break;
    }

    final entityRef = _resolveEntityRef(output);
    return LineProcessSuccess(
      lineResults: <CreateLineResult>[
        CreateLineResult(
          sourceText: sourceText,
          status: CreateLineStatus.success,
          message: '${_entityLabel(type)} criado com sucesso.',
          entityType: entityRef.$1,
          entityId: entityRef.$2,
        ),
      ],
      tasksCount: tasks,
      remindersCount: reminders,
      eventsCount: events,
      routinesCount: routines,
      shoppingListsCount: shoppingLists,
      shoppingItemsCount: shoppingItems,
    );
  }

  List<InboxSuggestionOutput> _resolvedSuggestions(InboxItemOutput item) {
    if (item.suggestions.isNotEmpty) {
      return item.suggestions;
    }
    if (item.suggestion != null) {
      return <InboxSuggestionOutput>[item.suggestion!];
    }
    return const <InboxSuggestionOutput>[];
  }

  int _shoppingItemsFromSuggestion(InboxSuggestionOutput suggestion) {
    final payload = suggestion.payload;
    if (payload is Map<String, dynamic>) {
      final items = payload['items'];
      if (items is List) return items.length;
      return 0;
    }
    if (payload is Map) {
      final items = payload['items'];
      if (items is List) return items.length;
      return 0;
    }
    return 0;
  }

  String _titleFromConfirmedOutput(InboxConfirmOutput output) {
    final type = output.type.trim().toLowerCase();
    switch (type) {
      case 'task':
        return output.task?.title.trim() ?? '';
      case 'reminder':
        return output.reminder?.title.trim() ?? '';
      case 'event':
        return output.event?.title.trim() ?? '';
      case 'routine':
        return output.routine?.title.trim() ?? '';
      case 'shopping':
        return output.shoppingList?.title.trim() ?? '';
      default:
        return '';
    }
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

    final lines = normalized
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    return lines.isEmpty ? <String>[normalized] : lines;
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
