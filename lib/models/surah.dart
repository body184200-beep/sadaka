class Surah {
  final int number;
  final String name;
  final String englishName;
  final String englishTranslation;
  final int versesCount;
  final String revelationType; // 'مكية' أو 'مدنية'

  const Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishTranslation,
    required this.versesCount,
    required this.revelationType,
  });

  String get formattedNumber => number.toString().padLeft(3, '0');
  bool get isMakki => revelationType == 'مكية';
  bool get isMadani => revelationType == 'مدنية';
}
