import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lift_mechanic_flutter/models/task_model.dart';
import 'package:lift_mechanic_flutter/models/document_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== TASKS METHODS ==========

  /// Получение потока всех задач пользователя
  Stream<List<Task>> getTasks(String userId) {
  return _firestore
      .collection('tasks_flutter')
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)  
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Task.fromFirestore(doc.data(), doc.id))
          .toList());
  }

  /// Обновление статуса задачи
  Future<void> updateTaskStatus(String taskId, String status) async {
    await _firestore.collection('tasks_flutter').doc(taskId).update({
      'status': status,
      'updatedAt': Timestamp.now(),
    });
  }

  // ========== DOCUMENTS METHODS ==========

  /// Получение потока всех документов пользователя
  Stream<List<Document>> getUserDocuments(String userId) {
    return _firestore
        .collection('documents_flutter')
        .where('userId', isEqualTo: userId)
        .orderBy('added', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Document.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Добавление нового документа
  Future<void> addDocument(Document document) async {
    await _firestore.collection('documents_flutter').add(document.toFirestore());
  }

  /// Удаление документа
  Future<void> deleteDocument(String documentId) async {
    await _firestore.collection('documents_flutter').doc(documentId).delete();
  }

  /// Очистка всех документов пользователя
  Future<void> clearUserDocuments(String userId) async {
    final querySnapshot = await _firestore
        .collection('documents_flutter')
        .where('userId', isEqualTo: userId)
        .get();
    
    final batch = _firestore.batch();
    for (final doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}