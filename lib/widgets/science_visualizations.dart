import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Vizualizimi i strukturës së atomit
class AtomStructureVisualization extends StatefulWidget {
  final int protons;
  final int neutrons;
  final int electrons;
  final bool isDark;

  const AtomStructureVisualization({
    super.key,
    this.protons = 17,
    this.neutrons = 18,
    this.electrons = 17,
    required this.isDark,
  });

  @override
  State<AtomStructureVisualization> createState() => _AtomStructureVisualizationState();
}

class _AtomStructureVisualizationState extends State<AtomStructureVisualization>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: const Size(double.infinity, 180),
            painter: _AtomPainter(
              protons: widget.protons,
              neutrons: widget.neutrons,
              electrons: widget.electrons,
              isDark: widget.isDark,
              animationValue: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _AtomPainter extends CustomPainter {
  final int protons;
  final int neutrons;
  final int electrons;
  final bool isDark;
  final double animationValue;

  _AtomPainter({
    required this.protons,
    required this.neutrons,
    required this.electrons,
    required this.isDark,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw nucleus
    final nucleusPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 25, nucleusPaint);

    // Draw nucleus label
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Cl',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );

    // Draw electron shells
    final shellPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Shell radii and electron counts: 2, 8, 7 for Chlorine
    final shells = [
      {'radius': 45.0, 'electrons': 2},
      {'radius': 65.0, 'electrons': 8},
      {'radius': 85.0, 'electrons': 7},
    ];

    for (var shell in shells) {
      canvas.drawCircle(center, shell['radius'] as double, shellPaint);
    }

    // Draw electrons
    final electronPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    int shellIndex = 0;
    for (var shell in shells) {
      final radius = shell['radius'] as double;
      final count = shell['electrons'] as int;
      final startAngle = animationValue * 2 * math.pi * (shellIndex % 2 == 0 ? 1 : -1);

      for (int i = 0; i < count; i++) {
        final angle = startAngle + (2 * math.pi * i / count);
        final x = center.dx + radius * math.cos(angle);
        final y = center.dy + radius * math.sin(angle);
        canvas.drawCircle(Offset(x, y), 5, electronPaint);
      }
      shellIndex++;
    }

    // Legend
    void drawLegend(String text, Color color, Offset position) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(position, 5, paint);
      
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(position.dx + 10, position.dy - 5));
    }

    drawLegend('Elektrone', Colors.blue, Offset(20, size.height - 30));
    drawLegend('Bërthamë', Colors.orange, Offset(20, size.height - 12));
  }

  @override
  bool shouldRepaint(covariant _AtomPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

/// Vizualizimi i ADN-së (Heliksi i dyfishtë)
class DNAVisualization extends StatefulWidget {
  final bool isDark;

  const DNAVisualization({super.key, required this.isDark});

  @override
  State<DNAVisualization> createState() => _DNAVisualizationState();
}

class _DNAVisualizationState extends State<DNAVisualization>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: const Size(double.infinity, 180),
            painter: _DNAPainter(
              isDark: widget.isDark,
              animationValue: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _DNAPainter extends CustomPainter {
  final bool isDark;
  final double animationValue;

  _DNAPainter({required this.isDark, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final startY = 20.0;
    final endY = size.height - 20;
    
    final basePairs = ['A-T', 'T-A', 'G-C', 'C-G', 'A-T', 'G-C', 'T-A', 'C-G'];
    final colors = {
      'A': Colors.red,
      'T': Colors.blue,
      'G': Colors.green,
      'C': Colors.orange,
    };

    final amplitude = 40.0;
    final offset = animationValue * 2 * math.pi;

    // Draw strands and base pairs
    for (int i = 0; i < basePairs.length; i++) {
      final y = startY + (endY - startY) * i / (basePairs.length - 1);
      final phase = offset + i * 0.8;
      
      final x1 = centerX + amplitude * math.sin(phase);
      final x2 = centerX - amplitude * math.sin(phase);

      // Base pair connection
      final pairPaint = Paint()
        ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.15)
        ..strokeWidth = 2;
      canvas.drawLine(Offset(x1, y), Offset(x2, y), pairPaint);

      // Nucleotides
      final pair = basePairs[i].split('-');
      
      // Left nucleotide
      final leftPaint = Paint()..color = colors[pair[0]]!;
      canvas.drawCircle(Offset(x1, y), 8, leftPaint);
      
      // Right nucleotide
      final rightPaint = Paint()..color = colors[pair[1]]!;
      canvas.drawCircle(Offset(x2, y), 8, rightPaint);

      // Labels
      void drawNucleotide(String label, Offset pos) {
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
      }

      drawNucleotide(pair[0], Offset(x1, y));
      drawNucleotide(pair[1], Offset(x2, y));
    }

    // Legend
    double legendY = size.height - 10;
    double legendX = 10.0;
    for (var entry in colors.entries) {
      final paint = Paint()..color = entry.value;
      canvas.drawCircle(Offset(legendX, legendY), 6, paint);
      
      final tp = TextPainter(
        text: TextSpan(
          text: entry.key,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(legendX + 10, legendY - 5));
      legendX += 35;
    }
  }

  @override
  bool shouldRepaint(covariant _DNAPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

/// Vizualizimi i qelizës
class CellVisualization extends StatelessWidget {
  final bool isDark;

  const CellVisualization({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: CustomPaint(
        size: const Size(double.infinity, 180),
        painter: _CellPainter(isDark: isDark),
      ),
    );
  }
}

class _CellPainter extends CustomPainter {
  final bool isDark;

  _CellPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Cell membrane
    final membranePaint = Paint()
      ..color = Colors.green.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    final membraneStroke = Paint()
      ..color = Colors.green
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawOval(
      Rect.fromCenter(center: center, width: 200, height: 140),
      membranePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 200, height: 140),
      membraneStroke,
    );

    // Nucleus
    final nucleusPaint = Paint()
      ..color = Colors.purple.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    
    final nucleusStroke = Paint()
      ..color = Colors.purple
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, 35, nucleusPaint);
    canvas.drawCircle(center, 35, nucleusStroke);

    // Nucleolus
    final nucleolusPaint = Paint()
      ..color = Colors.purple.shade700
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx + 5, center.dy - 5), 10, nucleolusPaint);

    // Mitochondria
    final mitoPaint = Paint()
      ..color = Colors.red.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    
    canvas.save();
    canvas.translate(center.dx + 60, center.dy - 20);
    canvas.rotate(0.3);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 35, height: 18),
      mitoPaint,
    );
    canvas.restore();

    canvas.save();
    canvas.translate(center.dx - 55, center.dy + 25);
    canvas.rotate(-0.4);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 30, height: 15),
      mitoPaint,
    );
    canvas.restore();

    // Ribosomes (small dots)
    final riboPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final random = math.Random(42);
    for (int i = 0; i < 15; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final dist = 50 + random.nextDouble() * 40;
      final x = center.dx + dist * math.cos(angle);
      final y = center.dy + dist * math.sin(angle) * 0.7;
      canvas.drawCircle(Offset(x, y), 3, riboPaint);
    }

    // Labels
    void drawLabel(String text, Offset position, Color color) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, position);
    }

    drawLabel('Bërthamë', Offset(center.dx - 22, center.dy + 40), Colors.purple);
    drawLabel('Membranë', Offset(center.dx + 70, center.dy - 60), Colors.green);
    drawLabel('Mitokondri', Offset(center.dx + 50, center.dy - 8), Colors.red);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Vizualizimi i ligjit të Njutonit (Forca dhe lëvizja)
class NewtonLawVisualization extends StatefulWidget {
  final bool isDark;

  const NewtonLawVisualization({super.key, required this.isDark});

  @override
  State<NewtonLawVisualization> createState() => _NewtonLawVisualizationState();
}

class _NewtonLawVisualizationState extends State<NewtonLawVisualization>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: const Size(double.infinity, 140),
            painter: _NewtonPainter(
              isDark: widget.isDark,
              animationValue: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _NewtonPainter extends CustomPainter {
  final bool isDark;
  final double animationValue;

  _NewtonPainter({required this.isDark, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    // Ground
    final groundPaint = Paint()
      ..color = isDark ? Colors.grey.shade700 : Colors.grey.shade400
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(20, size.height - 30),
      Offset(size.width - 20, size.height - 30),
      groundPaint,
    );

    // Box position (animated)
    final boxX = 60 + (size.width - 160) * animationValue;
    final boxSize = 40.0;

    // Box
    final boxPaint = Paint()
      ..color = Colors.blue.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(boxX, size.height - 30 - boxSize, boxSize, boxSize),
      boxPaint,
    );

    // Mass label on box
    final massText = TextPainter(
      text: TextSpan(
        text: 'm',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    massText.paint(
      canvas,
      Offset(boxX + boxSize / 2 - 5, size.height - 30 - boxSize / 2 - 8),
    );

    // Force arrow
    final arrowPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final arrowStart = Offset(boxX + boxSize, size.height - 30 - boxSize / 2);
    final arrowEnd = Offset(boxX + boxSize + 50, size.height - 30 - boxSize / 2);
    
    canvas.drawLine(arrowStart, arrowEnd, arrowPaint);
    
    // Arrow head
    final arrowHeadPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    
    final path = Path()
      ..moveTo(arrowEnd.dx, arrowEnd.dy)
      ..lineTo(arrowEnd.dx - 10, arrowEnd.dy - 5)
      ..lineTo(arrowEnd.dx - 10, arrowEnd.dy + 5)
      ..close();
    canvas.drawPath(path, arrowHeadPaint);

    // Force label
    final forceText = TextPainter(
      text: TextSpan(
        text: 'F',
        style: TextStyle(
          color: Colors.red,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    forceText.paint(canvas, Offset(arrowEnd.dx - 25, arrowEnd.dy - 20));

    // Formula
    final formulaText = TextPainter(
      text: TextSpan(
        text: 'F = m × a',
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    formulaText.paint(canvas, Offset(size.width / 2 - 40, 10));
  }

  @override
  bool shouldRepaint(covariant _NewtonPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

/// Vizualizimi i qarqeve elektrike
class CircuitVisualization extends StatelessWidget {
  final bool isDark;

  const CircuitVisualization({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      child: CustomPaint(
        size: const Size(double.infinity, 160),
        painter: _CircuitPainter(isDark: isDark),
      ),
    );
  }
}

class _CircuitPainter extends CustomPainter {
  final bool isDark;

  _CircuitPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final wirePaint = Paint()
      ..color = isDark ? Colors.white70 : Colors.black54
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw circuit rectangle
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(centerX, centerY), width: 180, height: 100),
      const Radius.circular(10),
    );
    canvas.drawRRect(rect, wirePaint);

    // Battery
    final batteryX = centerX - 90;
    final batteryY = centerY;
    
    // Long line (positive)
    canvas.drawLine(
      Offset(batteryX - 8, batteryY - 15),
      Offset(batteryX - 8, batteryY + 15),
      Paint()..color = Colors.red..strokeWidth = 3,
    );
    // Short line (negative)
    canvas.drawLine(
      Offset(batteryX + 5, batteryY - 8),
      Offset(batteryX + 5, batteryY + 8),
      Paint()..color = Colors.black..strokeWidth = 2,
    );

    // Resistor (zigzag)
    final resistorX = centerX + 60;
    final resistorY = centerY - 50;
    final resistorPaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final zigzag = Path()
      ..moveTo(resistorX - 20, resistorY)
      ..lineTo(resistorX - 15, resistorY - 8)
      ..lineTo(resistorX - 5, resistorY + 8)
      ..lineTo(resistorX + 5, resistorY - 8)
      ..lineTo(resistorX + 15, resistorY + 8)
      ..lineTo(resistorX + 20, resistorY);
    canvas.drawPath(zigzag, resistorPaint);

    // Light bulb
    final bulbX = centerX + 60;
    final bulbY = centerY + 50;
    
    canvas.drawCircle(
      Offset(bulbX, bulbY),
      12,
      Paint()..color = Colors.yellow.withOpacity(0.5)..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(bulbX, bulbY),
      12,
      Paint()..color = Colors.yellow..strokeWidth = 2..style = PaintingStyle.stroke,
    );

    // Labels
    void drawLabel(String text, Offset pos) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos);
    }

    drawLabel('V', Offset(batteryX - 20, batteryY + 20));
    drawLabel('R', Offset(resistorX - 5, resistorY + 12));
    drawLabel('💡', Offset(bulbX - 8, bulbY + 15));

    // Formula
    final formula = TextPainter(
      text: TextSpan(
        text: 'V = I × R',
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    formula.paint(canvas, Offset(20, 10));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Vizualizimi i energjisë kinetike dhe potenciale
class EnergyVisualization extends StatefulWidget {
  final bool isDark;

  const EnergyVisualization({super.key, required this.isDark});

  @override
  State<EnergyVisualization> createState() => _EnergyVisualizationState();
}

class _EnergyVisualizationState extends State<EnergyVisualization>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: const Size(double.infinity, 160),
            painter: _EnergyPainter(
              isDark: widget.isDark,
              animationValue: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _EnergyPainter extends CustomPainter {
  final bool isDark;
  final double animationValue;

  _EnergyPainter({required this.isDark, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    // Pendulum visualization
    final pivotX = size.width / 2;
    final pivotY = 20.0;
    final length = 80.0;
    
    // Angle based on animation (-45 to 45 degrees)
    final angle = (animationValue - 0.5) * math.pi / 2;
    
    final ballX = pivotX + length * math.sin(angle);
    final ballY = pivotY + length * math.cos(angle);

    // String
    final stringPaint = Paint()
      ..color = isDark ? Colors.white54 : Colors.black38
      ..strokeWidth = 2;
    canvas.drawLine(Offset(pivotX, pivotY), Offset(ballX, ballY), stringPaint);

    // Pivot
    canvas.drawCircle(
      Offset(pivotX, pivotY),
      5,
      Paint()..color = isDark ? Colors.white : Colors.black,
    );

    // Ball
    final ballPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(ballX, ballY), 15, ballPaint);

    // Energy bars
    final barWidth = 30.0;
    final barMaxHeight = 60.0;
    
    // Potential energy (max at sides, min at center)
    final peHeight = barMaxHeight * (1 - math.cos(angle).abs());
    
    // Kinetic energy (max at center, min at sides)
    final keHeight = barMaxHeight * math.cos(angle).abs();

    // PE bar
    final peBarX = size.width - 80;
    final peBarY = size.height - 20;
    canvas.drawRect(
      Rect.fromLTWH(peBarX, peBarY - peHeight, barWidth, peHeight),
      Paint()..color = Colors.green,
    );
    canvas.drawRect(
      Rect.fromLTWH(peBarX, peBarY - barMaxHeight, barWidth, barMaxHeight),
      Paint()..color = Colors.green.withOpacity(0.2)..style = PaintingStyle.stroke..strokeWidth = 1,
    );

    // KE bar  
    final keBarX = size.width - 40;
    canvas.drawRect(
      Rect.fromLTWH(keBarX, peBarY - keHeight, barWidth, keHeight),
      Paint()..color = Colors.red,
    );
    canvas.drawRect(
      Rect.fromLTWH(keBarX, peBarY - barMaxHeight, barWidth, barMaxHeight),
      Paint()..color = Colors.red.withOpacity(0.2)..style = PaintingStyle.stroke..strokeWidth = 1,
    );

    // Labels
    void drawLabel(String text, Offset pos, Color color) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos);
    }

    drawLabel('PE', Offset(peBarX + 5, size.height - 12), Colors.green);
    drawLabel('KE', Offset(keBarX + 5, size.height - 12), Colors.red);

    // Formula
    final formula = TextPainter(
      text: TextSpan(
        text: 'E = PE + KE',
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    formula.paint(canvas, Offset(20, 10));
  }

  @override
  bool shouldRepaint(covariant _EnergyPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

/// Vizualizimi i valëve zanore
class WaveVisualization extends StatefulWidget {
  final bool isDark;

  const WaveVisualization({super.key, required this.isDark});

  @override
  State<WaveVisualization> createState() => _WaveVisualizationState();
}

class _WaveVisualizationState extends State<WaveVisualization>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(16),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: const Size(double.infinity, 130),
            painter: _WavePainter(
              isDark: widget.isDark,
              animationValue: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final bool isDark;
  final double animationValue;

  _WavePainter({required this.isDark, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2 + 10;
    final amplitude = 30.0;
    final wavelength = size.width / 2;
    
    // Axis
    final axisPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.2)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(20, centerY),
      Offset(size.width - 20, centerY),
      axisPaint,
    );

    // Wave
    final wavePaint = Paint()
      ..color = Colors.purple
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    final offset = animationValue * 2 * math.pi;

    for (double x = 20; x < size.width - 20; x += 1) {
      final y = centerY - amplitude * math.sin((x / wavelength) * 2 * math.pi + offset);
      if (x == 20) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, wavePaint);

    // Amplitude arrow
    final arrowPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2;
    
    final midX = size.width / 2;
    canvas.drawLine(
      Offset(midX, centerY),
      Offset(midX, centerY - amplitude),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(midX - 5, centerY - amplitude + 8),
      Offset(midX, centerY - amplitude),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(midX + 5, centerY - amplitude + 8),
      Offset(midX, centerY - amplitude),
      arrowPaint,
    );

    // Labels
    final ampLabel = TextPainter(
      text: TextSpan(
        text: 'A',
        style: TextStyle(
          color: Colors.green,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    ampLabel.paint(canvas, Offset(midX + 8, centerY - amplitude / 2 - 6));

    // Formula
    final formula = TextPainter(
      text: TextSpan(
        text: 'v = f × λ',
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    formula.paint(canvas, Offset(20, 5));
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
