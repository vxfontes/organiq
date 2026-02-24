import 'package:flutter/material.dart';
import 'package:inbota/modules/flags/data/models/flag_create_input.dart';
import 'package:inbota/modules/flags/data/models/flag_output.dart';
import 'package:inbota/modules/flags/data/models/flag_update_input.dart';
import 'package:inbota/modules/flags/data/models/subflag_create_input.dart';
import 'package:inbota/modules/flags/data/models/subflag_output.dart';
import 'package:inbota/modules/flags/data/models/subflag_update_input.dart';
import 'package:inbota/modules/flags/domain/usecases/create_flag_usecase.dart';
import 'package:inbota/modules/flags/domain/usecases/create_subflag_usecase.dart';
import 'package:inbota/modules/flags/domain/usecases/delete_flag_usecase.dart';
import 'package:inbota/modules/flags/domain/usecases/delete_subflag_usecase.dart';
import 'package:inbota/modules/flags/domain/usecases/get_flags_usecase.dart';
import 'package:inbota/modules/flags/domain/usecases/get_subflags_by_flag_usecase.dart';
import 'package:inbota/modules/flags/domain/usecases/update_flag_usecase.dart';
import 'package:inbota/modules/flags/domain/usecases/update_subflag_usecase.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/state/ib_state.dart';

class SettingsContextsController implements IBController {
  SettingsContextsController(
    this._getFlagsUsecase,
    this._createFlagUsecase,
    this._updateFlagUsecase,
    this._deleteFlagUsecase,
    this._getSubflagsByFlagUsecase,
    this._createSubflagUsecase,
    this._updateSubflagUsecase,
    this._deleteSubflagUsecase,
  );

  final GetFlagsUsecase _getFlagsUsecase;
  final CreateFlagUsecase _createFlagUsecase;
  final UpdateFlagUsecase _updateFlagUsecase;
  final DeleteFlagUsecase _deleteFlagUsecase;
  final GetSubflagsByFlagUsecase _getSubflagsByFlagUsecase;
  final CreateSubflagUsecase _createSubflagUsecase;
  final UpdateSubflagUsecase _updateSubflagUsecase;
  final DeleteSubflagUsecase _deleteSubflagUsecase;

  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<bool> saving = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);
  final ValueNotifier<List<FlagOutput>> flags = ValueNotifier(const []);
  final ValueNotifier<Map<String, List<SubflagOutput>>> subflagsByFlag =
      ValueNotifier(const {});

  bool get hasContent => flags.value.isNotEmpty;

  @override
  void dispose() {
    loading.dispose();
    saving.dispose();
    error.dispose();
    flags.dispose();
    subflagsByFlag.dispose();
  }

  Future<void> load() async {
    if (loading.value) return;
    loading.value = true;
    error.value = null;

    final flagsResult = await _getFlagsUsecase.call(limit: 200);

    final loadedFlags = flagsResult.fold<List<FlagOutput>>((failure) {
      _setError(failure, fallback: 'Não foi possível carregar flags.');
      return const [];
    }, (output) => _safeFlags(output.items));

    flags.value = loadedFlags;

    final nextSubflagsByFlag = <String, List<SubflagOutput>>{};
    final subflagsResults = await Future.wait(
      loadedFlags.map((flag) async {
        final result = await _getSubflagsByFlagUsecase.call(
          flagId: flag.id,
          limit: 200,
        );
        return MapEntry(flag.id, result);
      }),
    );

    for (final entry in subflagsResults) {
      entry.value.fold(
        (failure) {
          _setError(failure, fallback: 'Não foi possível carregar subflags.');
          nextSubflagsByFlag[entry.key] = const [];
        },
        (output) {
          nextSubflagsByFlag[entry.key] = _safeSubflags(output.items);
        },
      );
    }

    subflagsByFlag.value = nextSubflagsByFlag;
    loading.value = false;
  }

  Future<void> refresh() async {
    await load();
  }

  Future<bool> createFlag({required String name, String? color}) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      error.value = 'Informe o nome da flag.';
      return false;
    }

    final normalizedColor = _normalizeColor(color);
    if (color != null && color.trim().isNotEmpty && normalizedColor == null) {
      error.value = 'Cor invalida. Use formato hexadecimal, ex: #4A90E2.';
      return false;
    }

    saving.value = true;
    error.value = null;

    final result = await _createFlagUsecase.call(
      FlagCreateInput(
        name: trimmedName,
        color: normalizedColor,
        sortOrder: flags.value.length,
      ),
    );

    saving.value = false;

    return result.fold(
      (failure) {
        _setError(failure, fallback: 'Não foi possível criar a flag.');
        return false;
      },
      (created) {
        final next = List<FlagOutput>.from(flags.value)..add(created);
        flags.value = _safeFlags(next);

        final nextSubflags = Map<String, List<SubflagOutput>>.from(
          subflagsByFlag.value,
        );
        nextSubflags.putIfAbsent(created.id, () => const []);
        subflagsByFlag.value = nextSubflags;
        return true;
      },
    );
  }

  Future<bool> updateFlag({
    required String id,
    required String name,
    String? color,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      error.value = 'Informe o nome da flag.';
      return false;
    }

    final normalizedColor = _normalizeColor(color);
    if (color != null && color.trim().isNotEmpty && normalizedColor == null) {
      error.value = 'Cor invalida. Use formato hexadecimal, ex: #4A90E2.';
      return false;
    }

    saving.value = true;
    error.value = null;

    final result = await _updateFlagUsecase.call(
      FlagUpdateInput(id: id, name: trimmedName, color: normalizedColor),
    );

    saving.value = false;

    return result.fold(
      (failure) {
        _setError(failure, fallback: 'Não foi possível atualizar a flag.');
        return false;
      },
      (updated) {
        _upsertFlag(updated);
        return true;
      },
    );
  }

  Future<bool> deleteFlag(String id) async {
    saving.value = true;
    error.value = null;

    final result = await _deleteFlagUsecase.call(id);
    saving.value = false;

    return result.fold(
      (failure) {
        _setError(failure, fallback: 'Não foi possível excluir a flag.');
        return false;
      },
      (_) {
        final nextFlags = List<FlagOutput>.from(flags.value)
          ..removeWhere((flag) => flag.id == id);
        flags.value = nextFlags;

        final nextSubflags = Map<String, List<SubflagOutput>>.from(
          subflagsByFlag.value,
        )..remove(id);
        subflagsByFlag.value = nextSubflags;
        return true;
      },
    );
  }

  Future<bool> createSubflag({
    required String flagId,
    required String name,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      error.value = 'Informe o nome da subflag.';
      return false;
    }

    saving.value = true;
    error.value = null;

    final currentItems = subflagsByFlag.value[flagId] ?? const [];
    final result = await _createSubflagUsecase.call(
      SubflagCreateInput(
        flagId: flagId,
        name: trimmedName,
        sortOrder: currentItems.length,
      ),
    );

    saving.value = false;

    return result.fold(
      (failure) {
        _setError(failure, fallback: 'Não foi possível criar a subflag.');
        return false;
      },
      (created) {
        _upsertSubflag(flagId, created);
        return true;
      },
    );
  }

  Future<bool> updateSubflag({required String id, required String name}) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      error.value = 'Informe o nome da subflag.';
      return false;
    }

    saving.value = true;
    error.value = null;

    final result = await _updateSubflagUsecase.call(
      SubflagUpdateInput(id: id, name: trimmedName),
    );

    saving.value = false;

    return result.fold(
      (failure) {
        _setError(failure, fallback: 'Não foi possível atualizar a subflag.');
        return false;
      },
      (updated) {
        final parentFlagId =
            updated.flag?.id ?? _findParentFlagIdBySubflagId(id);
        if (parentFlagId == null) {
          error.value = 'Não foi possível localizar a subflag para atualizar.';
          return false;
        }
        _upsertSubflag(parentFlagId, updated);
        return true;
      },
    );
  }

  Future<bool> deleteSubflag(String id) async {
    final parentFlagId = _findParentFlagIdBySubflagId(id);
    if (parentFlagId == null) {
      error.value = 'Não foi possível localizar a subflag para excluir.';
      return false;
    }

    saving.value = true;
    error.value = null;

    final result = await _deleteSubflagUsecase.call(id);
    saving.value = false;

    return result.fold(
      (failure) {
        _setError(failure, fallback: 'Não foi possível excluir a subflag.');
        return false;
      },
      (_) {
        final nextMap = Map<String, List<SubflagOutput>>.from(
          subflagsByFlag.value,
        );
        final nextList = List<SubflagOutput>.from(
          nextMap[parentFlagId] ?? const [],
        )..removeWhere((item) => item.id == id);
        nextMap[parentFlagId] = nextList;
        subflagsByFlag.value = nextMap;
        return true;
      },
    );
  }

  List<SubflagOutput> subflagsOf(String flagId) {
    return subflagsByFlag.value[flagId] ?? const [];
  }

  void _upsertFlag(FlagOutput item) {
    final next = List<FlagOutput>.from(flags.value);
    final index = next.indexWhere((flag) => flag.id == item.id);
    if (index == -1) {
      next.add(item);
    } else {
      next[index] = item;
    }
    flags.value = _safeFlags(next);
  }

  void _upsertSubflag(String flagId, SubflagOutput item) {
    final nextMap = Map<String, List<SubflagOutput>>.from(subflagsByFlag.value);
    final nextList = List<SubflagOutput>.from(nextMap[flagId] ?? const []);
    final index = nextList.indexWhere((subflag) => subflag.id == item.id);
    if (index == -1) {
      nextList.add(item);
    } else {
      nextList[index] = item;
    }
    nextMap[flagId] = _safeSubflags(nextList);
    subflagsByFlag.value = nextMap;
  }

  String? _findParentFlagIdBySubflagId(String subflagId) {
    for (final entry in subflagsByFlag.value.entries) {
      if (entry.value.any((item) => item.id == subflagId)) {
        return entry.key;
      }
    }
    return null;
  }

  List<FlagOutput> _safeFlags(List<FlagOutput> items) {
    final safe = items.where((item) => item.id.trim().isNotEmpty).toList();
    safe.sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      if (byOrder != 0) return byOrder;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return safe;
  }

  List<SubflagOutput> _safeSubflags(List<SubflagOutput> items) {
    final safe = items.where((item) => item.id.trim().isNotEmpty).toList();
    safe.sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      if (byOrder != 0) return byOrder;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return safe;
  }

  String? _normalizeColor(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;

    var hex = value.toUpperCase().replaceAll('#', '');
    if (hex.length == 3) {
      hex = hex.split('').map((char) => '$char$char').join();
    }
    if (hex.length == 8) {
      hex = hex.substring(2);
    }
    if (hex.length != 6) return null;
    if (!RegExp(r'^[0-9A-F]{6}$').hasMatch(hex)) return null;
    return '#$hex';
  }

  void _setError(Failure failure, {required String fallback}) {
    final message = failure.message?.trim();
    if (message != null && message.isNotEmpty) {
      error.value = message;
    } else if (error.value == null || error.value!.isEmpty) {
      error.value = fallback;
    }
  }
}
