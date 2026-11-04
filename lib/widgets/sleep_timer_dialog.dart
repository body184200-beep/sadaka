import 'package:flutter/material.dart';
import '../services/audio_player_service.dart';

class SleepTimerDialog extends StatelessWidget {
  const SleepTimerDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const SleepTimerDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerService = AudioPlayerService();
    final minutesLeft = playerService.sleepTimerMinutesRemaining;

    return Padding(
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bedtime_rounded, color: Color(0xFF1B6B53)),
              SizedBox(width: 8),
              Text(
                'مؤقت النوم',
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
            minutesLeft != null
                ? 'المؤقت يعمل حالياً: يتبقى حوالي $minutesLeft دقيقة'
                : 'سيتم إيقاف التلاوة تلقائياً بعد الوقت المحدد',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _timerOption(context, 15, '15 دقيقة'),
              _timerOption(context, 30, '30 دقيقة'),
              _timerOption(context, 45, '45 دقيقة'),
              _timerOption(context, 60, 'ساعة كاملة'),
              _timerOption(context, 90, 'ساعة ونصف'),
            ],
          ),
          if (minutesLeft != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              icon: const Icon(Icons.cancel_rounded, color: Colors.red),
              label: const Text(
                'إلغاء مؤقت النوم',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                playerService.cancelSleepTimer();
                Navigator.pop(context);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _timerOption(BuildContext context, int minutes, String label) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF1F5F2),
        foregroundColor: const Color(0xFF1B6B53),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF1B6B53), width: 0.8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: () {
        AudioPlayerService().setSleepTimer(minutes);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم ضبط مؤقت النوم على $label'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF1B6B53),
          ),
        );
      },
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
