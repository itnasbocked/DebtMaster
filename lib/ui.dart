import 'package:flutter/material.dart';
import 'dart:math';

class IngresosEgresosScreen extends StatefulWidget {
  @override
  State<IngresosEgresosScreen> createState() =>
      _IngresosEgresosScreenState();
}

class _IngresosEgresosScreenState
    extends State<IngresosEgresosScreen> {

  List<Movimiento> movimientos = [];

  int idUsuario = 1;

  int get totalIngresos {
    return movimientos
        .where((m) => m.tipo == "ingreso" && esDelMesActual(m.fecha))
        .fold(0, (sum, m) => sum + m.monto);
  }

  int get totalEgresos {
    return movimientos
        .where((m) => m.tipo == "egreso" && esDelMesActual(m.fecha))
        .fold(0, (sum, m) => sum + m.monto);
  }

  bool esDelMesActual(DateTime fecha) {
    DateTime now = DateTime.now();
    return fecha.month == now.month && fecha.year == now.year;
  }

  double get porcentajeGasto {
    if (totalIngresos == 0) return 0;
    return totalEgresos / totalIngresos;
  }

  void agregarMovimiento(String tipo) async {
    TextEditingController montoController =
        TextEditingController();
    TextEditingController descripcionController =
        TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Agregar $tipo"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: montoController,
              keyboardType: TextInputType.number,
              decoration:
                  InputDecoration(labelText: "Monto"),
            ),
            TextField(
              controller: descripcionController,
              decoration:
                  InputDecoration(labelText: "Descripción"),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancelar")),
          ElevatedButton(
              onPressed: () {
                movimientos.add(
                  Movimiento(
                    idUsuario: idUsuario,
                    monto: int.parse(montoController.text),
                    fecha: DateTime.now(),
                    tipo: tipo,
                    descripcion:
                        descripcionController.text,
                  ),
                );
                setState(() {});
                Navigator.pop(context);
              },
              child: Text("Guardar"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    Color grisClaro = Color(0xFFE6E8EB);
    Color grisMedio = Color(0xFFBFC3C8);

    return Scaffold(
      backgroundColor: Color(0xFFF2F4F7),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [

              // Título
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: grisClaro,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      "Ingresos / egresos",
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [

                        // INGRESOS
                        Expanded(
                          child: Container(
                            margin:
                                EdgeInsets.only(right: 10),
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: grisMedio,
                              borderRadius:
                                  BorderRadius.circular(
                                      20),
                            ),
                            child: Column(
                              children: [
                                Text("Ingresos",
                                    style: TextStyle(
                                        fontSize: 18,
                                        color:
                                            Colors.white)),
                                SizedBox(height: 10),
                                Container(
                                  height: 60,
                                  decoration:
                                      BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius
                                            .circular(15),
                                  ),
                                  alignment:
                                      Alignment.center,
                                  child: Text(
                                    "\$${(totalIngresos / 100).toStringAsFixed(2)}",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight:
                                            FontWeight
                                                .bold),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),

                        // EGRESOS
                        Expanded(
                          child: Container(
                            margin:
                                EdgeInsets.only(left: 10),
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: grisMedio,
                              borderRadius:
                                  BorderRadius.circular(
                                      20),
                            ),
                            child: Column(
                              children: [
                                Text("Egresos",
                                    style: TextStyle(
                                        fontSize: 18,
                                        color:
                                            Colors.white)),
                                SizedBox(height: 10),
                                Container(
                                  height: 60,
                                  decoration:
                                      BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius
                                            .circular(15),
                                  ),
                                  alignment:
                                      Alignment.center,
                                  child: Text(
                                    "\$${(totalEgresos / 100).toStringAsFixed(2)}",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight:
                                            FontWeight
                                                .bold),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30),

              // GRAFICA
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFFDADDE2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  children: [
                    Text(
                      "Salud sobre ingresos en gastos",
                      style: TextStyle(
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceAround,
                      children: [
                        SizedBox(
                          width: 150,
                          height: 150,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: porcentajeGasto,
                                strokeWidth: 15,
                                backgroundColor:
                                    Colors.grey.shade300,
                                valueColor:
                                    AlwaysStoppedAnimation(
                                        Colors.green),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 100,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(
                                    15),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "${(porcentajeGasto * 100).toStringAsFixed(1)}%",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30),

              // BOTONES
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.access_time,
                        size: 40),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  HistorialScreen(
                                      movimientos)));
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.add, size: 40),
                    onPressed: () {
                      showModalBottomSheet(
                          context: context,
                          builder: (_) => Column(
                                mainAxisSize:
                                    MainAxisSize.min,
                                children: [
                                  ListTile(
                                    title:
                                        Text("Ingreso"),
                                    onTap: () {
                                      Navigator.pop(
                                          context);
                                      agregarMovimiento(
                                          "ingreso");
                                    },
                                  ),
                                  ListTile(
                                    title:
                                        Text("Egreso"),
                                    onTap: () {
                                      Navigator.pop(
                                          context);
                                      agregarMovimiento(
                                          "egreso");
                                    },
                                  ),
                                ],
                              ));
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}