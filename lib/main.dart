import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF07261D),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const QuranAudioApp());
}

class QuranAudioApp extends StatelessWidget {
  const QuranAudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'القرآن الكريم • صدقة جارية على روح محمد أسامة',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F4C3A),
          primary: const Color(0xFF0F4C3A),
          onPrimary: Colors.white,
          secondary: const Color(0xFFD4AF37),
          onSecondary: const Color(0xFF07261D),
          surface: Colors.white,
          surfaceContainerLowest: const Color(0xFFF8FAF9),
          surfaceContainerLow: const Color(0xFFF2F6F4),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F8F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF082D23),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
          iconTheme: IconThemeData(color: Color(0xFFD4AF37)),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1.5,
          shadowColor: const Color(0xFF0F4C3A).withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF082D23),
          contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          behavior: SnackBarBehavior.floating,
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide.none,
        ),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: SplashScreen(),
      ),
    );
  }
}
