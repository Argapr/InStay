import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:excel/excel.dart' as excel;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';

class HistoryTransactionPage extends StatefulWidget {
  const HistoryTransactionPage({super.key});

  @override
  State<HistoryTransactionPage> createState() => _HistoryTransactionPageState();
}

class _HistoryTransactionPageState extends State<HistoryTransactionPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> transactions = [];
  bool isLoading = true;
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    // Set default date range to last 30 days
    endDate = DateTime.now();
    startDate = DateTime.now().subtract(const Duration(days: 30));
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    try {
      setState(() => isLoading = true);

      var query = supabase.from('transactions').select('''
        *,
        rooms (
          room_number, 
          room_type_id,
          room_types (
            name
          )
        )
      ''');

      // Add date range filter if dates are selected
      if (startDate != null && endDate != null) {
        query = query.gte('created_at', startDate!.toIso8601String()).lte(
            'created_at',
            endDate!.add(const Duration(days: 1)).toIso8601String());
      }

      final response = await query;

      if (response != null) {
        setState(() {
          transactions = response;
          isLoading = false;
        });
      } else {
        throw Exception('Data transaksi tidak ditemukan!');
      }
    } catch (e) {
      print('Error fetching transactions: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data transaksi: $e')),
      );
    }
  }

  Future<void> _exportToExcel() async {
    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tidak ada data transaksi untuk diexport')),
      );
      return;
    }

    try {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }

      final excelfile = excel.Excel.createExcel();
      final sheet = excelfile['Transaksi'];

      // Enhanced header styling with white text
      final headerCellStyle = excel.CellStyle(
        bold: true,
        horizontalAlign: excel.HorizontalAlign.Center,
        backgroundColorHex: "#4F4F4F",
        fontColorHex: "#FFFFFF",
        verticalAlign: excel.VerticalAlign.Center,
        textWrapping: excel.TextWrapping.WrapText,
        fontSize: 12,
      );

      // Customer name cell styling - left aligned
      final customerNameCellStyle = excel.CellStyle(
        horizontalAlign: excel.HorizontalAlign.Left,
        verticalAlign: excel.VerticalAlign.Center,
        textWrapping: excel.TextWrapping.WrapText,
        fontSize: 11,
        backgroundColorHex: "#FFFFFF",
      );

      // Data cell styling - centered content
      final dataCellStyle = excel.CellStyle(
        horizontalAlign: excel.HorizontalAlign.Center,
        verticalAlign: excel.VerticalAlign.Center,
        textWrapping: excel.TextWrapping.WrapText,
        fontSize: 11,
        backgroundColorHex: "#FFFFFF",
      );

      // Amount cell styling - centered with currency format
      final amountCellStyle = excel.CellStyle(
        horizontalAlign: excel.HorizontalAlign.Center,
        verticalAlign: excel.VerticalAlign.Center,
        fontSize: 11,
        backgroundColorHex: "#FFFFFF",
      );

      // Header tabel
      final headers = [
        'Nama Pelanggan',
        'Tipe Kamar',
        'Nomor Kamar',
        'Jumlah Pembayaran',
        'Tanggal Transaksi',
      ];

      // Append and style header row
      sheet.appendRow(headers);

      // Apply header styling and set column widths
      for (var col = 0; col < headers.length; col++) {
        final cell = sheet.cell(
            excel.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
        cell.cellStyle = headerCellStyle;

        // Set column width
        if (col == 0) {
          sheet.setColWidth(col, 25.0); // Nama Pelanggan
        } else if (col == 1) {
          sheet.setColWidth(col, 15.0); // Tipe Kamar
        } else if (col == 2) {
          sheet.setColWidth(col, 20.0); // Nomor Kamar
        } else if (col == 3) {
          sheet.setColWidth(col, 30.0); // Jumlah Pembayaran
        } else {
          sheet.setColWidth(col, 25.0); // Tanggal Transaksi
        }
      }

      // Mengisi data dengan styling
      var rowIndex = 1;
      for (var transaction in transactions) {
        final room = transaction['rooms'];
        final rowData = [
          transaction['customer_name'],
          room?['room_types']?['name'] ?? '-',
          room?['room_number']?.toString() ?? '-',
          NumberFormat.currency(
            locale: 'id_ID',
            symbol: 'Rp ',
            decimalDigits: 0,
          ).format(transaction['payment_amount']),
          DateFormat('dd-MM-yyyy HH:mm').format(
            DateTime.parse(transaction['created_at']),
          ),
        ];

        // Append row data with different styling for customer name
        for (var col = 0; col < rowData.length; col++) {
          final cell = sheet.cell(excel.CellIndex.indexByColumnRow(
              columnIndex: col, rowIndex: rowIndex));
          cell.value = rowData[col];

          // Apply appropriate cell style based on column
          if (col == 0) {
            cell.cellStyle =
                customerNameCellStyle; // Left align for customer name
          } else if (col == 3) {
            cell.cellStyle = amountCellStyle; // Center align for amount
          } else {
            cell.cellStyle = dataCellStyle; // Center align for other columns
          }
        }

        rowIndex++;
      }

      // Add simple borders to all cells
      for (var row = 0; row < rowIndex; row++) {
        for (var col = 0; col < headers.length; col++) {
          final cell = sheet.cell(excel.CellIndex.indexByColumnRow(
              columnIndex: col, rowIndex: row));

          var style = excel.CellStyle(
            backgroundColorHex: row == 0 ? "#4F4F4F" : "#FFFFFF",
            fontColorHex: row == 0 ? "#FFFFFF" : "#000000",
            bold: row == 0 ? true : false,
            horizontalAlign: row == 0
                ? excel.HorizontalAlign.Center
                : (col == 0
                    ? excel.HorizontalAlign.Left
                    : excel.HorizontalAlign.Center),
            verticalAlign: excel.VerticalAlign.Center,
            textWrapping: excel.TextWrapping.WrapText,
            fontSize: row == 0 ? 12 : 11,
          );
          cell.cellStyle = style;
        }
      }

      // Menyimpan file
      final directory = await getDownloadsDirectory();
      if (directory == null) throw Exception('Direktori tidak ditemukan');

      final fileName =
          'Transaction_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(excelfile.encode()!);

      await OpenFilex.open(filePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File Excel disimpan di: $filePath'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16,
            right: 16,
          ),
        ),
      );
    } catch (e) {
      print('Error export: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal export: $e')),
      );
    }
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        end: endDate ?? DateTime.now(),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF9A9A9A),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF333333),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      fetchTransactions();
    }
  }

  String formatCurrency(dynamic amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _showDateRangePicker,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF9A9A9A)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                startDate != null && endDate != null
                                    ? '${formatDate(startDate!)} - ${formatDate(endDate!)}'
                                    : 'Pilih Rentang Tanggal',
                                style: const TextStyle(
                                  color: Color(0xFF666666),
                                ),
                              ),
                              const Icon(
                                Icons.calendar_today,
                                color: Color(0xFF9A9A9A),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _exportToExcel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9A9A9A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('View to Excel'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF9A9A9A),
                          ),
                        )
                      : transactions.isEmpty
                          ? const Center(
                              child: Text(
                                'Tidak ada transaksi untuk periode ini',
                                style: TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : CustomScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              slivers: [
                                SliverPadding(
                                  padding: EdgeInsets.only(
                                    left: 16,
                                    right: 16,
                                    top: 16,
                                    bottom:
                                        MediaQuery.of(context).padding.bottom +
                                            32,
                                  ),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final transaction = transactions[index];
                                        final room = transaction['rooms'];

                                        return Container(
                                          margin:
                                              const EdgeInsets.only(bottom: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey
                                                    .withOpacity(0.1),
                                                spreadRadius: 1,
                                                blurRadius: 10,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        transaction[
                                                            'customer_name'],
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Color(0xFF333333),
                                                        ),
                                                        softWrap: true,
                                                        overflow: TextOverflow
                                                            .visible,
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                                0xFF9A9A9A)
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      child: Text(
                                                        formatCurrency(transaction[
                                                            'payment_amount']),
                                                        style: const TextStyle(
                                                          color:
                                                              Color(0xFF9A9A9A),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.hotel,
                                                      size: 20,
                                                      color: Color(0xFF9A9A9A),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      room != null
                                                          ? '${room['room_types']['name']} - Room ${room['room_number']}'
                                                          : 'Room data not available',
                                                      style: const TextStyle(
                                                        color:
                                                            Color(0xFF666666),
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.calendar_today,
                                                      size: 20,
                                                      color: Color(0xFF9A9A9A),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Transaction Date: ${formatDate(DateTime.parse(transaction['created_at']))}',
                                                      style: const TextStyle(
                                                        color:
                                                            Color(0xFF666666),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                      childCount: transactions.length,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
