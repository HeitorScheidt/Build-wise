import 'package:cloud_firestore/cloud_firestore.dart';

class WorkDiaryEntry {
  final String period;
  final bool wasPractical;
  final String userName;
  final String description;
  final DateTime date;
  final List<String> photos;

  WorkDiaryEntry({
    required this.period,
    required this.wasPractical,
    required this.userName,
    required this.description,
    required this.date,
    this.photos = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'wasPractical': wasPractical,
      'userName': userName,
      'description': description,
      'date': date.toIso8601String(), // Serializing to ISO-8601 string format
      'photos': photos,
    };
  }

  static WorkDiaryEntry fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    var data = doc.data()!;
    return WorkDiaryEntry(
      period: data['period'] as String,
      wasPractical: data['wasPractical'] as bool,
      userName: data['userName'] as String,
      description: data['description'] as String,
      date: data['date'] != null
          ? (data['date'] as Timestamp).toDate()
          : DateTime.now(),
      //date: (data['date'] as Timestamp).toDate(),
      photos: List<String>.from(data['photos'] ?? []),
      //photos: List<String>.from(data['photos'] as List<dynamic>),
    );
  }

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
}
