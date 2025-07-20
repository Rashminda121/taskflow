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

  @HiveField(9)
  final int colorValue; // Store color as int value instead of Color object

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
    Color color = Colors.blue, // Accept Color but store as int
  }) : colorValue = color.value;

  // Getter to convert stored int back to Color
  Color get color => Color(colorValue);

  String get formattedStartTime =>
      '${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}';
  String get formattedEndTime =>
      '${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}';

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? category,
    bool? isCompleted,
    List<String>? subtasks,
    Color? color,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      subtasks: subtasks ?? this.subtasks,
      color: color ?? this.color,
    );
  }
}
