import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/audio_lesson.dart';
import '../../services/audiobook_service.dart';

class LessonPlayerScreen extends StatelessWidget {
  final AudioLesson lesson;
  const LessonPlayerScreen({super.key, required this.lesson});

  static const _subjectIcons = {
    'Matematikë': Icons.calculate,
    'Fizikë': Icons.bolt,
    'Kimi': Icons.science,
    'Biologji': Icons.biotech,
  };

  static const _subjectColors = {
    'Matematikë': Colors.blue,
    'Fizikë': Colors.orange,
    'Kimi': Colors.green,
    'Biologji': Colors.teal,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final icon = _subjectIcons[lesson.subject] ?? Icons.school;
    final color = _subjectColors[lesson.subject] ?? Colors.deepPurple;
    final minutes = (lesson.durationSeconds / 60).ceil();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dëgjo Mësimin'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // Subject art
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.7), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(icon, size: 56, color: Colors.white),
          ),

          const SizedBox(height: 20),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              lesson.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${lesson.subject} · ~$minutes min',
            style: TextStyle(color: theme.colorScheme.secondary),
          ),

          const SizedBox(height: 24),

          // Controls
          Consumer<AudiobookService>(
            builder: (context, service, _) {
              final isThisPlaying =
                  service.currentLessonId == lesson.id && service.ttsState == TtsState.playing;
              final isThisPaused =
                  service.currentLessonId == lesson.id && service.ttsState == TtsState.paused;

              return Column(
                children: [
                  // Play / Pause / Stop
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 36,
                        onPressed: () => service.stopPlayback(),
                        icon: Icon(Icons.stop_rounded, color: theme.colorScheme.secondary),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          iconSize: 48,
                          color: Colors.white,
                          onPressed: () {
                            if (isThisPlaying) {
                              service.pausePlayback();
                            } else {
                              service.playLesson(lesson);
                            }
                          },
                          icon: Icon(isThisPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Speed selector
                      PopupMenuButton<double>(
                        onSelected: (rate) => service.setSpeechRate(rate),
                        icon: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${service.speechRate}x',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        itemBuilder: (_) => [0.75, 1.0, 1.25, 1.5]
                            .map((r) => PopupMenuItem(value: r, child: Text('${r}x')))
                            .toList(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  if (isThisPlaying)
                    Text('Duke luajtur...', style: TextStyle(color: color, fontWeight: FontWeight.w500))
                  else if (isThisPaused)
                    Text('Pauzë', style: TextStyle(color: theme.colorScheme.secondary)),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          Divider(indent: 24, endIndent: 24, color: isDark ? Colors.white12 : Colors.black12),

          // Transcript
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Transkripti',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Text(
                lesson.script,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.7,
                  color: theme.colorScheme.onSurface.withOpacity(0.85),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
