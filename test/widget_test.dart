import 'package:flutter_test/flutter_test.dart';
import 'package:mohamed_osama/services/quran_data.dart';

void main() {
  test('Quran data contains all 114 surahs and reciters', () {
    expect(QuranData.surahs.length, 114);
    expect(QuranData.surahs.first.name, 'الفاتحة');
    expect(QuranData.surahs.last.name, 'الناس');
    expect(QuranData.reciters.isNotEmpty, true);
    expect(QuranData.getSurah(1).name, 'الفاتحة');
  });
}
