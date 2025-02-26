import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

class InvoiceGenerator {
  static Future<File> generateInvoice({
    required String customerName,
    required String email,
    required String uniqueNumber,
    required String roomNumber,
    required int nights,
    required double totalPayment,
    required double changeAmount,
    required DateTime bookingDate,
  }) async {
    final pdf = pw.Document();

    // Load logo image
    final logoImage = pw.MemoryImage(
      (await rootBundle.load('assets/instay_logo.png')).buffer.asUint8List(),
    );

    // Define styles
    final titleStyle = pw.TextStyle(
      fontSize: 24,
      fontWeight: pw.FontWeight.bold,
    );

    final headerStyle = pw.TextStyle(
      fontSize: 18,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.grey800,
    );

    final contentStyle = pw.TextStyle(
      fontSize: 14,
      color: PdfColors.black,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with logo
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Image(logoImage, width: 120),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('INVOICE', style: titleStyle),
                      pw.Text('Date: ${bookingDate.toString().split(' ')[0]}'),
                      pw.Text('Invoice #: $uniqueNumber'),
                    ],
                  ),
                ],
              ),

              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),

              // Hotel Information
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Instay Hotel', style: headerStyle),
                    pw.Text('Jl. Karanganyar Cigadung No. 123'),
                    pw.Text('Phone: +62 821 2534 9737'),
                    pw.Text('Email: info@Instayhotel.com'),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Guest Information
              pw.Text('Guest Information', style: headerStyle),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Name: $customerName', style: contentStyle),
                    pw.Text('Email: $email', style: contentStyle),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Booking Details
              pw.Text('Booking Details', style: headerStyle),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Description',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Details',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  // Room Details
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Room Number'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(roomNumber),
                      ),
                    ],
                  ),
                  // Duration
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Duration'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('$nights nights'),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Payment Information
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Payment Information', style: headerStyle),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Payment:'),
                        pw.Text('Rp ${NumberFormat('#,###').format(totalPayment)}'),
                      ],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Change Amount:'),
                        pw.Text('Rp ${NumberFormat('#,###').format(changeAmount)}'),
                      ],
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Footer
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 10),
              pw.Text(
                'Thank you for choosing InStay Hotel',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );

    // Save the PDF
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/invoice_$uniqueNumber.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }
}
