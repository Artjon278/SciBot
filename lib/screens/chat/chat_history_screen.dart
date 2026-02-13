import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/chat_service.dart';
import '../../services/chat_storage_service.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  List<ChatSession> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    
    final chatService = context.read<ChatService>();
    final sessions = await chatService.getAllSessions();
    
    setState(() {
      _sessions = sessions;
      _isLoading = false;
    });
  }

  Future<void> _deleteSession(ChatSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fshi Bisedën?'),
        content: Text('Je i sigurt që dëshiron të fshish "${session.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anulo'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Fshi'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await context.read<ChatService>().deleteSession(session.id);
      _loadSessions();
    }
  }

  void _loadSession(ChatSession session) async {
    await context.read<ChatService>().loadSession(session.id);
    if (mounted) {
      Navigator.pop(context, true); // Return true to indicate session loaded
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 1) {
      return 'Tani';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} min më parë';
    } else if (diff.inDays < 1) {
      return '${diff.inHours} orë më parë';
    } else if (diff.inDays == 1) {
      return 'Dje';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ditë më parë';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Bisedat e Mëparshme',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_sessions.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.delete_sweep_outlined,
                color: Colors.red.withOpacity(0.7),
              ),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Fshi të Gjitha?'),
                    content: const Text('Je i sigurt që dëshiron të fshish të gjitha bisedat?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Anulo'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Fshi të Gjitha'),
                      ),
                    ],
                  ),
                );
                
                if (confirmed == true) {
                  final storage = ChatStorageService();
                  await storage.clearAllSessions();
                  context.read<ChatService>().clearHistory();
                  _loadSessions();
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? _buildEmptyState(theme, isDark)
              : _buildSessionsList(theme, isDark),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: theme.colorScheme.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Nuk ke biseda të ruajtura',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fillo një bisedë të re me SciBot',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsList(ThemeData theme, bool isDark) {
    // Grupo sesionet sipas datës
    final Map<String, List<ChatSession>> grouped = {};
    
    for (final session in _sessions) {
      final now = DateTime.now();
      final diff = now.difference(session.lastMessageAt);
      
      String key;
      if (diff.inDays == 0) {
        key = 'Sot';
      } else if (diff.inDays == 1) {
        key = 'Dje';
      } else if (diff.inDays < 7) {
        key = 'Këtë Javë';
      } else if (diff.inDays < 30) {
        key = 'Këtë Muaj';
      } else {
        key = 'Më të Vjetra';
      }
      
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(session);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: grouped.length,
      itemBuilder: (context, groupIndex) {
        final groupKey = grouped.keys.elementAt(groupIndex);
        final groupSessions = grouped[groupKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                groupKey,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            ...groupSessions.map((session) => _buildSessionTile(session, theme, isDark)),
          ],
        );
      },
    );
  }

  Widget _buildSessionTile(ChatSession session, ThemeData theme, bool isDark) {
    final chatService = context.read<ChatService>();
    final isCurrentSession = chatService.currentSessionId == session.id;

    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteSession(session),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Fshi Bisedën?'),
            content: Text('Fshi "${session.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Anulo'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Fshi'),
              ),
            ],
          ),
        ) ?? false;
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isCurrentSession
                ? Colors.blue.withOpacity(0.2)
                : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isCurrentSession ? Icons.chat : Icons.chat_bubble_outline,
            color: isCurrentSession 
                ? Colors.blue 
                : theme.colorScheme.onSurface.withOpacity(0.5),
            size: 22,
          ),
        ),
        title: Text(
          session.title,
          style: TextStyle(
            fontWeight: isCurrentSession ? FontWeight.w600 : FontWeight.w500,
            fontSize: 15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (session.previewText != null)
              Text(
                session.previewText!,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(session.lastMessageAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.message_outlined,
                  size: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
                const SizedBox(width: 4),
                Text(
                  '${session.messages.length} mesazhe',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: isCurrentSession
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Aktive',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
        onTap: () => _loadSession(session),
      ),
    );
  }
}
