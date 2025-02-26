import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class LogActivityPage extends StatefulWidget {
  @override
  _LogActivityPageState createState() => _LogActivityPageState();
}

class _LogActivityPageState extends State<LogActivityPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  DateTime? startDate;
  DateTime? endDate;
  
  final Color primaryColor = Color(0xFF9A9A9A);
  final Color backgroundColor = Color(0xFFF5F5F5);

  Future<List<Map<String, dynamic>>> fetchLogActivities() async {
    try {
      var query = supabase
          .from('log')
          .select('id, activity, created_at, users!inner(username, role)');

      if (startDate != null && endDate != null) {
        final endOfDay = DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59);
        query = query.filter('created_at', 'gt', startDate!.toIso8601String())
                    .filter('created_at', 'lt', endOfDay.toIso8601String());
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List<dynamic>).map<Map<String, dynamic>>((log) {
        return {
          'log_activity': "${log['users']['username']} ${log['activity']} sebagai ${log['users']['role']}",
          'created_at': log['created_at'],
          'username': log['users']['username'],
          'role': log['users']['role'],
        };
      }).toList();
    } catch (e) {
      print("Error fetching log activities: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today, color: primaryColor),
            onPressed: () => _selectDateRange(context),
          ),
        ],
      ),
      body: Column(
        children: [
          if (startDate != null && endDate != null)
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  Icon(Icons.date_range, color: primaryColor),
                  SizedBox(width: 8),
                  Text(
                    '${DateFormat('dd/MM/yyyy').format(startDate!)} - ${DateFormat('dd/MM/yyyy').format(endDate!)}',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        startDate = null;
                        endDate = null;
                      });
                    },
                    child: Text('Reset', style: TextStyle(color: primaryColor)),
                  ),
                ],
              ),
            ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchLogActivities(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: primaryColor));
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                        SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }
                final logs = snapshot.data ?? [];
                if (logs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 48, color: primaryColor),
                        SizedBox(height: 16),
                        Text('Tidak ada aktivitas'),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: EdgeInsets.all(8),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.grey[200],
                              child: Icon(Icons.person_outline, color: Colors.grey),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    log['username'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    log['log_activity'],
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        DateFormat('dd MMM yyyy HH:mm').format(
                                          DateTime.parse(log['created_at']),
                                        ),
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                log['role'],
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
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
    }
  }
}