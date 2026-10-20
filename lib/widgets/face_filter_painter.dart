import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

enum FaceFilter { none, mask, glasses, catEars, crown, mustache }

extension FaceFilterExt on FaceFilter {
  String get label {
    switch (this) {
      case FaceFilter.none: return 'None';
      case FaceFilter.mask: return '😷 Masker';
      case FaceFilter.glasses: return '🕶️ Kacamata';
      case FaceFilter.catEars: return '🐱 Kucing';
      case FaceFilter.crown: return '👑 Mahkota';
      case FaceFilter.mustache: return '🥸 Kumis';
    }
  }
}

class FaceFilterPainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;
  final FaceFilter filter;
  final bool isFrontCamera;

  FaceFilterPainter({
    required this.faces,
    required this.imageSize,
    required this.filter,
    required this.isFrontCamera,
  });

  // Konversi titik dari koordinat image ke koordinat layar
  Offset _scalePoint(Point point, Size size) {
    final double imgW = imageSize.height;
    final double imgH = imageSize.width;
    final double scaleX = size.width / imgW;
    final double scaleY = size.height / imgH;

    double x = point.x.toDouble() * scaleX;
    double y = point.y.toDouble() * scaleY;

    if (isFrontCamera) x = size.width - x;
    return Offset(x, y);
  }

  // Konversi bounding box
  Rect _scaleRect(Rect rect, Size size) {
    final double imgW = imageSize.height;
    final double imgH = imageSize.width;
    final double scaleX = size.width / imgW;
    final double scaleY = size.height / imgH;

    double left = rect.left * scaleX;
    double top = rect.top * scaleY;
    double w = rect.width * scaleX;
    double h = rect.height * scaleY;

    if (isFrontCamera) left = size.width - left - w;
    return Rect.fromLTWH(left, top, w, h);
  }

  void _drawEmoji(Canvas canvas, String emoji, Offset position, double fontSize) {
    final tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = TextSpan(text: emoji, style: TextStyle(fontSize: fontSize));
    tp.layout();
    // Center emoji di posisi yang diberikan
    tp.paint(canvas, Offset(position.dx - tp.width / 2, position.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (filter == FaceFilter.none || faces.isEmpty) return;

    for (final face in faces) {
      final scaledRect = _scaleRect(face.boundingBox, size);
      final faceW = scaledRect.width;
      final faceH = scaledRect.height;

      // Ambil landmark kalau ada
      final leftEye = face.landmarks[FaceLandmarkType.leftEye];
      final rightEye = face.landmarks[FaceLandmarkType.rightEye];
      final noseBase = face.landmarks[FaceLandmarkType.noseBase];
      final bottomMouth = face.landmarks[FaceLandmarkType.bottomMouth];
      final leftMouth = face.landmarks[FaceLandmarkType.leftMouth];
      final rightMouth = face.landmarks[FaceLandmarkType.rightMouth];
      final leftEar = face.landmarks[FaceLandmarkType.leftEar];
      final rightEar = face.landmarks[FaceLandmarkType.rightEar];

      switch (filter) {
        case FaceFilter.glasses:
          if (leftEye != null && rightEye != null) {
            final leftPos = _scalePoint(leftEye.position, size);
            final rightPos = _scalePoint(rightEye.position, size);
            // Tengah antara dua mata
            final center = Offset(
              (leftPos.dx + rightPos.dx) / 2,
              (leftPos.dy + rightPos.dy) / 2,
            );
            _drawEmoji(canvas, '🕶️', center, faceW * 0.9);
          } else {
            // Fallback pakai bounding box
            _drawEmoji(canvas, '🕶️',
              Offset(scaledRect.center.dx, scaledRect.top + faceH * 0.35),
              faceW * 0.9);
          }
          break;

        case FaceFilter.mask:
          if (bottomMouth != null) {
            final pos = _scalePoint(bottomMouth.position, size);
            _drawEmoji(canvas, '😷', Offset(scaledRect.center.dx, pos.dy), faceW * 0.9);
          } else if (leftMouth != null && rightMouth != null) {
            final lPos = _scalePoint(leftMouth.position, size);
            final rPos = _scalePoint(rightMouth.position, size);
            final center = Offset((lPos.dx + rPos.dx) / 2, (lPos.dy + rPos.dy) / 2);
            _drawEmoji(canvas, '😷', center, faceW * 0.9);
          } else {
            _drawEmoji(canvas, '😷',
              Offset(scaledRect.center.dx, scaledRect.top + faceH * 0.72),
              faceW * 0.9);
          }
          break;

        case FaceFilter.mustache:
          if (noseBase != null) {
            final pos = _scalePoint(noseBase.position, size);
            // Kumis tepat di bawah hidung
            _drawEmoji(canvas, '👨', Offset(scaledRect.center.dx, pos.dy + faceH * 0.08), faceW * 0.7);
          } else {
            _drawEmoji(canvas, '👨',
              Offset(scaledRect.center.dx, scaledRect.top + faceH * 0.62),
              faceW * 0.7);
          }
          break;

        case FaceFilter.crown:
          // Mahkota di atas kepala
          _drawEmoji(canvas, '👑',
            Offset(scaledRect.center.dx, scaledRect.top - faceH * 0.1),
            faceW * 0.9);
          break;

        case FaceFilter.catEars:
          // Telinga kucing di kiri dan kanan atas kepala
          if (leftEar != null && rightEar != null) {
            final lPos = _scalePoint(leftEar.position, size);
            final rPos = _scalePoint(rightEar.position, size);
            _drawEmoji(canvas, '🐱',
              Offset(scaledRect.center.dx, scaledRect.top - faceH * 0.05),
              faceW * 1.1);
          } else {
            _drawEmoji(canvas, '🐱',
              Offset(scaledRect.center.dx, scaledRect.top - faceH * 0.05),
              faceW * 1.1);
          }
          break;

        case FaceFilter.none:
          break;
      }
    }
  }

  @override
  bool shouldRepaint(FaceFilterPainter old) =>
      old.faces != faces || old.filter != filter || old.isFrontCamera != isFrontCamera;
}
