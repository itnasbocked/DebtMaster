class Meta{
    int? id;
    int usuarioId;
    String nombre;
    int montoObjetivo;
    int montoActual;
    DateTime fechaLimite;
    String icono

    Meta({
        this.id,
        required this.usuarioId,
        required this.nombre,
        required this.montoObjetivo,
        this.montoActual = 0,
        required this fechaLimite,
        required this.icono,
    });

    Map<String, dynamic> toMap(){
        return{
            'id' : id,
            'usuario_id': usuarioId,
            'nombre': nombre,
            'monto_objetivo' : montoObjetivo,
            'monto_actual' : montoActual,
            'fecha_limite' : fechaLimite.toIso8601String(),
            'icono' : icono,
        };
    }

    factory Meta.fromMap(Map<String, dynamic> map){
        return Meta(
            id: map['id'],
            usuarioId: map['usuario_id'],
            nombre: map['nombre'],
            montoObjetivo: map['monto_objetivo'],
            montoActual: map['monto_actual'],
            fechaLimite: DateTime.parse(map['fecha_limite']),
            icono: map['icono'],
        );
    }
}