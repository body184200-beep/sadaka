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
        final speed = _playerService.speed;
        final maxDurationMs = duration.inMilliseconds.toDouble();

        return Container(
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF07291F), Color(0xFF0F4536)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.6), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF07291F).withValues(alpha: 0.45),
                blurRadius: 16,
                offset: const Offset(0, 5),
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
                  child: Row(
                    children: [
                      // Avatar / Icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B6B53),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD4AF37), width: 1.4),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
                              blurRadius: 6,
                            ),
                          ],
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
                      const SizedBox(width: 12),
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
                                    fontSize: 16.5,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E7D32),
                                    borderRadius: BorderRadius.circular(6),
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
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Time indicator (isolated position rebuild)
                      ValueListenableBuilder<Duration>(
                        valueListenable: _playerService.positionNotifier,
                        builder: (context, position, _) {
                          final displayPos = _dragValue != null
                              ? Duration(milliseconds: _dragValue!.toInt())
                              : position;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white10),
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
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: Color(0xFFD4AF37),
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),

              // Interactive Seek Bar (isolated position rebuild)
              ValueListenableBuilder<Duration>(
                valueListenable: _playerService.positionNotifier,
                builder: (context, position, _) {
                  final currentPositionMs = position.inMilliseconds.toDouble().clamp(
                        0.0,
                        maxDurationMs > 0 ? maxDurationMs : 1.0,
                      );
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3.5,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                        activeTrackColor: const Color(0xFFD4AF37),
                        inactiveTrackColor: Colors.white.withValues(alpha: 0.18),
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
                  );
                },
              ),

              // Controls Row
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
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
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
                        // Previous Surah
                        IconButton(
                          icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 28),
                          tooltip: 'السورة السابقة',
                          onPressed: () => _playerService.playPrevious(),
                        ),
                        // Rewind 10s (-10 ثواني)
                        IconButton(
                          icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 24),
                          tooltip: 'تأخير 10 ثوانٍ',
                          onPressed: () => _playerService.seekBackward(10),
                        ),
                        const SizedBox(width: 4),
                        // Main Play / Pause Button with golden radial gradient
                        if (_playerService.isBuffering)
                          const SizedBox(
                            width: 46,
                            height: 46,
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                              ),
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF0D278), Color(0xFFB8860B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: const Color(0xFF07261D),
                                size: 28,
                              ),
                              onPressed: () => _playerService.togglePlayPause(),
                            ),
                          ),
                        const SizedBox(width: 4),
                        // Forward 10s (+10 ثواني)
                        IconButton(
                          icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 24),
                          tooltip: 'تقديم 10 ثوانٍ',
                          onPressed: () => _playerService.seekForward(10),
                        ),
                        // Next Surah
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 28),
                          tooltip: 'السورة التالية',
                          onPressed: () => _playerService.playNext(),
                        ),
                      ],
                    ),

                    // Equalizer / Volume Icon button
                    IconButton(
                      icon: const Icon(Icons.bolt_rounded, color: Color(0xFFD4AF37), size: 22),
                      tooltip: 'مضخم الصوت مفعّل',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PlayerScreen()),
                        );
                      },
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
