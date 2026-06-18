// One-off helper: renders the TDLF-Educ brand logo to a 1024x1024 PNG using
// Flutter's own engine (so no external image tools are needed), then exits.
//
// Run on any desktop target, e.g.:
//   flutter run -d windows -t tool/generate_icon.dart
//
// Output: assets/icon/app_icon.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() => runApp(const _IconGenApp());

class _IconGenApp extends StatefulWidget {
  const _IconGenApp();
  @override
  State<_IconGenApp> createState() => _IconGenAppState();
}

class _IconGenAppState extends State<_IconGenApp> {
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _capture());
  }

  Future<void> _capture() async {
    // Let the gradient + icon font fully paint first.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final boundary =
        _key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.0); // 512 * 2 = 1024px
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory('assets/icon');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final file = File('assets/icon/app_icon.png');
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
    stdout.writeln('ICON_WRITTEN: ${file.absolute.path}');
    await Future<void>.delayed(const Duration(milliseconds: 200));
    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: RepaintBoundary(
            key: _key,
            child: SizedBox(
              width: 512,
              height: 512,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF4F46E5),
                      Color(0xFF7C3AED),
                      Color(0xFFA855F7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(112),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: 84,
                      left: 84,
                      child: Container(
                        width: 176,
                        height: 176,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                      ),
                    ),
                    const Icon(Icons.school_rounded,
                        size: 264, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
