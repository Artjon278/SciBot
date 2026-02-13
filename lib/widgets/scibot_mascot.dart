import 'package:flutter/material.dart';

/// Widgeti i maskotës SciBot - bot i animuar që ndërvepron me përdoruesin
class SciBotMascot extends StatefulWidget {
  final double size;
  final bool isAnimating;
  final bool showGlow;
  final VoidCallback? onTap;

  const SciBotMascot({
    super.key,
    this.size = 80,
    this.isAnimating = true,
    this.showGlow = false,
    this.onTap,
  });

  @override
  State<SciBotMascot> createState() => _SciBotMascotState();
}

class _SciBotMascotState extends State<SciBotMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _bounceAnimation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.easeInOut,
      ),
    );
    if (widget.isAnimating) {
      _bounceController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SciBotMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating && !_bounceController.isAnimating) {
      _bounceController.repeat(reverse: true);
    } else if (!widget.isAnimating && _bounceController.isAnimating) {
      _bounceController.stop();
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _bounceAnimation.value),
            child: child,
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Efekti i shkëlqimit (glow)
            if (widget.showGlow)
              Container(
                width: widget.size + 20,
                height: widget.size + 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
            // Imazhi i maskotës - pa clipping rrethore, transparente natyrale
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: Image.asset(
                'assets/images/scibot_mascot.png',
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget i vogël i maskotës për përdorim në chat bubbles dhe avatarë
/// Pa animacion bounce, thjesht imazhi
class SciBotAvatar extends StatelessWidget {
  final double size;

  const SciBotAvatar({super.key, this.size = 34});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/scibot_mascot.png',
        fit: BoxFit.contain,
      ),
    );
  }
}
