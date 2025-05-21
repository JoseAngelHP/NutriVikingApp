import 'package:flutter/material.dart';
import 'package:nutri_viking_app/Pages/qr_scanner.dart';
import 'client_macros_page.dart';
import 'modern_macros_page.dart';
import 'nutrition_macros_page.dart'; 

class MainNavigationPage extends StatefulWidget {
  final String clientId;
  final String clientName;
  final String coachId;

  const MainNavigationPage({
    Key? key,
    required this.clientId,
    required this.clientName,
    required this.coachId,
  }) : super(key: key);

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      ClientMacrosPage(
        clientId: widget.clientId,
        clientName: widget.clientName,
        coachId: widget.coachId,
      ),
      ModernMacrosPage(
        clientId: widget.clientId,
        clientName: widget.clientName,
        coachId: widget.coachId,
      ),
      NutritionMacrosPage(
        clientId: widget.clientId,
        coachId: widget.coachId, 
        clientName: widget.clientName, 
      ),
      QrScanner(
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFFb51837),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.supervised_user_circle), label: 'Perfil'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart_rounded), label: 'Datos'),
          BottomNavigationBarItem(icon: Icon(Icons.bento_rounded), label: 'Salud'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_sharp), label: 'QR'),
        ],
      ),
    );
  }
}
