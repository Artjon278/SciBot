import 'package:flutter/material.dart';
import '../../data/challenges.dart';
import '../../services/gemini_service.dart';
import '../../widgets/science_visualizations.dart';

class ChallengeSolveScreen extends StatefulWidget {
  final Challenge challenge;

  const ChallengeSolveScreen({super.key, required this.challenge});

  @override
  State<ChallengeSolveScreen> createState() => _ChallengeSolveScreenState();
}

class _ChallengeSolveScreenState extends State<ChallengeSolveScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _answerController = TextEditingController();
  final TextEditingController _finalAnswerController = TextEditingController();
  final List<Map<String, dynamic>> _chatMessages = [];
  // ignore: unused_field
  final bool _showHints = false;
  int _currentHintIndex = 0;
  bool _isLoading = false;
  
  // Answer check state
  bool _isCheckingAnswer = false;
  Map<String, dynamic>? _answerResult;
  late AnimationController _resultAnimController;
  late Animation<double> _resultAnimation;

  @override
  void initState() {
    super.initState();
    _resultAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _resultAnimation = CurvedAnimation(
      parent: _resultAnimController,
      curve: Curves.easeOutBack,
    );
    
    // Add initial bot message with the challenge
    _chatMessages.add({
      'role': 'bot',
      'content': '🎯 **${widget.challenge.title}**\n\n${widget.challenge.description}\n\nShkruaj përgjigjen tënde ose kërko ndihmë!',
    });
  }

  @override
  void dispose() {
    _answerController.dispose();
    _finalAnswerController.dispose();
    _resultAnimController.dispose();
    super.dispose();
  }

  Future<void> _checkFinalAnswer() async {
    if (_finalAnswerController.text.trim().isEmpty) return;
    
    setState(() {
      _isCheckingAnswer = true;
      _answerResult = null;
    });
    
    final gemini = GeminiService();
    final result = await gemini.checkAnswer(
      subject: widget.challenge.subject,
      challengeTitle: widget.challenge.title,
      challengeDescription: widget.challenge.description,
      userAnswer: _finalAnswerController.text.trim(),
      correctAnswer: widget.challenge.correctAnswer,
    );
    
    setState(() {
      _isCheckingAnswer = false;
      _answerResult = result;
    });
    
    _resultAnimController.forward(from: 0);
  }

  void _resetAnswer() {
    setState(() {
      _answerResult = null;
      _finalAnswerController.clear();
    });
  }

  Future<void> _sendMessage() async {
    if (_answerController.text.trim().isEmpty) return;

    final userMessage = _answerController.text.trim();
    setState(() {
      _chatMessages.add({
        'role': 'user',
        'content': userMessage,
      });
      _isLoading = true;
    });
    _answerController.clear();

    // Check for hint requests locally first
    final lowerMessage = userMessage.toLowerCase();
    if (lowerMessage.contains('sugjerim') || lowerMessage.contains('ndihmë') || lowerMessage.contains('hint')) {
      if (_currentHintIndex < widget.challenge.hints.length) {
        final hint = widget.challenge.hints[_currentHintIndex];
        _currentHintIndex++;
        if (mounted) {
          setState(() {
            _isLoading = false;
            _chatMessages.add({
              'role': 'bot',
              'content': '💡 **Sugjerim $_currentHintIndex:**\n\n$hint\n\n${_currentHintIndex < widget.challenge.hints.length ? "Kërko përsëri nëse të duhet tjetër sugjerim." : "Ky ishte sugjerimi i fundit!"}',
            });
          });
        }
        return;
      }
    }

    // Use Gemini API for real AI responses
    try {
      final gemini = GeminiService();
      final response = await gemini.sendMessage(
        userMessage,
        context: 'Lënda: ${widget.challenge.subject}\nSfida: ${widget.challenge.title}\nPërshkrimi: ${widget.challenge.description}\nNdihmo nxënësin por mos jep përgjigjen direkt. Udhëzo hap pas hapi.',
        useHistory: false,
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          _chatMessages.add({
            'role': 'bot',
            'content': response,
          });
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _chatMessages.add({
            'role': 'bot',
            'content': '⚠️ Gabim në lidhje me AI. Provo përsëri.',
          });
        });
      }
    }
  }

  void _showSolution() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return AlertDialog(
          backgroundColor: theme.scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Text(widget.challenge.iconEmoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              const Expanded(child: Text('Zgjidhja')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hapat e zgjidhjes:',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...widget.challenge.hints.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '${entry.key + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Mbyll',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.06),
                  ),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.challenge.iconEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.challenge.title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.challenge.subject,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _showSolution,
                    icon: Icon(
                      Icons.lightbulb_outline,
                      color: theme.colorScheme.secondary,
                    ),
                    tooltip: 'Shiko zgjidhjen',
                  ),
                ],
              ),
            ),

            // Visualization (if available)
            _buildVisualization(isDark),

            // Answer Submission Section
            _buildAnswerSection(theme, isDark),

            // Chat messages
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _chatMessages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isLoading && index == _chatMessages.length) {
                    return _buildTypingIndicator(isDark);
                  }
                  final message = _chatMessages[index];
                  return _buildMessageBubble(
                    message['content'],
                    message['role'] == 'user',
                    isDark,
                  );
                },
              ),
            ),

            // Input area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.06),
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Quick actions
                  Row(
                    children: [
                      _buildQuickAction(
                        context,
                        label: '💡 Kërko ndihmë',
                        onTap: () {
                          _answerController.text = 'Më jep një sugjerim';
                          _sendMessage();
                        },
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildQuickAction(
                        context,
                        label: '📝 Shpjego',
                        onTap: () {
                          _answerController.text = 'Më shpjego konceptin';
                          _sendMessage();
                        },
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Text input
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _answerController,
                            style: theme.textTheme.bodyLarge,
                            decoration: InputDecoration(
                              hintText: 'Shkruaj përgjigjen...',
                              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.secondary.withOpacity(0.6),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: IconButton(
                            onPressed: _sendMessage,
                            icon: Icon(
                              Icons.arrow_upward_rounded,
                              color: isDark ? Colors.black : Colors.white,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: isDark ? Colors.white : Colors.black,
                              padding: const EdgeInsets.all(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String content, bool isUser, bool isDark) {
    final theme = Theme.of(context);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 12,
          left: isUser ? 48 : 0,
          right: isUser ? 0 : 48,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser
              ? (isDark ? Colors.white : Colors.black)
              : (isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.04)),
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
        ),
        child: Text(
          content,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isUser
                ? (isDark ? Colors.black : Colors.white)
                : theme.colorScheme.onSurface,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 48),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: const Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            const SizedBox(width: 4),
            _buildDot(1),
            const SizedBox(width: 4),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildVisualization(bool isDark) {
    Widget? visualization;

    // Get visualization based on challenge ID
    switch (widget.challenge.id) {
      // Kimi
      case 'kim_2': // Struktura e Atomit
        visualization = AtomStructureVisualization(isDark: isDark);
        break;
      
      // Biologji
      case 'bio_1': // Struktura e ADN-së
        visualization = DNAVisualization(isDark: isDark);
        break;
      case 'bio_2': // Fotosenteza
        visualization = CellVisualization(isDark: isDark);
        break;
      case 'bio_3': // Mitoza dhe Mejoza
        visualization = CellVisualization(isDark: isDark);
        break;
      
      // Fizikë
      case 'fiz_1': // Ligjet e Njutonit
        visualization = NewtonLawVisualization(isDark: isDark);
        break;
      case 'fiz_2': // Qarqet elektrike
        visualization = CircuitVisualization(isDark: isDark);
        break;
      case 'fiz_3': // Energjia Kinetike
        visualization = EnergyVisualization(isDark: isDark);
        break;
      case 'fiz_4': // Valët dhe Zëri
        visualization = WaveVisualization(isDark: isDark);
        break;
    }

    if (visualization == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: visualization,
      ),
    );
  }

  Widget _buildAnswerSection(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.green.withOpacity(0.15), Colors.blue.withOpacity(0.15)]
              : [Colors.green.withOpacity(0.08), Colors.blue.withOpacity(0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.green.withOpacity(0.2)
                      : Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dorëzo Përgjigjen',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'AI do të kontrollojë përgjigjen tënde',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Answer input
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.15)
                    : Colors.black.withOpacity(0.1),
              ),
            ),
            child: TextField(
              controller: _finalAnswerController,
              style: theme.textTheme.bodyLarge,
              maxLines: 2,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Shkruaj përgjigjen finale këtu...',
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.secondary.withOpacity(0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Submit button or result
          if (_answerResult == null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCheckingAnswer ? null : _checkFinalAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isCheckingAnswer
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text('Po kontrollohet...'),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Kontrollo Përgjigjen',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
              ),
            )
          else
            _buildAnswerResult(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildAnswerResult(ThemeData theme, bool isDark) {
    final result = _answerResult!;
    final isCorrect = result['isCorrect'] as bool;
    final score = result['score'] as int;
    final feedback = result['feedback'] as String;
    final correctAnswer = result['correctAnswer'] as String;
    final explanation = result['explanation'] as String;

    return ScaleTransition(
      scale: _resultAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCorrect
                  ? Colors.green.withOpacity(isDark ? 0.25 : 0.15)
                  : Colors.red.withOpacity(isDark ? 0.25 : 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCorrect
                    ? Colors.green.withOpacity(0.4)
                    : Colors.red.withOpacity(0.4),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? Colors.green.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    color: isCorrect ? Colors.green : Colors.red,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isCorrect ? '✅ E saktë!' : '❌ Jo e saktë',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isCorrect ? Colors.green : Colors.red,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getScoreColor(score).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$score/100',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getScoreColor(score),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feedback,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Correct answer (if wrong)
          if (!isCorrect && correctAnswer.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.blue.withOpacity(0.15)
                    : Colors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb, color: Colors.blue, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Përgjigja e saktë:',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    correctAnswer,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Explanation
          if (explanation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.school,
                        color: theme.colorScheme.secondary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Shpjegimi:',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    explanation,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Try again button
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _resetAnswer,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.3)
                      : Colors.black.withOpacity(0.2),
                ),
              ),
              child: const Text('🔄 Provo përsëri'),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }
}
