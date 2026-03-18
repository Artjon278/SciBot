import 'package:cloud_firestore/cloud_firestore.dart';

class StudentProfile {
  final String uid;
  final String learningStyle; // vizual, logjik, praktik, lexues
  final List<String> preferredSubjects;
  final String currentLevel; // fillestar, mesatar, avancuar
  final String goal; // provim, nota, kuriozitet
  final int dailyStudyMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  StudentProfile({
    required this.uid,
    required this.learningStyle,
    required this.preferredSubjects,
    required this.currentLevel,
    required this.goal,
    required this.dailyStudyMinutes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'learningStyle': learningStyle,
      'preferredSubjects': preferredSubjects,
      'currentLevel': currentLevel,
      'goal': goal,
      'dailyStudyMinutes': dailyStudyMinutes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory StudentProfile.fromMap(Map<String, dynamic> map) {
    return StudentProfile(
      uid: map['uid'] ?? '',
      learningStyle: map['learningStyle'] ?? 'vizual',
      preferredSubjects: List<String>.from(map['preferredSubjects'] ?? []),
      currentLevel: map['currentLevel'] ?? 'mesatar',
      goal: map['goal'] ?? 'nota',
      dailyStudyMinutes: map['dailyStudyMinutes'] ?? 30,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
