import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../services/homework_service.dart';

class ExerciseSolveScreen extends StatefulWidget {
  final String homeworkId;
  final Exercise exercise;

  const ExerciseSolveScreen({
    super.key,
    required this.homeworkId,
    required this.exercise,
  });

  @override
  State<ExerciseSolveScreen> createState() => _ExerciseSolveScreenState();
}

class _ExerciseSolveScreenState extends State<ExerciseSolveScreen> {
  bool _isSolving = false;
  String? _solution;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _solution = widget.exercise.solution;
  }

  Future<void> _solve() async {
    setState(() {
      _isSolving = true;
      _errorMsg = null;
    });

    try {
      final hwService = context.read<HomeworkService>();
      final result = await hwService.solveExercise(
        widget.homeworkId,
        widget.exercise.id,
      );

      if (result != null) {
        setState(() {
          _solution = result;
          _isSolving = false;
        });
      } else {
        setState(() {
          _errorMsg = 'Nuk u arrit të zgjidhej. Provoni përsëri.';
          _isSolving = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Gabim: $e';
        _isSolving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ex = widget.exercise;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ushtrim ${ex.number}',
                    style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (ex.isSolved || _solution != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.check_circle, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text('Zgjidhur', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green)),
                    ]),
                  ),
              ]),
            ),

            // ── Content ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Exercise text ──
                    _buildExerciseSection(context, ex, isDark),

                    const SizedBox(height: 24),

                    // ── Solution area ──
                    if (_isSolving) _buildLoadingState(context, isDark),
                    if (_errorMsg != null) _buildErrorState(context, isDark),
                    if (_solution != null && !_isSolving) _buildSolutionSection(context, isDark),
                    if (_solution == null && !_isSolving && _errorMsg == null)
                      _buildSolvePrompt(context, isDark),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  Exercise Text Section
  // ═══════════════════════════════════════════════════
  Widget _buildExerciseSection(BuildContext context, Exercise ex, bool isDark) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.blue.shade900, Colors.indigo.shade900]
              : [Colors.blue.shade50, Colors.indigo.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.blue.withOpacity(0.3) : Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(isDark ? 0.3 : 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '📝 Ushtrim ${ex.number}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.blue.shade200 : Colors.blue.shade700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ex.subject,
                style: TextStyle(fontSize: 11, color: theme.colorScheme.secondary),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Text(
            ex.title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            ex.text,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: theme.colorScheme.onSurface.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  Solve Prompt (before solving)
  // ═══════════════════════════════════════════════════
  Widget _buildSolvePrompt(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.purple.shade800, Colors.blue.shade800]
                    : [Colors.purple.shade300, Colors.blue.shade300],
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('🤖', style: TextStyle(fontSize: 30))),
          ),
          const SizedBox(height: 16),
          Text(
            'Gati për zgjidhje?',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'AI do ta zgjidhë këtë ushtrim hap pas hapi me shpjegime të detajuara',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _solve,
              icon: const Icon(Icons.auto_awesome, size: 20),
              label: const Text(
                'Zgjidh me AI',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  Loading State
  // ═══════════════════════════════════════════════════
  Widget _buildLoadingState(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text('AI po punon...', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            'Po analizon ushtrimet dhe po përgatit zgjidhjen hap pas hapi',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  Error State
  // ═══════════════════════════════════════════════════
  Widget _buildErrorState(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(isDark ? 0.15 : 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 36),
          const SizedBox(height: 12),
          Text(_errorMsg!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade700)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _solve,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Provo përsëri'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  Solution Section
  // ═══════════════════════════════════════════════════
  Widget _buildSolutionSection(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.auto_awesome, size: 14, color: Colors.green),
                SizedBox(width: 4),
                Text('Zgjidhja e AI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green)),
              ]),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _solve,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.refresh, size: 14, color: theme.colorScheme.secondary),
                  const SizedBox(width: 4),
                  Text('Rigjenero', style: TextStyle(fontSize: 11, color: theme.colorScheme.secondary)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          MarkdownBody(
            data: _solution!,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              h1: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              h2: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              h3: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              p: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
              strong: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              em: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
              listBullet: theme.textTheme.bodyMedium,
              blockquoteDecoration: BoxDecoration(
                color: isDark ? Colors.blue.withOpacity(0.1) : Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border(left: BorderSide(color: Colors.blue, width: 3)),
              ),
              blockquotePadding: const EdgeInsets.all(12),
              codeblockDecoration: BoxDecoration(
                color: isDark ? Colors.black54 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              codeblockPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}
