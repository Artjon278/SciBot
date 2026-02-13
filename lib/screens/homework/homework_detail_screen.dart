import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/homework_service.dart';
import '../../core/utils/page_transitions.dart';
import 'exercise_solve_screen.dart';

class HomeworkDetailScreen extends StatefulWidget {
  final HomeworkItem homework;

  const HomeworkDetailScreen({super.key, required this.homework});

  @override
  State<HomeworkDetailScreen> createState() => _HomeworkDetailScreenState();
}

class _HomeworkDetailScreenState extends State<HomeworkDetailScreen> {
  late HomeworkItem _hw;

  static const Map<String, String> _subjectEmojis = {
    'Matematikë': '📐',
    'Fizikë': '⚡',
    'Kimi': '⚗️',
    'Biologji': '🧬',
    'Informatikë': '💻',
    'Tjetër': '📚',
  };

  @override
  void initState() {
    super.initState();
    _hw = widget.homework;
  }

  void _refreshFromService() {
    final hwService = context.read<HomeworkService>();
    final updated = hwService.items.where((h) => h.id == _hw.id).firstOrNull;
    if (updated != null) {
      setState(() => _hw = updated);
    }
  }

  Future<void> _solveAll() async {
    final hwService = context.read<HomeworkService>();
    final unsolved = _hw.exercises.where((e) => !e.isSolved).toList();
    if (unsolved.isEmpty) return;

    for (final ex in unsolved) {
      await hwService.solveExercise(_hw.id, ex.id);
      _refreshFromService();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final emoji = _subjectEmojis[_hw.subject] ?? '📚';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _hw.title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Consumer<HomeworkService>(
                builder: (context, hwService, _) {
                  // Refresh local state from service
                  final liveHw = hwService.items.where((h) => h.id == _hw.id).firstOrNull;
                  if (liveHw != null && liveHw != _hw) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _hw = liveHw);
                    });
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Info card ──
                        _buildInfoCard(context, emoji, isDark),

                        const SizedBox(height: 20),

                        // ── Progress ──
                        _buildProgressSection(context, isDark),

                        const SizedBox(height: 24),

                        // ── Section title ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ushtrimet',
                              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            if (_hw.exercises.any((e) => !e.isSolved))
                              GestureDetector(
                                onTap: _solveAll,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(isDark ? 0.2 : 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.auto_awesome, size: 14, color: Colors.blue),
                                      SizedBox(width: 4),
                                      Text('Zgjidh të gjitha',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue)),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ── Exercise cards ──
                        ...List.generate(_hw.exercises.length, (i) {
                          final ex = _hw.exercises[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildExerciseCard(context, ex, i, isDark),
                          );
                        }),

                        const SizedBox(height: 40),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  Info Card
  // ═══════════════════════════════════════════════════
  Widget _buildInfoCard(BuildContext context, String emoji, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.indigo.shade900, Colors.blue.shade900]
              : [Colors.indigo.shade400, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hw.subject,
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    _hw.title,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            _infoBadge(Icons.assignment, '${_hw.totalCount} ushtrime'),
            const SizedBox(width: 10),
            _infoBadge(Icons.check_circle, '${_hw.solvedCount} zgjidhur'),
            const SizedBox(width: 10),
            _infoBadge(Icons.calendar_today, '${_hw.createdAt.day}/${_hw.createdAt.month}/${_hw.createdAt.year}'),
          ]),
        ],
      ),
    );
  }

  Widget _infoBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: Colors.white70),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════
  //  Progress
  // ═══════════════════════════════════════════════════
  Widget _buildProgressSection(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final progress = _hw.progress;
    final percent = (progress * 100).toInt();

    Color barColor;
    if (_hw.isFullySolved) {
      barColor = Colors.green;
    } else if (_hw.solvedCount > 0) {
      barColor = Colors.orange;
    } else {
      barColor = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progresi', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              Text('$percent%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: barColor)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.06),
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _hw.isFullySolved
                ? 'Të gjitha ushtrimet janë zgjidhur!'
                : '${_hw.solvedCount} nga ${_hw.totalCount} ushtrime zgjidhur',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  Exercise Card
  // ═══════════════════════════════════════════════════
  Widget _buildExerciseCard(BuildContext context, Exercise ex, int index, bool isDark) {
    final theme = Theme.of(context);

    Color numColor;
    IconData trailingIcon;
    String trailingText;

    if (ex.isSolved) {
      numColor = Colors.green;
      trailingIcon = Icons.check_circle;
      trailingText = 'Zgjidhur';
    } else {
      numColor = Colors.blue;
      trailingIcon = Icons.auto_awesome;
      trailingText = 'Zgjidh';
    }

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          SlidePageRoute(
            page: ExerciseSolveScreen(
              homeworkId: _hw.id,
              exercise: ex,
            ),
          ),
        );
        _refreshFromService();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ex.isSolved
                ? Colors.green.withOpacity(0.3)
                : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
          ),
        ),
        child: Row(
          children: [
            // Number badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: numColor.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  ex.number,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: numColor),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ex.title,
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ex.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Action
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: numColor.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(trailingIcon, size: 14, color: numColor),
                const SizedBox(width: 4),
                Text(trailingText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: numColor)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
