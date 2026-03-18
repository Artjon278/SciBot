// SciBot Dashboard Screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/mastery_service.dart';
import '../../services/gamification_service.dart';
import '../../services/spaced_repetition_service.dart';
import '../../services/weekly_report_service.dart';
import '../../services/quiz_stats_service.dart';
import '../../services/streak_service.dart';
import '../../services/curriculum_service.dart';
import '../../services/exam_prediction_service.dart';
import '../../services/daily_challenge_service.dart';
import '../../data/quiz_data.dart';
import '../quiz/quiz_play_screen.dart';
import '../../core/utils/page_transitions.dart';
import '../../widgets/activity_calendar.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const DashboardScreen({super.key, this.onBack});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ExamPredictionService _examService = ExamPredictionService();
  String? _selectedExamSubject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => widget.onBack?.call(),
                    child: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(width: 12),
                  Text('Paneli', style: theme.textTheme.headlineMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDailyChallengeCard(context, isDark),
                    const SizedBox(height: 16),
                    _buildActivityCalendarCard(context, isDark),
                    const SizedBox(height: 16),
                    _buildReviewCard(context, isDark),
                    const SizedBox(height: 16),
                    _buildWeeklyReportCard(context, isDark),
                    const SizedBox(height: 16),
                    _buildExamPredictionCard(context, isDark),
                    const SizedBox(height: 16),
                    _buildMasteryDetails(context, isDark),
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

  Widget _buildDailyChallengeCard(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Consumer<DailyChallengeService>(
      builder: (context, dcService, _) {
        final challenge = dcService.todayChallenge;
        if (challenge == null) return const SizedBox.shrink();

        final completed = dcService.todayCompleted;
        final result = dcService.todayResult;
        final yesterdayResult = dcService.yesterdayResult;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: completed
                  ? [Colors.green.withOpacity(isDark ? 0.2 : 0.1), Colors.teal.withOpacity(isDark ? 0.1 : 0.05)]
                  : [Colors.purple.withOpacity(isDark ? 0.2 : 0.1), Colors.blue.withOpacity(isDark ? 0.1 : 0.05)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: (completed ? Colors.green : Colors.purple).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sfida e Ditës', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: completed ? Colors.green : Colors.purple)),
                        Row(
                          children: [
                            Text('${challenge.subject} • Streak: ${dcService.challengeStreak}', style: TextStyle(fontSize: 13, color: theme.colorScheme.secondary)),
                            if (yesterdayResult != null) ...[
                              Text(' • Dje: ${yesterdayResult.correct ? "✅" : "❌"}', style: TextStyle(fontSize: 12, color: theme.colorScheme.secondary)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(challenge.question, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, height: 1.4)),
              const SizedBox(height: 14),
              if (completed && result != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: result.correct ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(result.correct ? Icons.check_circle : Icons.cancel, color: result.correct ? Colors.green : Colors.red),
                      const SizedBox(width: 8),
                      Text(result.correct ? 'E saktë! Bravo!' : 'Përgjigja e saktë: ${challenge.options[challenge.correctIndex]}',
                        style: TextStyle(fontWeight: FontWeight.w600, color: result.correct ? Colors.green : Colors.red)),
                    ],
                  ),
                )
              else
                ...List.generate(challenge.options.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          await dcService.submitAnswer(i);
                          if (mounted) {
                            final correct = i == challenge.correctIndex;
                            if (correct) {
                              context.read<GamificationService>().awardXP(XPActivity.challengeComplete);
                            }
                            context.read<StreakService>().recordActivity(activityType: 'daily_challenge');
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1)),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('${String.fromCharCode(65 + i)}. ${challenge.options[i]}', style: theme.textTheme.bodyMedium),
                        ),
                      ),
                    ),
                  );
                }),
              if (completed && challenge.explanation.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(challenge.explanation, style: TextStyle(fontSize: 12, color: theme.colorScheme.secondary, fontStyle: FontStyle.italic)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityCalendarCard(BuildContext context, bool isDark) {
    return Consumer<StreakService>(
      builder: (context, streak, _) {
        final data = streak.getLast30DaysActivity();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.subtleFill(isDark),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ActivityCalendar(activityData: data),
        );
      },
    );
  }

  Widget _buildReviewCard(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Consumer<SpacedRepetitionService>(
      builder: (context, sr, _) {
        if (sr.dueCount == 0) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.successColor(isDark).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.successColor(isDark).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Text('✅', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Asgjë për përsëritje!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.successColor(isDark))),
                      Text('Vazhdo me kuize të reja', style: TextStyle(fontSize: 13, color: theme.colorScheme.secondary)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final byCounts = sr.getDueCountBySubject();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.orange.withOpacity(isDark ? 0.2 : 0.1), Colors.deepOrange.withOpacity(isDark ? 0.1 : 0.05)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🧠', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${sr.dueCount} pyetje për përsëritje', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.orange)),
                        Text('Përsërit për të mos harruar', style: TextStyle(fontSize: 13, color: theme.colorScheme.secondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: byCounts.entries.map((e) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.08) : Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Text('${e.key}: ${e.value}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final items = sr.dueItems.take(10).toList();
                    final questions = items.map((i) => QuizQuestion(
                      id: i.id, question: i.question, options: i.options,
                      correctIndex: i.correctIndex, subject: i.subject,
                      difficulty: 'mesatar', explanation: i.explanation,
                    )).toList();
                    if (questions.isNotEmpty) {
                      Navigator.push(context, SlidePageRoute(page: QuizPlayScreen(questions: questions, title: 'Përsëritje')));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Fillo Përsëritjen', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeeklyReportCard(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Consumer<WeeklyReportService>(
      builder: (context, reportService, _) {
        final report = reportService.latestReport;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppTheme.subtleFill(isDark), borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Raporti Javor', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  GestureDetector(
                    onTap: () {
                      reportService.generateReport(
                        mastery: context.read<MasteryService>(),
                        quizStats: context.read<QuizStatsService>(),
                        streak: context.read<StreakService>(),
                        gamification: context.read<GamificationService>(),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(12)),
                      child: Text('Gjenero', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (report == null)
                Text('Shtypni "Gjenero" për raportin e parë', style: TextStyle(fontSize: 13, color: theme.colorScheme.secondary))
              else ...[
                Row(
                  children: [
                    _reportStat('🎯', '${report.quizzesCompleted}', 'Kuize', isDark),
                    _reportStat('✅', '${report.averageAccuracy.round()}%', 'Saktësi', isDark),
                    _reportStat('⭐', '${report.xpEarned}', 'XP', isDark),
                    _reportStat('🔥', '${report.streakDays}', 'Streak', isDark),
                  ],
                ),
                if (report.improvements.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...report.improvements.map((imp) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          imp.contains('ra ') || imp.contains('rrit') ? Icons.trending_up : Icons.trending_down,
                          size: 14,
                          color: imp.contains('ra ') ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(imp, style: TextStyle(fontSize: 12, color: theme.colorScheme.secondary))),
                      ],
                    ),
                  )),
                ],
                if (report.objectives.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Objektiva për javën:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  ...report.objectives.map((o) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.flag_outlined, size: 14, color: AppTheme.accentColor(isDark)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(o, style: TextStyle(fontSize: 12, color: theme.colorScheme.secondary))),
                      ],
                    ),
                  )),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _reportStat(String icon, String value, String label, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black)),
          Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45)),
        ],
      ),
    );
  }

  Widget _buildExamPredictionCard(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final curriculum = context.watch<CurriculumService>();
    final subjects = ['Matematikë', 'Fizikë', 'Kimi', 'Biologji'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: AppTheme.secondaryGradient(isDark)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Parashikim Mature', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            curriculum.hasGrade ? 'Bazuar në programin e Klasës ${curriculum.grade}' : 'Zgjidh klasën në profil',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: subjects.map((s) {
              final isSelected = _selectedExamSubject == s;
              return GestureDetector(
                onTap: () async {
                  setState(() => _selectedExamSubject = s);
                  await _examService.generatePrediction(
                    subject: s,
                    grade: curriculum.grade,
                    mastery: context.read<MasteryService>(),
                  );
                  if (mounted) setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(s, style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.black : Colors.white,
                  )),
                ),
              );
            }).toList(),
          ),
          if (_examService.lastPrediction != null && _selectedExamSubject != null) ...[
            const SizedBox(height: 16),
            ...(_examService.lastPrediction!.topics.take(5).map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: t.mastered ? Colors.greenAccent : (t.probability >= 70 ? Colors.redAccent : Colors.amberAccent),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(t.topic, style: const TextStyle(color: Colors.white, fontSize: 13))),
                  Text('${t.probability.round()}%', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ))),
            const SizedBox(height: 10),
            Text(_examService.lastPrediction!.advice, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  Widget _buildMasteryDetails(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Consumer<MasteryService>(
      builder: (context, mastery, _) {
        final weak = mastery.getWeakestTopics(limit: 5);
        final strong = mastery.getStrongestTopics(limit: 5);

        if (weak.isEmpty && strong.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppTheme.subtleFill(isDark), borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                const Text('📊', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 10),
                Text('Fillo të mësosh për të parë progresin', style: TextStyle(fontSize: 14, color: theme.colorScheme.secondary)),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (weak.isNotEmpty) ...[
              Text('Fokus i nevojshëm', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              ...weak.map((t) => _topicTile(t, isDark, Colors.red)),
              const SizedBox(height: 16),
            ],
            if (strong.isNotEmpty) ...[
              Text('Pikat e forta', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              ...strong.map((t) => _topicTile(t, isDark, Colors.green)),
            ],
          ],
        );
      },
    );
  }

  Widget _topicTile(TopicScore t, bool isDark, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.subtleFill(isDark), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text('${(t.mastery * 100).round()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.topic, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
                Text('${t.subject} • ${t.total} tentativa', style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
