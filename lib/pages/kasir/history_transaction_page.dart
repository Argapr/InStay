import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class HistoryTransactionPage extends StatefulWidget {
  const HistoryTransactionPage({super.key});

  @override
  State<HistoryTransactionPage> createState() => _HistoryTransactionPageState();
}

class _HistoryTransactionPageState extends State<HistoryTransactionPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> transactions = [];
  bool isLoading = true;
  final Map<int, Timer> _timers = {};
  final Map<int, Duration> _remainingTimes = {};
  final Map<int, bool> _isCheckedIn = {};

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  @override
  void dispose() {
    _timers.forEach((key, timer) => timer.cancel());
    super.dispose();
  }

  Future<void> fetchTransactions() async {
    try {
      final response = await supabase.from('transactions').select('''
    id, customer_name, created_at, duration_nights, checked_in_at, check_out_date,
    rooms (
      id, room_number, room_types (name)
    )
  ''').order('created_at', ascending: false); // Tambahkan ini

      if (response != null) {
        setState(() {
          transactions = response;
          isLoading = false;

          for (int i = 0; i < transactions.length; i++) {
            final transaction = transactions[i];
            final nights =
                (transaction['duration_nights'] as num?)?.toInt() ?? 1;
            final checkedInAt = transaction['checked_in_at'];
            final checkOutDate = transaction['check_out_date'];

            if (checkedInAt != null && checkOutDate == null) {
              final checkInTime = DateTime.parse(checkedInAt);
              final now = DateTime.now();
              final diff = now.difference(checkInTime);
              final remaining = Duration(hours: 24 * nights) - diff;

              if (remaining.isNegative) {
                _remainingTimes[i] = Duration.zero;
                _isCheckedIn[i] = false;
              } else {
                _remainingTimes[i] = remaining;
                _isCheckedIn[i] = true;
                _startTimer(i);
              }
            } else {
              _isCheckedIn[i] = false;
            }
          }
        });
      }
    } catch (e) {
      print('Error fetching transactions: $e');
      setState(() => isLoading = false);
    }
  }

  void _startTimer(int index) {
    _timers[index]?.cancel();

    _timers[index] = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTimes[index] != null &&
            _remainingTimes[index]!.inSeconds > 0) {
          _remainingTimes[index] =
              _remainingTimes[index]! - const Duration(seconds: 1);
        } else {
          timer.cancel();
          _isCheckedIn[index] = false;
        }
      });
    });
  }

  Future<void> _logActivity(String activity) async {
    final prefs = await SharedPreferences.getInstance();
    final cashierId =
        prefs.getString('user_id'); // Ambil ID kasir dari SharedPreferences

    if (cashierId != null) {
      await supabase.from('log').insert({
        'id_user': cashierId,
        'activity': activity,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _checkIn(int index) async {
    final transaction = transactions[index];
    final transactionId = transaction['id'];
    final room = transaction['rooms'];
    final roomNumber = room?['room_number'] ?? 'Unknown';

    try {
      final checkInTime = DateTime.now();
      await supabase
          .from('transactions')
          .update({'checked_in_at': checkInTime.toIso8601String()}).eq(
              'id', transactionId);

      setState(() {
        _isCheckedIn[index] = true;
        _remainingTimes[index] =
            Duration(hours: 24 * (transaction['duration_nights'] as int? ?? 1));
      });

      _startTimer(index);
      await _logActivity('Melakukan check-in pada room $roomNumber');
    } catch (e) {
      print('Check-in failed: $e');
    }
  }

  Future<void> _checkOut(int index) async {
    final transaction = transactions[index];
    final transactionId = transaction['id'];
    final room = transaction['rooms'];
    final roomId = room?['id'];
    final roomNumber = room?['room_number'] ?? 'Unknown';

    try {
      await supabase
          .from('transactions')
          .update({'check_out_date': DateTime.now().toIso8601String()}).eq(
              'id', transactionId);

      if (roomId != null) {
        await supabase
            .from('rooms')
            .update({'is_available': true}).eq('id', roomId);
      }

      _timers[index]?.cancel();
      await fetchTransactions();
      // setState(() {
      //   _isCheckedIn[index] = false;
      //   _remainingTimes[index] = Duration.zero;
      // });

      await _logActivity('Melakukan check-out pada room $roomNumber');
    } catch (e) {
      print('Check-out failed: $e');
    }
  }

  String formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    final date = DateTime.parse(dateString).toLocal();
    return DateFormat('dd MMMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9A9A9A)),
            ))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                final room = transaction['rooms'];
                final roomType = room?['room_types']?['name'] ?? 'Unknown';
                final roomNumber = room?['room_number'] ?? 'Unknown';
                final customerName = transaction['customer_name'] ?? 'Unknown';
                final transactionDate = formatDate(transaction['created_at']);
                final checkOutDate = transaction['check_out_date'];
                final isCheckedIn = _isCheckedIn[index] ?? false;
                final remainingTime = _remainingTimes[index] ?? Duration.zero;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFF9A9A9A),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                customerName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Room $roomNumber',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.hotel,
                                  color: Color(0xFF9A9A9A),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  roomType,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF9A9A9A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  color: Color(0xFF9A9A9A),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  transactionDate,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              ],
                            ),
                            if (isCheckedIn && checkOutDate == null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.timer,
                                      color: Color(0xFFFF9800),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Remaining: ${remainingTime.inHours}:${remainingTime.inMinutes.remainder(60)}:${remainingTime.inSeconds.remainder(60)}',
                                      style: const TextStyle(
                                        color: Color(0xFFFF9800),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            if (!isCheckedIn && checkOutDate == null)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _checkIn(index),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF9A9A9A),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Check-in',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            if (isCheckedIn && checkOutDate == null)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _checkOut(index),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF9800),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Check-out',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
