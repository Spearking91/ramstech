import 'package:flutter/material.dart';
import '../models/upload_model.dart';

class ChartWidget extends StatelessWidget {
  final List<UploadModel> data;

  const ChartWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CustomPaint(
                size: Size.infinite,
                painter: ChartPainter(data),
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: Colors.orange,
                    ),
                    SizedBox(width: 4),
                    Text('Temperature'),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: Colors.blue,
                    ),
                    SizedBox(width: 4),
                    Text('Humidity'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ChartPainter extends CustomPainter {
  final List<UploadModel> data;

  ChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Find min/max values for scaling
    double minTemp =
        data.map((e) => e.temperature ?? 0).reduce((a, b) => a < b ? a : b);
    double maxTemp =
        data.map((e) => e.temperature ?? 0).reduce((a, b) => a > b ? a : b);
    double minHum =
        data.map((e) => e.humidity ?? 0).reduce((a, b) => a < b ? a : b);
    double maxHum =
        data.map((e) => e.humidity ?? 0).reduce((a, b) => a > b ? a : b);

    // Add some padding to the range
    double tempRange = maxTemp - minTemp;
    double humRange = maxHum - minHum;
    if (tempRange == 0) tempRange = 1;
    if (humRange == 0) humRange = 1;

    // Draw temperature line
    paint.color = Colors.orange;
    final tempPath = Path();
    for (int i = 0; i < data.length; i++) {
      final temp = data[i].temperature ?? 0;
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((temp - minTemp) / tempRange) * size.height;

      if (i == 0) {
        tempPath.moveTo(x, y);
      } else {
        tempPath.lineTo(x, y);
      }
    }
    canvas.drawPath(tempPath, paint);

    // Draw humidity line
    paint.color = Colors.blue;
    final humPath = Path();
    for (int i = 0; i < data.length; i++) {
      final hum = data[i].humidity ?? 0;
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((hum - minHum) / humRange) * size.height;

      if (i == 0) {
        humPath.moveTo(x, y);
      } else {
        humPath.lineTo(x, y);
      }
    }
    canvas.drawPath(humPath, paint);

    // Draw grid lines
    paint.color = Colors.grey.withOpacity(0.3);
    paint.strokeWidth = 1;

    // Horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final y = (i / 4) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Vertical grid lines
    for (int i = 0; i <= 4; i++) {
      final x = (i / 4) * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
