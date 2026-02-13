import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../services/gemini_service.dart';

class PhotoLabScreen extends StatefulWidget {
  const PhotoLabScreen({super.key});

  @override
  State<PhotoLabScreen> createState() => _PhotoLabScreenState();
}

class _PhotoLabScreenState extends State<PhotoLabScreen> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final GeminiService _gemini = GeminiService();
  
  File? _selectedImage;
  bool _isDocument = false;
  String? _selectedMode;
  String? _result;
  bool _isLoading = false;
  final TextEditingController _additionalPromptController = TextEditingController();
  
  late AnimationController _animController;
  // ignore: unused_field
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _modes = [
    {
      'id': 'summarize',
      'title': 'Përmbledh',
      'icon': Icons.summarize,
      'color': Colors.blue,
      'description': 'Merr pikat kryesore të materialit',
    },
    {
      'id': 'flashcard',
      'title': 'Flashcards',
      'icon': Icons.style,
      'color': Colors.purple,
      'description': 'Krijo karta për të mësuar',
    },
    {
      'id': 'quiz',
      'title': 'Kuiz',
      'icon': Icons.quiz,
      'color': Colors.orange,
      'description': 'Gjenero pyetje kuizi',
    },
    {
      'id': 'lab',
      'title': 'Laborator',
      'icon': Icons.science,
      'color': Colors.green,
      'description': 'Krijo sfidë laboratori',
    },
    {
      'id': 'solve',
      'title': 'Zgjidh',
      'icon': Icons.calculate,
      'color': Colors.red,
      'description': 'Zgjidh problemin hap pas hapi',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _additionalPromptController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _result = null;
          _selectedMode = null;
        });
        _animController.forward(from: 0);
      }
    } catch (e) {
      _showError('Gabim gjatë zgjedhjes së imazhit: $e');
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png', 'webp'],
      );
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final ext = file.path.toLowerCase().split('.').last;
      final isImage = ['jpg', 'jpeg', 'png', 'webp'].contains(ext);

      setState(() {
        _selectedImage = file;
        _isDocument = !isImage;
        _result = null;
        _selectedMode = null;
      });
      _animController.forward(from: 0);
    } catch (e) {
      _showError('Gabim gjatë zgjedhjes së skedarit: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null || _selectedMode == null) return;

    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final response = await _gemini.analyzeImage(
        imageFile: _selectedImage!,
        mode: _selectedMode!,
        additionalPrompt: _additionalPromptController.text.isNotEmpty
            ? _additionalPromptController.text
            : null,
      );

      if (mounted) {
        setState(() {
          _result = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError('Gabim: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Zgjidh burimin',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Foto, PDF ose DOCX',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.secondary,
              ),
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
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSourceOption(
                    icon: Icons.photo_library,
                    title: 'Galeria',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
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
                      Navigator.pop(context);
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
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
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
          children: [
            // Header
            _buildHeader(theme, themeProvider, isDark),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image selection area
                    _buildImageArea(theme, isDark),
                    
                    if (_selectedImage != null) ...[
                      const SizedBox(height: 20),
                      
                      // Mode selection
                      _buildModeSelection(theme, isDark),
                      
                      const SizedBox(height: 16),
                      
                      // Additional prompt
                      _buildAdditionalPrompt(theme, isDark),
                      
                      const SizedBox(height: 16),
                      
                      // Analyze button
                      _buildAnalyzeButton(isDark),
                    ],
                    
                    // Results
                    if (_result != null) ...[
                      const SizedBox(height: 24),
                      _buildResults(theme, isDark),
                    ],
                    
                    // Loading indicator
                    if (_isLoading) ...[
                      const SizedBox(height: 24),
                      _buildLoadingIndicator(theme, isDark),
                    ],
                    
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

  Widget _buildHeader(ThemeData theme, ThemeProvider themeProvider, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_back,
                size: 20,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text('📸', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Foto Laboratori',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Ngarko foto ose dokument dhe mëso me AI',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => themeProvider.toggleTheme(),
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageArea(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: _selectedImage != null ? 250 : 200,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _selectedImage != null
                ? Colors.green.withOpacity(0.5)
                : (isDark
                    ? Colors.white.withOpacity(0.15)
                    : Colors.black.withOpacity(0.1)),
            width: _selectedImage != null ? 2 : 1,
          ),
        ),
        child: _selectedImage != null
            ? Stack(
                children: [
                  if (_isDocument)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.description, size: 48, color: theme.colorScheme.secondary),
                          const SizedBox(height: 8),
                          Text(
                            _selectedImage!.path.split(Platform.pathSeparator).last,
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    )
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.file(
                        _selectedImage!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  // Change image button
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  // Success indicator
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_isDocument ? Icons.description : Icons.check, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            _isDocument ? 'Dokumenti u ngarkua' : 'Imazhi u ngarkua',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 40,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Kliko për të ngarkuar',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Foto, PDF, DOCX ose galeri',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildModeSelection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Çfarë dëshiron të bësh?',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _modes.map((mode) {
            final isSelected = _selectedMode == mode['id'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMode = mode['id'];
                  _result = null;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (mode['color'] as Color).withOpacity(isDark ? 0.3 : 0.15)
                      : (isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.04)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? mode['color'] as Color
                        : (isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.08)),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      mode['icon'] as IconData,
                      size: 18,
                      color: isSelected
                          ? mode['color'] as Color
                          : theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      mode['title'] as String,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? mode['color'] as Color
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        
        // Mode description
        if (_selectedMode != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (_modes.firstWhere((m) => m['id'] == _selectedMode)['color'] as Color)
                  .withOpacity(isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  _modes.firstWhere((m) => m['id'] == _selectedMode)['icon'] as IconData,
                  color: _modes.firstWhere((m) => m['id'] == _selectedMode)['color'] as Color,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _modes.firstWhere((m) => m['id'] == _selectedMode)['description'] as String,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAdditionalPrompt(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kërkesë shtesë (opsionale)',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.08),
            ),
          ),
          child: TextField(
            controller: _additionalPromptController,
            style: theme.textTheme.bodyMedium,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'p.sh. "Fokusohu tek formulat" ose "Shpjego më thjeshtë"',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.secondary.withOpacity(0.5),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzeButton(bool isDark) {
    final isEnabled = _selectedMode != null && !_isLoading;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isEnabled ? _analyzeImage : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled
              ? (_modes.firstWhere((m) => m['id'] == _selectedMode)['color'] as Color)
              : Colors.grey,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedMode != null
                  ? (_modes.firstWhere((m) => m['id'] == _selectedMode)['icon'] as IconData)
                  : Icons.auto_awesome,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _selectedMode == null
                  ? 'Zgjidh një opsion'
                  : 'Analizo me AI',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(ThemeData theme, bool isDark) {
    final mode = _modes.firstWhere((m) => m['id'] == _selectedMode);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: mode['color'] as Color,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isDocument ? 'AI po analizon dokumentin...' : 'AI po analizon imazhin...',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getModeLoadingText(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  String _getModeLoadingText() {
    switch (_selectedMode) {
      case 'summarize':
        return 'Duke nxjerrë pikat kryesore...';
      case 'flashcard':
        return 'Duke krijuar flashcards...';
      case 'quiz':
        return 'Duke gjeneruar pyetje kuizi...';
      case 'lab':
        return 'Duke krijuar sfidë laboratori...';
      case 'solve':
        return 'Duke zgjidhur problemin...';
      default:
        return 'Duke procesuar...';
    }
  }

  Widget _buildResults(ThemeData theme, bool isDark) {
    final mode = _modes.firstWhere((m) => m['id'] == _selectedMode, orElse: () => _modes[0]);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (mode['color'] as Color).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (mode['color'] as Color).withOpacity(isDark ? 0.25 : 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  mode['icon'] as IconData,
                  color: mode['color'] as Color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${mode['title']} - Rezultati',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Copy button
              IconButton(
                onPressed: () {
                  // Copy to clipboard functionality would go here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Teksti u kopjua!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                icon: Icon(
                  Icons.copy,
                  color: theme.colorScheme.secondary,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Divider
          Container(
            height: 1,
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.08),
          ),
          const SizedBox(height: 16),
          
          // Result content
          SelectableText(
            _result ?? '',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _result = null;
                    });
                    _analyzeImage();
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Rianalizo'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedImage = null;
                      _selectedMode = null;
                      _result = null;
                      _additionalPromptController.clear();
                    });
                  },
                  icon: const Icon(Icons.add_photo_alternate, size: 18),
                  label: const Text('Foto e re'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mode['color'] as Color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
