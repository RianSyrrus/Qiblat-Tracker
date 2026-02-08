import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

class PdfGuidePage extends StatefulWidget {
  const PdfGuidePage({super.key});

  @override
  State<PdfGuidePage> createState() => _PdfGuidePageState();
}

class _PdfGuidePageState extends State<PdfGuidePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.red.shade900,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Panduan Penggunaan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: PdfPreview(
        build: (format) async {
          final ByteData data = await rootBundle.load('assets/qt/sopqt.pdf');
          return data.buffer.asUint8List();
        },
        canChangeOrientation: false,
        canDebug: false,
        allowSharing: false,
        allowPrinting: false,
        pdfFileName: 'Panduan_Qiblat_Tracker.pdf',
      ),
    );
  }
}
