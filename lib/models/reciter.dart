class Reciter {
  final String id;
  final String name;
  final String subName;
  final String serverUrl;
  final String style; // حفص عن عاصم، مرتل، مجود
  final String? assetPrefix; // If specific assets are bundled

  const Reciter({
    required this.id,
    required this.name,
    required this.subName,
    required this.serverUrl,
    required this.style,
    this.assetPrefix,
  });

  String getSurahAudioUrl(int surahNumber) {
    final formatted = surahNumber.toString().padLeft(3, '0');
    return '$serverUrl$formatted.mp3';
  }
}
