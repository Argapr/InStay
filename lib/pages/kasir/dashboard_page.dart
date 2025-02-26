import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatelessWidget {
  DashboardPage({Key? key}) : super(key: key);

  final SupabaseClient supabase = Supabase.instance.client;
  final Color primaryColor = const Color(0xFF9A9A9A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildTotalBookingsCard()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTodayRevenueCard()),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildActiveRoomsCard()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildAvailableRoomsCard()),
                  ],
                ),
                const SizedBox(height: 32),
                _buildRecentTransactionsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalBookingsCard() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('transactions').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        return _buildDashboardCard(
          'Total Bookings',
          snapshot.hasData ? '${snapshot.data!.length}' : '...',
          Icons.book,
          Colors.blue,
        );
      },
    );
  }

  Widget _buildTodayRevenueCard() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('transactions').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        double total = 0;
        if (snapshot.hasData) {
          // Ambil tanggal hari ini dalam zona waktu UTC agar sesuai dengan database
          DateTime now = DateTime.now().toUtc();
          DateTime startOfDay = DateTime.utc(now.year, now.month, now.day);
          DateTime endOfDay = startOfDay.add(Duration(days: 1));

          // Debugging: Cetak semua transaksi yang masuk dari database
          print("=== Semua Transaksi ===");
          for (var transaction in snapshot.data!) {
            print(
                "ID: ${transaction['id']}, Created At: ${transaction['created_at']}, Amount: ${transaction['payment_amount']}");
          }

          // Filter transaksi berdasarkan tanggal hari ini
          var filteredTransactions = snapshot.data!.where((transaction) {
            if (transaction['created_at'] == null) return false;

            // Konversi ke UTC agar sesuai dengan database
            DateTime createdAt =
                DateTime.parse(transaction['created_at']).toUtc();

            return createdAt
                    .isAfter(startOfDay.subtract(Duration(seconds: 1))) &&
                createdAt.isBefore(endOfDay);
          }).toList();

          // Debugging: Cetak transaksi setelah difilter
          print("=== Transaksi Hari Ini ===");
          for (var transaction in filteredTransactions) {
            print(
                "ID: ${transaction['id']}, Created At: ${transaction['created_at']}, Amount: ${transaction['payment_amount']}");
          }

          // Hitung total pendapatan dari transaksi yang sudah difilter
          total = filteredTransactions.fold(
              0.0,
              (sum, transaction) =>
                  sum +
                  ((transaction['payment_amount'] ?? 0) as num).toDouble());
        }

        return _buildDashboardCard(
          'Today Revenue',
          'Rp ${(total / 1e6).toStringAsFixed(1)}M',
          Icons.attach_money,
          Colors.green,
        );
      },
    );
  }

  Widget _buildActiveRoomsCard() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('rooms').stream(primaryKey: ['id']).map((rooms) =>
          rooms.where((room) => room['is_available'] == true).toList()),
      builder: (context, snapshot) {
        return _buildDashboardCard(
          'Active Rooms',
          snapshot.hasData ? '${snapshot.data!.length}' : '...',
          Icons.meeting_room,
          Colors.orange,
        );
      },
    );
  }

  Widget _buildAvailableRoomsCard() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('rooms').stream(primaryKey: ['id']).map((rooms) =>
          rooms.where((room) => room['is_available'] == false).toList()),
      builder: (context, snapshot) {
        return _buildDashboardCard(
          'Non-Available Rooms',
          snapshot.hasData ? '${snapshot.data!.length}' : '...',
          Icons.room_preferences,
          Colors.purple,
        );
      },
    );
  }

  Widget _buildDashboardCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 15,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Transactions',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildRecentTransactionsList(),
      ],
    );
  }

  Widget _buildRecentTransactionsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('transactions')
          .stream(primaryKey: ['id']).map((transactions) => transactions
            ..sort((a, b) => DateTime.parse(b['created_at'])
                .compareTo(DateTime.parse(a['created_at'])))
            ..take(3)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final transactions = snapshot.data ?? [];

        return Column(
          children: transactions
              .take(3)
              .map((transaction) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: primaryColor.withOpacity(0.1),
                        child: Icon(
                          Icons.receipt_long,
                          color: primaryColor,
                        ),
                      ),
                      title: Text(
                        transaction['customer_name'] ?? 'No Name',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        DateFormat('dd MMM yyyy, HH:mm').format(
                          DateTime.parse(transaction['created_at']),
                        ),
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      trailing: Text(
                        'Rp ${NumberFormat('#,###').format(transaction['payment_amount'])}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}
