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

  @override
  void initState() {
    super.initState();
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
    if (mounted) setState(() {});
  }

  List<Surah> _getFilteredSurahs(List<int> offlineNumbers) {
    return QuranData.surahs.where((surah) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matchesName = surah.name.contains(q);
        final matchesEnglish = surah.englishName.toLowerCase().contains(q);
        final matchesNumber = surah.number.toString() == q;
        if (!matchesName && !matchesEnglish && !matchesNumber) {
          return false;
        }
      }

      switch (_selectedFilter) {
        case 'offline':
          return offlineNumbers.contains(surah.number);
        case 'favorites':
          return _playerService.isFavorite(surah.number);
        case 'makki':
          return surah.isMakki;
        case 'madani':
          return surah.isMadani;
        case 'all':
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final reciter = _playerService.currentReciter;

    return FutureBuilder<List<int>>(
      future: _downloadManager.getDownloadedSurahNumbers(reciter.id),
      builder: (context, snapshot) {
        final offlineNumbers = snapshot.data ?? [];
        final filteredSurahs = _getFilteredSurahs(offlineNumbers);

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            title: const Row(
              children: [
                Icon(Icons.menu_book_rounded, color: Color(0xFFD4AF37), size: 24),
                SizedBox(width: 8),
                Text(
                  'القرآن الكريم الصوتي',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
                icon: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    const Icon(Icons.offline_pin_rounded, size: 26),
                    if (offlineNumbers.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFFD4AF37),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${offlineNumbers.length}',
                          style: const TextStyle(
                            color: Color(0xFF0D3B2E),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                tooltip: 'التلاوات المتاحة بدون إنترنت',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DownloadsScreen()),
                  );
                },
              ),
              const SizedBox(width: 6),
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
                // Dedication Banner Card (الوالدة الكريمة ومحمد أسامة)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                  child: InkWell(
                    onTap: () => DedicationDialog.show(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D3B2E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD4AF37), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D3B2E).withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Thumbnail of mother and son (Top-aligned for clear faces)
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
                                  blurRadius: 6,
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
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'صدقة جارية على روح محمد أسامة',
                                      style: TextStyle(
                                        color: Color(0xFFD4AF37),
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.verified_rounded, color: Color(0xFFD4AF37), size: 14),
                                  ],
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'اللهم اغفر له وارحمه واجعله في الفردوس الأعلى',
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'الأدعية والصور',
                              style: TextStyle(
                                color: Color(0xFFD4AF37),
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Reciter Selector Card
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RecitersScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F4C3A), Color(0xFF1B6B53)],
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F4C3A).withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
                            ),
                            child: const Center(
                              child: Icon(Icons.record_voice_over_rounded, color: Color(0xFFD4AF37), size: 20),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'القارئ الحالي',
                                  style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10.5, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  reciter.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Text(
                                  'تغيير',
                                  style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                                ),
                                Icon(Icons.chevron_left_rounded, color: Colors.white, size: 15),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'ابحث عن سورة بالاسم أو الرقم...',
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1B6B53)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
                      ),
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                    },
                  ),
                ),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Row(
                    children: [
                      _filterChip('all', 'جميع السور (114)'),
                      _filterChip('offline', 'جاهزة أوفلاين بدون نت (${offlineNumbers.length})'),
                      _filterChip('favorites', 'المفضلة (${_playerService.favoriteSurahs.length})'),
                      _filterChip('makki', 'مكية (86)'),
                      _filterChip('madani', 'مدنية (28)'),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // Surahs List
                Expanded(
                  child: filteredSurahs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _selectedFilter == 'offline'
                                    ? Icons.offline_pin_outlined
                                    : Icons.search_off_rounded,
                                size: 54,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _selectedFilter == 'offline'
                                    ? 'لا توجد سور محملة أوفلاين حالياً'
                                    : 'لا توجد سور مطابقة لبحثك',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredSurahs.length,
                          itemBuilder: (context, index) {
                            final surah = filteredSurahs[index];
                            return SurahListTile(
                              surah: surah,
                              onTap: () {
                                _playerService.playOrToggleSurah(surah);
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const PlayerScreen()),
                                );
                              },
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
      },
    );
  }

  Widget _filterChip(String id, String label) {
    final isSelected = _selectedFilter == id;
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF1B6B53),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF1B6B53),
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected ? const Color(0xFF1B6B53) : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        onSelected: (_) {
          setState(() => _selectedFilter = id);
        },
      ),
    );
  }
}
