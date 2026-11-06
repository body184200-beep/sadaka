import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/reciter.dart';
import '../models/surah.dart';

class DownloadManager extends ChangeNotifier {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal();

  final Dio _dio = Dio();
  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, double> _downloadProgress = {};

  // List of all 114 surahs pre-bundled for Sheikh Mohamed Siddiq El-Minshawi
  static final List<int> _minshAllSurahs = List.generate(114, (i) => i + 1);

  static final Map<String, List<int>> _bundledAssets = {
    'minsh': _minshAllSurahs,
  };

  Map<String, double> get downloadProgress => _downloadProgress;

  bool isDownloading(String reciterId, int surahNumber) {
    return _downloadProgress.containsKey('${reciterId}_$surahNumber');
  }

  double getProgress(String reciterId, int surahNumber) {
    return _downloadProgress['${reciterId}_$surahNumber'] ?? 0.0;
  }

  Future<String?> _getReciterDirectory(String reciterId) async {
    if (kIsWeb) return null;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDir.path}/quran_audio/$reciterId');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir.path;
    } catch (_) {
      return null;
    }
  }

  Future<File?> getLocalFile(String reciterId, int surahNumber) async {
    if (kIsWeb) return null;
    try {
      final reciterDir = await _getReciterDirectory(reciterId);
      if (reciterDir == null) return null;
      final fileName = '${surahNumber.toString().padLeft(3, '0')}.mp3';
      return File('$reciterDir/$fileName');
    } catch (_) {
      return null;
    }
  }

  bool isBundled(String reciterId, int surahNumber) {
    return _bundledAssets[reciterId]?.contains(surahNumber) ?? false;
  }

  Future<bool> isSurahDownloaded(String reciterId, int surahNumber) async {
    if (isBundled(reciterId, surahNumber)) {
      return true;
    }
    if (kIsWeb) {
      return false;
    }
    try {
      final file = await getLocalFile(reciterId, surahNumber);
      return file != null && await file.exists();
    } catch (_) {
      return false;
    }
  }

  /// Returns audio source:
  /// 'asset:assets/audio/afs_001.mp3' or 'file:/path/to/001.mp3' or null
  Future<String?> getOfflineAudioSource(String reciterId, int surahNumber) async {
    final formatted = surahNumber.toString().padLeft(3, '0');

    // 1. Check exact reciter bundled asset
    if (_bundledAssets[reciterId]?.contains(surahNumber) ?? false) {
      return 'asset:assets/audio/${reciterId}_$formatted.mp3';
    }

    // 2. Check cached local file on device (non-web)
    if (!kIsWeb) {
      try {
        final file = await getLocalFile(reciterId, surahNumber);
        if (file != null && await file.exists()) {
          return 'file:${file.path}';
        }
      } catch (_) {}
    }

    return null;
  }

  /// Auto-caches a surah in background silently while playing (on mobile/desktop)
  Future<void> autoCacheSurahInBackground(Reciter reciter, Surah surah) async {
    if (kIsWeb) return;
    final key = '${reciter.id}_${surah.number}';
    if (_downloadProgress.containsKey(key)) return;

    try {
      final file = await getLocalFile(reciter.id, surah.number);
      if (file == null || await file.exists()) return;

      final url = reciter.getSurahAudioUrl(surah.number);
      final tempFile = File('${file.path}.tmp');

      await _dio.download(url, tempFile.path);
      if (await tempFile.exists()) {
        await tempFile.rename(file.path);
        notifyListeners();
      }
    } catch (_) {
      // Silently ignore background caching errors
    }
  }

  Future<bool> downloadSurah({
    required Reciter reciter,
    required Surah surah,
    VoidCallback? onCompleted,
    Function(String error)? onError,
  }) async {
    if (kIsWeb) {
      onCompleted?.call();
      return true;
    }
    final key = '${reciter.id}_${surah.number}';
    if (_downloadProgress.containsKey(key)) return false;

    final cancelToken = CancelToken();
    _cancelTokens[key] = cancelToken;
    _downloadProgress[key] = 0.01;
    notifyListeners();

    try {
      final file = await getLocalFile(reciter.id, surah.number);
      if (file == null) throw Exception('Path error');
      final tempFile = File('${file.path}.download');
      final url = reciter.getSurahAudioUrl(surah.number);

      await _dio.download(
        url,
        tempFile.path,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            _downloadProgress[key] = received / total;
            notifyListeners();
          }
        },
      );

      if (await tempFile.exists()) {
        if (await file.exists()) {
          await file.delete();
        }
        await tempFile.rename(file.path);
      }

      _downloadProgress.remove(key);
      _cancelTokens.remove(key);
      notifyListeners();
      onCompleted?.call();
      return true;
    } catch (e) {
      _downloadProgress.remove(key);
      _cancelTokens.remove(key);
      notifyListeners();
      if (!CancelToken.isCancel(e as DioException? ?? DioException(requestOptions: RequestOptions()))) {
        onError?.call('فشل تحميل السورة');
      }
      return false;
    }
  }

  void cancelDownload(String reciterId, int surahNumber) {
    final key = '${reciterId}_$surahNumber';
    _cancelTokens[key]?.cancel('User cancelled');
    _cancelTokens.remove(key);
    _downloadProgress.remove(key);
    notifyListeners();
  }

  Future<bool> deleteDownloadedSurah(String reciterId, int surahNumber) async {
    if (kIsWeb) return false;
    try {
      final file = await getLocalFile(reciterId, surahNumber);
      if (file != null && await file.exists()) {
        await file.delete();
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<List<int>> getDownloadedSurahNumbers(String reciterId) async {
    final list = <int>{};
    if (_bundledAssets.containsKey(reciterId)) {
      list.addAll(_bundledAssets[reciterId]!);
    }

    if (!kIsWeb) {
      try {
        final dirPath = await _getReciterDirectory(reciterId);
        if (dirPath != null) {
          final dir = Directory(dirPath);
          if (await dir.exists()) {
            final files = dir.listSync();
            for (final f in files) {
              if (f is File && f.path.endsWith('.mp3')) {
                final fileName = f.uri.pathSegments.last.replaceAll('.mp3', '');
                final num = int.tryParse(fileName);
                if (num != null) list.add(num);
              }
            }
          }
        }
      } catch (_) {}
    }

    final sorted = list.toList()..sort();
    return sorted;
  }

  Future<int> getDownloadedTotalBytes(String reciterId) async {
    if (kIsWeb) {
      return 25 * 1024 * 1024; // 25 MB estimated for bundled assets
    }
    int total = 0;
    try {
      final dirPath = await _getReciterDirectory(reciterId);
      if (dirPath != null) {
        final dir = Directory(dirPath);
        if (await dir.exists()) {
          final files = dir.listSync();
          for (final f in files) {
            if (f is File) {
              total += await f.length();
            }
          }
        }
      }
    } catch (_) {}
    return total;
  }
}
