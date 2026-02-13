import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../data/quiz_data.dart';
import '../../services/quiz_stats_service.dart';

class QuizPlayScreen extends StatefulWidget {
  final List<QuizQuestion> questions;
  final String title;

  const QuizPlayScreen({
    super.key,
    required this.questions,
    required this.title,
  });

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedAnswer;
  bool _answered = false;
  bool _showExplanation = false;
  Timer? _timer;
  int _timeLeft = 30;
  List<int?> _userAnswers = [];

  @override
  void initState() {
    super.initState();
    _userAnswers = List.filled(widget.questions.length, null);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timeLeft = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    if (!_answered) {
      setState(() {
        _answered = true;
        _showExplanation = true;
      });
      _timer?.cancel();
    }
  }

  void _selectAnswer(int index) {
    if (_answered) return;

    setState(() {
      _selectedAnswer = index;
    });
  }

  void _confirmAnswer() {
    if (_selectedAnswer == null || _answered) return;

    final isCorrect = _selectedAnswer == widget.questions[_currentIndex].correctIndex;

    setState(() {
      _answered = true;
      _showExplanation = true;
      _userAnswers[_currentIndex] = _selectedAnswer;
      if (isCorrect) _score++;
    });
    _timer?.cancel();
  }

  void _nextQuestion() {
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answered = false;
        _showExplanation = false;
      });
      _startTimer();
    } else {
      _showResults();
    }
  }

  void _showResults() {
    // Save quiz result to stats
    context.read<QuizStatsService>().addResult(
      title: widget.title,
      subject: widget.questions.isNotEmpty ? widget.questions.first.subject : null,
      totalQuestions: widget.questions.length,
      correctAnswers: _score,
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final percentage = (_score / widget.questions.length * 100).round();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            // Result icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _getResultColor(percentage).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getResultEmoji(percentage),
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            Text(
              _getResultMessage(percentage),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            
            Text(
              '$_score/${widget.questions.length} përgjigje të sakta',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Score circle
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getResultColor(percentage),
                  width: 8,
                ),
              ),
              child: Center(
                child: Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: _getResultColor(percentage),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Review answers
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: widget.questions.length,
                itemBuilder: (context, index) {
                  final question = widget.questions[index];
                  final userAnswer = _userAnswers[index];
                  final isCorrect = userAnswer == question.correctIndex;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: userAnswer == null
                            ? Colors.grey
                            : (isCorrect ? Colors.green : Colors.red),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: userAnswer == null
                                ? Colors.grey.withOpacity(0.2)
                                : (isCorrect
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.red.withOpacity(0.2)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Icon(
                              userAnswer == null
                                  ? Icons.timer_off
                                  : (isCorrect ? Icons.check : Icons.close),
                              size: 16,
                              color: userAnswer == null
                                  ? Colors.grey
                                  : (isCorrect ? Colors.green : Colors.red),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'P${index + 1}: ${question.question}',
                            style: theme.textTheme.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Mbyll',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _currentIndex = 0;
                          _score = 0;
                          _selectedAnswer = null;
                          _answered = false;
                          _showExplanation = false;
                          _userAnswers = List.filled(widget.questions.length, null);
                        });
                        _startTimer();
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
                        'Provo Përsëri',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
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

  Color _getResultColor(int percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    if (percentage >= 40) return Colors.amber;
    return Colors.red;
  }

  String _getResultEmoji(int percentage) {
    if (percentage >= 90) return '🏆';
    if (percentage >= 80) return '🎉';
    if (percentage >= 60) return '👍';
    if (percentage >= 40) return '📚';
    return '💪';
  }

  String _getResultMessage(int percentage) {
    if (percentage >= 90) return 'Shkëlqyeshëm!';
    if (percentage >= 80) return 'Shumë Mirë!';
    if (percentage >= 60) return 'Mirë!';
    if (percentage >= 40) return 'Jo Keq!';
    return 'Provo Përsëri!';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final question = widget.questions[_currentIndex];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _showExitDialog(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Pyetja ${_currentIndex + 1}/${widget.questions.length}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Timer
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _timeLeft <= 10
                          ? Colors.red.withOpacity(0.15)
                          : (isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.04)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer,
                          size: 16,
                          color: _timeLeft <= 10 ? Colors.red : theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_timeLeft}s',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _timeLeft <= 10 ? Colors.red : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / widget.questions.length,
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.06),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? Colors.white : Colors.black,
                  ),
                  minHeight: 6,
                ),
              ),
            ),

            // Question
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subject badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        question.subject,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Question text
                    Text(
                      question.question,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Options
                    ...List.generate(question.options.length, (index) {
                      final isSelected = _selectedAnswer == index;
                      final isCorrect = index == question.correctIndex;
                      final showCorrect = _answered && isCorrect;
                      final showWrong = _answered && isSelected && !isCorrect;

                      Color bgColor;
                      Color borderColor;
                      Color textColor = theme.colorScheme.onSurface;

                      if (showCorrect) {
                        bgColor = Colors.green.withOpacity(0.15);
                        borderColor = Colors.green;
                        textColor = Colors.green;
                      } else if (showWrong) {
                        bgColor = Colors.red.withOpacity(0.15);
                        borderColor = Colors.red;
                        textColor = Colors.red;
                      } else if (isSelected) {
                        bgColor = isDark ? Colors.white : Colors.black;
                        borderColor = Colors.transparent;
                        textColor = isDark ? Colors.black : Colors.white;
                      } else {
                        bgColor = isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.04);
                        borderColor = isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.08);
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () => _selectAnswer(index),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderColor, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (showWrong
                                            ? Colors.red
                                            : (showCorrect
                                                ? Colors.green
                                                : (isDark ? Colors.black : Colors.white)))
                                        : (showCorrect
                                            ? Colors.green
                                            : Colors.transparent),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected || showCorrect
                                          ? Colors.transparent
                                          : (isDark
                                              ? Colors.white.withOpacity(0.2)
                                              : Colors.black.withOpacity(0.1)),
                                    ),
                                  ),
                                  child: Center(
                                    child: showCorrect || showWrong
                                        ? Icon(
                                            showCorrect ? Icons.check : Icons.close,
                                            size: 18,
                                            color: Colors.white,
                                          )
                                        : Text(
                                            String.fromCharCode(65 + index),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: isSelected
                                                  ? (isDark ? Colors.white : Colors.black)
                                                  : textColor,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    question.options[index],
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    // Explanation
                    if (_showExplanation && question.explanation != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.blue.withOpacity(0.15)
                              : Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  size: 18,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Shpjegim',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              question.explanation!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom button
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: _answered
                    ? ElevatedButton(
                        onPressed: _nextQuestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.white : Colors.black,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _currentIndex < widget.questions.length - 1
                              ? 'Pyetja Tjetër'
                              : 'Shiko Rezultatin',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _selectedAnswer != null ? _confirmAnswer : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedAnswer != null
                              ? Colors.green
                              : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.06),
                          disabledForegroundColor: isDark
                              ? Colors.white.withOpacity(0.3)
                              : Colors.black.withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 20,
                              color: _selectedAnswer != null
                                  ? Colors.white
                                  : (isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3)),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Konfirmo Përgjigjen',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Dil nga Kuizi?'),
        content: const Text('Progresi yt do të humbasë nëse del tani.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Vazhdo',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Dil'),
          ),
        ],
      ),
    );
  }
}
