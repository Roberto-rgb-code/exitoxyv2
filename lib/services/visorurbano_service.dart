import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gsheets/gsheets.dart';

class ExcelToUTM { // <-- antes: ExcelReader
  static const _credentials = r'''PASTE_AQUI_TUS_CREDENTIALS_JSON_DE_SERVICE_ACCOUNT''';
  static const _spreadsheetId = '1hbxDEXj7bvZ-zFCdemxb1c9xZ_-LYLLgiSV4P76U8rQ';
  static final _gsheets = GSheets(_credentials);
  static Worksheet? _ws;

  static Future<void> init() async {
    final ss = await _gsheets.spreadsheet(_spreadsheetId);
    _ws = await ss.worksheetByTitle('Cálculo de Coordenadas');
  }

  static Future<List<double>> toUTM(double lat, double lon) async {
    if (_ws == null) await init();
    final row = 2;
    await _ws!.values.insertValue(lon, column: 1, row: row);
    await _ws!.values.insertValue(lat, column: 2, row: row);
    final east = double.parse(await _ws!.values.value(column: 30, row: row));
    final north = double.parse(await _ws!.values.value(column: 31, row: row));
    return [east, north];
  }
}

class VisorUrbanoService {
  static Future<List<dynamic>> predioPorLatLon(double lat, double lon) async {
    final utm = await ExcelToUTM.toUTM(lat, lon); // <-- renombrado
    final url = Uri.parse(
      "https://visorurbano.com:3000/api/v2/catastro/predio/${utm[0]}/${utm[1]}",
    );
    final r = await http.get(url);
    if (r.statusCode != 200) throw Exception('VisorUrbano error ${r.statusCode}');
    return json.decode(r.body);
  }
}
