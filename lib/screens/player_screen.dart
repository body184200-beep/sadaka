import 'package:flutter/material.dart';
import '../services/audio_player_service.dart';
import '../services/download_manager.dart';
import '../widgets/dedication_dialog.dart';
import '../widgets/full_screen_image_viewer.dart';
import '../widgets/sleep_timer_dialog.dart';
import 'reciters_screen.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final AudioPlayerService _playerService = AudioPlayerService();
  final DownloadManager _downloadManager = DownloadManager();
  double? _dragValue;
  int _artworkIndex = 0;

  static const List<Map<String, String>> _artworks = [
    {'path': 'assets/images/mohamed_portrait.jpg', 'title': 'المغفور له بإذن الله: محمد أسامة'},
    {'path': 'assets/images/splash_parents.jpg', 'title': 'محمد مع والدته الكريمة'},
    {'path': 'assets/images/mother_and_son.jpg', 'title': 'بر بالوالدة وذكرى عطرة'},
    {'path': 'assets/images/mohamed_suit.jpg', 'title': 'اللهم ارحم شبابه واغفر له'},
    {'path': 'assets/images/family_collage.jpg', 'title': 'ذكريات طيبة ومحبة باقية'},
    {'path': 'assets/icon.jpeg', 'title': 'القرآن الكريم'},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (_playerService.isPlaying) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    if (duration <= Duration.zero) return '00:00';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final hours = duration.inHours;
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  void _showSpeedPicker(BuildContext context) {
    final currentSpeed = _playerService.speed;
    final speeds = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'سرعة التلاوة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B6B53),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: speeds.map((s) {
                final isSel = s == currentSpeed;
                return ChoiceChip(
                  label: Text(
                    s == 1.0 ? '1.0x (طبيعي)' : '${s}x',
                    style: TextStyle(
                      color: isSel ? Colors.white : const Color(0xFF1B6B53),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  selected: isSel,
                  selectedColor: const Color(0xFF1B6B53),
                  backgroundColor: const Color(0xFFF1F5F2),
                  onSelected: (_) {
                    _playerService.setSpeed(s);
                    Navigator.pop(ctx);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showVolumeBoosterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isEnabled = _playerService.isLoudnessBoostEnabled;
            final gain = _playerService.loudnessGain;

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bolt_rounded, color: Color(0xFFD4AF37), size: 24),
                      SizedBox(width: 8),
                      Text(
                        'مضخم الصوت الرقمي الفائق',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B6B53),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isEnabled
                        ? 'الصوت مضخم لأقصى درجة ممكنة (+${gain.toInt()} dB) لتوفير أعلى مستوى صوت نقي'
                        : 'مضخم الصوت معطل حالياً',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isEnabled ? const Color(0xFF2E7D32) : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Icon(Icons.volume_down_rounded, color: Color(0xFF1B6B53)),
                      Expanded(
                        child: Slider(
                          min: 0.0,
                          max: 20.0,
                          divisions: 20,
                          label: '+${gain.toInt()} dB',
                          value: isEnabled ? gain : 0.0,
                          activeColor: const Color(0xFFD4AF37),
                          inactiveColor: Colors.grey.shade300,
                          onChanged: (val) {
                            setSheetState(() {});
                            _playerService.setLoudnessGain(val);
                          },
                        ),
                      ),
                      const Icon(Icons.volume_up_rounded, color: Color(0xFFD4AF37)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.bolt_rounded, color: Colors.white),
                        label: const Text('أقصى تضخيم (+20 dB)', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B6B53),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          setSheetState(() {});
                          _playerService.setLoudnessGain(20.0);
                        },
                      ),
                      OutlinedButton.icon(
                        icon: Icon(isEnabled ? Icons.power_settings_new_rounded : Icons.play_arrow_rounded),
                        label: Text(isEnabled ? 'إيقاف التضخيم' : 'تفعيل التضخيم'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isEnabled ? Colors.red.shade700 : const Color(0xFF1B6B53),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          setSheetState(() {});
                          _playerService.toggleLoudnessBoost();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _playerService,
      builder: (context, _) {
        final surah = _playerService.currentSurah;
        final reciter = _playerService.currentReciter;
        final isPlaying = _playerService.isPlaying;
        final isOffline = _playerService.isOfflinePlayback;
        final position = _playerService.position;
        final duration = _playerService.duration;
        final isFav = surah != null && _playerService.isFavorite(surah.number);
        final repeatMode = _playerService.repeatMode;
        final speed = _playerService.speed;
        final sleepMins = _playerService.sleepTimerMinutesRemaining;

        if (isPlaying) {
          if (!_pulseController.isAnimating) {
            _pulseController.repeat(reverse: true);
          }
        } else {
          if (_pulseController.isAnimating) {
            _pulseController.stop();
          }
        }

        if (surah == null) {
          return const Scaffold(
            body: Center(child: Text('الرجاء اختيار سورة')),
          );
        }

        final maxDurationMs = duration.inMilliseconds.toDouble();
        final currentArtwork = _artworks[_artworkIndex];

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF072019), Color(0xFF0F4C3A), Color(0xFF061813)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              children: [
                // Ambient background watermark of current photo
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.10,
                    child: Image.asset(
                      currentArtwork['path']!,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (ctx, error, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),

                SafeArea(
                  child: Column(
                    children: [
                      // Top Navigation Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 34),
                              onPressed: () => Navigator.pop(context),
                            ),
                            // Reciter selector button
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const RecitersScreen()),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F4C3A),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.record_voice_over_rounded, color: Color(0xFFD4AF37), size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      reciter.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.verified_rounded, color: Color(0xFFD4AF37), size: 14),
                                  ],
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Dedication / Sadaqah Jariyah dialog
                                IconButton(
                                  icon: const Icon(Icons.favorite_rounded, color: Color(0xFFD4AF37), size: 24),
                                  tooltip: 'صدقة جارية على روح محمد أسامة',
                                  onPressed: () => DedicationDialog.show(context),
                                ),
                                // Sleep Timer
                                IconButton(
                                  icon: Icon(
                                    sleepMins != null ? Icons.bedtime_rounded : Icons.bedtime_outlined,
                                    color: sleepMins != null ? const Color(0xFFD4AF37) : Colors.white,
                                    size: 24,
                                  ),
                                  onPressed: () => SleepTimerDialog.show(context),
                                ),
                                // Favorite
                                IconButton(
                                  icon: Icon(
                                    isFav ? Icons.star_rounded : Icons.star_border_rounded,
                                    color: isFav ? const Color(0xFFD4AF37) : Colors.white,
                                    size: 26,
                                  ),
                                  onPressed: () => _playerService.toggleFavorite(surah.number),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Center Luxury Artwork Frame (Responsive to prevent any layout overflow)
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final availableHeight = constraints.maxHeight;
                            // Dynamically adapt artwork size based on available vertical space
                            final cardHeight = (availableHeight - 55).clamp(140.0, 240.0);
                            final cardWidth = (cardHeight * 0.82).clamp(120.0, 210.0);
                            final isCompact = availableHeight < 250;

                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ScaleTransition(
                                    scale: isPlaying ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _artworkIndex = (_artworkIndex + 1) % _artworks.length;
                                        });
                                      },
                                      child: Container(
                                        width: cardWidth,
                                        height: cardHeight,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F3E30),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: const Color(0xFFD4AF37), width: 2.2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFD4AF37).withValues(alpha: isPlaying ? 0.35 : 0.15),
                                              blurRadius: 24,
                                              spreadRadius: 3,
                                            ),
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.5),
                                              blurRadius: 12,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(18),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              Image.asset(
                                                currentArtwork['path']!,
                                                fit: BoxFit.cover,
                                                alignment: Alignment.topCenter,
                                                errorBuilder: (ctx, error, _) => const Center(
                                                  child: Icon(Icons.menu_book_rounded, size: 60, color: Color(0xFFD4AF37)),
                                                ),
                                              ),
                                              // Bottom subtle gradient overlay for title
                                              Positioned(
                                                left: 0,
                                                right: 0,
                                                bottom: 0,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Colors.transparent,
                                                        Colors.black.withValues(alpha: 0.85),
                                                      ],
                                                      begin: Alignment.topCenter,
                                                      end: Alignment.bottomCenter,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          currentArtwork['title']!,
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(Icons.fullscreen_rounded, color: Color(0xFFD4AF37), size: 20),
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(),
                                                        tooltip: 'تكبير الصورة',
                                                        onPressed: () {
                                                          FullScreenImageViewer.open(
                                                            context,
                                                            currentArtwork['path']!,
                                                            title: currentArtwork['title']!,
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Visual photo dots indicator
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(_artworks.length, (idx) {
                                      final isSel = idx == _artworkIndex;
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _artworkIndex = idx;
                                          });
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 250),
                                          margin: const EdgeInsets.symmetric(horizontal: 3),
                                          width: isSel ? 18 : 6,
                                          height: 5,
                                          decoration: BoxDecoration(
                                            color: isSel ? const Color(0xFFD4AF37) : Colors.white24,
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                  if (!isCompact) ...[
                                    const SizedBox(height: 6),
                                    // Tip to cycle photos
                                    TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _artworkIndex = (_artworkIndex + 1) % _artworks.length;
                                        });
                                      },
                                      icon: const Icon(Icons.touch_app_rounded, color: Color(0xFFD4AF37), size: 14),
                                      label: const Text(
                                        'المس لتغيير الصورة (صدقة جارية)',
                                        style: TextStyle(
                                          color: Color(0xFFD4AF37),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(0xFFD4AF37),
                                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  const SizedBox(height: 8),

                  // Surah Info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        Text(
                          'سورة ${surah.name}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 29,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'السورة ${surah.number} • ${surah.revelationType} • ${surah.versesCount} آيات • ${surah.englishName}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Memorial Prayer Bar for Mohamed Osama
                        InkWell(
                          onTap: () => DedicationDialog.show(context),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D3B2E),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.5), width: 0.8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.favorite_rounded, color: Color(0xFFD4AF37), size: 14),
                                SizedBox(width: 6),
                                Text(
                                  'اللهم ارحم شبابه واغفر له واجعل الجنة مثواه • صدقة جارية',
                                  style: TextStyle(
                                    color: Color(0xFFE5C158),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Offline Badge
                        if (isOffline)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF81C784), width: 1),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.offline_pin_rounded, color: Color(0xFF81C784), size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'تلاوة أوفلاين تعمل بدون إنترنت',
                                  style: TextStyle(
                                    color: Color(0xFF81C784),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          FutureBuilder<bool>(
                            future: _downloadManager.isSurahDownloaded(reciter.id, surah.number),
                            builder: (context, snap) {
                              final downloaded = snap.data ?? false;
                              if (downloaded) {
                                return const SizedBox.shrink();
                              }
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.sync_rounded, color: Color(0xFFD4AF37), size: 15),
                                    SizedBox(width: 6),
                                    Text(
                                      'يتم حفظ السورة تلقائياً للعمل بدون نت',
                                      style: TextStyle(
                                        color: Color(0xFFD4AF37),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 8),
                        // Volume Booster Badge
                        InkWell(
                          onTap: () => _showVolumeBoosterSheet(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.volume_up_rounded, color: Color(0xFFD4AF37), size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  _playerService.isLoudnessBoostEnabled
                                      ? 'مضخم الصوت: أقصى درجة (+${_playerService.loudnessGain.toInt()} dB)'
                                      : 'مضخم الصوت: معطل',
                                  style: const TextStyle(
                                    color: Color(0xFFD4AF37),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.bolt_rounded, color: Color(0xFFD4AF37), size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Seek Bar with smooth drag
                  ValueListenableBuilder<Duration>(
                    valueListenable: _playerService.positionNotifier,
                    builder: (context, position, _) {
                      final currentPositionMs = position.inMilliseconds.toDouble().clamp(
                            0.0,
                            maxDurationMs > 0 ? maxDurationMs : 1.0,
                          );
                      final displayPosition = _dragValue != null
                          ? Duration(milliseconds: _dragValue!.toInt())
                          : position;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: const Color(0xFFD4AF37),
                                inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                                thumbColor: const Color(0xFFD4AF37),
                                trackHeight: 4.0,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
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
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(displayPosition),
                                    style: const TextStyle(
                                      color: Color(0xFFD4AF37),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    maxDurationMs > 0
                                        ? _formatDuration(duration)
                                        : 'جاري التحميل...',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  // Playback Controls Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Repeat Mode
                        IconButton(
                          icon: Icon(
                            repeatMode == QuranRepeatMode.one
                                ? Icons.repeat_one_rounded
                                : repeatMode == QuranRepeatMode.all
                                    ? Icons.repeat_rounded
                                    : Icons.repeat_rounded,
                            color: repeatMode == QuranRepeatMode.none
                                ? Colors.white.withValues(alpha: 0.4)
                                : const Color(0xFFD4AF37),
                            size: 24,
                          ),
                          tooltip: 'وضع التكرار',
                          onPressed: () => _playerService.toggleRepeatMode(),
                        ),
                        // Previous Surah
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 28),
                            tooltip: 'السورة السابقة',
                            onPressed: () => _playerService.playPrevious(),
                          ),
                        ),
                        // 10s Rewind (-10s)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 24),
                            tooltip: 'تأخير 10 ثوانٍ',
                            onPressed: () => _playerService.seekBackward(10),
                          ),
                        ),
                        // Main Play / Pause Button
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF3D274), Color(0xFFC59B27), Color(0xFF9E7B18)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _playerService.isBuffering
                                ? const SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF0D3B2E),
                                      strokeWidth: 3,
                                    ),
                                  )
                                : IconButton(
                                    icon: Icon(
                                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                      color: const Color(0xFF07261D),
                                      size: 42,
                                    ),
                                    onPressed: () => _playerService.togglePlayPause(),
                                  ),
                          ),
                        ),
                        // 10s Forward (+10s)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 24),
                            tooltip: 'تقديم 10 ثوانٍ',
                            onPressed: () => _playerService.seekForward(10),
                          ),
                        ),
                        // Next Surah
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 28),
                            tooltip: 'السورة التالية',
                            onPressed: () => _playerService.playNext(),
                          ),
                        ),
                        // Playback Speed button
                        GestureDetector(
                          onTap: () => _showSpeedPicker(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFD4AF37), width: 0.8),
                            ),
                            child: Text(
                              '${speed}x',
                              style: const TextStyle(
                                color: Color(0xFFD4AF37),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_playerService.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC0392B).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _playerService.errorMessage!,
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  },
);
  }
}
