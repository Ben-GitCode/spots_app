import 'package:flutter/material.dart';
import 'package:spots_app/utils/models.dart';

// class OverlappingReactionStack extends StatelessWidget {
//   final List<SpotReactions> reactions;
//   final int? totalReactions;
//   final double scale;
//   final double outlineWidth;
//   final Color outlineColor;
//   final Color counterTextColor;

//   const OverlappingReactionStack({
//     super.key,
//     required this.reactions,
//     this.totalReactions,
//     this.scale = 1.0,
//     this.outlineWidth = 2.5,
//     this.outlineColor = Colors.white,
//     this.counterTextColor = Colors.black87,
//   });

//   String _formatReactionsCount(int count) {
//     if (count >= 1000000)
//       return '${(count / 1000000).toStringAsFixed(count % 1000000 == 0 ? 0 : 1)}M';
//     if (count >= 1000)
//       return '${(count / 1000).toStringAsFixed(count % 1000 == 0 ? 0 : 1)}K';
//     return count.toString();
//   }

//   Widget _buildOutlinedImage(String assetPath, double size) {
//     final offsets = [
//       Offset(-outlineWidth, -outlineWidth),
//       Offset(outlineWidth, -outlineWidth),
//       Offset(outlineWidth, outlineWidth),
//       Offset(-outlineWidth, outlineWidth),
//       Offset(0, -outlineWidth),
//       Offset(0, outlineWidth),
//       Offset(-outlineWidth, 0),
//       Offset(outlineWidth, 0),
//     ];

//     // 🔹 Fixes the "Smudge" bug: Only draws shadows if width > 0 AND color is fully opaque
//     bool drawOutline = outlineWidth > 0 && outlineColor.alpha == 255;

//     return Stack(
//       alignment: Alignment.center,
//       children: [
//         if (drawOutline)
//           for (var offset in offsets)
//             Positioned(
//               left: offset.dx + outlineWidth,
//               top: offset.dy + outlineWidth,
//               child: ColorFiltered(
//                 colorFilter: ColorFilter.mode(outlineColor, BlendMode.srcIn),
//                 child: Image.asset(assetPath, width: size, height: size),
//               ),
//             ),
//         Positioned(
//           left: drawOutline ? outlineWidth : 0,
//           top: drawOutline ? outlineWidth : 0,
//           child: Image.asset(assetPath, width: size, height: size),
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (reactions.isEmpty) return const SizedBox();

//     final double baseEmojiSize = 24.0 * scale;
//     final double sizeDecreaseStep = 3.0 * scale;
//     final double overlapOffset = 16.0 * scale;
//     final double spacing = 8.0 * scale;
//     final double counterFontSize = 16.0 * scale;

//     // Bounding box buffer for the outline shadow
//     final double safeOutlineWidth = (outlineColor.alpha == 255)
//         ? outlineWidth
//         : 0.0;

//     List<Widget> emojiWidgets = [];

//     for (int i = 0; i < reactions.length; i++) {
//       final double currentEmojiSize = baseEmojiSize - (i * sizeDecreaseStep);
//       emojiWidgets.add(
//         Positioned(
//           right: i * overlapOffset,
//           top: (baseEmojiSize - currentEmojiSize) / 2,
//           child: SizedBox(
//             width: currentEmojiSize + (safeOutlineWidth * 2),
//             height: currentEmojiSize + (safeOutlineWidth * 2),
//             child: _buildOutlinedImage(
//               reactions[i].assetPath,
//               currentEmojiSize,
//             ),
//           ),
//         ),
//       );
//     }

//     final double smallestEmojiSize =
//         baseEmojiSize - ((reactions.length - 1) * sizeDecreaseStep);
//     final double exactWidth =
//         smallestEmojiSize +
//         ((reactions.length - 1) * overlapOffset) +
//         (safeOutlineWidth * 2);

//     final stackWidget = SizedBox(
//       width: exactWidth,
//       height: baseEmojiSize + (safeOutlineWidth * 2),
//       child: Stack(
//         clipBehavior: Clip.none,
//         children: emojiWidgets.reversed.toList(),
//       ),
//     );

//     if (totalReactions != null && totalReactions! > 0) {
//       return Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           stackWidget,
//           SizedBox(width: spacing),
//           Text(
//             _formatReactionsCount(totalReactions!),
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: counterFontSize,
//               color: counterTextColor,
//             ),
//           ),
//         ],
//       );
//     }

//     return stackWidget;
//   }
// }

class OverlappingReactionStack extends StatelessWidget {
  final List<SpotReactions> reactions;
  final int? totalReactions;
  final double scale;
  final Color outlineColor;
  final Color counterTextColor;

  const OverlappingReactionStack({
    super.key,
    required this.reactions,
    this.totalReactions,
    this.scale = 1.0,
    required this.outlineColor,
    required this.counterTextColor,
  });

  String _formatReactionsCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(count % 1000000 == 0 ? 0 : 1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(count % 1000 == 0 ? 0 : 1)}K';
    }
    return count.toString();
  }

  // 🔹 THE MAGIC: Draws the image 8 times in solid white to create a perfect contour outline
  Widget _buildOutlinedImage(
    String assetPath,
    double size,
    double outlineWidth,
    Color outlineColor,
  ) {
    // Defines the 8 directional shifts
    final offsets = [
      Offset(-outlineWidth, -outlineWidth),
      Offset(outlineWidth, -outlineWidth),
      Offset(outlineWidth, outlineWidth),
      Offset(-outlineWidth, outlineWidth),
      Offset(0, -outlineWidth),
      Offset(0, outlineWidth),
      Offset(-outlineWidth, 0),
      Offset(outlineWidth, 0),
    ];

    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. Draw the 8 white shadow images
        for (var offset in offsets)
          Positioned(
            left:
                offset.dx + outlineWidth, // Shifted to fit in the bounding box
            top: offset.dy + outlineWidth,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(outlineColor, BlendMode.srcIn),
              child: Image.asset(assetPath, width: size, height: size),
            ),
          ),

        // 2. Draw the actual colored image dead center on top
        Positioned(
          left: outlineWidth,
          top: outlineWidth,
          child: Image.asset(assetPath, width: size, height: size),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox();

    // 🔹 Scaled Constants
    final double baseEmojiSize = 24.0 * scale;
    final double sizeDecreaseStep = 0 * scale;
    final double overlapOffset =
        20.0 * scale; // Tighter overlap since we don't have big circles
    final double outlineWidth =
        2.5 * scale; // The thickness of the die-cut border
    final double spacing = 5.0 * scale;
    final double counterFontSize = 16.0 * scale;

    // const Color outlineColor = Colors.white;
    // const Color counterTextColor = Colors.black87;

    List<Widget> emojiWidgets = [];

    for (int i = 0; i < reactions.length; i++) {
      final double currentEmojiSize = baseEmojiSize - (i * sizeDecreaseStep);

      emojiWidgets.add(
        Positioned(
          right: i * overlapOffset,
          // Vertically centers the shrinking emojis
          top: (baseEmojiSize - currentEmojiSize) / 2,
          child: SizedBox(
            // Bounding box must accommodate the image + the outline thickness on all sides
            width: currentEmojiSize + (outlineWidth * 2),
            height: currentEmojiSize + (outlineWidth * 2),
            child: _buildOutlinedImage(
              reactions[i].assetPath,
              currentEmojiSize,
              outlineWidth,
              outlineColor,
            ),
          ),
        ),
      );
    }

    final double smallestEmojiSize =
        baseEmojiSize - ((reactions.length - 1) * sizeDecreaseStep);
    final double exactWidth =
        smallestEmojiSize +
        ((reactions.length - 1) * overlapOffset) +
        (outlineWidth * 2);

    final stackWidget = SizedBox(
      width: exactWidth,
      height: baseEmojiSize + (outlineWidth * 2),
      child: Stack(
        clipBehavior: Clip.none,
        children: emojiWidgets.reversed.toList(),
      ),
    );

    if (totalReactions != null && totalReactions! > 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          stackWidget,
          SizedBox(width: spacing),
          Text(
            _formatReactionsCount(totalReactions!),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: counterFontSize,
              color: counterTextColor,
            ),
          ),
        ],
      );
    }

    return stackWidget;
  }
}
