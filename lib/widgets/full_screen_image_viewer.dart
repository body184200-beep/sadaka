import 'package:flutter/material.dart';

class FullScreenImageViewer extends StatelessWidget {
  final String imagePath;
  final String title;

  const FullScreenImageViewer({
    super.key,
    required this.imagePath,
    this.title = '',
  });

  static void open(BuildContext context, String imagePath, {String title = ''}) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (ctx, anim, secondaryAnim) => FullScreenImageViewer(imagePath: imagePath, title: title),
        transitionsBuilder: (ctx, animation, _, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.94),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4.0,
          child: Hero(
            tag: imagePath,
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: (ctx, error, _) => const Center(
                child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 60),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
