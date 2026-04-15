import 'package:dm/logic/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database/database_helper.dart';
import 'auth_page.dart';

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
  final int idUsuarioActual = 1;
  final primaryBlue = const Color(0xFF6200EE);

  final List<Widget> _pantallas = const [
    CalendarioScreen(),
    TarjetasScreen(),
    IngresosEgresosScreen(),
    MetasScreen()
  ];

  final List<String> _titulos = [
    "Calendario",
    "Mis Tarjetas",
    "Movimientos",
    "Metas"
  ];

  Future<void> _mostrarPerfilUsuario() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('usuario', where: 'id = ?', whereArgs: [idUsuarioActual]);

    if (result.isEmpty) return;

    String nombre = result.first['nombre'] as String;
    String correo = result.first['correo'] as String;
    int ingresoCentavos = result.first['ingreso_mensual'] as int;

    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFF2962FF), 
                child: Icon(Icons.person, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(nombre, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(correo, style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    const Text("Ingreso Mensual", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      "\$${(ingresoCentavos / 100).toStringAsFixed(2)}", 
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF22C55E))
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cerrar", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              icon: const Icon(Icons.logout),
              label: const Text("Cerrar Sesión", style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear(); 

                if (!context.mounted) return;
                
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthPage()),
                  (route) => false, 
                );
              },
            )
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // HitTestBehavior.opaque es vital: permite capturar toques incluso 
      // en los espacios vacíos del fondo donde no hay widgets.
      behavior: HitTestBehavior.opaque,
      onDoubleTap: () {
        debugPrint("--- GESTO DE DEPURACIÓN: DOBLE TOQUE DETECTADO ---");
        NotificationService().Bypass();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F4F7),
        // Barra superior
        appBar: AppBar(
          title: Text(
            _titulos[_selectedIndex],
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 28, color: Colors.black)
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.account_circle, color: Colors.black, size: 32),
              onPressed: _mostrarPerfilUsuario, 
            )
          ],
        ),
        // Contenedor principal
        body: IndexedStack(
          index: _selectedIndex,
          children: _pantallas,
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
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
            offset: const Offset(0, -5), 
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
        selectedItemColor: primaryBlue,      
        unselectedItemColor: Colors.grey.shade400,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined, size: 26),
            activeIcon: Icon(Icons.calendar_today, size: 26),
            label: "Calendario",
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.credit_card_outlined, size: 28),
            activeIcon: Icon(Icons.credit_card, size: 28),
            label: "Tarjetas",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sync_alt_outlined, size: 28),
            activeIcon: Icon(Icons.sync_alt_rounded, size: 28),
            label: "Ingresos/Egresos",
          ),
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