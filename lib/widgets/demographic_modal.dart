import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ChartData {
  String name;
  int value;
  Color color;
  ChartData({required this.name, required this.value, required this.color});
}

class DemographicModal extends StatelessWidget {
  final int total;
  final int hombres;
  final int mujeres;
  final List demoGraficData;

  const DemographicModal({
    Key? key,
    required this.total,
    required this.hombres,
    required this.mujeres,
    required this.demoGraficData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<ChartData> chartData = [
      ChartData(name: 'Hombres', value: hombres, color: Colors.orange),
      ChartData(name: 'Mujeres', value: mujeres, color: const Color(0xFF00BCD4)),
    ];

    Size size = MediaQuery.of(context).size;
    return AlertDialog(
      title: const Center(child: Text('Datos Demográficos')),
      content: SizedBox(
        height: size.height * 0.35,
        width: size.width * 0.5,
        child: PageView(
          children: [
            _womenAndMen(size, chartData),
            _otherDemographic(size),
          ],
        ),
      ),
    );
  }

  Widget _womenAndMen(Size size, List<ChartData> chartData) {
    return SizedBox(
      height: size.height * 0.5,
      width: size.width * 0.5,
      child: Column(
        children: [
          const Text('Total de habitantes en la zona: '),
          Text(
            total.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(
            width: size.width * 0.8,
            height: size.height * 0.3,
            child: SfCircularChart(
              legend: Legend(
                isVisible: true,
                position: LegendPosition.bottom,
              ),
              series: [
                DoughnutSeries<ChartData, String>(
                  dataSource: chartData,
                  pointColorMapper: (ChartData data, _) => data.color,
                  xValueMapper: (ChartData data, _) => data.name,
                  yValueMapper: (ChartData data, _) => data.value,
                  dataLabelSettings: DataLabelSettings(isVisible: true),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _otherDemographic(Size size) {
    Map<String, List> listOfExpandible = {
      'MS': [],
      'SI': [],
      'SP': [],
      'GE': [],
      'MF': [],
      'EE': [],
      'P': [],
      'ARI': [],
      'ISE': [],
      'I': [],
      'T': [],
      'PO': [],
    };

    for (var element in demoGraficData) {
      String categoria = element['categoria'] ?? '';
      if (listOfExpandible.containsKey(categoria)) {
        listOfExpandible[categoria]!.add(element);
      }
    }

    return SizedBox(
      height: size.height * 0.5,
      width: size.width * 0.5,
      child: SingleChildScrollView(
        child: Column(children: _returnExpandibles(listOfExpandible, size)),
      ),
    );
  }

  List<Widget> _returnExpandibles(Map<String, List> listOfExpandible, Size size) {
    List<Widget> listWidgets = [];

    for (var categoria in listOfExpandible.keys) {
      if (listOfExpandible[categoria]!.isEmpty) continue;
      
      String name = _getCategoriString(categoria);
      List<Widget> expandible = [];
      
      for (var element in listOfExpandible[categoria]!) {
        expandible.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
            child: ExpansionTile(
              iconColor: Colors.white,
              collapsedIconColor: Colors.white,
              collapsedTextColor: Colors.white,
              collapsedBackgroundColor: Colors.black,
              textColor: Colors.white,
              backgroundColor: Colors.black,
              title: Text(element['nombre'] ?? ''),
              children: [
                Text(
                  '${element['dato'] ?? ''} ${element['unidad'] ?? ''}',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                )
              ],
            ),
          ),
        );
      }

      Widget w = Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: SizedBox(
          width: size.width * 0.85,
          child: ExpansionTile(
            iconColor: Colors.white,
            collapsedIconColor: Colors.white,
            collapsedTextColor: Colors.white,
            collapsedBackgroundColor: Colors.black,
            textColor: Colors.white,
            backgroundColor: Colors.black,
            title: Text(name),
            children: expandible,
          ),
        ),
      );
      listWidgets.add(w);
    }

    return listWidgets;
  }

  String _getCategoriString(String categoria) {
    switch (categoria) {
      case 'MS':
        return 'Manejo sustentable del medio ambiente';
      case 'SI':
        return 'Sociedad incluyente';
      case 'SP':
        return 'Sistema político';
      case 'GE':
        return 'Gobierno eficiente';
      case 'MF':
        return 'Mercado de factores';
      case 'EE':
        return 'Economía estable';
      case 'P':
        return 'Precursores';
      case 'ARI':
        return 'Aprovechamiento de relaciones internacionales';
      case 'ISE':
        return 'Innovación de sectores económicos';
      case 'I':
        return 'Inversión';
      case 'T':
        return 'Talento';
      default:
        return 'Población';
    }
  }
}
