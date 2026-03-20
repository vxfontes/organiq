class TaskCreateInput {
  const TaskCreateInput({
    required this.title,
    this.description,
    this.dueAt,
    this.status,
    this.flagId,
    this.subflagId,
  });

  final String title;
  final String? description;
  final DateTime? dueAt;
  final String? status;
  final String? flagId;
  final String? subflagId;

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{'title': title};

    if (description != null && description!.trim().isNotEmpty) {
      payload['description'] = description!.trim();
    }

    if (dueAt != null) {
      payload['dueAt'] = dueAt!.toUtc().toIso8601String();
    }

    if (status != null && status!.trim().isNotEmpty) {
      payload['status'] = status!.trim();
    }

    if (flagId != null && flagId!.trim().isNotEmpty) {
      payload['flagId'] = flagId!.trim();
    }

    if (subflagId != null && subflagId!.trim().isNotEmpty) {
      payload['subflagId'] = subflagId!.trim();
    }

    return payload;
  }
}
