import 'dart:ui'; // Needed for PathMetrics
import 'package:flutter/material.dart';

// 1. DATA MODELS
enum TraceType { reaction, moment, tag, group }

class Trace {
  final TraceType type;
  final String username;
  final String message;
  final String? time;
  final Color avatarColor;
  final String? initial;
  final bool isGradient;
  final TraceAttachment? attachment;

  Trace({
    required this.type,
    required this.username,
    required this.message,
    this.time,
    this.avatarColor = Colors.grey,
    this.initial,
    this.isGradient = false,
    this.attachment,
  });
}

class TraceAttachment {
  final String imageUrl;
  final String title;
  final String subtitle;
  final String location;

  TraceAttachment({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.location,
  });
}

// 2. MAIN SCREEN
class TracesScreen extends StatelessWidget {
  const TracesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // MOCK DATA
    final List<Trace> traces = [
      Trace(
        type: TraceType.reaction,
        username: "System",
        message: "You have 12 new reactions to your moment in Tel Aviv",
        avatarColor: Colors.blueAccent,
        isGradient: true,
      ),
      Trace(
        type: TraceType.moment,
        username: "daniel_davidson",
        message: "left a moment at Tokyo",
        initial: "d",
        avatarColor: const Color(0xFF7CB342),
      ),
      Trace(
        type: TraceType.tag,
        username: "ben_liberman",
        message: "tagged you in a shared moment. Add to your map",
        initial: "b",
        avatarColor: const Color(0xFF5C6BC0),
        attachment: TraceAttachment(
          imageUrl: "https://picsum.photos/200",
          title: "ben_liberman",
          subtitle: "+5 Others",
          location: "Expo Tel Aviv",
        ),
      ),
      Trace(
        type: TraceType.group,
        username: "tsion_sayada",
        message: 'added you to private group "Sigmas"',
        initial: "t",
        avatarColor: const Color(0xFFA1887F),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Traces",
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: traces.length,
        itemBuilder: (context, index) {
          return _TraceItemWidget(
            trace: traces[index],
            isLast: index == traces.length - 1,
            // Pass index to alternate curve direction if you want a "Snake" look later
            index: index,
          );
        },
      ),
    );
  }
}

// 3. THE SMART LIST ITEM
class _TraceItemWidget extends StatelessWidget {
  final Trace trace;
  final bool isLast;
  final int index;

  const _TraceItemWidget({
    required this.trace,
    required this.isLast,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- LEFT RAIL ---
          SizedBox(
            width: 50,
            child: Column(
              children: [
                _buildAvatar(),

                // CASE 1: Normal Items (Snake Line)
                if (!isLast)
                  Expanded(
                    child: CustomPaint(
                      // 🔹 Pass 'isEven' to flip direction
                      painter: _PathPainter(isEven: index.isEven),
                      child: Container(),
                    ),
                  ),

                // CASE 2: The Last Item (End Cap)
                if (isLast) ...[
                  const SizedBox(height: 4),
                  CustomPaint(
                    size: const Size(1, 20),
                    painter: _StraightDashedLine(),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.directions_walk,
                    size: 30,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),

          // --- RIGHT CONTENT ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30.0, left: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRichText(),
                  if (trace.attachment != null) ...[
                    const SizedBox(height: 12),
                    _buildAttachmentCard(trace.attachment!),
                  ],
                  const SizedBox(height: 8),
                  Divider(
                    color: Colors.grey[300],
                    thickness: 2,
                  ), // Thicker lines
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ... (Keep _buildAvatar, _buildRichText, _buildAttachmentCard exactly the same) ...
  Widget _buildAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: trace.isGradient ? null : trace.avatarColor,
        gradient: trace.isGradient
            ? const LinearGradient(
                colors: [Color(0xFF91C5F2), Color(0xFFF2A7E6)],
              )
            : null,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: trace.initial != null
            ? Text(
                trace.initial!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildRichText() {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
          height: 1.4,
          fontFamily: 'Arial',
        ),
        children: [
          if (trace.username != "System")
            TextSpan(
              text: "${trace.username} ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          TextSpan(text: trace.message),
        ],
      ),
    );
  }

  Widget _buildAttachmentCard(TraceAttachment att) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              att.imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (c, o, s) => Container(
                width: 60,
                height: 60,
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  att.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  att.subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      att.location,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// // 4. THE CUSTOM PAINTER (Curved & Dashed)
// class _PathPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     Paint paint = Paint()
//       ..color = Colors.grey[400]!
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2
//       ..strokeCap = StrokeCap.round;

//     Path path = Path();

//     // START: Top Center (Directly below the current avatar)
//     path.moveTo(size.width / 2, 0);

//     // END: Bottom Center (Directly above the next avatar)
//     // CURVE: A cubic bezier curve that wiggles slightly
//     path.cubicTo(
//       size.width * 0.1,
//       size.height * 0.3, // Control Point 1 (Curve Left)
//       size.width * 0.9,
//       size.height * 0.7, // Control Point 2 (Curve Right)
//       size.width / 2,
//       size.height, // End Point
//     );

//     // DRAW DASHED LINE
//     // PathMetrics lets us measure the path and chop it into dashes
//     final PathMetrics pathMetrics = path.computeMetrics();
//     for (PathMetric pathMetric in pathMetrics) {
//       double distance = 0.0;
//       const double dashWidth = 6.0; // Length of dash
//       const double dashSpace = 4.0; // Length of gap

//       while (distance < pathMetric.length) {
//         // Draw a segment
//         canvas.drawPath(
//           pathMetric.extractPath(distance, distance + dashWidth),
//           paint,
//         );
//         // Skip ahead
//         distance += dashWidth + dashSpace;
//       }
//     }
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => false;
// }

// 4. THE SMOOTH SNAKE PAINTER 🐍
class _PathPainter extends CustomPainter {
  final bool isEven;

  _PathPainter({required this.isEven});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.grey[400]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    Path path = Path();

    // START: Top Center
    path.moveTo(size.width / 2, 0);

    // LOGIC:
    // We want a smooth S-curve.
    // If Even: Curve Left -> Right
    // If Odd:  Curve Right -> Left

    // Amount of horizontal wiggle (keep it subtle, e.g., 15px)
    double wiggle = 25.0;
    double dir = isEven ? -1.0 : 1.0;

    // CUBIC BEZIER (The smoothest S-curve)
    path.cubicTo(
      // Control Point 1: Pushes out horizontally from the start
      (size.width / 2) + (wiggle * dir),
      size.height * 0.3,

      // Control Point 2: Pushes out horizontally from the end (opposite side)
      (size.width / 2) - (wiggle * dir),
      size.height * 0.7,

      // End Point: Bottom Center
      size.width / 2,
      size.height,
    );

    // DRAW DASHED LINE LOGIC
    final PathMetrics pathMetrics = path.computeMetrics();
    for (PathMetric pathMetric in pathMetrics) {
      double distance = 0.0;
      const double dashWidth = 6.0;
      const double dashSpace = 4.0;

      while (distance < pathMetric.length) {
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _StraightDashedLine extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const double dashWidth = 4;
    const double dashSpace = 4;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashWidth), paint);
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
