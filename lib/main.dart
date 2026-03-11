import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dm/ui/auth_page.dart';
import 'package:dm/ui/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Comenté el await para evitar cuello de botella al iniciar la app
  // await DatabaseHelper.instance.database;

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

  final prefs = await SharedPreferences.getInstance();
  final bool sesionActiva = prefs.getBool('isLoggedIn') ?? false;

  runApp(MyApp(sesionActiva: sesionActiva));
}

class MyApp extends StatelessWidget {
  final bool sesionActiva;
  const MyApp({super.key, required this.sesionActiva});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DebtMaster',
      home: sesionActiva ? const MainScreen() : const AuthPage(),
    );
  }
}