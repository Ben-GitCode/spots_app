import 'package:flutter/material.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class Achievement {
  const Achievement({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

// ── Sample data ───────────────────────────────────────────────────────────────

const List<Achievement> _achievements = [
  Achievement(
    title: 'First Steps',
    description: 'Visited your very first city.',
    icon: Icons.place,
  ),
  Achievement(
    title: 'Globetrotter',
    description: 'Explored cities in 5 different countries.',
    icon: Icons.public,
  ),
  Achievement(
    title: 'Event Chaser',
    description: 'Attended 3 local events during your travels.',
    icon: Icons.event,
  ),
  Achievement(
    title: 'Continent Hopper',
    description: 'Set foot on 3 different continents.',
    icon: Icons.flight,
  ),
  Achievement(
    title: 'Night Owl',
    description: 'Logged a visit after midnight.',
    icon: Icons.nightlight_round,
  ),
  Achievement(
    title: 'Stamp Collector',
    description: 'Collected 20 passport stamps.',
    icon: Icons.collections_bookmark,
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  // ── Theme colours (match rest of Passport app) ──────────────────────────────
  static const Color _navy = Color(0xFF1B2A4A);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _cream = Color(0xFFF5F0E8);
  static const Color _stampBorder = Color(0xFFB8A898);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: Stack(
        children: [
          // Wavy background pattern
          const Positioned.fill(child: _WavyBackground()),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                const _SortFilterBar(),
                Expanded(
                  child: _buildStampGrid(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: _navy,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
            ),
          ),
          const Text(
            'Passport',
            style: TextStyle(
              color: _gold,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // ── Stamp grid ─────────────────────────────────────────────────────────────

  Widget _buildStampGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _achievements.length,
      itemBuilder: (context, index) =>
          _StampTile(achievement: _achievements[index]),
    );
  }
}

// ── Sort / Filter bar ─────────────────────────────────────────────────────────

class _SortFilterBar extends StatelessWidget {
  const _SortFilterBar();

  static const Color _navy = AchievementsScreen._navy;
  static const Color _gold = AchievementsScreen._gold;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _navy,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _barButton(
              label: 'Sort',
              trailing: const Icon(Icons.keyboard_arrow_down,
                  color: _gold, size: 18),
              onTap: () {},
            ),
          ),
          Container(width: 1, height: 20, color: Colors.white30),
          Expanded(
            child: _barButton(
              label: 'Filter',
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _barButton({
    required String label,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _gold,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 2),
            trailing,
          ],
        ],
      ),
    );
  }
}

// ── Stamp tile ─────────────────────────────────────────────────────────────────

class _StampTile extends StatelessWidget {
  const _StampTile({required this.achievement});

  final Achievement achievement;

  static const Color _navy = AchievementsScreen._navy;
  static const Color _gold = AchievementsScreen._gold;
  static const Color _stampBorder = AchievementsScreen._stampBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _stampBorder.withOpacity(0.4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Passport stamp circle
          _StampCircle(icon: achievement.icon),
          const SizedBox(height: 12),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              achievement.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _navy,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              achievement.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _navy.withOpacity(0.6),
                fontSize: 11,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stamp circle graphic ───────────────────────────────────────────────────────

class _StampCircle extends StatelessWidget {
  const _StampCircle({required this.icon});

  final IconData icon;

  static const Color _navy = AchievementsScreen._navy;
  static const Color _gold = AchievementsScreen._gold;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(80, 80),
      painter: _StampPainter(),
      child: SizedBox(
        width: 80,
        height: 80,
        child: Center(
          child: Icon(icon, color: _navy, size: 32),
        ),
      ),
    );
  }
}

// ── Stamp painter (dashed outer ring + inner ring) ─────────────────────────────

class _StampPainter extends CustomPainter {
  static const Color _navy = AchievementsScreen._navy;
  static const Color _gold = AchievementsScreen._gold;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 2;
    final innerRadius = outerRadius - 10;

    // Solid inner circle fill
    canvas.drawCircle(
      center,
      innerRadius - 2,
      Paint()..color = _gold.withOpacity(0.12),
    );

    // Inner ring
    canvas.drawCircle(
      center,
      innerRadius,
      Paint()
        ..color = _navy
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Outer dashed ring
    _drawDashedCircle(canvas, center, outerRadius, _navy);
  }

  void _drawDashedCircle(
      Canvas canvas, Offset center, double radius, Color color) {
    const dashCount = 36;
    const dashAngle = 0.12;
    const gapAngle = (2 * 3.14159265) / dashCount - dashAngle;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    double angle = 0;
    for (int i = 0; i < dashCount; i++) {
      final startAngle = angle;
      final sweepAngle = dashAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      angle += dashAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Wavy background ────────────────────────────────────────────────────────────

class _WavyBackground extends StatelessWidget {
  const _WavyBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WavyPainter(),
    );
  }
}

class _WavyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD6CCBB).withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const waveHeight = 8.0;
    const waveLength = 60.0;
    const spacing = 22.0;

    int lineCount = (size.height / spacing).ceil() + 1;

    for (int i = 0; i < lineCount; i++) {
      final y = i * spacing;
      final path = Path();
      path.moveTo(0, y.toDouble());

      double x = 0;
      bool up = true;
      while (x < size.width) {
        path.relativeQuadraticBezierTo(
          waveLength / 2,
          up ? -waveHeight : waveHeight,
          waveLength,
          0,
        );
        x += waveLength;
        up = !up;
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}