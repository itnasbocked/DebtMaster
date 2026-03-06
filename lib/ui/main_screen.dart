import 'package:flutter/material.dart';
import 'ingresos_egresos_screen.dart';
import 'metas_screen.dart';
import 'calendario_screen.dart';
import 'tarjetas_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final primaryBlue = const Color(0xFF6200EE); //0xFF2563EB
  final List<Widget> _pantallas = [
    CalendarioScreen(),
    TarjetasScreen(),
    IngresosEgresosScreen(),
    MetasScreen()
  ];

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Colors.white,
      body: _pantallas[_selectedIndex],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5), // Sombra sutil hacia arriba
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: primaryBlue,      // Azul #2962FF
        unselectedItemColor: Colors.grey.shade400,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        items: const [
          // 1. Calendario
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined, size: 26),
            activeIcon: Icon(Icons.calendar_today, size: 26),
            label: "Calendario",
          ),
          // 2. Tarjetas (Pagos TDC)
          BottomNavigationBarItem(
              icon: Icon(Icons.credit_card_outlined, size: 28),
            activeIcon: Icon(Icons.credit_card, size: 28),
            label: "Tarjetas",
          ),
          // 3. Billetera (Dashboard principal)
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined, size: 28),
            activeIcon: Icon(Icons.account_balance_wallet, size: 28),
            label: "Billetera",
          ),
          // 4. Metas (Objetivos de ahorro)
          BottomNavigationBarItem(
            icon: Icon(Icons.outlined_flag, size: 28),
            activeIcon: Icon(Icons.flag, size: 28),
            label: "Metas",
          ),
        ],
      ),
    );
  }

}