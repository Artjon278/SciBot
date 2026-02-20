import 'package:cloud_firestore/cloud_firestore.dart';

class AudioLesson {
  final String id;
  final String userId;
  final String subject;
  final String topic;
  final String title;
  final String script;
  final int durationSeconds;
  final DateTime createdAt;
  bool isFavorite;

  AudioLesson({
    required this.id,
    required this.userId,
    required this.subject,
    required this.topic,
    required this.title,
    required this.script,
    required this.durationSeconds,
    required this.createdAt,
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'subject': subject,
        'topic': topic,
        'title': title,
        'script': script,
        'durationSeconds': durationSeconds,
        'createdAt': Timestamp.fromDate(createdAt),
        'isFavorite': isFavorite,
      };

  factory AudioLesson.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return AudioLesson(
      id: doc.id,
      userId: m['userId'] ?? '',
      subject: m['subject'] ?? '',
      topic: m['topic'] ?? '',
      title: m['title'] ?? '',
      script: m['script'] ?? '',
      durationSeconds: m['durationSeconds'] ?? 0,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isFavorite: m['isFavorite'] ?? false,
    );
  }
}
