import 'package:flutter/material.dart';
import '../services/audio_player_service.dart';
import '../services/download_manager.dart';
import '../services/quran_data.dart';
import '../widgets/mini_player.dart';
import '../widgets/surah_list_tile.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final DownloadManager _downloadManager = DownloadManager();
  final AudioPlayerService _playerService = AudioPlayerService();

  @override
  Widget build(BuildContext context) {
    final reciter = _playerService.currentReciter;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'السور المتاحة بدون نت (أوفلاين)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Storage & Reciter Info Header
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D3B2E), Color(0xFF1B6B53)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D3B2E).withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FutureBuilder<int>(
              future: _downloadManager.getDownloadedTotalBytes(reciter.id),
              builder: (context, sizeSnapshot) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.offline_pin_rounded,
                          color: Color(0xFFD4AF37),
                          size: 26,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'القارئ: ${reciter.name}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'جميع السور الموضحة أدناه جاهزة للاستماع فوراً بدون أي اتصال بالإنترنت أو الحاجة للتحميل المسبق.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // List of downloaded surahs
          Expanded(
            child: FutureBuilder<List<int>>(
              future: _downloadManager.getDownloadedSurahNumbers(reciter.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final downloadedNumbers = snapshot.data ?? [];

                if (downloadedNumbers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_done_rounded,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'السور المدمجة جاهزة في الشاشة الرئيسية',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: downloadedNumbers.length,
                  itemBuilder: (context, index) {
                    final surahNum = downloadedNumbers[index];
                    final surah = QuranData.getSurah(surahNum);
                    return SurahListTile(
                      surah: surah,
                      onTap: () {
                        final isCurrent = _playerService.currentSurah?.number == surah.number;
                        if (isCurrent) {
                          _playerService.togglePlayPause();
                        } else {
                          _playerService.playSurah(surah, forceReload: true);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }
}
