import 'package:flutter/material.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({Key? key}) : super(key: key);

  @override
  _BottomNavigationState createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Navigasi ke halaman yang sesuai berdasarkan index
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/log-aktivitas');
        break;
      case 1:
        Navigator.pushNamed(context, '/booking');
        break;
      case 2:
        Navigator.pushNamed(context, '/profil');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.list_alt),
          label: 'Log Aktivitas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add),
          label: 'Booking',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    );
  }
}