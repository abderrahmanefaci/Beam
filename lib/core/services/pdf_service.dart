import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class PdfService {
  // Convert list of images to PDF
  Future<File> createPdfFromImages({
    required List<Uint8List> images,
    required String title,
  }) async {
    final pdf = pw.Document();

    for (final imageBytes in images) {
      final image = pw.MemoryImage(imageBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(image),
            );
          },
        ),
      );
    }

    // Save to temporary file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/${title.replaceAll(' ', '_')}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }
}