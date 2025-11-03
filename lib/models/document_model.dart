import 'package:cloud_firestore/cloud_firestore.dart';

class Document {
  final String id;
  final String name;
  final String url;
  final String category;
  final DateTime added;
  final String userId;
  final bool cached;

  Document({
    required this.id,
    required this.name,
    required this.url,
    required this.category,
    required this.added,
    required this.userId,
    this.cached = false,
  });

  factory Document.fromFirestore(Map<String, dynamic> data, String id) {
    final rawAdded = data['added'];
    DateTime parsedAdded;

    if (rawAdded is Timestamp) {
      parsedAdded = rawAdded.toDate();
    } else if (rawAdded is String) {
      parsedAdded = DateTime.parse(rawAdded);
    } else if (rawAdded is DateTime) {
      parsedAdded = rawAdded;
    } else {
      // fallback: текущее время
      parsedAdded = DateTime.now();
    }

    return Document(
      id: id,
      name: data['name'] ?? '',
      url: data['url'] ?? '',
      category: data['category'] ?? 'user',
      added: parsedAdded,
      userId: data['userId'] ?? '',
      cached: data['cached'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'url': url,
      'category': category,
      'added': Timestamp.fromDate(added),
      'userId': userId,
      'cached': cached,
    };
  }

  Document copyWith({
    String? id,
    String? name,
    String? url,
    String? category,
    DateTime? added,
    String? userId,
    bool? cached,
  }) {
    return Document(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      category: category ?? this.category,
      added: added ?? this.added,
      userId: userId ?? this.userId,
      cached: cached ?? this.cached,
    );
  }
}