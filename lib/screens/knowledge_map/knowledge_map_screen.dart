import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/quiz_stats_service.dart';
import '../quiz/quiz_screen.dart';
import '../../core/utils/page_transitions.dart';

// ─── Data helpers ────────────────────────────────────────────────────────────

enum MasteryLevel { notStarted, weak, intermediate, mastered }

class SubjectMastery {
  final String subject;
  final String icon;
  final Color baseColor;
  final int totalAttempts;
  final int totalCorrect;
  final int totalQuestions;
  /// Ordered list of (timestamp, accuracy%) for the last 20 quiz sessions
  final List<({DateTime date, double accuracy})> history;

  const SubjectMastery({
    required this.subject,
    required this.icon,
    required this.baseColor,
    required this.totalAttempts,
    required this.totalCorrect,
    required this.totalQuestions,
    required this.history,
  });

  double get masteryPercent =>
      totalQuestions > 0 ? totalCorrect / totalQuestions * 100 : 0;

  MasteryLevel get level {
    if (totalAttempts == 0) return MasteryLevel.notStarted;
    if (masteryPercent >= 80) return MasteryLevel.mastered;
    if (masteryPercent >= 50) return MasteryLevel.intermediate;
    return MasteryLevel.weak;
  }

  Color get levelColor {
    switch (level) {
      case MasteryLevel.mastered:
        return const Color(0xFF34A853);
      case MasteryLevel.intermediate:
        return const Color(0xFFE8A33D);
      case MasteryLevel.weak:
        return const Color(0xFFD93025);
      case MasteryLevel.notStarted:
        return const Color(0xFF9E9E9E);
    }
  }

  String get levelLabel {
    switch (level) {
      case MasteryLevel.mastered:
        return 'Zotëron';
      case MasteryLevel.intermediate:
        return 'Mesatarisht';
      case MasteryLevel.weak:
        return 'Dobët';
      case MasteryLevel.notStarted:
        return 'Nuk ka filluar';
    }
  }
}

List<SubjectMastery> computeMastery(List<QuizResult> results) {
  const subjectDefs = [
    {'name': 'Matematikë', 'icon': '📐', 'color': 0xFF4CAF50},
    {'name': 'Kimi', 'icon': '⚗️', 'color': 0xFF2196F3},
    {'name': 'Biologji', 'icon': '🧬', 'color': 0xFF9C27B0},
    {'name': 'Fizikë', 'icon': '⚛️', 'color': 0xFFFF9800},
  ];

  return subjectDefs.map((def) {
    final name = def['name'] as String;
    final subjectResults = results
        .where((r) =>
            r.subject != null &&
            r.subject!.toLowerCase().contains(name.toLowerCase().split(' ')[0]))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final history = subjectResults
        .map((r) => (date: r.timestamp, accuracy: r.accuracy))
        .toList();

    return SubjectMastery(
      subject: name,
      icon: def['icon'] as String,
      baseColor: Color(def['color'] as int),
      totalAttempts: subjectResults.length,
      totalCorrect: subjectResults.fold(0, (s, r) => s + r.correctAnswers),
      totalQuestions: subjectResults.fold(0, (s, r) => s + r.totalQuestions),
      history: history.length > 20 ? history.sublist(history.length - 20) : history,
    );
  }).toList();
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class KnowledgeMapScreen extends StatelessWidget {
  final VoidCallback? onBack;
  const KnowledgeMapScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Consumer<QuizStatsService>(
          builder: (context, stats, _) {
            final masteries = computeMastery(stats.results);
            final overallPercent = masteries.isEmpty
                ? 0.0
                : masteries.fold<double>(0, (s, m) => s + m.masteryPercent) /
                    masteries.length;

            return CustomScrollView(
              slivers: [
                // ── App bar ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        if (onBack != null)
                          GestureDetector(
                            onTap: onBack,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.subtleFill(isDark),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.arrow_back_ios_new_rounded,
                                  size: 18,
                                  color: theme.colorScheme.onSurface),
                            ),
                          ),
                        if (onBack != null) const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Harta e Njohurive',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Progresi yt sipas lëndës',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Overall progress banner ──
                SliverToBoxAdapter(
                  child: _OverallBanner(
                    percent: overallPercent,
                    isDark: isDark,
                    theme: theme,
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // ── Section title ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Lëndët',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // ── Subject grid ──
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _SubjectCard(
                        mastery: masteries[i],
                        isDark: isDark,
                        onTap: () => _showSubjectDetail(
                            context, masteries[i], isDark),
                      ),
                      childCount: masteries.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.95,
                    ),
                  ),
                ),

                // ── Legend ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                    child: _Legend(isDark: isDark),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showSubjectDetail(
      BuildContext context, SubjectMastery mastery, bool isDark) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubjectDetailSheet(
        mastery: mastery,
        isDark: isDark,
        theme: theme,
      ),
    );
  }
}

// ─── Overall banner ──────────────────────────────────────────────────────────

class _OverallBanner extends StatelessWidget {
  final double percent;
  final bool isDark;
  final ThemeData theme;

  const _OverallBanner(
      {required this.percent, required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A3A5C), const Color(0xFF2A1A4E)]
              : [const Color(0xFF4A90D9), const Color(0xFF7E57C2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Circular progress
          SizedBox(
            width: 80,
            height: 80,
            child: CustomPaint(
              painter: _CircularProgressPainter(
                percent: percent / 100,
                trackColor: Colors.white.withValues(alpha: 0.2),
                progressColor: Colors.white,
              ),
              child: Center(
                child: Text(
                  '${percent.round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Zotërim i Përgjithshëm',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _getOverallMessage(percent),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getOverallMessage(double p) {
    if (p == 0) return 'Fillo quiz-et për të parë progresin tënd!';
    if (p >= 80) return 'Shkëlqyeshëm! Vazhdо kështu!';
    if (p >= 60) return 'Mirë! Pak më shumë punë dhe do të zotërosh!';
    if (p >= 40) return 'Mos u ndal, je në rrugën e duhur!';
    return 'Fillo të praktikosh çdo ditë!';
  }
}

// ─── Subject card ─────────────────────────────────────────────────────────────

class _SubjectCard extends StatelessWidget {
  final SubjectMastery mastery;
  final bool isDark;
  final VoidCallback onTap;

  const _SubjectCard(
      {required this.mastery, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = mastery.levelColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + level dot
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(mastery.icon, style: const TextStyle(fontSize: 32)),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Subject name
            Text(
              mastery.subject,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),

            // Level label
            Text(
              mastery.levelLabel,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),

            const Spacer(),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: mastery.masteryPercent / 100,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),

            // Percent + attempts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${mastery.masteryPercent.round()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  mastery.totalAttempts == 0
                      ? 'Pa quiz'
                      : '${mastery.totalAttempts} quiz',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Legend ──────────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  final bool isDark;
  const _Legend({required this.isDark});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Color(0xFF34A853), 'Zotëron (≥80%)'),
      (Color(0xFFE8A33D), 'Mesatarisht (≥50%)'),
      (Color(0xFFD93025), 'Dobët (<50%)'),
      (Color(0xFF9E9E9E), 'Nuk ka filluar'),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: items
          .map((item) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: item.$1,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.$2,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ))
          .toList(),
    );
  }
}

// ─── Subject detail bottom sheet ─────────────────────────────────────────────

class _SubjectDetailSheet extends StatelessWidget {
  final SubjectMastery mastery;
  final bool isDark;
  final ThemeData theme;

  const _SubjectDetailSheet(
      {required this.mastery, required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    final color = mastery.levelColor;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(mastery.icon, style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mastery.subject,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          mastery.levelLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Big percent
                Text(
                  '${mastery.masteryPercent.round()}%',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _StatChip(
                  label: 'Quiz',
                  value: mastery.totalAttempts.toString(),
                  isDark: isDark,
                  theme: theme,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  label: 'Saktë',
                  value: mastery.totalCorrect.toString(),
                  isDark: isDark,
                  theme: theme,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  label: 'Pyetje',
                  value: mastery.totalQuestions.toString(),
                  isDark: isDark,
                  theme: theme,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Chart title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                mastery.history.isEmpty
                    ? 'Nuk ka të dhëna ende'
                    : 'Historiku i Progresit',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Progress chart
          if (mastery.history.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                height: 120,
                child: _ProgressChart(
                  history: mastery.history,
                  color: color,
                  isDark: isDark,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.subtleFill(isDark),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Bëj quiz-in e parë për të parë progresin!',
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),

          const Spacer(),

          // Start quiz button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    SlidePageRoute(
                      page: QuizScreen(
                        onBack: () => Navigator.pop(context),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.quiz_outlined),
                label: Text('Fillo Quiz — ${mastery.subject}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final ThemeData theme;

  const _StatChip({
    required this.label,
    required this.value,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.subtleFill(isDark),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Progress chart ──────────────────────────────────────────────────────────

class _ProgressChart extends StatelessWidget {
  final List<({DateTime date, double accuracy})> history;
  final Color color;
  final bool isDark;

  const _ProgressChart({
    required this.history,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LineChartPainter(
        data: history.map((h) => h.accuracy).toList(),
        color: color,
        isDark: isDark,
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final bool isDark;

  _LineChartPainter(
      {required this.data, required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final gridColor =
        (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);
    final labelColor =
        (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4);

    // Draw horizontal grid lines at 0, 50, 100
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    final labelStyle = TextStyle(
      color: labelColor,
      fontSize: 10,
    );

    for (final pct in [0, 50, 100]) {
      final y = size.height - (pct / 100) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      // Label
      final tp = TextPainter(
        text: TextSpan(text: '$pct%', style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - 12));
    }

    if (data.length == 1) {
      // Single dot
      final x = size.width / 2;
      final y = size.height - (data[0] / 100) * size.height;
      canvas.drawCircle(Offset(x, y), 5, Paint()..color = color);
      return;
    }

    final step = size.width / (data.length - 1);

    // Fill area under line
    final fillPath = Path();
    fillPath.moveTo(0, size.height);
    for (int i = 0; i < data.length; i++) {
      final x = i * step;
      final y = size.height - (data[i].clamp(0, 100) / 100) * size.height;
      fillPath.lineTo(x, y);
    }
    fillPath.lineTo((data.length - 1) * step, size.height);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill,
    );

    // Draw line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final linePath = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i * step;
      final y = size.height - (data[i].clamp(0, 100) / 100) * size.height;
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }
    canvas.drawPath(linePath, linePaint);

    // Draw dots
    final dotPaint = Paint()..color = color;
    final dotBg = Paint()
      ..color = isDark ? const Color(0xFF1A1A1A) : Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final x = i * step;
      final y = size.height - (data[i].clamp(0, 100) / 100) * size.height;
      canvas.drawCircle(Offset(x, y), 4, dotBg);
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.data != data || old.color != color;
}

// ─── Circular progress painter ───────────────────────────────────────────────

class _CircularProgressPainter extends CustomPainter {
  final double percent;
  final Color trackColor;
  final Color progressColor;

  _CircularProgressPainter({
    required this.percent,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    const strokeWidth = 7.0;
    const startAngle = -math.pi / 2;

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = trackColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Progress
    if (percent > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        2 * math.pi * percent,
        false,
        Paint()
          ..color = progressColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_CircularProgressPainter old) =>
      old.percent != percent;
}
