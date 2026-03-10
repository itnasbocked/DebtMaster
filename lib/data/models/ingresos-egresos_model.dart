class Movimiento {
  int? id;
  int usuario_id;
  int monto; // Guardado en centavos
  DateTime fecha;
  String tipo;
  String? descripcion;
  String frecuencia; // 'ninguna', 'diario', 'semanal', 'mensual', etc.

  Movimiento({
    this.id,
    required this.usuario_id,
    required this.monto,
    required this.fecha,
    required this.tipo,
    this.descripcion = "Opcional",
    this.frecuencia = 'ninguna'
  });

  //Escritura a la BD / Convertir a un mapa
  Map<String, dynamic> toMap(){
    return {
    'id': id,
    'usuario_id': usuario_id,
    'monto': monto,
    'fecha': fecha.toIso8601String(),
    'tipo': tipo,
    'descripcion': descripcion,
    'frecuencia': frecuencia
    };
  }
  
  //Lectura de la BD / Constructor de un mapa
  //Un factory permite crear una instancia apicando lógica antes de devolver el objeto
  factory Movimiento.fromMap(Map<String, dynamic> map){
    return Movimiento(
      id: map['id'],
      usuario_id: map['usuario_id'],
      monto: map['monto'],
      fecha: DateTime.parse(map['fecha']),
      tipo: map['tipo'],
      descripcion: map['descripcion'],
      frecuencia: map['frecuencia']
    );
  }
}
