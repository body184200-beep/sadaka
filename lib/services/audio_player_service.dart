import 'dart:async';
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
  AudioPlayerService._internal() {
    _init();
  }

  final AudioPlayer _player = AudioPlayer();
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
  Duration get position => _player.position;

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

  Future<void> _init() async {
    try {
      if (!kIsWeb) {
        final session = await AudioSession.instance;
        await session.configure(const AudioSessionConfiguration.music());
      }
    } catch (_) {}

    _player.playerStateStream.listen((state) {
      _isBuffering = state.processingState == ProcessingState.buffering;
      if (state.processingState == ProcessingState.completed) {
        _handlePlaybackCompleted();
      }
      notifyListeners();
    });

    _player.positionStream.listen((_) => notifyListeners());

    _player.durationStream.listen((dur) {
      if (dur != null && dur > Duration.zero) {
        _cachedDuration = dur;
      }
      notifyListeners();
    });

    _player.playbackEventStream.listen((event) {
      if (event.duration != null && event.duration! > Duration.zero) {
        _cachedDuration = event.duration!;
      }
      notifyListeners();
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
          await _player.setAudioSource(AudioSource.asset(assetPath));
        } else if (offlineSource.startsWith('file:')) {
          final filePath = offlineSource.substring(5);
          await _player.setAudioSource(AudioSource.file(filePath));
        }
      } else {
        // Stream online AND automatically cache in background
        _isOfflinePlayback = false;
        final url = _currentReciter.getSurahAudioUrl(surah.number);
        await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));

        // Silently cache for offline playback automatically (mobile/desktop)
        _downloadManager.autoCacheSurahInBackground(_currentReciter, surah);
      }

      _loadedAudioReciterId = _currentReciter.id;
      _loadedAudioSurahNumber = surah.number;
      await _player.setSpeed(_speed);

      if (autoPlay) {
        await _player.play();
      }
      notifyListeners();
    } catch (e) {
      _loadedAudioReciterId = null;
      _loadedAudioSurahNumber = null;
      _errorMessage = 'تعذر تشغيل تلاوة القارئ (${_currentReciter.name})، يرجى التأكد من الاتصال بالإنترنت.';
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
      await _player.play();
    }
    notifyListeners();
  }

  Future<void> play() async => await _player.play();
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
    int nextNum = _currentSurah!.number + 1;
    if (nextNum > 114) nextNum = 1;
    final nextSurah = QuranData.getSurah(nextNum);
    await playSurah(nextSurah, forceReload: true);
  }

  Future<void> playPrevious() async {
    if (_currentSurah == null) return;
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
