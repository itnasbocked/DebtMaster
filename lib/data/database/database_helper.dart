import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/ingresos-egresos_model.dart';

class DatabaseHelper {

  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Obtener la base de datos
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('debtmaster.db');
    return _database!;
  }

  // Inicializar DB
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async{
        await _createDB(db, version);
      }
    );
  }

  Future _createDB(Database db, int version) async {
    // 1. Tabla de Usuarios
    await db.execute('''
      CREATE TABLE usuario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        correo TEXT NOT NULL UNIQUE,      -- Añadido para el login
        contrasena TEXT NOT NULL,         -- Añadido para el login
        ingreso_mensual INTEGER NOT NULL
      )
    ''');

    // 2. Tabla de Tarjetas
    await db.execute('''
    CREATE TABLE tarjeta (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      usuario_id INTEGER NOT NULL,
      nombre_tarjeta TEXT,
      numero_tarjeta TEXT, -- NUEVA COLUMNA
      tipo TEXT,
      corte_dia INTEGER,
      pago_dia INTEGER,
      monto_minimo INTEGER,
      FOREIGN KEY (usuario_id) REFERENCES usuario(id)
    )
  ''');

    // 3. Tabla de Gastos Fijos
    await db.execute('''
      CREATE TABLE gasto_fijo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        nombre_gasto TEXT,
        monto INTEGER,
        frecuencia TEXT,
        fecha_pago TEXT,
        FOREIGN KEY (usuario_id) REFERENCES usuario(id)
      )
    ''');

    // 4. Tabla de Movimientos (Ingresos/Egresos)
    await db.execute('''
      CREATE TABLE movimiento (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        monto INTEGER NOT NULL,
        fecha TEXT NOT NULL,
        tipo TEXT NOT NULL,
        descripcion TEXT,
        frecuencia TEXT NOT NULL DEFAULT 'ninguna', -- 'diario', 'semanal', 'mensual', etc.
        FOREIGN KEY (usuario_id) REFERENCES usuario(id)
      )
    ''');

    await db.insert('usuario', {
    'nombre': 'Admin',
    'correo': 'admin@debtmaster.com',
    'contrasena': 'admin123',
    'ingreso_mensual': 1000000, // En centavos
    });

    // 5. Tabla de Alertas
    await db.execute('''
      CREATE TABLE alerta (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        tipo TEXT,
        fecha_alerta TEXT,
        mensaje TEXT,
        FOREIGN KEY (usuario_id) REFERENCES usuario(id)
        )
    ''');

    // 6. Tabla de Metas
    await db.execute( '''
      CREATE TABLE meta(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        monto_objetivo INTEGER NOT NULL,
        monto_actual INTEGER NOT NULL DEFAULT 0,
        fecha_limite TEXT NOT NULL,
        icono TEXT NOT NULL,
        FOREIGN KEY (usuario_id) REFERENCES usuario(id)
      )
    ''');

    // 7. Tabla de Historial de Aportes a Metas
    await db.execute('''
      CREATE TABLE aporte_meta (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        meta_id INTEGER NOT NULL,
        monto INTEGER NOT NULL,
        fecha TEXT NOT NULL,
        FOREIGN KEY (meta_id) REFERENCES meta(id) ON DELETE CASCADE
      )
    ''');
  
  }

  Future<void> inyectarTarjetaPrueba() async {
    debugPrint("Inicio");
    final db = await instance.database;
    
    final List<Map<String, dynamic>> existentes = await db.query('tarjeta');
    if (existentes.isEmpty) {
      await db.insert('tarjeta', {
        'usuario_id': 1,
        'nombre_tarjeta': 'BBVA',
        'numero_tarjeta': '4152 3134 1234 5678',
        'tipo': 'Credito',
        'corte_dia': 20,
        'pago_dia': 5,
        'monto_minimo': 250000
      });
      debugPrint("--- HARDWARE: Tarjeta de prueba inyectada con tu esquema ---");
      calcularPresupuestoDiarioSeguro();
    }
  }

  Future<int> insertarTarjeta(Map<String, dynamic> tarjetaData) async {
    final db = await database;
    return await db.insert('tarjeta', tarjetaData);
  }

  Future<double> calcularPresupuestoDiarioSeguro() async {
    debugPrint("Calculo de Preuspuesto");
    final db = await instance.database;
    debugPrint("Salida de la instancia");

    final List<Map<String, dynamic>> ingresosData = await db.rawQuery("SELECT SUM(monto) as total FROM movimiento WHERE tipo = 'ingreso'");
    final List<Map<String, dynamic>> gastosData = await db.rawQuery("SELECT SUM(monto) as total FROM movimiento WHERE tipo = 'gasto'");
    
    double ingresos = (ingresosData.first['total'] as num?)?.toDouble() ?? 0.0;
    double gastos = (gastosData.first['total'] as num?)?.toDouble() ?? 0.0;
    double liquidez = ingresos - gastos;

    debugPrint("Ingresos");
    final List<Map<String, dynamic>> deudaData = await db.rawQuery("SELECT SUM(monto_minimo) as total FROM tarjeta");
    double obligaciones = (deudaData.first['total'] as num?)?.toDouble() ?? 0.0;
    debugPrint("Salida Ingresos");


    DateTime hoy = DateTime.now();
    DateTime ultimoDiaMes = DateTime(hoy.year, hoy.month + 1, 0); 
    int diasRestantes = ultimoDiaMes.day - hoy.day;

    if (diasRestantes <= 0) diasRestantes = 1;

    double dineroLibre = (liquidez - obligaciones) / 100;
    double presupuestoDiario = dineroLibre / diasRestantes;
    
    debugPrint(presupuestoDiario.toString());
    if (presupuestoDiario < 0) return 0.0;

    debugPrint("Liquidez: \$${liquidez.toStringAsFixed(2)} | Deuda: \$${obligaciones.toStringAsFixed(2)} | Días: $diasRestantes");
    debugPrint("PRESUPUESTO DIARIO: \$${presupuestoDiario.toStringAsFixed(2)}");

    return presupuestoDiario;
  }

  Future<List<Map<String, dynamic>>> obtenerTarjetas() async {
    final db = await database;
    return await db.query('tarjeta');
  }

  //Funciones CRUD para usuarios

  Future<int> crearUsuario({
  required String nombre,
  required String correo,
  required String contrasena,
  required double ingresoMensual,
  }) async {
  final db = await instance.database;
  
  return await db.insert('usuario', {
    'nombre': nombre,
    'correo': correo,
    'contrasena': contrasena,
    'ingreso_mensual': (ingresoMensual * 100).round(),
    });
  }

  Future<Map<String, dynamic>?> verificarUsuario(String correo, String contrasena) async {
  final db = await instance.database;
  
  final maps = await db.query(
    'usuario',
    where: 'correo = ? AND contrasena = ?',
    whereArgs: [correo, contrasena],
  );

  if (maps.isNotEmpty) {
    return maps.first;
  }
    return null;
  }

  Future<int> crearMovimiento(Movimiento movimiento) async{
    final db = await instance.database;
    return await db.insert('movimiento', movimiento.toMap());
  }

  Future<List<Movimiento>> consultarMovimientos(int usuarioId) async{
    final db = await instance.database;
    final result = await db.query('movimiento',
    where: 'usuario_id = ?',
    whereArgs: [usuarioId],
    orderBy: 'fecha DESC');
    return result.map((map) => Movimiento.fromMap(map)).toList();
  }

  // static Database? _database;
  
  Future<int> obtenerBalance(int usuarioId) async{
    final Database db = await instance.database;

    final resultIngresos = await db.rawQuery(
      'SELECT SUM(monto) as total FROM movimiento WHERE usuario_id = ? AND tipo = ?', 
      [usuarioId, 'ingreso']
    );
    final resultEgresos = await db.rawQuery(
      'SELECT SUM(monto) as total FROM movimiento WHERE usuario_id = ? AND tipo = ?', 
      [usuarioId, 'egreso']
    );

    int ingresos = (resultIngresos.first['total'] as int?) ?? 0;
    int egresos = (resultEgresos.first['total'] as int?) ?? 0;

    return ingresos - egresos;
  }
  
}
