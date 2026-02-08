import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';

class MagneticCompassWidget extends StatefulWidget {
  const MagneticCompassWidget({super.key});

  @override
  State<MagneticCompassWidget> createState() => _MagneticCompassWidgetState();
}

class _MagneticCompassWidgetState extends State<MagneticCompassWidget> {
  double _heading = 0;
  bool _hasPermission = true;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  List<double> _magnetometerReading = [0, 0, 0];
  List<double> _accelerometerReading = [0, 0, 9.8];

  // Smoothing filter
  final List<double> _headingHistory = [];
  final int _smoothingWindowSize = 5;

  // Throttling
  DateTime _lastUpdate = DateTime.now();
  final int _updateIntervalMs = 50; // Update UI setiap 50ms (20 FPS)

  @override
  void initState() {
    super.initState();
    _initCompass();
  }

  void _initCompass() {
    // Listen to magnetometer
    _magnetometerSubscription = magnetometerEvents.listen(
      (MagnetometerEvent event) {
        _magnetometerReading = [event.x, event.y, event.z];
        _calculateHeadingThrottled();
      },
      onError: (error) {
        setState(() {
          _hasPermission = false;
        });
      },
    );

    // Listen to accelerometer for tilt compensation
    _accelerometerSubscription = accelerometerEvents.listen((
      AccelerometerEvent event,
    ) {
      _accelerometerReading = [event.x, event.y, event.z];
    });
  }

  void _calculateHeadingThrottled() {
    final now = DateTime.now();
    if (now.difference(_lastUpdate).inMilliseconds < _updateIntervalMs) {
      return;
    }
    _lastUpdate = now;

    _calculateHeading();
  }

  void _calculateHeading() {
    // Ambil data sensor
    final mx = _magnetometerReading[0];
    final my = _magnetometerReading[1];
    final mz = _magnetometerReading[2];

    final ax = _accelerometerReading[0];
    final ay = _accelerometerReading[1];
    final az = _accelerometerReading[2];

    // Normalisasi accelerometer untuk menghitung pitch dan roll
    final norm = math.sqrt(ax * ax + ay * ay + az * az);
    if (norm == 0) return;

    final axNorm = ax / norm;
    final ayNorm = ay / norm;
    final azNorm = az / norm;

    // Hitung pitch dan roll untuk tilt compensation
    final pitch = math.asin(-axNorm);
    final roll = math.asin(ayNorm / math.cos(pitch));

    // Tilt compensation untuk magnetometer
    final magX = mx * math.cos(pitch) + mz * math.sin(pitch);
    final magY =
        mx * math.sin(roll) * math.sin(pitch) +
        my * math.cos(roll) -
        mz * math.sin(roll) * math.cos(pitch);

    // Hitung heading dari magnetometer yang sudah dikompensasi
    // Untuk Android dalam mode portrait
    var heading = math.atan2(magY, magX) * (180 / math.pi);

    // Normalisasi ke 0-360
    if (heading < 0) {
      heading += 360;
    }

    // Koreksi orientasi untuk Android
    // Tambah 90° untuk orientasi + 180° untuk membalik N-S
    heading = (heading + 90 + 180) % 360;

    // Apply smoothing filter
    _headingHistory.add(heading);
    if (_headingHistory.length > _smoothingWindowSize) {
      _headingHistory.removeAt(0);
    }

    // Hitung rata-rata dengan circular mean untuk menghindari masalah di 0/360°
    final smoothedHeading = _calculateCircularMean(_headingHistory);

    setState(() {
      _heading = smoothedHeading;
    });
  }

  // Circular mean untuk averaging angles (menghindari masalah di 0°/360°)
  double _calculateCircularMean(List<double> angles) {
    if (angles.isEmpty) return 0;

    double sinSum = 0;
    double cosSum = 0;

    for (var angle in angles) {
      final radian = angle * (math.pi / 180);
      sinSum += math.sin(radian);
      cosSum += math.cos(radian);
    }

    final meanRadian = math.atan2(
      sinSum / angles.length,
      cosSum / angles.length,
    );
    var meanDegree = meanRadian * (180 / math.pi);

    if (meanDegree < 0) {
      meanDegree += 360;
    }

    return meanDegree;
  }

  @override
  void dispose() {
    _magnetometerSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return _buildErrorWidget();
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Compass widget
          SizedBox(
            width: 300,
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Rotating compass bezel (berputar sehingga N selalu ke utara)
                Transform.rotate(
                  angle: (_heading * (math.pi / 180) * -1),
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.7),
                      border: Border.all(color: Colors.red.shade700, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: CustomPaint(
                      size: const Size(280, 280),
                      painter: CompassBackgroundPainter(),
                    ),
                  ),
                ),

                // Fixed phone direction indicator (segitiga putih tetap di atas)
                Positioned(
                  top: 10,
                  child: CustomPaint(
                    size: const Size(30, 30),
                    painter: PhoneDirectionIndicator(),
                  ),
                ),

                // Center point
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.red, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),

                // Label "Kompas Magnetik" (tidak berputar)
                const Positioned(
                  bottom: 20,
                  child: Text(
                    'KOMPAS MAGNETIK',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Heading display DI BAWAH kompas
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.shade700, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Direction text
                SizedBox(
                  width: 30,
                  child: Text(
                    _getDirectionText(_heading),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Degree display
                Text(
                  '${_heading.toInt()}°',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getDirectionText(double heading) {
    if (heading >= 337.5 || heading < 22.5) return 'U'; // Utara
    if (heading >= 22.5 && heading < 67.5) return 'TL'; // Timur Laut
    if (heading >= 67.5 && heading < 112.5) return 'T'; // Timur
    if (heading >= 112.5 && heading < 157.5) return 'TG'; // Tenggara
    if (heading >= 157.5 && heading < 202.5) return 'S'; // Selatan
    if (heading >= 202.5 && heading < 247.5) return 'BD'; // Barat Daya
    if (heading >= 247.5 && heading < 292.5) return 'B'; // Barat
    if (heading >= 292.5 && heading < 337.5) return 'BL'; // Barat Laut
    return '';
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.red.shade700, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 40),
            const SizedBox(height: 10),
            const Text(
              'Sensor Kompas\nTidak Tersedia',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 10),
            const Text(
              'Perangkat tidak mendukung\nmagnetometer atau izin ditolak',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// Painter untuk rotating compass bezel
class CompassBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw cardinal directions (N, E, S, W)
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    final directions = [
      {'text': 'U', 'angle': 0.0, 'color': Colors.red}, // Utara - Merah
      {'text': 'T', 'angle': 90.0, 'color': Colors.white}, // Timur - Putih
      {'text': 'S', 'angle': 180.0, 'color': Colors.white}, // Selatan - Putih
      {'text': 'B', 'angle': 270.0, 'color': Colors.white}, // Barat - Putih
    ];

    for (var dir in directions) {
      final angle = (dir['angle'] as double) * (math.pi / 180);
      final x = center.dx + (radius - 45) * math.sin(angle);
      final y = center.dy - (radius - 45) * math.cos(angle);

      textPainter.text = TextSpan(
        text: dir['text'] as String,
        style: TextStyle(
          color: dir['color'] as Color,
          fontSize: dir['text'] == 'U' ? 24 : 20,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black.withOpacity(0.7), blurRadius: 4),
          ],
        ),
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }

    // Draw degree numbers (0, 30, 60, 90, ...)
    final degreeStyle = TextStyle(
      color: Colors.white70,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      shadows: [Shadow(color: Colors.black.withOpacity(0.7), blurRadius: 2)],
    );

    for (int deg = 0; deg < 360; deg += 30) {
      final angle = deg * (math.pi / 180);
      final x = center.dx + (radius - 70) * math.sin(angle);
      final y = center.dy - (radius - 70) * math.cos(angle);

      textPainter.text = TextSpan(text: '$deg', style: degreeStyle);

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }

    // Draw degree marks
    final minorPaint = Paint()
      ..color = Colors.white30
      ..strokeWidth = 1.5;

    final majorPaint = Paint()
      ..color = Colors.white60
      ..strokeWidth = 2;

    for (int i = 0; i < 360; i += 2) {
      final angle = i * (math.pi / 180);
      final isMajor = i % 30 == 0;
      final currentPaint = isMajor ? majorPaint : minorPaint;

      final startRadius = isMajor ? radius - 25 : radius - 15;
      final endRadius = radius - 10;

      final start = Offset(
        center.dx + startRadius * math.sin(angle),
        center.dy - startRadius * math.cos(angle),
      );

      final end = Offset(
        center.dx + endRadius * math.sin(angle),
        center.dy - endRadius * math.cos(angle),
      );

      canvas.drawLine(start, end, currentPaint);
    }

    // Draw inner decorative circles
    final innerCirclePaint = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(center, radius - 80, innerCirclePaint);
    canvas.drawCircle(center, radius - 90, innerCirclePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Painter untuk fixed phone direction indicator (segitiga putih tetap di atas)
class PhoneDirectionIndicator extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw white triangle pointing up
    final path = Path()
      ..moveTo(center.dx, 0)
      ..lineTo(center.dx - 10, 20)
      ..lineTo(center.dx + 10, 20)
      ..close();

    // Draw shadow
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Draw white triangle fill
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // Draw border
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
