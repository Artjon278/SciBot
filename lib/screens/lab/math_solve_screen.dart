import 'package:flutter/material.dart';
import '../../data/challenges.dart';
import '../../services/gemini_service.dart';
import '../../widgets/math_visualizations.dart';

class MathSolveScreen extends StatefulWidget {
  final Challenge challenge;

  const MathSolveScreen({super.key, required this.challenge});

  @override
  State<MathSolveScreen> createState() => _MathSolveScreenState();
}

class _MathSolveScreenState extends State<MathSolveScreen> with SingleTickerProviderStateMixin {
  String _currentInput = '';
  String _result = '';
  bool _showResult = false;
  bool _isCorrect = false;
  final List<String> _steps = [];
  bool _showHelpChat = false;
  final List<Map<String, String>> _helpMessages = [];
  int _currentHintIndex = 0;
  
  // AI Answer checking state
  // ignore: unused_field
  final bool _isCheckingWithAI = false;
  // ignore: unused_field
  Map<String, dynamic>? _aiResult;
  late AnimationController _resultAnimController;
  // ignore: unused_field
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
  }

  @override
  void dispose() {
    _resultAnimController.dispose();
    super.dispose();
  }

  void _addToInput(String value) {
    setState(() {
      _currentInput += value;
      _showResult = false;
    });
  }

  void _clear() {
    setState(() {
      _currentInput = '';
      _result = '';
      _showResult = false;
    });
  }

  void _backspace() {
    if (_currentInput.isNotEmpty) {
      setState(() {
        _currentInput = _currentInput.substring(0, _currentInput.length - 1);
        _showResult = false;
      });
    }
  }

  void _calculate() {
    if (_currentInput.isEmpty) return;
    
    try {
      // Simple evaluation for basic math
      String result = _evaluateExpression(_currentInput);
      setState(() {
        _result = result;
        _steps.add('$_currentInput = $result');
      });
    } catch (e) {
      setState(() {
        _result = 'Gabim';
      });
    }
  }

  String _evaluateExpression(String expression) {
    // Basic evaluation - replace with a proper math parser in production
    expression = expression.replaceAll('×', '*').replaceAll('÷', '/').replaceAll('−', '-');
    
    try {
      // Very simple evaluation for demo purposes
      // In production, use a proper math expression parser
      final result = _simpleEval(expression);
      return result.toString();
    } catch (e) {
      return 'Gabim';
    }
  }

  double _simpleEval(String expr) {
    expr = expr.replaceAll(' ', '');
    
    // Handle parentheses first
    while (expr.contains('(')) {
      final start = expr.lastIndexOf('(');
      final end = expr.indexOf(')', start);
      if (end == -1) throw Exception('Invalid expression');
      final inner = expr.substring(start + 1, end);
      final result = _simpleEval(inner);
      expr = expr.substring(0, start) + result.toString() + expr.substring(end + 1);
    }
    
    // Split by + and - (keeping the operators)
    List<String> terms = [];
    String current = '';
    for (int i = 0; i < expr.length; i++) {
      if ((expr[i] == '+' || expr[i] == '-') && i > 0 && !('*/^'.contains(expr[i-1]))) {
        terms.add(current);
        current = expr[i];
      } else {
        current += expr[i];
      }
    }
    terms.add(current);
    
    double result = 0;
    for (String term in terms) {
      if (term.isEmpty) continue;
      result += _evalTerm(term);
    }
    
    return result;
  }

  double _evalTerm(String term) {
    // Handle multiplication and division
    List<String> factors = [];
    List<String> operators = [];
    String current = '';
    
    for (int i = 0; i < term.length; i++) {
      if (term[i] == '*' || term[i] == '/') {
        factors.add(current);
        operators.add(term[i]);
        current = '';
      } else {
        current += term[i];
      }
    }
    factors.add(current);
    
    double result = double.tryParse(factors[0]) ?? 0;
    for (int i = 0; i < operators.length; i++) {
      double next = double.tryParse(factors[i + 1]) ?? 0;
      if (operators[i] == '*') {
        result *= next;
      } else {
        result /= next;
      }
    }
    
    return result;
  }

  // ignore: unused_element
  void _saveStep() {
    if (_currentInput.isNotEmpty && _result.isNotEmpty) {
      setState(() {
        _currentInput = _result;
        _result = '';
      });
    }
  }

  void _checkAnswer() {
    setState(() {
      _showResult = true;
      // Simple check - in production, use proper answer matching
      String userAnswer = _result.isNotEmpty ? _result : _currentInput;
      userAnswer = userAnswer.replaceAll(' ', '');
      String correctAnswer = widget.challenge.correctAnswer?.replaceAll(' ', '') ?? '';
      
      // Check if the numeric values match
      try {
        double userNum = double.parse(userAnswer);
        double correctNum = double.parse(correctAnswer);
        _isCorrect = (userNum - correctNum).abs() < 0.01;
      } catch (e) {
        _isCorrect = userAnswer.toLowerCase() == correctAnswer.toLowerCase();
      }
    });

    if (_isCorrect) {
      _showSuccessDialog();
    } else {
      _showAICheckDialog();
    }
  }

  Future<void> _showAICheckDialog() async {
    String userAnswer = _result.isNotEmpty ? _result : _currentInput;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.scaffoldBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: FutureBuilder<Map<String, dynamic>>(
                future: _checkWithAI(userAnswer),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'AI po analizon...',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Duke kontrolluar përgjigjen tënde',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    );
                  }

                  if (snapshot.hasError) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text('Gabim: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Mbyll'),
                        ),
                      ],
                    );
                  }

                  final result = snapshot.data!;
                  final isCorrect = result['isCorrect'] as bool;
                  final score = result['score'] as int;
                  final feedback = result['feedback'] as String;
                  final correctAnswer = result['correctAnswer'] as String;
                  final explanation = result['explanation'] as String;

                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Result icon
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? Colors.green.withOpacity(0.15)
                                : Colors.red.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCorrect ? Icons.check_rounded : Icons.close_rounded,
                            color: isCorrect ? Colors.green : Colors.red,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Title and score
                        Text(
                          isCorrect ? 'Saktë! 🎉' : 'Jo krejtësisht...',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isCorrect ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Score badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getScoreColor(score).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Pikët: $score/100',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getScoreColor(score),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Feedback
                        Text(
                          feedback,
                          style: theme.textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        
                        // Correct answer (if wrong)
                        if (!isCorrect && correctAnswer.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(isDark ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.lightbulb, color: Colors.blue, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Përgjigja e saktë:',
                                      style: TextStyle(
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
                                  : Colors.black.withOpacity(0.04),
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
                                    const SizedBox(width: 6),
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
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    _showResult = false;
                                    _aiResult = null;
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Provo prapë'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? Colors.white : Colors.black,
                                  foregroundColor: isDark ? Colors.black : Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Kthehu'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _checkWithAI(String userAnswer) async {
    final gemini = GeminiService();
    return await gemini.checkAnswer(
      subject: widget.challenge.subject,
      challengeTitle: widget.challenge.title,
      challengeDescription: widget.challenge.description,
      userAnswer: userAnswer,
      correctAnswer: widget.challenge.correctAnswer,
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  void _askForHelp() {
    setState(() {
      _showHelpChat = true;
    });
    
    if (_helpMessages.isEmpty) {
      _helpMessages.add({
        'role': 'bot',
        'content': '👋 Përshëndetje! Jam këtu për të të ndihmuar me "${widget.challenge.title}".\n\nÇfarë të duhet?',
      });
    }
  }

  void _getHint() {
    if (_currentHintIndex < widget.challenge.hints.length) {
      setState(() {
        _helpMessages.add({
          'role': 'user',
          'content': 'Më jep një sugjerim',
        });
        _helpMessages.add({
          'role': 'bot',
          'content': '💡 Sugjerim ${_currentHintIndex + 1}:\n\n${widget.challenge.hints[_currentHintIndex]}',
        });
        _currentHintIndex++;
      });
    } else {
      setState(() {
        _helpMessages.add({
          'role': 'user',
          'content': 'Më jep një sugjerim',
        });
        _helpMessages.add({
          'role': 'bot',
          'content': '📚 Të kam dhënë të gjitha sugjerimet! Provo të zgjidhësh me informacionin që ke.',
        });
      });
    }
  }

  void _showSuccessDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.green,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Saktë! 🎉',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Përgjigja: ${widget.challenge.correctAnswer}',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Vazhdo',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
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
                    child: Text(
                      widget.challenge.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Help button
                  GestureDetector(
                    onTap: _askForHelp,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.blue.withOpacity(0.2)
                            : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.help_outline,
                            size: 18,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Ndihmë',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: _showHelpChat ? _buildHelpChat(isDark) : _buildCalculator(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculator(bool isDark) {
    final theme = Theme.of(context);
    final visualization = getVisualizationForChallenge(widget.challenge.id, isDark);

    return Column(
      children: [
        // Visualization (if available)
        if (visualization != null)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
            child: visualization,
          ),

        // Challenge description
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.challenge.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.4,
            ),
          ),
        ),

        // Display area
        Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _showResult
                    ? (_isCorrect ? Colors.green : Colors.red)
                    : (isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.08)),
                width: _showResult ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Previous steps
                if (_steps.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: _steps.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            _steps[index],
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        );
                      },
                    ),
                  )
                else
                  const Spacer(),
                
                // Current input
                Text(
                  _currentInput.isEmpty ? '0' : _currentInput,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                ),
                
                // Result
                if (_result.isNotEmpty)
                  Text(
                    '= $_result',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      color: _showResult
                          ? (_isCorrect ? Colors.green : Colors.red)
                          : theme.colorScheme.secondary,
                    ),
                    textAlign: TextAlign.right,
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Calculator keyboard
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
              // Row 1: Special keys
              Row(
                children: [
                  _buildKey('C', onTap: _clear, isSpecial: true, isDark: isDark),
                  _buildKey('⌫', onTap: _backspace, isSpecial: true, isDark: isDark),
                  _buildKey('(', isDark: isDark),
                  _buildKey(')', isDark: isDark),
                  _buildKey('√', isDark: isDark),
                ],
              ),
              const SizedBox(height: 8),
              // Row 2
              Row(
                children: [
                  _buildKey('7', isDark: isDark),
                  _buildKey('8', isDark: isDark),
                  _buildKey('9', isDark: isDark),
                  _buildKey('÷', isOperator: true, isDark: isDark),
                  _buildKey('^', isDark: isDark),
                ],
              ),
              const SizedBox(height: 8),
              // Row 3
              Row(
                children: [
                  _buildKey('4', isDark: isDark),
                  _buildKey('5', isDark: isDark),
                  _buildKey('6', isDark: isDark),
                  _buildKey('×', isOperator: true, isDark: isDark),
                  _buildKey('x', isVariable: true, isDark: isDark),
                ],
              ),
              const SizedBox(height: 8),
              // Row 4
              Row(
                children: [
                  _buildKey('1', isDark: isDark),
                  _buildKey('2', isDark: isDark),
                  _buildKey('3', isDark: isDark),
                  _buildKey('−', isOperator: true, isDark: isDark),
                  _buildKey('y', isVariable: true, isDark: isDark),
                ],
              ),
              const SizedBox(height: 8),
              // Row 5
              Row(
                children: [
                  _buildKey('0', isDark: isDark),
                  _buildKey('.', isDark: isDark),
                  _buildKey('=', onTap: _calculate, isOperator: true, isDark: isDark),
                  _buildKey('+', isOperator: true, isDark: isDark),
                  _buildKey('✓', onTap: _checkAnswer, isCheck: true, isDark: isDark),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKey(
    String label, {
    VoidCallback? onTap,
    bool isOperator = false,
    bool isSpecial = false,
    bool isVariable = false,
    bool isCheck = false,
    required bool isDark,
  }) {
    final theme = Theme.of(context);

    Color bgColor;
    Color textColor;

    if (isCheck) {
      bgColor = Colors.green;
      textColor = Colors.white;
    } else if (isOperator) {
      bgColor = isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.08);
      textColor = isDark ? Colors.white : Colors.black;
    } else if (isSpecial) {
      bgColor = isDark ? Colors.red.withOpacity(0.2) : Colors.red.withOpacity(0.1);
      textColor = Colors.red;
    } else if (isVariable) {
      bgColor = isDark ? Colors.blue.withOpacity(0.2) : Colors.blue.withOpacity(0.1);
      textColor = Colors.blue;
    } else {
      bgColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04);
      textColor = theme.colorScheme.onSurface;
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          onTap: onTap ?? () => _addToInput(label),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpChat(bool isDark) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Back to calculator button
        Padding(
          padding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: () => setState(() => _showHelpChat = false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calculate_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurface,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Kthehu tek kalkulatori',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Chat messages
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _helpMessages.length,
            itemBuilder: (context, index) {
              final message = _helpMessages[index];
              final isUser = message['role'] == 'user';

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
                    message['content']!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isUser
                          ? (isDark ? Colors.black : Colors.white)
                          : theme.colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Quick actions
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
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _getHint,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.08),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '💡 Sugjerim',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _helpMessages.add({
                        'role': 'user',
                        'content': 'Më shpjego formulën',
                      });
                      _helpMessages.add({
                        'role': 'bot',
                        'content': '📝 Për këtë sfidë, duhet të përdorësh:\n\n${widget.challenge.hints.join('\n\n')}',
                      });
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.08),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '📝 Formula',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
