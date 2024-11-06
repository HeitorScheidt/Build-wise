import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleEntry {
  final String id;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String responsible;
  final String title;
  final String description;
  final String priority;
  bool isExpired;
  bool isCompleted; // Adicionando o campo isCompleted

  ScheduleEntry({
    required this.id,
    required this.startDateTime,
    required this.endDateTime,
    required this.responsible,
    required this.title,
    required this.description,
    required this.priority,
    this.isExpired = false, // Inicializa isExpired com valor padrão false
    this.isCompleted = false, // Inicializa isCompleted com valor padrão false
  });

  // Converter do Firestore para um objeto ScheduleEntry
  factory ScheduleEntry.fromFirestore(Map<String, dynamic> data, String id) {
    return ScheduleEntry(
      id: id,
      startDateTime: (data['startDateTime'] as Timestamp).toDate(),
      endDateTime: (data['endDateTime'] as Timestamp).toDate(),
      responsible: data['responsible'],
      title: data['title'],
      description: data['description'],
      priority: data['priority'] ?? 'Normal',
      isExpired: data['isExpired'] ?? false,
      isCompleted: data['isCompleted'] ??
          false, // Define isCompleted como false se não estiver presente
    );
  }

  // Converter o objeto ScheduleEntry para o formato que será salvo no Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'startDateTime': startDateTime,
      'endDateTime': endDateTime,
      'responsible': responsible,
      'title': title,
      'description': description,
      'priority': priority,
      'isExpired': isExpired, // Inclui isExpired no Firestore
      'isCompleted': isCompleted, // Inclui isCompleted no Firestore
    };
  }
}
