import 'package:cloud_firestore/cloud_firestore.dart';

class WorkDiaryEntry {
  final String entryId;
  final String period;
  final bool wasPractical;
  final String userName;
  final String description;
  final DateTime date;
  final List<String> photos;

  WorkDiaryEntry({
    required this.entryId,
    required this.period,
    required this.wasPractical,
    required this.userName,
    required this.description,
    required this.date,
    this.photos = const [],
  });

  // Converte a entrada para JSON, por exemplo, para exibição ou serialização geral
  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'wasPractical': wasPractical,
      'userName': userName,
      'description': description,
      'date': date.toIso8601String(),
      'photos': photos,
    };
  }

  // Converte a entrada para ser usada no Firestore, com data em formato Timestamp
  Map<String, dynamic> toFirestore() {
    return {
      'period': period,
      'wasPractical': wasPractical,
      'userName': userName,
      'description': description,
      'date': Timestamp.fromDate(date),
      'photos': photos,
    };
  }

  // Método para criar uma instância de WorkDiaryEntry a partir de um documento do Firestore
  factory WorkDiaryEntry.fromDocument(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    var data = doc.data()!;
    return WorkDiaryEntry(
      entryId: doc.id,
      period: data['period'] ?? '',
      wasPractical: data['wasPractical'] ?? false,
      userName: data['userName'] ?? '',
      description: data['description'] ?? '',
      date: data['date'] != null
          ? (data['date'] as Timestamp).toDate()
          : DateTime.now(),
      photos: List<String>.from(data['photos'] ?? []),
    );
  }
}
