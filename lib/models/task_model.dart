import 'package:cloud_firestore/cloud_firestore.dart'; // ← ДОБАВЬТЕ ИМПОРТ

class Task {
  final String id;
  final String title;
  final String address;
  final String elevator;
  final String deadline;
  final String status;
  final String userId;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    required this.address,
    required this.elevator,
    required this.deadline,
    required this.status,
    required this.userId,
    required this.createdAt,
  });

  factory Task.fromFirestore(Map<String, dynamic> data, String id) {
    return Task(
      id: id,
      title: data['title'] ?? '',
      address: data['address'] ?? '',
      elevator: data['elevator'] ?? '',
      deadline: data['deadline'] ?? '',
      status: data['status'] ?? 'new',
      userId: data['userId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(), // ← Timestamp теперь распознается
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'address': address,
      'elevator': elevator,
      'deadline': deadline,
      'status': status,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt), // ← Timestamp теперь распознается
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? address,
    String? elevator,
    String? deadline,
    String? status,
    String? userId,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      address: address ?? this.address,
      elevator: elevator ?? this.elevator,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}