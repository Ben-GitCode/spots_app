import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:spots_app/utils/models.dart';
import 'package:spots_app/components/overlapping_reaction_stack.dart';
import 'package:spots_app/utils/moment_data.dart';

String formatNumberWithCommas(int count) {
  var formatter = NumberFormat('#,###,###');
  return formatter.format(count);
}

class MomentFullScreenView extends StatefulWidget {
  final Moment moment;
  const MomentFullScreenView({super.key, required this.moment});
  @override
  State<MomentFullScreenView> createState() => _MomentFullScreenViewState();
}

class _MomentFullScreenViewState extends State<MomentFullScreenView> {
  // 🔹 The Centralized Data Updater
  // This safely handles swapping, adding, and removing reactions
  void _handleReactionSelect(
    Reactions tappedReaction,
    VoidCallback? updateListSheet,
  ) {
    setState(() {
      Reactions? oldReaction = widget.moment.userReaction;

      if (oldReaction == tappedReaction) {
        // SCENARIO 1: Tapping the already selected reaction (Remove it)
        // 🔹 FIX: We use tappedReaction here since we know it equals oldReaction and is non-null!
        widget.moment.reactionCounts[tappedReaction] =
            (widget.moment.reactionCounts[tappedReaction] ?? 1) - 1;

        if (widget.moment.reactionCounts[tappedReaction] == 0) {
          widget.moment.reactionCounts.remove(tappedReaction);
        }

        widget.moment.userReaction = null;
      } else {
        // SCENARIO 2: Tapping a new reaction (Swap or Add)
        if (oldReaction != null) {
          // Remove the old one first
          // 🔹 FIX: Added the '!' operator to tell Dart it is definitely not null
          widget.moment.reactionCounts[oldReaction!] =
              (widget.moment.reactionCounts[oldReaction] ?? 1) - 1;

          if (widget.moment.reactionCounts[oldReaction] == 0) {
            widget.moment.reactionCounts.remove(oldReaction);
          }
        }

        // Add the new one
        widget.moment.userReaction = tappedReaction;
        widget.moment.reactionCounts[tappedReaction] =
            (widget.moment.reactionCounts[tappedReaction] ?? 0) + 1;
      }
    });

    // If the list bottom sheet is open, this forces it to visually update!
    updateListSheet?.call();
  }

  void _showReactionsList() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetContext) {
        // 🔹 StatefulBuilder lets us update the bottom sheet instantly without closing it
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            // Sort the list fresh on every rebuild
            var sortedEntries = widget.moment.reactionCounts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 16.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🔹 THE DRAG HANDLE
                    Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                    Text(
                      "${formatNumberWithCommas(widget.moment.totalReactions)} Reactions",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),

                    Expanded(
                      child: ListView.builder(
                        // 🔹 Add 1 to the count to make room for our special top row
                        itemCount: sortedEntries.length + 1,
                        itemBuilder: (context, index) {
                          // ==========================================
                          // THE SPECIAL TOP ROW (Index 0)
                          // ==========================================
                          if (index == 0) {
                            if (widget.moment.userReaction != null) {
                              // STATE 1: User HAS reacted -> Show Green "Remove" Pill
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    // 🔹 Opens selector AND passes the setState function so the list updates live!
                                    _showReactionSelector(
                                      updateListSheet: () =>
                                          setSheetState(() {}),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(
                                      bottom: 16,
                                      top: 8,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.green.shade300,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset(
                                          widget.moment.userReaction!.assetPath,
                                          width: 28,
                                          height: 28,
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          "Tap to change",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              // STATE 2: User has NOT reacted -> Show "Add Reaction" Button
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    // 🔹 Opens selector AND passes the setState function
                                    _showReactionSelector(
                                      updateListSheet: () =>
                                          setSheetState(() {}),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(
                                      bottom: 24,
                                      top: 8,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.add_reaction_outlined,
                                            color: Colors.black54,
                                            size: 30,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          "Add a reaction",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                          }

                          // ==========================================
                          // THE STANDARD LIST (Index 1+)
                          // ==========================================
                          // We subtract 1 from the index because the 0th item is our special row
                          final entry = sortedEntries[index - 1];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            leading: Image.asset(
                              entry.key.assetPath,
                              width: 32,
                              height: 32,
                            ),
                            title: Text(
                              entry.key.name.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: Text(
                              formatNumberWithCommas(entry.value),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 🔹 Optionally accepts a callback so the list sheet can rebuild if it's open behind this one
  void _showReactionSelector({VoidCallback? updateListSheet}) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 🔹 Passing the Enums directly
                _buildAnimatedEmojiBtn(Reactions.funny, updateListSheet),
                _buildAnimatedEmojiBtn(Reactions.wow, updateListSheet),
                _buildAnimatedEmojiBtn(Reactions.wholesome, updateListSheet),
                _buildAnimatedEmojiBtn(Reactions.insightful, updateListSheet),
                _buildAnimatedEmojiBtn(Reactions.sad, updateListSheet),
                _buildAnimatedEmojiBtn(Reactions.meh, updateListSheet),
                _buildAnimatedEmojiBtn(Reactions.support, updateListSheet),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedEmojiBtn(
    Reactions reaction,
    VoidCallback? updateListSheet,
  ) {
    bool isSelected = widget.moment.userReaction == reaction;

    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        Navigator.pop(context); // Close the selector
        _handleReactionSelect(
          reaction,
          updateListSheet,
        ); // Trigger the swap logic
      },
      child: Container(
        padding: const EdgeInsets.all(
          5,
        ), // Gives the emoji room inside the grey circle
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // 🔹 Shows the Grey Selection Circle
          color: isSelected
              // ? Colors.grey.withValues(alpha: 0.4)
              ? Colors.green.withValues(alpha: 0.4)
              : Colors.transparent,
        ),
        child: Image.asset(
          reaction.animatedAssetPath,
          width: 35,
          height: 35,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.emoji_emotions, size: 40, color: Colors.amber),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // const Color buttonsBackgroundColor = Color(0xFF636A73);
    const Color buttonsBackgroundColor = Color(0xFF545454);
    // const Color buttonsBackgroundColor = Color(0xFF3D3D3D);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.85),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Fixed Top Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: buttonsBackgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  Text(
                    "${widget.moment.timestamp.day.toString().padLeft(2, '0')}/${widget.moment.timestamp.month.toString().padLeft(2, '0')}/${widget.moment.timestamp.year}",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // 2. 🔹 FIXED: The Constant Size Scroll Container
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Hero(
                  tag: 'moment_card_${widget.moment.id}',
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      // The container acts as the physical window, the content scrolls fluidly inside
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // All media blocks are forced to a perfect 3:4 vertical portrait
                          final double mediaHeight =
                              constraints.maxWidth * (4 / 3);

                          return SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // A. The Media Block
                                    SizedBox(
                                      height: mediaHeight,
                                      child: widget.moment.media.buildExpanded(
                                        context,
                                      ),
                                    ),

                                    // B. The White Context Area
                                    Container(
                                      color: Colors.white,
                                      padding: const EdgeInsets.fromLTRB(
                                        20,
                                        7,
                                        20,
                                        20,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const SizedBox(
                                                width: 50,
                                              ), // Leaves room for avatar
                                              Expanded(
                                                child: Text(
                                                  "@${widget.moment.authorName}",
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Colors.black87,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: Colors.grey.shade300,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons
                                                          .photo_library_outlined,
                                                      size: 16,
                                                      color: Colors.black54,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      "Tel Aviv Moments",
                                                      style: TextStyle(
                                                        color: Colors.blue[800],
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 10),

                                          // Conditionally render the caption only if it exists
                                          if (widget
                                              .moment
                                              .caption
                                              .isNotEmpty) ...[
                                            const Divider(height: 1),
                                            const SizedBox(height: 12),
                                            Text(
                                              widget.moment.caption,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                color: Colors.black87,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                // C. Overlapping Avatar (Seamed dynamically!)
                                Positioned(
                                  left: 0,
                                  top: mediaHeight - 30,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: CircleAvatar(
                                      radius: 30,
                                      backgroundImage: NetworkImage(
                                        widget.moment.avatarUrl,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 3. 🔹 FIXED 20px HORIZONTAL OVERFLOW: Smaller paddings on bottom bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: buttonsBackgroundColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.moment.commentCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(), // Safely takes remaining width
                  // The Split Reaction Pill (No outlines here!)
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: buttonsBackgroundColor,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: _showReactionsList,
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(22),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10, right: 10),
                            child: OverlappingReactionStack(
                              reactions: widget.moment.top3Reactions,
                              totalReactions: widget.moment.totalReactions,
                              scale:
                                  0.9, // Scaled down to guarantee no overflow
                              outlineColor: buttonsBackgroundColor,
                              counterTextColor: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 30,
                          color: Color(0xFF404040),
                        ),
                        InkWell(
                          // 🔹 Opens the selector directly. No need for updateListSheet here since list is closed.
                          onTap: () => _showReactionSelector(),
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(22),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10, right: 15),
                            // 🔹 THE DYNAMIC ICON: Shows selected image OR the default icon!
                            child: widget.moment.userReaction != null
                                ? Image.asset(
                                    widget.moment.userReaction!.assetPath,
                                    width: 22,
                                    height: 22,
                                  )
                                : const Icon(
                                    Icons.add_reaction_outlined,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  //const SizedBox(width: 8),
                  const Spacer(),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: buttonsBackgroundColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.bookmark_border,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: buttonsBackgroundColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.share_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
