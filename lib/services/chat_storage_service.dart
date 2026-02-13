import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_service.dart';

/// Struktura e një sesioni bisede
class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final List<ChatMessage> messages;
  final String? previewText;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastMessageAt,
    required this.messages,
    this.previewText,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'lastMessageAt': lastMessageAt.toIso8601String(),
    'messages': messages.map((m) => {
      'text': m.text,
      'isUser': m.isUser,
      'timestamp': m.timestamp.toIso8601String(),
    }).toList(),
    'previewText': previewText,
  };

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    final messagesList = (json['messages'] as List).map((m) => ChatMessage(
      text: m['text'],
      isUser: m['isUser'],
      timestamp: DateTime.parse(m['timestamp']),
    )).toList();

    return ChatSession(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.parse(json['createdAt']),
      lastMessageAt: DateTime.parse(json['lastMessageAt']),
      messages: messagesList,
      previewText: json['previewText'],
    );
  }

  /// Krijon titull automatik nga mesazhi i parë
  static String generateTitle(List<ChatMessage> messages) {
    if (messages.isEmpty) return 'Bisedë e re';
    
    final firstUserMessage = messages.firstWhere(
      (m) => m.isUser,
      orElse: () => messages.first,
    );
    
    String title = firstUserMessage.text;
    if (title.length > 40) {
      title = '${title.substring(0, 37)}...';
    }
    return title;
  }
}

/// Shërbimi për ruajtjen e bisedave
class ChatStorageService {
  static const String _sessionsKey = 'chat_sessions';
  static const String _currentSessionKey = 'current_session_id';
  static const int _maxSessions = 50; // Ruaj maksimumi 50 biseda

  SharedPreferences? _prefs;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Merr të gjitha sesionet
  Future<List<ChatSession>> getAllSessions() async {
    final p = await prefs;
    final String? data = p.getString(_sessionsKey);
    
    if (data == null || data.isEmpty) return [];
    
    try {
      final List<dynamic> jsonList = jsonDecode(data);
      final sessions = jsonList.map((j) => ChatSession.fromJson(j)).toList();
      
      // Rendit nga më i ri tek më i vjetër
      sessions.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      
      return sessions;
    } catch (e) {
      return [];
    }
  }

  /// Ruaj një sesion
  Future<void> saveSession(ChatSession session) async {
    final p = await prefs;
    final sessions = await getAllSessions();
    
    // Gjej nëse ekziston dhe zëvendëso
    final existingIndex = sessions.indexWhere((s) => s.id == session.id);
    if (existingIndex >= 0) {
      sessions[existingIndex] = session;
    } else {
      sessions.insert(0, session);
    }
    
    // Mbaj vetëm sesionet e fundit
    while (sessions.length > _maxSessions) {
      sessions.removeLast();
    }
    
    final jsonList = sessions.map((s) => s.toJson()).toList();
    await p.setString(_sessionsKey, jsonEncode(jsonList));

    // Ruaj gjithashtu në Firebase për "recent chats"
    await _saveSessionToFirestore(session);
  }

  Future<void> _saveSessionToFirestore(ChatSession session) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = _db
        .collection('users')
        .doc(user.uid)
        .collection('chat_sessions')
        .doc(session.id);

    await ref.set({
      ...session.toJson(),
      'userId': user.uid,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Fshi një sesion
  Future<void> deleteSession(String sessionId) async {
    final p = await prefs;
    final sessions = await getAllSessions();
    
    sessions.removeWhere((s) => s.id == sessionId);
    
    final jsonList = sessions.map((s) => s.toJson()).toList();
    await p.setString(_sessionsKey, jsonEncode(jsonList));
  }

  /// Merr sesionin aktual
  Future<String?> getCurrentSessionId() async {
    final p = await prefs;
    return p.getString(_currentSessionKey);
  }

  /// Vendos sesionin aktual
  Future<void> setCurrentSessionId(String? sessionId) async {
    final p = await prefs;
    if (sessionId != null) {
      await p.setString(_currentSessionKey, sessionId);
    } else {
      await p.remove(_currentSessionKey);
    }
  }

  /// Merr një sesion me ID
  Future<ChatSession?> getSession(String sessionId) async {
    final sessions = await getAllSessions();
    try {
      return sessions.firstWhere((s) => s.id == sessionId);
    } catch (e) {
      return null;
    }
  }

  /// Gjeneron ID unike
  String generateSessionId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Pastro të gjitha sesionet
  Future<void> clearAllSessions() async {
    final p = await prefs;
    await p.remove(_sessionsKey);
    await p.remove(_currentSessionKey);
  }
}