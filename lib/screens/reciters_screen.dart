import 'package:flutter/material.dart';
import '../services/audio_player_service.dart';
import '../services/download_manager.dart';
import '../services/quran_data.dart';

class RecitersScreen extends StatelessWidget {
  const RecitersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerService = AudioPlayerService();
    final downloadManager = DownloadManager();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'اختيار القارئ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        itemCount: QuranData.reciters.length,
        itemBuilder: (context, index) {
          final reciter = QuranData.reciters[index];
          final isSelected = playerService.currentReciter.id == reciter.id;

          return FutureBuilder<List<int>>(
            future: downloadManager.getDownloadedSurahNumbers(reciter.id),
            builder: (context, snapshot) {
              final downloadedCount = snapshot.data?.length ?? 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF0F4C3A).withValues(alpha: 0.09)
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF1B6B53)
                        : Colors.grey.withValues(alpha: 0.15),
                    width: isSelected ? 1.8 : 1,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1B6B53)
                          : const Color(0xFFE8F0EC),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.person_rounded,
                        color: isSelected ? Colors.white : const Color(0xFF1B6B53),
                        size: 28,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        reciter.name,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? const Color(0xFF1B6B53) : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (downloadedCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF81C784), width: 0.8),
                          ),
                          child: Text(
                            '$downloadedCount سورة جاهزة بدون نت',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.25), width: 0.8),
                          ),
                          child: const Text(
                            'تلاوة بالإنترنت',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      reciter.subName,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF1B6B53),
                          size: 26,
                        )
                      : const Icon(
                          Icons.chevron_left_rounded,
                          color: Colors.grey,
                        ),
                  onTap: () {
                    playerService.setReciter(reciter);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم اختيار القارئ: ${reciter.name}'),
                        duration: const Duration(seconds: 2),
                        backgroundColor: const Color(0xFF1B6B53),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
