import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class GeneratePage extends StatefulWidget {
  const GeneratePage({super.key});

  @override
  State<GeneratePage> createState() => _GeneratePageState();
}

class _GeneratePageState extends State<GeneratePage> {
  String? qrData;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Generate QR code'),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.popAndPushNamed(context, "/scan");
              },
              icon: Icon(Icons.qr_code_scanner))
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextField(
              onSubmitted: (value) {
                setState(() {
                  qrData = value;
                });
              },
            ),
            if (qrData != null) PrettyQrView.data(data: qrData!),
          ],
        ),
      ),
    );
  }
}
