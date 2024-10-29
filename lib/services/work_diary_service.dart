import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:build_wise/models/work_diary_entry.dart';

class WorkDiaryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addWorkDiaryEntry(
      String userId, String projectId, WorkDiaryEntry entry) async {
    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('workdiary')
        .add(entry.toFirestore());
  }

  Future<List<WorkDiaryEntry>> loadWorkDiaryEntries(
      String userId, String projectId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('workdiary')
          .get();

      return snapshot.docs
          .map((doc) => WorkDiaryEntry.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to load entries: $e');
    }
  }

  Future<void> updateWorkDiaryEntry(
      String projectId, String entryId, WorkDiaryEntry updatedEntry) async {
    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('workdiary')
        .doc(entryId)
        .update(updatedEntry.toFirestore());
  }

  Future<void> deleteWorkDiaryEntry(String projectId, String entryId) async {
    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('workdiary')
        .doc(entryId)
        .delete();
  }
}
