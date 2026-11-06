import 'dart:async';
import 'dart:io';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reciter.dart';
import '../models/surah.dart';
import 'download_manager.dart';
import 'quran_data.dart';

enum QuranRepeatMode { none, one, all }

class AudioPlayerService extends ChangeNotifier {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;

  late final AudioPlayer _player;
  late final AndroidLoudnessEnhancer? _loudnessEnhancer;
  final DownloadManager _downloadManager = DownloadManager();

  Surah? _currentSurah;
  Reciter _currentReciter = QuranData.reciters.first;
  bool _isOfflinePlayback = false;
  QuranRepeatMode _repeatMode = QuranRepeatMode.all;
  double _speed = 1.0;
  bool _isBuffering = false;
  String? _errorMessage;
  Duration _cachedDuration = Duration.zero;

  Timer? _sleepTimer;
  DateTime? _sleepTimerEndTime;

  String? _loadedAudioReciterId;
  int? _loadedAudioSurahNumber;

  final Set<int> _favoriteSurahs = {};
  double _loudnessGain = 18.0; // Extreme boost in dB (up to 20 dB maximum)
  bool _isLoudnessBoostEnabled = true;
  final ValueNotifier<Duration> positionNotifier = ValueNotifier<Duration>(Duration.zero);

  AudioPlayerService._internal() {
    if (!kIsWeb && Platform.isAndroid) {
      _loudnessEnhancer = AndroidLoudnessEnhancer();
      _player = AudioPlayer(
        audioPipeline: AudioPipeline(
          androidAudioEffects: [
            _loudnessEnhancer!,
          ],
        ),
      );
    } else {
      _loudnessEnhancer = null;
      _player = AudioPlayer();
    }
    _init();
  }

  AudioPlayer get player => _player;
  Surah? get currentSurah => _currentSurah;
  Reciter get currentReciter => _currentReciter;
  String? get loadedAudioReciterId => _loadedAudioReciterId;
  int? get loadedAudioSurahNumber => _loadedAudioSurahNumber;
  bool get isOfflinePlayback => _isOfflinePlayback;
  QuranRepeatMode get repeatMode => _repeatMode;
  double get speed => _speed;
  bool get isBuffering => _isBuffering;
  String? get errorMessage => _errorMessage;
  Set<int> get favoriteSurahs => _favoriteSurahs;
  bool get isPlaying => _player.playing;
  Duration get position => positionNotifier.value;
  Stream<Duration> get positionStream => _player.positionStream;

  Duration get duration {
    final d = _player.duration;
    if (d != null && d > Duration.zero) {
      _cachedDuration = d;
      return d;
    }
    return _cachedDuration;
  }

  int? get sleepTimerMinutesRemaining {
    if (_sleepTimerEndTime == null) return null;
    final diff = _sleepTimerEndTime!.difference(DateTime.now()).inMinutes;
    return diff > 0 ? diff + 1 : 0;
  }

  double get loudnessGain => _loudnessGain;
  bool get isLoudnessBoostEnabled => _isLoudnessBoostEnabled;
  bool get hasLoudnessEnhancer => _loudnessEnhancer != null;

  Future<void> applyMaximumVolumeSettings() async {
    try {
      await _player.setVolume(1.0);
      if (_loudnessEnhancer != null) {
        await _loudnessEnhancer!.setEnabled(_isLoudnessBoostEnabled);
        if (_isLoudnessBoostEnabled) {
          await _loudnessEnhancer!.setTargetGain(_loudnessGain);
        }
      }
    } catch (_) {}
  }

  Future<void> setLoudnessGain(double gain) async {
    _loudnessGain = gain.clamp(0.0, 20.0);
    _isLoudnessBoostEnabled = _loudnessGain > 0;
    await applyMaximumVolumeSettings();
    notifyListeners();
  }

  Future<void> toggleLoudnessBoost() async {
    _isLoudnessBoostEnabled = !_isLoudnessBoostEnabled;
    await applyMaximumVolumeSettings();
    notifyListeners();
  }

  Future<void> _init() async {
    try {
      if (!kIsWeb) {
        final session = await AudioSession.instance;
        await session.configure(const AudioSessionConfiguration.music());
        await session.setActive(true);
      }
    } catch (_) {}

    await applyMaximumVolumeSettings();

    _player.playerStateStream.listen((state) {
      _isBuffering = state.processingState == ProcessingState.buffering;
      if (state.processingState == ProcessingState.completed) {
        _handlePlaybackCompleted();
      }
      notifyListeners();
    });

    _player.positionStream.listen((pos) {
      positionNotifier.value = pos;
    });

    _player.durationStream.listen((dur) {
      if (dur != null && dur > Duration.zero && dur != _cachedDuration) {
        _cachedDuration = dur;
        notifyListeners();
      }
    });

    _player.playbackEventStream.listen((event) {
      if (event.duration != null && event.duration! > Duration.zero && event.duration! != _cachedDuration) {
        _cachedDuration = event.duration!;
        notifyListeners();
      }
    });

    await _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favList = prefs.getStringList('favorite_surahs') ?? [];
      _favoriteSurahs.addAll(favList.map((e) => int.tryParse(e) ?? 0).where((n) => n > 0));

      final reciterId = prefs.getString('last_reciter_id');
      if (reciterId != null) {
        final r = QuranData.reciters.firstWhere((x) => x.id == reciterId, orElse: () => QuranData.reciters.first);
        _currentReciter = r;
      }

      final lastSurahNum = prefs.getInt('last_surah_number');
      if (lastSurahNum != null && lastSurahNum >= 1 && lastSurahNum <= 114) {
        _currentSurah = QuranData.getSurah(lastSurahNum);
      } else {
        _currentSurah = QuranData.surahs.first;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorite_surahs', _favoriteSurahs.map((e) => e.toString()).toList());
      await prefs.setString('last_reciter_id', _currentReciter.id);
      if (_currentSurah != null) {
        await prefs.setInt('last_surah_number', _currentSurah!.number);
      }
    } catch (_) {}
  }

  void toggleFavorite(int surahNumber) {
    if (_favoriteSurahs.contains(surahNumber)) {
      _favoriteSurahs.remove(surahNumber);
    } else {
      _favoriteSurahs.add(surahNumber);
    }
    _savePreferences();
    notifyListeners();
  }

  bool isFavorite(int surahNumber) => _favoriteSurahs.contains(surahNumber);

  Future<void> setReciter(Reciter reciter) async {
    if (_currentReciter.id == reciter.id) return;
    _currentReciter = reciter;
    _savePreferences();
    notifyListeners();

    final wasPlaying = _player.playing;
    _loadedAudioReciterId = null;

    if (_currentSurah != null) {
      await playSurah(
        _currentSurah!,
        reciter: reciter,
        forceReload: true,
        autoPlay: wasPlaying,
      );
    }
  }

  /// Toggles play/pause if already loaded, or loads and plays if different surah or reciter
  Future<void> playOrToggleSurah(Surah surah, {Reciter? reciter}) async {
    final targetReciter = reciter ?? _currentReciter;
    final isSameSurahAndReciter = _currentSurah?.number == surah.number &&
        _loadedAudioReciterId == targetReciter.id &&
        _player.audioSource != null;

    if (isSameSurahAndReciter) {
      await togglePlayPause();
      return;
    }
    await playSurah(surah, reciter: targetReciter, forceReload: true, autoPlay: true);
  }

  Future<bool> _checkInternet() async {
    if (kIsWeb) return true;
    try {
      final lookup = await InternetAddress.lookup('dns.google').timeout(const Duration(seconds: 2));
      return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> playSurah(
    Surah surah, {
    Reciter? reciter,
    bool autoPlay = true,
    bool forceReload = false,
  }) async {
    final targetReciter = reciter ?? _currentReciter;

    // If same surah and already loaded and not force reloading, just ensure playback
    if (!forceReload &&
        _currentSurah?.number == surah.number &&
        _loadedAudioReciterId == targetReciter.id &&
        _player.audioSource != null) {
      if (autoPlay && !_player.playing) {
        await _player.play();
      }
      return;
    }

    _currentSurah = surah;
    _currentReciter = targetReciter;
    _errorMessage = null;
    _cachedDuration = Duration.zero;
    _savePreferences();
    notifyListeners();

    try {
      final offlineSource = await _downloadManager.getOfflineAudioSource(_currentReciter.id, surah.number);
      if (offlineSource != null) {
        _isOfflinePlayback = true;
        if (offlineSource.startsWith('asset:')) {
          final assetPath = offlineSource.substring(6);
          await _player.setAsset(assetPath);
        } else if (offlineSource.startsWith('file:')) {
          final filePath = offlineSource.substring(5);
          await _player.setFilePath(filePath);
        }
      } else {
        // Not offline: check internet before attempting to stream so we don't freeze on buffering
        if (!kIsWeb) {
          final hasInternet = await _checkInternet();
          if (!hasInternet) {
            _isBuffering = false;
            _errorMessage = 'سورة ${surah.name} غير مدمجة أوفلاين للقارئ (${_currentReciter.name})، يرجى تشغيل الإنترنت لتشغيلها أو اختيار سورة مدمجة بدون نت من قائمة «جاهزة أوفلاين».';
            notifyListeners();
            return;
          }
        }

        // Stream online AND automatically cache in background
        _isOfflinePlayback = false;
        final url = _currentReciter.getSurahAudioUrl(surah.number);
        await _player.setUrl(url).timeout(const Duration(seconds: 8));

        // Silently cache for offline playback automatically (mobile/desktop)
        _downloadManager.autoCacheSurahInBackground(_currentReciter, surah);
      }

      _loadedAudioReciterId = _currentReciter.id;
      _loadedAudioSurahNumber = surah.number;
      await _player.setSpeed(_speed);
      await applyMaximumVolumeSettings();

      if (autoPlay) {
        await _player.play();
      }
      notifyListeners();
    } catch (e) {
      _loadedAudioReciterId = null;
      _loadedAudioSurahNumber = null;
      _isBuffering = false;
      _errorMessage = 'تعذر تشغيل سورة ${surah.name} للقارئ (${_currentReciter.name}). يرجى التحقق من اتصال الإنترنت أو اختيار سورة أوفلاين.';
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    if (_currentSurah == null) return;

    final isLoadedCurrent = _loadedAudioSurahNumber == _currentSurah!.number &&
        _loadedAudioReciterId == _currentReciter.id &&
        _player.audioSource != null;

    if (!isLoadedCurrent) {
      await playSurah(_currentSurah!, reciter: _currentReciter, forceReload: true, autoPlay: true);
      return;
    }

    if (_player.playing) {
      await _player.pause();
    } else {
      await applyMaximumVolumeSettings();
      await _player.play();
    }
    notifyListeners();
  }

  Future<void> play() async {
    await applyMaximumVolumeSettings();
    await _player.play();
  }
  Future<void> pause() async => await _player.pause();

  Future<void> seek(Duration targetPosition) async {
    try {
      final max = duration;
      final clamped = targetPosition < Duration.zero
          ? Duration.zero
          : (max > Duration.zero && targetPosition > max ? max : targetPosition);
      await _player.seek(clamped);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> seekForward([int seconds = 10]) async {
    final target = _player.position + Duration(seconds: seconds);
    await seek(target);
  }

  Future<void> seekBackward([int seconds = 10]) async {
    final target = _player.position - Duration(seconds: seconds);
    await seek(target);
  }

  Future<void> playNext() async {
    if (_currentSurah == null) return;
    final offlineNumbers = await _downloadManager.getDownloadedSurahNumbers(_currentReciter.id);
    if (offlineNumbers.isNotEmpty && !await _checkInternet()) {
      // In offline mode: smoothly advance to the next available offline surah
      final currentIndex = offlineNumbers.indexOf(_currentSurah!.number);
      int nextIndex = (currentIndex + 1) % offlineNumbers.length;
      final nextSurah = QuranData.getSurah(offlineNumbers[nextIndex]);
      await playSurah(nextSurah, forceReload: true);
      return;
    }

    int nextNum = _currentSurah!.number + 1;
    if (nextNum > 114) nextNum = 1;
    final nextSurah = QuranData.getSurah(nextNum);
    await playSurah(nextSurah, forceReload: true);
  }

  Future<void> playPrevious() async {
    if (_currentSurah == null) return;
    final offlineNumbers = await _downloadManager.getDownloadedSurahNumbers(_currentReciter.id);
    if (offlineNumbers.isNotEmpty && !await _checkInternet()) {
      // In offline mode: smoothly advance to the previous available offline surah
      final currentIndex = offlineNumbers.indexOf(_currentSurah!.number);
      int prevIndex = currentIndex <= 0 ? offlineNumbers.length - 1 : currentIndex - 1;
      final prevSurah = QuranData.getSurah(offlineNumbers[prevIndex]);
      await playSurah(prevSurah, forceReload: true);
      return;
    }

    int prevNum = _currentSurah!.number - 1;
    if (prevNum < 1) prevNum = 114;
    final prevSurah = QuranData.getSurah(prevNum);
    await playSurah(prevSurah, forceReload: true);
  }

  Future<void> setSpeed(double newSpeed) async {
    _speed = newSpeed;
    await _player.setSpeed(newSpeed);
    notifyListeners();
  }

  void cycleSpeed() {
    double nextSpeed;
    if (_speed == 1.0) {
      nextSpeed = 1.25;
    } else if (_speed == 1.25) {
      nextSpeed = 1.5;
    } else if (_speed == 1.5) {
      nextSpeed = 1.75;
    } else if (_speed == 1.75) {
      nextSpeed = 2.0;
    } else if (_speed == 2.0) {
      nextSpeed = 0.75;
    } else {
      nextSpeed = 1.0;
    }
    setSpeed(nextSpeed);
  }

  void toggleRepeatMode() {
    switch (_repeatMode) {
      case QuranRepeatMode.none:
        _repeatMode = QuranRepeatMode.one;
        break;
      case QuranRepeatMode.one:
        _repeatMode = QuranRepeatMode.all;
        break;
      case QuranRepeatMode.all:
        _repeatMode = QuranRepeatMode.none;
        break;
    }
    notifyListeners();
  }

  void _handlePlaybackCompleted() {
    if (_repeatMode == QuranRepeatMode.one) {
      _player.seek(Duration.zero);
      _player.play();
    } else if (_repeatMode == QuranRepeatMode.all) {
      playNext();
    }
  }

  void setSleepTimer(int minutes) {
    cancelSleepTimer();
    if (minutes <= 0) return;
    _sleepTimerEndTime = DateTime.now().add(Duration(minutes: minutes));
    _sleepTimer = Timer(Duration(minutes: minutes), () {
      pause();
      cancelSleepTimer();
    });
    notifyListeners();
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerEndTime = null;
    notifyListeners();
  }

  String formatDuration(Duration d) {
    if (d <= Duration.zero) return '00:00';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = d.inHours;
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _player.dispose();
    super.dispose();
  }
}
