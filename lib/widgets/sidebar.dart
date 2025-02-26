import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            child: Text('Menu'),
          ),
          ListTile(
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pushNamed(context, '/dashboard');
            },
          ),
          ListTile(
            title: const Text('Profil'),
            onTap: () {
              Navigator.pushNamed(context, '/profil');
            },
          ),
          ListTile(
            title: const Text('Booking'),
            onTap: () {
              Navigator.pushNamed(context, '/booking');
            },
          ),
          ListTile(
            title: const Text('Log Aktivitas'),
            onTap: () {
              Navigator.pushNamed(context, '/log-aktivitas');
            },
          ),
        ],
      ),
    );
  }
}