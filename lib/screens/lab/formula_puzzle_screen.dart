import 'package:flutter/material.dart';
import '../../data/challenges.dart';
import '../../services/gemini_service.dart';

class FormulaPuzzleScreen extends StatefulWidget {
  final Challenge challenge;

  const FormulaPuzzleScreen({super.key, required this.challenge});

  @override
  State<FormulaPuzzleScreen> createState() => _FormulaPuzzleScreenState();
}

class _FormulaPuzzleScreenState extends State<FormulaPuzzleScreen> {
  late List<String> _availableElements;
  final List<String> _selectedElements = [];
  bool _isCorrect = false;
  bool _showResult = false;
  // ignore: unused_field
  final bool _isCheckingWithAI = false;

  @override
  void initState() {
    super.initState();
    _availableElements = List.from(widget.challenge.puzzleElements ?? []);
    _availableElements.shuffle();
  }

  void _addElement(String element, int index) {
    setState(() {
      _selectedElements.add(element);
      _availableElements.removeAt(index);
      _showResult = false;
    });
  }

  void _removeElement(int index) {
    setState(() {
      _availableElements.add(_selectedElements[index]);
      _selectedElements.removeAt(index);
      _showResult = false;
    });
  }

  void _checkAnswer() {
    String userFormula = _buildFormula(_selectedElements);
    setState(() {
      _isCorrect = userFormula == widget.challenge.correctAnswer;
      _showResult = true;
    });

    if (_isCorrect) {
      _showSuccessDialog();
    } else {
      _showAICheckDialog(userFormula);
    }
  }

  Future<void> _showAICheckDialog(String userFormula) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return AlertDialog(
          backgroundColor: theme.scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: FutureBuilder<Map<String, dynamic>>(
            future: _checkWithAI(userFormula),
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
                      'Duke kontrolluar formulën "$userFormula"',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                      textAlign: TextAlign.center,
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
                      isCorrect ? 'E saktë! 🎉' : 'Jo e saktë',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isCorrect ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // User's answer
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Përgjigja jote: $userFormula',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
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
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.lightbulb, color: Colors.blue, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Formula e saktë:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              correctAnswer,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
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
                              _resetPuzzle();
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('🔄 Provo prapë'),
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
  }

  Future<Map<String, dynamic>> _checkWithAI(String userFormula) async {
    final gemini = GeminiService();
    return await gemini.checkAnswer(
      subject: widget.challenge.subject,
      challengeTitle: widget.challenge.title,
      challengeDescription: widget.challenge.description,
      userAnswer: userFormula,
      correctAnswer: widget.challenge.correctAnswer,
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  String _buildFormula(List<String> elements) {
    if (widget.challenge.puzzleType == 'balance') {
      return elements.join('');
    }
    
    // Count elements and build formula
    Map<String, int> counts = {};
    for (var element in elements) {
      counts[element] = (counts[element] ?? 0) + 1;
    }
    
    // Build formula string
    StringBuffer formula = StringBuffer();
    // Order: C, H, then alphabetically
    List<String> orderedElements = counts.keys.toList();
    orderedElements.sort((a, b) {
      if (a == 'C') return -1;
      if (b == 'C') return 1;
      if (a == 'H') return -1;
      if (b == 'H') return 1;
      return a.compareTo(b);
    });
    
    for (var element in orderedElements) {
      formula.write(element);
      if (counts[element]! > 1) {
        formula.write(_subscript(counts[element]!));
      }
    }
    
    return formula.toString();
  }

  String _subscript(int number) {
    const subscripts = ['₀', '₁', '₂', '₃', '₄', '₅', '₆', '₇', '₈', '₉'];
    String result = '';
    for (var digit in number.toString().split('')) {
      result += subscripts[int.parse(digit)];
    }
    return result;
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return AlertDialog(
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
                'Ti krijove ${widget.challenge.correctAnswer}',
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
        );
      },
    );
  }

  void _resetPuzzle() {
    setState(() {
      _availableElements = List.from(widget.challenge.puzzleElements ?? []);
      _availableElements.shuffle();
      _selectedElements.clear();
      _showResult = false;
      _isCorrect = false;
    });
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
                  Expanded(
                    child: Text(
                      widget.challenge.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _resetPuzzle,
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: theme.colorScheme.secondary,
                    ),
                    tooltip: 'Rifillo',
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Challenge description
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            widget.challenge.iconEmoji,
                            style: const TextStyle(fontSize: 40),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.challenge.description,
                            style: theme.textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Formula display area
                    Text(
                      'Formula jote:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 80),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _showResult
                            ? (_isCorrect
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1))
                            : (isDark
                                ? Colors.white.withOpacity(0.08)
                                : Colors.black.withOpacity(0.04)),
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
                      child: _selectedElements.isEmpty
                          ? Center(
                              child: Text(
                                'Kliko elementet për ti shtuar këtu',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: _selectedElements
                                  .asMap()
                                  .entries
                                  .map((entry) => _buildElementChip(
                                        entry.value,
                                        () => _removeElement(entry.key),
                                        true,
                                        isDark,
                                      ))
                                  .toList(),
                            ),
                    ),

                    if (_selectedElements.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _buildFormula(_selectedElements),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _showResult
                              ? (_isCorrect ? Colors.green : Colors.red)
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Available elements
                    Text(
                      'Elementet e disponueshme:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      constraints: const BoxConstraints(minHeight: 100),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: _availableElements
                            .asMap()
                            .entries
                            .map((entry) => _buildElementChip(
                                  entry.value,
                                  () => _addElement(entry.value, entry.key),
                                  false,
                                  isDark,
                                ))
                            .toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _resetPuzzle,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(
                                color: isDark
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.black.withOpacity(0.1),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Rifillo',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _selectedElements.isNotEmpty
                                ? _checkAnswer
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isDark ? Colors.white : Colors.black,
                              foregroundColor:
                                  isDark ? Colors.black : Colors.white,
                              disabledBackgroundColor: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.05),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Kontrollo',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElementChip(
    String element,
    VoidCallback onTap,
    bool isSelected,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    
    // Element colors
    Color bgColor;
    Color textColor;
    
    if (element == 'H') {
      bgColor = Colors.blue.withOpacity(0.15);
      textColor = Colors.blue;
    } else if (element == 'O') {
      bgColor = Colors.red.withOpacity(0.15);
      textColor = Colors.red;
    } else if (element == 'C') {
      bgColor = Colors.grey.withOpacity(0.15);
      textColor = isDark ? Colors.grey[300]! : Colors.grey[700]!;
    } else if (element == 'Na') {
      bgColor = Colors.purple.withOpacity(0.15);
      textColor = Colors.purple;
    } else if (element == 'Cl') {
      bgColor = Colors.green.withOpacity(0.15);
      textColor = Colors.green;
    } else if (element == 'S') {
      bgColor = Colors.yellow.withOpacity(0.15);
      textColor = Colors.orange;
    } else if (element == 'Fe') {
      bgColor = Colors.orange.withOpacity(0.15);
      textColor = Colors.orange;
    } else {
      bgColor = isDark
          ? Colors.white.withOpacity(0.1)
          : Colors.black.withOpacity(0.05);
      textColor = theme.colorScheme.onSurface;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: textColor.withOpacity(0.3),
          ),
          boxShadow: isSelected
              ? []
              : [
                  BoxShadow(
                    color: textColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Text(
          element,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
