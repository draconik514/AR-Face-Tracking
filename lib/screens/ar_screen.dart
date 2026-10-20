import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/supabase_service.dart';
import '../widgets/face_filter_painter.dart';
import 'history_screen.dart';

class ARScreen extends StatefulWidget {
  const ARScreen({super.key});

  @override
  State<ARScreen> createState() => _ARScreenState();
}

class _ARScreenState extends State<ARScreen> {
  final SupabaseService _dbService = SupabaseService();
  final GlobalKey _previewKey = GlobalKey();

  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  List<CameraDescription> _cameras = [];

  List<Face> _faces = [];
  Size _imageSize = Size.zero;
  bool _isProcessing = false;
  bool _hasCameraPermission = false;
  bool _isFrontCamera = true;
  bool _isSmiling = false;

  FaceFilter _currentFilter = FaceFilter.none;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableClassification: true,
        enableLandmarks: true, // aktifkan landmark mata, hidung, mulut
      ),
    );
    _requestPermissionAndInit();
  }

  Future<void> _requestPermissionAndInit() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isGranted) {
      setState(() => _hasCameraPermission = true);
      await _initCamera();
    } else {
      setState(() => _hasCameraPermission = false);
    }
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    final selected = _cameras.firstWhere(
      (c) => c.lensDirection ==
          (_isFrontCamera ? CameraLensDirection.front : CameraLensDirection.back),
      orElse: () => _cameras.first,
    );

    await _cameraController?.stopImageStream();
    await _cameraController?.dispose();

    _cameraController = CameraController(
      selected,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _cameraController!.initialize();
    if (!mounted) return;
    setState(() {});
    _cameraController!.startImageStream(_processCameraImage);
  }

  Future<void> _switchCamera() async {
    setState(() => _isFrontCamera = !_isFrontCamera);
    await _initCamera();
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final camera = _cameras.firstWhere(
        (c) => c.lensDirection ==
            (_isFrontCamera ? CameraLensDirection.front : CameraLensDirection.back),
        orElse: () => _cameras.first,
      );

      // Gabungkan semua planes untuk NV21
      final WriteBuffer allBytes = WriteBuffer();
      for (final plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation)
          ?? InputImageRotation.rotation0deg;

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );

      final faces = await _faceDetector!.processImage(inputImage);

      bool smiling = false;
      if (faces.isNotEmpty) {
        smiling = (faces.first.smilingProbability ?? 0) > 0.7;
      }

      if (mounted) {
        setState(() {
          _faces = faces;
          _imageSize = Size(image.width.toDouble(), image.height.toDouble());
          _isSmiling = smiling;
        });
      }
    } catch (_) {}

    _isProcessing = false;
  }

  Future<void> _takeScreenshot() async {
    try {
      final boundary = _previewKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      await Gal.putImageBytes(byteData.buffer.asUint8List());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('📸 Foto disimpan ke galeri!'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveSession() async {
    final filterName = _currentFilter == FaceFilter.none
        ? 'Tanpa Filter'
        : _currentFilter.label;
    final success = await _dbService.logARSession(maskName: filterName);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? 'Session berhasil disimpan!' : 'Gagal menyimpan session.'),
      backgroundColor: success ? Colors.green : Colors.red,
    ));
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('AR Face Tracking', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(
              _isFrontCamera ? Icons.camera_front : Icons.camera_rear,
              color: Colors.white,
            ),
            tooltip: 'Switch Kamera',
            onPressed: _switchCamera,
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_hasCameraPermission) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Izin kamera dibutuhkan', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final status = await Permission.camera.request();
                if (status.isPermanentlyDenied) await openAppSettings();
                if (status.isGranted && mounted) {
                  setState(() => _hasCameraPermission = true);
                  await _initCamera();
                }
              },
              child: const Text('Berikan Izin'),
            ),
          ],
        ),
      );
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Camera + Filter Overlay
        Expanded(
          child: RepaintBoundary(
            key: _previewKey,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_cameraController!),
                // Filter overlay
                if (_faces.isNotEmpty && _imageSize != Size.zero)
                  CustomPaint(
                    painter: FaceFilterPainter(
                      faces: _faces,
                      imageSize: _imageSize,
                      filter: _currentFilter,
                      isFrontCamera: _isFrontCamera,
                    ),
                  ),
                // Status wajah + senyum
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _faces.isEmpty
                            ? 'Arahkan kamera ke wajah'
                            : _isSmiling
                                ? '😄 Senyum terdeteksi!'
                                : '✅ ${_faces.length} wajah terdeteksi',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Filter selector
        Container(
          color: Colors.black,
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            children: FaceFilter.values.map((filter) {
              final isSelected = _currentFilter == filter;
              return GestureDetector(
                onTap: () => setState(() => _currentFilter = filter),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.grey[800],
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                  ),
                  child: Text(
                    filter.label,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Action buttons
        Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _takeScreenshot,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Screenshot'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
              ElevatedButton.icon(
                onPressed: _saveSession,
                icon: const Icon(Icons.save),
                label: const Text('Simpan Session'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
