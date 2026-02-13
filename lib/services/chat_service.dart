import 'package:flutter/foundation.dart';
import 'gemini_service.dart';
import 'chat_storage_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.isLoading = false,
  }) : timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({
    String? text,
    bool? isUser,
    DateTime? timestamp,
    bool? isLoading,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ChatService extends ChangeNotifier {
  final GeminiService _gemini = GeminiService();
  final ChatStorageService _storage = ChatStorageService();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  String? _currentSessionId;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  String? get currentSessionId => _currentSessionId;

  /// Dërgon mesazh dhe merr përgjigje
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Krijo sesion të ri nëse nuk ekziston
    _currentSessionId ??= _storage.generateSessionId();

    // Shto mesazhin e përdoruesit
    _messages.add(ChatMessage(
      text: text.trim(),
      isUser: true,
    ));
    notifyListeners();

    // Trego që AI po shkruan
    _isTyping = true;
    notifyListeners();

    try {
      // Merr përgjigjen nga Gemini
      final response = await _gemini.sendMessage(text);

      // Shto përgjigjen e AI
      _messages.add(ChatMessage(
        text: response,
        isUser: false,
      ));
      
      // Ruaj sesionin automatikisht
      await _saveCurrentSession();
    } catch (e) {
      _messages.add(ChatMessage(
        text: 'Na vjen keq, ndodhi një gabim. Provo përsëri.',
        isUser: false,
      ));
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  /// Ruaj sesionin aktual
  Future<void> _saveCurrentSession() async {
    if (_currentSessionId == null || _messages.isEmpty) return;
    
    final session = ChatSession(
      id: _currentSessionId!,
      title: ChatSession.generateTitle(_messages),
      createdAt: _messages.first.timestamp,
      lastMessageAt: _messages.last.timestamp,
      messages: List.from(_messages),
      previewText: _messages.last.text.length > 60 
          ? '${_messages.last.text.substring(0, 57)}...'
          : _messages.last.text,
    );
    
    await _storage.saveSession(session);
    await _storage.setCurrentSessionId(_currentSessionId);
  }

  /// Ngarko një sesion ekzistues
  Future<void> loadSession(String sessionId) async {
    final session = await _storage.getSession(sessionId);
    if (session == null) return;
    
    _messages.clear();
    _messages.addAll(session.messages);
    _currentSessionId = sessionId;
    _gemini.clearHistory();
    
    // Ringarko historinë e Gemini
    for (final msg in _messages) {
      if (msg.isUser) {
        // Mos dërgo mesazh, vetëm shto në histori
      }
    }
    
    await _storage.setCurrentSessionId(sessionId);
    notifyListeners();
  }

  /// Merr të gjitha sesionet
  Future<List<ChatSession>> getAllSessions() async {
    return await _storage.getAllSessions();
  }

  /// Fshi një sesion
  Future<void> deleteSession(String sessionId) async {
    await _storage.deleteSession(sessionId);
    
    // Nëse fshihet sesioni aktual, pastro
    if (_currentSessionId == sessionId) {
      clearHistory();
    }
    
    notifyListeners();
  }

  /// Dërgon pyetje për ndihmë me sfidë
  Future<void> askForChallengeHelp({
    required String subject,
    required String title,
    required String description,
    String? userAttempt,
  }) async {
    _currentSessionId ??= _storage.generateSessionId();
    
    // Shto mesazhin e përdoruesit
    _messages.add(ChatMessage(
      text: 'Më ndihmo me sfidën: $title',
      isUser: true,
    ));
    notifyListeners();

    _isTyping = true;
    notifyListeners();

    try {
      final response = await _gemini.helpWithChallenge(
        subject: subject,
        title: title,
        description: description,
        userAttempt: userAttempt,
      );

      _messages.add(ChatMessage(
        text: response,
        isUser: false,
      ));
      
      await _saveCurrentSession();
    } catch (e) {
      _messages.add(ChatMessage(
        text: 'Na vjen keq, ndodhi një gabim. Provo përsëri.',
        isUser: false,
      ));
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  /// Pastron historinë e bisedës dhe fillon bisedë të re
  void clearHistory() {
    _messages.clear();
    _currentSessionId = null;
    _gemini.clearHistory();
    _storage.setCurrentSessionId(null);
    notifyListeners();
  }

  /// Shto mesazh mirëseardhjeje
  void addWelcomeMessage() {
    if (_messages.isEmpty) {
      _messages.add(ChatMessage(
        text: 'Përshëndetje! 👋 Unë jam SciBot, asistenti yt për shkencën. '
            'Më pyet çfarëdo gjëje për Matematikë, Fizikë, Kimi ose Biologji!',
        isUser: false,
      ));
      notifyListeners();
    }
  }
}
