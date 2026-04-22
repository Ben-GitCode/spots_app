// 1. ENUMS
enum PrivacyTypes { public, private, me }

enum Reactions { funny, wow, sad, insightful, support, meh, wholesome, empty }

extension ReactionsExtension on Reactions {
  String get assetPath {
    switch (this) {
      case Reactions.funny:
        return "assets/emojis/emoji_u1f602.png";
      case Reactions.wow:
        return "assets/emojis/emoji_u1f62f.png";
      case Reactions.sad:
        return "assets/emojis/emoji_u1f622.png";
      case Reactions.insightful:
        return "assets/emojis/emoji_u1f4a1.png";
      case Reactions.support:
        return "assets/emojis/emoji_u1f525.png";
      case Reactions.meh:
        return "assets/emojis/emoji_u1f615.png";
      case Reactions.wholesome:
        return "assets/emojis/emoji_u1f970.png";
      case Reactions.empty:
        return "assets/emojis/emoji_u2754.png";
    }
  }

  // 🔹 NEW: The Animated WebPs (Used ONLY in the bottom sheet selector)
  String get animatedAssetPath {
    switch (this) {
      case Reactions.funny:
        return "assets/animated/funny.webp";
      case Reactions.wow:
        return "assets/animated/wow.webp";
      case Reactions.sad:
        return "assets/animated/sad.webp";
      case Reactions.insightful:
        return "assets/animated/insightful.webp";
      case Reactions.support:
        return "assets/animated/support.webp";
      case Reactions.meh:
        return "assets/animated/meh.webp";
      case Reactions.wholesome:
        return "assets/animated/wholesome.webp";
      case Reactions.empty:
        return "assets/animated/empty.webp";
    }
  }
}
