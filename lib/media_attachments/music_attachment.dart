import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:spots_app/media_attachments/media_attachment_base.dart';

class MusicTrack {
  final String id;
  final String title;
  final String artist;
  final String artUrl;
  final String? previewUrl;
  final String externalUrl;

  MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.artUrl,
    this.previewUrl,
    required this.externalUrl,
  });
}

class MusicAttachment extends MediaAttachment {
  final TextEditingController _searchController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer(); // 🔹 The Audio Engine
  Timer? _debounceTimer;

  StreamSubscription? _playerSubscription;

  bool isSearching = false;
  List<MusicTrack> searchResults = [];
  MusicTrack? selectedTrack;

  // 🔹 Tracks which song is currently playing
  String? currentlyPlayingId;

  MusicAttachment() {
    _searchController.addListener(_onSearchChanged);

    // 🔹 2. Assign the listener to the subscription variable
    _playerSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      currentlyPlayingId = null;
      notifyListeners();
    });
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    final query = _searchController.text.trim();
    if (query.isEmpty) {
      searchResults = [];
      isSearching = false;
      notifyListeners();
      return;
    }

    isSearching = true;
    notifyListeners();

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    try {
      final url = Uri.parse(
        'https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&entity=song&limit=10',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];

        searchResults = results
            .map(
              (track) => MusicTrack(
                id: track['trackId'].toString(),
                title: track['trackName'] ?? 'Unknown',
                artist: track['artistName'] ?? 'Unknown',
                artUrl: (track['artworkUrl100'] as String).replaceAll(
                  '100x100bb',
                  '600x600bb',
                ),
                previewUrl: track['previewUrl'],
                externalUrl: track['trackViewUrl'],
              ),
            )
            .toList();
      }
    } catch (e) {
      debugPrint("Search error: $e");
      searchResults = [];
    }

    isSearching = false;
    notifyListeners();
  }

  // 🔹 The new Play/Pause logic
  Future<void> togglePreview(MusicTrack track) async {
    if (track.previewUrl == null) return;
    HapticFeedback.lightImpact();

    if (currentlyPlayingId == track.id) {
      // Pause if tapping the currently playing track
      await _audioPlayer.pause();
      currentlyPlayingId = null;
    } else {
      // Stop whatever is playing and start the new track
      await _audioPlayer.play(UrlSource(track.previewUrl!));
      currentlyPlayingId = track.id;
    }
    notifyListeners();
  }

  void selectTrack(MusicTrack track) {
    HapticFeedback.selectionClick();
    selectedTrack = track;

    // Stop playback if they select a track to keep the UI clean
    _audioPlayer.stop();
    currentlyPlayingId = null;

    notifyListeners();
  }

  void clearSelection() {
    HapticFeedback.lightImpact();
    selectedTrack = null;
    _searchController.clear();
    searchResults = [];

    // Stop playback if they discard the track
    _audioPlayer.stop();
    currentlyPlayingId = null;

    notifyListeners();
  }

  @override
  String get hintText => "What's the vibe?...";

  @override
  bool get requiresText => false;

  @override
  bool get isTopLayout => false;

  @override
  bool get isValid => selectedTrack != null;

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'music',
      'track_id': selectedTrack?.id,
      'title': selectedTrack?.title,
      'artist': selectedTrack?.artist,
      'art_url': selectedTrack?.artUrl,
      'preview_url': selectedTrack?.previewUrl,
      'url': selectedTrack?.externalUrl,
    };
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);

    // 🔹 3. Cancel the audio stream BEFORE disposing the player
    _playerSubscription?.cancel();

    // Stop the music instantly so it doesn't play while the UI shrinks
    _audioPlayer.stop();
    _audioPlayer.dispose();

    // 🔹 4. THE MAGIC FIX: Delay the destruction of the text controller
    // This gives the AnimatedSize exactly enough time to finish
    // its 300ms shrinking animation before pulling the rug out.
    Future.delayed(const Duration(milliseconds: 350), () {
      _searchController.dispose();
    });

    super.dispose();
  }

  @override
  Widget buildEditor(BuildContext context) {
    return ListenableBuilder(
      listenable: this,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: selectedTrack == null
                ? _buildSearchMode()
                : _buildSelectedCard(),
          ),
        );
      },
    );
  }

  Widget _buildSearchMode() {
    return Column(
      key: const ValueKey('search_mode'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Icon(Icons.search_rounded, color: Colors.white54),
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: "Search any song...",
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (isSearching)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (searchResults.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 240),
              decoration: BoxDecoration(
                color: const Color(0xFF141418),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12, width: 1),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final track = searchResults[index];
                  final isPlaying = currentlyPlayingId == track.id;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        track.artUrl,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      track.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      track.artist,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // 🔹 The new Trailing Play/Pause Button for Preview
                    trailing: track.previewUrl != null
                        ? IconButton(
                            icon: Icon(
                              isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_fill,
                              color: isPlaying
                                  ? const Color.fromARGB(255, 242, 121, 131)
                                  : Colors.white70,
                              size: 28,
                            ),
                            onPressed: () => togglePreview(track),
                          )
                        : const SizedBox(
                            width: 28,
                          ), // Spacer if no preview exists
                    // Tapping the row still selects the track
                    onTap: () => selectTrack(track),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSelectedCard() {
    final isPlaying = currentlyPlayingId == selectedTrack!.id;

    return Container(
      key: const ValueKey('selected_mode'),
      height: 100,
      // height: 72,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: Row(
        children: [
          // 🔹 Tap the album art on the final card to play/pause!
          GestureDetector(
            onTap: () => togglePreview(selectedTrack!),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    selectedTrack!.artUrl,
                    width: 70,
                    height: 70,
                    // width: 54,
                    // height: 54,
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  width: 70,
                  height: 70,
                  // width: 54,
                  // height: 54,
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 40,
                    // size: 28,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedTrack!.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    // fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  selectedTrack!.artist,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 17,
                    // fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: clearSelection,
            icon: const Icon(Icons.close_rounded, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
