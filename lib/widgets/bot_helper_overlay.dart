import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bot_helper_service.dart';
import 'scibot_mascot.dart';

/// Overlay draggable i botit SciBot - optimizuar me minimize/expand,
/// animacione të buta dhe pozicionim më të mirë
class BotHelperOverlay extends StatefulWidget {
  final String currentScreen;
  final Widget child;

  const BotHelperOverlay({
    super.key,
    required this.currentScreen,
    required this.child,
  });

  @override
  State<BotHelperOverlay> createState() => _BotHelperOverlayState();
}

class _BotHelperOverlayState extends State<BotHelperOverlay>
    with TickerProviderStateMixin {
  Offset _botPosition = const Offset(16, -1);
  bool _isDragging = false;
  bool _showMenu = false;
  bool _isMinimized = false; // Minimized mode - shows small dot
  late AnimationController _tipAnimController;
  late Animation<double> _tipAnimation;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _tipAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _tipAnimation = CurvedAnimation(
      parent: _tipAnimController,
      curve: Curves.easeOutBack,
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bounceAnimation = CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPosition();
      final botService = context.read<BotHelperService>();
      if (botService.botVisible) {
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) {
            botService.showTipForScreen(widget.currentScreen);
          }
        });
      }
    });
  }

  void _initPosition() {
    if (_botPosition.dy < 0) {
      final screenSize = MediaQuery.of(context).size;
      setState(() {
        _botPosition = Offset(
          screenSize.width - 90,
          screenSize.height - 250,
        );
      });
    }
  }

  @override
  void didUpdateWidget(BotHelperOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentScreen != widget.currentScreen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final botService = context.read<BotHelperService>();
        botService.clearTip();
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            botService.showTipForScreen(widget.currentScreen);
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _tipAnimController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _onTapBot() {
    if (_isMinimized) {
      setState(() => _isMinimized = false);
      _bounceController.forward(from: 0);
      return;
    }

    final botService = context.read<BotHelperService>();
    if (botService.activeTip != null) {
      botService.dismissCurrentTip(widget.currentScreen);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          botService.showTipForScreen(widget.currentScreen);
        }
      });
    } else {
      setState(() => _showMenu = !_showMenu);
    }
  }

  void _onDoubleTapBot() {
    setState(() => _isMinimized = !_isMinimized);
    if (!_isMinimized) {
      _bounceController.forward(from: 0);
    }
  }

  void _onLongPressBot() {
    if (!_isMinimized) {
      setState(() => _showMenu = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BotHelperService>(
      builder: (context, botService, _) {
        if (botService.activeTip != null && botService.isTipExpanded && !_isMinimized) {
          _tipAnimController.forward();
        } else {
          _tipAnimController.reverse();
        }

        return Stack(
          children: [
            widget.child,

            if (botService.botVisible && _botPosition.dy >= 0 && widget.currentScreen != 'home') ...[
              // Tip bubble
              if (botService.activeTip != null && !_isMinimized)
                Positioned(
                  left: _getBubbleLeft(),
                  top: _botPosition.dy - 100,
                  child: ScaleTransition(
                    scale: _tipAnimation,
                    alignment: Alignment.bottomCenter,
                    child: _buildTipBubble(botService.activeTip!, botService),
                  ),
                ),

              // Context menu overlay
              if (_showMenu)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setState(() => _showMenu = false),
                    child: Container(
                      color: Colors.black26,
                      child: Stack(
                        children: [
                          Positioned(
                            left: _getMenuLeft(),
                            top: _botPosition.dy - 170,
                            child: _buildContextMenu(botService),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Draggable bot
              AnimatedPositioned(
                duration: _isDragging ? Duration.zero : const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                left: _botPosition.dx,
                top: _botPosition.dy,
                child: GestureDetector(
                  onTap: _onTapBot,
                  onDoubleTap: _onDoubleTapBot,
                  onLongPress: _onLongPressBot,
                  onPanStart: (_) => setState(() => _isDragging = true),
                  onPanUpdate: (details) {
                    setState(() {
                      _botPosition += details.delta;
                      final screenSize = MediaQuery.of(context).size;
                      _botPosition = Offset(
                        _botPosition.dx.clamp(0, screenSize.width - 70),
                        _botPosition.dy.clamp(50, screenSize.height - 140),
                      );
                    });
                  },
                  onPanEnd: (_) {
                    setState(() => _isDragging = false);
                    _snapToEdge();
                  },
                  child: AnimatedScale(
                    scale: _isDragging ? 1.15 : (_isMinimized ? 0.5 : 1.0),
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack,
                    child: AnimatedOpacity(
                      opacity: _isMinimized ? 0.6 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: ScaleTransition(
                        scale: Tween(begin: 0.95, end: 1.0).animate(_bounceAnimation),
                        child: SciBotMascot(
                          size: 65,
                          isAnimating: !_isDragging && !_isMinimized,
                          showGlow: botService.activeTip != null && !_isMinimized,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  double _getBubbleLeft() {
    final screenWidth = MediaQuery.of(context).size.width;
    const bubbleWidth = 240.0;
    double left = _botPosition.dx - bubbleWidth / 2 + 32;
    return left.clamp(12, screenWidth - bubbleWidth - 12);
  }

  double _getMenuLeft() {
    final screenWidth = MediaQuery.of(context).size.width;
    double left = _botPosition.dx - 60;
    return left.clamp(12, screenWidth - 212);
  }

  void _snapToEdge() {
    final screenWidth = MediaQuery.of(context).size.width;
    final center = _botPosition.dx + 35;

    setState(() {
      if (center < screenWidth / 2) {
        _botPosition = Offset(8, _botPosition.dy);
      } else {
        _botPosition = Offset(screenWidth - 78, _botPosition.dy);
      }
    });
  }

  Widget _buildTipBubble(String tip, BotHelperService botService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 240,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2D35) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.cyanAccent.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tip,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() => _isMinimized = true);
                  botService.dismissCurrentTip(widget.currentScreen);
                },
                child: Text(
                  'Minimizo',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => botService.dismissCurrentTip(widget.currentScreen),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.cyanAccent.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContextMenu(BotHelperService botService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2D35) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _menuItem(
              Icons.lightbulb_outline,
              'Tregom një këshillë',
              Colors.amber,
              () {
                setState(() => _showMenu = false);
                botService.showTipForScreen(widget.currentScreen);
              },
            ),
            _menuDivider(isDark),
            _menuItem(
              Icons.minimize_rounded,
              'Minimizo',
              Colors.blue,
              () {
                setState(() {
                  _showMenu = false;
                  _isMinimized = true;
                });
              },
            ),
            _menuDivider(isDark),
            _menuItem(
              Icons.visibility_off_outlined,
              'Fshih SciBot',
              Colors.grey,
              () {
                setState(() => _showMenu = false);
                botService.hideBot();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('SciBot u fsheh! Mund ta rikthesh nga cilësimet.'),
                    action: SnackBarAction(
                      label: 'Rikthe',
                      onPressed: () => botService.showBot(),
                    ),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  Widget _menuDivider(bool isDark) {
    return Divider(
      height: 1,
      color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
    );
  }

  Widget _menuItem(
    IconData icon,
    String label,
    Color iconColor,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
