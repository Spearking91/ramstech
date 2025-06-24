import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scanner'),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.popAndPushNamed(context, "/generate");
              },
              icon: Icon(Icons.qr_code))
        ],
      ),
      body: MobileScanner(
        controller: MobileScannerController(
            detectionSpeed: DetectionSpeed.noDuplicates, returnImage: true),
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          final Uint8List? image = capture.image;
          for (final barcode in barcodes) {
            print('Barcode found! ${barcode.rawValue}');
          }
          if (image != null) {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(barcodes.first.rawValue ?? ""),
                  content: Image(image: MemoryImage(image)),
                );
              },
            );
          }
        },
      ),
    );
  }
}
