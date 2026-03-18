import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/profile_quiz_data.dart';
import '../../services/student_profile_service.dart';
import '../home/home_screen.dart';

/// Quiz i profilit kognitiv - shfaqet pas onboarding-ut ose nga Settings
class OnboardingQuizScreen extends StatefulWidget {
  /// Nëse true, navigo në HomeScreen pas përfundimit
  final bool navigateToHome;

  const OnboardingQuizScreen({super.key, this.navigateToHome = true});

  @override
  State<OnboardingQuizScreen> createState() => _OnboardingQuizScreenState();
}

class _OnboardingQuizScreenState extends State<OnboardingQuizScreen>
    with SingleTickerProviderStateMixin {
  int _currentQuestion = 0;
  final Map<String, dynamic> _answers = {};
  // Për pyetjen e lëndëve (multi-select)
  final Set<String> _selectedSubjects = {};

  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _selectOption(ProfileQuizOption option) {
    final question = profileQuizQuestions[_currentQuestion];

    if (question.category == 'subjects') {
      // Multi-select për lëndët
      setState(() {
        if (_selectedSubjects.contains(option.value)) {
          _selectedSubjects.remove(option.value);
        } else {
          _selectedSubjects.add(option.value);
        }
      });
      return;
    }

    // Ruaj përgjigjen
    if (question.category == 'learningStyle') {
      // Mblidh votat për stilin e të mësuarit
      final votes = _answers['learningStyleVotes'] ?? <String, int>{};
      votes[option.value] = (votes[option.value] ?? 0) + 1;
      _answers['learningStyleVotes'] = votes;
    } else {
      _answers[question.category] = option.value;
    }

    _goToNext();
  }

  void _confirmSubjects() {
    if (_selectedSubjects.isEmpty) return;
    _answers['subjects'] = _selectedSubjects.toList();
    _goToNext();
  }

  void _goToNext() {
    if (_currentQuestion < profileQuizQuestions.length - 1) {
      setState(() => _currentQuestion++);
      _animController.reset();
      _animController.forward();
    } else {
      _finishQuiz();
    }
  }

  void _goBack() {
    if (_currentQuestion > 0) {
      setState(() => _currentQuestion--);
      _animController.reset();
      _animController.forward();
    }
  }

  Future<void> _finishQuiz() async {
    // Determino stilin dominues të mësuarit
    final rawVotes = _answers['learningStyleVotes'];
    final votes = rawVotes is Map ? Map<String, int>.from(rawVotes) : <String, int>{};
    String learningStyle = 'vizual';
    int maxVotes = 0;
    votes.forEach((style, count) {
      if (count > maxVotes) {
        maxVotes = count;
        learningStyle = style;
      }
    });

    final profileService = context.read<StudentProfileService>();
    final error = await profileService.saveProfile(
      learningStyle: learningStyle,
      preferredSubjects: List<String>.from(_answers['subjects'] ?? ['Matematikë']),
      currentLevel: _answers['level'] ?? 'mesatar',
      goal: _answers['goal'] ?? 'nota',
      dailyStudyMinutes: int.tryParse(_answers['time'] ?? '30') ?? 30,
    );

    if (!mounted) return;

    if (error == null) {
      _showResultDialog(learningStyle);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gabim: $error'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showResultDialog(String learningStyle) {
    final styleInfo = _learningStyleInfo[learningStyle]!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(styleInfo['emoji']!, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  'Profili yt është gati!',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Stili yt: ${styleInfo['title']}',
                    style: TextStyle(
                      color: AppTheme.accentBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  styleInfo['description']!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      if (widget.navigateToHome) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false,
                        );
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      widget.navigateToHome ? 'Fillo me SciBot! 🚀' : 'U ruajt! ✓',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static const Map<String, Map<String, String>> _learningStyleInfo = {
    'vizual': {
      'emoji': '🎨',
      'title': 'Vizual',
      'description':
          'Ti mëson më mirë me figura, diagrama dhe video. SciBot do të përdorë shpjegime vizuale sa herë që mundësohet!',
    },
    'logjik': {
      'emoji': '🧠',
      'title': 'Logjik',
      'description':
          'Ti mëson duke analizuar dhe kuptuar logjikën prapa koncepteve. SciBot do të foksusohet tek hapat dhe arsyetimi!',
    },
    'praktik': {
      'emoji': '🔬',
      'title': 'Praktik',
      'description':
          'Ti mëson duke bërë! SciBot do të sugjerojë eksperimente dhe ushtrime praktike për ty.',
    },
    'lexues': {
      'emoji': '📖',
      'title': 'Lexues',
      'description':
          'Ti mëson duke lexuar dhe shënuar. SciBot do të japë shpjegime të detajuara me tekst të organizuar.',
    },
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final question = profileQuizQuestions[_currentQuestion];
    final progress = (_currentQuestion + 1) / profileQuizQuestions.length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header me progress
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (_currentQuestion > 0)
                        GestureDetector(
                          onTap: _goBack,
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
                        )
                      else
                        const SizedBox(width: 36),
                      Expanded(
                        child: Text(
                          'Profili Kognitiv',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${_currentQuestion + 1}/${profileQuizQuestions.length}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.06),
                      valueColor: const AlwaysStoppedAnimation(AppTheme.accentBlue),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),

            // Pyetja
            Expanded(
              child: FadeTransition(
                opacity: _fadeIn,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                  child: Column(
                    children: [
                      Text(
                        question.question,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (question.category == 'subjects')
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Mund të zgjedhësh më shumë se një',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ),
                      const SizedBox(height: 32),

                      // Opsionet
                      ...question.options.map((option) {
                        final isSelected = question.category == 'subjects'
                            ? _selectedSubjects.contains(option.value)
                            : false;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildOptionCard(
                            option: option,
                            isSelected: isSelected,
                            isDark: isDark,
                            theme: theme,
                            onTap: () => _selectOption(option),
                          ),
                        );
                      }),

                      // Butoni "Vazhdo" për multi-select (lëndët)
                      if (question.category == 'subjects') ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed:
                                _selectedSubjects.isNotEmpty ? _confirmSubjects : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentBlue,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.black.withOpacity(0.06),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              _selectedSubjects.isEmpty
                                  ? 'Zgjidh të paktën një lëndë'
                                  : 'Vazhdo (${_selectedSubjects.length} lëndë)',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildOptionCard({
    required ProfileQuizOption option,
    required bool isSelected,
    required bool isDark,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentBlue.withOpacity(0.12)
              : (isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.03)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.accentBlue.withOpacity(0.5)
                : (isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.08)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(option.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                option.text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppTheme.accentBlue : null,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: AppTheme.accentBlue,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
