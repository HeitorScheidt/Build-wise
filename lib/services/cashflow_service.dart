import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cashflow_model.dart';

class CashflowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addCashflow(
      String userId, String projectId, Cashflow cashflow) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .doc(projectId)
        .collection('cashflows')
        .doc(cashflow.id)
        .set(cashflow.toMap());
  }

  Future<void> updateCashflow(
      String userId, String projectId, Cashflow cashflow) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .doc(projectId)
        .collection('cashflows')
        .doc(cashflow.id)
        .update(cashflow.toMap());
  }

  Future<void> deleteCashflow(
      String userId, String projectId, String cashflowId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .doc(projectId)
        .collection('cashflows')
        .doc(cashflowId)
        .delete();
  }

  Stream<List<Cashflow>> getCashflows(String userId, String projectId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .doc(projectId)
        .collection('cashflows')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Cashflow.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
}
