import 'package:flutter/material.dart';
import '../models/surah.dart';
import '../services/audio_player_service.dart';
import '../services/download_manager.dart';
import '../services/quran_data.dart';
import '../widgets/dedication_dialog.dart';
import '../widgets/mini_player.dart';
import '../widgets/surah_list_tile.dart';
import 'downloads_screen.dart';
import 'player_screen.dart';
import 'reciters_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioPlayerService _playerService = AudioPlayerService();
  final DownloadManager _downloadManager = DownloadManager();

  String _searchQuery = '';
  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  List<Surah> _filteredSurahs = QuranData.surahs;

  static const List<int> _quickSurahNumbers = [1, 18, 36, 55, 56, 67, 112, 113, 114];

  @override
  void initState() {
    super.initState();
    _updateFilteredSurahs(notify: false);
    _playerService.addListener(_onServiceUpdate);
    _downloadManager.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _playerService.removeListener(_onServiceUpdate);
    _downloadManager.removeListener(_onServiceUpdate);
    _searchController.dispose();
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) {
      _updateFilteredSurahs();
    }
  }

  void _updateFilteredSurahs({bool notify = true}) {
    final q = _searchQuery.trim().toLowerCase();
    final favs = _playerService.favoriteSurahs;

    final results = QuranData.surahs.where((surah) {
      if (q.isNotEmpty) {
        final matchesName = surah.name.contains(q);
        final matchesEnglish = surah.englishName.toLowerCase().contains(q);
        final matchesNumber = surah.number.toString() == q;
        if (!matchesName && !matchesEnglish && !matchesNumber) {
          return false;
        }
      }

      switch (_selectedFilter) {
        case 'favorites':
          return favs.contains(surah.number);
        case 'makki':
          return surah.isMakki;
        case 'madani':
          return surah.isMadani;
        case 'all':
        default:
          return true;
      }
    }).toList();

    if (notify) {
      setState(() {
        _filteredSurahs = results;
      });
    } else {
      _filteredSurahs = results;
    }
  }

  void _playSurah(Surah surah) {
    _playerService.playOrToggleSurah(surah);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PlayerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reciter = _playerService.currentReciter;
    final currentSurah = _playerService.currentSurah;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD4AF37), width: 1),
              ),
              child: const Icon(Icons.menu_book_rounded, color: Color(0xFFD4AF37), size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'القرآن الكريم',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'صدقة جارية • محمد أسامة',
                  style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.offline_pin_rounded, color: Colors.white, size: 13),
                  SizedBox(width: 4),
                  Text(
                    '114 أوفلاين',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Dedication / Sadaqah Jariyah button
          IconButton(
            icon: const Icon(Icons.favorite_rounded, color: Color(0xFFD4AF37), size: 24),
            tooltip: 'صدقة جارية على روح محمد أسامة',
            onPressed: () => DedicationDialog.show(context),
          ),
          // Offline Surahs button
          IconButton(
            icon: const Icon(Icons.download_done_rounded, color: Colors.white, size: 24),
            tooltip: 'التلاوات المتاحة بدون إنترنت',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DownloadsScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7FAF8), Color(0xFFEFF5F1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Unified Royal Islamic Hero Card
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF06231B), Color(0xFF0F4738), Color(0xFF08271F)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF06231B).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Basmalah Calligraphy Header
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                      ),
                      child: const Center(
                        child: Text(
                          '❖  بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ  ❖',
                          style: TextStyle(
                            color: Color(0xFFE5C158),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      child: Column(
                        children: [
                          // Memorial Tribute Row (Mohamed Osama)
                          InkWell(
                            onTap: () => DedicationDialog.show(context),
                            borderRadius: BorderRadius.circular(14),
                            child: Row(
                              children: [
                                // Glowing circular avatar
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/mother_and_son.jpg',
                                      fit: BoxFit.cover,
                                      alignment: Alignment.topCenter,
                                      errorBuilder: (ctx, error, _) => const Icon(
                                        Icons.favorite,
                                        color: Color(0xFFD4AF37),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'صدقة جارية على روح محمد أسامة',
                                            style: TextStyle(
                                              color: Color(0xFFE5C158),
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(Icons.verified_rounded, color: Color(0xFFD4AF37), size: 14),
                                        ],
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'اللهم اجعل القرآن الكريم نوراً له وأسكنه الفردوس الأعلى',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD4AF37).withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFD4AF37), width: 0.8),
                                  ),
                                  child: const Text(
                                    'الأدعية والذكرى 🤍',
                                    style: TextStyle(
                                      color: Color(0xFFE5C158),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),
                          Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
                          const SizedBox(height: 8),

                          // Reciter & Feature Pills Row
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RecitersScreen()),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Row(
                              children: [
                                const Icon(Icons.record_voice_over_rounded, color: Color(0xFFD4AF37), size: 18),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'القارئ: ${reciter.name} (المصحف المرتل)',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'تضخيم صوت +20dB ⚡',
                                    style: TextStyle(
                                      color: Color(0xFFE5C158),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Quick Surahs Shortlist (السور المباركة)
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _quickSurahNumbers.length,
                itemBuilder: (context, index) {
                  final surahNum = _quickSurahNumbers[index];
                  final surah = QuranData.getSurahByNumber(surahNum);
                  if (surah == null) return const SizedBox.shrink();

                  final isCurrent = currentSurah?.number == surah.number;

                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: InkWell(
                      onTap: () => _playSurah(surah),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCurrent ? const Color(0xFF0F4C3A) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isCurrent ? const Color(0xFFD4AF37) : const Color(0xFFD0DDD6),
                            width: isCurrent ? 1.4 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCurrent ? Icons.volume_up_rounded : Icons.star_rounded,
                              size: 14,
                              color: isCurrent ? const Color(0xFFD4AF37) : const Color(0xFF1B6B53),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              surah.name,
                              style: TextStyle(
                                color: isCurrent ? Colors.white : const Color(0xFF0F4C3A),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
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

            const SizedBox(height: 4),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن سورة بالاسم أو الرقم...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1B6B53)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _searchQuery = '';
                              _updateFilteredSurahs();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  ),
                  onChanged: (val) {
                    _searchQuery = val;
                    _updateFilteredSurahs();
                  },
                ),
              ),
            ),

            // Filter Tabs Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  _filterChip('all', 'جميع السور (114)', Icons.menu_book_rounded),
                  _filterChip('favorites', 'المفضلة (${_playerService.favoriteSurahs.length})', Icons.star_rounded),
                  _filterChip('makki', 'مكية (86)', Icons.location_on_outlined),
                  _filterChip('madani', 'مدنية (28)', Icons.mosque_outlined),
                ],
              ),
            ),

            if (_playerService.errorMessage != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFEEBA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFF856404), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _playerService.errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFF856404),
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _selectedFilter = 'all';
                        _updateFilteredSurahs();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('جميع السور', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

            // Surahs List Header (Title & Count)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'سور القرآن الكريم (${_filteredSurahs.length})',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'تلاوة الشيخ المنشاوي',
                    style: TextStyle(
                      color: Color(0xFF1B6B53),
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Surahs List
            Expanded(
              child: _filteredSurahs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 50,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'لا توجد سور مطابقة للبحث',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredSurahs.length,
                      physics: const BouncingScrollPhysics(),
                      cacheExtent: 600,
                      addRepaintBoundaries: true,
                      itemBuilder: (context, index) {
                        final surah = _filteredSurahs[index];
                        return SurahListTile(
                          key: ValueKey(surah.number),
                          surah: surah,
                          onTap: () => _playSurah(surah),
                        );
                      },
                    ),
            ),

            // Floating Mini Player
            const MiniPlayer(),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String id, String label, [IconData? icon]) {
    final isSelected = _selectedFilter == id;
    return Padding(
      padding: const EdgeInsets.only(left: 6.0),
      child: FilterChip(
        selected: isSelected,
        avatar: icon != null
            ? Icon(
                icon,
                size: 15,
                color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFF0F4C3A),
              )
            : null,
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF0F4C3A),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          fontSize: 12,
        ),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF0F4C3A),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? const Color(0xFFD4AF37) : Colors.grey.withValues(alpha: 0.22),
            width: isSelected ? 1.4 : 1,
          ),
        ),
        onSelected: (_) {
          _selectedFilter = id;
          _updateFilteredSurahs();
        },
      ),
    );
  }
}
