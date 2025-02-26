import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'dashboard_page.dart';
import 'booking_room_page.dart';
import 'history_transaction_page.dart';
import 'profil_page.dart';

// Custom AppBar Widget
class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String pageTitle;
  final String? userName;

  const CustomAppBar({
    Key? key,
    required this.pageTitle,
    this.userName,
  }) : super(key: key);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(75);
}

class _CustomAppBarState extends State<CustomAppBar> {
  late Timer _timer;
  late String _timeString;
  late String _dateString;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer =
        Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTime());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() {
    final DateTime now = DateTime.now();
    final String formattedTime = DateFormat('HH:mm').format(now);
    final String formattedDate = DateFormat('MMM dd, yyyy, HH.mm').format(now);
    if (mounted) {
      setState(() {
        _timeString = formattedTime;
        _dateString = formattedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hai, ${widget.userName ?? "Kasir"}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _dateString,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.pageTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF9A9A9A),
            ),
          ),
        ],
      ),
    );
  }
}

// Modified KasirPage
class KasirPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const KasirPage({Key? key, this.userData}) : super(key: key);

  @override
  _KasirPageState createState() => _KasirPageState();
}

class _KasirPageState extends State<KasirPage> {
  int _selectedIndex = 0;
  final Color _navColor = const Color(0xFF9A9A9A);
  late final List<Widget> _pages;
  Map<String, dynamic>? userData;

  // List of page titles
  final List<String> _pageTitles = [
    'Dashboard',
    'Booking Room',
    'History Transaction',
    'Profile'
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _pages = [
      DashboardPage(), // Pastikan class DashboardPage sudah didefinisikan
      BookingRoomPage(), // Pastikan class BookingRoomPage sudah didefinisikan
      HistoryTransactionPage(), // Pastikan class HistoryTransactionPage sudah didefinisikan
      ProfilPage(
          userData:
              widget.userData), // Pastikan class ProfilPage sudah didefinisikan
    ];
  }

  Future<void> _fetchUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('users')
          .select('username')
          .eq('id', user.id)
          .single();

      setState(() {
        userData = response;
      });
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        pageTitle: _pageTitles[_selectedIndex],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.dashboard, 'Dashboard'),
            _buildNavItem(1, Icons.add_box, 'Booking'),
            _buildNavItem(2, Icons.history, 'Log'),
            _buildNavItem(3, Icons.person, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _navColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? _navColor : Colors.grey[400],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? _navColor : Colors.grey[400],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
