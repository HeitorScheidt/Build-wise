import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/schedule_model.dart';

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Método para carregar entradas do cronograma
  Future<List<ScheduleEntry>> loadScheduleEntries(String userId) async {
    final snapshot = await _firestore
        .collection('users') // Alterado de 'user' para 'users'
        .doc(userId)
        .collection('cronograma')
        .get();

    return snapshot.docs
        .map((doc) => ScheduleEntry.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  // Método para adicionar uma nova entrada
  Future<void> addScheduleEntry(String userId, ScheduleEntry entry) async {
    await _firestore
        .collection('users') // Alterado de 'user' para 'users'
        .doc(userId)
        .collection('cronograma')
        .add(entry.toFirestore());
  }

  // Método para deletar uma entrada existente
  Future<void> deleteScheduleEntry(String userId, String entryId) async {
    await _firestore
        .collection('users') // Alterado de 'user' para 'users'
        .doc(userId)
        .collection('cronograma')
        .doc(entryId)
        .delete();
  }

  // Método para atualizar uma entrada existente
  Future<void> updateScheduleEntry(String userId, ScheduleEntry entry) async {
    await _firestore
        .collection('users') // Alterado de 'user' para 'users'
        .doc(userId)
        .collection('cronograma')
        .doc(entry.id)
        .update(entry.toFirestore());
  }
}
