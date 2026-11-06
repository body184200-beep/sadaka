import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'full_screen_image_viewer.dart';

class DedicationDialog extends StatelessWidget {
  const DedicationDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DedicationDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = [
      {'path': 'assets/images/mohamed_portrait.jpg', 'title': 'المغفور له بإذن الله: محمد أسامة'},
      {'path': 'assets/images/splash_parents.jpg', 'title': 'محمد مع والدته الكريمة'},
      {'path': 'assets/images/mother_and_son.jpg', 'title': 'بر بالوالدة وذكرى عطرة'},
      {'path': 'assets/images/mohamed_suit.jpg', 'title': 'اللهم ارحم شبابه واغفر له'},
      {'path': 'assets/images/family_collage.jpg', 'title': 'ذكريات طيبة ومحبة باقية'},
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF07241C), Color(0xFF0F4335), Color(0xFF08221B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.favorite_rounded, color: Color(0xFFD4AF37), size: 24),
                    SizedBox(width: 8),
                    Text(
                      'صدقة جارية على روح محمد أسامة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Quran Ayah Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F4C3A), Color(0xFF1B6B53)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFD4AF37), width: 1.4),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Column(
                    children: [
                      Text(
                        '﴿ الَّذِينَ تَتَوَفَّاهُمُ الْمَلَائِكَةُ طَيِّبِينَ يَقُولُونَ سَلَامٌ عَلَيْكُمُ ادْخُلُوا الْجَنَّةَ بِمَا كُنتُمْ تَعْمَلُونَ ﴾',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.6,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '[ سورة النحل: ٣٢ ]',
                        style: TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'اللهم اجعل ثواب تلاوة كل حرف من هذا المصحف الشريف نوراً ورحمة وضياءً لمحمد أسامة في قبره، وشفيعاً له يوم الحساب، وعوّضه عن شبابه بالجنة.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ألبوم الذكرى العطرة والإهداء',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'اسحب للتنقل ◄',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Horizontal Image Cards (Tap to view full screen)
                SizedBox(
                  height: 235,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      final item = images[index];
                      return GestureDetector(
                        onTap: () {
                          FullScreenImageViewer.open(
                            context,
                            item['path']!,
                            title: item['title']!,
                          );
                        },
                        child: Container(
                          width: 175,
                          margin: const EdgeInsets.only(left: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF14231E),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.asset(
                                        item['path']!,
                                        fit: BoxFit.cover,
                                        alignment: Alignment.topCenter,
                                        errorBuilder: (ctx, error, _) => const Center(
                                          child: Icon(Icons.image, color: Colors.grey),
                                        ),
                                      ),
                                      Positioned(
                                        top: 6,
                                        right: 6,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.6),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.fullscreen_rounded,
                                            color: Color(0xFFD4AF37),
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                                  child: Text(
                                    item['title']!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 22),

                // Du'as for the deceased Mohamed Osama
                const Text(
                  'أدعية للمغفور له بإذن الله (محمد أسامة)',
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                _duaCard(
                  context,
                  'اللهم اغفر لمحمد أسامة وارحمه، وعافه واعف عنه، وأكرم نزله، ووسّع مدخله، واغسله بالماء والثلج والبرد، ونقّه من الخطايا كما يُنقّى الثوب الأبيض من الدنس.',
                  'دعاء مأثور للمتوفى',
                ),
                const SizedBox(height: 8),
                _duaCard(
                  context,
                  'اللهم اجعل قبره روضة من رياض الجنة، ولا تجعله حفرة من حفر النار، وافتح له باباً من الجنة تهبّ عليه نسائمها ورحماتها.',
                  'دعاء للمتوفى',
                ),
                const SizedBox(height: 8),
                _duaCard(
                  context,
                  'اللهم أبدله داراً خيراً من داره، وأهلاً خيراً من أهله، وأدخله الجنة بغير حساب ولا سابقة عذاب، واجمعه مع النبيين والصديقين والشهداء.',
                  'دعاء مأثور',
                ),
                const SizedBox(height: 8),
                _duaCard(
                  context,
                  'اللهم ارحم شبابه، وعوّضه عن شبابه بالجنة ونعيمها، وأنزل على قلوب والدته وأهله ومحبيه الصبر والسلوان والسكينة واجمعهم به في الفردوس الأعلى.',
                  'دعاء لمحمد ولوالدته وأهله',
                ),
                const SizedBox(height: 8),
                _duaCard(
                  context,
                  'اللهم اجعل كل آية تُتلى في هذا التطبيق في ميزان حسنات محمد أسامة صدقةً جاريةً لا تنقطع إلى يوم القيامة.',
                  'ثواب الصدقة الجارية',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _duaCard(BuildContext context, String text, String source) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                source,
                style: const TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFFD4AF37), size: 18),
                          SizedBox(width: 8),
                          Text('تم نسخ الدعاء بنجاح - جزاكم الله خيراً'),
                        ],
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD4AF37), width: 0.8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_rounded, color: Color(0xFFD4AF37), size: 13),
                      SizedBox(width: 4),
                      Text(
                        'نسخ الدعاء',
                        style: TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
