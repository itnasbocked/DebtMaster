import '../data/database/database_helper.dart';
import '../data/models/ingresos-egresos.dart';

class MovimientoController{
  Future<String> registrarMovimiento({
    required String montoRaw,
    required String descripcion,
    required String tipo,
    required String frecuencia,
    required int usuarioId,
  }) async{
    try{
      if (montoRaw.isEmpty) return 'El monto no puede estar vacío';
      final montoDecimal = double.tryParse(montoRaw) ?? 0.0;
      if (montoDecimal <= 0) return 'Monto inválido. Debe ser un número positivo.';
      int montoCentavos = (montoDecimal * 100).round();

      final nuevoMovimiento = Movimiento(usuario_id: usuarioId, monto: montoCentavos, fecha: DateTime.now(), tipo: tipo,
      descripcion: descripcion.isEmpty ? "Sin descripción" : descripcion, frecuencia: 'ninguna');

      final id = await DatabaseHelper.instance.crearMovimiento(nuevoMovimiento);
      if (id > 0){
        return 'ÉXITO';
      } else{
        return 'Error al registrar movimiento';
      }

    } catch (e){
      return 'Error al registrar movimiento: ${e.toString()}';
    }
  }

  Future<double> formatearBalance(int usuarioId) async{
    int balanceCentavos = await DatabaseHelper.instance.obtenerBalance(usuarioId);
    return balanceCentavos / 100.0;
  }

  Future <List<Movimiento>> obtenerMovimientos(int usuarioId) async{
    try{
      return await DatabaseHelper.instance.consultarMovimientos(usuarioId);
    } catch (e){
      //Devolver una lista vacía para no romper la UI
      print('Error al obtener movimientos: ${e.toString()}');
      return [];
    }
  }
}