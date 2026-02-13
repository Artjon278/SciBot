import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Widget për vizualizimin e Teoremës së Pitagorës
class PythagorasVisualization extends StatelessWidget {
  final double a; // Kateti i parë
  final double b; // Kateti i dytë  
  final double c; // Hipotenuza
  final bool isDark;

  const PythagorasVisualization({
    super.key,
    this.a = 6,
    this.b = 8,
    this.c = 10,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: CustomPaint(
        size: const Size(double.infinity, 180),
        painter: _PythagorasPainter(
          a: a,
          b: b,
          c: c,
          isDark: isDark,
        ),
      ),
    );
  }
}

class _PythagorasPainter extends CustomPainter {
  final double a, b, c;
  final bool isDark;

  _PythagorasPainter({
    required this.a,
    required this.b,
    required this.c,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.white : Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = (isDark ? Colors.blue : Colors.blue.shade300).withOpacity(0.2)
      ..style = PaintingStyle.fill;

    // Scale factor
    final scale = size.height / 12;
    final offsetX = size.width / 2 - 40;
    final offsetY = size.height - 20;

    // Triangle points
    final p1 = Offset(offsetX, offsetY); // Bottom left
    final p2 = Offset(offsetX + a * scale, offsetY); // Bottom right
    final p3 = Offset(offsetX, offsetY - b * scale); // Top left

    // Draw filled triangle
    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..close();
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);

    // Draw right angle marker
    final rightAnglePaint = Paint()
      ..color = isDark ? Colors.white70 : Colors.black54
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    final squareSize = 12.0;
    canvas.drawLine(
      Offset(p1.dx + squareSize, p1.dy),
      Offset(p1.dx + squareSize, p1.dy - squareSize),
      rightAnglePaint,
    );
    canvas.drawLine(
      Offset(p1.dx + squareSize, p1.dy - squareSize),
      Offset(p1.dx, p1.dy - squareSize),
      rightAnglePaint,
    );

    // Text painter for labels
    void drawLabel(String text, Offset position, Color color) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, position);
    }

    // Draw labels
    // Side a (bottom)
    drawLabel(
      '${a.toInt()}m',
      Offset((p1.dx + p2.dx) / 2 - 10, p1.dy + 5),
      Colors.green,
    );

    // Side b (left - the unknown)
    drawLabel(
      '?',
      Offset(p1.dx - 25, (p1.dy + p3.dy) / 2 - 8),
      Colors.orange,
    );

    // Side c (hypotenuse)
    drawLabel(
      '${c.toInt()}m',
      Offset((p2.dx + p3.dx) / 2 + 5, (p2.dy + p3.dy) / 2 - 8),
      Colors.blue,
    );

    // Draw wall indicator
    final wallPaint = Paint()
      ..color = isDark ? Colors.grey.shade600 : Colors.grey.shade400
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    
    canvas.drawLine(
      Offset(p1.dx - 5, p1.dy + 15),
      Offset(p1.dx - 5, p3.dy - 10),
      wallPaint,
    );

    // Wall pattern
    for (int i = 0; i < 5; i++) {
      final y = p1.dy + 10 - i * 20;
      if (y > p3.dy) {
        canvas.drawLine(
          Offset(p1.dx - 10, y),
          Offset(p1.dx - 5, y - 5),
          wallPaint..strokeWidth = 1,
        );
      }
    }

    // Ground line
    final groundPaint = Paint()
      ..color = isDark ? Colors.grey.shade600 : Colors.grey.shade400
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(p1.dx - 20, p1.dy),
      Offset(p2.dx + 20, p2.dy),
      groundPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Widget për vizualizimin e dy zareve
class DiceVisualization extends StatefulWidget {
  final bool isDark;

  const DiceVisualization({super.key, required this.isDark});

  @override
  State<DiceVisualization> createState() => _DiceVisualizationState();
}

class _DiceVisualizationState extends State<DiceVisualization> {
  int dice1 = 1;
  int dice2 = 6;

  void _rollDice() {
    setState(() {
      dice1 = math.Random().nextInt(6) + 1;
      dice2 = math.Random().nextInt(6) + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sum = dice1 + dice2;
    final isTarget = sum == 7;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDice(dice1),
              const SizedBox(width: 20),
              Text(
                '+',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(width: 20),
              _buildDice(dice2),
              const SizedBox(width: 20),
              Text(
                '=',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isTarget ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isTarget ? Colors.green : Colors.grey,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$sum',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isTarget ? Colors.green : (widget.isDark ? Colors.white : Colors.black),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _rollDice,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: widget.isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.casino,
                    size: 18,
                    color: widget.isDark ? Colors.white70 : Colors.black54,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Hidh zaret',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: widget.isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isTarget)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '🎯 Shuma është 7!',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDice(int value) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.white : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _DicePainter(value: value),
      ),
    );
  }
}

class _DicePainter extends CustomPainter {
  final int value;

  _DicePainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final dotRadius = 5.0;
    final center = Offset(size.width / 2, size.height / 2);
    final offset = 15.0;

    // Dot positions based on value
    final positions = <Offset>[];
    
    switch (value) {
      case 1:
        positions.add(center);
        break;
      case 2:
        positions.add(Offset(center.dx - offset, center.dy - offset));
        positions.add(Offset(center.dx + offset, center.dy + offset));
        break;
      case 3:
        positions.add(Offset(center.dx - offset, center.dy - offset));
        positions.add(center);
        positions.add(Offset(center.dx + offset, center.dy + offset));
        break;
      case 4:
        positions.add(Offset(center.dx - offset, center.dy - offset));
        positions.add(Offset(center.dx + offset, center.dy - offset));
        positions.add(Offset(center.dx - offset, center.dy + offset));
        positions.add(Offset(center.dx + offset, center.dy + offset));
        break;
      case 5:
        positions.add(Offset(center.dx - offset, center.dy - offset));
        positions.add(Offset(center.dx + offset, center.dy - offset));
        positions.add(center);
        positions.add(Offset(center.dx - offset, center.dy + offset));
        positions.add(Offset(center.dx + offset, center.dy + offset));
        break;
      case 6:
        positions.add(Offset(center.dx - offset, center.dy - offset));
        positions.add(Offset(center.dx + offset, center.dy - offset));
        positions.add(Offset(center.dx - offset, center.dy));
        positions.add(Offset(center.dx + offset, center.dy));
        positions.add(Offset(center.dx - offset, center.dy + offset));
        positions.add(Offset(center.dx + offset, center.dy + offset));
        break;
    }

    for (final pos in positions) {
      canvas.drawCircle(pos, dotRadius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Widget për vizualizimin e ekuacionit kuadratik (parabolë)
class QuadraticVisualization extends StatelessWidget {
  final bool isDark;

  const QuadraticVisualization({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      child: CustomPaint(
        size: const Size(double.infinity, 160),
        painter: _QuadraticPainter(isDark: isDark),
      ),
    );
  }
}

class _QuadraticPainter extends CustomPainter {
  final bool isDark;

  _QuadraticPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = isDark ? Colors.white30 : Colors.black26
      ..strokeWidth = 1;

    final curvePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final rootPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height * 0.7;
    final scale = 25.0;

    // Draw axes
    canvas.drawLine(
      Offset(20, centerY),
      Offset(size.width - 20, centerY),
      axisPaint,
    );
    canvas.drawLine(
      Offset(centerX, 10),
      Offset(centerX, size.height - 10),
      axisPaint,
    );

    // Draw parabola: y = x² - 5x + 6 = (x-2)(x-3)
    // Roots at x=2, x=3
    // Vertex at x=2.5, y=-0.25
    final path = Path();
    bool started = false;

    for (double x = 0; x <= 5; x += 0.1) {
      final y = x * x - 5 * x + 6;
      final screenX = centerX + (x - 2.5) * scale;
      final screenY = centerY - y * scale;

      if (!started) {
        path.moveTo(screenX, screenY);
        started = true;
      } else {
        path.lineTo(screenX, screenY);
      }
    }
    canvas.drawPath(path, curvePaint);

    // Draw roots
    final root1X = centerX + (2 - 2.5) * scale;
    final root2X = centerX + (3 - 2.5) * scale;
    
    canvas.drawCircle(Offset(root1X, centerY), 6, rootPaint);
    canvas.drawCircle(Offset(root2X, centerY), 6, rootPaint);

    // Labels
    void drawLabel(String text, Offset position, Color color) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, position);
    }

    drawLabel('x=2', Offset(root1X - 12, centerY + 8), Colors.green);
    drawLabel('x=3', Offset(root2X - 12, centerY + 8), Colors.green);
    drawLabel('y', Offset(centerX + 5, 12), isDark ? Colors.white54 : Colors.black45);
    drawLabel('x', Offset(size.width - 18, centerY - 15), isDark ? Colors.white54 : Colors.black45);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Widget për vizualizimin e vargjeve aritmetike
class SequenceVisualization extends StatelessWidget {
  final bool isDark;

  const SequenceVisualization({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Vargu: a₁=5, d=3 → 5, 8, 11, 14, 17, 20, ...
    final a1 = 5.0;
    final d = 3.0;
    final terms = List.generate(7, (i) => a1 + i * d);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Term boxes
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < terms.length; i++) ...[
                  Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: (i == 4 || i == 5)
                              ? Colors.orange.withOpacity(0.2)
                              : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: (i == 4 || i == 5)
                                ? Colors.orange
                                : (isDark ? Colors.white24 : Colors.black12),
                            width: (i == 4 || i == 5) ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${terms[i].toInt()}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: (i == 4 || i == 5)
                                  ? Colors.orange
                                  : (isDark ? Colors.white : Colors.black),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'a${i + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                  if (i < terms.length - 1) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Column(
                        children: [
                          Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: Colors.green,
                          ),
                          Text(
                            '+3',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Formula
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.blue.withOpacity(0.15) : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'aₙ = a₁ + (n-1)·d = 5 + (n-1)·3',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget për vizualizimin e logaritmit
class LogarithmVisualization extends StatelessWidget {
  final bool isDark;

  const LogarithmVisualization({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Powers of 2 visualization
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i <= 4; i++) ...[
                Column(
                  children: [
                    Container(
                      width: 50,
                      height: 40,
                      decoration: BoxDecoration(
                        color: i == 3 ? Colors.green.withOpacity(0.2) : 
                               (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: i == 3 ? Colors.green : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${math.pow(2, i).toInt()}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: i == 3 ? Colors.green : (isDark ? Colors.white : Colors.black),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '2${'⁰¹²³⁴'[i]}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
                if (i < 4) const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 16),
          // Equation breakdown
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.purple.withOpacity(0.15) : Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'log₂(x) + log₂(x-2) = 3',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '↓',
                  style: TextStyle(
                    fontSize: 20,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
                Text(
                  'log₂(x·(x-2)) = 3',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                Text(
                  '↓',
                  style: TextStyle(
                    fontSize: 20,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
                Text(
                  'x·(x-2) = 2³ = 8',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Funksion që kthen vizualizimin e duhur bazuar në ID të sfidës
Widget? getVisualizationForChallenge(String challengeId, bool isDark) {
  switch (challengeId) {
    case 'mat_1':
      return QuadraticVisualization(isDark: isDark);
    case 'mat_2':
      return PythagorasVisualization(isDark: isDark);
    case 'mat_3':
      return DiceVisualization(isDark: isDark);
    case 'mat_4':
      return LogarithmVisualization(isDark: isDark);
    case 'mat_5':
      return SequenceVisualization(isDark: isDark);
    default:
      return null;
  }
}
