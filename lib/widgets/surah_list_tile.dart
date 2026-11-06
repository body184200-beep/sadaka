import 'package:flutter/material.dart';
import '../models/surah.dart';
import '../services/audio_player_service.dart';

class SurahListTile extends StatelessWidget {
  final Surah surah;
  final VoidCallback onTap;

  const SurahListTile({
    super.key,
    required this.surah,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final playerService = AudioPlayerService();

    final isCurrent = playerService.currentSurah?.number == surah.number &&
        playerService.loadedAudioReciterId == playerService.currentReciter.id;
    final isPlaying = isCurrent && playerService.isPlaying;
    final isFav = playerService.isFavorite(surah.number);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4.5),
      decoration: BoxDecoration(
        color: isCurrent
            ? const Color(0xFF0F4C3A).withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? const Color(0xFFD4AF37)
              : Colors.grey.withValues(alpha: 0.14),
          width: isCurrent ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrent
                ? const Color(0xFF0F4C3A).withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: isCurrent ? 10 : 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          splashColor: const Color(0xFF0F4C3A).withValues(alpha: 0.08),
          highlightColor: const Color(0xFFD4AF37).withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Medallion with Surah Number or Playing Equalizer
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: isCurrent
                        ? const LinearGradient(
                            colors: [Color(0xFF0F4C3A), Color(0xFF1B6B53)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isCurrent ? null : const Color(0xFFF2F6F3),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCurrent ? const Color(0xFFD4AF37) : const Color(0xFFD0DDD6),
                      width: isCurrent ? 1.6 : 1.2,
                    ),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: isPlaying
                        ? const Icon(Icons.graphic_eq_rounded, color: Color(0xFFD4AF37), size: 24)
                        : Text(
                            '${surah.number}',
                            style: TextStyle(
                              color: isCurrent ? Colors.white : const Color(0xFF0F4C3A),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),

                // Surah Name and Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            'سورة ${surah.name}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isCurrent ? const Color(0xFF0F4C3A) : const Color(0xFF1F2925),
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F4C3A),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isPlaying ? 'قيد التلاوة' : 'محددة',
                                style: const TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          // Makki / Madani Tag
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: surah.isMakki
                                  ? const Color(0xFFFFF3E0)
                                  : const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: surah.isMakki
                                    ? const Color(0xFFFFB74D)
                                    : const Color(0xFF81C784),
                                width: 0.6,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  surah.isMakki ? Icons.location_on_outlined : Icons.mosque_outlined,
                                  size: 11,
                                  color: surah.isMakki
                                      ? const Color(0xFFE65100)
                                      : const Color(0xFF2E7D32),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  surah.revelationType,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: surah.isMakki
                                        ? const Color(0xFFE65100)
                                        : const Color(0xFF2E7D32),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${surah.versesCount} آية',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '• ${surah.englishName}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Trailing Buttons: Favorite & Play/Pause
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: isFav ? const Color(0xFFD4AF37) : Colors.grey.shade300,
                        size: 24,
                      ),
                      tooltip: isFav ? 'إزالة من المفضلة' : 'إضافة للمفضلة',
                      onPressed: () {
                        playerService.toggleFavorite(surah.number);
                      },
                    ),
                    IconButton(
                      icon: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: isCurrent
                              ? const LinearGradient(
                                  colors: [Color(0xFFE5C158), Color(0xFFB8860B)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isCurrent ? null : const Color(0xFFF0F4F2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: isCurrent ? const Color(0xFF07261D) : const Color(0xFF0F4C3A),
                          size: 22,
                        ),
                      ),
                      onPressed: onTap,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
