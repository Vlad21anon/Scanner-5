import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
// Импортируйте вашу модель ScanFile, если она находится в отдельном файле
import '../models/scan_file.dart';

class FileShareService {
  /// Создаёт PDF-файл из переданного файла (ScanFile).
  /// Если файл содержит несколько страниц (поле pages заполнено),
  /// то все изображения объединяются в один PDF-файл.
  static Future<void> saveFileAsPdf(ScanFile file) async {
    try {
      // Создаем PDF-документ
      final pdf = pw.Document();

      // Определяем список путей к изображениям:
      // Если file.pages не пустой – используем его, иначе оставляем список пустым
      final List<String> imagePaths = file.pages.isNotEmpty ? file.pages : [];

      // Для каждого изображения добавляем страницу в PDF-документ
      for (final imagePath in imagePaths) {
        final imageFile = File(imagePath);
        if (!await imageFile.exists()) {
          debugPrint("Файл не найден: $imagePath");
          continue;
        }
        final imageBytes = await imageFile.readAsBytes();
        final pdfImage = pw.MemoryImage(imageBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
              );
            },
          ),
        );
      }

      // Сохраняем PDF во временный файл
      final tempDir = await getTemporaryDirectory();
      final tempPdfPath =
          '${tempDir.path}/temp_shared_file_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final tempPdfFile = File(tempPdfPath);
      await tempPdfFile.writeAsBytes(await pdf.save());

      // Параметры для открытия системного окна сохранения файла
      final params = SaveFileDialogParams(
        sourceFilePath: tempPdfPath,
        fileName: "shared_file_${DateTime.now().millisecondsSinceEpoch}.pdf",
      );

      // Открываем системный диалог для сохранения файла
      final savedPath = await FlutterFileDialog.saveFile(params: params);
      debugPrint("PDF файл сохранен по пути: $savedPath");
    } catch (e) {
      debugPrint("Ошибка при создании PDF: $e");
    }
  }

  static Future<void> shareFileAsPdf(ScanFile file, {String? text}) async {
    try {
      // Создаём PDF документ
      final pdf = pw.Document();

      // Определяем список путей к изображениям:
      // если file.pages не пустой – используем его, иначе используем file.path
      final List<String> imagePaths = file.pages.isNotEmpty ? file.pages : [file.pages.first];

      // Для каждого изображения добавляем страницу в PDF-документ
      for (final imagePath in imagePaths) {
        final imageFile = File(imagePath);
        if (!await imageFile.exists()) {
          debugPrint("Файл не найден: $imagePath");
          continue;
        }
        final imageBytes = await imageFile.readAsBytes();
        final pdfImage = pw.MemoryImage(imageBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
              );
            },
          ),
        );
      }

      // Сохраняем PDF во временный файл
      final tempDir = await getTemporaryDirectory();
      final pdfPath =
          '${tempDir.path}/shared_file_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final pdfFile = File(pdfPath);
      await pdfFile.writeAsBytes(await pdf.save());

      // Шарим PDF-файл через share_plus
      await Share.shareXFiles(
        [XFile(pdfPath)],
        text: text ?? 'Here is your PDF file',
      );
    } catch (e) {
      debugPrint("Ошибка при создании или шаринге PDF: $e");
    }
  }

  /// Универсальный метод для шаринга списка файлов по их путям.
  static Future<void> shareFiles(List<String> filePaths, {String? text}) async {
    try {
      final files = filePaths.map((path) => XFile(path)).toList();
      await Share.shareXFiles(files, text: text);
    } catch (e) {
      debugPrint("Ошибка при шаринге файлов: $e");
    }
  }
}
