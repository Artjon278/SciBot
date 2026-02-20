import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/audio_lesson.dart';
import '../../services/audiobook_service.dart';
import 'generate_lesson_sheet.dart';
import 'lesson_player_screen.dart';

class AudiobooksScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const AudiobooksScreen({super.key, this.onBack});

  @override
  State<AudiobooksScreen> createState() => _AudiobooksScreenState();
}

class _AudiobooksScreenState extends State<AudiobooksScreen> {
  String _selectedSubject = 'Të gjitha';

  static const _subjects = [
    'Të gjitha',
    'Matematikë',
    'Fizikë',
    'Kimi',
    'Biologji',
  ];

  static const _subjectIcons = {
    'Matematikë': Icons.calculate,
    'Fizikë': Icons.bolt,
    'Kimi': Icons.science,
    'Biologji': Icons.biotech,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Icon(Icons.headphones, color: theme.colorScheme.primary, size: 28),
                const SizedBox(width: 10),
                Text(
                  'Audio Mësime',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // New lesson card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: GestureDetector(
              onTap: () => _showGenerateSheet(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [Colors.deepPurple.shade800, Colors.indigo.shade900]
                        : [Colors.deepPurple.shade400, Colors.indigo.shade500],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mësim i Ri',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Gjenero mësim audio me AI',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.6), size: 18),
                  ],
                ),
              ),
            ),
          ),

          // Subject filter chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _subjects.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final s = _subjects[index];
                final selected = s == _selectedSubject;
                return ChoiceChip(
                  label: Text(s),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedSubject = s),
                  selectedColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : theme.colorScheme.onSurface,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Lesson list
          Expanded(
            child: Consumer<AudiobookService>(
              builder: (context, service, _) {
                final filtered = _selectedSubject == 'Të gjitha'
                    ? service.lessons
                    : service.lessons.where((l) => l.subject == _selectedSubject).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.headphones_outlined,
                            size: 64, color: theme.colorScheme.secondary.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Text(
                          'Asnjë mësim audio',
                          style: TextStyle(color: theme.colorScheme.secondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Krijo mësimin e parë duke shtypur butonin lart',
                          style: TextStyle(
                            color: theme.colorScheme.secondary.withOpacity(0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      _buildLessonTile(context, filtered[index], isDark),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonTile(BuildContext context, AudioLesson lesson, bool isDark) {
    final theme = Theme.of(context);
    final service = context.read<AudiobookService>();
    final isPlaying = service.currentLessonId == lesson.id && service.ttsState == TtsState.playing;
    final icon = _subjectIcons[lesson.subject] ?? Icons.school;
    final minutes = (lesson.durationSeconds / 60).ceil();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LessonPlayerScreen(lesson: lesson)),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tileColor: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: (isPlaying ? Colors.deepPurple : theme.colorScheme.primary).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isPlaying ? Icons.play_arrow : icon,
            color: isPlaying ? Colors.deepPurple : theme.colorScheme.primary,
          ),
        ),
        title: Text(
          lesson.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${lesson.subject} · ~$minutes min',
          style: TextStyle(fontSize: 12, color: theme.colorScheme.secondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                lesson.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: lesson.isFavorite ? Colors.red : theme.colorScheme.secondary,
                size: 20,
              ),
              onPressed: () => service.toggleFavorite(lesson),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.secondary, size: 20),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Fshi mësimin?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anulo')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        child: const Text('Fshi'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) service.deleteLesson(lesson);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showGenerateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GenerateLessonSheet(),
    );
  }
}
