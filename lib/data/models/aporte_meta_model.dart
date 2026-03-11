class AporteMeta {
  int? id;
  int metaId;
  int monto;
  DateTime fecha;

  AporteMeta({
    this.id,
    required this.metaId,
    required this.monto,
    required this.fecha,
  });

  factory AporteMeta.fromMap(Map<String, dynamic> map) {
    return AporteMeta(
      id: map['id'],
      metaId: map['meta_id'],
      monto: map['monto'],
      fecha: DateTime.parse(map['fecha']),
    );
  }
}