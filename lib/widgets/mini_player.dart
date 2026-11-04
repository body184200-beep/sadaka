import 'package:flutter/material.dart';
import '../screens/player_screen.dart';
import '../services/audio_player_service.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  final AudioPlayerService _playerService = AudioPlayerService();
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _playerService,
      builder: (context, _) {
        final surah = _playerService.currentSurah;
        if (surah == null) return const SizedBox.shrink();

        final isPlaying = _playerService.isPlaying;
        final isOffline = _playerService.isOfflinePlayback;
        final duration = _playerService.duration;
        final position = _playerService.position;
        final speed = _playerService.speed;

        final maxDurationMs = duration.inMilliseconds.toDouble();
        final currentPositionMs = position.inMilliseconds.toDouble().clamp(
              0.0,
              maxDurationMs > 0 ? maxDurationMs : 1.0,
            );

        final displayPos = _dragValue != null
            ? Duration(milliseconds: _dragValue!.toInt())
            : position;

        return Container(
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0D3B2E),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Info Row (Tappable to open full player screen)
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PlayerScreen()),
                  );
                },
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                  child: Row(
                    children: [
                      // Avatar / Icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B6B53),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            'assets/icon.jpeg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.menu_book_rounded,
                              color: Color(0xFFD4AF37),
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Surah & Reciter name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'سورة ${surah.name}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (isOffline)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2E7D32),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: const Text(
                                      'أوفلاين',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _playerService.currentReciter.name,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Time indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          maxDurationMs > 0
                              ? '${_playerService.formatDuration(displayPos)} / ${_playerService.formatDuration(duration)}'
                              : _playerService.formatDuration(displayPos),
                          style: const TextStyle(
                            color: Color(0xFFD4AF37),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.open_in_full_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),

              // Interactive Seek Bar (تقديم وتأخير بالسحب)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3.5,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: const Color(0xFFD4AF37),
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                    thumbColor: const Color(0xFFD4AF37),
                  ),
                  child: Slider(
                    min: 0.0,
                    max: maxDurationMs > 0 ? maxDurationMs : 1.0,
                    value: (_dragValue ?? currentPositionMs).clamp(
                      0.0,
                      maxDurationMs > 0 ? maxDurationMs : 1.0,
                    ),
                    onChanged: maxDurationMs > 0
                        ? (val) {
                            setState(() {
                              _dragValue = val;
                            });
                          }
                        : null,
                    onChangeEnd: maxDurationMs > 0
                        ? (val) {
                            _playerService.seek(Duration(milliseconds: val.toInt()));
                            setState(() {
                              _dragValue = null;
                            });
                          }
                        : null,
                  ),
                ),
              ),

              // Controls Row (تقديم 10 ثواني، تشغيل/إيقاف، تأخير 10 ثواني، والتحكم بالسرعة)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Speed button
                    InkWell(
                      onTap: () => _playerService.cycleSpeed(),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFD4AF37), width: 0.8),
                        ),
                        child: Text(
                          '${speed}x',
                          style: const TextStyle(
                            color: Color(0xFFD4AF37),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),

                    // Playback actions
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Rewind 10s (-10 ثواني)
                        IconButton(
                          icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 26),
                          tooltip: 'تأخير 10 ثوانٍ',
                          onPressed: () => _playerService.seekBackward(10),
                        ),
                        const SizedBox(width: 4),
                        // Main Play / Pause Button
                        if (_playerService.isBuffering)
                          const SizedBox(
                            width: 44,
                            height: 44,
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                              ),
                            ),
                          )
                        else
                          IconButton(
                            icon: Icon(
                              isPlaying
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.play_circle_fill_rounded,
                              color: const Color(0xFFD4AF37),
                              size: 44,
                            ),
                            onPressed: () => _playerService.togglePlayPause(),
                          ),
                        const SizedBox(width: 4),
                        // Forward 10s (+10 ثواني)
                        IconButton(
                          icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 26),
                          tooltip: 'تقديم 10 ثوانٍ',
                          onPressed: () => _playerService.seekForward(10),
                        ),
                      ],
                    ),

                    // Next Surah
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 28),
                      tooltip: 'السورة التالية',
                      onPressed: () => _playerService.playNext(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
