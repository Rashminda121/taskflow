import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final TimeOfDay startTime;

  @HiveField(5)
  final TimeOfDay endTime;

  @HiveField(6)
  final String category;

  @HiveField(7)
  bool isCompleted;

  @HiveField(8)
  final List<String> subtasks;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.category,
    this.isCompleted = false,
    this.subtasks = const [],
  });

  String get formattedStartTime =>
      '${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}';
  String get formattedEndTime =>
      '${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}';
}
