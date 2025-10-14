import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/predio_service.dart';

class CommercialModal extends StatefulWidget {
  final Map<String, dynamic> commercialData;
  final LatLng coordinates;

  const CommercialModal({
    Key? key,
    required this.commercialData,
    required this.coordinates,
  }) : super(key: key);

  @override
  State<CommercialModal> createState() => _CommercialModalState();
}

class _CommercialModalState extends State<CommercialModal> {
  PageController pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          topLeft: Radius.circular(20),
        ),
      ),
      height: 400,
      child: PageView(
        controller: pageController,
        children: [
          _commercialInfoPage(),
          _predioInfoPage(),
        ],
      ),
    );
  }

  Widget _commercialInfoPage() {
    return Container(
      margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _row("Nombre: ", widget.commercialData["nombre"] ?? 'Sin nombre'),
          _row("Descripción: ", widget.commercialData["descripcion"] ?? 'Sin descripción'),
          Container(
            width: 400,
            height: 250,
            child: GridView.count(
              primary: false,
              padding: const EdgeInsets.only(top: 10, left: 15, right: 15),
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              crossAxisCount: 3,
              children: <Widget>[
                _iconInfo(
                  Icons.square_foot,
                  "${widget.commercialData["superficie_m3"] ?? 0}m2",
                  "Superficie",
                ),
                _iconInfo(
                  Icons.door_front_door,
                  "${widget.commercialData["num_cuartos"] ?? 0}",
                  "Cuartos",
                ),
                _iconInfo(
                  Icons.bathroom,
                  "${widget.commercialData["num_banos"] ?? 0}",
                  "Baños",
                ),
                _iconInfo(
                  Icons.local_parking,
                  "${widget.commercialData["num_cajones"] ?? 0}",
                  "Cajones",
                ),
              ],
            ),
          ),
          _row("Información adicional: ", widget.commercialData["extras"] ?? 'Sin información adicional'),
        ],
      ),
    );
  }

  Widget _predioInfoPage() {
    return FutureBuilder<PredioInfo?>(
      future: _getPredioInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data == null) {
          return const Center(
            child: Text('No se encontró información del predio'),
          );
        }

        final predioInfo = snapshot.data!;
        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.only(top: 15, left: 10, right: 10),
            child: Column(
              children: [
                // PRIMERO LA CLAVE Y EL MAPITA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _firstRow(predioInfo),
                ),
                // UBICACIÓN Y ZONIFICACIÓN
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  padding: const EdgeInsets.all(15),
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    children: _ubicationDescription(predioInfo),
                  ),
                ),
                // SUPERFICIE LEGAL
                Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(15),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Column(
                    children: _surfaceLegal(predioInfo),
                  ),
                ),
                Container(
                  color: Colors.black,
                  height: 1,
                  width: MediaQuery.of(context).size.width,
                ),
                // COMENZAMOS CON LOS PERMISOS
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  child: Center(
                    child: Column(
                      children: _bothPermitions(predioInfo),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Future<PredioInfo?> _getPredioInfo() async {
    try {
      final predioService = PredioService();
      return await predioService.fetchPredioByLatLng(widget.coordinates);
    } catch (e) {
      print('Error obteniendo información del predio: $e');
      return null;
    }
  }

  Widget _row(String nombreData, String tipoData) {
    return Row(
      children: [
        _texto(nombreData, 16, FontWeight.bold),
        _texto(tipoData, 14, FontWeight.w500),
      ],
    );
  }

  Widget _texto(String dataInfo, double tamFont, FontWeight fontWeight) {
    return Text(
      dataInfo,
      style: TextStyle(
        overflow: TextOverflow.ellipsis,
        fontWeight: fontWeight,
        fontSize: tamFont,
      ),
    );
  }

  Widget _iconInfo(IconData icon, String data, String nombre) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF00BCD4), width: 3),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 5),
            child: Text(nombre),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Icon(icon, size: 50),
              Text(
                data,
                style: const TextStyle(fontSize: 20),
              )
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _firstRow(PredioInfo data) {
    Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('predio'),
        position: widget.coordinates,
      )
    };

    return [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          color: Colors.black,
        ),
        child: Column(
          children: [
            Text(
              'Clave: ${data.cuentaCatastral}',
              textAlign: TextAlign.start,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            Text(
              'Tipo: ${data.usoDeSuelo}',
              textAlign: TextAlign.start,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.all(2),
        height: 100,
        width: 100,
        decoration: const BoxDecoration(
          color: Colors.black,
        ),
        child: GoogleMap(
          zoomControlsEnabled: false,
          initialCameraPosition: CameraPosition(
            target: widget.coordinates,
            zoom: 18,
          ),
          markers: markers,
        ),
      )
    ];
  }

  List<Widget> _ubicationDescription(PredioInfo data) {
    return [
      Text(
        'Ubicación: ${data.domicilio}',
        style: const TextStyle(color: Colors.white, fontSize: 18),
        textAlign: TextAlign.justify,
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          Text(
            'Uso de suelo: ${data.usoDeSuelo}',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
    ];
  }

  List<Widget> _surfaceLegal(PredioInfo data) {
    return [
      Text(
        'Superficie: ${data.superficie.toStringAsFixed(0)}m2',
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
      const SizedBox(height: 6),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            children: [
              Text(
                'Cuenta catastral: ${data.cuentaCatastral}',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ],
      ),
    ];
  }

  List<Widget> _bothPermitions(PredioInfo data) {
    return [
      SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        child: ExpansionTile(
          iconColor: Colors.white,
          collapsedIconColor: Colors.white,
          collapsedTextColor: Colors.white,
          collapsedBackgroundColor: Colors.black,
          textColor: Colors.white,
          backgroundColor: Colors.black,
          title: const Text('Información del predio'),
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Cuenta catastral: ${data.cuentaCatastral}\n'
                'Uso de suelo: ${data.usoDeSuelo}\n'
                'Superficie: ${data.superficie.toStringAsFixed(0)} m²\n'
                'Domicilio: ${data.domicilio}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 15),
    ];
  }
}
