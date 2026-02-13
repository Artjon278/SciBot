import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../services/homework_service.dart';
import '../../core/utils/page_transitions.dart';
import 'homework_detail_screen.dart';

class HomeworkScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const HomeworkScreen({super.key, this.onBack});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  final ImagePicker _picker = ImagePicker();

  static const List<Map<String, String>> _subjects = [
    {'name': 'Matematikë', 'emoji': '📐'},
    {'name': 'Fizikë', 'emoji': '⚡'},
    {'name': 'Kimi', 'emoji': '⚗️'},
    {'name': 'Biologji', 'emoji': '🧬'},
    {'name': 'Informatikë', 'emoji': '💻'},
    {'name': 'Tjetër', 'emoji': '📚'},
  ];

  String? _selectedSubject;
  bool _hideCompleted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeworkService>().loadHomework();
    });
  }

  List<HomeworkItem> _filteredItems(List<HomeworkItem> items) {
    var filtered = items;
    if (_selectedSubject != null) {
      filtered = filtered.where((h) => h.subject == _selectedSubject).toList();
    }
    if (_hideCompleted) {
      filtered = filtered.where((h) => !h.isFullySolved).toList();
    }
    return filtered;
  }

  String _getSubjectEmoji(String subject) {
    return _subjects.firstWhere(
      (s) => s['name'] == subject,
      orElse: () => {'emoji': '📚'},
    )['emoji']!;
  }

  Future<void> _pickAndExtract(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image == null) return;

      final file = File(image.path);
      if (!mounted) return;

      final hwService = context.read<HomeworkService>();
      final result = await hwService.createFromPhoto(file);

      if (result != null && mounted) {
        Navigator.push(
          context,
          SlidePageRoute(page: HomeworkDetailScreen(homework: result)),
        );
      } else if (hwService.extractError != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(hwService.extractError!)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gabim: $e')),
        );
      }
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'],
      );
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      if (!mounted) return;

      final ext = file.path.toLowerCase().split('.').last;
      final isImage = ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'].contains(ext);

      final hwService = context.read<HomeworkService>();
      final hw = isImage
          ? await hwService.createFromPhoto(file)
          : await hwService.createFromDocument(file);

      if (hw != null && mounted) {
        Navigator.push(
          context,
          SlidePageRoute(page: HomeworkDetailScreen(homework: hw)),
        );
      } else if (hwService.extractError != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(hwService.extractError!)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gabim: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Ngarko detyrat',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Foto, PDF ose DOCX — AI do të nxjerrë ushtrimet automatikisht',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.secondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildSourceOption(
                    icon: Icons.camera_alt,
                    title: 'Kamera',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndExtract(ImageSource.camera);
                    },
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSourceOption(
                    icon: Icons.folder_open,
                    title: 'Skedar',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickDocument();
                    },
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 8),
            Text(title,
                style:
                    TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    GestureDetector(
                      onTap: () => widget.onBack != null ? widget.onBack!() : Navigator.pop(context),
                      child: Icon(Icons.arrow_back,
                          color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(width: 12),
                    Text('Detyrat',
                        style: theme.textTheme.headlineMedium?.copyWith(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                  ]),
                  IconButton(
                    onPressed: () => themeProvider.toggleTheme(),
                    icon: Icon(
                        isDark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        color: theme.colorScheme.onSurface),
                  ),
                ],
              ),
            ),

            // ── Content ──
            Expanded(
              child: Consumer<HomeworkService>(
                builder: (context, hwService, _) {
                  // Extracting overlay
                  if (hwService.isExtracting) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 20),
                          Text('AI po analizon...',
                              style: theme.textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text('Po nxjerr ushtrimet',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.secondary)),
                        ],
                      ),
                    );
                  }

                  if (hwService.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final filtered = _filteredItems(hwService.items);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // ── Upload card ──
                        _buildUploadCard(context, isDark),

                        const SizedBox(height: 24),

                        // ── Stats ──
                        _buildStatsRow(context, hwService, isDark),

                        const SizedBox(height: 24),

                        // ── Subject filter ──
                        Text('Filtro sipas lëndës',
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _buildSubjectChip(context,
                                name: 'Të gjitha',
                                emoji: '🎯',
                                isSelected: _selectedSubject == null,
                                onTap: () =>
                                    setState(() => _selectedSubject = null),
                                isDark: isDark),
                            ..._subjects.map((s) => _buildSubjectChip(
                                context,
                                name: s['name']!,
                                emoji: s['emoji']!,
                                isSelected: _selectedSubject == s['name'],
                                onTap: () => setState(() =>
                                    _selectedSubject =
                                        _selectedSubject == s['name']
                                            ? null
                                            : s['name']),
                                isDark: isDark)),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── List header ──
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedSubject != null
                                  ? 'Detyrat e $_selectedSubject'
                                  : 'Të gjitha detyrat',
                              style: theme.textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => setState(() => _hideCompleted = !_hideCompleted),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: _hideCompleted
                                          ? (isDark ? Colors.white : Colors.black)
                                          : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _hideCompleted ? Icons.visibility_off : Icons.visibility,
                                          size: 14,
                                          color: _hideCompleted
                                              ? (isDark ? Colors.black : Colors.white)
                                              : theme.colorScheme.secondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _hideCompleted ? 'Fshehur' : 'Fshih',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: _hideCompleted
                                                ? (isDark ? Colors.black : Colors.white)
                                                : theme.colorScheme.secondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('${filtered.length}',
                                    style: theme.textTheme.bodyMedium),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ── Homework list ──
                        if (filtered.isEmpty)
                          _buildEmptyState(context, isDark)
                        else
                          ...filtered.map((hw) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildHomeworkCard(
                                    context, hw, isDark, hwService),
                              )),

                        const SizedBox(height: 80),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showImageSourceDialog,
        backgroundColor: isDark ? Colors.white : Colors.black,
        foregroundColor: isDark ? Colors.black : Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Ngarko Detyra',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  Upload Card
  // ═══════════════════════════════════════════════════
  Widget _buildUploadCard(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.indigo.shade900, Colors.purple.shade900]
              : [Colors.indigo.shade400, Colors.purple.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12)),
              child: const Text('📸 Foto / 📄 PDF → Zgjidhje',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 16),
          const Text('Skano Detyrat',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
              'Foto, PDF ose DOCX • AI i ndan ushtrimet • Zgjidh hap pas hapi',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.8), fontSize: 14)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _pickAndExtract(ImageSource.camera),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 18, color: Colors.black),
                      SizedBox(width: 8),
                      Text('Foto',
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: _pickDocument,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.white.withOpacity(0.4)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open,
                          size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Skedar',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  Stats Row
  // ═══════════════════════════════════════════════════
  Widget _buildStatsRow(
      BuildContext context, HomeworkService hwService, bool isDark) {
    final theme = Theme.of(context);
    return Row(children: [
      _buildStatCard(theme, '${hwService.totalHomework}', 'Gjithsej',
          Icons.assignment, Colors.blue, isDark),
      const SizedBox(width: 10),
      _buildStatCard(theme, '${hwService.fullyDoneCount}', 'Përfunduar',
          Icons.check_circle, Colors.green, isDark),
      const SizedBox(width: 10),
      _buildStatCard(theme, '${hwService.inProgressCount}', 'Në punë',
          Icons.pending, Colors.orange, isDark),
      const SizedBox(width: 10),
      _buildStatCard(theme, '${hwService.newCount}', 'Të reja',
          Icons.fiber_new, Colors.purple, isDark),
    ]);
  }

  Widget _buildStatCard(ThemeData theme, String value, String label,
      IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: theme.colorScheme.secondary)),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  Subject Chip
  // ═══════════════════════════════════════════════════
  Widget _buildSubjectChip(BuildContext context,
      {required String name,
      required String emoji,
      required bool isSelected,
      required VoidCallback onTap,
      required bool isDark}) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white : Colors.black)
              : (isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : (isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1))),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(name,
              style: TextStyle(
                  color: isSelected
                      ? (isDark ? Colors.black : Colors.white)
                      : theme.colorScheme.onSurface,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400)),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  Homework Card
  // ═══════════════════════════════════════════════════
  Widget _buildHomeworkCard(BuildContext context, HomeworkItem hw,
      bool isDark, HomeworkService hwService) {
    final theme = Theme.of(context);

    Color progressColor;
    String progressLabel;
    if (hw.isFullySolved) {
      progressColor = Colors.green;
      progressLabel = 'Përfunduar';
    } else if (hw.solvedCount > 0) {
      progressColor = Colors.orange;
      progressLabel = '${hw.solvedCount}/${hw.totalCount} zgjidhur';
    } else {
      progressColor = Colors.blue;
      progressLabel = '${hw.totalCount} ushtrime';
    }

    return Dismissible(
      key: Key(hw.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Fshi detyrën?'),
            content: Text(
                'Do të fshish "${hw.title}" me ${hw.totalCount} ushtrime?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Anulo')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white),
                child: const Text('Fshi'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => hwService.deleteHomework(hw.id),
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(context,
              SlidePageRoute(page: HomeworkDetailScreen(homework: hw)));
          if (mounted) hwService.loadHomework();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(_getSubjectEmoji(hw.subject),
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hw.title,
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          '${hw.createdAt.day}/${hw.createdAt.month}/${hw.createdAt.year}',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary),
                        ),
                      ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: progressColor
                          .withOpacity(isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(progressLabel,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: progressColor)),
                ),
              ]),
              const SizedBox(height: 12),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: hw.progress,
                  minHeight: 6,
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.06),
                  valueColor: AlwaysStoppedAnimation(progressColor),
                ),
              ),
              const SizedBox(height: 10),
              // Exercise preview chips
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: hw.exercises.take(6).map((ex) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: ex.isSolved
                          ? Colors.green
                              .withOpacity(isDark ? 0.2 : 0.1)
                          : (isDark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.black.withOpacity(0.04)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: ex.isSolved
                              ? Colors.green.withOpacity(0.3)
                              : Colors.transparent),
                    ),
                    child:
                        Row(mainAxisSize: MainAxisSize.min, children: [
                      if (ex.isSolved)
                        const Icon(Icons.check,
                            size: 12, color: Colors.green),
                      if (ex.isSolved) const SizedBox(width: 4),
                      Text('Usht. ${ex.number}',
                          style: TextStyle(
                              fontSize: 11,
                              color: ex.isSolved
                                  ? Colors.green
                                  : theme.colorScheme.secondary)),
                    ]),
                  );
                }).toList(),
              ),
              if (hw.exercises.length > 6)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('+${hw.exercises.length - 6} të tjera',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  Empty State
  // ═══════════════════════════════════════════════════
  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.04),
            shape: BoxShape.circle,
          ),
          child: const Center(
              child: Text('📸', style: TextStyle(fontSize: 36))),
        ),
        const SizedBox(height: 16),
        Text('Nuk ka detyra ende',
            style: theme.textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(
            'Bëj foto ose ngarko dokument dhe AI do t\'i nxjerrë\nushtrimet automatikisht',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.secondary),
            textAlign: TextAlign.center),
      ]),
    );
  }
}
