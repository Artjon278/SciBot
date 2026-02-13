import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Widget për të shfaqur formula matematikore me stil të bukur
class FormulaCard extends StatelessWidget {
  final String formula;
  final String? label;
  final Color color;

  const FormulaCard({
    super.key,
    required this.formula,
    this.label,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            formula,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Ilustrim i Teoremës së Pitagorës
class PythagorasIllustration extends StatelessWidget {
  const PythagorasIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: 200,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: CustomPaint(
        painter: _PythagorasPainter(),
        size: const Size(double.infinity, 200),
      ),
    );
  }
}

class _PythagorasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.blue.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    // Trekëndëshi
    final path = Path();
    final startX = size.width * 0.2;
    final startY = size.height * 0.75;
    final width = size.width * 0.4;
    final height = size.height * 0.5;

    path.moveTo(startX, startY);
    path.lineTo(startX + width, startY);
    path.lineTo(startX, startY - height);
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);

    // Katroret në brinjët
    final smallSquare = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Katrori i këndit të drejtë
    canvas.drawRect(
      Rect.fromLTWH(startX, startY - 20, 20, 20),
      smallSquare,
    );

    // Labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // a
    textPainter.text = const TextSpan(
      text: 'a',
      style: TextStyle(color: Colors.blue, fontSize: 18, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(startX + width / 2 - 5, startY + 10));

    // b
    textPainter.text = const TextSpan(
      text: 'b',
      style: TextStyle(color: Colors.blue, fontSize: 18, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(startX - 20, startY - height / 2));

    // c
    textPainter.text = const TextSpan(
      text: 'c',
      style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(startX + width / 2 + 20, startY - height / 2 - 10));

    // Formula
    textPainter.text = const TextSpan(
      text: 'a² + b² = c²',
      style: TextStyle(color: Colors.blue, fontSize: 20, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.6, size.height * 0.4));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Ilustrim i Atomit
class AtomIllustration extends StatefulWidget {
  const AtomIllustration({super.key});

  @override
  State<AtomIllustration> createState() => _AtomIllustrationState();
}

class _AtomIllustrationState extends State<AtomIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
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
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: 180,
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _AtomPainter(_controller.value),
            size: const Size(double.infinity, 180),
          );
        },
      ),
    );
  }
}

class _AtomPainter extends CustomPainter {
  final double progress;
  _AtomPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.height * 0.35;

    // Bërthama
    final nucleusPaint = Paint()
      ..color = Colors.purple
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 15, nucleusPaint);

    // Orbitat
    final orbitPaint = Paint()
      ..color = Colors.purple.withOpacity(0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 3; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * math.pi / 3);
      canvas.scale(1, 0.3);
      canvas.drawCircle(Offset.zero, radius, orbitPaint);
      canvas.restore();
    }

    // Elektronet
    final electronPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      final angle = progress * 2 * math.pi + i * (2 * math.pi / 3);
      final orbitAngle = i * math.pi / 3;
      
      final x = center.dx + radius * math.cos(angle) * math.cos(orbitAngle);
      final y = center.dy + radius * math.cos(angle) * math.sin(orbitAngle) * 0.3 
                + radius * math.sin(angle) * 0.3;
      
      canvas.drawCircle(Offset(x, y), 6, electronPaint);
    }

    // Label
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Struktura e Atomit',
        style: TextStyle(color: Colors.purple, fontSize: 14, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, size.height - 25));
  }

  @override
  bool shouldRepaint(covariant _AtomPainter oldDelegate) => oldDelegate.progress != progress;
}

/// Ilustrim i ADN-së
class DNAIllustration extends StatefulWidget {
  const DNAIllustration({super.key});

  @override
  State<DNAIllustration> createState() => _DNAIllustrationState();
}

class _DNAIllustrationState extends State<DNAIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
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
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: 180,
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _DNAPainter(_controller.value),
            size: const Size(double.infinity, 180),
          );
        },
      ),
    );
  }
}

class _DNAPainter extends CustomPainter {
  final double progress;
  _DNAPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final amplitude = 40.0;
    final frequency = 2.0;

    final paint1 = Paint()
      ..color = Colors.green
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final paint2 = Paint()
      ..color = Colors.teal
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final basePaint = Paint()
      ..color = Colors.orange.withOpacity(0.6)
      ..strokeWidth = 2;

    final path1 = Path();
    final path2 = Path();

    final offset = progress * 2 * math.pi;

    for (double y = 20; y < size.height - 20; y += 1) {
      final x1 = centerX + amplitude * math.sin(frequency * y / 20 + offset);
      final x2 = centerX - amplitude * math.sin(frequency * y / 20 + offset);

      if (y == 20) {
        path1.moveTo(x1, y);
        path2.moveTo(x2, y);
      } else {
        path1.lineTo(x1, y);
        path2.lineTo(x2, y);
      }

      // Bazat (lidhjet)
      if (y.toInt() % 15 == 0) {
        canvas.drawLine(Offset(x1, y), Offset(x2, y), basePaint);
        
        // Nukleotidet
        canvas.drawCircle(Offset(x1, y), 4, Paint()..color = Colors.red);
        canvas.drawCircle(Offset(x2, y), 4, Paint()..color = Colors.blue);
      }
    }

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);

    // Label
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Spirale e Dyfishtë ADN',
        style: TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, size.height - 20));
  }

  @override
  bool shouldRepaint(covariant _DNAPainter oldDelegate) => oldDelegate.progress != progress;
}

/// Ilustrim i Ligjeve të Njutonit
class NewtonLawsIllustration extends StatelessWidget {
  const NewtonLawsIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildLaw('I', 'Ligji i Inercisë', 'Trupi qëndron në prehje ose lëviz drejtvizor nëse nuk veprojnë forca'),
          const Divider(),
          _buildLaw('II', 'F = m × a', 'Forca = Masa × Nxitimi'),
          const Divider(),
          _buildLaw('III', 'Aksion - Reaksion', 'Çdo veprimi i përgjigjet një kundërreaksion i barabartë'),
        ],
      ),
    );
  }

  Widget _buildLaw(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
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

/// Ilustrim i Tabelës Periodike (fragment)
class PeriodicTableIllustration extends StatelessWidget {
  const PeriodicTableIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.cyan.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Tabela Periodike',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.cyan,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildElement('H', '1', 'Hidrogjen', Colors.blue),
              _buildElement('He', '2', 'Helium', Colors.purple),
              _buildElement('Li', '3', 'Litium', Colors.red),
              _buildElement('Be', '4', 'Berilium', Colors.orange),
              _buildElement('B', '5', 'Bor', Colors.amber),
              _buildElement('C', '6', 'Karbon', Colors.grey),
              _buildElement('N', '7', 'Azot', Colors.blue),
              _buildElement('O', '8', 'Oksigjen', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildElement(String symbol, String number, String name, Color color) {
    return Container(
      width: 60,
      height: 70,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            number,
            style: TextStyle(fontSize: 10, color: color),
          ),
          Text(
            symbol,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            name,
            style: const TextStyle(fontSize: 8),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Funksion për të zgjedhur ilustrimin bazuar në përmbajtjen e mesazhit
Widget? getIllustrationForMessage(String message) {
  final lowerMessage = message.toLowerCase();
  
  if (lowerMessage.contains('pitagor') || lowerMessage.contains('trekëndësh')) {
    return const PythagorasIllustration();
  }
  
  if (lowerMessage.contains('atom') || lowerMessage.contains('elektron') || lowerMessage.contains('proton')) {
    return const AtomIllustration();
  }
  
  if (lowerMessage.contains('adn') || lowerMessage.contains('dna') || lowerMessage.contains('gjenetik')) {
    return const DNAIllustration();
  }
  
  if (lowerMessage.contains('njuton') || lowerMessage.contains('newton') || lowerMessage.contains('forca')) {
    return const NewtonLawsIllustration();
  }
  
  if (lowerMessage.contains('periodik') || lowerMessage.contains('element') || lowerMessage.contains('kimi')) {
    return const PeriodicTableIllustration();
  }
  
  // Formula të zakonshme
  if (lowerMessage.contains('a² + b² = c²') || lowerMessage.contains('a^2')) {
    return const FormulaCard(
      formula: 'a² + b² = c²',
      label: 'Teorema e Pitagorës',
      color: Colors.blue,
    );
  }
  
  if (lowerMessage.contains('e = mc')) {
    return const FormulaCard(
      formula: 'E = mc²',
      label: 'Ekuacioni i Ajnshtajnit',
      color: Colors.purple,
    );
  }
  
  if (lowerMessage.contains('f = ma') || lowerMessage.contains('f=ma')) {
    return const FormulaCard(
      formula: 'F = m × a',
      label: 'Ligji i Dytë i Njutonit',
      color: Colors.orange,
    );
  }
  
  return null;
}

/// Karta për koncept me ikonë
class ConceptCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const ConceptCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black54,
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
