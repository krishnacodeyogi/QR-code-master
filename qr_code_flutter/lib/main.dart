import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF8B5CF6),
        scaffoldBackgroundColor: const Color(0xFF0C0A2E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8B5CF6),
          secondary: Color(0xFFC084FC),
          surface: Color(0xFF1E1B4B),
          background: Color(0xFF0C0A2E),
        ),
        useMaterial3: true,
        fontFamily: 'sans-serif',
      ),
      home: const QrGeneratorScreen(),
    );
  }
}

class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  final TextEditingController _textController = TextEditingController();
  Color _fgColor = Colors.white;
  Color _bgColor = const Color(0xFF1E1B4B);
  double _qrSize = 250;
  String _ecLevel = 'M'; // L, M, Q, H
  File? _logoFile;
  String? _logoFileName;
  
  final ImagePicker _picker = ImagePicker();

  String get _effectiveEcLevel => _logoFile != null ? 'H' : _ecLevel;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // Preset pairings
  static const List<Map<String, dynamic>> _presets = [
    {'name': 'Nebula', 'fg': Colors.white, 'bg': Color(0xFF1E1B4B)},
    {'name': 'Classic', 'fg': Colors.black, 'bg': Colors.white},
    {'name': 'Mint', 'fg': Color(0xFF10B981), 'bg': Color(0xFF041A10)},
    {'name': 'Cyber Pink', 'fg': Color(0xFFEC4899), 'bg': Color(0xFF1F0410)},
    {'name': 'Sunburst', 'fg': Color(0xFFF97316), 'bg': Color(0xFF240E02)},
    {'name': 'Solar Gold', 'fg': Color(0xFFEAB308), 'bg': Color(0xFF1F1A00)},
  ];

  // Helper to load image for embedded logo rendering in image export
  Future<ui.Image> _loadUiImage(File file) async {
    final Uint8List bytes = await file.readAsBytes();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }

  // Generate and Share the QR code
  Future<void> _shareQrCode() async {
    final String text = _textController.text.trim();
    if (text.isEmpty) {
      _showSnackBar('Please enter content first');
      return;
    }

    try {
      final qrValidationResult = QrValidator.validate(
        data: text,
        version: QrVersions.auto,
        errorCorrectionLevel: _effectiveEcLevel == 'L'
            ? QrErrorCorrectLevel.L
            : _effectiveEcLevel == 'M'
                ? QrErrorCorrectLevel.M
                : _effectiveEcLevel == 'Q'
                    ? QrErrorCorrectLevel.Q
                    : QrErrorCorrectLevel.H,
      );

      if (qrValidationResult.status != QrValidationStatus.valid) {
        _showSnackBar('QR validation failed');
        return;
      }

      final qrCode = qrValidationResult.qrCode!;
      
      ui.Image? embeddedImage;
      if (_logoFile != null) {
        embeddedImage = await _loadUiImage(_logoFile!);
      }

      final painter = QrPainter.withQr(
        qr: qrCode,
        color: _fgColor,
        emptyColor: _bgColor,
        gapless: true,
        embeddedImage: embeddedImage,
        embeddedImageStyle: embeddedImage != null
            ? QrEmbeddedImageStyle(
                size: Size.square(_qrSize * 0.22),
              )
            : null,
      );

      final double exportSize = 512; // High-quality output size
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      
      painter.paint(canvas, Size.square(exportSize));
      
      final ui.Picture picture = recorder.endRecording();
      final ui.Image image = await picture.toImage(exportSize.toInt(), exportSize.toInt());
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        _showSnackBar('Failed to generate PNG data');
        return;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/qr_studio_code.png').create();
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Generated with QR Studio App',
      );
    } catch (e) {
      _showSnackBar('Error generating/sharing QR: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF7C3AED),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickLogo() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image != null) {
        final File file = File(image.path);
        final int fileSize = await file.length();
        
        if (fileSize > 5 * 1024 * 1024) {
          _showSnackBar('Image must be under 5MB');
          return;
        }

        setState(() {
          _logoFile = file;
          _logoFileName = image.name;
        });
        _showSnackBar('Logo uploaded successfully');
      }
    } catch (e) {
      _showSnackBar('Failed to pick logo: $e');
    }
  }

  void _removeLogo() {
    setState(() {
      _logoFile = null;
      _logoFileName = null;
    });
  }

  void _swapColors() {
    setState(() {
      final temp = _fgColor;
      _fgColor = _bgColor;
      _bgColor = temp;
    });
  }

  // Calculate Scan Quality Indicator
  Map<String, dynamic> _getScanQuality(String text) {
    if (text.isEmpty) return {'label': '', 'color': Colors.transparent};
    
    int moduleCount = 21;
    final qrValidationResult = QrValidator.validate(
      data: text,
      version: QrVersions.auto,
      errorCorrectionLevel: _effectiveEcLevel == 'L'
          ? QrErrorCorrectLevel.L
          : _effectiveEcLevel == 'M'
              ? QrErrorCorrectLevel.M
              : _effectiveEcLevel == 'Q'
                  ? QrErrorCorrectLevel.Q
                  : QrErrorCorrectLevel.H,
    );

    if (qrValidationResult.status == QrValidationStatus.valid) {
      moduleCount = qrValidationResult.qrCode!.moduleCount;
    }

    final double totalModules = moduleCount + 4.0; // Adding 2 modules margin on each side
    final double pxPerModule = _qrSize / totalModules;

    if (pxPerModule >= 6.0) {
      return {'label': 'Excellent', 'color': Colors.green};
    } else if (pxPerModule >= 4.0) {
      return {'label': 'Good', 'color': Colors.amber};
    } else {
      return {'label': 'Dense (Try L / Increase Size)', 'color': Colors.orange};
    }
  }

  // Color picker dialog
  void _openColorPicker(bool isFg) {
    Color selectedColor = isFg ? _fgColor : _bgColor;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1B4B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFF7C3AED), width: 1),
              ),
              title: Text(
                isFg ? 'Custom QR Color' : 'Custom Background Color',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: selectedColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: selectedColor.withOpacity(0.4),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildColorSlider('Red', selectedColor.red, (val) {
                    setDialogState(() {
                      selectedColor = selectedColor.withRed(val);
                    });
                  }),
                  _buildColorSlider('Green', selectedColor.green, (val) {
                    setDialogState(() {
                      selectedColor = selectedColor.withGreen(val);
                    });
                  }),
                  _buildColorSlider('Blue', selectedColor.blue, (val) {
                    setDialogState(() {
                      selectedColor = selectedColor.withBlue(val);
                    });
                  }),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      if (isFg) {
                        _fgColor = selectedColor;
                      } else {
                        _bgColor = selectedColor;
                      }
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Select'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildColorSlider(String label, int val, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text(val.toString(), style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace')),
          ],
        ),
        Slider(
          value: val.toDouble(),
          min: 0,
          max: 255,
          activeColor: label == 'Red'
              ? Colors.red
              : label == 'Green'
                  ? Colors.green
                  : Colors.blue,
          inactiveColor: Colors.white12,
          onChanged: (double dVal) {
            onChanged(dVal.toInt());
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String text = _textController.text;
    final Map<String, dynamic> qualityInfo = _getScanQuality(text);

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient Nebula
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0C0A2E),
                  Color(0xFF1E1B4B),
                  Color(0xFF08061F),
                ],
              ),
            ),
          ),
          
          // Blob glow 1
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7C3AED).withOpacity(0.2),
              ),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 120, sigmaY: 120),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // Blob glow 2
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4F46E5).withOpacity(0.15),
              ),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // App body
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 20),

                  // Preview Widget
                  _buildPreview(text, qualityInfo),
                  const SizedBox(height: 20),

                  // Content Input
                  _buildContentInput(),
                  const SizedBox(height: 16),

                  // Logo Embedder
                  _buildLogoEmbedder(),
                  const SizedBox(height: 16),

                  // Color Picker
                  _buildColorControls(),
                  const SizedBox(height: 16),

                  // Size & Error Correction Controls
                  _buildLayoutControls(),
                  const SizedBox(height: 24),

                  // Generate Button
                  _buildActionBtn(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFC084FC), Color(0xFF8B5CF6), Color(0xFF818CF8)],
          ).createShader(bounds),
          child: const Text(
            'QR Studio',
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const Text(
          'Craft precision QR codes instantly.',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w300,
            color: Color(0xFFC4B5FD),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview(String text, Map<String, dynamic> qualityInfo) {
    return GlassCard(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Icon(Icons.qr_code, size: 16, color: Color(0xFFC4B5FD)),
                SizedBox(width: 8),
                Text(
                  'PREVIEW',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Color(0xFFC4B5FD),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // QR Code display container
            Container(
              width: 250,
              height: 250,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: text.isEmpty ? Colors.black26 : _bgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF8B5CF6).withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: text.isEmpty
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withOpacity(0.15),
                          blurRadius: 20,
                          spreadRadius: 2,
                        )
                      ],
              ),
              child: text.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner,
                            size: 40,
                            color: Color(0xFFC4B5FD),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Enter content to generate\nyour QR code.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white38,
                            height: 1.4,
                          ),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: QrImageView(
                        data: text,
                        version: QrVersions.auto,
                        errorCorrectionLevel: _effectiveEcLevel == 'L'
                            ? QrErrorCorrectLevel.L
                            : _effectiveEcLevel == 'M'
                                ? QrErrorCorrectLevel.M
                                : _effectiveEcLevel == 'Q'
                                    ? QrErrorCorrectLevel.Q
                                    : QrErrorCorrectLevel.H,
                        size: 250,
                        gapless: true,
                        embeddedImage: _logoFile != null ? FileImage(_logoFile!) : null,
                        embeddedImageStyle: _logoFile != null
                            ? const QrEmbeddedImageStyle(
                                size: Size.square(45),
                              )
                            : null,
                        eyeStyle: QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: _fgColor,
                        ),
                        dataModuleStyle: QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: _fgColor,
                        ),
                      ),
                    ),
            ),
            
            const SizedBox(height: 16),
            if (text.isNotEmpty) ...[
              Text(
                '${_qrSize.toInt()} × ${_qrSize.toInt()} PX',
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: Colors.white30,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              if (qualityInfo['label'].isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: (qualityInfo['color'] as Color).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (qualityInfo['color'] as Color).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: qualityInfo['color'],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: qualityInfo['color'],
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        qualityInfo['label'],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: qualityInfo['color'],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContentInput() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONTENT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Color(0xFFC4B5FD),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withOpacity(0.15),
              ),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _textController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Enter URL or text...',
                    hintStyle: TextStyle(color: Colors.white30, fontSize: 14),
                    contentPadding: EdgeInsets.all(16),
                    border: InputBorder.none,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16.0, bottom: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${_textController.text.length} / 2953',
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: Colors.white24,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoEmbedder() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'LOGO / IMAGE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Color(0xFFC4B5FD),
                ),
              ),
              if (_logoFile != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'EC auto → H',
                    style: TextStyle(fontSize: 10, color: Color(0xFFC4B5FD)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (_logoFile != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF8B5CF6).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _logoFile!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _logoFileName ?? 'Embedded Logo',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'Appears in the center of the QR',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _removeLogo,
                    icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                  ),
                ],
              ),
            ),
          ] else ...[
            GestureDetector(
              onTap: _pickLogo,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withOpacity(0.15),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 20,
                        color: Color(0xFFC4B5FD),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload logo image',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          'PNG, JPG — max 5MB',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white30,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildColorControls() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'COLORS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Color(0xFFC4B5FD),
            ),
          ),
          const SizedBox(height: 16),
          
          // Color previews & Swap button
          Row(
            children: [
              // FG Color
              Expanded(
                child: GestureDetector(
                  onTap: () => _openColorPicker(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _fgColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'QR Color',
                            style: TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Swap button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: IconButton(
                  onPressed: _swapColors,
                  icon: const Icon(
                    Icons.swap_horiz,
                    color: Color(0xFFC4B5FD),
                  ),
                  tooltip: 'Swap colors',
                ),
              ),
              
              // BG Color
              Expanded(
                child: GestureDetector(
                  onTap: () => _openColorPicker(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _bgColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Background',
                            style: TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          const Text(
            'PRESETS',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: Colors.white30,
            ),
          ),
          const SizedBox(height: 10),
          
          // Presets layout
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _presets.length,
              itemBuilder: (context, index) {
                final preset = _presets[index];
                final isSelected = _fgColor == preset['fg'] && _bgColor == preset['bg'];
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _fgColor = preset['fg'];
                      _bgColor = preset['bg'];
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF7C3AED).withOpacity(0.2) : Colors.black12,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF8B5CF6) : Colors.white10,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Small overlapping circles
                        Stack(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: preset['bg'],
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white24, width: 0.5),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: preset['fg'],
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white24, width: 0.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          preset['name'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutControls() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Size Control
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'QR SIZE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Color(0xFFC4B5FD),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_qrSize.toInt()}px',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC4B5FD),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF8B5CF6),
              inactiveTrackColor: Colors.white10,
              thumbColor: const Color(0xFFC084FC),
              overlayColor: const Color(0xFF8B5CF6).withOpacity(0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: _qrSize,
              min: 150,
              max: 400,
              divisions: 5,
              onChanged: (val) {
                setState(() {
                  _qrSize = val;
                });
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Error Correction Control
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ERROR CORRECTION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Color(0xFFC4B5FD),
                ),
              ),
              if (_logoFile != null)
                const Text(
                  'locked to H',
                  style: TextStyle(fontSize: 11, color: Colors.white30),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: ['L', 'M', 'Q', 'H'].map((level) {
              final isSelected = _effectiveEcLevel == level;
              final isLocked = _logoFile != null;
              
              return Expanded(
                child: GestureDetector(
                  onTap: isLocked
                      ? null
                      : () {
                          setState(() {
                            _ecLevel = level;
                          });
                        },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF8B5CF6)
                          : Colors.black26,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFC084FC)
                            : Colors.white10,
                      ),
                    ),
                    child: Text(
                      level,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isLocked ? Colors.white24 : Colors.white60),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF7C3AED),
            Color(0xFFC084FC),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: _shareQrCode,
        icon: const Icon(Icons.share, color: Colors.white, size: 20),
        label: const Text(
          'Share / Save QR Code',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}

// Glassmorphic Premium Card container
class GlassCard extends StatelessWidget {
  final Widget child;

  const GlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1.0,
        ),
      ),
      child: child,
    );
  }
}
