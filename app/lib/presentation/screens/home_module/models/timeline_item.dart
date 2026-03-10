import 'package:flutter/material.dart';

class TimelineItem {
  const TimelineItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.type,
    required this.scheduledTime,
    required this.isCompleted,
    required this.isOverdue,
    this.onComplete,
  });

  final String id;
  final String title;
  final String? subtitle;
  final TimelineItemType type;
  final DateTime scheduledTime;
  final bool isCompleted;
  final bool isOverdue;
  final VoidCallback? onComplete;
}

enum TimelineItemType { event, reminder, routine, task }
