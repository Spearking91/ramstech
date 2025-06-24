import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../models/upload_model.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';

class ExcelExportService {
  static void _setCellValue(Sheet sheet, int col, int row, dynamic value) {
    final cell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    if (value is num) {
      cell.value = DoubleCellValue(value.toDouble());
    } else {
      cell.value = TextCellValue(value?.toString() ?? 'N/A');
    }
  }

  static Future<String> exportToExcel(
      List<UploadModel> data, String fileName) async {
    if (data.isEmpty) {
      throw Exception('No data to export');
    }

    try {
      final excel = Excel.createExcel();
      final sheet = excel[excel.getDefaultSheet()!];

      // Add headers with style
      final headerStyle =
          CellStyle(bold: true, horizontalAlign: HorizontalAlign.Center);

      final headers = [
        'Date Time',
        'Temperature (°C)',
        'Humidity (%)',
        'PMS (µg/m³)',
        'AQI'
      ];

      // Add headers with style
      for (var i = 0; i < headers.length; i++) {
        final cell =
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // Add data with error handling
      for (var i = 0; i < data.length; i++) {
        final row = i + 1;
        final item = data[i];

        try {
          _setCellValue(sheet, 0, row, item.formattedDateTime);
          _setCellValue(sheet, 1, row, item.temperature);
          _setCellValue(sheet, 2, row, item.humidity);
          _setCellValue(sheet, 3, row, item.pms);
          _setCellValue(sheet, 4, row, item.aqi);
        } catch (e) {
          // In a production app, consider using a logging framework
          print('Error writing row $row: $e');
          continue;
        }
      }

      // Save file with proper path handling
      final directory = await getApplicationDocumentsDirectory();
      final sanitizedFileName =
          fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final filePath = path.join(directory.path, '$sanitizedFileName.xlsx');

      final file = File(filePath);
      final List<int>? fileBytes = excel.encode();
      if (fileBytes == null) {
        throw Exception('Failed to encode Excel file bytes.');
      }
      await file.writeAsBytes(fileBytes);

      return filePath;
    } catch (e) {
      throw Exception('Failed to export Excel file: $e');
    }
  }

  static Future<void> exportAndShareToExcel(
      List<UploadModel> data, String fileName,
      {String? shareSubject}) async {
    if (data.isEmpty) {
      throw Exception('No data to export');
    }

    try {
      final filePath = await exportToExcel(data, fileName);
      final xFile = XFile(filePath);

      await Share.shareXFiles(
        [xFile],
        subject: shareSubject ?? 'Exported Sensor Data: $fileName',
      );
    } catch (e) {
      throw Exception('Failed to export and share Excel file: $e');
    }
  }
}
