import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/audiobook_service.dart';
import 'lesson_player_screen.dart';

class GenerateLessonSheet extends StatefulWidget {
  const GenerateLessonSheet({super.key});

  @override
  State<GenerateLessonSheet> createState() => _GenerateLessonSheetState();
}

class _GenerateLessonSheetState extends State<GenerateLessonSheet> {
  final _topicController = TextEditingController();
  String _selectedSubject = 'Matematikë';

  static const _subjects = ['Matematikë', 'Fizikë', 'Kimi', 'Biologji'];

  static const _topicSuggestions = {
    'Matematikë': ['Teorema e Pitagorës', 'Ekuacionet kuadratike', 'Trigonometria'],
    'Fizikë': ['Ligjet e Njutonit', 'Energjia kinetike', 'Rryma elektrike'],
    'Kimi': ['Tabela periodike', 'Lidhjet kimike', 'Reaksionet redoks'],
    'Biologji': ['ADN dhe ARN', 'Fotosinteza', 'Sistemi nervor'],
  };

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text('Gjenero Mësim Audio',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),

            // Subject picker
            Text('Lënda', style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.secondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _subjects.map((s) {
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
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Topic field
            Text('Tema', style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.secondary)),
            const SizedBox(height: 8),
            TextField(
              controller: _topicController,
              decoration: InputDecoration(
                hintText: 'p.sh. Teorema e Pitagorës',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 8),

            // Topic suggestions
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: (_topicSuggestions[_selectedSubject] ?? []).map((t) {
                return ActionChip(
                  label: Text(t, style: const TextStyle(fontSize: 12)),
                  onPressed: () => _topicController.text = t,
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Generate button
            Consumer<AudiobookService>(
              builder: (context, service, _) {
                return SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: service.isGenerating
                        ? null
                        : () => _generate(context, service),
                    icon: service.isGenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(service.isGenerating ? 'Duke gjeneruar...' : 'Gjenero Mësimin'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generate(BuildContext context, AudiobookService service) async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shkruaj një temë')),
      );
      return;
    }

    final lesson = await service.generateLesson(
      subject: _selectedSubject,
      topic: topic,
    );

    if (!mounted) return;

    if (lesson != null) {
      Navigator.pop(context); // close sheet
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LessonPlayerScreen(lesson: lesson)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gabim në gjenerimin e mësimit')),
      );
    }
  }
}
