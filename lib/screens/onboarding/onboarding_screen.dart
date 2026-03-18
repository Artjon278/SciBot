// SciBot Onboarding Screen
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'onboarding_quiz_screen.dart';

/// Ekrani i onboarding-ut që shfaqet vetëm hera e parë
class OnboardingScreen extends StatefulWidget {
  final Future<void> Function() onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      title: 'Përshëndetje! Unë jam SciBot 🤖',
      description:
          'Jam asistenti yt personal i shkencës! Do të ndihmoj me detyrat, konceptet, dhe eksperimentet.',
      icon: Icons.waving_hand_rounded,
      color: AppTheme.accentBlue,
    ),
    _OnboardingPage(
      title: 'Pyet çdo gjë! 💬',
      description:
          'Matematikë, Fizikë, Kimi, Biologji - shkruaj pyetjen tënde dhe unë do të përgjigjem hap pas hapi.',
      icon: Icons.chat_bubble_rounded,
      color: AppTheme.success,
    ),
    _OnboardingPage(
      title: 'Laboratori Virtual 🧪',
      description:
          'Bëj eksperimente virtuale pa rrezik! Mëso duke provuar vetë.',
      icon: Icons.science_rounded,
      color: AppTheme.warning,
    ),
    _OnboardingPage(
      title: 'Kuize & Sfida 🎯',
      description:
          'Testo njohuritë e tua me kuize interaktive. Fito pikë dhe sfido veten!',
      icon: Icons.quiz_rounded,
      color: AppTheme.info,
    ),
    _OnboardingPage(
      title: 'Unë jam gjithmonë këtu! 🌟',
      description:
          'Mund të më shohësh në çdo ekran. Prek mbi mua për këshilla! Mund edhe të më fshehësh nëse dëshiron.',
      icon: Icons.touch_app_rounded,
      color: const Color(0xFF26A69A),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _skip() {
    _finish();
  }

  Future<void> _finish() async {
    await widget.onComplete();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const OnboardingQuizScreen(navigateToHome: true),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: _skip,
                    child: Text(
                      'Kalo',
                      style: TextStyle(
                        color: theme.colorScheme.secondary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),

              // Pages
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index], theme, isDark);
                  },
                ),
              ),

              // Dots indicator
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? _pages[_currentPage].color
                            : (isDark
                                ? Colors.white.withOpacity(0.2)
                                : Colors.black.withOpacity(0.15)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),

              // Next/Start button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pages[_currentPage].color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1
                          ? 'Fillo me SciBot! 🚀'
                          : 'Vazhdo',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page, ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon badge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 40,
              color: page.color,
            ),
          ),
          const SizedBox(height: 28),

          // Title
          Text(
            page.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 24,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            page.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.secondary,
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
