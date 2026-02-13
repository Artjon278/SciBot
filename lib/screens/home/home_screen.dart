import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/theme/theme_provider.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/bot_helper_service.dart';
import '../../widgets/chat_illustrations.dart';
import '../../widgets/bot_helper_overlay.dart';
import '../../widgets/scibot_mascot.dart';
import '../lab/lab_screen.dart';
import '../quiz/quiz_screen.dart';
import '../homework/homework_screen.dart';
import '../chat/chat_history_screen.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';
import '../../core/utils/page_transitions.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  int _selectedIndex = 0;
  bool _chatStarted = false;

  String _currentScreen = 'home';

  String get userName => context.read<AuthService>().username;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatService = context.read<ChatService>();
      if (chatService.messages.isNotEmpty) {
        setState(() => _chatStarted = true);
      }
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    _chatController.clear();
    
    if (!_chatStarted) {
      setState(() {
        _chatStarted = true;
        _currentScreen = 'chat';
      });
    }

    await context.read<ChatService>().sendMessage(text);
    _scrollToBottom();
  }

  void _resetChat() {
    context.read<ChatService>().clearHistory();
    setState(() {
      _chatStarted = false;
      _currentScreen = 'home';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = theme.brightness == Brightness.dark;

    return BotHelperOverlay(
      currentScreen: _currentScreen,
      child: Scaffold(
        body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white : Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.science_outlined,
                          color: isDark ? Colors.black : Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'SciBot',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Chat history button
                      IconButton(
                        onPressed: () async {
                          final result = await Navigator.push<bool>(
                            context,
                            SlidePageRoute(page: const ChatHistoryScreen()),
                          );
                          // If a session was loaded, update chat state
                          if (result == true) {
                            final chatService = context.read<ChatService>();
                            if (chatService.messages.isNotEmpty) {
                              setState(() => _chatStarted = true);
                              _scrollToBottom();
                            }
                          }
                        },
                        icon: Icon(
                          Icons.history_rounded,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        tooltip: 'Bisedat e mëparshme',
                      ),
                      if (_chatStarted)
                        IconButton(
                          onPressed: _resetChat,
                          icon: Icon(
                            Icons.add_comment_outlined,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          tooltip: 'Bisedë e re',
                        ),
                      IconButton(
                        onPressed: () => themeProvider.toggleTheme(),
                        icon: Icon(
                          isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      // Profile menu
                      PopupMenuButton<String>(
                        icon: Consumer<AuthService>(
                          builder: (context, auth, _) {
                            if (auth.photoUrl != null) {
                              return CircleAvatar(
                                radius: 16,
                                backgroundImage: NetworkImage(auth.photoUrl!),
                                backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                              );
                            }
                            return CircleAvatar(
                              radius: 16,
                              backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                              child: Text(
                                auth.username.isNotEmpty ? auth.username[0].toUpperCase() : '?',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            );
                          },
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        offset: const Offset(0, 45),
                        onSelected: (value) async {
                          if (value == 'profile') {
                            Navigator.push(
                              context,
                              SlidePageRoute(page: const ProfileScreen()),
                            );
                          } else if (value == 'toggle_bot') {
                            context.read<BotHelperService>().toggleBotVisibility();
                          } else if (value == 'logout') {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Dil nga llogaria?'),
                                content: const Text('Je i sigurt që dëshiron të dalësh?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Anulo'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Dil'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true && mounted) {
                              await context.read<AuthService>().signOut();
                              if (mounted) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  (route) => false,
                                );
                              }
                            }
                          }
                        },
                        itemBuilder: (context) {
                          final auth = context.read<AuthService>();
                          return [
                            PopupMenuItem(
                              enabled: false,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    auth.username,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  if (auth.email != null)
                                    Text(
                                      auth.email!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.secondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'profile',
                              child: Row(
                                children: [
                                  Icon(Icons.person_outline, size: 18),
                                  SizedBox(width: 10),
                                  Text('Profili im'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'toggle_bot',
                              child: Consumer<BotHelperService>(
                                builder: (context, botService, _) {
                                  return Row(
                                    children: [
                                      botService.botVisible
                                          ? const Icon(Icons.visibility_off_outlined, size: 18, color: Colors.cyan)
                                          : const SciBotAvatar(size: 18),
                                      const SizedBox(width: 10),
                                      Text(
                                        botService.botVisible
                                            ? 'Fshih SciBot'
                                            : 'Shfaq SciBot',
                                        style: const TextStyle(color: Colors.cyan),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Icon(Icons.logout, size: 18, color: Colors.red),
                                  SizedBox(width: 10),
                                  Text('Dil nga llogaria', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ];
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: _chatStarted 
                  ? _buildChatView(theme, isDark) 
                  : _buildWelcomeView(theme, isDark),
            ),

            // Chat input
            _buildChatInput(theme, isDark),
          ],
        ),
      ),
      
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: isDark 
                  ? Colors.white.withOpacity(0.08) 
                  : Colors.black.withOpacity(0.06),
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(context, Icons.chat_bubble_outline, Icons.chat_bubble, 'Chat', 0, isDark),
                _buildNavItem(context, Icons.science_outlined, Icons.science, 'Laboratori', 1, isDark),
                _buildNavItem(context, Icons.quiz_outlined, Icons.quiz, 'Kuizi', 2, isDark),
                _buildNavItem(context, Icons.home_work_outlined, Icons.home_work, 'HW', 3, isDark),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildWelcomeView(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const Spacer(flex: 2),
          
          Text(
            'Përshëndetje, $userName 👋',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Çfarë do të mësojmë sot?',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.secondary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _buildSuggestionChip('📐 Shpjegom teoremën e Pitagorës', isDark),
              _buildSuggestionChip('⚗️ Çfarë është tabela periodike?', isDark),
              _buildSuggestionChip('🧬 Si funksionon ADN-ja?', isDark),
              _buildSuggestionChip('⚡ Ligjet e Njutonit', isDark),
            ],
          ),

          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text, bool isDark) {
    return GestureDetector(
      onTap: () {
        _chatController.text = text.substring(2).trim();
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
        ),
      ),
    );
  }

  Widget _buildChatView(ThemeData theme, bool isDark) {
    return Consumer<ChatService>(
      builder: (context, chatService, _) {
        _scrollToBottom();

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: chatService.messages.length + (chatService.isTyping ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == chatService.messages.length && chatService.isTyping) {
              return _buildTypingIndicator(isDark);
            }
            return _buildMessageBubble(chatService.messages[index], isDark);
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isDark) {
    final isUser = message.isUser;
    final illustration = !isUser ? getIllustrationForMessage(message.text) : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? Colors.blue
                        : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                  ),
                  child: isUser
                      ? Text(
                          message.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        )
                      : MarkdownBody(
                          data: message.text,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 15,
                              height: 1.4,
                            ),
                            strong: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                            em: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontStyle: FontStyle.italic,
                              fontSize: 15,
                            ),
                            h1: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                            h2: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            h3: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            listBullet: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 15,
                            ),
                            code: TextStyle(
                              color: isDark ? Colors.greenAccent : Colors.green.shade800,
                              backgroundColor: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.06),
                              fontSize: 14,
                              fontFamily: 'monospace',
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.black.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_outline, color: isDark ? Colors.white70 : Colors.black54, size: 18),
                ),
              ],
            ],
          ),
          // Illustration after AI message
          if (illustration != null)
            Padding(
              padding: EdgeInsets.only(left: !isUser ? 0 : 0, top: 8),
              child: illustration,
            ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInput(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _chatController,
                focusNode: _focusNode,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Shkruaj mesazhin tënd...',
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.secondary.withOpacity(0.6),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            Consumer<ChatService>(
              builder: (context, chatService, _) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: IconButton(
                    onPressed: chatService.isTyping ? null : _sendMessage,
                    icon: Icon(
                      Icons.arrow_upward_rounded,
                      color: chatService.isTyping ? Colors.grey : (isDark ? Colors.black : Colors.white),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: chatService.isTyping 
                          ? Colors.grey.withOpacity(0.3) 
                          : (isDark ? Colors.white : Colors.black),
                      padding: const EdgeInsets.all(10),
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

  Widget _buildNavItem(BuildContext context, IconData icon, IconData activeIcon, String label, int index, bool isDark) {
    final theme = Theme.of(context);
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
          _currentScreen = index == 0
              ? 'home'
              : index == 1
                  ? 'lab'
                  : index == 2
                      ? 'quiz'
                      : 'homework';
        });
        if (index == 1) {
          Navigator.push(context, SlidePageRoute(page: const LabScreen()));
        } else if (index == 2) {
          Navigator.push(context, SlidePageRoute(page: const QuizScreen()));
        } else if (index == 3) {
          Navigator.push(context, SlidePageRoute(page: const HomeworkScreen()));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.06)) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.secondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = (_controller.value + delay) % 1.0;
            final opacity = (value < 0.5 ? value : 1 - value) * 2;
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.3 + opacity * 0.7),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
