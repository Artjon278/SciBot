import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Struktura e mesazhit për historinë
class ChatHistoryItem {
  final String role; // 'user' ose 'model'
  final String text;
  
  ChatHistoryItem({required this.role, required this.text});
  
  Map<String, dynamic> toJson() => {
    'role': role,
    'parts': [{'text': text}],
  };
}

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  static const String _model = 'gemini-2.5-flash';  // Gemini 2.5 Flash
  
  // Historia e bisedës
  final List<ChatHistoryItem> _chatHistory = [];
  static const int _maxHistoryLength = 12; // Optimizuar: 12 mesazhe mjaftojnë për kontekst

  String? _customSystemPrompt;

  void setSystemPrompt(String prompt) {
    _customSystemPrompt = prompt;
  }

  static const String _defaultSystemPrompt = '''
Ti je SciBot, asistent AI i shkencës për nxënësit e shkollave të mesme në Shqipëri.
Ekspertizë: Matematikë, Fizikë, Kimi, Biologji.

Rregulla:
- Përgjigju VETËM në shqip
- Përgjigje koncize (max 200 fjalë) përveç kur kërkohet zgjidhje e detajuar
- Përdor emoji për ta bërë më tërheqës (p.sh. 📐 për matematikë, ⚗️ për kimi)
- Për probleme matematikore: trego ÇDODNJË hap me formulë
- Për koncepte shkencore: analogji e thjeshtë + shembull real
- Ji inkurajues por i drejtpërdrejtë
- Përdor markdown (bold, lista, headers) për strukturë
- Referoju bisedave të mëparshme kur lidhet
- Nëse nxënësi gabon, korrigjo me mirësjellje dhe shpjego PSE
''';

  String get _systemPrompt => _customSystemPrompt ?? _defaultSystemPrompt;

  /// Dërgon mesazh tek Gemini dhe merr përgjigje me memorie
  Future<String> sendMessage(String message, {String? context, bool useHistory = true}) async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_API_KEY_HERE') {
      return 'Gabim: API Key nuk është konfiguruar. Shko tek .env dhe shto GEMINI_API_KEY';
    }

    try {
      final url = Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey');
      
      // Ndërto listën e contents me historinë
      final List<Map<String, dynamic>> contents = [];
      
      // Shto system prompt si mesazh i parë
      contents.add({
        'role': 'user',
        'parts': [{'text': _systemPrompt + (context != null ? '\n\nKonteksti: $context' : '')}],
      });
      contents.add({
        'role': 'model',
        'parts': [{'text': 'Kuptohet! Jam SciBot dhe jam gati të të ndihmoj me shkencën. Pyet çfarëdo gjëje!'}],
      });
      
      // Shto historinë e bisedës nëse është aktivizuar
      if (useHistory) {
        for (final item in _chatHistory) {
          contents.add(item.toJson());
        }
      }
      
      // Shto mesazhin aktual të përdoruesit
      contents.add({
        'role': 'user',
        'parts': [{'text': message}],
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': contents,
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 2048,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List?;
          
          if (parts != null && parts.isNotEmpty) {
            final responseText = parts[0]['text'] ?? 'Nuk mora përgjigje.';
            
            // Ruaj në histori
            if (useHistory) {
              _addToHistory('user', message);
              _addToHistory('model', responseText);
            }
            
            return responseText;
          }
        }
        return 'Nuk mora përgjigje nga AI.';
      } else {
        final error = jsonDecode(response.body);
        return 'Gabim: ${error['error']?['message'] ?? 'Diçka shkoi keq'}';
      }
    } catch (e) {
      return 'Gabim lidhjeje: $e';
    }
  }
  
  /// Nxjerr JSON objekt nga teksti - gjen { e parë dhe } e fundit
  String? _extractJson(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) return null;
    return text.substring(start, end + 1);
  }

  /// Nxjerr JSON array nga teksti
  String? _extractJsonArray(String text) {
    final start = text.indexOf('[');
    final end = text.lastIndexOf(']');
    if (start == -1 || end == -1 || end <= start) return null;
    return text.substring(start, end + 1);
  }

  /// Shton mesazh në histori
  void _addToHistory(String role, String text) {
    _chatHistory.add(ChatHistoryItem(role: role, text: text));
    
    // Mbaj vetëm mesazhet e fundit
    while (_chatHistory.length > _maxHistoryLength) {
      _chatHistory.removeAt(0);
    }
  }
  
  /// Pastron historinë e bisedës
  void clearHistory() {
    _chatHistory.clear();
  }
  
  /// Merr numrin e mesazheve në histori
  int get historyLength => _chatHistory.length;

  /// Ndihmon me zgjidhjen e sfidës
  Future<String> helpWithChallenge({
    required String subject,
    required String title,
    required String description,
    String? userAttempt,
  }) async {
    final context = '''
Lënda: $subject
Sfida: $title
Përshkrimi: $description
${userAttempt != null ? 'Tentativa e nxënësit: $userAttempt' : ''}
''';

    return sendMessage(
      'Më ndihmo të zgjidh këtë sfidë. Jep udhëzime hap pas hapi, por mos jep përgjigjen direkt.',
      context: context,
    );
  }

  /// Gjeneron pyetje kuizi - optimizuar me topic support
  Future<Map<String, dynamic>?> generateQuizQuestion({
    required String subject,
    required String difficulty,
    String? topic,
  }) async {
    final topicHint = topic != null && topic.trim().isNotEmpty
        ? '\nTema specifike: "$topic"'
        : '';
    final prompt = '''
Krijo 1 pyetje kuizi për "$subject" ($difficulty).$topicHint

VETËM JSON:
{"question":"...","options":["A","B","C","D"],"correctIndex":0,"explanation":"..."}

Rregulla:
- correctIndex: 0-3
- Në shqip, nivel shkolle e mesme
- Opsionet duhet të jenë bindëse (jo qartazi të gabuara)
- Shpjegimi: 1-2 fjali koncize
''';

    try {
      final response = await sendMessage(prompt);
      
      // Mundohu të nxjerrësh JSON nga përgjigja
      final jsonStr = _extractJson(response);
      if (jsonStr != null) {
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Gjeneron shumë pyetje kuizi njëherësh - më efikase
  Future<List<Map<String, dynamic>>> generateBatchQuizQuestions({
    required String subject,
    required String difficulty,
    required String topic,
    int count = 5,
  }) async {
    final prompt = '''
Krijo $count pyetje kuizi për "$subject" ($difficulty), tema: "$topic".

VETËM JSON array:
[{"question":"...","options":["A","B","C","D"],"correctIndex":0,"explanation":"..."},...]

Rregulla: shqip, shkolle e mesme, opsione bindëse, shpjegime koncize.
''';

    try {
      final response = await sendMessage(prompt, useHistory: false);
      final jsonArrayStr = _extractJsonArray(response);
      if (jsonArrayStr != null) {
        final decoded = jsonDecode(jsonArrayStr);
        if (decoded is List) {
          return decoded.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Gjeneron pyetje kuizi nga një ushtrim i zgjidhur
  Future<List<Map<String, dynamic>>> generateQuizFromExercise({
    required String exerciseText,
    required String exerciseTitle,
    required String subject,
    required String solution,
    int count = 5,
  }) async {
    final prompt = '''
Bazuar në këtë ushtrim të zgjidhur, krijo $count pyetje kuizi për të testuar njohuritë e nxënësit.

Lënda: $subject
Titulli: $exerciseTitle
Ushtrimi: $exerciseText
Zgjidhja: $solution

VETËM JSON array:
[{"question":"...","options":["A","B","C","D"],"correctIndex":0,"explanation":"..."},...]

Rregulla:
- correctIndex: 0-3
- Në shqip, nivel shkolle e mesme
- Pyetjet duhet të testojnë konceptet e ushtrimit
- Opsionet duhet të jenë bindëse
- Shpjegimi: 1-2 fjali koncize
- Përfshi pyetje për formulat, hapat, konceptet bazë
''';

    try {
      final response = await sendMessage(prompt, useHistory: false);
      final jsonArrayStr = _extractJsonArray(response);
      if (jsonArrayStr != null) {
        final decoded = jsonDecode(jsonArrayStr);
        if (decoded is List) {
          return decoded.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Shpjegon një koncept
  Future<String> explainConcept(String concept, String subject) async {
    return sendMessage(
      'Shpjegom konceptin "$concept" në lëndën $subject në mënyrë të thjeshtë dhe të kuptueshme për një nxënës të shkollës së mesme.',
    );
  }

  /// Kontrollon nëse API key është i vlefshëm
  Future<bool> isApiKeyValid() async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_API_KEY_HERE') {
      return false;
    }
    
    try {
      final response = await sendMessage('Përshëndet shkurtimisht.');
      return !response.startsWith('Gabim');
    } catch (e) {
      return false;
    }
  }

  /// Kontrollon përgjigjen e përdoruesit për një sfidë
  Future<Map<String, dynamic>> checkAnswer({
    required String subject,
    required String challengeTitle,
    required String challengeDescription,
    required String userAnswer,
    String? correctAnswer,
  }) async {
    final prompt = '''
Kontrollo përgjigjen e nxënësit. $subject: "$challengeTitle"
Sfida: $challengeDescription
${correctAnswer != null ? 'Saktë: $correctAnswer' : ''}
Nxënësi: $userAnswer

VETËM JSON (isCorrect duhet të jetë true ose false, score numër 0-100):
{"isCorrect":false,"score":50,"feedback":"inkurajues,shqip","correctAnswer":"...","explanation":"hapat e zgjidhjes"}
''';

    try {
      final response = await sendMessage(prompt, useHistory: false);
      
      // Nxjerr JSON nga përgjigja
      final jsonStr = _extractJson(response);
      if (jsonStr != null) {
        final result = jsonDecode(jsonStr) as Map<String, dynamic>;
        return {
          'isCorrect': result['isCorrect'] ?? false,
          'score': result['score'] ?? 0,
          'feedback': result['feedback'] ?? 'Nuk munda të analizoj përgjigjen.',
          'correctAnswer': result['correctAnswer'] ?? '',
          'explanation': result['explanation'] ?? '',
        };
      }
      return {
        'isCorrect': false,
        'score': 0,
        'feedback': 'Gjej gabim në analizimin e përgjigjes.',
        'correctAnswer': correctAnswer ?? '',
        'explanation': '',
      };
    } catch (e) {
      return {
        'isCorrect': false,
        'score': 0,
        'feedback': 'Gabim teknik: $e',
        'correctAnswer': correctAnswer ?? '',
        'explanation': '',
      };
    }
  }

  /// Analizon një imazh dhe kthen përgjigje bazuar në modalitetin
  Future<String> analyzeImage({
    required File imageFile,
    required String mode, // 'summarize', 'flashcard', 'quiz', 'lab', 'solve'
    String? additionalPrompt,
  }) async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_API_KEY_HERE') {
      return 'Gabim: API Key nuk është konfiguruar.';
    }

    try {
      // Konverto imazhin në base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Merr llojin e skedarit
      final path = imageFile.path.toLowerCase();
      String mimeType = 'image/jpeg';
      if (path.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (path.endsWith('.gif')) {
        mimeType = 'image/gif';
      } else if (path.endsWith('.webp')) {
        mimeType = 'image/webp';
      } else if (path.endsWith('.pdf')) {
        mimeType = 'application/pdf';
      } else if (path.endsWith('.docx')) {
        mimeType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      } else if (path.endsWith('.doc')) {
        mimeType = 'application/msword';
      } else if (path.endsWith('.txt')) {
        mimeType = 'text/plain';
      }

      // Ndërto prompt-in sipas modalitetit
      String prompt = _getPromptForMode(mode, additionalPrompt);

      final url = Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
                {
                  'inline_data': {
                    'mime_type': mimeType,
                    'data': base64Image,
                  }
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 2048,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List?;
          
          if (parts != null && parts.isNotEmpty) {
            return parts[0]['text'] ?? 'Nuk mora përgjigje.';
          }
        }
        return 'Nuk mora përgjigje nga AI.';
      } else {
        final error = jsonDecode(response.body);
        return 'Gabim: ${error['error']?['message'] ?? 'Diçka shkoi keq'}';
      }
    } catch (e) {
      return 'Gabim: $e';
    }
  }

  String _getPromptForMode(String mode, String? additionalPrompt) {
    final extra = additionalPrompt != null ? '\n\nKërkesë shtesë: $additionalPrompt' : '';
    
    switch (mode) {
      case 'summarize':
        return '''
Përmbledh këtë imazh studimi në shqip:
📚 TEMA: [tema kryesore]
📝 PIKAT KYÇE: [lista]
💡 KONCEPTET: [shpjegim i shkurtër]
🔗 LIDHJET: [si lidhen]
$extra''';
      
      case 'flashcard':
        return '''
Krijo 5-8 flashcards nga ky imazh studimi. Shqip.

Format për secilën:
🎴 FLASHCARD N:
PYETJE: [pyetja]
PËRGJIGJE: [përgjigja koncize]
$extra''';
      
      case 'quiz':
        return '''
Krijo kuiz 5-7 pyetje nga ky imazh. Shqip.

Format:
📝 KUIZI
1️⃣ [Pyetja]
   a) [A]  b) [B]  c) [C]  d) [D]
   ✅ Përgjigja: [shkronja]
$extra''';
      
      case 'lab':
        return '''
Krijo sfidë laboratori nga ky imazh shkencor. Shqip.

Format:
🔬 SFIDA E LABORATORIT
📌 TITULLI: [titulli]
📖 PËRSHKRIMI: [2-3 fjali]
🎯 OBJEKTIVI: [çfarë arrihet]
📋 HAPAT: [lista e numeruar]
💡 SUGJERIMET: [3 sugjerime]
✅ PËRGJIGJA E PRITUR: [zgjidhja]
$extra''';
      
      case 'solve':
        return '''
Zgjidh problemin në imazh hap pas hapi. Shqip.

Format:
📐 ZGJIDHJA
🔍 PROBLEMI: [çfarë sheh]
📝 TË DHËNAT: [lista]
🎯 KËRKOHET: [çfarë]
📋 HAPAT: [hap pas hapi me formula]
✅ PËRGJIGJA: [rezultati]
💡 SHËNIM: [këshillë]
$extra''';
      
      default:
        return '''
Shiko këtë imazh dhe më ndihmo të kuptoj përmbajtjen.
Përgjigju në shqip.
$extra''';
    }
  }

  /// Nxjerr ushtrimet nga një foto detyra
  Future<List<Map<String, String>>> extractExercisesFromImage(File imageFile) async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_API_KEY_HERE') {
      return [];
    }

    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      String mimeType = 'image/jpeg';
      if (imageFile.path.toLowerCase().endsWith('.png')) {
        mimeType = 'image/png';
      } else if (imageFile.path.toLowerCase().endsWith('.webp')) {
        mimeType = 'image/webp';
      }

      const prompt = '''
Nxirr ushtrimet nga ky imazh. VETËM JSON array:
[{"number":"1","title":"titull shkurt","text":"teksti i plotë me formula","subject":"Matematikë|Fizikë|Kimi|Biologji|Informatikë|Tjetër"}]
Ndaji saktë çdo ushtrim. Tekst komplet. VETËM JSON.
''';

      final url = Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
                {
                  'inline_data': {
                    'mime_type': mimeType,
                    'data': base64Image,
                  }
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 4096,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final text = candidates[0]['content']['parts'][0]['text'] ?? '';
          final jsonArrayStr = _extractJsonArray(text);
          if (jsonArrayStr != null) {
            final decoded = jsonDecode(jsonArrayStr);
            if (decoded is List) {
              final results = <Map<String, String>>[];
              for (final e in decoded) {
                if (e is Map) {
                  results.add({
                    'number': '${e['number'] ?? ''}',
                    'title': '${e['title'] ?? ''}',
                    'text': '${e['text'] ?? ''}',
                    'subject': '${e['subject'] ?? 'Tjetër'}',
                  });
                }
              }
              return results;
            }
          }
        }
      }
      return [];
    } catch (e) {
      debugPrint('extractExercisesFromImage error: $e');
      return [];
    }
  }

  /// Nxjerr ushtrimet nga një dokument PDF/tekst
  Future<List<Map<String, String>>> extractExercisesFromDocument(File docFile) async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_API_KEY_HERE') {
      return [];
    }

    try {
      final bytes = await docFile.readAsBytes();
      final base64Doc = base64Encode(bytes);
      final path = docFile.path.toLowerCase();

      String mimeType;
      if (path.endsWith('.pdf')) {
        mimeType = 'application/pdf';
      } else if (path.endsWith('.docx')) {
        mimeType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      } else if (path.endsWith('.doc')) {
        mimeType = 'application/msword';
      } else if (path.endsWith('.txt')) {
        mimeType = 'text/plain';
      } else {
        mimeType = 'application/pdf';
      }

      const prompt = '''
Nxirr ushtrimet nga ky dokument. VETËM JSON array:
[{"number":"1","title":"titull shkurt","text":"teksti i plotë me formula","subject":"Matematikë|Fizikë|Kimi|Biologji|Informatikë|Tjetër"}]
Ndaji saktë çdo ushtrim. Tekst komplet. VETËM JSON.
''';

      final url = Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
                {
                  'inline_data': {
                    'mime_type': mimeType,
                    'data': base64Doc,
                  }
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 8192,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final text = candidates[0]['content']['parts'][0]['text'] ?? '';
          final jsonArrayStr = _extractJsonArray(text);
          if (jsonArrayStr != null) {
            final decoded = jsonDecode(jsonArrayStr);
            if (decoded is List) {
              final results = <Map<String, String>>[];
              for (final e in decoded) {
                if (e is Map) {
                  results.add({
                    'number': '${e['number'] ?? ''}',
                    'title': '${e['title'] ?? ''}',
                    'text': '${e['text'] ?? ''}',
                    'subject': '${e['subject'] ?? 'Tjetër'}',
                  });
                }
              }
              return results;
            }
          }
        }
      }
      return [];
    } catch (e) {
      debugPrint('extractExercisesFromDocument error: $e');
      return [];
    }
  }

  /// Zgjidh një ushtrim hap pas hapi
  Future<String> solveExercise({
    required String exerciseText,
    required String subject,
  }) async {
    final prompt = '''
Zgjidh këtë ushtrim $subject hap pas hapi. Shqip.

USHTRIMI: $exerciseText

Format:
📐 **ZGJIDHJA**
🔍 **Të dhënat:** [lista]
🎯 **Kërkohet:** [çfarë]
📋 **Hapat:**
**Hapi 1:** [veprim + formulë]
**Hapi 2:** [veprim + formulë]
...
✅ **Përgjigja:** [rezultati]
💡 **Këshillë:** [1 fjali]
''';

    return sendMessage(prompt, useHistory: false);
  }

  /// Gjeneron skript për mësim audio
  Future<Map<String, String>?> generateAudioLessonScript({
    required String subject,
    required String topic,
  }) async {
    final prompt = '''
Krijo një mësim audio për lëndën "$subject", tema: "$topic".
Mësimi duhet të jetë për nxënës të shkollës së mesme në Shqipëri, në shqip.

RREGULLA TË RËNDËSISHME:
- Shkruaj VETËM tekst të thjeshtë prozë (pa simbole matematikore, pa markdown, pa lista me pika)
- Mos përdor kurrë simbole si: *, #, -, =, +, ^, √, ≠, ≤, ≥
- Numrat dhe formulat shkruaji me fjalë (p.sh. "x në katror" jo "x²", "rrënja katrore" jo "√")
- Stili duhet të jetë si një mësues që flet natyrshëm
- Fillo me një hyrje tërheqëse
- Shpjego konceptet hap pas hapi me shembuj të thjeshtë
- Përfundo me një përmbledhje
- Gjatësia: 400-600 fjalë

VETËM JSON:
{"title":"Titulli i mësimit","script":"Teksti i plotë i mësimit..."}
''';

    try {
      final response = await sendMessage(prompt, useHistory: false);
      final jsonStr = _extractJson(response);
      if (jsonStr != null) {
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        return {
          'title': decoded['title']?.toString() ?? topic,
          'script': decoded['script']?.toString() ?? '',
        };
      }
      return null;
    } catch (e) {
      debugPrint('generateAudioLessonScript error: $e');
      return null;
    }
  }

  /// Gjeneron flashcards nga teksti i nxjerrë nga imazhi
  Future<List<Map<String, String>>> generateFlashcardsFromImage(File imageFile) async {
    final response = await analyzeImage(imageFile: imageFile, mode: 'flashcard');
    
    // Parse flashcards from response
    List<Map<String, String>> flashcards = [];
    final lines = response.split('\n');
    
    String? currentQuestion;
    for (var line in lines) {
      if (line.contains('PYETJE:')) {
        currentQuestion = line.replaceAll(RegExp(r'.*PYETJE:\s*'), '').trim();
      } else if (line.contains('PËRGJIGJE:') && currentQuestion != null) {
        final answer = line.replaceAll(RegExp(r'.*PËRGJIGJE:\s*'), '').trim();
        flashcards.add({
          'question': currentQuestion,
          'answer': answer,
        });
        currentQuestion = null;
      }
    }
    
    return flashcards;
  }

  /// Gjeneron quiz nga imazhi
  Future<List<Map<String, dynamic>>> generateQuizFromImage(File imageFile) async {
    final response = await analyzeImage(imageFile: imageFile, mode: 'quiz');
    
    // Parse quiz from response (simplified parsing)
    List<Map<String, dynamic>> questions = [];
    
    final questionBlocks = response.split(RegExp(r'\n\d️⃣|\n\d\)|\n\d\.'));
    
    for (var block in questionBlocks) {
      if (block.trim().isEmpty) continue;
      
      final lines = block.split('\n').where((l) => l.trim().isNotEmpty).toList();
      if (lines.isEmpty) continue;
      
      String question = lines.first.trim();
      List<String> options = [];
      int correctIndex = 0;
      
      for (var line in lines.skip(1)) {
        if (line.contains(RegExp(r'^\s*[a-d]\)'))) {
          options.add(line.replaceAll(RegExp(r'^\s*[a-d]\)\s*'), '').trim());
        } else if (line.contains('✅') || line.toLowerCase().contains('përgjigje')) {
          final match = RegExp(r'[a-d]').firstMatch(line.toLowerCase());
          if (match != null) {
            correctIndex = match.group(0)!.codeUnitAt(0) - 'a'.codeUnitAt(0);
          }
        }
      }
      
      if (question.isNotEmpty && options.length >= 2) {
        questions.add({
          'question': question,
          'options': options,
          'correctIndex': correctIndex.clamp(0, options.length - 1),
        });
      }
    }
    
    return questions;
  }
}
