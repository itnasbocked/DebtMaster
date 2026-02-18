import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
      onCreate: _createDB,
    );
  }

  // Crear tablas
  Future _createDB(Database db, int version) async {

    await db.execute('''
      CREATE TABLE usuario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        ingreso_mensual REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tarjeta (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        nombre_tarjeta TEXT,
        tipo TEXT,
        corte_dia INTEGER,
        pago_dia INTEGER,
        monto_minimo REAL,
        FOREIGN KEY (usuario_id) REFERENCES usuario(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE gasto_fijo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        nombre_gasto TEXT,
        monto REAL,
        frecuencia TEXT,
        fecha_pago TEXT,
        FOREIGN KEY (usuario_id) REFERENCES usuario(id)
      )
    ''');

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
  }
}
