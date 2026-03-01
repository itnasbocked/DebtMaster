// import 'package:dm/ui/ingresos_egresos.dart';
import 'package:flutter/material.dart';
// import 'data/database/database_helper.dart';
// import 'ui/auth_page.dart';
// import 'ui/metas_screen.dart';
import 'ui/ingresos_egresos.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Comentar await para evitar cuello de botella al iniciar la app
  // await DatabaseHelper.instance.database;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DebtMaster',
      home: const IngresosEgresosScreen(),
    );
  }
}