import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/streak_service.dart';
import '../../services/gamification_service.dart';
import '../../services/mastery_service.dart';
import '../../services/curriculum_service.dart';
import '../../services/adaptive_ai_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _usernameController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    _usernameController.text = auth.username;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _saveUsername() async {
    final newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await context.read<AuthService>().updateUsername(newUsername);
      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('Emri u përditësua me sukses!'),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(
                  bottom: BorderSide(color: AppTheme.subtleBorder(isDark)),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.subtleFill(isDark),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.arrow_back, size: 20, color: theme.colorScheme.onSurface),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text('Profili Im', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildUserHeader(context, isDark),
                    const SizedBox(height: 24),
                    _buildXPCard(context, isDark),
                    const SizedBox(height: 16),
                    _buildGradeSelector(context, isDark),
                    const SizedBox(height: 16),
                    _buildLearningStyleSelector(context, isDark),
                    const SizedBox(height: 16),
                    _buildAIPersonalitySelector(context, isDark),
                    const SizedBox(height: 16),
                    _buildMasteryOverview(context, isDark),
                    const SizedBox(height: 16),
                    _buildBadgesSection(context, isDark),
                    const SizedBox(height: 16),
                    _buildStreakSection(context, isDark),
                    const SizedBox(height: 16),
                    _buildUsernameField(context, isDark),
                    const SizedBox(height: 16),
                    _buildEmailField(context, isDark),
                    const SizedBox(height: 16),
                    _buildAppInfo(context, isDark),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Consumer2<AuthService, GamificationService>(
      builder: (context, auth, gamification, _) {
        return Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.subtleFill(isDark),
                border: Border.all(color: AppTheme.accentColor(isDark), width: 3),
              ),
              child: auth.photoUrl != null
                  ? ClipOval(child: Image.network(auth.photoUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildInitial(auth, theme)))
                  : _buildInitial(auth, theme),
            ),
            const SizedBox(height: 12),
            Text(auth.username, style: theme.textTheme.headlineMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentColor(isDark).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${gamification.levelTitle} • Nivel ${gamification.level}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.accentColor(isDark)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildXPCard(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Consumer<GamificationService>(
      builder: (context, gam, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: AppTheme.primaryGradient(isDark)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Nivel ${gam.level}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  Text('${gam.totalXP} XP', style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: gam.levelProgress,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${gam.xpInCurrentLevel}/${gam.xpNeededForNext} XP deri në Nivel ${gam.level + 1}',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGradeSelector(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Consumer<CurriculumService>(
      builder: (context, curriculum, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.subtleFill(isDark),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.school_outlined, size: 16, color: theme.colorScheme.secondary),
                  const SizedBox(width: 8),
                  Text('Klasa', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary, fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(7, (i) {
                  final grade = i + 6;
                  final isSelected = curriculum.grade == grade;
                  return GestureDetector(
                    onTap: () => curriculum.setGrade(grade),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? Colors.transparent : AppTheme.subtleBorder(isDark)),
                      ),
                      child: Center(
                        child: Text(
                          '$grade',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? (isDark ? Colors.black : Colors.white) : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLearningStyleSelector(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final styles = [
      {'id': 'balanced', 'label': 'I Balancuar', 'icon': '⚖️'},
      {'id': 'visual', 'label': 'Vizual', 'icon': '👁️'},
      {'id': 'practice', 'label': 'Praktikë', 'icon': '✍️'},
      {'id': 'theory', 'label': 'Teori', 'icon': '📖'},
    ];

    return Consumer<CurriculumService>(
      builder: (context, curriculum, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.subtleFill(isDark),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.psychology_outlined, size: 16, color: theme.colorScheme.secondary),
                  const SizedBox(width: 8),
                  Text('Stili i Mësimit', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary, fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: styles.map((s) {
                  final isSelected = curriculum.learningStyle == s['id'];
                  return GestureDetector(
                    onTap: () => curriculum.setLearningStyle(s['id']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? Colors.transparent : AppTheme.subtleBorder(isDark)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(s['icon']!, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(s['label']!, style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? (isDark ? Colors.black : Colors.white) : theme.colorScheme.onSurface,
                          )),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAIPersonalitySelector(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Consumer<AdaptiveAIService>(
      builder: (context, ai, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.subtleFill(isDark),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.smart_toy_outlined, size: 16, color: theme.colorScheme.secondary),
                  const SizedBox(width: 8),
                  Text('Personaliteti i AI', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  if (ai.manualOverride)
                    GestureDetector(
                      onTap: () => ai.disableManualOverride(),
                      child: Text('Auto', style: TextStyle(fontSize: 11, color: AppTheme.accentColor(isDark))),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ...StudentPersonality.values.map((p) {
                final isSelected = ai.personality == p;
                return GestureDetector(
                  onTap: () => ai.setPersonality(p),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.accentColor(isDark).withOpacity(0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppTheme.accentColor(isDark) : AppTheme.subtleBorder(isDark),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                              Text(p.description, style: TextStyle(fontSize: 11, color: theme.colorScheme.secondary)),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle, size: 20, color: AppTheme.accentColor(isDark)),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Toni: ', style: TextStyle(fontSize: 13, color: theme.colorScheme.secondary)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      children: AdaptiveAIService.toneOptions.map((t) {
                        final isSelected = ai.tone == t;
                        return GestureDetector(
                          onTap: () => ai.setTone(t),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isSelected ? Colors.transparent : AppTheme.subtleBorder(isDark)),
                            ),
                            child: Text(t, style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? (isDark ? Colors.black : Colors.white) : theme.colorScheme.onSurface,
                            )),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMasteryOverview(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Consumer<MasteryService>(
      builder: (context, mastery, _) {
        final subjects = ['Matematikë', 'Fizikë', 'Kimi', 'Biologji'];
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.subtleFill(isDark),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.insights, size: 16, color: theme.colorScheme.secondary),
                  const SizedBox(width: 8),
                  Text('Mjeshtëria ime', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary, fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 16),
              ...subjects.map((subject) {
                final sm = mastery.getSubjectMastery(subject);
                final icons = {'Matematikë': '📐', 'Fizikë': '⚡', 'Kimi': '⚗️', 'Biologji': '🧬'};
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Text(icons[subject] ?? '📚', style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(subject, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                                Text('${(sm.overallMastery * 100).round()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _masteryColor(sm.overallMastery))),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: sm.overallMastery,
                                backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.06),
                                valueColor: AlwaysStoppedAnimation<Color>(_masteryColor(sm.overallMastery)),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Color _masteryColor(double mastery) {
    if (mastery >= 0.8) return Colors.green;
    if (mastery >= 0.5) return Colors.orange;
    if (mastery >= 0.3) return Colors.amber;
    return Colors.red.shade300;
  }

  Widget _buildBadgesSection(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Consumer<GamificationService>(
      builder: (context, gam, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.subtleFill(isDark),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.emoji_events_outlined, size: 16, color: theme.colorScheme.secondary),
                  const SizedBox(width: 8),
                  Text('Arritjet (${gam.unlockedBadges.length}/${gam.badges.length})', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary, fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: gam.badges.map((badge) {
                  return Tooltip(
                    message: '${badge.name}: ${badge.description}',
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: badge.unlocked
                            ? AppTheme.accentColor(isDark).withOpacity(0.15)
                            : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: badge.unlocked ? AppTheme.accentColor(isDark).withOpacity(0.3) : AppTheme.subtleBorder(isDark),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          badge.icon,
                          style: TextStyle(fontSize: 22, color: badge.unlocked ? null : Colors.grey.withOpacity(0.3)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStreakSection(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Consumer<StreakService>(
      builder: (context, streak, _) {
        final fireColor = streak.currentStreak >= 7
            ? Colors.deepOrange
            : streak.currentStreak >= 3
                ? Colors.orange
                : Colors.amber;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: streak.currentStreak > 0
                ? LinearGradient(colors: [fireColor.withOpacity(isDark ? 0.15 : 0.1), fireColor.withOpacity(isDark ? 0.05 : 0.02)])
                : null,
            color: streak.currentStreak > 0 ? null : AppTheme.subtleFill(isDark),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: streak.currentStreak > 0 ? fireColor.withOpacity(0.3) : AppTheme.subtleBorder(isDark)),
          ),
          child: Column(
            children: [
              Text(streak.currentStreak > 0 ? '🔥' : '💤', style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 8),
              Text(
                streak.currentStreak > 0 ? '${streak.currentStreak} ditë streak!' : 'Asnjë streak aktiv',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: streak.currentStreak > 0 ? fireColor : null),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildStreakStat(context, label: 'Rekord', value: '${streak.longestStreak}', icon: '🏆', isDark: isDark)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStreakStat(context, label: 'Ditë totale', value: '${streak.totalActiveDays}', icon: '📅', isDark: isDark)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStreakStat(BuildContext context, {required String label, required String value, required String icon, required bool isDark}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary)),
        ],
      ),
    );
  }

  Widget _buildUsernameField(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        return _buildField(
          context, label: 'Emri', icon: Icons.person_outline, isDark: isDark,
          child: _isEditing
              ? Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _usernameController,
                        style: theme.textTheme.bodyLarge,
                        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero, isDense: true),
                        autofocus: true,
                      ),
                    ),
                    if (_isSaving)
                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    else ...[
                      GestureDetector(
                        onTap: _saveUsername,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                          child: Icon(Icons.check, size: 18, color: AppTheme.successColor(isDark)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() { _isEditing = false; _usernameController.text = auth.username; }),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                          child: Icon(Icons.close, size: 18, color: AppTheme.errorColor(isDark)),
                        ),
                      ),
                    ],
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: Text(auth.username, style: theme.textTheme.bodyLarge)),
                    GestureDetector(
                      onTap: () => setState(() => _isEditing = true),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: AppTheme.subtleFill(isDark), borderRadius: BorderRadius.circular(6)),
                        child: Icon(Icons.edit, size: 16, color: theme.colorScheme.secondary),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildEmailField(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        return _buildField(
          context, label: 'Email', icon: Icons.email_outlined, isDark: isDark,
          child: Text(auth.email ?? 'N/A', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.secondary)),
        );
      },
    );
  }

  Widget _buildAppInfo(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.subtleFill(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.subtleBorder(isDark)),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(isDark ? 'assets/images/1.png' : 'assets/images/sci-removebg-preview.png', width: 32, height: 32, fit: BoxFit.cover),
          ),
          const SizedBox(height: 10),
          Text('SciBot v2.0.0', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('AI Science Tutor', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary)),
        ],
      ),
    );
  }

  Widget _buildInitial(AuthService auth, ThemeData theme) {
    return Center(
      child: Text(
        auth.username.isNotEmpty ? auth.username[0].toUpperCase() : '?',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
      ),
    );
  }

  Widget _buildField(BuildContext context, {required String label, required IconData icon, required bool isDark, required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.subtleFill(isDark), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.secondary),
              const SizedBox(width: 8),
              Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
