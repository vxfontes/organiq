class CreateLineResult {
  const CreateLineResult({
    required this.sourceText,
    required this.status,
    required this.message,
    this.entityId,
    this.entityType = CreateEntityType.unknown,
    this.deleted = false,
    this.deleting = false,
    this.confirmed = false,
  });

  final String sourceText;
  final CreateLineStatus status;
  final String message;
  final String? entityId;
  final CreateEntityType entityType;
  final bool deleted;
  final bool deleting;
  final bool confirmed;

  bool get canDelete =>
      status == CreateLineStatus.success &&
          !deleted &&
          !deleting &&
          entityId != null &&
          entityId!.trim().isNotEmpty &&
          entityType != CreateEntityType.unknown;

  CreateLineResult copyWith({
    String? message,
    String? entityId,
    CreateEntityType? entityType,
    bool? deleted,
    bool? deleting,
    bool? confirmed,
  }) {
    return CreateLineResult(
      sourceText: sourceText,
      status: status,
      message: message ?? this.message,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      deleted: deleted ?? this.deleted,
      deleting: deleting ?? this.deleting,
      confirmed: confirmed ?? this.confirmed,
    );
  }
}

enum CreateEntityType { task, reminder, event, shoppingList, routine, unknown }

enum CreateLineStatus { success, failed }
