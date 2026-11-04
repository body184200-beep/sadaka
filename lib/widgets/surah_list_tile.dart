import 'package:flutter/material.dart';
import '../models/surah.dart';
import '../services/audio_player_service.dart';
import '../services/download_manager.dart';

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
    final downloadManager = DownloadManager();

    final isCurrent = playerService.currentSurah?.number == surah.number &&
        playerService.loadedAudioReciterId == playerService.currentReciter.id;
    final isPlaying = isCurrent && playerService.isPlaying;
    final isFav = playerService.isFavorite(surah.number);
    final reciter = playerService.currentReciter;

    return FutureBuilder<bool>(
      future: downloadManager.isSurahDownloaded(reciter.id, surah.number),
      builder: (context, snapshot) {
        final isDownloaded = snapshot.data ?? false;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: isCurrent
                ? const Color(0xFF0F4C3A).withValues(alpha: 0.12)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCurrent
                  ? const Color(0xFF1B6B53)
                  : Colors.grey.withValues(alpha: 0.15),
              width: isCurrent ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            onTap: onTap,
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isCurrent ? const Color(0xFF1B6B53) : const Color(0xFFF1F5F2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrent ? const Color(0xFFD4AF37) : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: isPlaying
                    ? const Icon(Icons.volume_up_rounded, color: Colors.white, size: 22)
                    : Text(
                        '${surah.number}',
                        style: TextStyle(
                          color: isCurrent ? Colors.white : const Color(0xFF1B6B53),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
            title: Row(
              children: [
                Text(
                  'سورة ${surah.name}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isCurrent ? const Color(0xFF1B6B53) : null,
                  ),
                ),
                const SizedBox(width: 8),
                if (isDownloaded)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF81C784), width: 0.8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.offline_pin_rounded, size: 12, color: Color(0xFF2E7D32)),
                        SizedBox(width: 3),
                        Text(
                          'أوفلاين بدون نت',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: surah.isMakki
                          ? const Color(0xFFFFF3E0)
                          : const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      surah.revelationType,
                      style: TextStyle(
                        fontSize: 11,
                        color: surah.isMakki
                            ? const Color(0xFFE65100)
                            : const Color(0xFF1565C0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${surah.versesCount} آية',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '• ${surah.englishName}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Favorite Button
                IconButton(
                  icon: Icon(
                    isFav ? Icons.star_rounded : Icons.star_border_rounded,
                    color: isFav ? const Color(0xFFD4AF37) : Colors.grey.shade400,
                    size: 22,
                  ),
                  onPressed: () {
                    playerService.toggleFavorite(surah.number);
                  },
                ),
                // Play / Pause Icon Button
                IconButton(
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                    color: isCurrent ? const Color(0xFF1B6B53) : Colors.grey.shade400,
                    size: 32,
                  ),
                  onPressed: onTap,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
