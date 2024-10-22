import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleEntry {
  final String id;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String responsible;
  final String title;
  final String description;
  final String priority; // Adicionando o campo de prioridade

  ScheduleEntry({
    required this.id,
    required this.startDateTime,
    required this.endDateTime,
    required this.responsible,
    required this.title,
    required this.description,
    required this.priority, // Inicializando o campo de prioridade
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
      priority: data['priority'] ??
          'Normal', // Definindo prioridade padrão se não estiver presente
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
      'priority': priority, // Incluindo prioridade no Firestore
    };
  }
}
